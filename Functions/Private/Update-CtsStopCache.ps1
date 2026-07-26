function Update-CtsStopCache {
  <#
  .SYNOPSIS
  Retrieves the raw CTS stop list and caches it locally
  .DESCRIPTION
  TODO
  .EXAMPLE
  Update-CtsStopCache TODO
  .EXAMPLE
  Update-CtsStopCache TODO
  #>
  [CmdletBinding(SupportsShouldProcess)]
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
        # Load file cache if available
        try {
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

    if ($Force -or $Refresh) {
      # Refresh stop cache
      try {
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

        if (-not $NoCacheFile) {
          $FileCache = [StopFileCache]@{
            ValidUntil = [StopCache]::Instance.ValidUntil
            Stops      = [StopCache]::Instance.Stops.Values
            Lines      = $LineCache.Values
          }
          $FileCache.Lines | ForEach-Object { $_.Destinations = [StopCache]::Instance.Destinations[$_.Id] }
          if ($Force -or $PSCmdlet.ShouldProcess($FileCachePath, 'Create/replace stop cache')) {
            $FileCache | ConvertTo-Json -Depth 100 -Compress | Set-Content -Path $FileCachePath -Force -WhatIf:$false -Confirm:$false
            Write-Verbose -Message "CtsStop: Updated cache: $FileCachePath"
          }
        }

        [StopCache]::Instance.Ready = $true
      } catch {
        $PSCmdlet.ThrowTerminatingError($_)
      }
    }
  }
}
