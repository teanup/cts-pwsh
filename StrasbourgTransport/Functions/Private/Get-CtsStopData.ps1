<#
.SYNOPSIS
Retrieves the raw CTS stop list and caches it locally
#>
function Get-CtsStopData {
  [CmdletBinding()]
  [OutputType([CtsAnnotatedStopPointStructure])]
  param(
    [Parameter(Mandatory = $false)]
    [Switch]$Force,

    [Parameter(Mandatory = $false)]
    [Switch]$NoCacheFile
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
          Write-Verbose -Message 'Stop cache has expired'
          $IsStopCacheExpired = $true
        }
      } catch {
        Write-Warning -Message "Error loading stop cache: $($_.Exception.Message)"
      }
    } elseif (-not $Force) {
      Write-Verbose -Message 'Stop cache not found'
      $IsStopCacheExpired = $true
    }

    if ($Force -or $IsStopCacheExpired) {
      # Fall back to CTS API
      try {
        $Response = Invoke-CtsApi -Path 'siri/2.0/stoppoints-discovery' -Query @{
          IncludeLinesDestinations = $true
        }
        [CtsStopPointsDelivery]$Script:StopCache = $Response.StopPointsDelivery

        if (-not $NoCacheFile) {
          $Script:StopCache | ConvertTo-Json -Depth 100 -Compress | Set-Content -Path $StopCachePath -Force
          Write-Verbose -Message "Updated stop cache: $StopCachePath"
        }
      } catch {
        throw $_
      }
    } else {
      Write-Verbose -Message "Using stop cache: $StopCachePath"
    }

    return $Script:StopCache.AnnotatedStopPointRef
  }
}
