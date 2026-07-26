<#
.SYNOPSIS
Classes for this module describing CTS stops, lines, departures and other helpers
#>

using namespace System
using namespace System.Collections.Generic
using namespace System.Collections.Concurrent
using namespace System.Management.Automation

# Base class for objects whose string representation includes ANSI escape codes
class Formatted {
  [Int] VisibleLength() {
    return [Formatted]::VisibleLength($this.ToString())
  }

  [Int] VisibleLength([Object]$ToStringParam) {
    return [Formatted]::VisibleLength($this.ToString($ToStringParam))
  }

  hidden static [Int] VisibleLength([String]$String) {
    return ($String -replace '\e\[[\d;]+m').Length
  }

  [String] PadLeft([Int]$TotalWidth) {
    return [Formatted]::Pad($this.ToString(), $TotalWidth, $true)
  }

  [String] PadLeft([Int]$TotalWidth, [Object]$ToStringParam) {
    return [Formatted]::Pad($this.ToString($ToStringParam), $TotalWidth, $true)
  }

  [String] PadRight([Int]$TotalWidth) {
    return [Formatted]::Pad($this.ToString(), $TotalWidth, $false)
  }

  [String] PadRight([Int]$TotalWidth, [Object]$ToStringParam) {
    return [Formatted]::Pad($this.ToString($ToStringParam), $TotalWidth, $false)
  }

  hidden static [String] Pad([String]$Text, [Int]$TotalWidth, [Bool]$PadLeft) {
    $PadLength = $TotalWidth - [Formatted]::VisibleLength($Text)
    if ($PadLength -le 0) {
      return $Text
    } elseif ($PadLeft) {
      return (' ' * $PadLength + $Text)
    } else {
      return ($Text + ' ' * $PadLength)
    }
  }
}

# Serializable snapshot of the stop cache for disk persistence
class StopFileCache {
  [DateTime] $ValidUntil
  [StopInfo[]] $Stops
  [LineRawInfo[]] $Lines
}

# Raw line data from the API response
class LineRawInfo {
  [String] $Id
  [String] $Name
  [String] $Color
  [Bool] $Dark
  [List[Destination]] $Destinations
}

# A destination served by a line at a given set of stops
class Destination {
  [String] $Line
  [Byte] $Direction
  [String] $Name
  [List[String]] $Stops
}

# Singleton in-memory cache of all stops, lines and destinations
class StopCache {
  [DateTime] $ValidUntil
  [ConcurrentDictionary[String, StopInfo]] $Stops
  [ConcurrentDictionary[String, LineInfo]] $Lines
  [ConcurrentDictionary[String, List[Destination]]] $Destinations
  [Bool] $Ready
  hidden static [StopCache] $StopCache = [StopCache]::new()
  static [StopCache] $Instance = [StopCache]::Get()

  hidden StopCache() {
    $this.Init(0)
  }

  hidden static [StopCache] Get() {
    return [StopCache]::StopCache
  }

  Init([DateTime]$ValidUntil) {
    $this.ValidUntil = $ValidUntil
    $this.Ready = $false
    $this.Stops = [ConcurrentDictionary[String, StopInfo]]::new()
    $this.Lines = [ConcurrentDictionary[String, LineInfo]]::new()
    $this.Destinations = [ConcurrentDictionary[String, List[Destination]]]::new()
  }
}

# Display metadata for a line
class LineInfo {
  [String] $Name
  [String] $DisplayName
  [String] $Description

  LineInfo([LineRawInfo]$Line) {
    $this.Name = $Line.Id
    $this.Description = $Line.Name

    $PSStyle = [PSStyle]::Instance
    $Background = $PSStyle.Background.FromRgb('0x' + $Line.Color)
    $Foreground = $Line.Dark ? $PSStyle.Foreground.White : $PSStyle.Foreground.Black
    $this.DisplayName = $PSStyle.Bold + $Background + $Foreground + ' ' + $this.Name + ' ' + $PSStyle.Reset
  }
}

