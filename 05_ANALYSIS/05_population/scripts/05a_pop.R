# 05a_pop.R — Population violin + PTA (S03 100 ICRP)
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
s03 <- read.csv(file.path(PROJECT_ROOT, "04_RESULTS/studies/S03_population.csv"))
s03s <- read.csv(file.path(PROJECT_ROOT, "04_RESULTS/studies/S03_population_summary.csv"))
p <- ggplot(s03, aes(x = "", y = Cmax)) + geom_violin(fill = "#005493", alpha = 0.7) + geom_boxplot(width = 0.1) +
  labs(title = "S03 Population — Cmax (n=100, 550 mg ×20)", x = "", y = "Cmax (mg/L)")
dir.create(file.path(PROJECT_ROOT, "05_ANALYSIS/05_population/figures"), showWarnings = FALSE)
ggsave(file.path(PROJECT_ROOT, "05_ANALYSIS/05_population/figures/s03_pop_violin.png"), p, width = 7, height = 5, dpi = 300, bg = "white")
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/studies/S03_population.csv"), file.path(PROJECT_ROOT, "05_ANALYSIS/05_population/tables/S03_population.csv"), overwrite = TRUE)
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/studies/S03_population_summary.csv"), file.path(PROJECT_ROOT, "05_ANALYSIS/05_population/tables/S03_population_summary.csv"), overwrite = TRUE)
# Note dual window F24 vs F96
cat("05_population done — note F24 vs F96 dual, fT not time-weighted\n")
