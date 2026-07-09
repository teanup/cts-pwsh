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
  [CmdletBinding(DefaultParameterSetName = 'Filters')]
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
    switch ($PSCmdlet.ParameterSetName) {
      'Filters' {
        $FindParam = @{
          Line        = $Line
          Stop        = $Stop
          Destination = $Destination
          Force       = $Force
          NoCacheFile = $NoCacheFile
        }
        $StopObject = Find-CtsStop @FindParam
      }
    }

    if ($null -ne $StopObject) {
      $StopObject | ForEach-Object { $Stops.Add([Stop]$_) }
    }
  }
  end {
    if ($Stops.Count -eq 0) {
      Write-Verbose -Message 'CtsDeparture: No stop found with requested filters'
      return
    }

    # Cache 1 extra stop as backup
    $DepartureData = Get-CtsDepartureData -StopId $Stops.Id -MinDepartures ($MaxDepartures + 1) -Force:$Force

    $NotBefore = [DateTime]::Now.AddSeconds(-10)
    $Stops | ForEach-Object {
      $StopId = $_.Id
      $StopName = $_.Name
      $StopDepartureData = $DepartureData | Where-Object { $_.StopId -eq $StopId }
      $_.Lines | ForEach-Object {
        $StopLine = $_
        # Include all destinations for given line to support CTS network changes
        $StopDepartureData | Where-Object { $_.LineName -eq $StopLine.Name } | ForEach-Object {
          [Departure]@{
            StopName = $StopName
            Line     = [Line]::new($StopLine, @($_.Destination))
            Times    = $_.Times | Where-Object { $_.Time -ge $NotBefore } | Select-Object -First $MaxDepartures
          }
        }
      }
    }
  }
}
