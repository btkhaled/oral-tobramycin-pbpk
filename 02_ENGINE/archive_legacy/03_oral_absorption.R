# ============================================================================
# 03_oral_absorption.R — Oral absorption scenarios (native tobramycin engine)
# Outputs: oral_simulations/oral_concentration_time.csv, oral_pk_parameters.csv
# ============================================================================

PROJ <- local(function() {
  d <- getwd()
  for (i in 1:6) { if (file.exists(file.path(d, "03_PBPK_MODELING/scripts/engine_tobramycin.R"))) return(normalizePath(d)); d <- dirname(d) }
  stop("root not found")
})()
source(file.path(PROJ, "03_PBPK_MODELING", "scripts", "engine_tobramycin.R"))
RES <- file.path(PROJ, "03_PBPK_MODELING", "results")

dir.create(file.path(RES, "oral_simulations"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(RES, "figures"), recursive = TRUE, showWarnings = FALSE)
suppressMessages(library(ggplot2))

DOSE <- 400
cat("=== Oral absorption scenarios (native engine, regional GI model) ===\n")

# Scenario set: native + formulation-enhanced Papp multipliers
# (Papp multiplier maps a formulation strategy to apparent permeability;
#  HIP logP' +1.6 => ~20x; SEDDS/NP/PE literature bands -> multipliers 2-10x)
scenarios <- tibble::tribble(
  ~scenario,              ~papp_mult, ~note,
  "solution_native",      1,          "Papp 1e-6 cm/s; F0 envelope 1.5-2.5%",
  "suspension_native",    1.2,        "slightly improved wetting",
  "sedds_native",         3,          "emulsification gain",
  "plga_np",              6,          "mucoadhesion + uptake",
  "pe_c10_10mM",          5,          "tight-junction modulation",
  "pe_c10_50mM",          8,          "C10 upper safe range",
  "hip_complex",          20,         "logP' +1.6 (Asad 2023)",
  "hip_sedds_pe_full",    20,         "combined platform (GA optimum proxy)"
)

profiles <- list(); rows <- list()
for (i in seq_len(nrow(scenarios))) {
  sc <- scenarios[i, ]
  sim <- simulate_tobramycin(dose_mg = DOSE, route = "oral", n_doses = 1,
                             Papp_cm_s = TOB$Papp_ref * sc$papp_mult,
                             t_end_h = 24, CLCR_mL_min = 120)
  m <- pk_metrics(sim)
  profiles[[i]] <- data.frame(scenario = sc$scenario, sim[, c("Time", "Conc")])
  rows[[i]] <- tibble::tibble(
    scenario = sc$scenario, papp_mult = sc$papp_mult,
    Papp_cm_s = TOB$Papp_ref * sc$papp_mult, dose_mg = DOSE,
    Cmax = m$Cmax, Tmax = m$Tmax, AUC24 = m$AUC24,
    F_oral_pct = m$AUC24 / (DOSE / cl_for_clcr(120)) * 100,
    Cmax_MIC = m$Cmax / TOB$MIC_default, AUC_MIC = m$AUC24 / TOB$MIC_default,
    Ctrough = m$Ctrough, note = sc$note
  )
  cat(sprintf("%-20s mult=%2.0f  F=%5.2f%%  Cmax=%6.3f  AUC=%6.2f\n",
              sc$scenario, sc$papp_mult, tail(rows[[i]]$F_oral_pct, 1), m$Cmax, m$AUC24))
}

prof <- dplyr::bind_rows(profiles)
params <- dplyr::bind_rows(rows)
write.csv(prof, file.path(RES, "oral_simulations", "oral_concentration_time.csv"), row.names = FALSE)
write.csv(params, file.path(RES, "oral_simulations", "oral_pk_parameters.csv"), row.names = FALSE)

p <- ggplot(prof, aes(Time, Conc, color = scenario)) +
  geom_line(linewidth = 0.9) +
  geom_hline(yintercept = 8, linetype = 2, color = "firebrick") +
  labs(title = "Oral tobramycin — formulation scenarios (400 mg, regional GI model)",
       subtitle = "Papp-driven absorption; dashed line = Cmax/MIC threshold (8, MIC 1 mg/L)",
       x = "Time (h)", y = "Plasma concentration (mg/L)", color = "Scenario") +
  theme(legend.position = "bottom")
ggsave(file.path(RES, "figures", "oral_scenarios.png"), p, width = 8.5, height = 5.5, dpi = 300, bg = "white")
cat("Outputs written: oral_concentration_time.csv, oral_pk_parameters.csv, figures/oral_scenarios.png\n")
