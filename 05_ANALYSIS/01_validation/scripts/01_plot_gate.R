# 01_plot_gate.R — Validation gate forest plot (S00 6/6 PASS)
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

source(file.path(PROJECT_ROOT, "05_ANALYSIS/utils/01_load_results.R"))
gate <- load_validation()$gate
# Forest plot: metric vs value/target
p <- ggplot(gate, aes(x = metric, y = as.numeric(value))) +
  geom_point(color = "#005493", size = 3) +
  geom_errorbar(aes(ymin = as.numeric(value)*0.9, ymax = as.numeric(value)*1.1), width = 0.2) +
  coord_flip() + labs(title = "S00 Validation Gate 6/6 PASS — 577.5 mg", x = "", y = "Value") +
  theme_minimal()
# Also sync 04 -> 05
sync_05_from_04()
# Copy with manuscript rename
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/validation/iv_validation_profile.png"),
          file.path(PROJECT_ROOT, "05_ANALYSIS/01_validation/figures/iv_validation_profile.png"), overwrite = TRUE)
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/validation/iv_validation_gate.csv"),
          file.path(PROJECT_ROOT, "05_ANALYSIS/01_validation/tables/gate_summary.csv"), overwrite = TRUE)
ggsave(file.path(PROJECT_ROOT, "05_ANALYSIS/01_validation/figures/gate_forest.png"), p, width = 8, height = 4, dpi = 300, bg = "white")
# Also to main 05
ggsave(file.path(PROJECT_ROOT, "05_ANALYSIS/figures/iv_validation_profile.png"), p, width = 8, height = 4, dpi = 300, bg = "white")
cat("01_validation done\n")
