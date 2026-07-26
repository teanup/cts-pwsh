function Update-CtsStopCache {
  <#
  .SYNOPSIS
  Retrieves the CTS stop list and caches it in memory and on disk
  .DESCRIPTION
  Fetches all CTS stops, lines and destinations from the API and indexes them in the singleton [StopCache] instance.
  The result is also persisted to a JSON file in the temp directory so subsequent sessions can skip the API call.
  .EXAMPLE
  Update-CtsStopCache
  .EXAMPLE
  Update-CtsStopCache -Force
  Bypasses the file cache and fetches fresh data from the API.
  #>
  [CmdletBinding(SupportsShouldProcess)]
  [OutputType([Void])]
  param (
    # Bypass both the in-memory and file caches, fetch fresh data from the API
    [Parameter()]
    [Switch] $Force,

    # Skip writing the cache file to disk (in-memory cache only)
    [Parameter()]
    [Switch] $NoCacheFile
  )
  process {
    $FileCachePath = [System.IO.Path]::GetTempPath() | Join-Path -ChildPath 'cts-stop-cache.json'
    $Refresh = $false

    if ($Force) {
      Write-Verbose -Message 'CtsStop: Refreshing cache'
    } elseif ([StopCache]::Instance.Ready) {
      if ([StopCache]::Instance.ValidUntil -lt [DateTime]::Now) {
        Write-Verbose -Message 'CtsStop: Cache has expired'
        $Refresh = $true
      }
    } else {
      if (Test-Path -Path $FileCachePath) {
        try {
          # Load file cache if available
          [StopFileCache]$FileCache = Get-Content -Path $FileCachePath -Raw | ConvertFrom-Json -AsHashtable

          if ($FileCache.ValidUntil -lt [DateTime]::Now) {
            Write-Verbose -Message 'CtsStop: Cache has expired'
            $Refresh = $true
          } else {
            # Index stops and lines
            Write-Verbose -Message "CtsStop: Using cache: $FileCachePath"
            [StopCache]::Instance.Init($FileCache.ValidUntil)
            $FileCache.Stops | ForEach-Object { [StopCache]::Instance.Stops[$_.Id] = $_ }
            $FileCache.Lines | ForEach-Object {
              [StopCache]::Instance.Lines[$_.Id] = $_
              [StopCache]::Instance.Destinations[$_.Id] = $_.Destinations
            }
            [StopCache]::Instance.Ready = $true
          }
        } catch {
          Write-Warning -Message "CtsStop: Error loading cache: $($_.Exception.Message)"
          $Refresh = $true
        }
      } else {
        Write-Verbose -Message 'CtsStop: Cache not found'
        $Refresh = $true
      }
    }

    if ($Force -or ($Refresh -and $PSCmdlet.ShouldProcess('Memory cache', 'Refresh stop cache'))) {
      try {
        # Refresh stop cache
        $Response = Invoke-CtsApi -Path 'siri/2.0/stoppoints-discovery' -Query @{ IncludeLinesDestinations = $true }
        [CtsStopPointsDelivery]$StopPoints = $Response.StopPointsDelivery

        $LineCache = [System.Collections.Concurrent.ConcurrentDictionary[String, LineRawInfo]]::new()
        [StopCache]::Instance.Init($StopPoints.ResponseTimestamp.AddDays(7))

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
                # Add or update line destinations
                if (-not [StopCache]::Instance.Destinations.TryAdd($Destination.Line, $Destination)) {
                  $Destinations = [StopCache]::Instance.Destinations[$Destination.Line]
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
              # Use line cache as reference
              if ($LineCache.TryAdd($RawLine.Id, $RawLine)) {
                [StopCache]::Instance.Lines[$RawLine.Id] = $RawLine
              }
              $IncludeStop += $true
            }
          }
          if ($IncludeStop) {
            [StopCache]::Instance.Stops[$Stop.Id] = $Stop
          }
        }
        [StopCache]::Instance.Ready = $true

        # Update file cache
        if (-not $NoCacheFile -and ($Force -or $PSCmdlet.ShouldProcess($FileCachePath, 'Replace file cache'))) {
          $FileCache = [StopFileCache]@{
            ValidUntil = [StopCache]::Instance.ValidUntil
            Stops      = [StopCache]::Instance.Stops.Values
            Lines      = $LineCache.Values
          }
          $FileCache.Lines | ForEach-Object { $_.Destinations = [StopCache]::Instance.Destinations[$_.Id] }
          $SetParam = @{
            Path    = $FileCachePath
            Force   = true
            WhatIf  = $false
            Confirm = $false
          }
          $FileCache | ConvertTo-Json -Depth 100 -Compress | Set-Content @SetParam
          Write-Verbose -Message "CtsStop: Updated cache: $FileCachePath"
        }
      } catch {
        $PSCmdlet.ThrowTerminatingError($_)
      }
    }
  }
}
