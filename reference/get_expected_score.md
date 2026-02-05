# Calculate Expected Score for a Player

Calculates the expected score for a player against a set of opponents
based on current Elo ratings.

## Usage

``` r
get_expected_score(player_rating, opponent_ratings, D = 400)
```

## Arguments

- player_rating:

  Numeric Elo rating of the player

- opponent_ratings:

  Numeric vector of opponent Elo ratings

- D:

  Numeric scale parameter for Elo calculation. Default is 400.

## Value

Numeric expected score (between 0 and 1)
