<#
.SYNOPSIS
Imports classes and functions, defines module-scope variables
#>

param(
  [String] $CtsApiKey
)

# Dot-source PowerShell scripts
$Classes = Get-ChildItem -Path ($PSScriptRoot | Join-Path -ChildPath 'Classes') -Include '*.ps1' -Recurse
$Functions = Get-ChildItem -Path ($PSScriptRoot | Join-Path -ChildPath 'Functions') -Include '*.ps1' -Recurse
@($Classes) + @($Functions) | ForEach-Object { . $_.FullName }

# Export custom types
$ExportableTypes = [System.Collections.Generic.List[Type]]@(
  [Stop],
  [Departure]
)
$TypeAcceleratorsClass = [PSCustomObject].Assembly.GetType('System.Management.Automation.TypeAccelerators')
$ExistingTypeAccelerators = $TypeAcceleratorsClass::Get
foreach ($Type in $ExportableTypes) {
  if ($Type.FullName -in $ExistingTypeAccelerators.Keys) {
    Write-Warning -Message "Type accelerator already exists for type '$($Type.FullName)'"
    $null = $ExportableTypes.Remove($Type.FullName)
  } else {
    $null = $TypeAcceleratorsClass::Add($Type.FullName, $Type)
  }
}
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
  foreach ($Type in $ExportableTypes) {
    $null = $TypeAcceleratorsClass::Remove($Type.FullName)
  }
}.GetNewClosure()


# CTS API token
$CtsApiKeyPath = $PSScriptRoot | Join-Path -ChildPath 'cts-api.key'
if ($CtsApiKey) {
  Set-Content -Path $CtsApiKeyPath -Value $CtsApiKey -Force
} else {
  $CtsApiKey = Get-Content -Path $CtsApiKeyPath | Select-Object -First 1
}
if (-not $CtsApiKey) {
  Write-Warning -Message 'Missing CTS API token!'
  Write-Warning -Message "Set your token in '$CtsApiKeyPath' or import the module with: -ArgumentList <your-token>"
}
Set-Variable -Name CtsApiToken -Value $CtsApiKey -Option Constant -Visibility Private -Scope Local

# Cache configuration
$Script:StopCacheValidFor = [TimeSpan]::FromDays(3)
