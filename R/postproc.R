#' postproc.R
#' diagnostics, waic, plots, latex table output
#'
#' @keywords internal
"_PACKAGE"

#' compute_waic
#'
#' @param fit stanreg object
#' @return loo::waic object
#' @export
compute_waic <- function(fit) {
    loo::waic(fit)
}

#' model_summary_table
#'
#' @param waic_list named list of waic objects
#' @param model_versions a tibble with model_id and tar_group
#'   (if available) to match with waic_list
#'   (if waic_list is named by tar_group, this will join on that)
#'   otherwise, assumes order matches waic_list
#' @param path output .tex file
#' @return NULL
#' @export
model_summary_table <- function(
    waic_list, model_versions,
    path = "./outputs/model_waic.tex") {
    # Extract formulas from model_versions
    formulas <- purrr::map_chr(
        model_versions$formula,
        ~ paste(deparse(.x), collapse = "")
    )
    df <- tibble::tibble(
        model_id = model_versions$model_id,
        formula = formulas,
        waic = purrr::map_dbl(
            waic_list, ~ .x$estimates["waic", "Estimate"]
        )
    )

    tex <- knitr::kable(
        df,
        format = "latex",
        booktabs = TRUE,
        digits = 2,
        col.names = c("model", "formula", "waic")
    )

    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    writeLines(tex, path)
    invisible(NULL)
}

#' diagnostic_plots
#'   saves density, pairs, and effect plots to disk
#'
#' @param fit       stanreg
#' @param model_id  character id, e.g. "model_01"
#' @return          NULL
#' @export
diagnostic_plots <- function(fit, model_id, testing = FALSE) {
    # full draws array: iterations x chains x parameters
    arr <- as.array(fit)
    nch <- dim(arr)[2L] # number of chains
    pars <- dimnames(arr)$parameters[
        seq_len(min(5, dim(arr)[3L]))
    ]

    if (testing) {
        # 1. density
        dens <- if (nch > 1) {
            bayesplot::mcmc_dens_overlay(
                arr[, , pars, drop = FALSE]
            )
        } else {
            {
                bayesplot::mcmc_dens(
                    arr[, , pars, drop = FALSE]
                )
            } + ggplot2::theme_bw()
        }
        ggplot2::ggsave(
            here(
                "./figs/diagnostics/",
                paste0(model_id, "_dens.png")
            ),
            dens,
            width = 6, height = 4, dpi = 300
        )
    } else {
        # 1. density
        dens <- if (nch > 1) {
            bayesplot::mcmc_dens_overlay(
                arr[, , pars, drop = FALSE]
            )
        } else {
            {
                bayesplot::mcmc_dens(
                    arr[, , pars, drop = FALSE]
                )
            } + ggplot2::theme_bw()
        }
        ggplot2::ggsave(
            here(
                "./figs/diagnostics/",
                paste0(model_id, "_dens.png")
            ),
            dens,
            width = 6, height = 4, dpi = 300
        )

        # 2. pairs plot (at least 2 params)
        if (length(pars) >= 2) {
            mat <- posterior::as_draws_matrix(arr)[, pars, drop = FALSE]
            pr <- bayesplot::mcmc_pairs(mat, pars = pars)
            ggplot2::ggsave(
                here(
                    "./figs/diagnostics/",
                    paste0(model_id, "_pairs.png")
                ),
                pr,
                width = 6, height = 6, dpi = 300
            )
        }

        # 3. posterior predictive density
        ppc <- rstanarm::posterior_predict(fit) |>
            as.data.frame() |>
            tidyr::pivot_longer(
                dplyr::everything(),
                names_to  = "obs",
                values_to = "pred"
            ) |>
            ggplot2::ggplot(ggplot2::aes(pred)) +
            ggplot2::geom_density() +
            ggplot2::theme_bw()

        ggplot2::ggsave(
            here(
                "./figs/diagnostics/",
                paste0(model_id, "_ppc.png")
            ),
            ppc,
            width = 6, height = 4, dpi = 300
        )

        # 4. coefficient intervals
        draws <- posterior::as_draws_matrix(fit)

        # keep only coefficient columns: rstanarm stores as
        # "(Intercept)", "x1", etc
        coef_cols <- colnames(draws)[
            colnames(draws) %in% names(fit$coefficients)
        ]

        if (length(coef_cols) > 0) {
            coef_df <- posterior::summarise_draws(
                draws[, coef_cols, drop = FALSE]
            ) |>
                dplyr::select(
                    variable, median,
                    lower = q5, upper = q95
                ) |>
                dplyr::arrange(median)
            # rename for ggplot
            colnames(coef_df) <- c("variable", "median", "lower", "upper")

            coef_plot <- ggplot2::ggplot(
                coef_df,
                ggplot2::aes(x = median, y = variable)
            ) +
                ggplot2::geom_vline(
                    xintercept = 0, linetype = "dashed"
                ) +
                ggplot2::geom_pointrange(
                    ggplot2::aes(xmin = lower, xmax = upper),
                    fatten = 1, size = 0.4
                ) +
                ggplot2::labs(
                    x = "Effect (median ± 90% CI)", y = NULL
                ) +
                ggplot2::theme_bw()

            ggplot2::ggsave(
                here(
                    "./figs/diagnostics/",
                    paste0(model_id, "_coef.png")
                ),
                coef_plot,
                width = 6,
                height = 4,
                dpi = 300
            )
        }
    }
}
