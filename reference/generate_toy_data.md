# Generate Toy Data for Testing

Generates random game data with varying numbers of players per game.
Useful for testing and demonstrating the Elo rating system. Players are
assigned different skill levels so that some players tend to perform
better than others, creating more realistic rating progressions.

## Usage

``` r
generate_toy_data(start_date, end_date, players, n_games = 100)
```

## Arguments

- start_date:

  Date object for the start of the date range

- end_date:

  Date object for the end of the date range

- players:

  Character vector of player names

- n_games:

  Integer number of games to generate. Default is 100.

## Value

Data frame with columns: game_id, date, and one column per player
containing their rank (1 = winner, NA = did not play). The first player
in the vector will tend to perform best, the last will tend to perform
worst.

## Examples

``` r
start_date <- as.Date("2023-01-01")
end_date <- as.Date("2023-12-31")
players <- c("Alice", "Bob", "Charlie", "David", "Eva")
toy_data <- generate_toy_data(start_date, end_date, players, n_games = 50)
```
