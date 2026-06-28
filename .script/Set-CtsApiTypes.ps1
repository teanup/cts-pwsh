<#
.SYNOPSIS
Parses the CTS API documentation to define compatible PowerShell types
#>

[CmdletBinding()]
[OutputType([Void])]
param(
  # Path to the PowerShell script where CTS API types should be defined
  [Parameter()]
  [String] $Path,

  # URL to the CTS API specifications (OpenAPI JSON)
  [Parameter()]
  [String] $OpenApiUrl = 'https://api.cts-strasbourg.eu/v1/swagger.json'
)

$ErrorActionPreference = 'Stop'
$TypePrefix = 'Cts'

function Get-CtsApiPropertyType {
  <#
  .SYNOPSIS
  Converts a property type's specifications into PowerShell a type name
  #>
  [CmdletBinding()]
  [OutputType([String])]
  param(
    # Raw specifications of an object type property
    [Parameter(Mandatory)]
    [PSCustomObject] $InputObject
  )
  process {
    if ($InputObject.type) {
      switch ($InputObject.type) {
        'string' {
          switch ($InputObject.format) {
            'date-time' {
              'DateTime'
              break
            }
            default {
              'String'
              break
            }
          }
        }
        'integer' {
          switch ($InputObject.format) {
            'int32' {
              'Int'
              break
            }
          }
        }
        'number' {
          switch ($InputObject.format) {
            'double' {
              'Double'
              break
            }
          }
        }
        'boolean' {
          'Bool'
          break
        }
        'array' {
          $ItemType = Get-CtsApiPropertyType -InputObject $InputObject.items
          if ($ItemType) {
            "$ItemType[]"
          }
          break
        }
      }
    } elseif ($InputObject.'$ref') {
      if ($InputObject.'$ref' -match '#/components/schemas/(?<type>\w+)') {
        "$TypePrefix$($Matches.type)"
      }
    }
  }
}

if ([String]::IsNullOrEmpty($Path)) {
  $Path = Join-Path -Path $PSScriptRoot -ChildPath 'CtsApi.ps1'
  Write-Verbose -Message "Using default path for CTS API types: $Path"
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

$TypeNameList = [System.Collections.Generic.List[String]]::new()

($CtsTypes | Get-Member -View Extended).Name | ForEach-Object {
  $TypeObj = $CtsTypes.$_
  $TypeName = "$TypePrefix$_"
  switch ($TypeObj.type) {
    'object' {
      if ($TypeObj.properties) {
        $PropertyList = ($TypeObj.properties | Get-Member -View Extended).Name | ForEach-Object {
          $Property = $TypeObj.properties.$_
          $PropertyType = Get-CtsApiPropertyType -InputObject $Property
          if ($PropertyType) {
            "[$PropertyType] `$$_"
          } else {
            Write-Warning -Message "Invalid property type for '$TypeName': $($Property | ConvertTo-Json -Compress)"
          }
        }
        $PropertyText = $PropertyList -join "`n  "
        Add-Content -Path $Path -Value "`nclass $TypeName {`n  $PropertyText`n}"
        $TypeNameList.Add($TypeName)
      } else {
        Write-Warning -Message "Ignoring object type '$TypeName' with no properties"
      }
    }
    'string' {
      if ($TypeObj.enum) {
        $EnumValues = $TypeObj.enum -join "`n  "
        Add-Content -Path $Path -Value "`nenum $TypeName {`n  $EnumValues`n}"
        $TypeNameList.Add($TypeName)
      } else {
        Write-Warning -Message "Invalid string type '$TypeName': $($Property | ConvertTo-Json -Compress)"
      }
    }
    default {
      Write-Warning -Message "Unknown base type '$($TypeObj.type)'"
    }
  }
}

Write-Information -MessageData "Defined $($TypeNameList.Count) CTS API types in: $Path" -InformationAction Continue
