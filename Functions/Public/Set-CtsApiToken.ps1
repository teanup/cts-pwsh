function Set-CtsApiToken {
  <#
  .SYNOPSIS
  Stores the CTS API token securely in the module directory
  .DESCRIPTION
  Saves the given API token in a hidden file (.cts-api.xml) in the module directory. On Windows the token is
  encrypted with the machine and user keys.
  .EXAMPLE
  Set-CtsApiToken -Token '<your-token>'
  #>
  [CmdletBinding(SupportsShouldProcess,
    HelpUri = 'https://github.com/teanup/cts-pwsh/blob/main/.docs/StrasbourgTransport/Set-CtsApiToken.md#Set-CtsApiToken')]
  [OutputType([Void])]
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String] $Token
  )
  process {
    try {
      $Script:CtsApiToken = [System.Net.NetworkCredential]::new('', $Token).SecurePassword
      $TokenFileName = '.cts-api.xml'

      # Use current module path by default
      $Path = $Script:ModulePath | Join-Path -ChildPath $TokenFileName

      # Try parent module path, stable through versions if using Install-PSResource
      $ParentPath = $Script:ModulePath | Split-Path -Parent
      if (($ParentPath | Split-Path -Leaf) -eq 'StrasbourgTransport') {
        $Path = $ParentPath | Join-Path -ChildPath $TokenFileName
      }

      Write-Verbose -Message "Saving CTS API token to: $Path"
      $Script:CtsApiToken | Export-Clixml -Path $Path -ErrorAction Stop

      # Hide item (no effect on Linux)
      $TokenItem = Get-Item -Path $Path -Force
      if ($null -ne $TokenItem.Attributes) {
        $TokenItem.Attributes = $TokenItem.Attributes -bor [System.IO.FileAttributes]::Hidden
      }
    } catch {
      $PSCmdlet.ThrowTerminatingError($_)
    }
  }
}