# A transport line with its display label and destinations
class Line : Formatted {
  [String] $Name
  [String] $DisplayName
  [String] $Description
  [String[]] $Destinations
  hidden [LineInfo] $LineInfo
  hidden static [Hashtable] $DynamicProperty = @{
    Name        = { $this.LineInfo.Name }
    DisplayName = { $this.LineInfo.DisplayName }
    Description = { $this.LineInfo.Description }
  }

  hidden static Line() {
    $UpdateParam = @{
      TypeName   = [Line].Name
      MemberType = 'ScriptProperty'
      Force      = $true
      WhatIf     = $false
      Confirm    = $false
    }
    [Line]::DynamicProperty.GetEnumerator() | ForEach-Object {
      Update-TypeData @UpdateParam -MemberName $_.Key -Value $_.Value
    }
  }

  [String] ToString() {
    return $this.DisplayName + " `u{279C} " + ($this.Destinations -join ';')
  }
}

# Raw stop data from the API response
class StopInfo {
  [String] $Id
  [String] $Name
}

# A physical stop with its associated lines
class Stop {
  [String] $Id
  [String] $Name
  [Line[]] $Lines
  hidden [StopInfo] $StopInfo
  hidden static [Hashtable] $DynamicProperty = @{
    Id   = { $this.StopInfo.Id }
    Name = { $this.StopInfo.Name }
  }

  hidden static Stop() {
    $UpdateParam = @{
      TypeName   = [Stop].Name
      MemberType = 'ScriptProperty'
      Force      = $true
      WhatIf     = $false
      Confirm    = $false
    }
    [Stop]::DynamicProperty.GetEnumerator() | ForEach-Object {
      Update-TypeData @UpdateParam -MemberName $_.Key -Value $_.Value
    }
  }

  [String] ToString() {
    return $this.Name + ' (' + ($this.Lines.Name -join ';') + ')'
  }
}

# Singleton in-memory cache of real-time departures per stop
class DepartureCache {
  [ConcurrentDictionary[String, List[DepartureInfo]]] $Departures
  hidden static [DepartureCache] $DepartureCache = [DepartureCache]::new()
  static [DepartureCache] $Instance = [DepartureCache]::Get()

  hidden DepartureCache() {
    $this.Departures = [ConcurrentDictionary[String, List[DepartureInfo]]]::new()
  }

  hidden static [DepartureCache] Get() {
    return [DepartureCache]::DepartureCache
  }
}

# Cached departure data for a single line-destination pair
class DepartureInfo {
  [DateTime] $ValidUntil
  [String] $Line
  [String] $Destination
  [DepartureTime[]] $Times
}

# A departure event for a stop, line and destination
class Departure {
  [String] $Stop
  [Line] $Line
  [DepartureTime[]] $Times
}

# A single departure time, either live or scheduled
class DepartureTime : Formatted {
  [DateTime] $Time
  [Bool] $Live

  [String] ToString() {
    return $this.ToString(0)
  }

  [String] ToString([DateTime]$ReferenceTime) {
    if ($ReferenceTime -eq 0) {
      $TimeText = $this.Time.ToString('HH:mm:ss')
    } else {
      $TimeDiff = $this.Time - $ReferenceTime
      if ($TimeDiff -le [TimeSpan]::FromSeconds(10)) {
        $TimeText = "`u{2B63}`u{2B63}"
      } else {
        $TimeText = '{0}:{1:d2}' -f [Math]::Floor($TimeDiff.TotalMinutes), $TimeDiff.Seconds
      }
    }

    $PSStyle = [PSStyle]::Instance
    if ($this.Live) {
      return $PSStyle.Bold + $TimeText + $PSStyle.BoldOff
    } else {
      return $PSStyle.Underline + $TimeText + $PSStyle.UnderlineOff
    }
  }
}
