function Get-CtsDepartureData {
  <#
  .SYNOPSIS
  Retrieves the raw CTS stop departures and caches it locally
  .DESCRIPTION
  TODO
  .EXAMPLE
  Get-CtsDepartureData TODO
  .EXAMPLE
  Get-CtsDepartureData TODO
  .OUTPUTS
  DepartureData objects with departure data for the specified stops
  #>
  [CmdletBinding()]
  [OutputType([DepartureData])]
  param (
    # IDs of the CTS stops to query
    [Parameter(Mandatory)]
    [ValidatePattern('^\w{6,10}$')]
    [String[]] $StopId,

    # Number of departures to query
    [Parameter()]
    [ValidateRange(1, 10)]
    [Int] $MinDepartures = 3,

    # Whether to bypass the departure cache
    [Parameter()]
    [Switch] $Force
  )
  process {
    if ($null -eq $Script:DepartureCache) {
      $Script:DepartureCache = [System.Collections.Generic.Dictionary[String, DepartureCache]]::new()
    }

    $Now = [DateTime]::Now
    $ExpiredStopId = $StopId | Where-Object {
      $Force -or $Script:DepartureCache.$_.ValidUntil -lt $Now
    }

    # Fetch expired departures
    if ($ExpiredStopId.Count -gt 0) {
      try {
        Write-Verbose -Message "CtsDeparture: Fetching departures for $($ExpiredStopId.Count) stops"
        $Response = Invoke-CtsApi -Path 'siri/2.0/stop-monitoring' -Query @{
          MonitoringRef            = $ExpiredStopId
          MinimumStopVisitsPerLine = $MinDepartures
        }
        [CtsStopMonitoringDelivery]$StopMonitoring = $Response.ServiceDelivery.StopMonitoringDelivery[0]
      } catch {
        $PSCmdlet.ThrowTerminatingError($_)
      }

      # Follow CTS response cache guidelines
      $ShortestCycle = [System.Xml.XmlConvert]::ToTimeSpan($StopMonitoring.ShortestPossibleCycle)
      $ValidUntil = $StopMonitoring.ResponseTimestamp + $ShortestCycle
      if ($StopMonitoring.ValidUntil -gt $ValidUntil) {
        $ValidUntil = $StopMonitoring.ValidUntil
      }

      # Update departure cache
      $StopVisits = $StopMonitoring.MonitoredStopVisit
      $ExpiredStopId | ForEach-Object {
        $Id = $_
        $VehicleJourneys = ($StopVisits | Where-Object { $_.MonitoringRef -eq $Id }).MonitoredVehicleJourney
        $Script:DepartureCache.$Id = [DepartureCache]@{
          ValidUntil = $ValidUntil
          Departures = $VehicleJourneys | Group-Object -Property LineRef, DestinationName | ForEach-Object {
            $Line = $_.Group[0].LineRef
            $Destination = $_.Group[0].DestinationName

            [DepartureData]@{
              StopId      = $Id
              LineName    = $Line
              Destination = $Destination
              Times       = $_.Group.MonitoredCall | ForEach-Object {
                [DepartureTime]@{
                  Time = $_.ExpectedDepartureTime
                  Live = $_.Extension.IsRealTime
                }
              }
            }
          }
        }
      }
    }

    # Return data for requested stops
    $StopId | ForEach-Object { $Script:DepartureCache.$_.Departures }
  }
}
