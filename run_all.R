# ============================================================================
# run_all.R — Master pipeline (hardened, Phase 0) — ⚠️  NOT FINISHED
# ----------------------------------------------------------------------------
# ⚠️  ANNOUNCEMENT — 2026-09-05
# This root `run_all.R` is NOT FINISHED and is NOT the recommended way to
# reproduce the build finale. It will remain incomplete until the modular
# pipelines are fully validated.
#
# 👉  Please run each pipeline dossier by dossier, one by one:
#     - 02_ENGINE :  Rscript 02_ENGINE/run_engine.R            (11 steps, ~6 min)
#     - 03_PKSIM  :  Rscript 03_PKSIM/run_pksim.R               (14 steps, ~1-2 h)
#     - 05_ANALYSIS: Rscript 05_ANALYSIS/run_all.R             (13 steps, ~1 min)
#     - 06_MANUSCRIPT: make -C 06_MANUSCRIPT                    (185 pp)
#     - 07_SLIDES:    cd 07_SLIDES && node make_deck.mjs        (28 slides)
# See README.md “Quickstart — 3 blocs” and each folder’s README.md / *_SUMMARY.md.
#
# Stages (when finished): env check -> DB patch -> S00 gate -> S01..S03 -> GA -> S04..S09
#         -> molecule batteries -> manifest. The NSGA-II GA runs in the
#         PK-Sim loop by default (pop 100 x gen 100, ~1-2 h).
# Usage:  Rscript run_all.R [--skip-ga] [--keep-going]
#         --skip-ga  reuse the committed results/ga/ Pareto front instead of
#                    re-running the GA (~2 min instead of ~1-2 h).
# Env:    DOTNET_ROOT must point to a .NET 8 install.
# NOTE:   on this macOS setup only the CRAN R build works (Homebrew R's rSharp
#         crashes in sexp_to_parameters); the CRAN Rscript path is preferred.
# ============================================================================
PROJ <- (function(){
  d<-getwd()
  for(i in 1:6){
    if(file.exists(file.path(d,"03_PKSIM/env/pk_sim_run.R")) || file.exists(file.path(d,"pksim/env/pk_sim_run.R"))) return(normalizePath(d))
    d<-dirname(d)
  }
  stop("repo root not found (expected 03_PKSIM/env/pk_sim_run.R)")
})()
setwd(PROJ)
args <- commandArgs(TRUE)
skip_ga    <- "--skip-ga" %in% args
keep_going <- "--keep-going" %in% args

# --- Rscript resolution: CRAN R first (rSharp works there), then R.home() ---
RS <- "/Library/Frameworks/R.framework/Resources/bin/Rscript"
if (!file.exists(RS)) RS <- file.path(R.home("bin"), "Rscript")

cat("========================================================================\n")
cat("⚠️  WARNING — run_all.R at repository root is NOT FINISHED\n")
cat("========================================================================\n")
cat("This root pipeline is a placeholder. Please run each dossier one by one:\n")
cat("  Rscript 02_ENGINE/run_engine.R     (11 steps, ~6 min, hypothesis generator)\n")
cat("  Rscript 03_PKSIM/run_pksim.R       (14 steps, ~1-2 h, gate 6/6, 10 checkpoints)\n")
cat("  Rscript 05_ANALYSIS/run_all.R     (13 steps, ~1 min, 126 artifacts)\n")
cat("  make -C 06_MANUSCRIPT              (185 pp)\n")
cat("See README.md and 02_ENGINE/README.md, 03_PKSIM/PKSIM_SUMMARY.md, 05_ANALYSIS/README.md\n")
cat("========================================================================\n\n")
cat("=== oral-tobramycin-pbpk — master pipeline (INCOMPLETE) ===\n")
cat(sprintf("root: %s\nRscript: %s\nGA: %s\n\n", PROJ, RS,
            ifelse(skip_ga, "--skip-ga (reuse committed results/ga/)", "NSGA-II in the PK-Sim loop (~1-2 h)")))

steps <- c(
  "03_PKSIM/env/check_env.R",
  "03_PKSIM/studies/S00_validation_gate.R",
  "03_PKSIM/studies/S01_iv_scenarios.R",
  "03_PKSIM/studies/S02_oral_calibration.R",
  "03_PKSIM/studies/S03_population.R",
  "03_PKSIM/ga/run_ga.R",
  "03_PKSIM/studies/S04_sensitivity.R",
  "03_PKSIM/studies/S05_food_effect.R",
  "03_PKSIM/studies/S06_fractionation_pta.R",
  "03_PKSIM/studies/S07_winner_characterization.R",
  "03_PKSIM/studies/S08_requirement_map.R",
  "03_PKSIM/studies/S09_multiplier_uncertainty.R",
  "03_PKSIM/studies/molecule_battery.R A 03_PKSIM/studies/molecules/A_legacy_winner.csv",
  "03_PKSIM/studies/molecule_battery.R B 03_PKSIM/studies/molecules/B_pksim_winner.csv"
)
if (skip_ga) steps <- steps[steps != "03_PKSIM/ga/run_ga.R"]

status <- data.frame(step = steps, exit = NA_integer_, seconds = NA_real_)
for (i in seq_along(steps)) {
  s <- steps[i]
  cat("\n>>>", s, "\n")
  t0 <- Sys.time()
  parts <- strsplit(s, " ")[[1]]
  st <- system(paste("unset R_HOME;", shQuote(RS), paste(shQuote(parts), collapse = " ")))
  dt <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  status$exit[i] <- st; status$seconds[i] <- round(dt, 1)
  cat(sprintf("<<< %s — exit %d (%.1fs)\n", s, st, dt))
  if (st != 0 && !keep_going) {
    cat("STEP FAILED — aborting (use --keep-going to continue anyway)\n")
    break
  }
}

# --- manifest: every artifact with size + md5 ------------------------------
cat("\n=== writing 04_RESULTS/MANIFEST.csv ===\n")
artifacts <- list.files(c("04_RESULTS", "03_PKSIM/model", "01_COMPOUND_DATA/snapshots"),
                        recursive = TRUE, full.names = TRUE)
artifacts <- artifacts[!dir.exists(artifacts)]
manifest <- data.frame(
  file   = artifacts,
  bytes  = file.info(artifacts)$size,
  mtime  = format(file.info(artifacts)$mtime, "%Y-%m-%d %H:%M:%S"),
  md5    = tools::md5sum(artifacts),
  row.names = NULL
)
write.csv(manifest, "04_RESULTS/MANIFEST.csv", row.names = FALSE)
# Also keep legacy path via symlink for compatibility if it exists
if (dir.exists("results")) write.csv(manifest, "results/MANIFEST.csv", row.names = FALSE)
cat("manifest:", nrow(manifest), "artifacts\n")

print(status)
fail <- status$step[which(status$exit != 0)]
if (length(fail)) { cat("\nFAILED STEPS:", paste(fail, collapse = ", "), "\n")
  quit(save = "no", status = 1) }
cat("\n=== pipeline complete — see 04_RESULTS/ and 04_RESULTS/MANIFEST.csv ===\n")
