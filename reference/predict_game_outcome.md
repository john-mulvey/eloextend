# Predict Game Outcome

Estimates the expected pairwise win rate for each player in an upcoming
game based on current Elo ratings. Each value represents the proportion
of pairwise matchups that player is expected to win. The values sum to 1
across all players.

## Usage

``` r
predict_game_outcome(player_ratings, D = 400)
```

## Arguments

- player_ratings:

  Named numeric vector of current Elo ratings for players

- D:

  Numeric scale parameter. Default is 400.

## Value

Named numeric vector of expected pairwise win rates (sum to 1)

## Examples

``` r
ratings <- c(Alice = 1200, Bob = 1000, Charlie = 1100)
predict_game_outcome(ratings)
#>     Alice       Bob   Charlie 
#> 0.4666040 0.2000627 0.3333333 
```
