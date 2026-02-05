# Calculate Scores from Rankings

Converts player rankings into weighted scores that sum to 1. Higher
ranks (lower numbers) receive higher scores. Handles NA values for
non-participating players.

## Usage

``` r
calculate_scores(ranks, method = "exponential", alpha = 1.4)
```

## Arguments

- ranks:

  Named numeric vector of rankings (1 = best, 2 = second, etc.) Names
  should be player identifiers. NA values indicate non-participating
  players. Tied ranks are supported: players with the same rank receive
  identical scores.

- method:

  Character string: "linear" or "exponential" (default). Linear uses
  arithmetic weighting, exponential uses geometric weighting.

- alpha:

  Numeric exponent for exponential weighting (only used if method =
  "exponential"). Must be \> 0 and != 1. Higher values give more weight
  to top finishers. Default is 1.4. Note: For N=2 players, alpha has no
  effect on the result.

## Value

Named numeric vector of scores (same length and names as ranks).
Non-participating players (NA ranks) receive a score of 0.

## Details

Single-player games (N=1) are valid input and return a score of 1 for
the sole participant. However, such games are meaningless for rating
updates since there is no competition, and update_ratings() will not
modify ratings for them.

For 2-player games with exponential scoring, the formula simplifies to
give the winner a score of 1 and the loser a score of 0, regardless of
alpha. This ensures convergence to standard Elo for head-to-head
matches.

Mathematical explanation: For N=2 with ranks 1 and 2, the exponential
formula gives:

- Winner (rank 1): (alpha^(2-1) - 1) / ((alpha^(2-1) - 1) +
  (alpha^(2-2) - 1)) = (alpha - 1) / (alpha - 1 + 0) = 1

- Loser (rank 2): (alpha^(2-2) - 1) / ((alpha^(2-1) - 1) +
  (alpha^(2-2) - 1)) = 0 / (alpha - 1) = 0 Thus, alpha cancels out for
  the 2-player case.

## Examples

``` r
# Simple ranking without NAs
calculate_scores(c(Alice = 1, Bob = 2, Charlie = 3, David = 4), method = "linear")
#>     Alice       Bob   Charlie     David 
#> 0.5000000 0.3333333 0.1666667 0.0000000 
calculate_scores(c(Alice = 1, Bob = 2, Charlie = 3, David = 4),
                 method = "exponential", alpha = 1.4)
#>     Alice       Bob   Charlie     David 
#> 0.5618557 0.3092784 0.1288660 0.0000000 

# With non-participating players (NAs)
ranks <- c(Alice = 1, Bob = 3, Charlie = 2, David = NA)
calculate_scores(ranks, method = "exponential", alpha = 1.4)
#>     Alice       Bob   Charlie     David 
#> 0.7058824 0.0000000 0.2941176 0.0000000 

# With tied ranks (tied players receive equal scores)
calculate_scores(c(Alice = 1, Bob = 2, Charlie = 2, David = 4), method = "linear")
#>   Alice     Bob Charlie   David 
#>    0.50    0.25    0.25    0.00 

# For 2 players with exponential, alpha doesn't matter:
calculate_scores(c(Alice = 1, Bob = 2), method = "exponential", alpha = 1.4)
#> Alice   Bob 
#>     1     0 
calculate_scores(c(Alice = 1, Bob = 2), method = "exponential", alpha = 10)
#> Alice   Bob 
#>     1     0 
```
