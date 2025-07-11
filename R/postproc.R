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
#' @param path output .tex file
#' @return NULL
#' @export
model_summary_table <- function(waic_list,
                                path = "./outputs/model_waic.tex") {
    df <- purrr::imap_dfr(
        waic_list,
        ~ data.frame(
            model = .y,
            waic = .x$estimates["waic", "Estimate"]
        )
    )

    tex <- knitr::kable(
        df,
        format = "latex",
        booktabs = TRUE,
        digits = 2,
        col.names = c("model", "waic")
    )

    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    writeLines(tex, path)
    invisible(NULL)
}

#' diagnostic_plots
#'
#' saves density + pairs + effect plots to disk
#'
#' @param fit stanreg
#' @param model_id character id
#' @return NULL
#' @export
diagnostic_plots <- function(fit, model_id) {
    out_dir <- "./figs"
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

    # density (use full array, keeps chain dimension)
    dens <- bayesplot::mcmc_dens_overlay(as.array(fit)) +
        ggplot2::theme_bw()

    ggplot2::ggsave(
        file.path(out_dir, paste0(model_id, "_dens.png")),
        dens,
        width = 6, height = 4, dpi = 300
    )

    # pairs
    pr <- bayesplot::mcmc_pairs(as.matrix(fit))
    ggplot2::ggsave(
        file.path(out_dir, paste0(model_id, "_pairs.png")),
        pr,
        width = 6, height = 6, dpi = 300
    )

    # marginal effects (simple example)
    eff <- rstanarm::posterior_linpred(fit, transform = TRUE) |>
        as.data.frame() |>
        tidyr::pivot_longer(dplyr::everything(),
            names_to = "obs", values_to = "pred"
        ) |>
        ggplot2::ggplot(ggplot2::aes(pred)) +
        ggplot2::geom_density() +
        ggplot2::theme_bw()

    ggplot2::ggsave(
        file.path(out_dir, paste0(model_id, "_effect.png")),
        eff,
        width = 6, height = 4, dpi = 300
    )
}
