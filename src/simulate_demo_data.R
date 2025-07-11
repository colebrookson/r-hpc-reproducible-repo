#!/usr/bin/env Rscript
#' simulate and save a demo data set for the targets pipeline
#'
#' generates a 25 000‑row data frame with 10 covariates (8 numeric, 2 factor)
#' and a continuous outcome `y`. the csv is written to
#' `./example/data/demo_data.csv`.
#'
#' run this script once before the pipeline.
#'
#' @author cole brookson

# packages ----
base::suppressPackageStartupMessages({
    stats::runif
    utils::write.csv
})

# constants ----
n_rows <- 25000L
cov_mean <- 0
cov_sd <- 1

# numeric covariates ----
num_mat <- matrix(
    stats::rnorm(n_rows * 8L, cov_mean, cov_sd),
    nrow = n_rows,
    dimnames = list(NULL, paste0("x", seq_len(8L)))
)

# factor covariates ----
f1 <- factor(sample(letters[1:4], n_rows, TRUE))
f2 <- factor(sample(c("low", "med", "high"), n_rows, TRUE))

# outcome ----
linear_pred <- 1 +
    0.5 * num_mat[, "x1"] -
    0.2 * num_mat[, "x4"] +
    ifelse(f1 == "a", 0.3, -0.3)
y <- rnorm(n_rows, linear_pred, 1)

# data frame ----
demo_df <- data.frame(num_mat, f1, f2, y)

# output dir ----
out_dir <- "./example/data"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

utils::write.csv(demo_df, file.path(out_dir, "demo_data.csv"),
    row.names = FALSE
)
message("wrote ", nrow(demo_df), " rows to ", file.path(
    out_dir,
    "demo_data.csv"
))
