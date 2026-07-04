function Show-CtsDeparture {
  <#
  .SYNOPSIS
  Displays the next departures dynamically at the specified CTS stops
  .DESCRIPTION
  TODO
  .EXAMPLE
  Show-CtsDeparture TODO
  .EXAMPLE
  Show-CtsDeparture TODO
  #>
  [CmdletBinding(DefaultParameterSetName = 'Filters')]
  [OutputType([Void])]
  param(
    # CTS line names to look up
    [Parameter(ParameterSetName = 'Filters')]
    [ArgumentCompleter([LineCompleter])]
    [AllowEmptyCollection()]
    [String[]] $Line,

    # CTS stop names to look up
    [Parameter(Position = 0, ParameterSetName = 'Filters')]
    [ArgumentCompleter([StopCompleter])]
    [AllowEmptyCollection()]
    [Alias('From')]
    [String[]] $Stop,

    # CTS destination names to look up
    [Parameter(Position = 1, ParameterSetName = 'Filters')]
    [ArgumentCompleter([DestinationCompleter])]
    [AllowEmptyCollection()]
    [Alias('To')]
    [String[]] $Destination,

    # CTS stop objects to use
    [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Object')]
    [AllowEmptyCollection()]
    [Stop[]] $StopObject,

    # Maximum number of departures per line, stop and destination
    [Parameter()]
    [ValidateRange(1, 8)]
    [Int] $MaxDepartures = 3,

    # Time between each departure refresh in seconds
    [Parameter()]
    [ValidateRange(1, [Int]::MaxValue)]
    [Int] $RefreshRate = 5,

    # Whether to bypass the stop and departure caches
    [Parameter(DontShow)]
    [Switch] $Force,

    # Whether to avoid updating the stop cache
    [Parameter(ParameterSetName = 'Filters', DontShow)]
    [Switch] $NoCacheFile
  )
  process {
    if ($PSCmdlet.ParameterSetName -eq 'Filters') {
      $GetParam = @{
        Line          = $Line
        Stop          = $Stop
        Destination   = $Destination
        MaxDepartures = $MaxDepartures
        Force         = $Force
        NoCacheFile   = $NoCacheFile
      }
    } else {
      $GetParam = @{
        StopObject    = $StopObject
        MaxDepartures = $MaxDepartures
        Force         = $Force
      }
    }

    while ($true) {
      $LastLineCount = $LineCount
      $LineCount = 0
      $Now = [DateTime]::Now
      $DepartureText = [System.Text.StringBuilder]::new()

      # Move cursor to top position
      if ($LastLineCount -gt 0) {
        Write-Host -Object "`e[$($LastLineCount)F" -NoNewline
      }

      Get-CtsDeparture @GetParam | Group-Object -Property StopName | ForEach-Object {
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
          $DepartureTimeText = $Departure.Times | ForEach-Object { $_.PadLeft(5, $Now) }
          $null = $DepartureText.AppendJoin('  ', $DepartureTimeText)
          $null = $DepartureText.AppendLine()
          $LineCount++
        }
      }

      # Erase previous departures
      if ($LastLineCount -gt 0) {
        Write-Host -Object "`e[$($LastLineCount)M" -NoNewline
      }

      # Print departures
      Write-Host -Object $DepartureText.ToString() -NoNewline
      Start-Sleep -Seconds $RefreshRate
    }
  }
}
