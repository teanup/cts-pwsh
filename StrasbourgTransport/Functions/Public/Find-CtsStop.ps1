<#
.SYNOPSIS
Finds CTS stops and lines matching filters
#>
function Find-CtsStop {
  [CmdletBinding()]
  [OutputType([Stop])]
  param(
    [Parameter(Mandatory = $false)]
    [String[]]$Line,

    [Parameter(Mandatory = $false, Position = 0)]
    [Alias('From')]
    [String[]]$Stop = (''),

    [Parameter(Mandatory = $false, Position = 1)]
    [Alias('To')]
    [String[]]$Destination = (''),

    [Parameter(Mandatory = $false, DontShow)]
    [Switch]$Force,

    [Parameter(Mandatory = $false, DontShow)]
    [Switch]$NoCacheFile
  )
  process {
    if ($Line.Count -eq 0) {
      $Line = ('*')
    }

    Get-CtsStopData -Force:$Force -NoCacheFile:$NoCacheFile | ForEach-Object {
      $CtsStop = $_
      # Filter stops
      foreach ($StopName in $Stop) {
        if ($CtsStop.StopName -like "*$StopName*") {
          $Lines = $CtsStop.Lines | ForEach-Object {
            $CtsLine = $_
            # Filer lines
            foreach ($LineName in $Line) {
              if ($CtsLine.LineRef -like "$LineName") {
                $Destinations = $CtsLine.Destinations | ForEach-Object {
                  # Filer destinations
                  foreach ($DestName in $Destination) {
                    if ($_.DestinationName -like "*$DestName*") {
                      return $_.DestinationName
                    }
                  }
                }
                if ($Destinations.Count -gt 0) {
                  return [Line]::new($CtsLine, $Destinations)
                }
              }
            }
          }
          if ($Lines.Count -gt 0) {
            return [Stop]::new($CtsStop, $Lines)
          }
        }
      }
    }
  }
}
