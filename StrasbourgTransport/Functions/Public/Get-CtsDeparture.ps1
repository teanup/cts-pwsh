<#
.SYNOPSIS
Retrieves the next departure at the specified CTS stops
#>
function Get-CtsDeparture {
  [CmdletBinding(DefaultParameterSetName = 'Filters')]
  [OutputType([Departure])]
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

    [Parameter(Mandatory = $false, DontShow)]
    [Switch]$Force,

    [Parameter(Mandatory = $false, ParameterSetName = 'Filters', DontShow)]
    [Switch]$NoCacheFile
  )
  process {
    if ($PSCmdlet.ParameterSetName -eq 'Filters') {
      $FindParam = @{
        Line        = $Line
        Stop        = $Stop
        Destination = $Destination
        Force       = $Force
        NoCacheFile = $NoCacheFile
      }
      $StopObject = Find-CtsStop @FindParam
    }

    if ($StopObject.Count -gt $Script:SafeRequestThreshold) {
      if (-not $PSCmdlet.ShouldContinue('Proceed with requests?', "You are about to request departures for $($StopObject.Count) CTS stops. Excessive API usage could be flagged as spam.")) {
        Write-Verbose "Aborted departure requests for $($StopObject.Count) stops"
      }
    }

    $StopObject | ForEach-Object {
      $CurStop = $_
      $CtsDepartures = Get-CtsDepartureData -StopId $CurStop.Id -MinDepartures ($Count + 1) -Force:$Force

      $CurStop.Lines | ForEach-Object {
        $CurLine = $_

        # Include same-line departures with different destinations to support CTS network changes
        $CtsDepartures.MonitoredVehicleJourney | Where-Object {
          $_.LineRef -eq $CurLine.Name
        } | Group-Object -Property DestinationName | ForEach-Object {
          $Departures = [Departure]::new($CurStop, $CurLine, $_.Group)

          # Filter expired departures
          $Departures.Departures = $Departures.Departures | Where-Object {
            ([DateTime]::Now - $_.Time) -le [TimeSpan]::FromSeconds(10)
          } | Select-Object -First $Count

          return $Departures
        }
      }
    }
  }
}
