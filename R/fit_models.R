#' fit_models.R
#' wrappers for rstanarm fits and tidy outputs
#'
#' @keywords internal
"_PACKAGE"

#' fit_one_model
#'
#' @param spec tibble row with formula, family, prior_sd
#' @param data training data.frame
#' @return rstanarm::stanreg object
#' @export
fit_one_model <- function(spec, data) {
    rstanarm::stan_glm(
        formula   = spec$formula[[1]],
        data      = data,
        family    = spec$family[[1]],
        prior     = rstanarm::normal(location = 0, scale = spec$prior_sd),
        chains    = 4,
        iter      = 2000,
        cores     = 4,
        seed      = 123
    )
}

#' fit_models_map
#'
#' @param formula this should be a column of a tibble
#' @param family this should be a column of a tibble
#' @param prior_sd this should be a column of a tibble
#' @param data training data.frame
#' @return rstanarm::stanreg object
#' @export
fit_models_map <- function(formula, family, prior_sd, data) {
    rstanarm::stan_glm(
        formula   = formula,
        data      = data,
        family    = family,
        prior     = rstanarm::normal(location = 0, scale = prior_sd),
        chains    = 4,
        iter      = 2000,
        cores     = 4,
        seed      = 123
    )
}
