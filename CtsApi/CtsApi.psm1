<#
.SYNOPSIS
Imports classes, functions and defines module-scope variables
#>

$Classes = Get-ChildItem -Path ($PSScriptRoot | Join-Path -ChildPath 'Classes') -Include '*.ps1' -Recurse
$Functions = Get-ChildItem -Path ($PSScriptRoot | Join-Path -ChildPath 'Functions') -Include '*.ps1' -Recurse
@($Classes) + @($Functions) | ForEach-Object { . $_.FullName }

# Set your CTS API token here
New-Variable -Name CtsApiToken -Value '' -Visibility Private -Scope Script
