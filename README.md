# StrasbourgTransport

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/StrasbourgTransport.svg?label=PowerShell%20Gallery&style=flat-square&logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAzMiAzMiIgZmlsbD0id2hpdGUiPjxwYXRoIGQ9Ik0zMC45MDYgNC4xMDRjMC43NiAwIDEuMjM0IDAuNjE1IDEuMDU3IDEuMzhsLTQuODggMjEuMzA3Yy0wLjE3MiAwLjc2LTAuOTI3IDEuMzgtMS42ODIgMS4zOGgtMjQuMzA3Yy0wLjc2IDAtMS4yMzQtMC42Mi0xLjA1Ny0xLjM4bDQuODgtMjEuMzA3YzAuMTcyLTAuNzY2IDAuOTI3LTEuMzggMS42ODItMS4zOHpNMTkuNzQgMTYuNTYzYzAuMzM5LTAuNTI2IDAuMzAyLTEuMjA4LTAuMTItMS42NTZsLTcuNDU4LTcuOTM4Yy0wLjUwNS0wLjUzNi0xLjM4LTAuNTQyLTEuOTUzLTAuMDA1LTAuNTczIDAuNTQyLTAuNjI1IDEuNDExLTAuMTIgMS45NDhsNi4yMTkgNi42MTV2MC4xNDZsLTkuODk2IDcuMTY3Yy0wLjU5OSAwLjQzMi0wLjcwOCAxLjMwMi0wLjI1IDEuOTM4IDAuNDY0IDAuNjM1IDEuMzIzIDAuNzk3IDEuOTIyIDAuMzU5bDEwLjk3NC03Ljg4YzAuMzctMC4yNiAwLjU4My0wLjQ5IDAuNjgyLTAuNjkzek0xNi4wMTYgMjIuNDI3Yy0wLjY4OC0wLjAwNS0xLjI0NSAwLjU0Ny0xLjI1IDEuMjI5IDAgMC42ODIgMC41NTcgMS4yMzQgMS4yNSAxLjIzNGg1LjkwNmMwLjY4OCAwLjAwNSAxLjI0NS0wLjU0NyAxLjI1LTEuMjM0LTAuMDA1LTAuNjgyLTAuNTYzLTEuMjM0LTEuMjUtMS4yMjl6Ii8+PC9zdmc+)](https://www.powershellgallery.com/packages/StrasbourgTransport)
&thinsp;
[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/StrasbourgTransport.svg?label=Downloads&style=flat-square&logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0id2hpdGUiPjxwYXRoIGQ9Ik0yMCwxNWExLDEsMCwwLDAtMSwxVjIwYS4yMi4yMiwwLDAsMS0uMTUuMDVINS4xNEM1LjA2LDIwLDUsMjAsNSwyMFYxNmExLDEsMCwwLDAtMiwwdjRhMi4wOCwyLjA4LDAsMCwwLDIuMTQsMkgxOC44NkEyLjA4LDIuMDgsMCwwLDAsMjEsMjBWMTZBMSwxLDAsMCwwLDIwLDE1WiI+PC9wYXRoPjxwYXRoIGQ9Ik0xMS4yOSwxNi43MWExLDEsMCwwLDAsLjMzLjIxLjk0Ljk0LDAsMCwwLC43NiwwLDEsMSwwLDAsMCwuMzMtLjIxbDQtNGExLDEsMCwwLDAtMS40Mi0xLjQyTDEzLDEzLjU5VjNhMSwxLDAsMCwwLTIsMFYxMy41OWwtMi4yOS0yLjNhMSwxLDAsMSwwLTEuNDIsMS40MloiPjwvcGF0aD48L3N2Zz4=)](https://www.powershellgallery.com/stats/packages/StrasbourgTransport?groupby=Version)
&thinsp;
[![Code Quality Workflow Status](https://img.shields.io/github/actions/workflow/status/teanup/cts-pwsh/powershell-quality.yml?label=Code%20Quality&style=flat-square&logo=github)](https://github.com/teanup/cts-pwsh/actions/workflows/powershell-quality.yml)
&thinsp;
[![Publish Module Workflow Status](https://img.shields.io/github/actions/workflow/status/teanup/cts-pwsh/powershell-publish.yml?label=Publish%20Module&style=flat-square&logo=github)](https://github.com/teanup/cts-pwsh/actions/workflows/powershell-publish.yml)

A PowerShell module to query and display real-time departures for the **CTS (Compagnie des Transports Strasbourgeois)** network directly in your terminal.

<img alt="Show-CtsDeparture demo" src="https://raw.githubusercontent.com/teanup/cts-pwsh/main/.docs/preview-crop.gif" width="640px" />

### Features

- :keyboard: **Smart tab completion**: Auto-completes stops, lines, and destinations. It ignores diacritics, so typing `rep` finds `République` instantly.
- :recycle: **Efficient caching**: Network data is cached for a week, and live departure times only refresh when the API indicates new data is available.
- :trolleybus: **Route-aware results**: Automatically includes alternative destinations traveling the same direction, so you don't miss a tram due to different terminus signs.
- :computer: **Live terminal view**: The `Show-CtsDeparture` updates the table in place. **Bold** text indicates real-time data, while <ins>underlined</ins> text shows scheduled times.

---

## Getting Started

### 1. Install the Module

Available on the [PowerShell Gallery](https://www.powershellgallery.com/packages/StrasbourgTransport):

```pwsh
Install-PSResource -Name StrasbourgTransport -Repository PSGallery
```

### 2. Configure Your API Token

You need a valid CTS API token to fetch data.

1. Request an account on the [CTS Open Data portal](https://cts-strasbourg.eu/en/open-data/).
2. Generate a new API token.
3. Save it securely using the module:

   ```pwsh
   Set-CtsApiToken -Token '<your-token>'
   ```

> [!NOTE]
> The token is stored in a hidden file within the module directory. On Windows, it is encrypted for security. It loads automatically when the module is imported and is kept through module updates.

---

## Usage

### Find Stops: `Find-CtsStop`

Search the network for stops, lines, or destinations.

```pwsh
# List all available stops
Find-CtsStop

# Find stops starting with "Gallia"
Find-CtsStop Gallia

# Find stops on line A or D heading towards Kehl or Illkirch
Find-CtsStop -Line A, D -Destination Kehl, Illkirch

# Strict mode: exclude same-direction alternatives (e.g., exclude "Port du Rhin" if looking for "Kehl")
Find-CtsStop -Line A, D -Destination Kehl, Illkirch -Strict
```

_Returns `Stop` objects that can be piped directly into departure commands._

### Get Departures: `Get-CtsDeparture`

Retrieve upcoming departures for any matching stop or direction.

```pwsh
# Get departures for any "Gare" stop heading towards "Rotterdam"
Get-CtsDeparture Gare Rotterdam

# Pipe specific stops and limit to 5 departures per line
Find-CtsStop Esplanade | Get-CtsDeparture -MaxDepartures 5
```

_Returns `Departure` objects with line info and timestamps._

### Live View: `Show-CtsDeparture`

Print an interactive, auto-refreshing table in your terminal. Press <kbd>Ctrl</kbd>+<kbd>C</kbd> to exit.

```pwsh
# Live view at "Homme de Fer", refreshing every 10 seconds
Show-CtsDeparture -Stop 'Homme de Fer' -RefreshRate 10

# Pipe specific stops directly into the live view
Find-CtsStop -Line H -Destination Parlement | Show-CtsDeparture
```

_The view updates in place. **Bold** times indicate real-time predictions, <ins>underlined</ins> times are scheduled._

---

### Contributing

This project is open source and built for regular users of the CTS public transport network. If you find a bug, have a feature idea, or want to improve the existing logic, feel free to open an issue or submit a pull request.

> [!TIP]
> The CTS API returns a lot more information than tram and bus departures: bike sharing slots, park & ride availability, disruption announcements...
>
> Check all the API types in [`Classes/CtsApi.ps1`](https://github.com/teanup/cts-pwsh/blob/main/Classes/CtsApi.ps1), maybe it will give you some ideas!
