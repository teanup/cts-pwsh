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
    $LastLineCount = 0
    # Save start position
    Write-Host -Object "`e7" -NoNewline

    while ($true) {
      $LineCount = 0
      $DepartureText = [System.Text.StringBuilder]::new()
      $Now = [DateTime]::Now

      Get-CtsDeparture @GetParam | Group-Object -Property StopName | ForEach-Object {
        $MaxLength = $_.Group.Line.VisibleLength | Measure-Object -Maximum
        $PadLength = $MaxLength.Maximum + 3

        # Stop name as title
        $null = $DepartureText.AppendLine($_.Name)
        $LineCount++

        # Lines as sub-elements
        for ($Index = 0; $Index -lt $_.Count; $Index++) {
          $Departure = $_.Group[$Index]
          if ($Index -lt ($_.Count - 1)) {
            $null = $DepartureText.Append(" `e(0tq`e(B ")
          } else {
            $null = $DepartureText.Append(" `e(0mq`e(B ")
          }
          $null = $DepartureText.Append($Departure.Line.PadRight($PadLength))

          $null = $DepartureText.AppendJoin('  ', $Departure.Departures.ForEach({ $_.ToString($Now) }))
          $null = $DepartureText.AppendLine()
          $LineCount++
        }
      }

      # Adjust start position
      $TerminalSequence = [System.Text.StringBuilder]::new("`e8")
      $LineCountDiff = $LineCount - $LastLineCount
      if ($LineCountDiff -gt 0) {
        $null = $TerminalSequence.Append("`e[$($LineCountDiff)S`e[$($LineCountDiff)A")
      } elseif ($LineCountDiff -lt 0) {
        $null = $TerminalSequence.Append("`e[$(-$LineCountDiff)T`e[$(-$LineCountDiff)B")
      }
      $null = $TerminalSequence.Append("`e7")

      # Replace previous departures and keep last error/warning/verbose messages
      if ($LastLineCount -gt 0) {
        $null = $TerminalSequence.Append("`e[$($LastLineCount)M")
      }
      if ($LineCount -gt 0) {
        $null = $TerminalSequence.Append("`e[$($LineCount)L")
      }
      $null = $DepartureText.Insert(0, $TerminalSequence)

      # Flush departures to console
      Write-Host -Object $DepartureText.ToString() -NoNewline
      Start-Sleep -Seconds $RefreshRate

      # Erase previous error/warning/verbose messages
      Write-Host -Object "`e8`e[100M" -NoNewline
      $LastLineCount = $LineCount
    }
  }
}
