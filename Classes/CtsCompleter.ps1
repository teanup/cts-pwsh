<#
.SYNOPSIS
Argument completers for CTS stops, lines and destinations
#>

using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections
using namespace System.Collections.Generic

# Base argument completer that delegates item lookup to a CtsItems method
class CtsCompleter : IArgumentCompleter {
  # Based on: https://gist.github.com/santisq/ad07e2e3913de981c4d2e06f41e6ddb4
  hidden [List[CompletionResult]] $Results = [List[CompletionResult]]::new()

  [IEnumerable[CompletionResult]] CompleteArgument(
    [String] $CommandName,
    [String] $ParameterName,
    [String] $WordToComplete,
    [CommandAst] $CommandAst,
    [IDictionary] $FakeBoundParameters
  ) {
    $this.Results.Clear()

    $FindParam = @{
      Line        = $FakeBoundParameters.Line
      Stop        = $FakeBoundParameters.Stop
      Destination = $FakeBoundParameters.Destination
      Completion  = $true
    }
    # Unescape quotes for CTS item lookup
    $FindParam.$ParameterName = [Regex]::Unescape($WordToComplete -replace '^"|"$|^''|''$')
    $CompletionItems = $this.CtsItems($FindParam)

    foreach ($Item in $CompletionItems) {
      # Escape quotes for command line parameter text
      $Completion = [CodeGeneration]::EscapeSingleQuotedStringContent($Item)
      if ($Item -match '\s|''|"') {
        $Completion = "'$Completion'"
      }

      $this.Results.Add([CompletionResult]::new($Completion, $Item, [CompletionResultType]::ParameterValue, $Item))
    }
    return $this.Results
  }
}

# Tab completer for the -Stop parameter: returns stop names matching the current context (line, destination)
class StopCompleter : CtsCompleter {
  hidden [String[]] CtsItems([IDictionary]$FindParam) {
    $Stops = (Find-CtsStop @FindParam).Name
    return $Stops | Sort-Object -Unique
  }
}

# Tab completer for the -Line parameter: returns line names matching the current context (stop, destination)
class LineCompleter : CtsCompleter {
  hidden [String[]] CtsItems([IDictionary]$FindParam) {
    $Lines = (Find-CtsStop @FindParam).Lines.Name
    return $Lines | Sort-Object -Unique
  }
}

# Tab completer for the -Destination parameter: returns destination names matching the current context (stop, line)
class DestinationCompleter : CtsCompleter {
  hidden [String[]] CtsItems([IDictionary]$FindParam) {
    $Destinations = (Find-CtsStop @FindParam).Lines.Destinations
    return $Destinations | Sort-Object -Unique
  }
}
