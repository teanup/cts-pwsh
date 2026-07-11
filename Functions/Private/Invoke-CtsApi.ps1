function Invoke-CtsApi {
  <#
  .SYNOPSIS
  Performs a request to the CTS API
  .DESCRIPTION
  TODO
  .EXAMPLE
  Invoke-CtsApi TODO
  .EXAMPLE
  Invoke-CtsApi TODO
  .OUTPUTS
  Response parsed as a custom object
  #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param (
    # Path to the CTS api endpoint to query
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String] $Path,

    # Optional query parameters to append to the request
    [Parameter()]
    [AllowNull()]
    [Hashtable] $Query,

    # CTS API token, usually set at module import
    [Parameter()]
    [ValidateNotNull()]
    [String] $Token = $Script:CtsApiToken,

    # Base URL of the CTS API
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String] $BaseUrl = 'https://api.cts-strasbourg.eu/v1/'
  )
  process {
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

    $RequestParam = @{
      Method         = 'Get'
      Uri            = $UriBuilder.ToString()
      Authentication = 'Basic'
      Credential     = [PSCredential]::new($Token, [SecureString]::new())
    }
    $Response = Invoke-RestMethod @RequestParam

    try {
      $CtsError = [CtsError]$Response
      return $CtsError.error
    } catch {
      return $Response
    }
  }
}
