#' model_grid.R
#'
#' build a tibble of model specs:
#'   * formula  (list-column of formula objects)
#'   * family   (list-column of family objects)
#'   * prior_sd (numeric)
#'
#' @return tibble
#' @export
build_model_grid <- function() {
    # --------------------------------------------------------------------------
    # 1. vectors of choices -----------------------------------------------------
    # --------------------------------------------------------------------------
    form_vec <- list(
        y ~ x1 + x2,
        y ~ x1 + x2 + x3,
        y ~ x1 + x2 + x3 + x4 + f1,
        y ~ x1 * f1 + x2 + x3 + x5 + f2
    )

    family_vec <- list(
        gaussian = stats::gaussian(),
        lognormal = stats::gaussian(link = "log")
    )

    prior_sd_vec <- c(1, 2.5)

    # --------------------------------------------------------------------------
    # 2. expand over *indices* (avoids coercion) -------------------------------
    # --------------------------------------------------------------------------
    grid <- expand.grid(
        formula_id = seq_along(form_vec),
        family_id = seq_along(family_vec),
        prior_sd = prior_sd_vec,
        KEEP.OUT.ATTRS = FALSE,
        stringsAsFactors = FALSE
    )

    # --------------------------------------------------------------------------
    # 3. replace indices with the actual objects -------------------------------
    # --------------------------------------------------------------------------
    grid$formula <- form_vec[grid$formula_id]
    grid$family <- family_vec[grid$family_id]

    grid$formula_id <- NULL
    grid$family_id <- NULL

    tibble::as_tibble(grid)
}
