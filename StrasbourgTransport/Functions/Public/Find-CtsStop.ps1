function Find-CtsStop {
  <#
  .SYNOPSIS
  Finds CTS stops and lines matching filters
  .DESCRIPTION
  TODO
  .EXAMPLE
  Find-CtsStop -Line A, D -Destination Kehl, Illkirch
  .EXAMPLE
  Find-CtsStop Gallia Gare, Neuhof, Wolfisheim
  .OUTPUTS
  Stop objects with the relevant lines and destinations
  #>
  [CmdletBinding()]
  [OutputType([Stop])]
  param (
    # CTS line names to look up
    [Parameter()]
    [ArgumentCompleter([LineCompleter])]
    [AllowEmptyCollection()]
    [String[]] $Line,

    # CTS stop names to look up
    [Parameter(Position = 0)]
    [ArgumentCompleter([StopCompleter])]
    [AllowEmptyCollection()]
    [Alias('From')]
    [String[]] $Stop,

    # CTS destination names to look up
    [Parameter(Position = 1)]
    [ArgumentCompleter([DestinationCompleter])]
    [AllowEmptyCollection()]
    [Alias('To')]
    [String[]] $Destination,

    # Whether to look up stops with loose string matching
    [Parameter(DontShow)]
    [Switch] $LooseMatch,

    # Whether to bypass the stop and departure caches
    [Parameter(DontShow)]
    [Switch] $Force,

    # Whether to avoid updating the stop cache
    [Parameter(DontShow)]
    [Switch] $NoCacheFile
  )
  begin {
    $StringComparison = [System.StringComparison]::CurrentCultureIgnoreCase

    function Test-StringArrayMatch {
      param (
        [String] $String,
        [String[]] $Patterns,
        [Switch] $Exact
      )
      foreach ($Pattern in $Patterns) {
        if (($Exact -and ($String -eq $Pattern)) -or $String.StartsWith($Pattern, $StringComparison)) {
          return $true
        }
      }
      return $false
    }
  }
  process {
    $StopCache = Get-CtsStopData -Force:$Force -NoCacheFile:$NoCacheFile

    $StopCache.Stops.GetEnumerator() | Where-Object {
      # Filter stops
      $Stop.Count -eq 0 -or (Test-StringArrayMatch -String $_.Value.Name -Patterns $Stop)
    } | ForEach-Object {
      $Lines = $_.Value.Lines.GetEnumerator() | Where-Object {
        # Filter lines
        $Line.Count -eq 0 -or (Test-StringArrayMatch -String $_.Key -Patterns $Line -Exact:(-not $LooseMatch))
      } | ForEach-Object {
        $Destinations = $_.Value | Where-Object {
          # Filter destinations
          $Destination.Count -eq 0 -or (Test-StringArrayMatch -String $_ -Patterns $Destination)
        }

        if ($Destinations.Count -gt 0) {
          [Line]::new($StopCache.Lines.($_.Key), $Destinations)
        }
      }

      if ($Lines.Count -gt 0) {
        [Stop]::new($_.Value, $Lines)
      }
    }
  }
}
