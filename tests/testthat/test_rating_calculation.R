test_that("scores sum to 1 for all methods", {
  # Test with various game sizes
  test_cases <- list(
    c(1, 2),
    c(1, 2, 3),
    c(1, 2, 3, 4),
    c(1, 2, 3, 4, 5)
  )

  for (ranks in test_cases) {
    # Linear scores
    linear_scores <- calculate_scores(ranks, method = "linear")
    expect_equal(sum(linear_scores), 1, tolerance = 1e-9)

    # Exponential scores with different alphas
    alphas <- c(1.2, 1.4, 1.8, 2.0)
    for (alpha in alphas) {
      exp_scores <- calculate_scores(ranks, method = "exponential", alpha = alpha)
      expect_equal(sum(exp_scores), 1, tolerance = 1e-9)
    }
  }
})

test_that("tied ranks receive equal scores", {
  # Two players tied for second place
  test_ranks <- c(Alice = 1, Bob = 2, Charlie = 2, David = 4)

  linear_scores <- calculate_scores(test_ranks, method = "linear")
  expect_equal(unname(linear_scores["Bob"]), unname(linear_scores["Charlie"]), tolerance = 1e-9)
  expect_equal(sum(linear_scores), 1, tolerance = 1e-9)

  exp_scores <- calculate_scores(test_ranks, method = "exponential", alpha = 1.4)
  expect_equal(unname(exp_scores["Bob"]), unname(exp_scores["Charlie"]), tolerance = 1e-9)
  expect_equal(sum(exp_scores), 1, tolerance = 1e-9)
})

test_that("2-player exponential scoring is alpha-independent", {
  test_ranks <- c(PlayerA = 1, PlayerB = 2)
  alphas <- c(1.1, 1.4, 1.8, 2.0, 5.0, 10.0)

  results <- lapply(alphas, function(a) {
    calculate_scores(test_ranks, method = "exponential", alpha = a)
  })

  # All results should be identical
  for (i in 2:length(results)) {
    expect_equal(results[[1]], results[[i]], tolerance = 1e-9)
  }

  # Winner should get score of 1, loser should get 0
  expect_equal(unname(results[[1]]["PlayerA"]), 1, tolerance = 1e-9)
  expect_equal(unname(results[[1]]["PlayerB"]), 0, tolerance = 1e-9)
})

test_that("scoring handles NA values correctly", {
  test_ranks <- c(Alice = 1, Bob = 2, Charlie = NA, David = 3)

  linear_scores <- calculate_scores(test_ranks, method = "linear")
  expect_equal(unname(linear_scores["Charlie"]), 0)
  expect_equal(sum(linear_scores[!is.na(test_ranks)]), 1, tolerance = 1e-9)

  exp_scores <- calculate_scores(test_ranks, method = "exponential", alpha = 1.4)
  expect_equal(unname(exp_scores["Charlie"]), 0)
  expect_equal(sum(exp_scores[!is.na(test_ranks)]), 1, tolerance = 1e-9)
})

test_that("invalid inputs are rejected", {
  # alpha = 1 should fail
  expect_error(
    calculate_scores(c(1, 2, 3), method = "exponential", alpha = 1.0),
    "alpha cannot equal 1"
  )

  # alpha <= 0 should fail
  expect_error(
    calculate_scores(c(1, 2, 3), method = "exponential", alpha = 0),
    "alpha must be greater than 0"
  )

  # Invalid method should fail
  expect_error(
    calculate_scores(c(1, 2, 3), method = "invalid"),
    "method must be"
  )
})
test_that("rating changes sum to zero (zero-sum property)", {
  test_cases <- list(
    # 2-player game
    data.frame(game_id = 1, date = as.Date("2024-01-01"), A = 1, B = 2),
    # 3-player game
    data.frame(game_id = 1, date = as.Date("2024-01-01"), A = 1, B = 2, C = 3),
    # 4-player game
    data.frame(game_id = 1, date = as.Date("2024-01-01"), A = 1, B = 2, C = 3, D = 4),
    # 5-player game
    data.frame(game_id = 1, date = as.Date("2024-01-01"), A = 1, B = 2, C = 3, D = 4, E = 5)
  )

  initial_rating <- 1000

  for (game_data in test_cases) {
    results <- calculate_all_ratings(game_data, initial_rating = initial_rating, K = 32, alpha = 1.4)
    rating_changes <- results$final_ratings - initial_rating
    total_change <- sum(rating_changes)

    expect_equal(total_change, 0, tolerance = 1e-9)
  }
})

