# ============================================================================
# 10_export_results.R — Aggregate all PBPK module outputs
# Output: results/summary_results.json + results/module_summary.csv
# ============================================================================

PROJ <- local(function() {
  d <- getwd()
  for (i in 1:6) { if (file.exists(file.path(d, "03_PBPK_MODELING/scripts/engine_tobramycin.R"))) return(normalizePath(d)); d <- dirname(d) }
  stop("root not found")
})()
source(file.path(PROJ, "03_PBPK_MODELING", "scripts", "engine_tobramycin.R"))
RES <- file.path(PROJ, "03_PBPK_MODELING", "results")

rd <- function(p) {
  f <- file.path(RES, p)
  if (file.exists(f)) read.csv(f) else NULL
}
iv_gate  <- rd("iv_validation/iv_validation_gate.csv")
iv_pk    <- rd("iv_validation/iv_pk_parameters.csv")
oral_pk  <- rd("oral_simulations/oral_pk_parameters.csv")
bio      <- rd("oral_simulations/bioavailability_comparison.csv")
tor      <- rd("sensitivity/tornado_plot_data.csv")
dose_tg  <- rd("oral_simulations/target_assessment.csv")

summary <- list(
  module = "03_PBPK_MODELING (native pure-R tobramycin engine)",
  engine = "2-compartment + regional GI (ACAT-lite) + CLCR power model + Hill PD",
  validation_gate_all_pass = all(iv_gate$check == "TRUE" | iv_gate$check == TRUE),
  gate = iv_gate,
  iv_parameters = iv_pk,
  oral_scenarios = oral_pk,
  bioavailability = bio,
  sensitivity_ranking = tor,
  dose_targets = dose_tg,
  key_conclusions = list(
    solubility_not_limiting = TRUE,
    permeability_primary_driver = TRUE,
    native_F_pct = "1.5-2.5 (emerges from Papp calibration)",
    hip_platform_F_pct = "~35 (Papp 20x; cross-checks GA optimum 34%)"
  ),
  generated = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
)
jsonlite::write_json(summary, file.path(RES, "summary_results.json"), pretty = TRUE, auto_unbox = TRUE)

# flat CSV summary
summ <- rbind(
  data.frame(section = "gate", item = iv_gate$metric, value = as.character(iv_gate$engine_value)),
  data.frame(section = "bioavailability", item = bio$scenario, value = sprintf("%.1f%%", bio$F_absolute_pct)),
  data.frame(section = "sensitivity_rank", item = tor$parameter, value = as.character(tor$rank))
)
write.csv(summ, file.path(RES, "module_summary.csv"), row.names = FALSE)
cat("Outputs written: summary_results.json, module_summary.csv\n")
cat("\n=== PBPK module complete ===\n")
