<#
.SYNOPSIS
Imports classes and functions, exports types and pre-loads cache
#>

Set-Variable -Name ModulePath -Value $PSScriptRoot -Option Constant -Visibility Private -Scope Local

# Dot-source PowerShell scripts
$Classes = Get-ChildItem -Path ($PSScriptRoot | Join-Path -ChildPath 'Classes') -Include '*.ps1' -Recurse
$Functions = Get-ChildItem -Path ($PSScriptRoot | Join-Path -ChildPath 'Functions') -Include '*.ps1' -Recurse
@($Classes) + @($Functions) | ForEach-Object { . $_.FullName }

# Export custom types
$ExportableTypes = @(
  [Stop],
  [Departure]
)
$TypeAcceleratorsClass = [PSCustomObject].Assembly.GetType('System.Management.Automation.TypeAccelerators')
$ExportableTypes = $ExportableTypes | ForEach-Object {
  if ($_.FullName -notin $TypeAcceleratorsClass::Get.Keys) {
    $TypeAcceleratorsClass::Add($_.FullName, $_)
    $_
  } else {
    Write-Warning -Message "StrasbourgTransport: Type accelerator already exists for type '$($_.FullName)'"
  }
}
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
  $null = $ExportableTypes | ForEach-Object { $TypeAcceleratorsClass::Remove($_.FullName) }
}.GetNewClosure()

# Check CTS API token
Set-Variable -Name CtsApiToken -Value $CtsApiKey -Visibility Private -Scope Local
if ($null -eq (Get-CtsApiToken)) {
  Write-Warning -Message 'CTS API token not found. Set your token with: Set-CtsApiToken -Token <your-token>'
  Write-Information -MessageData ('Using StrasbourgTransport for the first time? ' +
    'Check the guide: https://github.com/teanup/cts-pwsh#getting-started') -InformationAction Continue
}

# Pre-load stop cache
try { Update-CtsStopCache } catch {}
