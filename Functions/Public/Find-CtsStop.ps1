function Find-CtsStop {
  <#
  .SYNOPSIS
  Finds CTS stops and lines matching filters
  .DESCRIPTION
  TODO
  .EXAMPLE
  Find-CtsStop Gallia Gare, Neuhof, Wolfisheim
  Returns all 'Gallia' stops with a line in direction of 'Gare...', 'Neuhof...' or 'Wolfisheim...'
  .EXAMPLE
  Find-CtsStop -Line A, D -Destination Kehl, Illkirch -Strict
  Returns all stops for lines 'A' and 'D' with the only destinations 'Kehl...' and 'Illkirch...'
  Destinations with the same direction are excluded: 'Port du Rhin', 'Les Halles'
  .OUTPUTS
  Stop objects with the relevant lines and destinations
  #>
  [CmdletBinding(SupportsShouldProcess)]
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

    # TODO
    [Parameter()]
    [Switch] $Strict,

    # TODO
    [Parameter(DontShow)]
    [Switch] $Completion,

    # Whether to bypass the stop and departure caches
    [Parameter(DontShow)]
    [Switch] $Force,

    # Whether to avoid updating the stop cache
    [Parameter(DontShow)]
    [Switch] $NoCacheFile
  )
  process {
    try {
      Update-CtsStopCache -Force:$Force -NoCacheFile:$NoCacheFile
    } catch {
      $PSCmdlet.ThrowTerminatingError($_)
    }

    $StringComparison = [System.StringComparison]::CurrentCultureIgnoreCase
    $Destinations = [StopCache]::Instance.Destinations.GetEnumerator() | Where-Object {
      $LineName = $_.Key
      # Loose match only for argument completion
      if ($Completion) {
        $Line.Count -eq 0 -or $Line.Where({ $LineName.StartsWith($_, $StringComparison) }).Count -gt 0
      } else {
        $Line.Count -eq 0 -or $Line -contains $LineName
      }
    } | ForEach-Object {
      $Dest = $_.Value.GetEnumerator() | Where-Object {
        $DestName = $_.Name
        $Destination.Count -eq 0 -or $Destination.Where({ $DestName.StartsWith($_, $StringComparison) }).Count -gt 0
      }
      if ($Strict) {
        $Dest
      } else {
        # Include same-direction destinations to support CTS network changes
        $Directions = $Dest.Direction | Select-Object -Unique
        $_.Value.GetEnumerator() | Where-Object { $_.Direction -in $Directions }
      }
    }
    $Stops = $Destinations.Stops | Select-Object -Unique | ForEach-Object {
      [StopCache]::Instance.Stops[$_]
    } | Where-Object {
      $StopName = $_.Name
      $Stop.Count -eq 0 -or $Stop.Where({ $StopName.StartsWith($_, $StringComparison) }).Count -gt 0
    }

    $Stops | ForEach-Object {
      $StopId = $_.Id
      $Lines = $Destinations | Where-Object {
        $_.Stops.Contains($StopId)
      } | Group-Object -Property Line | ForEach-Object {
        [Line]@{
          LineInfo     = [StopCache]::Instance.Lines[$_.Name]
          Destinations = $_.Group.Name
        }
      }
      [Stop]@{
        StopInfo = $_
        Lines    = $Lines
      }
    }
  }
}
