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
  List of stop objects with the relevant lines and destinations
  #>
  [CmdletBinding()]
  [OutputType([System.Collections.Generic.List[Stop]])]
  param(
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

    # Whether to bypass the stop and departure caches
    [Parameter(DontShow)]
    [Switch] $Force,

    # Whether to avoid updating the stop cache
    [Parameter(DontShow)]
    [Switch] $NoCacheFile
  )
  process {
    $Stops = [System.Collections.Generic.List[Stop]]::new()
    $CaseComparison = [System.StringComparison]::CurrentCultureIgnoreCase

    Get-CtsStopData -Force:$Force -NoCacheFile:$NoCacheFile | ForEach-Object {
      $CtsStop = $_
      # Filter stops
      $IsMatchingStop = $Stop.Count -eq 0
      if (-not $IsMatchingStop) {
        foreach ($StopName in $Stop) {
          if ($CtsStop.StopName.StartsWith($StopName, $CaseComparison)) {
            $IsMatchingStop = $true
            break
          }
        }
      }
      if (-not $IsMatchingStop -or $CtsStop.Lines.Count -eq 0) {
        return
      }

      $Lines = $CtsStop.Lines | ForEach-Object {
        $CtsLine = $_
        # Filer lines
        $IsMatchingLine = $Line.Count -eq 0
        if (-not $IsMatchingLine) {
          foreach ($LineName in $Line) {
            if ($CtsLine.LineRef.StartsWith($LineName, $CaseComparison)) {
              $IsMatchingLine = $true
              break
            }
          }
        }
        if (-not $IsMatchingLine -or $CtsLine.Destinations.Count -eq 0) {
          return
        }

        $Destinations = $CtsLine.Destinations | ForEach-Object { $_.DestinationName } | ForEach-Object {
          $CtsDest = $_
          # Filer destinations
          $IsMatchingDest = $Destination.Count -eq 0
          if (-not $IsMatchingDest) {
            foreach ($DestName in $Destination) {
              if ($CtsDest.StartsWith($DestName, $CaseComparison)) {
                $IsMatchingDest = $true
                break
              }
            }
          }
          if ($IsMatchingDest) {
            $CtsDest
          }
        }

        if ($Destinations.Count -gt 0) {
          [Line]::new(
            $CtsLine.LineRef,
            $CtsLine.LineName,
            '0x' + $CtsLine.Extension.RouteColor,
            '0x' + $CtsLine.Extension.RouteTextColor,
            $Destinations
          )
        }
      }

      if ($Lines.Count -gt 0) {
        $Stops.Add([Stop]::new($CtsStop.StopPointRef, $CtsStop.StopName, $Lines))
      }
    }

    $Stops
  }
}
