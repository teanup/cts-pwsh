# StrasbourgTransport (PowerShell module)

Display Strasbourg public transport departures in PowerShell.

## Prerequisites

You need a **CTS API token** to use this module.

1. Request an account on the [CTS Open Data portal](https://cts-strasbourg.eu/en/open-data/)
2. Generate an API token
3. Save the token in a file named `.cts-api.key` at the module root, or pass it when importing:
    ```pwsh
    Import-Module StrasbourgTransport -ArgumentList '<your-token>'
    ```

## Usage

### Find-CtsStop

Query the CTS network for stops, lines and destinations. All filters are optional and matched by prefix (case-insensitive).

```pwsh
# All stops
Find-CtsStop

# Stops whose name starts with "Gallia"
Find-CtsStop Gallia

# Stops on line A or D heading towards Kehl or Illkirch
Find-CtsStop -Line A, D -Destination Kehl, Illkirch

# Same as above, but exclude same-direction alternatives (e.g. "Port du Rhin")
Find-CtsStop -Line A, D -Destination Kehl, Illkirch -Strict
```

Returns `[Stop]` objects that can be piped into `Get-CtsDeparture` or `Show-CtsDeparture`.

### Get-CtsDeparture

Retrieve upcoming departure times for matching stops, lines and destinations.

```pwsh
# Departures at stops named "Gare" heading towards "Rotterdam"
Get-CtsDeparture Gare Rotterdam

# Pipe stops from Find-CtsStop, limit to 5 departures per line
Find-CtsStop Esplanade | Get-CtsDeparture -MaxDepartures 5
```

Returns `[Departure]` objects with the stop name, line info and departure times.

### Show-CtsDeparture

Display departures as a live-updating table in the terminal. Press <kbd>Ctrl</kbd>+<kbd>C</kbd> to exit.

```pwsh
# Live view at Homme de Fer, refreshing every 10 seconds
Show-CtsDeparture -Stop 'Homme de Fer' -RefreshRate 10

# Pipe stops from Find-CtsStop
Find-CtsStop -Line H -Destination Parlement | Show-CtsDeparture
```

The display refreshes automatically at the given interval and redraws in place using ANSI escape codes. Live (real-time) departure times are shown in **bold**; scheduled times are shown with an <u>underline</u>.
