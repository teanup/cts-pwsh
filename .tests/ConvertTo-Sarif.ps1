#Requires -Modules PSScriptAnalyzer

using namespace System
using namespace System.Collections.Generic
using namespace Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic

class SarifLog {
  static SarifLog() {
    $UpdateParam = @{
      TypeName   = [SarifLog].Name
      MemberType = 'NoteProperty'
      Force      = $true
    }
    Update-TypeData @UpdateParam -MemberName '$schema' -Value 'https://json.schemastore.org/sarif-2.1.0.json'
    Update-TypeData @UpdateParam -MemberName 'version' -Value '2.1.0'
    Update-TypeData @UpdateParam -MemberName 'runs' -Value ([SarifRun[]]@(@{}))
  }
}

class SarifRun {
  [SarifTool] $tool = @{}
  [SarifResult[]] $results = @()
}

class SarifTool {
  [SarifToolComponent] $driver = @{}
}

class SarifToolComponent {
  [String] $name
  [String] $semanticVersion
  [SarifReportingDescriptor[]] $rules = @()
}

class SarifReportingDescriptor {
  [String] $id
  [String] $name
  [SarifMessage] $shortDescription = @{}
  [SarifMessage] $fullDescription = @{}
  [SarifReportingConfiguration] $defaultConfiguration = @{}
  [SarifMultiformatMessageString] $help = @{}
  [SarifPropertyBag] $properties = @{}
}

class SarifMessage {
  [String] $text
}

class SarifReportingConfiguration {
  [String] $level
}

class SarifMultiformatMessageString {
  [String] $text
  [String] $markdown
}

class SarifPropertyBag {
  [String[]] $tags = @()
}

class SarifResult {
  [String] $ruleId
  [String] $level
  [SarifMessage] $message = @{}
  [SarifLocation[]] $locations = @()
  [SarifFix[]] $fixes = @()
}

class SarifLocation {
  [SarifPhysicalLocation] $physicalLocation = @{}
}

class SarifPhysicalLocation {
  [SarifArtifactLocation] $artifactLocation = @{}
  [SarifRegion] $region = @{}
}

class SarifArtifactLocation {
  [String] $uri
}

class SarifRegion {
  [Int] $startLine
  [Int] $startColumn
  [Int] $endLine
  [Int] $endColumn

  SarifRegion([Object]$RegionObject) {
    $this.startLine = [Math]::Max(1, $RegionObject.StartLineNumber)
    $this.startColumn = [Math]::Max(1, $RegionObject.StartColumnNumber)
    $this.endLine = [Math]::Max(1, $RegionObject.EndLineNumber)
    $this.endColumn = [Math]::Max(1, $RegionObject.EndColumnNumber)
  }
}

class SarifFix {
  [SarifMessage] $description = @{}
  [SarifArtifactChange[]] $artifactChanges = @()
}

class SarifArtifactChange {
  [SarifArtifactLocation] $artifactLocation = @{}
  [SarifReplacement[]] $replacements = @()
}

class SarifReplacement {
  [SarifRegion] $deletedRegion = @{}
  [SarifArtifactContent] $insertedContent = @{}
}

class SarifArtifactContent {
  [String] $text
}

class SarifLevel {
  static [String] Parse([DiagnosticSeverity]$Severity) {
    $Level = 'none'
    switch ($Severity) {
      ([DiagnosticSeverity]::ParseError) { $Level = 'error' }
      ([DiagnosticSeverity]::Error) { $Level = 'error' }
      ([DiagnosticSeverity]::Warning) { $Level = 'warning' }
      ([DiagnosticSeverity]::Information) { $Level = 'note' }
    }
    return $Level
  }
}

function ConvertTo-Sarif {
  <#
  .SYNOPSIS
  Converts PSScriptAnalyzer results to SARIF for GitHub code analysis
  .DESCRIPTION
  Converts DiagnosticRecord objects (ignore SuppressedRecord) from PSScriptAnalyzer to a serializable
  SARIF log object, which follows the GitHub recommendations for code analysis output:
  https://docs.github.com/en/code-security/reference/code-scanning/sarif-files/sarif-support
  .EXAMPLE
  Invoke-ScriptAnalyzer -Path . -Recurse | ConvertTo-Sarif | ConvertTo-JSON
  .OUTPUTS
  [SarifLog] with the analysis results in SARIF format, ready to be serialized to JSON.
  .NOTES
  This function is a replacement for Microsoft's archived ConvertTo-SARIF cmdlet, last updated in 2021:
  https://github.com/microsoft/ConvertToSARIF
  The recommended PSScriptAnalyzer GitHub action is only a wrapper around ConvertTo-SARIF and PSScriptAnalyzer.
  It was last updated in 2022: https://github.com/microsoft/psscriptanalyzer-action
  #>
  [CmdletBinding()]
  [OutputType([SarifLog])]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [System.Object[]] $InputObject
  )
  begin {
    $Results = [List[SarifResult]]::new()
    $Rules = [Dictionary[String, SarifReportingDescriptor]]::new()
  }
  process {
    # Ignore suppressed records
    $InputObject | Where-Object { $_ -is [DiagnosticRecord] } | ForEach-Object {
      # Register rules once
      $_.RuleName | Where-Object { -not $Rules.ContainsKey($_) } | ForEach-Object {
        $Rule = Get-ScriptAnalyzerRule -Name $_
        $RuleRefId = $_.Substring(2)
        $RuleRefUrl = "https://learn.microsoft.com/powershell/utility-modules/psscriptanalyzer/rules/$RuleRefId"

        $Rules.Add($_, @{
            id                   = $_
            name                 = $Rule.CommonName
            shortDescription     = @{ text = $Rule.Description }
            fullDescription      = @{ text = $Rule.Description }
            defaultConfiguration = @{ level = [SarifLevel]::Parse($Rule.Severity) }
            help                 = @{
              text     = "$RuleRefId reference: $RuleRefUrl"
              markdown = "[$RuleRefId reference]($RuleRefUrl)"
            }
          }
        )
      }

      $RuleName = $_.RuleName
      $FilePath = $_.Extent.File

      $Results.Add(@{
          ruleId    = $_.RuleName
          level     = [SarifLevel]::Parse($_.Severity)
          message   = @{ text = $_.Message }
          locations = @{
            physicalLocation = @{
              artifactLocation = @{ uri = $_.ScriptPath }
              region           = [SarifRegion]::new($_.Extent)
            }
          }
          fixes     = @($_.SuggestedCorrections | Where-Object { $_ } | ForEach-Object {
              $Fix = @{
                description     = @{ text = $_.Description }
                artifactChanges = @{
                  artifactLocation = @{ uri = $_.File }
                  replacements     = @{
                    deletedRegion   = [SarifRegion]::new($_)
                    insertedContent = @{ text = $_.Text }
                  }
                }
              }
              # PSScriptAnalyzer bug: https://github.com/PowerShell/PSScriptAnalyzer/issues/2201
              if ($RuleName -eq 'PSAlignAssignmentStatement') {
                $Fix.description.text = $_.File
                $Fix.artifactChanges.artifactLocation.uri = $FilePath
              }
              $Fix
            })
        })
    }
  }
  end {
    $SarifLog = [SarifLog]::new()

    $Module = Get-Module -Name 'PSScriptAnalyzer'
    $SarifLog.runs[0].tool.driver = @{
      name            = $Module.Name
      semanticVersion = $Module.Version
      rules           = $Rules.Values
    }
    $SarifLog.runs[0].results = $Results

    $SarifLog
  }
}
