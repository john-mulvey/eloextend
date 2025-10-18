#' Calculate Scores from Rankings
#'
#' Converts player rankings into weighted scores that sum to 1.
#' Higher ranks (lower numbers) receive higher scores. Handles NA values
#' for non-participating players.
#'
#' Single-player games (N=1) are valid input and return a score of 1 for the
#' sole participant. However, such games are meaningless for rating updates since
#' there is no competition, and update_ratings() will not modify ratings for them.
#'
#' For 2-player games with exponential scoring, the formula simplifies to give
#' the winner a score of 1 and the loser a score of 0, regardless of alpha.
#' This ensures convergence to standard Elo for head-to-head matches.
#'
#' Mathematical explanation: For N=2 with ranks 1 and 2, the exponential formula gives:
#' - Winner (rank 1): (alpha^(2-1) - 1) / ((alpha^(2-1) - 1) + (alpha^(2-2) - 1)) = (alpha - 1) / (alpha - 1 + 0) = 1
#' - Loser (rank 2):  (alpha^(2-2) - 1) / ((alpha^(2-1) - 1) + (alpha^(2-2) - 1)) = 0 / (alpha - 1) = 0
#' Thus, alpha cancels out for the 2-player case.
#'
#' @param ranks Named numeric vector of rankings (1 = best, 2 = second, etc.)
#'   Names should be player identifiers. NA values indicate non-participating players.
#'   Tied ranks are supported: players with the same rank receive identical scores.
#' @param method Character string: "linear" or "exponential" (default).
#'   Linear uses arithmetic weighting, exponential uses geometric weighting.
#' @param alpha Numeric exponent for exponential weighting (only used if method = "exponential").
#'   Must be > 0 and != 1. Higher values give more weight to top finishers. Default is 1.4.
#'   Note: For N=2 players, alpha has no effect on the result.
#' @return Named numeric vector of scores (same length and names as ranks).
#'   Non-participating players (NA ranks) receive a score of 0.
#' @export
#' @examples
#' # Simple ranking without NAs
#' calculate_scores(c(Alice = 1, Bob = 2, Charlie = 3, David = 4), method = "linear")
#' calculate_scores(c(Alice = 1, Bob = 2, Charlie = 3, David = 4),
#'                  method = "exponential", alpha = 1.4)
#'
#' # With non-participating players (NAs)
#' ranks <- c(Alice = 1, Bob = 3, Charlie = 2, David = NA)
#' calculate_scores(ranks, method = "exponential", alpha = 1.4)
#'
#' # With tied ranks (tied players receive equal scores)
#' calculate_scores(c(Alice = 1, Bob = 2, Charlie = 2, David = 4), method = "linear")
#'
#' # For 2 players with exponential, alpha doesn't matter:
#' calculate_scores(c(Alice = 1, Bob = 2), method = "exponential", alpha = 1.4)
#' calculate_scores(c(Alice = 1, Bob = 2), method = "exponential", alpha = 10)
calculate_scores <- function(ranks, method = "exponential", alpha = 1.4) {
  # Validate input
  if (!is.numeric(ranks)) {
    stop("ranks must be a numeric vector")
  }

  if (!method %in% c("linear", "exponential")) {
    stop("method must be 'linear' or 'exponential'")
  }

  # Filter out NA values (non-participating players)
  valid_ranks <- ranks[!is.na(ranks)]
  N <- length(valid_ranks)

  if (N == 0) {
    return(numeric(0))
  }

  # Single player case
  if (N == 1) {
    result <- numeric(length(ranks))
    result[!is.na(ranks)] <- 1
    names(result) <- names(ranks)
    return(result)
  }

  # Calculate scores based on method (for participating players only)
  if (method == "linear") {
    scores <- (N - rank(valid_ranks, ties.method = "average")) / (N * (N - 1) / 2)
  } else {
    # Exponential method
    # Validate alpha
    if (!is.numeric(alpha) || length(alpha) != 1) {
      stop("alpha must be a single numeric value")
    }

    if (alpha <= 0) {
      stop("alpha must be greater than 0")
    }

    if (abs(alpha - 1) < .Machine$double.eps) {
      stop("alpha cannot equal 1 (exponential scores undefined)")
    }

    # Exponentially decreasing scores based on rank
    exponentiated_scores <- alpha^(N - rank(valid_ranks, ties.method = "average")) - 1

    # Normalise to sum to 1
    scores <- exponentiated_scores / sum(exponentiated_scores)
  }

  # Create result vector with original structure (including NAs)
  result <- numeric(length(ranks))
  result[!is.na(ranks)] <- scores
  names(result) <- names(ranks)

  return(result)
}
#' Calculate Expected Score for a Player
#'
#' Calculates the expected score for a player against a set of opponents
#' based on current Elo ratings.
#'
#' @param player_rating Numeric Elo rating of the player
#' @param opponent_ratings Numeric vector of opponent Elo ratings
#' @param D Numeric scale parameter for Elo calculation. Default is 400.
#' @return Numeric expected score (between 0 and 1)
#' @export
#' @examples
#' get_expected_score(1200, c(1000, 1100, 1300), D = 400)
get_expected_score <- function(player_rating, opponent_ratings, D = 400) {
  if (!is.numeric(player_rating) || length(player_rating) != 1) {
    stop("player_rating must be a single numeric value")
  }

  if (!is.numeric(opponent_ratings) || length(opponent_ratings) == 0) {
    stop("opponent_ratings must be a non-empty numeric vector")
  }

  if (!is.numeric(D) || length(D) != 1 || D <= 0) {
    stop("D must be a single positive numeric value")
  }

  N <- length(opponent_ratings) + 1  # Total players including this player

  # Sum of expected pairwise wins against each opponent
  expected_pairwise_wins <- sum(sapply(opponent_ratings, function(opp_rating) {
    1 / (1 + 10^((opp_rating - player_rating) / D))
  }))

  # Normalise by total number of pairwise matchups
  expected_score <- expected_pairwise_wins / (N * (N - 1) / 2)

  return(expected_score)
}


