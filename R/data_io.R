#' data_io.R
#' helpers for reading and cleaning demo data
#'
#' @keywords internal
"_PACKAGE"

#' read_demo_data
#'
#' @param path character. location of the csv.
#' @return data.frame
#' @export
read_demo_data <- function(
    path = "./data/demo_data.csv") {
    readr::read_csv(path, show_col_types = FALSE)
}

#' clean_demo_data
#'
#' centres / scales numeric vars and sets factor contrasts.
#'
#' @param df data.frame from [read_demo_data()].
#' @return data.frame cleaned
#' @export
clean_demo_data <- function(df) {
    num_vars <- names(df)[vapply(df, is.numeric, logical(1))]
    df[num_vars] <- lapply(df[num_vars], scale)

    df
}

#' Sanitize a Branch Name String
#'
#' This function replaces all non-alphanumeric and non-underscore characters
#' in a string with underscores. If the resulting string starts with a digit,
#' it prepends an "X" to the string.
#'
#' @param x A character string representing a branch name.
#'
#' @return A sanitized character string suitable for use as a variable or
#' branch name.
#'
#' @examples
#' sanitize_branch("feature/new-branch")
#' sanitize_branch("123branch")
#'
#' @export
sanitize_branch <- function(x) {
    x <- gsub("[^A-Za-z0-9_]+", "_", x)
    ifelse(grepl("^[0-9]", x), paste0("X", x), x)
}
