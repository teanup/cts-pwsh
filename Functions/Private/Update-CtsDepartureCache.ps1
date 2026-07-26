function Update-CtsDepartureCache {
  <#
  .SYNOPSIS
  Retrieves the raw CTS stop departures and caches it locally
  .DESCRIPTION
  TODO
  .EXAMPLE
  Update-CtsDepartureCache TODO
  .EXAMPLE
  Update-CtsDepartureCache TODO
  #>
  [CmdletBinding(SupportsShouldProcess)]
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
    $ExpiredStopId = $Force ? $StopId : $StopId | Where-Object {
      $Departures = [DepartureCache]::Instance.Departures[$_]
      $Force -or $Departures.Count -eq 0 -or $Departures[0].ValidUntil -lt [DateTime]::Now
    }

    if ($ExpiredStopId.Count -gt 0 -and ($Force -or $PSCmdlet.ShouldProcess($ExpiredStopId, 'Refresh stop departures'))) {
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
        $Departures = $_.Group.MonitoredVehicleJourney | Group-Object -Property {
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
        [DepartureCache]::Instance.Departures[$_.Name] = $Departures
      }
    }
  }
}
