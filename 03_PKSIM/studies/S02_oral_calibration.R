# ============================================================================
# S02_oral_calibration.R — Calibrate the transcellular intestinal permeability
# override so that the PK-Sim oral baseline reproduces the literature
# bioavailability envelope (F0 ~ 1.5-2%), then map the enhancement factors.
# ----------------------------------------------------------------------------
# Context: PK-Sim's Willmann correlation yields P_int = 1.9e-12 dm/min for
# tobramycin (logP -2.9, MW 467) — effectively zero because the paracellular
# pathway is not included by default and the correlation saturates for very
# hydrophilic cations. Clinical evidence (F 1-2%) implies a higher effective
# permeability; the override reproduces it (documented PK-Sim practice for
# Caco-2 inputs, PK-Sim user documentation, "Specific intestinal permeability").
# ============================================================================
suppressMessages(library(ospsuite))
PROJ <- (function(){d<-getwd();for(i in 1:6){if(file.exists(file.path(d,"pksim/env/pk_sim_run.R")))return(normalizePath(d));d<-dirname(d)};stop("root not found")})()

sim <- loadSimulation(file.path(PROJ, "pksim", "model", "tobramycin_oral.pkml"))
P   <- "Tobramycin|Specific intestinal permeability (transcellular)"
MW  <- 467.515
auc_iv <- 102.5; dose_o <- 550; dose_i <- 577.5

setOutputInterval(simulation = sim, startTime = 0, endTime = 5760, resolution = 10)  # 96-h output

run_F <- function(pint_dm_min) {
  setParameterValues(getParameter(P, sim), pint_dm_min)
  r <- runSimulations(sim)[[1]]
  out <- getOutputValues(r)
  df <- as.data.frame(out$data)
  pl <- grep("Plasma .Peripheral", names(df), value = TRUE)[1]
  d2 <- df[df$Time <= 5760, ]                 # 96-h window (Time in MINUTES) — captures the flip-flop tail; F convention documented in docs/07
  tt <- d2$Time / 60                          # -> hours
  cc <- d2[[pl]] * MW / 1000                  # µmol/l -> mg/L
  auc <- sum(diff(tt) * (head(cc, -1) + tail(cc, -1)) / 2)
  cmax <- max(cc)
  F <- (auc / dose_o) / (auc_iv / dose_i) * 100
  list(F = F, cmax = cmax, auc = auc)
}

cat("=== P_int calibration scan (PK-Sim native oral) ===\n")
vals <- c(1e-11, 3e-11, 1e-10, 3e-10, 1e-9, 3e-9, 1e-8, 3e-8, 1e-7, 3e-7, 1e-6)  # dm/min, log-scan
out <- do.call(rbind, lapply(vals, function(v) {
  r <- run_F(v)
  cat(sprintf("Pint=%8.2e dm/min (%.1e cm/s): F=%7.3f%%  Cmax=%8.4f  AUC=%8.3f\n",
              v, v / 60, r$F, r$cmax, r$auc))
  data.frame(pint_dm_min = v, pint_cm_s = v / 60, F = r$F, cmax = r$cmax, auc = r$auc)
}))
dir.create(file.path(PROJ, "results"), showWarnings = FALSE)
write.csv(out, file.path(PROJ, "results", "studies", "S02_oral_papp_calibration.csv"), row.names = FALSE)

# interpolation helpers for the GA mapping
F_of_pint <- function(v) approx(out$pint_dm_min, out$F, xout = v, rule = 2)$y
cat("\nCalibration table saved: results/S02_oral_papp_calibration.csv\n")
