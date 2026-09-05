# ============================================================================
# run_all.R — Master pipeline (hardened, Phase 0)
# Stages: env check -> DB patch -> S00 gate -> S01..S03 -> GA -> S04..S09
#         -> molecule batteries -> manifest. The NSGA-II GA runs in the
#         PK-Sim loop by default (pop 100 x gen 100, ~1-2 h).
# Usage:  Rscript run_all.R [--skip-ga] [--keep-going]
#         --skip-ga  reuse the committed results/ga/ Pareto front instead of
#                    re-running the GA (~2 min instead of ~1-2 h).
# Env:    DOTNET_ROOT must point to a .NET 8 install.
# NOTE:   on this macOS setup only the CRAN R build works (Homebrew R's rSharp
#         crashes in sexp_to_parameters); the CRAN Rscript path is preferred.
# ============================================================================
PROJ <- (function(){d<-getwd();for(i in 1:6){if(file.exists(file.path(d,"pksim/env/pk_sim_run.R")))return(normalizePath(d));d<-dirname(d)};stop("repo root not found")})()
setwd(PROJ)
args <- commandArgs(TRUE)
skip_ga    <- "--skip-ga" %in% args
keep_going <- "--keep-going" %in% args

# --- Rscript resolution: CRAN R first (rSharp works there), then R.home() ---
RS <- "/Library/Frameworks/R.framework/Resources/bin/Rscript"
if (!file.exists(RS)) RS <- file.path(R.home("bin"), "Rscript")

cat("=== oral-tobramycin-pbpk — master pipeline ===\n")
cat(sprintf("root: %s\nRscript: %s\nGA: %s\n\n", PROJ, RS,
            ifelse(skip_ga, "--skip-ga (reuse committed results/ga/)", "NSGA-II in the PK-Sim loop (~1-2 h)")))

steps <- c(
  "pksim/env/check_env.R",
  "pksim/studies/S00_validation_gate.R",
  "pksim/studies/S01_iv_scenarios.R",
  "pksim/studies/S02_oral_calibration.R",
  "pksim/studies/S03_population.R",
  "pksim/ga/run_ga.R",
  "pksim/studies/S04_sensitivity.R",
  "pksim/studies/S05_food_effect.R",
  "pksim/studies/S06_fractionation_pta.R",
  "pksim/studies/S07_winner_characterization.R",
  "pksim/studies/S08_requirement_map.R",
  "pksim/studies/S09_multiplier_uncertainty.R",
  "pksim/studies/molecule_battery.R A pksim/studies/molecules/A_legacy_winner.csv",
  "pksim/studies/molecule_battery.R B pksim/studies/molecules/B_pksim_winner.csv"
)
if (skip_ga) steps <- steps[steps != "pksim/ga/run_ga.R"]

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
cat("\n=== writing results/MANIFEST.csv ===\n")
artifacts <- list.files(c("results", "pksim/model", "data/snapshots"),
                        recursive = TRUE, full.names = TRUE)
artifacts <- artifacts[!dir.exists(artifacts)]
manifest <- data.frame(
  file   = artifacts,
  bytes  = file.info(artifacts)$size,
  mtime  = format(file.info(artifacts)$mtime, "%Y-%m-%d %H:%M:%S"),
  md5    = tools::md5sum(artifacts),
  row.names = NULL
)
write.csv(manifest, "results/MANIFEST.csv", row.names = FALSE)
cat("manifest:", nrow(manifest), "artifacts\n")

print(status)
fail <- status$step[which(status$exit != 0)]
if (length(fail)) { cat("\nFAILED STEPS:", paste(fail, collapse = ", "), "\n")
  quit(save = "no", status = 1) }
cat("\n=== pipeline complete — see results/ and results/MANIFEST.csv ===\n")
