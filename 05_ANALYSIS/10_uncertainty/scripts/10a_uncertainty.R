# 10a_uncertainty.R — S09 20k draws + frontier
# Portable PROJECT_ROOT (like 02_ENGINE)
if (!exists("PROJECT_ROOT")) {
  this_file <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
  if (is.null(this_file) || !nzchar(this_file)) {
    ca <- commandArgs(trailingOnly = FALSE)
    f <- ca[grep("--file=", ca)]
    if (length(f) > 0) this_file <- sub("--file=", "", f[1])
  }
  this_file <- gsub("~\\+~", " ", this_file)
  if (!is.null(this_file) && nzchar(this_file) && file.exists(this_file)) {
    PROJECT_ROOT <- normalizePath(file.path(dirname(normalizePath(this_file)), "../../.."), mustWork = FALSE)
  } else {
    PROJECT_ROOT <- normalizePath(getwd(), mustWork = FALSE)
    for (i in 1:6) {
      if (dir.exists(file.path(PROJECT_ROOT, "05_ANALYSIS")) && dir.exists(file.path(PROJECT_ROOT, "04_RESULTS"))) break
      PROJECT_ROOT <- dirname(PROJECT_ROOT)
    }
  }
}

source(file.path(PROJECT_ROOT, "05_ANALYSIS/utils/00_setup.R"))
s09a <- read.csv(file.path(PROJECT_ROOT, "04_RESULTS/studies/S09_uncertainty_summary_A.csv"))
s09b <- read.csv(file.path(PROJECT_ROOT, "04_RESULTS/studies/S09_uncertainty_summary_B.csv"))
# Frontier is precomputed S09_frontier.png, just copy and add forest
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/studies/S09_frontier.png"), file.path(PROJECT_ROOT, "05_ANALYSIS/10_uncertainty/figures/S09_frontier.png"), overwrite = TRUE)
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/studies/S09_uncertainty_summary_A.csv"), file.path(PROJECT_ROOT, "05_ANALYSIS/10_uncertainty/tables/S09_uncertainty_summary_A.csv"), overwrite = TRUE)
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/studies/S09_uncertainty_summary_B.csv"), file.path(PROJECT_ROOT, "05_ANALYSIS/10_uncertainty/tables/S09_uncertainty_summary_B.csv"), overwrite = TRUE)
# Note PTA_AUC120 inversion in A (100% vs 65%) — check column swap
cat("10_uncertainty done — note S09 PTA_AUC120 inversion A 100% vs 65%\n")
