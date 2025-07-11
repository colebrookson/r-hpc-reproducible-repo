## For more information about targets see https://books.ropensci.org/targets
## Load your packages, e.g. library(targets).
source("./packages.R")

# parallel settings LOCAL VS HPC -----------------------------------------------
run_env <- Sys.getenv("TAR_RUN_ENV", unset = "local")
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
# stage 1: data ----------------------------------------------------------------
data_plan <- tar_plan(
    tar_target(
        raw_data,
        read_demo_data(),
        format = "qs"
    ),
    tar_target(
        clean_data,
        clean_demo_data(raw_data),
        format = "qs"
    )
)

# stage 2: model fitting -------------------------------------------------------
model_plan <- tar_plan(
    tar_target(
        model_specs,
        build_model_grid(),
        format = "qs"
    ),
    tar_target(
        model_fits,
        {
            spec <- model_specs[tar_group$id, ]
            fit_one_model(spec, clean_data)
        },
        pattern = map(model_specs),
        format = "qs",
        resources = tar_resources(
            clustermq = list(n_cpus = 4, walltime = "04:00:00")
        )
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
        cue = tar_cue(mode = "always") # refresh table each run
    ),
    tar_target(
        plots,
        diagnostic_plots(model_fits, tar_group$id),
        pattern = map(model_fits),
        iteration = "vector"
    )
)

## pipeline object -------------------------------------------------------------
list(
    data_plan,
    model_plan,
    post_plan
)
