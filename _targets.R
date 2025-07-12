## For more information about targets see https://books.ropensci.org/targets
## Load your packages, e.g. library(targets).
source("./packages.R")

# parallel settings LOCAL VS HPC -----------------------------------------------
run_env <- Sys.getenv("TAR_RUN_ENV", unset = "local")
targets::tar_option_set(
    # keep workspaces if something crashes
    workspace_on_error = TRUE,
    # clustermq worker settings (apply to *all* workers)
    resources = tar_resources(
        clustermq = tar_resources_clustermq(
            template = if (run_env == "hpc") "slurm/clustermq.tmpl" else NULL
        )
    )
)
if (run_env == "hpc") {
    targets::tar_option_set(
        workspace_on_error = TRUE
    )
    options(
        clustermq.scheduler = "slurm",
        clustermq.template  = "slurm/clustermq.tmpl"
    )
}

## load helper funcs -----------------------------------------------------------
targets::tar_source()

## tar plans -------------------------------------------------------------------
# stage 1: data ---------------------------------------------------------------
data_plan <- tar_plan(
    tar_target(raw_data, read_demo_data(), format = "qs"),
    tar_target(clean_data, clean_demo_data(raw_data), format = "qs")
)

# stage 2: model fitting -------------------------------------------------------
model_plan <- tar_plan(
    # 1. full grid --------------------------------------------------------------
    tar_target(model_specs, build_model_grid(), format = "qs"),

    # 2. split into list of rows -----------------------------------------------
    tar_target(
        model_specs_rows,
        split(model_specs, seq_len(nrow(model_specs))),
        format = "qs"
    ),

    # 3. fit each row -----------------------------------------------------------
    tar_target(
        model_fits,
        {
            spec <- model_specs_rows[[1]] # each branch gets a single‑row tibble
            fit_one_model(spec, clean_data)
        },
        pattern = map(model_specs_rows),
        format = "qs"
    )
)

# stage 3: post‑processing -----------------------------------------------------
post_plan <- tar_plan(
    tar_target(
        model_waic,
        compute_waic(model_fits),
        pattern = map(model_fits),
        iteration = "list"
    ),
    tar_target(
        waic_tbl,
        model_summary_table(model_waic),
        cue = tar_cue(mode = "always")
    ),
    tar_target(
        plots,
        diagnostic_plots(
            fit = model_fits,
            model_id = sprintf("model_%02d", tar_branch_index()) # e.g. model_01
        ),
        pattern = map(model_fits),
        iteration = "vector"
    )
)

## pipeline object -------------------------------------------------------------
list(data_plan, model_plan, post_plan)
