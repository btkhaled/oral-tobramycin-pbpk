# 03a_iv_scenarios.R — Dose × CLCR heatmap (S01 20×)
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
s01 <- read.csv(file.path(PROJECT_ROOT, "04_RESULTS/studies/S01_iv_scenarios.csv"))
p <- ggplot(s01, aes(x = factor(CLCR), y = factor(dose_mg), fill = AUC24)) + geom_tile() +
  scale_fill_viridis_c() + labs(title = "S01 Dose × CLCR — AUC24", x = "CLCR (mL/min)", y = "Dose (mg)", fill = "AUC24")
dir.create(file.path(PROJECT_ROOT, "05_ANALYSIS/03_dose_clcr/figures"), showWarnings = FALSE)
ggsave(file.path(PROJECT_ROOT, "05_ANALYSIS/03_dose_clcr/figures/s01_iv_clcr_heatmap.png"), p, width = 7, height = 5, dpi = 300, bg = "white")
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/studies/S01_iv_scenarios.csv"), file.path(PROJECT_ROOT, "05_ANALYSIS/03_dose_clcr/tables/S01_iv_scenarios.csv"), overwrite = TRUE)
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/studies/S01_iv_scenarios.png"), file.path(PROJECT_ROOT, "05_ANALYSIS/03_dose_clcr/figures/s01_iv_scenarios.png"), overwrite = TRUE)
cat("03_dose_clcr done\n")
