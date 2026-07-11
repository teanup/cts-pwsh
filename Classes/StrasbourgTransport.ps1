<#
.SYNOPSIS
Classes describing simplified CTS types for this module
#>

using namespace System
using namespace System.Collections.Generic
using namespace System.Management.Automation

class Formatted {
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
    $Text = $this.ToString($HasToStringParam, $ToStringParam)
    $LenDiff = $TotalWidth - $this.VisibleLength($Text)
    if ($LenDiff -le 0) {
      return $Text
    } elseif ($PadLeft) {
      return (' ' * $LenDiff + $Text)
    } else {
      return ($Text + ' ' * $LenDiff)
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

  hidden [String] ToString([Bool]$HasToStringParam, [Object]$ToStringParam) {
    if ($HasToStringParam) {
      return $this.ToString($ToStringParam)
    } else {
      return $this.ToString()
    }
  }
}

class StopData {
  [String] $Id
  [String] $Name
  [Dictionary[String, String[]]] $Lines
}

class Stop {
  [String] $Id
  [String] $Name
  [Line[]] $Lines

  Stop([StopData]$StopData, [Line[]]$Lines) {
    $this.Id = $StopData.Id
    $this.Name = $StopData.Name
    $this.Lines = $Lines
  }

  Stop([StopData]$StopData, [Dictionary[String, LineData]]$LineCache) {
    $this.Id = $StopData.Id
    $this.Name = $StopData.Name
    $this.Lines = $StopData.Lines.GetEnumerator().ForEach({ [Line]::new($LineCache.($_.Key), $_.Value) })
  }

  [String] ToString() {
    return "$($this.Name) ($($this.Lines.Name -join ';'))"
  }
}

class LineData {
  [String] $Name
  [String] $Description
  [String] $Background
  [String] $Foreground
}

class Line : Formatted {
  [String] $Name
  [String] $DisplayName
  [String] $Description
  [String[]] $Destinations

  Line([LineData]$LineData, [String[]]$Destinations) {
    $this.Name = $LineData.Name
    $this.Description = $LineData.Description
    $this.Destinations = $Destinations

    $PSStyle = [PSStyle]::Instance
    $Background = $PSStyle.Background.FromRgb('0x' + $LineData.Background)
    $Foreground = $PSStyle.Foreground.FromRgb('0x' + $LineData.Foreground)
    $this.DisplayName = $PSStyle.Bold + $Background + $Foreground + ' ' + $this.Name + ' ' + $PSStyle.Reset
  }

  Line([Line]$Line, [String[]]$Destinations) {
    $this.Name = $Line.Name
    $this.DisplayName = $Line.DisplayName
    $this.Description = $Line.Description
    $this.Destinations = $Destinations
  }

  [String] ToString() {
    return $this.DisplayName + " `u{279C} " + ($this.Destinations -join ';')
  }
}

class Departure {
  [String] $StopName
  [Line] $Line
  [DepartureTime[]] $Times
}

class DepartureTime : Formatted {
  [DateTime] $Time
  [Bool] $Live

  [String] ToString() {
    return $this.ToString(0)
  }

  [String] ToString([DateTime]$ReferenceTime) {
    $PSStyle = [PSStyle]::Instance

    if ($ReferenceTime -eq 0) {
      $TimeText = $this.Time.ToString('HH:mm:ss')
    } else {
      $TimeSpan = $this.Time - $ReferenceTime
      if ($TimeSpan -le [TimeSpan]::FromSeconds(10)) {
        return $PSStyle.Bold + "`u{2B63}`u{2B63}" + $PSStyle.BoldOff
      }
      $TimeText = '{0}:{1:d2}' -f [Math]::Floor($TimeSpan.TotalMinutes), $TimeSpan.Seconds
    }

    if ($this.Live) {
      return $PSStyle.Bold + $TimeText + $PSStyle.BoldOff
    } else {
      return $PSStyle.Underline + $TimeText + $PSStyle.UnderlineOff
    }
  }
}

class StopCache {
  [DateTime] $ValidUntil
  [Dictionary[String, StopData]] $Stops
  [Dictionary[String, LineData]] $Lines
}

class DepartureCache {
  [DateTime] $ValidUntil
  [DepartureData[]] $Departures
}

class DepartureData {
  [String] $StopId
  [String] $LineName
  [String] $Destination
  [DepartureTime[]] $Times
}
