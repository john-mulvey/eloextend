## Overview

**eloextend** extends the classic Elo rating system to handle multiplayer games with 3 or more players, where the players can be assigned a rank finish order. The package treats multiplayer games as the sum of all pairwise matchups between participants, ensuring that:

- 2-player games reduce to standard Elo ratings (backward compatible)
- The zero-sum property is maintained (rating changes sum to zero)
- Both linear and exponential scoring methods are supported
- Tied ranks are permissible

## Installation

```r
# Install from local source
devtools::install_local("path/to/eloextend")

# Or install in development mode
devtools::load_all("path/to/eloextend")
```

## Quick Start

```r
library(eloextend)

# Generate example data
start_date <- as.Date("2024-01-01")
end_date <- as.Date("2024-03-31")
players <- c("Alice", "Bob", "Charlie", "David", "Eva")

game_data <- generate_toy_data(start_date, end_date, players, n_games = 50)

# Calculate ratings
results <- calculate_all_ratings(
  game_data,
  initial_rating = 1000,
  K = 32,
  method = "exponential",
  alpha = 1.4
)

# View final ratings
results$final_ratings

# Plot rating history
plot_rating_history(results$ratings_history, x_axis = "game_id")

# Get player statistics
stats <- summarise_player_stats(game_data, results)
print(stats)

# Predict next game outcome
predict_game_outcome(results$final_ratings[c("Alice", "Bob", "Charlie")])
```

## Key Features

### Core Functions

- `calculate_scores()` - Convert rankings to normalised scores
- `update_ratings()` - Update ratings after a single game
- `calculate_all_ratings()` - Calculate ratings across multiple games
- `get_expected_score()` - Calculate expected score for a player

### Utility Functions

- `generate_toy_data()` - Generate random game data for testing
- `validate_game_data()` - Validate game data format
- `predict_game_outcome()` - Predict win probabilities
- `summarise_player_stats()` - Generate player performance metrics
- `extract_final_ratings()` - Extract final ratings from results

### Visualisation

- `plot_rating_history()` - Plot rating changes over time
  - Static ggplot2 plots
  - Interactive plotly plots
  - Plot by date or game sequence

## Scoring Methods

### Linear Scoring
Arithmetic weighting based on rank position.

### Exponential Scoring (default)
Geometric weighting with configurable alpha parameter. Higher alpha values give more weight to top finishers.

**Note:** For 2-player games, the exponential method always gives the winner a score of 1 and the loser a score of 0, regardless of alpha.

## Data Format

Game data should be a data frame with:
- `game_id`: Unique game identifier
- `date`: Date of the game
- One column per player containing their rank (1 = winner, NA = did not play)

Example:
```r
data.frame(
  game_id = 1:3,
  date = as.Date(c("2024-01-01", "2024-01-02", "2024-01-03")),
  Alice = c(1, 2, 1),
  Bob = c(2, 1, 3),
  Charlie = c(3, 3, 2)
)
```

## Mathematical Properties

1. **Zero-sum property**: Rating changes across all participants sum to zero
2. **Two-player convergence**: 2-player games match standard Elo calculations
3. **Score normalisation**: Game scores always sum to 1
4. **Expected score consistency**: Expected scores for all players sum to 1
