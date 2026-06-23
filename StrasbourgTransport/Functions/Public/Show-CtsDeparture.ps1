<#
.SYNOPSIS
Displays the next departures at the specified CTS stops dynamically
#>
function Show-CtsDeparture {
  [CmdletBinding(DefaultParameterSetName = 'Filters')]
  [OutputType([Void])]
  param(
    [Parameter(Mandatory = $false, ParameterSetName = 'Filters')]
    [String[]]$Line,

    [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'Filters')]
    [Alias('From')]
    [String[]]$Stop = (''),

    [Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'Filters')]
    [Alias('To')]
    [String[]]$Destination = (''),

    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Object')]
    [Stop[]]$StopObject,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 8)]
    [Int]$Count = 3,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, [Int]::MaxValue)]
    [Int]$RefreshRate = 5,

    [Parameter(Mandatory = $false, DontShow)]
    [Switch]$Force,

    [Parameter(Mandatory = $false, ParameterSetName = 'Filters', DontShow)]
    [Switch]$NoCacheFile
  )
  process {
    if ($PSCmdlet.ParameterSetName -eq 'Filters') {
      $GetParam = @{
        Line        = $Line
        Stop        = $Stop
        Destination = $Destination
        Count       = $Count
        Force       = $Force
        NoCacheFile = $NoCacheFile
      }
    } else {
      $GetParam = @{
        StopObject = $StopObject
        Count      = $Count
        Force      = $Force
      }
    }
    $LineCount = 0

    while ($true) {
      $Now = [DateTime]::Now
      $DepartureText = [System.Text.StringBuilder]::new()

      # Erase previous departures
      if ($LineCount -gt 0) {
        Write-Host -Object "`e[$($LineCount)F`e[$($LineCount)M" -NoNewline
      }
      $LineCount = 0

      Get-CtsDeparture @GetParam | Group-Object -Property StopName | ForEach-Object {
        $MaxLength = $_.Group | ForEach-Object { $_.Line.VisibleLength() } | Measure-Object -Maximum
        $PadLength = $MaxLength.Maximum + 3

        # Stop name as title
        $null = $DepartureText.AppendLine($_.Name)
        $LineCount++

        # Lines as sub-elements
        for ($Index = 0; $Index -lt $_.Count; $Index++) {
          $Departure = $_.Group[$Index]
          if ($Index -lt ($_.Count - 1)) {
            $null = $DepartureText.Append(" `u{251C}`u{2500} ")
          } else {
            $null = $DepartureText.Append(" `u{2514}`u{2500} ")
          }
          $null = $DepartureText.Append($Departure.Line.PadRight($PadLength))

          # Departures on same line
          $DepartureTimeText = $Departure.Departures | ForEach-Object { $_.PadLeft(5, $Now) }
          $null = $DepartureText.AppendJoin('  ', $DepartureTimeText)
          $null = $DepartureText.AppendLine()
          $LineCount++
        }
      }

      # Flush departures to console
      Write-Host -Object $DepartureText.ToString() -NoNewline
      Start-Sleep -Seconds $RefreshRate
    }
  }
}
