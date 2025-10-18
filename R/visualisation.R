#' Plot Rating History
#'
#' Creates a line plot showing how player ratings changed over time.
#'
#' @param ratings_history Data frame with columns: date, player, rating, game_id
#' @param title Character string for plot title. Default is NULL (no title).
#' @param interactive Logical. If TRUE, returns interactive plotly plot.
#'   If FALSE, returns static ggplot2 plot. Default is FALSE.
#' @param x_axis Character string: "date" or "game_id". Default is "date".
#'   "date" plots ratings against date (can cause overlapping when multiple games occur on same date).
#'   "game_id" plots ratings against sequential game number with date labels,
#'   avoiding overlap and showing each game distinctly. Note: the date scale is not linear
#'   when using "game_id" - games are evenly spaced regardless of time between them.
#' @return A ggplot2 or plotly plot object
#' @export
#' @examples
#' \dontrun{
#' results <- calculate_all_ratings(game_data)
#' plot_rating_history(results$ratings_history, title = "My Game Ratings")
#' plot_rating_history(results$ratings_history, interactive = TRUE)
#' plot_rating_history(results$ratings_history, x_axis = "game_id")
#' }
plot_rating_history <- function(ratings_history,
                             title = NULL,
                             interactive = FALSE,
                             x_axis = "date") {

  if (!is.data.frame(ratings_history)) {
    stop("ratings_history must be a data frame")
  }

  if (!x_axis %in% c("date", "game_id")) {
    stop("x_axis must be either 'date' or 'game_id'")
  }

  required_cols <- c("date", "player", "rating")
  if (!all(required_cols %in% colnames(ratings_history))) {
    stop("ratings_history must contain columns: date, player, rating")
  }

  if (x_axis == "game_id" && !"game_id" %in% colnames(ratings_history)) {
    stop("ratings_history must contain 'game_id' column when x_axis = 'game_id'")
  }

  # Create base ggplot
  if (x_axis == "date") {
    # Original behaviour: plot by date
    p <- ggplot2::ggplot(ratings_history, ggplot2::aes(x = date, y = rating, colour = player)) +
      ggplot2::geom_line(linewidth = 1) +
      ggplot2::labs(
        title = title,
        x = "Date",
        y = "Rating",
        colour = "Player"
      ) +
      ggplot2::theme(
        axis.text.x = ggplot2::element_text(angle = 90, hjust = 1, vjust = 0.5, size = 8)
      )
  } else {
    # New behaviour: plot by game_id with date labels
    # Get unique game_id-date pairs for x-axis labels
    game_dates <- ratings_history %>%
      dplyr::select(game_id, date) %>%
      dplyr::distinct() %>%
      dplyr::arrange(game_id)

    # Adaptive date formatting and label selection based on time range
    date_range_days <- as.numeric(diff(range(game_dates$date)))

    if (date_range_days > 60) {
      # Long range: show "Jan 2023" format, unique months only
      game_dates <- game_dates %>%
        dplyr::mutate(month_year = format(date, "%b %Y"))

      # Get first game_id for each unique month
      unique_months <- game_dates %>%
        dplyr::group_by(month_year) %>%
        dplyr::slice(1) %>%
        dplyr::ungroup()

      selected_labels <- unique_months
      date_labels <- unique_months$month_year
    } else {
      # Short range: show "03 Jan" format, unique days only
      game_dates <- game_dates %>%
        dplyr::mutate(day_month = format(date, "%d %b"))

      # Get first game_id for each unique day
      unique_days <- game_dates %>%
        dplyr::group_by(day_month) %>%
        dplyr::slice(1) %>%
        dplyr::ungroup()

      selected_labels <- unique_days
      date_labels <- unique_days$day_month
    }

    p <- ggplot2::ggplot(ratings_history, ggplot2::aes(x = game_id, y = rating, colour = player)) +
      ggplot2::geom_line(linewidth = 1) +
      ggplot2::scale_x_continuous(
        breaks = selected_labels$game_id,
        labels = date_labels
      ) +
      ggplot2::labs(
        title = title,
        x = "Games (by Date)",
        y = "Rating",
        colour = "Player"
      ) +
      ggplot2::theme(
        axis.text.x = ggplot2::element_text(angle = 90, hjust = 1, vjust = 0.5, size = 8)
      )
  }

  # Apply common theme
  p <- p +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      legend.position = "right",
      axis.text.x = ggplot2::element_text(angle = 90, hjust = 1, vjust = 0.5, size = 8)
    )

  # Return interactive or static plot
  if (interactive) {
    if (!requireNamespace("plotly", quietly = TRUE)) {
      stop("plotly package is required for interactive plots.\n",
           "Please install it with: install.packages(\"plotly\")")
    }

    # Convert to plotly
    plotly_obj <- plotly::ggplotly(p)

    # JavaScript for hover effect - grey out non-hovered lines
    hoverer <- "
    function(el, x) {
      el.on('plotly_hover', function(d) {
        var curveNum = d.points[0].curveNumber;
        var nTraces = el.data.length;
        var opacities = [];
        for (var i = 0; i < nTraces; i++) {
          opacities[i] = (i === curveNum) ? 1 : 0.2;
        }
        Plotly.restyle(el, {'opacity': opacities});
      });

      el.on('plotly_unhover', function(d) {
        var nTraces = el.data.length;
        var opacities = [];
        for (var i = 0; i < nTraces; i++) {
          opacities[i] = 1;
        }
        Plotly.restyle(el, {'opacity': opacities});
      });
    }"

    if (requireNamespace("htmlwidgets", quietly = TRUE)) {
      plotly_obj <- plotly_obj %>% htmlwidgets::onRender(hoverer)
    }

    return(plotly_obj)
  } else {
    return(p)
  }
}
