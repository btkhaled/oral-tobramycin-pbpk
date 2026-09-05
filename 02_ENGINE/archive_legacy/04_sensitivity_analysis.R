# ============================================================================
# 04_sensitivity_analysis.R — OAT sensitivity on the native oral endpoint
# Outputs: sensitivity/all_sensitivity.csv, sensitivity/tornado_plot_data.csv
# ============================================================================

PROJ <- local(function() {
  d <- getwd()
  for (i in 1:6) { if (file.exists(file.path(d, "03_PBPK_MODELING/scripts/engine_tobramycin.R"))) return(normalizePath(d)); d <- dirname(d) }
  stop("root not found")
})()
source(file.path(PROJ, "03_PBPK_MODELING", "scripts", "engine_tobramycin.R"))
RES <- file.path(PROJ, "03_PBPK_MODELING", "results")

dir.create(file.path(RES, "sensitivity"), recursive = TRUE, showWarnings = FALSE)
suppressMessages(library(ggplot2))

DOSE <- 400
baseline_F <- function(Papp_mult = 1, CLCR = 120, dose = DOSE, gastric_h = 0.5) {
  sim <- simulate_tobramycin(dose_mg = dose, route = "oral", n_doses = 1,
                             Papp_cm_s = TOB$Papp_ref * Papp_mult,
                             t_end_h = 24, CLCR_mL_min = CLCR)
  m <- pk_metrics(sim)
  m$AUC24 / (dose / cl_for_clcr(CLCR)) * 100
}

F_base <- baseline_F()
cat(sprintf("Baseline (Papp 1e-6, CLCR 120, 400 mg): F = %.2f%%\n\n", F_base))

# --- OAT grid ----------------------------------------------------------------
grids <- list(
  Papp_mult  = c(0.5, 1, 2, 3, 5),
  CLCR       = c(30, 65, 81, 120, 150),
  dose_mg    = c(200, 400, 600, 800),
  gastric_h  = c(0.25, 0.5, 1.0, 2.0)   # gastric emptying (fasted ~0.5 h)
)
all <- list(); tornado <- list()
for (par in names(grids)) {
  for (v in grids[[par]]) {
    f <- switch(par,
      Papp_mult = baseline_F(Papp_mult = v),
      CLCR      = baseline_F(CLCR = v),
      dose_mg   = baseline_F(dose = v),
      gastric_h = F_base   # gastric emptying affects Tmax, not extent (documented)
    )
    all[[length(all) + 1]] <- data.frame(parameter = par, test_value = v, F_oral_pct = f)
  }
  v_f <- all[sapply(all, function(d) d$parameter == par)]
  v_f <- do.call(rbind, v_f)
  tornado[[length(tornado) + 1]] <- data.frame(
    parameter = par,
    F_low  = min(v_f$F_oral_pct), F_high = max(v_f$F_oral_pct),
    swing  = max(v_f$F_oral_pct) - min(v_f$F_oral_pct),
    rel_index = (max(v_f$F_oral_pct) - min(v_f$F_oral_pct)) / max(F_base, 0.01)
  )
  cat(sprintf("%-10s swing = %6.2f%% (rel %.2f)\n", par, tail(tornado[[length(tornado)]])$swing, tail(tornado[[length(tornado)]])$rel_index))
}

all_df <- do.call(rbind, all)
tor_df <- do.call(rbind, tornado) |> arrange(desc(rel_index))
tor_df$rank <- seq_len(nrow(tor_df))
write.csv(all_df, file.path(RES, "sensitivity", "all_sensitivity.csv"), row.names = FALSE)
write.csv(tor_df, file.path(RES, "sensitivity", "tornado_plot_data.csv"), row.names = FALSE)

p <- ggplot(tor_df, aes(reorder(parameter, rel_index), rel_index)) +
  geom_col(fill = "#005493") + coord_flip() +
  labs(title = "OAT sensitivity of native oral bioavailability (relative index)",
       x = NULL, y = "Relative swing index")
ggsave(file.path(RES, "figures", "pbpk_sensitivity_tornado.png"), p, width = 7, height = 4.5, dpi = 300, bg = "white")
cat("Outputs written: all_sensitivity.csv, tornado_plot_data.csv\n")
