---
document type: cmdlet
external help file: StrasbourgTransport-Help.xml
HelpUri: https://github.com/teanup/cts-pwsh/blob/main/.docs/StrasbourgTransport/Find-CtsStop.md#Find-CtsStop
Locale: en-US
Module Name: StrasbourgTransport
ms.date: 08/01/2026
PlatyPS schema version: 2024-05-01
title: Find-CtsStop
---

# Find-CtsStop

## SYNOPSIS

Finds CTS stops and lines matching filters

## SYNTAX

### __AllParameterSets

```
Find-CtsStop [[-Stop] <string[]>] [[-Destination] <string[]>] [-Line <string[]>] [-Strict] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

Queries the cached CTS network data and returns `Stop` objects whose name, line and destination match the given filters.

Stop, line and destination names are matched by prefix (case-insensitive), so partial names work.

## EXAMPLES

### EXAMPLE 1

```pwsh
Find-CtsStop Gallia Gare, Neuhof, Wolfisheim
```

Returns all stops named 'Gallia...' with a line heading towards 'Gare...', 'Neuhof...' or 'Wolfisheim...'

### EXAMPLE 2

```pwsh
Find-CtsStop -Line A, D -Destination Kehl, Illkirch -Strict
```

Returns all stops for lines 'A' and 'D' with the only destinations 'Kehl...' and 'Illkirch...'

Destinations with the same direction are excluded: 'Port du Rhin', 'Les Halles'

## PARAMETERS

### -Completion

Enable loose prefix matching for argument completion (internal)

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
- Name: (All)
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

Bypass the stop cache and fetch fresh data from the API

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
- Name: (All)
  Position: 0
  IsRequired: false
  ValueFromPipeline: false
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

## OUTPUTS

### Stop

`Stop` objects with the relevant lines and destinations

## NOTES

## RELATED LINKS