#' Update Ratings After a Single Game
#'
#' Updates player ratings based on the results of a single game.
#' This is the core atomic operation for rating updates.
#'
#' This implementation treats multiplayer games as the sum of all pairwise matchups
#' between participants. For games with exactly 2 players, this reduces to standard
#' Elo ratings, ensuring backward compatibility. The zero-sum property is maintained:
#' rating changes across all participants in a game sum to zero (within floating-point
#' precision).
#'
#' Single-player games (N=1) are valid input but will not result in any rating changes,
#' as there is no competition. Games with 0 participating players are also handled
#' gracefully with no rating updates.
#'
#' @param game_ranks Named numeric vector of player ranks for this game (1 = winner, NA = did not play)
#' @param current_ratings Named numeric vector of current player ratings
#' @param K Numeric K-factor controlling rating volatility. Default is 32.
#' @param method Character string: "linear" or "exponential" scoring. Default is "exponential".
#' @param alpha Numeric exponent for exponential scoring. Default is 1.4.
#' @param D Numeric scale parameter for Elo calculation. Default is 400.
#' @return Named numeric vector of updated ratings (for all players, not just participants)
#' @export
#' @examples
#' current_ratings <- c(Alice = 1000, Bob = 1000, Charlie = 1000)
#' game_ranks <- c(Alice = 1, Bob = 2, Charlie = NA)
#' new_ratings <- update_ratings(game_ranks, current_ratings, K = 32)
update_ratings <- function(game_ranks,
                           current_ratings,
                           K = 32,
                           method = "exponential",
                           alpha = 1.4,
                           D = 400) {

  # Validate inputs
  if (!is.numeric(game_ranks) || is.null(names(game_ranks))) {
    stop("game_ranks must be a named numeric vector")
  }

  if (!is.numeric(current_ratings) || is.null(names(current_ratings))) {
    stop("current_ratings must be a named numeric vector")
  }

  if (!is.numeric(K) || length(K) != 1 || K <= 0) {
    stop("K must be a single positive numeric value")
  }

  if (!is.numeric(D) || length(D) != 1 || D <= 0) {
    stop("D must be a single positive numeric value")
  }

  # Make a copy of current ratings to update
  updated_ratings <- current_ratings

  # Calculate game scores
  game_scores <- calculate_scores(game_ranks, method = method, alpha = alpha)

  # Identify participating players
  participating_players <- names(game_ranks)[!is.na(game_ranks)]
  N <- length(participating_players)

  # Only update ratings if multiple players participated
  if (N > 1) {
    # Save ratings snapshot before game (critical for simultaneous updates)
    ratings_before_game <- current_ratings

    for (player_A in participating_players) {
      # Get ratings of other players FROM BEFORE THIS GAME
      other_players <- participating_players[participating_players != player_A]
      opponent_ratings <- ratings_before_game[other_players]

      # Calculate expected and actual scores
      expected_score <- get_expected_score(ratings_before_game[player_A], opponent_ratings, D = D)
      actual_score <- game_scores[player_A]

      # Update rating
      rating_change <- K * (N - 1) * (actual_score - expected_score)
      updated_ratings[player_A] <- updated_ratings[player_A] + rating_change
    }
  }

  return(updated_ratings)
}


