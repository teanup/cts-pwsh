---
document type: cmdlet
external help file: StrasbourgTransport-Help.xml
HelpUri: https://github.com/teanup/cts-pwsh/blob/main/.docs/StrasbourgTransport/Show-CtsDeparture.md#Show-CtsDeparture
Locale: en-US
Module Name: StrasbourgTransport
ms.date: 07/28/2026
PlatyPS schema version: 2024-05-01
title: Show-CtsDeparture
---

# Show-CtsDeparture

## SYNOPSIS

Displays the next departures dynamically at the specified CTS stops

## SYNTAX

### Filters (Default)

```
Show-CtsDeparture [[-Stop] <string[]>] [[-Destination] <string[]>] [-Line <string[]>] [-Strict]
 [-MaxDepartures <int>] [-RefreshRate <int>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Object

```
Show-CtsDeparture -StopObject <Stop[]> [-MaxDepartures <int>] [-RefreshRate <int>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

Shows a live-updating table of departures in the terminal (press Ctrl+C to exit).
Refreshes automatically at the given interval and redraws in place using ANSI escape codes.

## EXAMPLES

### EXAMPLE 1

Show-CtsDeparture -Stop Esplanade -Destination Lingolsheim, Robertsau

### EXAMPLE 2

Show-CtsDeparture -Stop 'Homme de Fer' -RefreshRate 10

## PARAMETERS

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Destination

Destination names to filter by (prefix match)

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- To
ParameterSets:
- Name: Filters
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Force

Bypass the stop and departure caches

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Line

Line names to filter by

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Filters
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -MaxDepartures

Maximum number of departure times to show per line, stop and destination

```yaml
Type: System.Int32
DefaultValue: 3
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -NoCacheFile

Skip writing the cache file to disk

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Filters
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -RefreshRate

Time between each departure refresh in seconds

```yaml
Type: System.Int32
DefaultValue: 5
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Stop

Stop names to filter by (prefix match)

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- From
ParameterSets:
- Name: Filters
  Position: 0
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -StopObject

Stop objects from Find-CtsStop to display departures for

```yaml
Type: Stop[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Object
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Strict

Only return destinations that exactly match -Destination, excluding same-direction alternatives

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Filters
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Stop[]

Stop objects from Find-CtsStop to retrieve departures for

## OUTPUTS

## NOTES

## RELATED LINKS
