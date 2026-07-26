function Update-CtsDepartureCache {
  <#
  .SYNOPSIS
  Retrieves CTS stop departures and caches them in memory
  .DESCRIPTION
  Fetches real-time departures for the given stop IDs from the CTS API and stores them in the singleton
  [DepartureCache] instance. Only stops whose cached data has expired are refreshed, unless -Force is used.
  .EXAMPLE
  Update-CtsDepartureCache -StopId 'HOFER_05', 'OBSER_05'
  .EXAMPLE
  Update-CtsDepartureCache -StopId 'CAILL_04' -MinDepartures 5 -Force
  #>
  [CmdletBinding(SupportsShouldProcess)]
  [OutputType([Void])]
  param (
    # IDs of the CTS stops to query
    [Parameter()]
    [AllowEmptyCollection()]
    [String[]] $StopId,

    # Minimum number of departures to fetch per line
    [Parameter()]
    [ValidateRange(1, 10)]
    [Int] $MinDepartures = 3,

    # Bypass the departure cache and refresh all specified stops
    [Parameter()]
    [Switch] $Force
  )
  process {
    $ExpiredId = $StopId | Where-Object {
      $Departure = [DepartureCache]::Instance.Departures[$_] | Select-Object -First 1
      $Force -or $null -eq $Departure -or $Departure.ValidUntil -lt [DateTime]::Now
    }

    if ($ExpiredId.Count -gt 0 -and ($Force -or $PSCmdlet.ShouldProcess($ExpiredId, 'Refresh stop departures'))) {
      try {
        Write-Verbose -Message "CtsDeparture: Fetching departures for $($ExpiredId.Count) stops"
        $Response = Invoke-CtsApi -Path 'siri/2.0/stop-monitoring' -Query @{
          MonitoringRef            = $ExpiredId
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
