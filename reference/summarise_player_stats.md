# Summarise Player Statistics

Creates a summary table of player performance metrics.

## Usage

``` r
summarise_player_stats(game_data, elo_results)
```

## Arguments

- game_data:

  Data frame of game results

- elo_results:

  List returned by calculate_all_ratings()

## Value

Data frame with columns: player, current_rating, n_games, n_wins,
n_losses, win_rate (sorted by rating descending)

## Examples

``` r
if (FALSE) { # \dontrun{
results <- calculate_all_ratings(game_data)
summary <- summarise_player_stats(game_data, results)
} # }
```
