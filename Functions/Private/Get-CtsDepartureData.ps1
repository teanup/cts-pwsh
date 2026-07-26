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
  [OutputType([DepartureCache])]
  param (
    # IDs of the CTS stops to query
    [Parameter()]
    [AllowEmptyCollection()]
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
      $Script:DepartureCache = [DepartureCache]::new()
    }

    $ExpiredStopId = $Force ? $StopId : $StopId | Where-Object {
      [System.Collections.Generic.List[DepartureInfo]]$Departures = $null
      if ($Force -or -not $Script:DepartureCache.Departures.TryGetValue($_, [Ref]$Departures)) {
        $true
      } else {
        $Departures.ValidUntil -lt [DateTime]::Now
      }
    }

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

      # Follow CTS cache guidelines
      $ShortestCycle = [System.Xml.XmlConvert]::ToTimeSpan($StopMonitoring.ShortestPossibleCycle)
      $ValidUntil = $StopMonitoring.ResponseTimestamp + $ShortestCycle
      if ($StopMonitoring.ValidUntil -gt $ValidUntil) {
        $ValidUntil = $StopMonitoring.ValidUntil
      }

      $StopMonitoring.MonitoredStopVisit | Group-Object -Property MonitoringRef | ForEach-Object {
        $StopId = $_.Name
        $Script:DepartureCache.Departures[$StopId] = $_.Group.MonitoredVehicleJourney | Group-Object -Property {
          $_.LineRef + "`n" + $_.DestinationName
        } | ForEach-Object {
          $Line, $Destination = $_.Name -split '\n'
          [DepartureInfo]@{
            ValidUntil  = $ValidUntil
            Line        = $Line
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

    $Script:DepartureCache
  }
}
