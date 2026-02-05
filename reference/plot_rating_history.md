# Plot Rating History

Creates a line plot showing how player ratings changed over time.

## Usage

``` r
plot_rating_history(
  ratings_history,
  title = NULL,
  interactive = FALSE,
  x_axis = "date"
)
```

## Arguments

- ratings_history:

  Data frame with columns: date, player, rating, game_id

- title:

  Character string for plot title. Default is NULL (no title).

- interactive:

  Logical. If TRUE, returns interactive plotly plot. If FALSE, returns
  static ggplot2 plot. Default is FALSE.

- x_axis:

  Character string: "date" or "game_id". Default is "date". "date" plots
  ratings against date (can cause overlapping when multiple games occur
  on same date). "game_id" plots ratings against sequential game number
  with date labels, avoiding overlap and showing each game distinctly.
  Note: the date scale is not linear when using "game_id" - games are
  evenly spaced regardless of time between them.

## Value

A ggplot2 or plotly plot object

## Examples

``` r
if (FALSE) { # \dontrun{
results <- calculate_all_ratings(game_data)
plot_rating_history(results$ratings_history, title = "My Game Ratings")
plot_rating_history(results$ratings_history, interactive = TRUE)
plot_rating_history(results$ratings_history, x_axis = "game_id")
} # }
```
