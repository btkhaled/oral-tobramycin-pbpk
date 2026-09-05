# ============================================================================
# 05_oral_vs_iv.R — Absolute bioavailability (oral vs IV, same dose)
# Output: oral_simulations/bioavailability_comparison.csv
# ============================================================================

PROJ <- local(function() {
  d <- getwd()
  for (i in 1:6) { if (file.exists(file.path(d, "03_PBPK_MODELING/scripts/engine_tobramycin.R"))) return(normalizePath(d)); d <- dirname(d) }
  stop("root not found")
})()
source(file.path(PROJ, "03_PBPK_MODELING", "scripts", "engine_tobramycin.R"))
RES <- file.path(PROJ, "03_PBPK_MODELING", "results")

DOSE <- 400; CLCR <- 120

iv <- simulate_tobramycin(dose_mg = DOSE, route = "iv_infusion", infusion_h = 0.5,
                          t_end_h = 24, CLCR_mL_min = CLCR)
m_iv <- pk_metrics(iv)
auc_iv <- m_iv$AUC24

scen <- tibble::tribble(
  ~scenario, ~papp_mult,
  "solution_native",   1,
  "sedds_native",      3,
  "pe_c10_50mM",       8,
  "hip_complex",       20,
  "hip_sedds_pe_full", 20
)
rows <- list()
for (i in seq_len(nrow(scen))) {
  po <- simulate_tobramycin(dose_mg = DOSE, route = "oral", n_doses = 1,
                            Papp_cm_s = TOB$Papp_ref * scen$papp_mult[i],
                            t_end_h = 24, CLCR_mL_min = CLCR)
  m <- pk_metrics(po)
  Fabs <- m$AUC24 / auc_iv * 100   # same dose, same subject
  rows[[i]] <- tibble::tibble(
    scenario = scen$scenario[i], dose_mg = DOSE,
    AUC_iv = auc_iv, AUC_oral = m$AUC24,
    F_absolute_pct = Fabs,
    F_literature = c("1-2", "3-5", "10-20", "10-25", "20-35")[i],
    Cmax_MIC = m$Cmax / TOB$MIC_default, AUC_MIC = m$AUC24 / TOB$MIC_default
  )
  cat(sprintf("%-20s F = %5.2f%%  (literature band %s%%)\n", scen$scenario[i], Fabs, tail(rows[[i]]$F_literature, 1)))
}
bio <- dplyr::bind_rows(rows)
write.csv(bio, file.path(RES, "oral_simulations", "bioavailability_comparison.csv"), row.names = FALSE)
cat("Output written: bioavailability_comparison.csv\n")
