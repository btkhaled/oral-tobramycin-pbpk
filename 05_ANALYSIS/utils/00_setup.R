# 00_setup.R — Shared setup for 05_ANALYSIS (English, like 02_ENGINE)
suppressMessages({
  library(ggplot2)
  library(dplyr)
  library(readr)
  library(tidyr)
  library(patchwork)
  library(viridis)
  library(scales)
  library(jsonlite)
})
THEME_05 <- theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", strip.text = element_text(face = "bold"),
        plot.title = element_text(hjust = 0.5, face = "bold"), panel.grid.minor = element_blank())
theme_set(THEME_05)
RESULTS <- file.path("04_RESULTS")
FIGURES <- file.path("05_ANALYSIS/figures")
TABLES  <- file.path("05_ANALYSIS/tables")
# Portable PROJECT_ROOT (like 02_ENGINE)
if (!exists("PROJECT_ROOT")) {
  this_file <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
  if (is.null(this_file) || !nzchar(this_file)) {
    ca <- commandArgs(trailingOnly = FALSE); f <- ca[grep("--file=", ca)]
    if (length(f) > 0) this_file <- sub("--file=", "", f[1])
  }
  this_file <- gsub("~\\+~", " ", this_file)
  if (!is.null(this_file) && nzchar(this_file) && file.exists(this_file)) {
    PROJECT_ROOT <- normalizePath(file.path(dirname(normalizePath(this_file)), "../.."), mustWork = FALSE)
  } else {
    PROJECT_ROOT <- normalizePath(getwd(), mustWork = FALSE)
    for (i in 1:6) {
      if (dir.exists(file.path(PROJECT_ROOT, "05_ANALYSIS")) && dir.exists(file.path(PROJECT_ROOT, "04_RESULTS"))) break
      PROJECT_ROOT <- dirname(PROJECT_ROOT)
    }
  }
}
