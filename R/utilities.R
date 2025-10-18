#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom dplyr arrange mutate group_by summarise filter left_join relocate desc n select distinct slice ungroup all_of row_number bind_rows
#' @importFrom tidyr pivot_longer
#' @importFrom ggplot2 ggplot aes geom_line labs theme theme_minimal element_text
#' @importFrom magrittr %>%
#' @importFrom stats setNames rnorm
## usethis namespace: end
NULL

# Declare global variables to avoid R CMD check notes
utils::globalVariables(c(
  "game_id",
  "player",
  "rating",
  "month_year",
  "day_month",
  "max_rank_in_game",
  "n_wins",
  "n_games",
  "current_rating"
))

#' Generate Toy Data for Testing
#'
#' Generates random game data with varying numbers of players per game.
#' Useful for testing and demonstrating the Elo rating system. Players are
#' assigned different skill levels so that some players tend to perform better
#' than others, creating more realistic rating progressions.
#'
#' @param start_date Date object for the start of the date range
#' @param end_date Date object for the end of the date range
#' @param players Character vector of player names
#' @param n_games Integer number of games to generate. Default is 100.
#' @return Data frame with columns: game_id, date, and one column per player
#'   containing their rank (1 = winner, NA = did not play). The first player
#'   in the vector will tend to perform best, the last will tend to perform worst.
#' @export
#' @examples
#' start_date <- as.Date("2023-01-01")
#' end_date <- as.Date("2023-12-31")
#' players <- c("Alice", "Bob", "Charlie", "David", "Eva")
#' toy_data <- generate_toy_data(start_date, end_date, players, n_games = 50)
generate_toy_data <- function(start_date, end_date, players, n_games = 100) {
  # Validate inputs
  if (!inherits(start_date, "Date") || !inherits(end_date, "Date")) {
    stop("start_date and end_date must be Date objects")
  }

  if (start_date >= end_date) {
    stop("start_date must be before end_date")
  }

  if (!is.character(players) || length(players) < 2) {
    stop("players must be a character vector with at least 2 players")
  }

  if (!is.numeric(n_games) || length(n_games) != 1 || n_games < 1) {
    stop("n_games must be a single positive integer")
  }

  # Generate random dates for games
  dates <- sample(seq(start_date, end_date, by = "day"), n_games, replace = TRUE)
  game_data <- data.frame(date = dates)

  # Assign skill levels to players (higher = better)
  # This creates more realistic data where some players consistently perform better
  # Using a smaller range (0.6 to 0.4) for moderate skill differences
  player_skills <- setNames(
    seq(from = 0.6, to = 0.4, length.out = length(players)),
    players
  )

  for (i in 1:n_games) {
    # Randomly decide which players participate in this game (2 to all players)
    participating_players <- sample(players, sample(2:length(players), 1))
    n_participants <- length(participating_players)

    # Generate ranks based on skill with some randomness
    # Higher skill = lower expected rank (better finish)
    participant_skills <- player_skills[participating_players]

    # Add random noise to skills for this game (larger noise for more upsets)
    game_performance <- participant_skills + rnorm(n_participants, mean = 0, sd = 0.25)

    # Convert to ranks (best performance = rank 1)
    ranks <- rank(-game_performance, ties.method = "random")

    # Create a named vector of ranks
    game_ranks <- setNames(ranks, participating_players)

    # Assign ranks to the game_data dataframe
    for (player in players) {
      game_data[i, player] <- if (player %in% participating_players) game_ranks[player] else NA
    }
  }

  # Sort by date and add game_id
  game_data <- game_data %>%
    dplyr::arrange(date) %>%
    dplyr::mutate(game_id = dplyr::row_number()) %>%
    dplyr::relocate(game_id, .before = date)

  return(game_data)
}



#' Validate Game Data Format
#'
#' Checks that game data is in the correct format for Elo calculations.
#' This function is called for its side effects (validation). It will stop
#' with an error if the data is invalid.
#'
#' @param data Data frame to validate
#' @return Invisibly returns TRUE if valid, otherwise throws an error with details
#' @export
validate_game_data <- function(data) {
  if (!is.data.frame(data)) {
    stop("data must be a data frame")
  }

  if (nrow(data) == 0) {
    stop("data must contain at least one row")
  }

  required_cols <- c("game_id", "date")
  if (!all(required_cols %in% colnames(data))) {
    stop("data must contain columns: game_id, date")
  }

  player_columns <- colnames(data)[!colnames(data) %in% required_cols]
  if (length(player_columns) == 0) {
    stop("data must contain at least one player column")
  }

  # Check that player columns contain numeric ranks
  for (col in player_columns) {
    if (!is.numeric(data[[col]]) && !all(is.na(data[[col]]))) {
      stop(paste0("Player column '", col, "' must contain numeric values or NA"))
    }
  }

  invisible(TRUE)
}


