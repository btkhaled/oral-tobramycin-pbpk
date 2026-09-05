# 12a_export.R — 05 -> 06 manuscript export (rename + tex)
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
# Sync 05 -> 06 with rename (S01→s01_iv_clcr etc, like 05 vs 06 audit)
# Figures: 05/figures 12 → 06/figures 46 (rename + s02)
src_figs <- list.files(file.path(PROJECT_ROOT, "05_ANALYSIS/figures"), pattern="\\.png$", full.names=TRUE)
for (f in src_figs) {
  dst_name <- basename(f)
  # Rename mapping
  dst_name <- gsub("S01_iv_scenarios.png", "s01_iv_clcr.png", dst_name)
  dst_name <- gsub("S04_sensitivity.png", "s04_elasticities.png", dst_name)
  dst_name <- gsub("S05_food_effect.png", "s05_food.png", dst_name)
  dst_name <- gsub("iv_validation_profile.png", "val_iv_profile.png", dst_name)
  file.copy(f, file.path(PROJECT_ROOT, "06_MANUSCRIPT/figures", dst_name), overwrite=TRUE)
}
# s02 already generated in 04_calibration
file.copy(file.path(PROJECT_ROOT, "05_ANALYSIS/04_calibration/figures/s02_calibration.png"),
          file.path(PROJECT_ROOT, "06_MANUSCRIPT/figures/s02_calibration.png"), overwrite=TRUE)
# Tables: 05/tables 23 → 06/tables 7 tex (already exist, just ensure)
cat("12_manuscript done — 05→06 rename + s02\n")
