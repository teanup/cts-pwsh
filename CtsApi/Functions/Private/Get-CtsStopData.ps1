<#
.SYNOPSIS
Retrieves the raw CTS stop points and cache it locally
#>
function Get-CtsStopData {
  [OutputType([AnnotatedStopPointStructure])]
  [CmdletBinding()]
  param(
    [Switch]$Force,
    [Switch]$NoCache
  )
  process {
    $StopPointsPath = [System.IO.Path]::GetTempPath() | Join-Path -ChildPath 'cts-stop-points.json'
    $StopPointsExpired = $true

    if (Test-Path -Path $StopPointsPath) {
      try {
        [StopPointsDelivery]$StopPoints = Get-Content -Path $StopPointsPath -Raw | ConvertFrom-Json
        if (-not $Force) {
          $StopPointsExpired = [DateTime]$StopPoints.ResponseTimestamp -lt [DateTime]::Now.AddDays(-3)
        }
      } catch {
        Write-Warning -Message "Error loading cached stops: $($_.Exception.Message)"
      }
    }

    if ($StopPointsExpired) {
      Write-Verbose -Message 'Cached stop data is absent or expired'
      try {
        $Response = Invoke-CtsApi -Path 'siri/2.0/stoppoints-discovery' -Query @{ IncludeLinesDestinations = $true }
        [StopPointsDelivery]$StopPoints = $Response.StopPointsDelivery
      } catch {
        throw $_.Exception.Message
      }
    } else {
      Write-Verbose -Message "Using cached stop data: $StopPointsPath"
    }

    if (-not $NoCache -and $StopPointsExpired) {
      $StopPoints | ConvertTo-Json -Depth 100 -Compress | Set-Content -Path $StopPointsPath -Force
      Write-Verbose -Message "Updated cached stop data: $StopPointsPath"
    }

    return $StopPoints.AnnotatedStopPointRef
  }
}
