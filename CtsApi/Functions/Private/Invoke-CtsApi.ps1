<#
.SYNOPSIS
Performs a request to the CTS API
#>
function Invoke-CtsApi {
  [OutputType([PSCustomObject])]
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][String]$Path,
    [Hashtable]$Query = $null,
    [String]$Token = $Script:CtsApiToken,
    [String]$BaseUrl = 'https://api.cts-strasbourg.eu/v1/'
  )
  process {
    if ([String]::IsNullOrEmpty($Token)) {
      throw 'Provide an API token to use the CTS API'
    }

    $Response = Invoke-RestMethod -Uri ($BaseUrl + $Path) -Body $Query -Method Get -Headers @{
      Authorization = "Basic $(
        [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Token + ':'))
      )"
    }

    if ($Response.Error) {
      throw "Error: $($Response.Error)"
    }

    return $Response
  }
}