#' Calculate All Ratings from Game Data
#'
#' Calculates Elo ratings for all players across a series of games.
#' Returns both final ratings and complete rating history.
#'
#' This function processes games sequentially, updating ratings after each game
#' using the update_ratings() function. It can be used for initial calculation
#' or for incremental updates by providing a subset of games.
#'
#' @param data Data frame with columns: game_id, date, and one column per player
#'   containing their rank in each game (1 = winner, NA = did not play)
#' @param initial_rating Numeric starting Elo rating for all players. Default is 1000.
#' @param K Numeric K-factor controlling rating volatility. Default is 32.
#' @param method Character string: "linear" or "exponential" scoring. Default is "exponential".
#' @param alpha Numeric exponent for exponential scoring. Default is 1.4.
#'   For 2-player games, alpha has no effect (winner always gets score 1, loser gets 0).
#' @param D Numeric scale parameter for Elo calculation. Default is 400.
#' @return List with two elements:
#'   \itemize{
#'     \item final_ratings: Named numeric vector of final Elo ratings
#'     \item ratings_history: Data frame with columns (date, player, rating, game_id)
#'   }
#' @export
#' @examples
#' # Three-player game example demonstrating multiplayer Elo
#' game_data <- data.frame(
#'   game_id = 1:3,
#'   date = as.Date(c("2024-01-01", "2024-01-02", "2024-01-03")),
#'   Alice = c(1, 2, 1),
#'   Bob = c(2, 1, 3),
#'   Charlie = c(3, 3, 2)
#' )
#' results <- calculate_all_ratings(game_data)
#' print(results$final_ratings)
#' head(results$ratings_history)
calculate_all_ratings <- function(data,
                                   initial_rating = 1000,
                                   K = 32,
                                   method = "exponential",
                                   alpha = 1.4,
                                   D = 400) {

  # Validate inputs
  if (!is.data.frame(data)) {
    stop("data must be a data frame")
  }

  required_cols <- c("game_id", "date")
  if (!all(required_cols %in% colnames(data))) {
    stop("data must contain columns: game_id, date")
  }

  if (!is.numeric(initial_rating) || length(initial_rating) != 1) {
    stop("initial_rating must be a single numeric value")
  }

  if (!is.numeric(K) || length(K) != 1 || K <= 0) {
    stop("K must be a single positive numeric value")
  }

  if (!is.numeric(D) || length(D) != 1 || D <= 0) {
    stop("D must be a single positive numeric value")
  }

  # Identify player columns
  player_columns <- colnames(data)[!colnames(data) %in% c("game_id", "date")]

  if (length(player_columns) == 0) {
    stop("data must contain at least one player column")
  }

  # Initialise ratings
  ratings <- setNames(rep(initial_rating, length(player_columns)), player_columns)

  # Sort data by date and game_id
  data <- data %>%
    dplyr::arrange(date, game_id)

  # Initialise list to store ratings history (more efficient than growing data frame)
  ratings_history_list <- vector("list", nrow(data))

  # Process each game
  for (i in 1:nrow(data)) {
    game_ranks <- setNames(as.numeric(data[i, player_columns]), player_columns)

    # Update ratings using the single-game function
    ratings <- update_ratings(game_ranks, ratings, K = K, method = method, alpha = alpha, D = D)

    # Record ratings after this game for all players
    ratings_history_list[[i]] <- data.frame(
      date = rep(data$date[i], length(player_columns)),
      player = player_columns,
      rating = ratings[player_columns],
      game_id = rep(data$game_id[i], length(player_columns)),
      stringsAsFactors = FALSE
    )
  }

  # Combine all history entries into single data frame
  ratings_history <- dplyr::bind_rows(ratings_history_list)

  # Remove auto-generated rownames
  rownames(ratings_history) <- NULL

  return(list(
    final_ratings = ratings,
    ratings_history = ratings_history
  ))
}
