function Get-CtsDeparture {
  <#
  .SYNOPSIS
  Retrieves the next departures at the specified CTS stops
  .DESCRIPTION
  TODO
  .EXAMPLE
  Get-CtsDeparture TODO
  .EXAMPLE
  Get-CtsDeparture TODO
  .OUTPUTS
  Departure objects for the relevant stops, lines and destinations
  #>
  [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Filters')]
  [OutputType([Departure])]
  param (
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

    # TODO
    [Parameter(ParameterSetName = 'Filters')]
    [Switch] $Strict,

    # CTS stop objects to use
    [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Object')]
    [AllowNull()]
    [Stop[]] $StopObject,

    # Maximum number of departures per line, stop and destination
    [Parameter()]
    [ValidateRange(1, 8)]
    [Int] $MaxDepartures = 3,

    # Whether to bypass the stop and departure caches
    [Parameter(DontShow)]
    [Switch] $Force,

    # Whether to avoid updating the stop cache
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

    try {
      # Cache 1 extra departure as backup
      Update-CtsDepartureCache -StopId $Stops.Id -MinDepartures ($MaxDepartures + 1) -Force:$Force
    } catch {
      $PSCmdlet.ThrowTerminatingError($_)
    }

    $NotBefore = [DateTime]::Now.AddSeconds(-10)
    $Stops | ForEach-Object {
      $StopName = $_.Name
      $Departures = [DepartureCache]::Instance.Departures[$_.Id] | Group-Object -Property Line
      $_.Lines | ForEach-Object {
        $StopLine = $_
        $Departures.Where({ $_.Name -eq $StopLine.Name }).Group | Where-Object {
          $_.Destination -in $StopLine.Destinations
        } | ForEach-Object {
          [Departure]@{
            Stop  = $StopName
            Line  = [Line]@{
              LineInfo     = $StopLine.LineInfo
              Destinations = $_.Destination
            }
            Times = $_.Times | Where-Object { $_.Time -ge $NotBefore } | Select-Object -First $MaxDepartures
          }
        }
      }
    } | Sort-Object -Property Stop, Line -Stable
  }
}
