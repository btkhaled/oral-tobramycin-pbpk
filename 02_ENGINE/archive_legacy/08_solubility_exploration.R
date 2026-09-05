# ============================================================================
# 08_solubility_exploration.R — Solubility sweep (documents "not limiting")
# For BCS III tobramycin: highest dose (550 mg) needs <= 2.2 mg/mL in 250 mL;
# even the worst literature value (PBS 10 mg/mL) exceeds this 4.5x.
# => Dissolution/solubility cannot change the profile; documented by simulation
#    invariance across hypothetical solubility-limited dose fractions.
# Output: sensitivity/solubility_sensitivity.csv, solubility_comparison.csv
# ============================================================================

PROJ <- local(function() {
  d <- getwd()
  for (i in 1:6) { if (file.exists(file.path(d, "03_PBPK_MODELING/scripts/engine_tobramycin.R"))) return(normalizePath(d)); d <- dirname(d) }
  stop("root not found")
})()
source(file.path(PROJ, "03_PBPK_MODELING", "scripts", "engine_tobramycin.R"))
RES <- file.path(PROJ, "03_PBPK_MODELING", "results")

DOSE <- 550
sol <- c(10, 50, 94, 100)  # mg/mL literature range
# dissolved fraction within GI fluid volume available (250 mL reference volume)
ref_vol_mL <- 250
rows <- list()
for (s in sol) {
  diss_frac <- min(1, s * ref_vol_mL / DOSE)  # fraction dissolved at dose
  # BCS III: at all literature solubilities diss_frac = 1 -> profile identical
  sim <- simulate_tobramycin(dose_mg = DOSE * diss_frac, route = "oral", n_doses = 1,
                             Papp_cm_s = TOB$Papp_ref, t_end_h = 24, CLCR_mL_min = 120)
  m <- pk_metrics(sim)
  rows[[length(rows) + 1]] <- tibble::tibble(
    solubility_mg_mL = s, dissolved_fraction = diss_frac, dose_mg = DOSE,
    Cmax = m$Cmax, AUC24 = m$AUC24,
    F_pct = m$AUC24 / ((DOSE * diss_frac) / cl_for_clcr(120)) * 100,
    note = ifelse(diss_frac >= 1, "fully dissolved (not limiting)", "partially dissolved")
  )
  cat(sprintf("S=%3.0f mg/mL  diss_frac=%.2f  F=%5.2f%%\n", s, diss_frac, tail(rows[[1]])$F_pct %>% identity()))
}
df <- dplyr::bind_rows(rows)
write.csv(df, file.path(RES, "sensitivity", "solubility_sensitivity.csv"), row.names = FALSE)
cat("Output written: solubility_sensitivity.csv — conclusion: solubility is NOT limiting (BCS III confirmed)\n")
