# 02a_convergence.R — GA convergence + pareto
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
ga <- load_ga()
p1 <- ggplot(ga$convergence, aes(x = gen, y = best_F)) + geom_line(color = "#005493") +
  labs(title = "GA Convergence — Best F", x = "Generation", y = "F (%)")
p2 <- ggplot(ga$pareto, aes(x = F_oral, y = Cmax_MIC)) + geom_point(color = "#005493") +
  labs(title = "Pareto Front — F vs Cmax/MIC", x = "F (%)", y = "Cmax/MIC")
# Sync
dir.create(file.path(PROJECT_ROOT, "05_ANALYSIS/02_ga/figures"), showWarnings = FALSE)
dir.create(file.path(PROJECT_ROOT, "05_ANALYSIS/02_ga/tables"), showWarnings = FALSE)
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/ga/convergence.csv"), file.path(PROJECT_ROOT, "05_ANALYSIS/02_ga/tables/convergence.csv"), overwrite = TRUE)
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/ga/pareto_front.csv"), file.path(PROJECT_ROOT, "05_ANALYSIS/02_ga/tables/pareto_front.csv"), overwrite = TRUE)
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/ga/top10.csv"), file.path(PROJECT_ROOT, "05_ANALYSIS/02_ga/tables/top10.csv"), overwrite = TRUE)
# Check corruption
if (any(ga$pareto$F_oral > 100)) warning("pareto F >100% — check cap")
ggsave(file.path(PROJECT_ROOT, "05_ANALYSIS/02_ga/figures/convergence_plot.png"), p1, width = 7, height = 4, dpi = 300, bg = "white")
ggsave(file.path(PROJECT_ROOT, "05_ANALYSIS/02_ga/figures/pareto_front.png"), p2, width = 7, height = 4, dpi = 300, bg = "white")
# Also to main
ggsave(file.path(PROJECT_ROOT, "05_ANALYSIS/figures/convergence_plot.png"), p1, width = 7, height = 4, dpi = 300, bg = "white")
cat("02_ga done\n")
