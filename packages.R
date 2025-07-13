## read your DESCRIPTION DCF and pull out Depends/Imports
d <- read.dcf("DESCRIPTION", c("Depends", "Imports"))
pkgs <- unlist(strsplit(paste(d[1, ], collapse = ","), ","))
pkgs <- trimws(gsub("\\(.*\\)", "", pkgs)) # drop version specs
pkgs <- setdiff(pkgs, "R")

loud_packages <- pkgs[!pkgs %in% c("here", "dplyr", "qs", "bayesplot")]

# load them all
lapply(loud_packages, function(p) {
    suppressPackageStartupMessages(
        library(p, character.only = TRUE)
    )
})
# suppress the messages of the things i don't want to see
lapply(pkgs, function(p) {
    suppressPackageStartupMessages(
        library(p, character.only = TRUE)
    )
})
