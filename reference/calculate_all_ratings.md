# Calculate All Ratings from Game Data

Calculates Elo ratings for all players across a series of games. Returns
both final ratings and complete rating history.

## Usage

``` r
calculate_all_ratings(
  data,
  initial_rating = 1000,
  K = 32,
  method = "exponential",
  alpha = 1.4,
  D = 400
)
```

## Arguments

- data:

  Data frame with columns: game_id, date, and one column per player
  containing their rank in each game (1 = winner, NA = did not play)

- initial_rating:

  Numeric starting Elo rating for all players. Default is 1000.

- K:

  Numeric K-factor controlling rating volatility. Default is 32.

- method:

  Character string: "linear" or "exponential" scoring. Default is
  "exponential".

- alpha:

  Numeric exponent for exponential scoring. Default is 1.4. For 2-player
  games, alpha has no effect (winner always gets score 1, loser gets 0).

- D:

  Numeric scale parameter for Elo calculation. Default is 400.

## Value

List with two elements:

- final_ratings: Named numeric vector of final Elo ratings

- ratings_history: Data frame with columns (date, player, rating,
  game_id)

## Details

This function processes games sequentially, updating ratings after each
game using the update_ratings() function. It can be used for initial
calculation or for incremental updates by providing a subset of games.

## Examples

``` r
# Three-player game example demonstrating multiplayer Elo
game_data <- data.frame(
  game_id = 1:3,
  date = as.Date(c("2024-01-01", "2024-01-02", "2024-01-03")),
  Alice = c(1, 2, 1),
  Bob = c(2, 1, 3),
  Charlie = c(3, 3, 2)
)
results <- calculate_all_ratings(game_data)
print(results$final_ratings)
#>     Alice       Bob   Charlie 
#> 1041.2442  998.2643  960.4914 
head(results$ratings_history)
#>         date  player    rating game_id
#> 1 2024-01-01   Alice 1023.8431       1
#> 2 2024-01-01     Bob  997.4902       1
#> 3 2024-01-01 Charlie  978.6667       1
#> 4 2024-01-02   Alice 1019.1466       2
#> 5 2024-01-02     Bob 1021.5635       2
#> 6 2024-01-02 Charlie  959.2899       2
```
