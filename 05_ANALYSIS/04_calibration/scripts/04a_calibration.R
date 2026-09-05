# 04a_calibration.R — F vs P_int calibration (S02) + generate s02_calibration.png (missing in 05)
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
s02 <- read.csv(file.path(PROJECT_ROOT, "04_RESULTS/studies/S02_oral_papp_calibration.csv"))
# Existing table has pint_dm_min, F, cmax, auc
p <- ggplot(s02, aes(x = pint_dm_min, y = F)) + geom_line(color = "#005493") + geom_point(color = "#005493") +
  scale_x_log10() + labs(title = "S02 Calibration — F vs P_int", x = "P_int (dm/min, log)", y = "F (%)") +
  geom_vline(xintercept = 3e-9, linetype = 2, color = "firebrick") +
  annotate("text", x = 3e-9, y = 50, label = "Pint0 3e-9 → F0 1.75%", hjust = -0.1, color = "firebrick")
dir.create(file.path(PROJECT_ROOT, "05_ANALYSIS/04_calibration/figures"), showWarnings = FALSE)
ggsave(file.path(PROJECT_ROOT, "05_ANALYSIS/04_calibration/figures/s02_calibration.png"), p, width = 7, height = 5, dpi = 300, bg = "white")
# Also to main
ggsave(file.path(PROJECT_ROOT, "05_ANALYSIS/figures/s02_calibration.png"), p, width = 7, height = 5, dpi = 300, bg = "white")
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/studies/S02_oral_papp_calibration.csv"), file.path(PROJECT_ROOT, "05_ANALYSIS/04_calibration/tables/S02_oral_papp_calibration.csv"), overwrite = TRUE)
cat("04_calibration done — s02_calibration.png generated (was missing in 05)\n")
