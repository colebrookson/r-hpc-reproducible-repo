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
    # 1. full grid -------------------------------------------------------------
    tar_target(model_specs, build_model_grid(), format = "qs"),

    # 2. split into list of rows -----------------------------------------------
    tar_group_by(
        model_versions,
        model_specs,
        model_id
    ),

    # 3. fit each row ----------------------------------------------------------
    tar_target(
        model_fits,
        fit_one_model(model_versions, clean_data),
        pattern = map(model_versions),
        format = "qs"
    )
)

# stage 2.1: model fitting in a different form ---------------------------------
model_map_plan <- tar_plan(

    # 3. fit each row ----------------------------------------------------------
    tarchetypes::tar_map(
        # 1. full grid ---------------------------------------------------------
        values = build_model_grid()[1:4, ],
        names = model_id,
        # 2. make the target ---------------------------------------------------
        tar_target(
            mapped_models,
            fit_models_map(
                formula = formula,
                prior_sd = prior_sd,
                family = family,
                data = clean_data
            )
        )
    )
)

# stage 3: post‑processing -----------------------------------------------------
post_plan <- tar_plan(
    tar_target(
        model_waic,
        compute_waic(model_fits),
        pattern = map(model_fits, model_versions),
        iteration = "list"
    ),
    tar_target(
        waic_tbl,
        model_summary_table(model_waic, model_versions),
        cue = tar_cue(mode = "always")
    ),
    tar_target(
        plots,
        diagnostic_plots(model_fits, model_versions$model_id,
            # if testing = TRUE, it prevents ALL plots from being saved
            # useful for quick checks without generating all plots
            testing = TRUE
        ),
        pattern = map(model_fits, model_versions),
        iteration = "list"
    )
)

## pipeline object -------------------------------------------------------------
list(
    data_plan,
    # model_plan,
    model_map_plan
    # post_plan
)
