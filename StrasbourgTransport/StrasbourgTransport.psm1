<#
.SYNOPSIS
Imports classes & functions and defines module-scope variables
#>

$Script:ExportTypes = [String[]]@()

# Dot-source PowerShell scripts
$Classes = Get-ChildItem -Path ($PSScriptRoot | Join-Path -ChildPath 'Classes') -Include '*.ps1' -Recurse
$Functions = Get-ChildItem -Path ($PSScriptRoot | Join-Path -ChildPath 'Functions') -Include '*.ps1' -Recurse
@($Classes) + @($Functions) | ForEach-Object { . $_.FullName }

# Export custom types
$TypeAccelerators = [PSCustomObject].Assembly.GetType('System.Management.Automation.TypeAccelerators')
foreach ($Type in $Script:ExportTypes) {
  if ($Type -as [System.Type]) {
    $null = $TypeAccelerators::Add($Type, $Type -as [System.Type])
  } else {
    Write-Warning -Message "Failed to export unknown type: $Type"
  }
}

# CTS API token
Set-Variable -Name CtsApiToken -Value '' -Option Constant -Visibility Private

# Cache configuration
$Script:StopCacheValidFor = [TimeSpan]::FromDays(3)
$Script:DepartureCacheValidFor = [TimeSpan]::FromSeconds(30)
$Script:SafeRequestThreshold = 4
