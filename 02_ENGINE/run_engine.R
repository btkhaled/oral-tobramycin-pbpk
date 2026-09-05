#!/usr/bin/env Rscript
# ============================================================================
# run_engine.R — Master pipeline for the maison GA engine (02_ENGINE)
# Runs the full exploratory pipeline non-destructively, with figures, in English.
# Usage:
#   Rscript 02_ENGINE/run_engine.R [options]
# Options:
#   --help                Show this help
#   --ga-only             Run GA (03_ga_run.R) only
#   --nsga2-only          Run NSGA-II (10_nsga2_optimization.R) only
#   --pop N               Override population size (GA popSize and NSGA-II POP_SIZE)
#   --gen G               Override generations (GA maxiter and NSGA-II N_GEN)
#   --out DIR             Output directory (default: 02_ENGINE/results_run_TIMESTAMP, non-destructive)
#   --keep-going          Don't abort on first failing step
#   --skip-figures        Skip figure-heavy steps (05,06,07,08,13)
# Examples:
#   Rscript 02_ENGINE/run_engine.R                          # full pipeline (~6 min, 100x200 + 200x300)
#   Rscript 02_ENGINE/run_engine.R --pop 12 --gen 3         # smoke test (~10s)
#   Rscript 02_ENGINE/run_engine.R --ga-only --pop 50 --gen 20
#   Rscript 02_ENGINE/run_engine.R --out /tmp/my_run --keep-going
# Notes:
#   - Portable: resolves PROJECT_ROOT from script location or getwd() walk-up (like 03_PKSIM).
#   - Non-destructive: writes to a timestamped folder, never overwrites 02_ENGINE/results_legacy/
#     (legacy remains the v0.1 provenance). Override with --out.
#   - Figures ON by default (05,06,07,08,13). Use --skip-figures to skip.
#   - Config cap is +1.6 (measured HIP, Asad2023, max ×126.3) — see 02_ENGINE/config/README.md
#     and 03_PKSIM/docs/07. Legacy 3.0 was artefact ×313 (sensitivity only).
# ============================================================================

# --- Help (before PROJ resolution, so it works from anywhere) ---
args <- commandArgs(TRUE)
if ("--help" %in% args || "-h" %in% args) {
  ca <- commandArgs(trailingOnly = FALSE)
  f <- ca[grep("--file=", ca)]
  this_help <- if (length(f) > 0) sub("--file=", "", f[1]) else file.path("02_ENGINE", "run_engine.R")
  # Decode R's space encoding (~+~) for paths with spaces
  this_help <- gsub("~\\+~", " ", this_help)
  hdr <- tryCatch(readLines(this_help, n = 45), error = function(e) NULL)
  if (!is.null(hdr) && length(hdr) > 0) {
    cat(hdr, sep = "\n")
  } else {
    cat("Usage: Rscript 02_ENGINE/run_engine.R [options]\n")
    cat("  --help                Show this help\n")
    cat("  --ga-only             Run GA (03_ga_run.R) only\n")
    cat("  --nsga2-only          Run NSGA-II (10_nsga2_optimization.R) only\n")
    cat("  --pop N               Override population size\n")
    cat("  --gen G               Override generations\n")
    cat("  --out DIR             Output directory (default: timestamped)\n")
    cat("  --keep-going          Don't abort on first failing step\n")
    cat("  --skip-figures        Skip figure-heavy steps\n")
  }
  quit(save = "no", status = 0)
}

# --- Resolve project root (portable, like 02_ENGINE/scripts/00_ga_setup.R) ---
PROJ <- (function() {
  this_file <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
  if (is.null(this_file) || !nzchar(this_file)) {
    ca <- commandArgs(trailingOnly = FALSE)
    f <- ca[grep("--file=", ca)]
    if (length(f) > 0) this_file <- sub("--file=", "", f[1])
  }
  candidates <- c()
  if (!is.null(this_file) && nzchar(this_file) && file.exists(this_file)) {
    candidates <- c(candidates, normalizePath(dirname(normalizePath(this_file)), mustWork = FALSE))
    candidates <- c(candidates, normalizePath(file.path(dirname(normalizePath(this_file)), ".."), mustWork = FALSE))
  }
  candidates <- c(candidates, normalizePath(getwd(), mustWork = FALSE))
  # Walk up 6 levels from each candidate
  for (base in candidates) {
    d <- base
    for (i in 1:6) {
      if (dir.exists(file.path(d, "02_ENGINE")) && dir.exists(file.path(d, "03_PKSIM"))) {
        return(normalizePath(d, mustWork = FALSE))
      }
      d <- dirname(d)
    }
  }
  stop("Project root not found (expected 02_ENGINE/ and 03_PKSIM/). Run from repo root or 02_ENGINE/.")
})()
setwd(PROJ)

args <- commandArgs(TRUE)

