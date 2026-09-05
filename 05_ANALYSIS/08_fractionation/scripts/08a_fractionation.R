# 08a_fractionation.R — QD/BID/TID + PTA (S06)
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
s06f <- read.csv(file.path(PROJECT_ROOT, "04_RESULTS/studies/S06_fractionation.csv"))
s06p <- read.csv(file.path(PROJECT_ROOT, "04_RESULTS/studies/S06_pta.csv"))
p1 <- ggplot(s06f, aes(x = regimen, y = Cmax_ss, fill = regimen)) + geom_col() +
  labs(title = "S06 Fractionation — Cmax_ss", x = "", y = "Cmax_ss (mg/L)") + theme(legend.position = "none", axis.text.x = element_text(angle = 30, hjust = 1))
dir.create(file.path(PROJECT_ROOT, "05_ANALYSIS/08_fractionation/figures"), showWarnings = FALSE)
ggsave(file.path(PROJECT_ROOT, "05_ANALYSIS/08_fractionation/figures/s06_fractionation_bar.png"), p1, width = 8, height = 5, dpi = 300, bg = "white")
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/studies/S06_fractionation.csv"), file.path(PROJECT_ROOT, "05_ANALYSIS/08_fractionation/tables/S06_fractionation.csv"), overwrite = TRUE)
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/studies/S06_pta.csv"), file.path(PROJECT_ROOT, "05_ANALYSIS/08_fractionation/tables/S06_pta.csv"), overwrite = TRUE)
# Note per-interval AUC vs daily
cat("08_fractionation done — note S06 AUC24 is per-interval, not daily\n")