#' Extract Final Ratings
#'
#' Convenience function to extract just the final ratings from Elo results.
#'
#' @param elo_results List returned by calculate_all_ratings()
#' @return Named numeric vector of final ratings
#' @export
extract_final_ratings <- function(elo_results) {
  if (!is.list(elo_results) || !"final_ratings" %in% names(elo_results)) {
    stop("elo_results must be a list containing 'final_ratings'")
  }
  return(elo_results$final_ratings)
}


#' Predict Game Outcome Probabilities
#'
#' Predicts win probability for each player in an upcoming game
#' based on current Elo ratings.
#'
#' @param player_ratings Named numeric vector of current Elo ratings for players
#' @param D Numeric scale parameter. Default is 400.
#' @return Named numeric vector of win probabilities (sum to 1)
#' @export
#' @examples
#' ratings <- c(Alice = 1200, Bob = 1000, Charlie = 1100)
#' predict_game_outcome(ratings)
predict_game_outcome <- function(player_ratings, D = 400) {
  if (!is.numeric(player_ratings) || length(player_ratings) < 2) {
    stop("player_ratings must be a numeric vector with at least 2 players")
  }

  if (is.null(names(player_ratings))) {
    names(player_ratings) <- paste0("Player", seq_along(player_ratings))
  }

  players <- names(player_ratings)
  N <- length(players)
  win_probs <- numeric(N)
  names(win_probs) <- players

  # Calculate expected score for each player
  for (i in seq_along(players)) {
    player <- players[i]
    opponents <- players[-i]
    win_probs[player] <- get_expected_score(
      player_ratings[player],
      player_ratings[opponents],
      D = D
    )
  }

  # Normalise to sum to 1 (win probabilities)
  win_probs <- win_probs / sum(win_probs)

  return(win_probs)
}


#' Summarise Player Statistics
#'
#' Creates a summary table of player performance metrics.
#'
#' @param game_data Data frame of game results
#' @param elo_results List returned by calculate_all_ratings()
#' @return Data frame with columns: player, current_rating, n_games, n_wins,
#'   n_losses, win_rate (sorted by rating descending)
#' @export
#' @examples
#' \dontrun{
#' results <- calculate_all_ratings(game_data)
#' summary <- summarise_player_stats(game_data, results)
#' }
summarise_player_stats <- function(game_data, elo_results) {
  validate_game_data(game_data)

  if (!is.list(elo_results) || !"final_ratings" %in% names(elo_results)) {
    stop("elo_results must be a list containing 'final_ratings'")
  }

  # Extract current ratings
  # Convert named vector to data frame with explicit column naming
  current_ratings <- data.frame(
    player = names(elo_results$final_ratings),
    current_rating = as.numeric(elo_results$final_ratings),
    stringsAsFactors = FALSE
  )

  # Calculate game statistics
  player_columns <- colnames(game_data)[!colnames(game_data) %in% c("game_id", "date")]

  # First, calculate the worst rank per game (before pivoting)
  game_max_ranks <- game_data %>%
    tidyr::pivot_longer(
      cols = dplyr::all_of(player_columns),
      names_to = "player",
      values_to = "rank"
    ) %>%
    dplyr::filter(!is.na(rank)) %>%
    dplyr::group_by(game_id) %>%
    dplyr::summarise(max_rank_in_game = max(rank, na.rm = TRUE), .groups = "drop")

  # Then pivot and join with max ranks
  summary_data <- game_data %>%
    tidyr::pivot_longer(
      cols = dplyr::all_of(player_columns),
      names_to = "player",
      values_to = "rank"
    ) %>%
    dplyr::filter(!is.na(rank)) %>%
    dplyr::left_join(game_max_ranks, by = "game_id") %>%
    dplyr::group_by(player) %>%
    dplyr::summarise(
      n_games = dplyr::n(),
      n_wins = sum(rank == 1),
      n_losses = sum(rank == max_rank_in_game),
      win_rate = n_wins / n_games,
      .groups = "drop"
    ) %>%
    dplyr::left_join(current_ratings, by = "player") %>%
    dplyr::relocate(current_rating, .after = player) %>%
    dplyr::arrange(dplyr::desc(current_rating))

  return(summary_data)
}
