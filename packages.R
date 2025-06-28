## read your DESCRIPTION DCF and pull out Depends/Imports
d <- read.dcf("DESCRIPTION", c("Depends", "Imports"))
pkgs <- unlist(strsplit(paste(d[1, ], collapse = ","), ","))
pkgs <- trimws(gsub("\\(.*\\)", "", pkgs)) # drop version specs
pkgs <- setdiff(pkgs, "R")

# load them all
lapply(pkgs, function(p) library(p, character.only = TRUE))
