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
  CtsMonitoredStopVisit objects with departure data for the specified stop
  #>
  [CmdletBinding()]
  [OutputType([CtsMonitoredStopVisit])]
  param(
    # ID of the CTS stop to query
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String] $StopId,

    # Number of departures to query
    [Parameter()]
    [ValidateRange(1, 10)]
    [Int] $MinDepartures = 3,

    # Whether to bypass the departure cache
    [Parameter()]
    [Switch] $Force
  )
  process {
    $DepartureCacheType = [System.Collections.Concurrent.ConcurrentDictionary[String, CtsStopMonitoringDelivery]]
    if ($null -eq $Script:DepartureCache -or $Script:DepartureCache -isnot $DepartureCacheType) {
      $Script:DepartureCache = $DepartureCacheType::new()
    }

    # Use runspace cache if available
    if (-not $Force -and $Script:DepartureCache.ContainsKey($StopId)) {
      [CtsStopMonitoringDelivery]$StopMonitoring = $null
      if ($Script:DepartureCache.TryGetValue($StopId, [Ref]$StopMonitoring)) {
        if (([DateTime]::Now - $StopMonitoring.ResponseTimestamp) -le $Script:DepartureCacheValidFor) {
          return $StopMonitoring.MonitoredStopVisit
        }
      }
    }

    # Fall back to CTS API
    try {
      $Response = Invoke-CtsApi -Path 'siri/2.0/stop-monitoring' -Query @{
        MonitoringRef            = $StopId
        MinimumStopVisitsPerLine = $MinDepartures
      } -Token $Script:CtsApiToken
      [CtsStopMonitoringDelivery]$StopMonitoring = $Response.ServiceDelivery.StopMonitoringDelivery[0]
      $StopMonitoring = $Script:DepartureCache.AddOrUpdate($StopId, $StopMonitoring, { $StopMonitoring })
      return $StopMonitoring.MonitoredStopVisit
    } catch {
      $PSCmdlet.ThrowTerminatingError($_)
    }
  }
}
