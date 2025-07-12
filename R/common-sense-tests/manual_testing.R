#!/usr/bin/env Rscript
# ---------------------------------------------------------------
#  debug_pipeline.R
#  --------------------------------------------------------------
#  Runs the full data‑prep → model‑fit → diagnostics loop
#  **without** the targets framework so you can step through
#  interactively and isolate plotting problems.
#
#  Usage (from repo root):
#    Rscript example/debug_pipeline.R      # batch
#    # or inside R:
#    source("example/debug_pipeline.R")    # interactive
#
#  Outputs:
#    • PNGs saved to  example/figs_debug/
#    • Any error message printed immediately
# ---------------------------------------------------------------

library(targets)
targets::tar_source("R") # load all helper functions

# ---- 0. data -----------------------------------------------------------------
raw <- read_demo_data() # from data_io.R
clean <- clean_demo_data(raw)

# ---- 1. model specifications -------------------------------------------------
spec_grid <- build_model_grid() # from model_grid.R
spec_rows <- split(spec_grid, seq_len(nrow(spec_grid)))

# ---- 2. iterate over each spec ----------------------------------------------
outdir <- "figs/figs_debug"
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

for (i in seq_along(spec_rows)) {
    spec <- spec_rows[[i]]
    message("\n--- fitting model ", i, "/", length(spec_rows), " ---")

    # 2a. fit ------------------------------------------------------------------
    fit <- try(
        fit_one_model(spec, clean), # from fit_models.R
        silent = TRUE
    )

    if (inherits(fit, "try-error")) {
        message("❌ Stan fit failed for model ", i)
        print(fit)
        next
    }

    # 2b. diagnostics ----------------------------------------------------------
    id <- sprintf("debug_model_%02d", i)
    try(
        compute_waic(
            fit = fit
        ),
        silent = FALSE # want full traceback
    )
    message("✔ finished waic calculation for ", id)

    try(
        model_summary_table(
            waic_list = list(id = fit), # single model, so list with one element
            path = file.path(outdir, paste0(id, "_waic.tex"))
        ),
        silent = FALSE # want full traceback
    )

    try(
        diagnostic_plots(
            fit = fit,
            model_id = id # from postproc.R
        ),
        silent = FALSE # want full traceback
    )
    message("✔ finished diagnostics for ", id)
}

message("\nAll done. Check PNGs under ", normalizePath(outdir))