test_that("2-player games match standard Elo", {
  two_player_game <- data.frame(
    game_id = 1,
    date = as.Date("2024-01-01"),
    PlayerA = 1,
    PlayerB = 2
  )

  # Our implementation
  results_multi <- calculate_all_ratings(two_player_game, initial_rating = 1000, K = 32, alpha = 1.4)

  # Standard Elo calculation
  R_A <- 1000
  R_B <- 1000
  E_A <- 1 / (1 + 10^((R_B - R_A) / 400))
  E_B <- 1 / (1 + 10^((R_A - R_B) / 400))
  S_A <- 1  # Winner
  S_B <- 0  # Loser
  R_A_new <- R_A + 32 * (S_A - E_A)
  R_B_new <- R_B + 32 * (S_B - E_B)

  # Compare
  expect_equal(unname(results_multi$final_ratings["PlayerA"]), R_A_new, tolerance = 1e-9)
  expect_equal(unname(results_multi$final_ratings["PlayerB"]), R_B_new, tolerance = 1e-9)
})

test_that("expected scores sum to 1", {
  test_cases <- list(
    c(Alice = 1000, Bob = 1000),
    c(Alice = 1200, Bob = 1000, Charlie = 1100),
    c(A = 1000, B = 1200, C = 1100, D = 900),
    c(A = 1500, B = 1000, C = 1200, D = 1100, E = 950)
  )

  for (ratings in test_cases) {
    players <- names(ratings)

    # Calculate expected score for each player
    expected_scores <- sapply(players, function(p) {
      opponents <- players[players != p]
      get_expected_score(ratings[p], ratings[opponents], D = 400)
    })

    expect_equal(sum(expected_scores), 1, tolerance = 1e-9)
  }
})

test_that("calculation is deterministic", {
  set.seed(123)
  dates <- seq(as.Date("2024-01-01"), as.Date("2024-01-10"), by = "day")

  game_data <- data.frame(
    game_id = 1:10,
    date = dates,
    Alice = sample(1:3, 10, replace = TRUE),
    Bob = sample(1:3, 10, replace = TRUE),
    Charlie = sample(1:3, 10, replace = TRUE)
  )

  # Calculate ratings twice with same parameters
  results1 <- calculate_all_ratings(game_data, alpha = 1.4)
  results2 <- calculate_all_ratings(game_data, alpha = 1.4)

  # Results should be identical
  expect_equal(results1$final_ratings, results2$final_ratings, tolerance = 1e-15)
})

test_that("winner gains rating from equal opponents", {
  test_cases <- list(
    data.frame(game_id = 1, date = as.Date("2024-01-01"), A = 1, B = 2),
    data.frame(game_id = 1, date = as.Date("2024-01-01"), A = 1, B = 2, C = 3),
    data.frame(game_id = 1, date = as.Date("2024-01-01"), A = 1, B = 2, C = 3, D = 4)
  )

  initial_rating <- 1000

  for (game_data in test_cases) {
    results <- calculate_all_ratings(game_data, initial_rating = initial_rating, K = 32, alpha = 1.4)

    # Winner is player A (rank = 1)
    winner_change <- results$final_ratings["A"] - initial_rating

    expect_gte(winner_change, -1e-9)  # Should be >= 0 (allowing tiny numerical errors)
  }
})

test_that("invalid inputs are rejected", {
  valid_data <- data.frame(
    game_id = 1,
    date = as.Date("2024-01-01"),
    Alice = 1,
    Bob = 2
  )

  # Negative K
  expect_error(
    calculate_all_ratings(valid_data, K = -32),
    "K must be.*positive"
  )

  # Zero K
  expect_error(
    calculate_all_ratings(valid_data, K = 0),
    "K must be.*positive"
  )

  # Negative D
  expect_error(
    calculate_all_ratings(valid_data, D = -400),
    "D must be.*positive"
  )
})
