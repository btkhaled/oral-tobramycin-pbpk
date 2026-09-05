# ============================================================================
# 07_permeability_exploration.R — Papp sweep (BCS III primary driver)
# Output: sensitivity/permeability_sensitivity.csv, permeability_comparison.csv
# ============================================================================

PROJ <- local(function() {
  d <- getwd()
  for (i in 1:6) { if (file.exists(file.path(d, "03_PBPK_MODELING/scripts/engine_tobramycin.R"))) return(normalizePath(d)); d <- dirname(d) }
  stop("root not found")
})()
source(file.path(PROJ, "03_PBPK_MODELING", "scripts", "engine_tobramycin.R"))
RES <- file.path(PROJ, "03_PBPK_MODELING", "results")

DOSE <- 400
papps <- c(0.5, 1, 2, 5, 10, 20, 30)   # x Papp_ref (1e-6 cm/s)
rows <- list(); profs <- list()
for (p in papps) {
  sim <- simulate_tobramycin(dose_mg = DOSE, route = "oral", n_doses = 1,
                             Papp_cm_s = TOB$Papp_ref * p, t_end_h = 24, CLCR_mL_min = 120)
  m <- pk_metrics(sim)
  rows[[length(rows) + 1]] <- tibble::tibble(
    papp_mult = p, Papp_cm_s = TOB$Papp_ref * p,
    Cmax = m$Cmax, Tmax = m$Tmax, AUC24 = m$AUC24,
    F_pct = m$AUC24 / (DOSE / cl_for_clcr(120)) * 100,
    Cmax_MIC = m$Cmax / TOB$MIC_default
  )
  profs[[length(profs) + 1]] <- data.frame(papp_mult = p, sim[, c("Time", "Conc")])
  cat(sprintf("Papp x%-4.1f  F=%5.2f%%  Cmax=%6.3f\n", p, dplyr::last(rows[[1]]$F_pct), m$Cmax))
}
df <- dplyr::bind_rows(rows); pr <- dplyr::bind_rows(profs)
write.csv(df, file.path(RES, "sensitivity", "permeability_sensitivity.csv"), row.names = FALSE)
write.csv(pr, file.path(RES, "sensitivity", "permeability_profiles.csv"), row.names = FALSE)
cat("Outputs written: permeability_sensitivity.csv, permeability_profiles.csv\n")
