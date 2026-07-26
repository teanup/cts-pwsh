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
    $FileCachePath = [System.IO.Path]::GetTempPath() | Join-Path -ChildPath 'cts-stop-cache.json'
    $NeedsCacheRefresh = $false

    if ($Force) {
      Write-Verbose -Message 'CtsStop: Refreshing cache'
    } elseif ($null -eq $Script:StopCache) {
      # Use file cache if available
      if (Test-Path -Path $FileCachePath) {
        try {
          [StopFileCache]$FileCache = Get-Content -Path $FileCachePath -Raw | ConvertFrom-Json -AsHashtable

          if ($FileCache.ValidUntil -lt [DateTime]::Now) {
            Write-Verbose -Message 'CtsStop: Cache has expired'
            $NeedsCacheRefresh = $true
          } else {
            Write-Verbose -Message "CtsStop: Using cache: $FileCachePath"

            # Index stops and lines
            $StopCache = [StopCache]@{ ValidUntil = $FileCache.ValidUntil }
            $FileCache.Stops | ForEach-Object {
              if (-not $StopCache.Stops.TryAdd($_.Id, $_)) {
                Write-Error -Message "Failed to add stop '$($_.Id)' to cache"
              }
            }
            $FileCache.Lines | ForEach-Object {
              if (-not $StopCache.Lines.TryAdd($_.Id, $_)) {
                Write-Error -Message "Failed to add line '$($_.Id)' to cache"
              }
              if (-not $StopCache.Destinations.TryAdd($_.Id, $_.Destinations)) {
                Write-Error -Message "Failed to add destinations of line '$($_.Id)' to cache"
              }
            }

            $Script:StopCache = $StopCache
          }
        } catch {
          Write-Warning -Message "CtsStop: Error loading cache: $($_.Exception.Message)"
          $NeedsCacheRefresh = $true
        }
      } else {
        Write-Verbose -Message 'CtsStop: Cache not found'
        $NeedsCacheRefresh = $true
      }
    } else {
      if ($Script:StopCache.ValidUntil -lt [DateTime]::Now) {
        Write-Verbose -Message 'CtsStop: Cache has expired'
        $NeedsCacheRefresh = $true
      }
    }

    # Refresh stop cache
    if ($Force -or $NeedsCacheRefresh) {
      try {
        $Response = Invoke-CtsApi -Path 'siri/2.0/stoppoints-discovery' -Query @{ IncludeLinesDestinations = $true }
        # $Response = Get-Content -Raw -Path '/workspaces/cts-pwsh/NuGet/stop-points-discovery.json' | ConvertFrom-Json
        [CtsStopPointsDelivery]$StopPoints = $Response.StopPointsDelivery

        $LineCache = [System.Collections.Concurrent.ConcurrentDictionary[String, LineRawInfo]]::new()
        $StopCache = [StopCache]@{ ValidUntil = $StopPoints.ResponseTimestamp.AddDays(7) }

        $StopPoints.AnnotatedStopPointRef | ForEach-Object {
          $Stop = [StopInfo]@{
            Id   = $_.StopPointRef
            Name = $_.StopName
          }
          $IncludeStop = $false
          $_.Lines | ForEach-Object {
            $RawLine = [LineRawInfo]@{
              Id    = $_.LineRef
              Name  = $_.LineName
              Color = $_.Extension.RouteColor
              Dark  = $_.Extension.RouteTextColor -eq 'FFFFFF'
            }
            $IncludeLine = $false
            $_.Destinations | ForEach-Object {
              $Direction = $_.DirectionRef
              # Ignore terminus (inconsistent across lines)
              $_.DestinationName | Where-Object { $_ -ne $Stop.Name } | ForEach-Object {
                $Destination = [Destination]@{
                  Line      = $RawLine.Id
                  Direction = $Direction
                  Name      = $_
                  Stops     = $Stop.Id
                }
                if (-not $StopCache.Destinations.TryAdd($Destination.Line, $Destination)) {
                  [System.Collections.Generic.List[Destination]]$Destinations = $null
                  if (-not $StopCache.Destinations.TryGetValue($Destination.Line, [Ref]$Destinations)) {
                    Write-Error -Message "Failed to get destinations of line '$($Destination.Line)' from cache"
                  }
                  $IsNewDest = $true
                  foreach ($Dest in $Destinations) {
                    if ($Dest.Direction -eq $Destination.Direction -and $Dest.Name -eq $Destination.Name) {
                      $Dest.Stops.Add($Stop.Id)
                      $IsNewDest = $false
                      break
                    }
                  }
                  if ($IsNewDest) {
                    $Destinations.Add($Destination)
                  }
                }
                $IncludeLine += $true
              }
            }
            if ($IncludeLine) {
              if ($LineCache.TryAdd($RawLine.Id, $RawLine)) {
                if (-not $StopCache.Lines.TryAdd($RawLine.Id, $RawLine)) {
                  Write-Error -Message "Failed to add line '$($RawLine.Id)' to cache"
                }
              }
              $IncludeStop += $true
            }
          }
          if ($IncludeStop) {
            if (-not $StopCache.Stops.TryAdd($Stop.Id, $Stop)) {
              Write-Error -Message "Failed to add stop '$($Stop.Id)' to cache"
            }
          }
        }

        if (-not $NoCacheFile) {
          $FileCache = [StopFileCache]@{
            ValidUntil = $StopCache.ValidUntil
            Stops      = $StopCache.Stops.Values
            Lines      = $LineCache.Values
          }
          $FileCache.Lines | ForEach-Object {
            [Destination[]]$Destinations = $null
            if (-not $StopCache.Destinations.TryGetValue($_.Id, [Ref]$Destinations)) {
              Write-Error -Message "Failed to get destinations of line '$($_.Id)' from cache"
            }
            $_.Destinations = $Destinations
          }
          $FileCache | ConvertTo-Json -Depth 100 -Compress | Set-Content -Path $FileCachePath -Force
          Write-Verbose -Message "CtsStop: Updated cache: $FileCachePath"
        }

        $Script:StopCache = $StopCache
      } catch {
        $PSCmdlet.ThrowTerminatingError($_)
      }
    }

    $Script:StopCache
  }
}
