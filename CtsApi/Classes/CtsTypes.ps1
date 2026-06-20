<#
.SYNOPSIS
Classes describing simplified CTS API types for this module
#>

class Stop {
  [String]$Id
  [String]$Name
  [Line[]]$Lines

  Stop([CtsAnnotatedStopPointStructure]$CtsStop) {
    $this.Id = $CtsStop.StopPointRef
    $this.Name = $CtsStop.StopName
    $this.Lines = [Line[]]$CtsStop.Lines
  }
}

class Line {
  [String]$Name
  [String]$DisplayName
  [String]$Description
  [String[]]$Destinations

  Line([CtsAnnotatedLineStructure]$CtsLine) {
    $this.Name = $CtsLine.LineRef
    $this.Description = $CtsLine.LineName
    $this.Destinations = $CtsLine.Destinations.DestinationName

    $PSStyle = $Global:PSStyle
    $Text = ' ' + $this.Name + ' '
    $Background = $PSStyle.Background.FromRgb('0x' + $CtsLine.Extension.RouteColor)
    $Foreground = $PSStyle.Foreground.FromRgb('0x' + $CtsLine.Extension.RouteTextColor)
    $this.DisplayName = $PSStyle.Bold + $Background + $Foreground + $Text + $PSStyle.Reset
  }

  [String] ToString() {
    return $this.DisplayName + " `u{279C} " + $this.Destinations
  }
}

$Script:ExportTypes += (
  'Stop',
  'Line'
)
