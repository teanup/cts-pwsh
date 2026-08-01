function Get-CtsApiToken {
  <#
  .SYNOPSIS
  Loads the CTS API token from the module directory
  .DESCRIPTION
  Reads the hidden token file (.cts-api.xml) from the module directory or its parent and returns the token as a
  SecureString, or $null if no token is found.
  .EXAMPLE
  Get-CtsApiToken
  .OUTPUTS
  [SecureString] containing the CTS API token, can be null if not found
  #>
  [CmdletBinding()]
  [OutputType([SecureString])]
  param ()
  process {
    if ($null -eq $Script:CtsApiToken) {
      $TokenFileName = '.cts-api.xml'
      # Test current module path and parent module path
      $TokenPath = @(
        ($Script:ModulePath | Join-Path -ChildPath $TokenFileName),
        ($Script:ModulePath | Split-Path -Parent | Join-Path -ChildPath $TokenFileName)
      )

      foreach ($Path in $TokenPath) {
        [SecureString]$Token = $null

        if (Test-Path -Path $Path) {
          try {
            $Token = Import-Clixml -Path $Path
            if ($Token.Length -eq 0) {
              Write-Verbose -Message "CtsApi: Empty token at: $Path"
            }
          } catch {
            Write-Verbose -Message "CtsApi: Failed to load token from '$Path': $_"
          }
        } else {
          Write-Verbose -Message "CtsApi: No token found at: $Path"
        }

        if ($Token.Length -gt 0) {
          $Script:CtsApiToken = $Token
          break
        }
      }
    }

    $Script:CtsApiToken
  }
}
