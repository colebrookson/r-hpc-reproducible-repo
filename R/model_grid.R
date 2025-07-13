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
    # vectors of choices
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

    # expand over *indices* (avoids coercion)
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

    grid <- tibble::as_tibble(grid)
    grid$model_id <- paste0("model_", seq_len(nrow(grid)))

    # Save as LaTeX table
    tex <- knitr::kable(
        grid,
        format = "latex",
        booktabs = TRUE,
        digits = 2,
        col.names = names(grid)
    )
    dir.create("outputs", showWarnings = FALSE)
    writeLines(tex, "outputs/model_grid.tex")

    grid
}
