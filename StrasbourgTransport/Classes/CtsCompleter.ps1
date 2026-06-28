<#
.SYNOPSIS
Argument completers for CTS stops, lines and destinations
.LINK
https://gist.github.com/santisq/ad07e2e3913de981c4d2e06f41e6ddb4#file-thing-doesnt-work-with-scriptblock-ps1
#>

using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections
using namespace System.Collections.Generic

class CtsCompleter : IArgumentCompleter {
  hidden [List[CompletionResult]] $Results = [List[CompletionResult]]::new()

  [IEnumerable[CompletionResult]] CompleteArgument(
    [String] $CommandName,
    [String] $ParameterName,
    [String] $WordToComplete,
    [CommandAst] $CommandAst,
    [IDictionary] $FakeBoundParameters
  ) {
    $this.Results.Clear()

    # Unescape quotes for CTS item lookup
    $FakeBoundParameters.$ParameterName = [Regex]::Unescape($WordToComplete -replace '(^"|"$)|(^''|''$)')
    $CompletionItems = $this.CtsItems($FakeBoundParameters)

    foreach ($Item in $CompletionItems) {
      # Escape quotes for command line parameter text
      $CompletionText = [CodeGeneration]::EscapeSingleQuotedStringContent($Item)
      if ($Item -match '\s') {
        $CompletionText = "'$CompletionText'"
      }

      $this.Results.Add([CompletionResult]::new($CompletionText, $Item, [CompletionResultType]::ParameterValue, $Item))
    }
    return $this.Results
  }
}

class StopCompleter : CtsCompleter {
  hidden [String[]] CtsItems([IDictionary]$FindParam) {
    $Stops = (Find-CtsStop @FindParam).Name
    return $Stops | Sort-Object -Unique
  }
}

class LineCompleter : CtsCompleter {
  hidden [String[]] CtsItems([IDictionary]$FindParam) {
    $Lines = (Find-CtsStop @FindParam).Lines.Name
    return $Lines | Sort-Object -Unique
  }
}

class DestinationCompleter : CtsCompleter {
  hidden [String[]] CtsItems([IDictionary]$FindParam) {
    $Destinations = (Find-CtsStop @FindParam).Lines.Destinations
    return $Destinations | Sort-Object -Unique
  }
}
