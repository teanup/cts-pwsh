function Invoke-CtsApi {
  <#
  .SYNOPSIS
  Performs a request to the CTS API
  .DESCRIPTION
  Sends a GET request to the CTS API at the specified endpoint path with a token for authentication.
  The query string is built from the provided hashtable, array values become duplicate parameters.
  .EXAMPLE
  Invoke-CtsApi -Path 'siri/2.0/stoppoints-discovery' -Query @{ IncludeLinesDestinations = $true }
  .EXAMPLE
  Invoke-CtsApi -Path 'siri/2.0/stop-monitoring' -Query @{ MonitoringRef = 'PARLE_05'; MinimumStopVisitsPerLine = 3 }
  .OUTPUTS
  [PSCustomObject] with the response parsed from JSON
  #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param (
    # Path to the CTS API endpoint to query
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String] $Path,

    # Query parameters to append to the request URL
    [Parameter()]
    [AllowNull()]
    [Hashtable] $Query,

    # CTS API token for authentication
    [Parameter()]
    [ValidateNotNull()]
    [SecureString] $Token = (Get-CtsApiToken),

    # Base URL of the CTS API
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String] $BaseUrl = 'https://api.cts-strasbourg.eu/v1/'
  )
  process {
    if ($null -eq $Token) {
      Write-Error -Message 'Missing CTS API token! Usage: Set-CtsApiToken -Token <your-token>' -ErrorAction Stop
    }

    $UriBuilder = [System.UriBuilder]::new($BaseUrl + $Path)
    $QueryString = [System.Web.HttpUtility]::ParseQueryString('')

    foreach ($Param in $Query.GetEnumerator()) {
      # Convert arrays to duplicate query parameters
      if ($Param.Value -is [Array]) {
        foreach ($Value in $Param.Value) {
          $QueryString.Add($Param.Key, $Value)
        }
      } else {
        $QueryString.Add($Param.Key, $Param.Value)
      }
    }
    $UriBuilder.Query = $QueryString.ToString()

    # Token goes in username field
    $RequestParam = @{
      Method         = 'Get'
      Uri            = $UriBuilder.ToString()
      Authentication = 'Basic'
      Credential     = [PSCredential]::new(
        [System.Net.NetworkCredential]::new('', $Token).Password, [SecureString]::new()
      )
    }

    try {
      $Response = Invoke-RestMethod @RequestParam
      $CtsError = ($Response -as [CtsError]).error
      if ($null -eq $CtsError) {
        $Response
      } else {
        Write-Error -Message "API Error: $CtsError" -ErrorAction Stop
      }
    } catch {
      $PSCmdlet.ThrowTerminatingError($_)
    }
  }
}
