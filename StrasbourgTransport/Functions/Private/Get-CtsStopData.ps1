function Get-CtsStopData {
  <#
  .SYNOPSIS
  Retrieves the raw CTS stop list and caches it locally
  .DESCRIPTION
  TODO
  .EXAMPLE
  Get-CtsStopData TODO
  .EXAMPLE
  Get-CtsStopData TODO
  .OUTPUTS
  CtsAnnotatedStopPointStructure objects with stop data for all stops
  #>
  [CmdletBinding()]
  [OutputType([CtsAnnotatedStopPointStructure])]
  param(
    # Whether to bypass the stop cache
    [Parameter()]
    [Switch] $Force,

    # Whether to avoid updating the stop cache
    [Parameter()]
    [Switch] $NoCacheFile
  )
  process {
    $StopCachePath = [System.IO.Path]::GetTempPath() | Join-Path -ChildPath 'cts-stop-cache.json'
    $IsStopCacheExpired = $false

    # Use runspace cache if available
    if (-not $Force -and $Script:StopCache -and $Script:StopCache -is [CtsStopPointsDelivery]) {
      if (([DateTime]::Now - $Script:StopCache.ResponseTimestamp) -le $Script:StopCacheValidFor) {
        return $Script:StopCache.AnnotatedStopPointRef
      } else {
        $IsStopCacheExpired = $true
      }
    }

    # Use file cache if available
    if (-not $Force -and (Test-Path -Path $StopCachePath)) {
      try {
        [CtsStopPointsDelivery]$Script:StopCache = Get-Content -Path $StopCachePath -Raw | ConvertFrom-Json
        if (([DateTime]::Now - $Script:StopCache.ResponseTimestamp) -gt $Script:StopCacheValidFor) {
          Write-Verbose -Message 'CtsStop: Cache has expired'
          $IsStopCacheExpired = $true
        }
      } catch {
        Write-Warning -Message "CtsStop: Error loading cache: $($_.Exception.Message)"
      }
    } elseif (-not $Force) {
      Write-Verbose -Message 'CtsStop: Cache not found'
      $IsStopCacheExpired = $true
    }

    if ($Force -or $IsStopCacheExpired) {
      # Fall back to CTS API
      try {
        $Response = Invoke-CtsApi -Path 'siri/2.0/stoppoints-discovery' -Query @{
          IncludeLinesDestinations = $true
        } -Token $Script:CtsApiToken
        [CtsStopPointsDelivery]$Script:StopCache = $Response.StopPointsDelivery

        if (-not $NoCacheFile) {
          $Script:StopCache | ConvertTo-Json -Depth 100 -Compress | Set-Content -Path $StopCachePath -Force
          Write-Verbose -Message "CtsStop: Updated cache: $StopCachePath"
        }
      } catch {
        $PSCmdlet.ThrowTerminatingError($_)
      }
    } else {
      Write-Verbose -Message "CtsStop: Using cache: $StopCachePath"
    }

    return $Script:StopCache.AnnotatedStopPointRef
  }
}
