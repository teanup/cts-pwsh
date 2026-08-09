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
  This function is a replacement for Microsoft's ConvertTo-SARIF cmdlet: https://github.com/microsoft/ConvertToSARIF
  The recommended PSScriptAnalyzer GitHub action is only a wrapper around ConvertTo-SARIF and PSScriptAnalyzer:
  https://github.com/microsoft/psscriptanalyzer-action
  #>
  [CmdletBinding()]
  [OutputType([SarifLog])]
  param (
    # DiagnosticRecord and SuppressedRecord objects to parse
    [Parameter(Mandatory, ValueFromPipeline)]
    [Object[]] $InputObject
  )
  begin {
    $Rules = [Dictionary[String, SarifReportingDescriptor]]::new()
    $Results = [List[SarifResult]]::new()
  }
  process {
    # Ignore suppressed records
    $InputObject | Where-Object { $_ -is [DiagnosticRecord] } | ForEach-Object {
      # Register rule
      if (-not $Rules.ContainsKey($_.RuleName)) {
        $RuleInfo = Get-ScriptAnalyzerRule -Name $_.RuleName
        $RuleRefId = $_.RuleName.Substring(2)
        $RuleRefUrl = "https://learn.microsoft.com/powershell/utility-modules/psscriptanalyzer/rules/$RuleRefId"

        $Rule = [SarifReportingDescriptor]@{
          id                   = $_.RuleName
          name                 = $_.RuleName
          shortDescription     = @{ text = $RuleInfo.CommonName }
          fullDescription      = @{ text = $RuleInfo.Description }
          defaultConfiguration = @{ level = [SarifLevel]::Parse($RuleInfo.Severity) }
          help                 = @{
            text     = "$($RuleInfo.Description) Read more: $RuleRefUrl"
            markdown = "$($RuleInfo.Description) [Read more]($RuleRefUrl)"
          }
        }
        $Rules.Add($_.RuleName, $Rule)
      }

      $ArtifactLocation = [SarifArtifactLocation]@{ uri = [Uri]::new($_.ScriptPath) }

      # PSScriptAnalyzer bug: https://github.com/PowerShell/PSScriptAnalyzer/issues/2201
      $BadFixFormat = $_.RuleName -eq 'PSAlignAssignmentStatement'

      $Result = [SarifResult]@{
        ruleId    = $_.RuleName
        level     = [SarifLevel]::Parse($_.Severity)
        message   = @{ text = $_.Message }
        locations = @{
          physicalLocation = @{
            artifactLocation = $ArtifactLocation
            region           = [SarifRegion]::new($_.Extent)
          }
        }
        fixes     = @($_.SuggestedCorrections) | ForEach-Object {
          $Fix = @{
            description     = @{ text = $_.Description }
            artifactChanges = @{
              artifactLocation = $ArtifactLocation
              replacements     = @{
                deletedRegion   = [SarifRegion]::new($_)
                insertedContent = @{ text = $_.Text }
              }
            }
          }
          if ($BadFixFormat) {
            $Fix.description.text = $_.File
          }
          $Fix
        }
      }
      $Results.Add($Result)
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

function Show-GitHubAnnotation {
  <#
  .SYNOPSIS
  Display GitHub annotations based on code analysis results
  .DESCRIPTION
  Write annotations to the console as a summary of a SARIF log object, based on GitHub's workflow documentation:
  https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands
  .EXAMPLE
  Invoke-ScriptAnalyzer -Path . -Recurse | ConvertTo-Sarif | Show-GitHubAnnotation
  #>
  [CmdletBinding()]
  [OutputType([Void])]
  param (
    # SARIF log object from ConvertTo-Sarif
    [Parameter(Mandatory, ValueFromPipeline)]
    [SarifLog] $SarifLog,

    # Root path used to relativize code analysis paths
    [Parameter()]
    [String] $Path
  )
  process {
    $Prefix = ''
    if (-not [String]::IsNullOrEmpty($Path)) {
      $Prefix = [Uri]::new((Convert-Path -LiteralPath $Path)).ToString() + '/'
    }

    $Rules = $SarifLog.runs[0].tool.driver.rules | Group-Object -Property id -AsHashTable
    $SarifLog.runs[0].results | ForEach-Object {
      $Level = switch ($_.level) {
        'error' { 'error' }
        'warning' { 'warning' }
        'note' { 'notice' }
        default { 'notice' }
      }

      $FilePath = $_.locations[0].physicalLocation.artifactLocation.uri
      if ($FilePath.StartsWith($Prefix)) {
        $FilePath = $FilePath.Substring($Prefix.Length)
      }

      $Region = $_.locations[0].physicalLocation.region
      $StartLine = $Region.startLine
      $StartColumn = $Region.startColumn
      $EndLine = $Region.endLine
      $EndColumn = $Region.endColumn
      $RegionInfo = "line=$StartLine,col=$StartColumn,endLine=$EndLine,endColumn=$EndColumn"

      $Title = $Rules[$_.ruleId].shortDescription.text
      $Message = $_.message.text

      Write-Host -Object "::$Level file=$FilePath,$RegionInfo,title=$Title`::$Message"
    }
  }
}
