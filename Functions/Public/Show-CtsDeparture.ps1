function Show-CtsDeparture {
  <#
  .SYNOPSIS
  Displays the next departures dynamically at the specified CTS stops
  .DESCRIPTION
  Shows a live-updating table of departures in the terminal (press Ctrl+C to exit).
  Refreshes automatically at the given interval and redraws in place using ANSI escape codes.
  .EXAMPLE
  Show-CtsDeparture -Stop Esplanade -Destination Lingolsheim, Robertsau
  .EXAMPLE
  Show-CtsDeparture -Stop 'Homme de Fer' -RefreshRate 10
  #>
  [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Filters',
    HelpUri = 'https://github.com/teanup/cts-pwsh/blob/main/.docs/StrasbourgTransport/Show-CtsDeparture.md#Show-CtsDeparture')]
  [OutputType([Void])]
  param (
    # Line names to filter by
    [Parameter(ParameterSetName = 'Filters')]
    [ArgumentCompleter([LineCompleter])]
    [AllowEmptyCollection()]
    [String[]] $Line,

    # Stop names to filter by (prefix match)
    [Parameter(Position = 0, ParameterSetName = 'Filters')]
    [ArgumentCompleter([StopCompleter])]
    [AllowEmptyCollection()]
    [Alias('From')]
    [String[]] $Stop,

    # Destination names to filter by (prefix match)
    [Parameter(Position = 1, ParameterSetName = 'Filters')]
    [ArgumentCompleter([DestinationCompleter])]
    [AllowEmptyCollection()]
    [Alias('To')]
    [String[]] $Destination,

    # Only return destinations that exactly match -Destination, excluding same-direction alternatives
    [Parameter(ParameterSetName = 'Filters')]
    [Switch] $Strict,

    # Stop objects from Find-CtsStop to display departures for
    [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Object')]
    [AllowNull()]
    [Stop[]] $StopObject,

    # Maximum number of departure times to show per line, stop and destination
    [Parameter()]
    [ValidateRange(1, 8)]
    [Int] $MaxDepartures = 3,

    # Time between each departure refresh in seconds
    [Parameter()]
    [ValidateRange(1, [Int]::MaxValue)]
    [Int] $RefreshRate = 5,

    # Bypass the stop and departure caches
    [Parameter(DontShow)]
    [Switch] $Force,

    # Skip writing the cache file to disk
    [Parameter(ParameterSetName = 'Filters', DontShow)]
    [Switch] $NoCacheFile
  )
  begin {
    $Stops = [System.Collections.Generic.List[System.Object]]::new()
  }
  process {
    if ($PSCmdlet.ParameterSetName -eq 'Filters') {
      $FindParam = @{
        Line        = $Line
        Stop        = $Stop
        Destination = $Destination
        Strict      = $Strict
        Force       = $Force
        NoCacheFile = $NoCacheFile
      }
      $StopObject = Find-CtsStop @FindParam
    }

    # Gather pipeline objects
    if ($null -ne $StopObject) {
      $StopObject | ForEach-Object { $Stops.Add([Stop]$_) }
    }
  }
  end {
    if ($Stops.Count -eq 0) {
      Write-Verbose -Message 'CtsDeparture: No stop found with requested filters'
      return
    }

    $LineCount = 0
    $GetParam = @{
      StopObject    = $Stops
      MaxDepartures = $MaxDepartures
      Force         = $Force
    }
    while ($true) {
      $LastLineCount = $LineCount
      $LineCount = 0
      $ReferenceTime = [DateTime]::Now
      $DepartureText = [System.Text.StringBuilder]::new()

      # Move cursor to top position
      if ($LastLineCount -gt 0) {
        Write-Host -Object "`e[$LastLineCount`F" -NoNewline
      }

      try {
        Get-CtsDeparture @GetParam | Group-Object -Property Stop | ForEach-Object {
          $MaxLength = $_.Group | ForEach-Object { $_.Line.VisibleLength() } | Measure-Object -Maximum
          $PadLength = $MaxLength.Maximum + 3

          # Stop name as title
          $null = $DepartureText.AppendLine($_.Name)
          $LineCount++

          # Lines as sub-elements
          for ($DepId = 0; $DepId -lt $_.Count; $DepId++) {
            $Departure = $_.Group[$DepId]
            if ($DepId -lt ($_.Count - 1)) {
              $null = $DepartureText.Append(" `u{251C}`u{2500} ")
            } else {
              $null = $DepartureText.Append(" `u{2514}`u{2500} ")
            }
            $null = $DepartureText.Append($Departure.Line.PadRight($PadLength))

            # Departures on same line
            $DepartureTimeText = $Departure.Times | ForEach-Object { $_.PadLeft(5, $ReferenceTime) }
            $null = $DepartureText.AppendJoin('  ', $DepartureTimeText)
            $null = $DepartureText.AppendLine()
            $LineCount++
          }
        }
      } catch {
        Write-Error -Message $_
      }

      # Erase previous departures
      if ($LastLineCount -gt 0) {
        Write-Host -Object "`e[$LastLineCount`M" -NoNewline
      }

      # Print departures
      Write-Host -Object $DepartureText -NoNewline
      Start-Sleep -Seconds $RefreshRate
    }
  }
}
