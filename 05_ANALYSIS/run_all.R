#!/usr/bin/env Rscript
# ============================================================================
# run_all.R — Master pipeline for 05_ANALYSIS (modular, non-destructive, English)
# Re-analyses 04_RESULTS/ (90 artifacts) into 05_ANALYSIS/ (90+30) + 06_MANUSCRIPT/
# Usage:
#   Rscript 05_ANALYSIS/run_all.R [options]
# Options:
#   --help                Show this help
#   --skip-figures        Skip figure generation (still copies tables)
#   --keep-going          Don't abort on first failing step
#   --out DIR             Output directory (default: 05_ANALYSIS/, non-destructive mirror in 05_ANALYSIS/results_run_*)
# Examples:
#   Rscript 05_ANALYSIS/run_all.R                          # full 12 modules, ~1 min
#   Rscript 05_ANALYSIS/run_all.R --skip-figures           # tables only
# ============================================================================

# --- Help before PROJ ---
args <- commandArgs(TRUE)
if ("--help" %in% args || "-h" %in% args) {
  ca <- commandArgs(trailingOnly = FALSE)
  f <- ca[grep("--file=", ca)]
  this_help <- if (length(f) > 0) sub("--file=", "", f[1]) else file.path("05_ANALYSIS", "run_all.R")
  this_help <- gsub("~\\+~", " ", this_help)
  hdr <- tryCatch(readLines(this_help, n = 50), error = function(e) NULL)
  if (!is.null(hdr) && length(hdr) > 0) {
    cat(hdr, sep = "\n")
  } else {
    cat("\nUsage: Rscript 05_ANALYSIS/run_all.R [options]\n")
  }
  quit(save = "no", status = 0)
}

# --- Resolve project root ---
PROJ <- (function() {
  this_file <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
  if (is.null(this_file) || !nzchar(this_file)) {
    ca <- commandArgs(trailingOnly = FALSE); f <- ca[grep("--file=", ca)]
    if (length(f) > 0) this_file <- sub("--file=", "", f[1])
  }
  this_file <- gsub("~\\+~", " ", this_file)
  candidates <- c()
  if (!is.null(this_file) && nzchar(this_file) && file.exists(this_file)) {
    candidates <- c(candidates, normalizePath(dirname(normalizePath(this_file)), mustWork = FALSE))
    candidates <- c(candidates, normalizePath(file.path(dirname(normalizePath(this_file)), ".."), mustWork = FALSE))
  }
  candidates <- c(candidates, normalizePath(getwd(), mustWork = FALSE))
  for (base in candidates) {
    d <- base
    for (i in 1:6) {
      if (dir.exists(file.path(d, "05_ANALYSIS")) && dir.exists(file.path(d, "04_RESULTS"))) return(normalizePath(d, mustWork = FALSE))
      d <- dirname(d)
    }
  }
  stop("Project root not found (expected 05_ANALYSIS/ and 04_RESULTS/).")
})()
setwd(PROJ)
skip_figures <- "--skip-figures" %in% args
keep_going   <- "--keep-going" %in% args
out_idx <- which(args == "--out")
if (length(out_idx) > 0) {
  out_dir <- normalizePath(args[out_idx + 1], mustWork = FALSE)
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
} else {
  out_dir <- file.path(PROJ, "05_ANALYSIS", paste0("results_run_", format(Sys.time(), "%Y%m%d_%H%M%S")))
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
}
RS <- "/Library/Frameworks/R.framework/Resources/bin/Rscript"
if (!file.exists(RS)) RS <- file.path(R.home("bin"), "Rscript")
cat("=== 05_ANALYSIS — modular pipeline ===\n")
cat("root:", PROJ, "\nRscript:", RS, "\nout:", out_dir, "\nfigures:", ifelse(skip_figures, "SKIP", "ON"), "\n\n")

# --- Define steps (12 modules) ---
steps_all <- c(
  "05_ANALYSIS/01_validation/scripts/01_plot_gate.R",
  "05_ANALYSIS/02_ga/scripts/02a_convergence.R",
  "05_ANALYSIS/02_ga/scripts/02b_pareto.R",
  "05_ANALYSIS/03_dose_clcr/scripts/03a_iv_scenarios.R",
  "05_ANALYSIS/04_calibration/scripts/04a_calibration.R",
  "05_ANALYSIS/05_population/scripts/05a_pop.R",
  "05_ANALYSIS/06_sensitivity/scripts/06a_sensitivity.R",
  "05_ANALYSIS/07_food/scripts/07a_food.R",
  "05_ANALYSIS/08_fractionation/scripts/08a_fractionation.R",
  "05_ANALYSIS/09_winner/scripts/09a_winner.R",
  "05_ANALYSIS/10_uncertainty/scripts/10a_uncertainty.R",
  "05_ANALYSIS/11_batteries/scripts/11a_batteries.R",
  "05_ANALYSIS/12_manuscript/scripts/12a_export.R"
)
steps <- steps_all
if (skip_figures) steps <- steps[!grepl("04_calibration|02a_convergence|02b_pareto|05a_pop|06a_sensitivity|07a_food|08a_fractionation|09a_winner|10a_uncertainty|11a_batteries|12a_export", steps)]

