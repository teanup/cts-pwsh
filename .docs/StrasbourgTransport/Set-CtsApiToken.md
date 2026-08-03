---
document type: cmdlet
external help file: StrasbourgTransport-Help.xml
HelpUri: https://github.com/teanup/cts-pwsh/blob/main/.docs/StrasbourgTransport/Set-CtsApiToken.md#Set-CtsApiToken
Locale: en-US
Module Name: StrasbourgTransport
ms.date: 08/01/2026
PlatyPS schema version: 2024-05-01
title: Set-CtsApiToken
---

# Set-CtsApiToken

## SYNOPSIS

Stores the CTS API token securely in the module directory

## SYNTAX

### __AllParameterSets

```
Set-CtsApiToken [-Token] <string> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

Saves the given API token in a hidden file (`.cts-api.xml`) in the module directory.

On Windows the token is encrypted with the machine and user keys.

## EXAMPLES

### EXAMPLE 1

```pwsh
Set-CtsApiToken -Token '<your-token>'
```

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

### -Token

Token to use for authenticating with the CTS API

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
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

## NOTES

## RELATED LINKS