# --- Help ---
if ("--help" %in% args || "-h" %in% args) {
  cat(readLines(file.path(PROJ, "02_ENGINE/run_engine.R"), n = 45), sep = "\n")
  quit(save = "no", status = 0)
}

# --- Parse args ---
ga_only      <- "--ga-only" %in% args
nsga2_only   <- "--nsga2-only" %in% args
keep_going   <- "--keep-going" %in% args
skip_figures <- "--skip-figures" %in% args

# --pop N and --gen G (value follows flag)
get_opt <- function(flag) {
  idx <- which(args == flag)
  if (length(idx) == 0 || idx == length(args)) return(NULL)
  val <- suppressWarnings(as.integer(args[idx + 1]))
  if (is.na(val) || val <= 0) stop(paste("Invalid value for", flag, ":", args[idx + 1]))
  val
}
pop_override <- get_opt("--pop")
gen_override <- get_opt("--gen")

# --out DIR
out_idx <- which(args == "--out")
if (length(out_idx) > 0) {
  if (out_idx == length(args)) stop("--out requires a directory argument")
  out_dir <- args[out_idx + 1]
  # Remove --out and its value from args for --pop/--gen handling already done
} else {
  out_dir <- file.path(PROJ, "02_ENGINE", paste0("results_run_", format(Sys.time(), "%Y%m%d_%H%M%S")))
}
out_dir <- normalizePath(out_dir, mustWork = FALSE)
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# --- Rscript resolution: CRAN R first (rSharp works there), then R.home() ---
RS <- "/Library/Frameworks/R.framework/Resources/bin/Rscript"
if (!file.exists(RS)) RS <- file.path(R.home("bin"), "Rscript")

cat("=== 02_ENGINE — maison GA engine pipeline ===\n")
cat("root:    ", PROJ, "\n")
cat("Rscript: ", RS, "\n")
cat("out:     ", out_dir, " (non-destructive)\n")
cat("figures: ", ifelse(skip_figures, "SKIP", "ON"), "\n")
if (!is.null(pop_override)) cat("pop:     ", pop_override, " (override)\n")
if (!is.null(gen_override)) cat("gen:     ", gen_override, " (override)\n")
cat("mode:    ", ifelse(ga_only, "GA only", ifelse(nsga2_only, "NSGA-II only", "FULL (GA + NSGA-II + analysis + figures)")), "\n\n")

# Export env vars so 00_ga_setup.R and 10_nsga2_optimization.R pick them up
Sys.setenv(ENGINE_OUT = out_dir)
if (!is.null(pop_override)) {
  Sys.setenv(ENGINE_POP = as.character(pop_override))
  Sys.setenv(ENGINE_POP_NSGA2 = as.character(pop_override))
}
if (!is.null(gen_override)) {
  Sys.setenv(ENGINE_GEN = as.character(gen_override))
  Sys.setenv(ENGINE_GEN_NSGA2 = as.character(gen_override))
}

# --- Define pipeline steps (relative to PROJ, like run_all.R) ---
# Full pipeline: setup → GA → NSGA-II → analysis → validation → figures
# Scripts are in 02_ENGINE/scripts/ (portable, see 02_ENGINE/scripts/00_ga_setup.R:23)
steps_all <- c(
  "02_ENGINE/scripts/00_ga_setup.R",
  "02_ENGINE/scripts/03_ga_run.R",
  "02_ENGINE/scripts/10_nsga2_optimization.R",
  "02_ENGINE/scripts/04_ga_results_analysis.R",
  "02_ENGINE/scripts/11_pareto_analysis.R",
  "02_ENGINE/scripts/12_sensitivity_validation.R",
  "02_ENGINE/scripts/05_ga_visualization.R",
  "02_ENGINE/scripts/06_comparison_analysis.R",
  "02_ENGINE/scripts/07_manufacturing_feasibility.R",
  "02_ENGINE/scripts/08_regulatory_feasibility.R",
  "02_ENGINE/scripts/13_manuscript_figures.R"
)

# Filter by --ga-only / --nsga2-only / --skip-figures
steps <- steps_all
if (ga_only && !nsga2_only) {
  # GA only: 00 + 03 + 04 (12 requires both GA and NSGA-II outputs, so skip it in partial mode)
  steps <- c(
    "02_ENGINE/scripts/00_ga_setup.R",
    "02_ENGINE/scripts/03_ga_run.R",
    "02_ENGINE/scripts/04_ga_results_analysis.R"
  )
  if (!skip_figures) {
    steps <- c(steps, "02_ENGINE/scripts/05_ga_visualization.R")
  }
} else if (nsga2_only && !ga_only) {
  steps <- c(
    "02_ENGINE/scripts/00_ga_setup.R",
    "02_ENGINE/scripts/10_nsga2_optimization.R",
    "02_ENGINE/scripts/11_pareto_analysis.R"
  )
  if (!skip_figures) {
    steps <- c(steps, "02_ENGINE/scripts/05_ga_visualization.R", "02_ENGINE/scripts/13_manuscript_figures.R")
  }
} else if (skip_figures) {
  steps <- steps[!grepl("05_ga_visualization|06_comparison|07_manufacturing|08_regulatory|13_manuscript_figures", steps)]
}

