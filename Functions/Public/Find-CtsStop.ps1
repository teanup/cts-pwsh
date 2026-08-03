function Find-CtsStop {
  <#
  .SYNOPSIS
  Finds CTS stops and lines matching filters
  .DESCRIPTION
  Queries the cached CTS network data and returns [Stop] objects whose name, line and destination match the given
  filters. Stop, line and destination names are matched by prefix (case-insensitive), so partial names work.
  .EXAMPLE
  Find-CtsStop Gallia Gare, Neuhof, Wolfisheim
  Returns all stops named 'Gallia...' with a line heading towards 'Gare...', 'Neuhof...' or 'Wolfisheim...'
  .EXAMPLE
  Find-CtsStop -Line A, D -Destination Kehl, Illkirch -Strict
  Returns all stops for lines 'A' and 'D' with the only destinations 'Kehl...' and 'Illkirch...'
  Destinations with the same direction are excluded: 'Port du Rhin', 'Les Halles'
  .OUTPUTS
  [Stop] objects with the relevant lines and destinations
  #>
  [CmdletBinding(SupportsShouldProcess,
    HelpUri = 'https://github.com/teanup/cts-pwsh/blob/main/.docs/StrasbourgTransport/Find-CtsStop.md#Find-CtsStop')]
  [OutputType([Stop])]
  param (
    # Line names to filter by
    [Parameter()]
    [ArgumentCompleter([LineCompleter])]
    [AllowEmptyCollection()]
    [String[]] $Line,

    # Stop names to filter by (prefix match)
    [Parameter(Position = 0)]
    [ArgumentCompleter([StopCompleter])]
    [AllowEmptyCollection()]
    [Alias('From')]
    [String[]] $Stop,

    # Destination names to filter by (prefix match)
    [Parameter(Position = 1)]
    [ArgumentCompleter([DestinationCompleter])]
    [AllowEmptyCollection()]
    [Alias('To')]
    [String[]] $Destination,

    # Only return destinations that exactly match -Destination, excluding same-direction alternatives
    [Parameter()]
    [Switch] $Strict,

    # Enable loose prefix matching for argument completion (internal)
    [Parameter(DontShow)]
    [Switch] $Completion,

    # Bypass the stop cache and fetch fresh data from the API
    [Parameter(DontShow)]
    [Switch] $Force,

    # Skip writing the cache file to disk
    [Parameter(DontShow)]
    [Switch] $NoCacheFile
  )
  process {
    try {
      Update-CtsStopCache -Force:$Force -NoCacheFile:$NoCacheFile
    } catch {
      $PSCmdlet.ThrowTerminatingError($_)
    }

    # Ignore diacritics and case
    $Compare = [CultureInfo]::InvariantCulture.CompareInfo
    $Options = @(
      [System.Globalization.CompareOptions]::IgnoreNonSpace,
      [System.Globalization.CompareOptions]::IgnoreCase
    )

    $Destinations = [StopCache]::Instance.Destinations.GetEnumerator() | Where-Object {
      $LineName = $_.Key
      # Loose match only for argument completion
      if ($Completion) {
        $Line.Count -eq 0 -or $Line.Where({ $Compare.IsPrefix($LineName, $_, $Options) }).Count -gt 0
      } else {
        $Line.Count -eq 0 -or $Line -contains $LineName
      }
    } | ForEach-Object {
      $Dest = $_.Value.GetEnumerator() | Where-Object {
        $DestName = $_.Name
        $Destination.Count -eq 0 -or $Destination.Where({ $Compare.IsPrefix($DestName, $_, $Options) }).Count -gt 0
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
      $Stop.Count -eq 0 -or $Stop.Where({ $Compare.IsPrefix($StopName, $_, $Options) }).Count -gt 0
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
