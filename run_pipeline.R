#!/usr/bin/env Rscript
# ---------------------------------------------------------------------
#  run_pipeline.R
#  --------------------------------------------------------------------
#  High‑level wrapper that
#    1. visualises the current targets DAG,
#    2. saves it as both HTML and PNG in the project root, and then
#    3. executes the pipeline via targets::tar_make().
#
#  The script is meant to be the container *entry‑point* (see CMD in the
#  Dockerfile).  Running it outside the container also works provided
#  all R packages listed in DESCRIPTION are installed.
#
#  ────────────────────────────────────────────────────────────────────
#  Usage
#  ────────────────────────────────────────────────────────────────────
#    • Inside the container: automatically invoked by
#        docker run …  or  apptainer exec …
#    • Manually on host:   Rscript example/run_pipeline.R
#
#  Environment variables honoured
#    TAR_RUN_ENV     –  "hpc" triggers SLURM settings in _targets.R
#    STAN_NUM_THREADS – passed through to rstanarm if set in Dockerfile
#
#  Outputs generated
#    current_targets.html   – interactive DAG (visNetwork)
#    current_targets.png    – static snapshot (PNG, 1600×900)
#    _targets/objects/…     – targets cache populated by tar_make()
#
#  Dependencies (all installed in the image)
#    • targets
#    • visNetwork
#    • webshot2  (PNG export; falls back gracefully if missing)
# ---------------------------------------------------------------------

# ---- 1. draw the graph -------------------------------------------------------
vis <- targets::tar_visnetwork(
    targets_only = TRUE,
    reporter     = "silent"
)
visNetwork::visSave(vis, "current_targets.html")

if (requireNamespace("webshot2", quietly = TRUE)) {
    webshot2::webshot(
        "current_targets.html",
        "current_targets.png",
        vwidth  = 1600,
        vheight = 900
    )
} else {
    message("webshot2 not available – skipped PNG export of DAG.")
}

# ---- 2. run the pipeline -----------------------------------------------------
targets::tar_make()
