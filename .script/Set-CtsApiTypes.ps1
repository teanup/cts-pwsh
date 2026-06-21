<#
.SYNOPSIS
Parses the CTS API documentation to define compatible PowerShell types
#>
[CmdletBinding()]
[OutputType([Void])]
param(
  [Parameter(Mandatory = $false)]
  [String]$Path,

  [Parameter(Mandatory = $false)]
  [String]$OpenApiUrl = 'https://api.cts-strasbourg.eu/v1/swagger.json',

  [Parameter(Mandatory = $false)]
  [Switch]$ExportTypes
)

$ErrorActionPreference = 'Stop'
$TypePrefix = 'Cts'

function Get-CtsApiPropertyType {
  [CmdletBinding()]
  [OutputType([String])]
  param(
    [Parameter(Mandatory = $true)]
    [PSCustomObject]$InputObject
  )
  process {
    if ($InputObject.type) {
      switch ($InputObject.type) {
        'string' {
          switch ($InputObject.format) {
            'date-time' {
              return 'DateTime'
            }
            default {
              return 'String'
            }
          }
        }
        'integer' {
          switch ($InputObject.format) {
            'int32' {
              return 'Int'
            }
            default {
              return 'Int'
            }
          }
        }
        'number' {
          switch ($InputObject.format) {
            'double' {
              return 'Double'
            }
            default {
              return 'Double'
            }
          }
        }
        'boolean' {
          return 'Bool'
        }
        'array' {
          return "$(Get-CtsApiPropertyType -InputObject $InputObject.items)[]"
        }
        default {
          Write-Error -Message "Unknown property type: $_"
          return
        }
      }
    } elseif ($InputObject.'$ref') {
      if ($InputObject.'$ref' -match '#/components/schemas/(?<type>\w+)') {
        return "$TypePrefix$($Matches.type)"
      }
    } else {
      Write-Error -Message "Unknown property type: $($InputObject | ConvertTo-Json -Compress)"
      return
    }
  }
}

if ([String]::IsNullOrEmpty($Path)) {
  $Path = Split-Path -Path $PSScriptRoot -Parent | Join-Path -ChildPath 'CtsApi' -AdditionalChildPath 'Classes', 'CtsApi.ps1'
  Write-Verbose -Message "Empty path for CTS API types, using default: $Path"
}

if (-not (Test-Path -Path $Path -PathType Leaf -IsValid)) {
  throw "Invalid path for CTS API types: $Path"
}

$OpenApi = Invoke-RestMethod -Uri $OpenApiUrl
$CtsTypes = $OpenApi.components.schemas
if ($null -eq $CtsTypes) {
  throw "Invalid OpenAPI format from: $OpenApiUrl"
}

$null = New-Item -Path $Path -ItemType File -Force -Value @"
<#
.SYNOPSIS
Classes describing types returned by the CTS API

.LINK
$OpenApiUrl
#>

"@

$TypeNameList = @()

($CtsTypes | Get-Member -View Extended).Name | ForEach-Object {
  $TypeObj = $CtsTypes.$_
  $TypeName = "$TypePrefix$_"
  switch ($TypeObj.type) {
    'object' {
      if ($TypeObj.properties) {
        $PropertyList = ($TypeObj.properties | Get-Member -View Extended).Name | ForEach-Object {
          $PropertyType = Get-CtsApiPropertyType -InputObject $TypeObj.properties.$_
          return "[$PropertyType]`$$_"
        }
        $PropertyText = $PropertyList -join "`n  "
        Add-Content -Path $Path -Value "`nclass $TypeName {`n  $PropertyText`n}"
        $TypeNameList += $TypeName
      } else {
        Write-Verbose -Message "Ignoring API type with no properties: $TypeName"
      }
    }
    'string' {
      if ($TypeObj.enum) {
        $EnumValues = $TypeObj.enum -join "`n  "
        Add-Content -Path $Path -Value "`nenum $TypeName {`n  $EnumValues`n}"
        $TypeNameList += $TypeName
      } else {
        Write-Warning -Message "Unknown base type for API type: $TypeName"
      }
    }
    default {
      Write-Warning -Message "Unknown API base type: $($TypeObj.type)"
    }
  }
}

if ($ExportTypes -and $TypeNameList) {
  $TypeNameText = $TypeNameList -join "',`n  '"
  Add-Content -Path $Path -Value "`n`$Script:ExportTypes += (`n  '$TypeNameText'`n)"
}

Write-Host -Object "Defined $($TypeNameList.Count) CTS API types in: $Path"
