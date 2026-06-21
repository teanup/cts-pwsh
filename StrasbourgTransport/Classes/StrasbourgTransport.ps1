<#
.SYNOPSIS
Classes describing simplified types for this module
#>

class Departure {
  [String]$StopName
  [Line]$Line
  [DepartureTime[]]$Departures

  Departure([Stop]$Stop, [Line]$Line, [CtsMonitoredVehicleJourney[]]$CtsDepartures) {
    $this.StopName = $Stop.Name
    $Destination = $CtsDepartures[0].DestinationName
    $this.Line = [Line]::new($Line)
    $this.Line.Destinations = @($Destination)
    $this.Departures = [DepartureTime[]]$CtsDepartures.MonitoredCall

    $IsKnowDest = $false
    foreach ($DestName in $Line.Destinations) {
      if ($Destination -like "*$DestName*") {
        $IsKnowDest = $true
        break
      }
    }
    if (-not $IsKnowDest) {
      Write-Warning -Message "Unexpected destination '$Destination' for line: $Line"
    }
  }
}

class Stop {
  [String]$Id
  [String]$Name
  [Line[]]$Lines

  Stop([CtsAnnotatedStopPointStructure]$CtsStop) {
    $this.Init($CtsStop, [Line[]]$CtsStop.Lines)
  }

  Stop([CtsAnnotatedStopPointStructure]$CtsStop, [Line[]]$Lines) {
    $this.Init($CtsStop, $Lines)
  }

  hidden Init([CtsAnnotatedStopPointStructure]$CtsStop, [Line[]]$Lines) {
    $this.Id = $CtsStop.StopPointRef
    $this.Name = $CtsStop.StopName
    $this.Lines = $Lines
  }

  [String] ToString() {
    return $this.Name
  }
}

class Line {
  [String]$Name
  [String]$DisplayName
  [String]$Description
  [String[]]$Destinations
  hidden [Int]$VisibleLength

  Line([CtsAnnotatedLineStructure]$CtsLine) {
    $this.Init($CtsLine, $CtsLine.Destinations.DestinationName)
  }

  Line([CtsAnnotatedLineStructure]$CtsLine, [String[]]$Destinations) {
    $this.Init($CtsLine, $Destinations)
  }

  Line([Line]$Line) {
    $this.Init($Line, @() + $Line.Destinations)
  }

  Line([Line]$Line, [String[]]$Destinations) {
    $this.Init($Line, $Destinations)
  }

  hidden Init([CtsAnnotatedLineStructure]$CtsLine, [String[]]$Destinations) {
    $this.Name = $CtsLine.LineRef
    $this.Description = $CtsLine.LineName
    $this.Destinations = $Destinations

    $PSStyle = $Global:PSStyle
    $Text = ' ' + $this.Name + ' '
    $Background = $PSStyle.Background.FromRgb('0x' + $CtsLine.Extension.RouteColor)
    $Foreground = $PSStyle.Foreground.FromRgb('0x' + $CtsLine.Extension.RouteTextColor)
    $this.DisplayName = $PSStyle.Bold + $Background + $Foreground + $Text + $PSStyle.Reset

    $this.VisibleLength = $Text.Length + 3 + ($this.Destinations -join ';').Length
  }

  hidden Init([Line]$Line, [String[]]$Destinations) {
    $this.Name = $Line.Name
    $this.DisplayName = $Line.DisplayName
    $this.Description = $Line.Description
    $this.Destinations = $Destinations
    $this.VisibleLength = $Line.VisibleLength
  }

  [String] ToString() {
    return $this.DisplayName + " `u{279C} " + ($this.Destinations -join ';')
  }

  [String] PadRight([Int]$TotalWidth) {
    $LineText = [System.Text.StringBuilder]::new($this.ToString())
    if ($TotalWidth -gt $this.VisibleLength) {
      $null = $LineText.Append([Char]' ', $TotalWidth - $this.VisibleLength)
    }
    return $LineText.ToString()
  }
}

class DepartureTime {
  [DateTime]$Time
  [Bool]$Live

  DepartureTime([CtsMonitoredCall]$CtsDepartureTime) {
    $this.Time = $CtsDepartureTime.ExpectedDepartureTime
    $this.Live = $CtsDepartureTime.Extension.IsRealTime
  }

  [String] ToString() {
    return $this.Format($this.Time.ToString('HH:mm:ss'))
  }

  [String] ToString([DateTime]$ReferenceTime) {
    $TimeSpan = $this.Time - $ReferenceTime
    if ($TimeSpan -le [TimeSpan]::Zero) {
      return "`u{21CA} "
    } elseif ($TimeSpan -ge [TimeSpan]::FromHours(1)) {
      return '>1h'
    } else {
      return $this.Format($TimeSpan.ToString('m\:ss'))
    }
  }

  hidden [String] Format([String]$TimeString) {
    $PSStyle = $Global:PSStyle
    if ($this.Live) {
      return $PSStyle.Bold + $TimeString + $PSStyle.BoldOff
    } else {
      return $PSStyle.Underline + $TimeString + $PSStyle.UnderlineOff
    }
  }
}

$Script:ExportTypes += (
  'Stop',
  'Departure'
)
