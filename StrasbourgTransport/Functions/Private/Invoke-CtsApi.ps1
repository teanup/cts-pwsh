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
  param(
    # Path to the CTS api endpoint to query
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String] $Path,

    # Query parameters or HTTP body
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
    $RequestParam = @{
      Method         = 'Get'
      Uri            = $BaseUrl + $Path
      Body           = $Query
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
