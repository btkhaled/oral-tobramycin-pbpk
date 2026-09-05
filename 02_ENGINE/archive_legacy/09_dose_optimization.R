# ============================================================================
# 09_dose_optimization.R — Oral dose optimization + target assessment
# Outputs: oral_simulations/dose_optimization.csv, target_assessment.csv
# ============================================================================

PROJ <- local(function() {
  d <- getwd()
  for (i in 1:6) { if (file.exists(file.path(d, "03_PBPK_MODELING/scripts/engine_tobramycin.R"))) return(normalizePath(d)); d <- dirname(d) }
  stop("root not found")
})()
source(file.path(PROJ, "03_PBPK_MODELING", "scripts", "engine_tobramycin.R"))
RES <- file.path(PROJ, "03_PBPK_MODELING", "results")

suppressMessages(library(ggplot2))
doses <- c(200, 300, 400, 500, 550, 600, 800, 1000)
scen <- list(
  list(name = "native (Papp 1e-6)", mult = 1),
  list(name = "hip_complex (20x)",  mult = 20),
  list(name = "full_platform (20x BID-capable)", mult = 20)
)
rows <- list(); targets <- list()
for (s in scen) {
  for (d in doses) {
    n_int <- if (grepl("BID", s$name)) 12 else 24
    sim <- simulate_tobramycin(dose_mg = d, route = "oral", n_doses = 1,
                               Papp_cm_s = TOB$Papp_ref * s$mult,
                               t_end_h = 24, CLCR_mL_min = 120)
    m <- pk_metrics(sim)
    rows[[length(rows) + 1]] <- tibble::tibble(
      scenario = s$name, dose_mg = d, Cmax = m$Cmax, AUC24 = m$AUC24,
      Cmax_MIC = m$Cmax / TOB$MIC_default, AUC_MIC = m$AUC24 / TOB$MIC_default,
      F_pct = m$AUC24 / (d / cl_for_clcr(120)) * 100,
      Ctrough = m$Ctrough, fT_MIC = m$fT_MIC
    )
  }
  sdf <- dplyr::bind_rows(rows |> tail(length(doses)))
  targets[[length(targets) + 1]] <- tibble::tibble(
    scenario = s$name,
    min_dose_Cmax_target = { hit <- sdf$dose_mg[sdf$Cmax_MIC >= 8]; ifelse(length(hit), min(hit), NA) },
    min_dose_AUC_target  = { hit <- sdf$dose_mg[sdf$AUC_MIC >= 80]; ifelse(length(hit), min(hit), NA) }
  )
}
dose_pk <- dplyr::bind_rows(rows)
tgt <- dplyr::bind_rows(targets)
write.csv(dose_pk, file.path(RES, "oral_simulations", "dose_optimization.csv"), row.names = FALSE)
write.csv(tgt, file.path(RES, "oral_simulations", "target_assessment.csv"), row.names = FALSE)
print(tgt)
p <- ggplot(dose_pk, aes(dose_mg, Cmax_MIC, color = scenario)) + geom_line(linewidth = 1) +
  geom_hline(yintercept = 8, linetype = 2, color = "firebrick") +
  labs(title = "Dose optimization — Cmax/MIC vs dose (MIC 1 mg/L)",
       x = "Dose (mg)", y = "Cmax/MIC", color = "Scenario")
ggsave(file.path(RES, "figures", "dose_optimization.png"), p, width = 7.5, height = 4.8, dpi = 300, bg = "white")
cat("Outputs written: dose_optimization.csv, target_assessment.csv\n")