cat("Steps (", length(steps), "):\n", paste0("  - ", steps, collapse = "\n"), "\n\n", sep = "")
status <- data.frame(step = steps, exit = NA_integer_, seconds = NA_real_, stringsAsFactors = FALSE)
for (i in seq_along(steps)) {
  s <- steps[i]
  cat("\n>>>", s, "\n")
  t0 <- Sys.time()
  cmd <- paste("unset R_HOME;", shQuote(RS), shQuote(s))
  st <- system(cmd)
  dt <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  status$exit[i] <- st; status$seconds[i] <- round(dt, 1)
  cat(sprintf("<<< %s — exit %d (%.1fs)\n", s, st, dt))
  if (st != 0 && !keep_going) { cat("STEP FAILED — aborting (use --keep-going)\n"); break }
}
# --- Sync 04 -> 05 main (like 04/README) ---
cat("\n=== syncing 04_RESULTS -> 05_ANALYSIS (main) ===\n")
# Ensure main 05 has TOUT (12 png + 23 csv) from 04, plus s02
src_figs <- c(list.files(file.path(PROJ, "04_RESULTS/studies"), pattern="\\.png$", full.names=TRUE),
              list.files(file.path(PROJ, "04_RESULTS/validation"), pattern="\\.png$", full.names=TRUE))
for (f in src_figs) file.copy(f, file.path(PROJ, "05_ANALYSIS/figures", basename(f)), overwrite=TRUE)
src_tabs <- c(list.files(file.path(PROJ, "04_RESULTS/studies"), pattern="\\.csv$", full.names=TRUE),
              list.files(file.path(PROJ, "04_RESULTS/ga"), pattern="\\.csv$", full.names=TRUE))
for (f in src_tabs) file.copy(f, file.path(PROJ, "05_ANALYSIS/tables", basename(f)), overwrite=TRUE)
# s02 already generated in 04_calibration
# Manifest
artifacts <- list.files(c("05_ANALYSIS"), recursive = TRUE, full.names = TRUE)
artifacts <- artifacts[!dir.exists(artifacts)]
manifest <- data.frame(file = artifacts, bytes = file.info(artifacts)$size,
                       mtime = format(file.info(artifacts)$mtime, "%Y-%m-%d %H:%M:%S"),
                       md5 = tools::md5sum(artifacts), row.names = NULL)
write.csv(manifest, file.path(PROJ, "05_ANALYSIS/MANIFEST.csv"), row.names = FALSE)
write.csv(manifest, file.path(out_dir, "ANALYSIS_MANIFEST.csv"), row.names = FALSE)
cat("manifest:", nrow(manifest), "artifacts -> 05_ANALYSIS/MANIFEST.csv +", file.path(out_dir, "ANALYSIS_MANIFEST.csv"), "\n")
# Copy TOUT to out_dir (like 02_ENGINE) — exclude out_dir itself to avoid recursion
# out_dir is inside 05_ANALYSIS (05_ANALYSIS/results_run_*), so we must not copy it into itself
copy_tree <- function(src, dst_sub) {
  dst <- file.path(out_dir, dst_sub)
  dir.create(dst, showWarnings = FALSE, recursive = TRUE)
  files <- list.files(file.path(PROJ, src), recursive = TRUE, full.names = TRUE)
  files <- files[!dir.exists(files)]
  # Exclude files that are inside any results_run_* folder and the current out_dir (avoid recursion)
  files <- files[!grepl("/results_run_", files)]
  files <- files[!grepl(paste0("^", normalizePath(out_dir, mustWork = FALSE)), normalizePath(files, mustWork = FALSE))]
  for (f in files) {
    rel <- sub(paste0("^", file.path(PROJ, src), "/"), "", f)
    dst_f <- file.path(dst, rel)
    dir.create(dirname(dst_f), showWarnings = FALSE, recursive = TRUE)
    file.copy(f, dst_f, overwrite = TRUE)
  }
  cat(sprintf("copied %s -> %s (%d files, results_run excluded)\n", src, dst, length(files)))
}
copy_tree("05_ANALYSIS", "05_ANALYSIS")
cat("copied 05_ANALYSIS ->", file.path(out_dir, "05_ANALYSIS"), "\n")
log_path <- file.path(out_dir, "ANALYSIS_LOG.md")
log_lines <- c(paste0("# 05_ANALYSIS run log — ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
               "", paste0("- **Root:** `", PROJ, "`"), paste0("- **Steps:** ", length(steps)),
               "", "## Status", "```", paste(capture.output(print(status)), collapse = "\n"), "```")
writeLines(log_lines, log_path)
cat("log:", log_path, "\n")
print(status)
fail <- status$step[which(status$exit != 0 & !is.na(status$exit))]
if (length(fail)) { cat("\nFAILED:", paste(fail, collapse=", "), "\n"); quit(save="no", status=1) }
cat("\n=== 05_ANALYSIS pipeline complete ===\n")
cat("Out dir:", out_dir, "\n")
