  <!-- badges: start -->
  [![R-CMD-check](https://github.com/john-mulvey/eloextend/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/john-mulvey/eloextend/actions/workflows/R-CMD-check.yaml)
  <!-- badges: end -->

# Overview

**eloextend** extends the classic Elo rating system to handle multiplayer games with 3 or more players, where the players can be assigned a rank finish order. The package treats multiplayer games as the sum of all pairwise matchups between participants, ensuring that:

- 2-player games reduce to classical Elo ratings
- Changes in rating after a game sum to zero
- Tied ranks are permissible

For more details on how the score is calculated, see the [relevant vignette](vignettes/rating_system.Rmd).

# Installation

```r
# if required, install remotes package
install.packages("remotes")

# install package from github
remotes::install_github("github.com/john-mulvey/eloextend", build_vignettes = TRUE)
```

# Quick Start

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
summarise_player_stats(game_data, results)

# Predict next game outcome
predict_game_outcome(results$final_ratings[c("Alice", "Bob", "Charlie")])
```

# Prior art

There are several other descriptions on the web of methods applying the same core idea that we utilise here of using pairwise comparisons to allow multiplayer Elo ratings. This includes a python package [multielo](https://github.com/djcunningham0/multielo).

