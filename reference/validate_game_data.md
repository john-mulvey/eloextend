# Validate Game Data Format

Checks that game data is in the correct format for Elo calculations.
This function is called for its side effects (validation). It will stop
with an error if the data is invalid.

## Usage

``` r
validate_game_data(data)
```

## Arguments

- data:

  Data frame to validate

## Value

Invisibly returns TRUE if valid, otherwise throws an error with details
