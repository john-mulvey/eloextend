test_that("data validation works correctly", {
  # Valid data should pass
  valid_data <- data.frame(
    game_id = 1,
    date = as.Date("2024-01-01"),
    Alice = 1,
    Bob = 2
  )

  expect_true(validate_game_data(valid_data))

  # Missing game_id should fail
  invalid_data <- data.frame(
    date = as.Date("2024-01-01"),
    Alice = 1,
    Bob = 2
  )
  expect_error(validate_game_data(invalid_data), "game_id")

  # No player columns should fail
  invalid_data <- data.frame(
    game_id = 1,
    date = as.Date("2024-01-01")
  )
  expect_error(validate_game_data(invalid_data), "player column")
})

test_that("win probabilities sum to 1", {
  test_cases <- list(
    c(Alice = 1000, Bob = 1000),
    c(Alice = 1200, Bob = 1000, Charlie = 1100),
    c(A = 1000, B = 1200, C = 1100, D = 900),
    c(A = 1500, B = 1000, C = 1200, D = 1100, E = 950)
  )

  for (ratings in test_cases) {
    win_probs <- predict_game_outcome(ratings)
    expect_equal(sum(win_probs), 1, tolerance = 1e-9)
  }
})

test_that("loss calculation is accurate per game", {
  # Test data that would expose the bug if losses were calculated incorrectly
  test_data <- data.frame(
    game_id = c(1, 2),
    date = as.Date(c("2024-01-01", "2024-01-02")),
    Alice = c(2, 2),    # Lost 2-player game (2nd of 2), came 2nd in 4-player game (not last)
    Bob = c(1, 3),      # Won 2-player game, came 3rd in 4-player game (not last)
    Charlie = c(NA, 4), # Only in game 2, came last
    David = c(NA, 1)    # Only in game 2, won
  )

  results <- calculate_all_ratings(test_data)
  summary <- summarise_player_stats(test_data, results)

  # Alice should have 1 loss (game 1 only), not 2
  expect_equal(summary$n_losses[summary$player == "Alice"], 1)
  expect_equal(summary$n_losses[summary$player == "Bob"], 0)
  expect_equal(summary$n_losses[summary$player == "Charlie"], 1)
  expect_equal(summary$n_losses[summary$player == "David"], 0)
})

test_that("generate_toy_data creates valid data", {
  start_date <- as.Date("2023-01-01")
  end_date <- as.Date("2023-01-31")
  players <- c("Alice", "Bob", "Charlie", "David")

  toy_data <- generate_toy_data(start_date, end_date, players, n_games = 20)

  # Should be valid game data
  expect_true(validate_game_data(toy_data))

  # Should have correct number of games
  expect_equal(nrow(toy_data), 20)

  # Should have correct columns
  expect_true(all(c("game_id", "date", players) %in% colnames(toy_data)))

  # Dates should be in range
  expect_true(all(toy_data$date >= start_date & toy_data$date <= end_date))
})

test_that("extract_final_ratings works correctly", {
  game_data <- data.frame(
    game_id = 1,
    date = as.Date("2024-01-01"),
    Alice = 1,
    Bob = 2
  )

  results <- calculate_all_ratings(game_data)
  final_ratings <- extract_final_ratings(results)

  expect_equal(final_ratings, results$final_ratings)
  expect_true(is.numeric(final_ratings))
  expect_true(!is.null(names(final_ratings)))
})
