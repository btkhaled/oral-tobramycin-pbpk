# 02b_pareto.R — detailed pareto analysis (like 02_ENGINE 11_pareto_analysis.R)
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
source(file.path(PROJECT_ROOT, "05_ANALYSIS/utils/01_load_results.R"))
# Placeholder: re-use 02_ga/02a outputs, create additional correlation
ga <- load_ga()
# Correlation matrix
if (nrow(ga$pareto) > 2) {
  cor_mat <- cor(ga$pareto[, c("F_oral","Cmax_MIC","AUC_MIC","dose_mg")])
  png(file.path(PROJECT_ROOT, "05_ANALYSIS/02_ga/figures/correlation_matrix.png"), width = 800, height = 600)
  corrplot::corrplot(cor_mat, method = "color")
  dev.off()
}
cat("02b_pareto done\n")
