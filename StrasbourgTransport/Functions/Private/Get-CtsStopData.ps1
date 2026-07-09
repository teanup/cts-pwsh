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
  [OutputType([StopCache])]
  param (
    # Whether to bypass the stop cache
    [Parameter()]
    [Switch] $Force,

    # Whether to avoid updating the stop cache
    [Parameter()]
    [Switch] $NoCacheFile
  )
  process {
    $StopCachePath = [System.IO.Path]::GetTempPath() | Join-Path -ChildPath 'cts-stop-cache.json'
    $NeedsCacheRefresh = $false

    # Use file cache if available
    if (-not $Force -and $null -eq $Script:StopCache) {
      if (Test-Path -Path $StopCachePath) {
        try {
          $StopFileCache = Get-Content -Path $StopCachePath -Raw | ConvertFrom-Json -AsHashtable
          if ([DateTime]$StopFileCache.ValidUntil -lt [DateTime]::Now) {
            Write-Verbose -Message 'CtsStop: Cache has expired'
            $NeedsCacheRefresh = $true
          } else {
            Write-Verbose -Message "CtsStop: Using cache: $StopCachePath"

            # Convert hashtables to dictionaries
            $Script:StopCache = [StopCache]@{
              ValidUntil = $StopFileCache.ValidUntil
              Stops      = [Dictionary[String, StopData]]::new()
              Lines      = [Dictionary[String, LineData]]::new()
            }
            $StopFileCache.Stops.Values | ForEach-Object {
              $StopData = [StopData]@{
                Id    = $_.Id
                Name  = $_.Name
                Lines = [Dictionary[String, String[]]]::new()
              }
              $_.Lines.GetEnumerator() | ForEach-Object { $StopData.Lines.($_.Key) = $_.Value }
              $Script:StopCache.Stops.($_.Id) = $StopData
            }
            $StopFileCache.Lines.Values | ForEach-Object { $Script:StopCache.Lines.($_.Name) = $_ }
          }
        } catch {
          Write-Warning -Message "CtsStop: Error loading cache: $($_.Exception.Message)"
          $NeedsCacheRefresh = $true
        }
      } else {
        Write-Verbose -Message 'CtsStop: Cache not found'
        $NeedsCacheRefresh = $true
      }
    }

    # Refresh stop cache
    if ($Force -or $NeedsCacheRefresh) {
      $Script:StopCache = [StopCache]@{
        ValidUntil = [DateTime]::Now.AddDays(7)
        Stops      = [System.Collections.Generic.Dictionary[String, StopData]]::new()
        Lines      = [System.Collections.Generic.Dictionary[String, LineData]]::new()
      }

      try {
        $Response = Invoke-CtsApi -Path 'siri/2.0/stoppoints-discovery' -Query @{ IncludeLinesDestinations = $true }
        [CtsStopPointsDelivery]$StopPoints = $Response.StopPointsDelivery

        $StopPoints.AnnotatedStopPointRef | ForEach-Object {
          $Lines = [System.Collections.Generic.Dictionary[String, String[]]]::new()
          $_.Lines | ForEach-Object {
            if ($null -eq $Script:StopCache.Lines.($_.LineRef)) {
              $Script:StopCache.Lines.($_.LineRef) = [LineData]@{
                Name        = $_.LineRef
                Description = $_.LineName
                Background  = $_.Extension.RouteColor
                Foreground  = $_.Extension.RouteTextColor
              }
            }
            # Mix all directions
            $Lines.($_.LineRef) = $_.Destinations.DestinationName
          }
          $Script:StopCache.Stops.($_.StopPointRef) = [StopData]@{
            Id    = $_.StopPointRef
            Name  = $_.StopName
            Lines = $Lines
          }
        }

        if (-not $NoCacheFile) {
          $Script:StopCache | ConvertTo-Json -Depth 100 -Compress | Set-Content -Path $StopCachePath -Force
          Write-Verbose -Message "CtsStop: Updated cache: $StopCachePath"
        }
      } catch {
        $PSCmdlet.ThrowTerminatingError($_)
      }
    }

    $Script:StopCache
  }
}
