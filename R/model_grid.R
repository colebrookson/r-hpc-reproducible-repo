#' model_grid.R
#'
#' build a tibble of model specs:
#'   * formula
#'   * family (gaussian, student_t)
#'   * prior_sd (normal(0, sd))
#'
#' @return tibble
#' @export
build_model_grid <- function() {
    form_vec <- c(
        y ~ x1 + x2,
        y ~ x1 + x2 + x3,
        y ~ x1 + x2 + x3 + x4 + f1,
        y ~ x1 * f1 + x2 + x3 + x5 + f2
    )

    family_vec <- list(
        gaussian = stats::gaussian(),
        student  = rstanarm::student_t(df = 7)
    )

    prior_sd <- c(1, 2.5)

    expand.grid(
        formula = form_vec,
        family = family_vec,
        prior_sd = prior_sd,
        stringsAsFactors = FALSE
    ) |>
        tibble::as_tibble()
}
