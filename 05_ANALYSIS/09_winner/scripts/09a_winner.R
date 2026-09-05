# 09a_winner.R — Winner + reqmap (S07 + S08)
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
s07 <- read.csv(file.path(PROJECT_ROOT, "04_RESULTS/studies/S07_dose_scan.csv"))
s08 <- read.csv(file.path(PROJECT_ROOT, "04_RESULTS/studies/S08_requirement_map.csv"))
# Winner: 944 mg x79 F90.7% (smoke) vs 100×100 F97% — plot dose_scan
p1 <- ggplot(s07, aes(x = dose_mg, y = Cmax_MIC)) + geom_line(color = "#005493") + geom_point(color = "#005493") +
  geom_hline(yintercept = 8, linetype = 2, color = "firebrick") + labs(title = "S07 Dose Scan — Cmax/MIC vs Dose", x = "Dose (mg)", y = "Cmax/MIC")
# Reqmap: F vs mult
p2 <- ggplot(s08, aes(x = mult, y = F_993)) + geom_line(color = "#005493") + geom_point(color = "#005493") +
  scale_x_log10() + labs(title = "S08 Reqmap — F vs mult @993 mg", x = "Mult (log)", y = "F (%)")
dir.create(file.path(PROJECT_ROOT, "05_ANALYSIS/09_winner/figures"), showWarnings = FALSE)
ggsave(file.path(PROJECT_ROOT, "05_ANALYSIS/09_winner/figures/s07_dose_scan.png"), p1, width = 7, height = 5, dpi = 300, bg = "white")
ggsave(file.path(PROJECT_ROOT, "05_ANALYSIS/09_winner/figures/s08_reqmap.png"), p2, width = 7, height = 5, dpi = 300, bg = "white")
# Copy with doc for dose drift 550→944→993→1000
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/studies/S07_dose_scan.csv"), file.path(PROJECT_ROOT, "05_ANALYSIS/09_winner/tables/S07_dose_scan.csv"), overwrite = TRUE)
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/studies/S07_winner_profile.csv"), file.path(PROJECT_ROOT, "05_ANALYSIS/09_winner/tables/S07_winner_profile.csv"), overwrite = TRUE)
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/studies/S08_requirement_map.csv"), file.path(PROJECT_ROOT, "05_ANALYSIS/09_winner/tables/S08_requirement_map.csv"), overwrite = TRUE)
cat("09_winner done — note dose 550 vs 944 vs 993 vs 1000, F24 vs F96\n")
