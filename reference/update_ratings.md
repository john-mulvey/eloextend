# Update Ratings After a Single Game

Updates player ratings based on the results of a single game. This is
the core atomic operation for rating updates.

## Usage

``` r
update_ratings(
  game_ranks,
  current_ratings,
  K = 32,
  method = "exponential",
  alpha = 1.4,
  D = 400
)
```

## Arguments

- game_ranks:

  Named numeric vector of player ranks for this game (1 = winner, NA =
  did not play)

- current_ratings:

  Named numeric vector of current player ratings

- K:

  Numeric K-factor controlling rating volatility. Default is 32.

- method:

  Character string: "linear" or "exponential" scoring. Default is
  "exponential".

- alpha:

  Numeric exponent for exponential scoring. Default is 1.4.

- D:

  Numeric scale parameter for Elo calculation. Default is 400.

## Value

Named numeric vector of updated ratings (for all players, not just
participants)

## Details

This implementation treats multiplayer games as the sum of all pairwise
matchups between participants. For games with exactly 2 players, this
reduces to standard Elo ratings, ensuring backward compatibility. The
zero-sum property is maintained: rating changes across all participants
in a game sum to zero (within floating-point precision).

Single-player games (N=1) are valid input but will not result in any
rating changes, as there is no competition. Games with 0 participating
players are also handled gracefully with no rating updates.

## Examples

``` r
current_ratings <- c(Alice = 1000, Bob = 1000, Charlie = 1000)
game_ranks <- c(Alice = 1, Bob = 2, Charlie = NA)
new_ratings <- update_ratings(game_ranks, current_ratings, K = 32)
```
