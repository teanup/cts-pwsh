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
}

class Formatted {
  hidden [String] ToString([Bool]$HasToStringParam, [Object]$ToStringParam) {
    if ($HasToStringParam) {
      return $this.ToString($ToStringParam)
    } else {
      return $this.ToString()
    }
  }

  [Int] VisibleLength() {
    return $this.VisibleLength($false, $null)
  }

  [Int] VisibleLength([Object]$ToStringParam) {
    return $this.VisibleLength($true, $ToStringParam)
  }

  hidden [Int] VisibleLength([Bool]$HasToStringParam, [Object]$ToStringParam) {
    return $this.VisibleLength($this.ToString($HasToStringParam, $ToStringParam))
  }

  hidden [Int] VisibleLength([String]$String) {
    return ($String -replace '\e\[[\d;]+m').Length
  }

  [String] PadLeft([Int]$TotalWidth) {
    return $this.Pad($TotalWidth, $true, $false, $null)
  }

  [String] PadLeft([Int]$TotalWidth, [Object]$ToStringParam) {
    return $this.Pad($TotalWidth, $true, $true, $ToStringParam)
  }

  [String] PadRight([Int]$TotalWidth) {
    return $this.Pad($TotalWidth, $false, $false, $null)
  }

  [String] PadRight([Int]$TotalWidth, [Object]$ToStringParam) {
    return $this.Pad($TotalWidth, $false, $true, $ToStringParam)
  }

  hidden [String] Pad([Int]$TotalWidth, [Bool]$PadLeft, [Bool]$HasToStringParam, [Object]$ToStringParam) {
    $String = $this.ToString($HasToStringParam, $ToStringParam)
    $LenDiff = $TotalWidth - $this.VisibleLength($String)
    if ($LenDiff -le 0) {
      return $String
    } elseif ($PadLeft) {
      return (' ' * $LenDiff + $String)
    } else {
      return ($String + ' ' * $LenDiff)
    }
  }
}

class Line : Formatted {
  [String]$Name
  [String]$DisplayName
  [String]$Description
  [String[]]$Destinations

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
  }

  hidden Init([Line]$Line, [String[]]$Destinations) {
    $this.Name = $Line.Name
    $this.DisplayName = $Line.DisplayName
    $this.Description = $Line.Description
    $this.Destinations = $Destinations
  }

  [String] ToString() {
    return $this.DisplayName + " `u{279C} " + ($this.Destinations -join ';')
  }
}

class DepartureTime : Formatted {
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
      return $Global:PSStyle.Bold + "`u{2B63}`u{2B63}" + $Global:PSStyle.BoldOff
    }
    $TimeText = '{0}:{1:d2}' -f [Math]::Floor($TimeSpan.TotalMinutes), $TimeSpan.Seconds
    return $this.Format($TimeText)
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
