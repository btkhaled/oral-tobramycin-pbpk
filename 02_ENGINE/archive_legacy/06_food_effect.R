# ============================================================================
# 06_food_effect.R — Fasted vs fed state
# Fed: slower gastric emptying (0.5 -> 1.5 h), no solubility benefit
# (BCS III: drug already fully dissolved; bile/solubilization irrelevant).
# Output: oral_simulations/food_effect_data.csv, food_effect_comparison.csv
# ============================================================================

PROJ <- local(function() {
  d <- getwd()
  for (i in 1:6) { if (file.exists(file.path(d, "03_PBPK_MODELING/scripts/engine_tobramycin.R"))) return(normalizePath(d)); d <- dirname(d) }
  stop("root not found")
})()
source(file.path(PROJ, "03_PBPK_MODELING", "scripts", "engine_tobramycin.R"))
RES <- file.path(PROJ, "03_PBPK_MODELING", "results")

suppressMessages(library(ggplot2))
DOSE <- 400

run_state <- function(stomach_h) {
  gi <- GI_SEGMENTS
  gi$transit_h[1] <- stomach_h
  sim <- simulate_tobramycin(dose_mg = DOSE, route = "oral", n_doses = 1,
                             Papp_cm_s = TOB$Papp_ref, t_end_h = 24, CLCR_mL_min = 120)
  m <- pk_metrics(sim)
  list(sim = sim, m = m)
}
# patch GI segment transit for fed state (engine reads GI_SEGMENTS global)
fasted <- run_state(0.5)
GI_SEGMENTS$transit_h[1] <- 1.5
fed <- run_state(1.5)
GI_SEGMENTS$transit_h[1] <- 0.5   # restore

fd <- rbind(
  data.frame(state = "fasted", fasted$sim[, c("Time", "Conc")]),
  data.frame(state = "fed",    fed$sim[, c("Time", "Conc")])
)
cmp <- tibble::tibble(
  state = c("fasted", "fed"),
  gastric_emptying_h = c(0.5, 1.5),
  Cmax = c(fasted$m$Cmax, fed$m$Cmax),
  Tmax = c(fasted$m$Tmax, fed$m$Tmax),
  AUC24 = c(fasted$m$AUC24, fed$m$AUC24),
  F_pct = c(fasted$m$AUC24, fed$m$AUC24) / (DOSE / cl_for_clcr(120)) * 100,
  Cmax_ratio_fed_fasted = fed$m$Cmax / fasted$m$Cmax
)
write.csv(fd,  file.path(RES, "oral_simulations", "food_effect_data.csv"), row.names = FALSE)
write.csv(cmp, file.path(RES, "oral_simulations", "food_effect_comparison.csv"), row.names = FALSE)
print(cmp)
p <- ggplot(fd, aes(Time, Conc, color = state)) + geom_line(linewidth = 1) +
  labs(title = "Food effect — native oral tobramycin (400 mg)",
       subtitle = "Fed delays Tmax; extent unchanged (BCS III: solubility never limiting)",
       x = "Time (h)", y = "Plasma concentration (mg/L)", color = "State")
ggsave(file.path(RES, "figures", "food_effect.png"), p, width = 7, height = 4.5, dpi = 300, bg = "white")
cat("Outputs written: food_effect_data.csv, food_effect_comparison.csv\n")