cat("Steps (", length(steps), "):\n", paste0("  - ", steps, collapse = "\n"), "\n\n", sep = "")

# --- Execute ---
status <- data.frame(step = steps, exit = NA_integer_, seconds = NA_real_, stringsAsFactors = FALSE)
for (i in seq_along(steps)) {
  s <- steps[i]
  cat("\n>>>", s, "\n")
  t0 <- Sys.time()
  # Use the same RS resolution and env inheritance as run_all.R
  # Quote handling: steps have no extra args, so simple shQuote(s)
  cmd <- paste("unset R_HOME;", shQuote(RS), shQuote(s))
  st <- system(cmd)
  dt <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  status$exit[i] <- st
  status$seconds[i] <- round(dt, 1)
  cat(sprintf("<<< %s — exit %d (%.1fs)\n", s, st, dt))
  if (st != 0 && !keep_going) {
    cat("STEP FAILED — aborting (use --keep-going to continue anyway)\n")
    break
  }
}

# --- Manifest: every artifact in out_dir with size + md5 ---
cat("\n=== writing ENGINE_MANIFEST.csv ===\n")
artifacts <- list.files(out_dir, recursive = TRUE, full.names = TRUE)
artifacts <- artifacts[!dir.exists(artifacts)]
if (length(artifacts) == 0) {
  cat("WARNING: no artifacts in out_dir — pipeline may have failed or wrote to results_legacy/\n")
  manifest <- data.frame(file = character(0), bytes = numeric(0), mtime = character(0), md5 = character(0))
} else {
  manifest <- data.frame(
    file  = artifacts,
    bytes = file.info(artifacts)$size,
    mtime = format(file.info(artifacts)$mtime, "%Y-%m-%d %H:%M:%S"),
    md5   = tools::md5sum(artifacts),
    row.names = NULL
  )
}
manifest_path <- file.path(out_dir, "ENGINE_MANIFEST.csv")
write.csv(manifest, manifest_path, row.names = FALSE)
cat("manifest:", nrow(manifest), "artifacts ->", manifest_path, "\n")

# --- Log ---
log_path <- file.path(out_dir, "ENGINE_LOG.md")
log_lines <- c(
  paste0("# 02_ENGINE run log — ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  paste0("- **Root:** `", PROJ, "`"),
  paste0("- **Rscript:** `", RS, "`"),
  paste0("- **Out:** `", out_dir, "` (non-destructive)"),
  paste0("- **Figures:** ", ifelse(skip_figures, "SKIP", "ON")),
  if (!is.null(pop_override)) paste0("- **Pop override:** ", pop_override) else NULL,
  if (!is.null(gen_override)) paste0("- **Gen override:** ", gen_override) else NULL,
  paste0("- **Steps:** ", length(steps)),
  "",
  "## Status",
  "",
  "```",
  paste(capture.output(print(status)), collapse = "\n"),
  "```",
  "",
  "## Manifest",
  "",
  paste0("- `ENGINE_MANIFEST.csv` : ", nrow(manifest), " artifacts"),
  if (nrow(manifest) > 0) paste0("- Total bytes: ", sum(manifest$bytes, na.rm = TRUE)) else NULL,
  "",
  "## Cross-check",
  "",
  "- Exploratory F platform 34.0% (TOB-161, 551 mg, ×20) vs PK-Sim 34.6% (Δ1.9%) — see `03_PKSIM/docs/06_legacy_vs_pksim.md`",
  "- Definitive: `04_RESULTS/ga` (PK-Sim NSGA-II 100×100, corner ×125 F96 97.1%)",
  "- Legacy: `02_ENGINE/results_legacy/` untouched (provenance)",
  ""
)
writeLines(log_lines, log_path)
cat("log:", log_path, "\n")

print(status)
fail <- status$step[which(status$exit != 0 & !is.na(status$exit))]
if (length(fail)) {
  cat("\nFAILED STEPS:", paste(fail, collapse = ", "), "\n")
  quit(save = "no", status = 1)
}
cat("\n=== 02_ENGINE pipeline complete ===\n")
cat("Out dir:", out_dir, "\n")
cat("Manifest:", manifest_path, "\n")
cat("Log:", log_path, "\n")
cat("Legacy (untouched): 02_ENGINE/results_legacy/\n")
cat("Definitive PK-Sim: 04_RESULTS/ga/ (100×100, ×125) vs exploratory 02 pop200×300\n")
