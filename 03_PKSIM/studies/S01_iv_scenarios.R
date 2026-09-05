# ============================================================================
# S01_iv_scenarios.R — IV dose x renal-function scenarios (PK-Sim engine)
# ----------------------------------------------------------------------------
# Batch mechanism (createSimulationBatch) varying:
#   - Events|...|ProtocolSchemaItem|Dose   (200-800 mg, 30-min infusion)
#   - Organism|Kidney|GFR (specific)       (CLCR 30-150 mL/min)
# NOTE: the renal process rate references GFR (specific) x kidney volume;
#       overriding the plain Organism|Kidney|GFR has no effect (verified).
#       CLCR -> GFR (specific) mapping: GFRspec = 0.266 x (CLCR / 112.5),
#       0.266 l/min/kg being the validated volunteer's baseline (GFR 112.5
#       mL/min, implied renal CL 5.63 L/h, thesis validation gate).
# ============================================================================
suppressMessages({library(ospsuite); library(ggplot2)})
PROJ <- (function(){d<-getwd();for(i in 1:6){if(file.exists(file.path(d,"pksim/env/pk_sim_run.R")))return(normalizePath(d));d<-dirname(d)};stop("root not found")})()

sim    <- loadSimulation(file.path(PROJ, "pksim", "model", "tobramycin_iv_validated.pkml"))
IV_RATE <- "Organism|PeripheralVenousBlood|Tobramycin|Plasma (Peripheral Venous Blood)"
DOSE_P  <- "Events|Walker 1979 Volunteer 1|Application_1|ProtocolSchemaItem|Dose"
GFR_P   <- "Organism|Kidney|GFR (specific)"
MW <- 467.515; MIC <- 1

doses <- c(200, 400, 577.5, 800)
clcrs <- c(30, 65, 90, 112.5, 150)
gfrspec_of <- function(clcr) 0.266 * clcr / 112.5

batch <- createSimulationBatch(sim, parametersOrPaths = c(GFR_P, DOSE_P))
combos <- expand.grid(dose = doses, clcr = clcrs)
for (i in seq_len(nrow(combos))) {
  # Dose base unit is kg (verified: 577.5 mg -> 0.0005775 kg)
  batch$addRunValues(c(gfrspec_of(combos$clcr[i]), combos$dose[i] / 1e6))
}
res <- runSimulationBatches(batch)[[1]]

rows <- list()
for (i in seq_along(res)) {
  out <- getOutputValues(res[[i]], quantitiesOrPaths = IV_RATE)
  df <- as.data.frame(out$data)
  tt <- df$Time / 60; cc <- df[[IV_RATE]] * MW / 1000
  k <- tt <= 24
  auc <- sum(diff(tt[k]) * (head(cc[k], -1) + tail(cc[k], -1)) / 2)
  rows[[i]] <- data.frame(
    dose_mg = combos$dose[i], CLCR = combos$clcr[i],
    Cmax = max(cc[k]), AUC24 = auc,
    Ctrough = cc[k][which.min(abs(tt[k] - 24))],
    CL_implied = combos$dose[i] / auc)
}
resdf <- do.call(rbind, rows)
resdf$Cmax_MIC <- resdf$Cmax / MIC
resdf$AUC_MIC  <- resdf$AUC24 / MIC
resdf$fe_norm  <- resdf$CL_implied / (0.266 * 0.42 * 60 * 0.95)  # sanity: ratio vs baseline renal CL
write.csv(resdf, file.path(PROJ, "results", "studies", "S01_iv_scenarios.csv"), row.names = FALSE)

p <- ggplot(resdf, aes(factor(CLCR), AUC24, fill = factor(dose_mg))) +
  geom_col(position = "dodge") +
  geom_hline(yintercept = 80, linetype = 2, color = "firebrick") +
  geom_hline(yintercept = 120, linetype = 2, color = "grey40") +
  labs(title = "IV tobramycin — AUC24 by dose and renal function (PK-Sim batch)",
       subtitle = "Dashed: AUC24/MIC target 80-120 (MIC 1 mg/L) — reached IV-only, never orally",
       x = "CLCR (mL/min)", y = "AUC24 (mg*h/L)", fill = "Dose (mg)") +
  theme(legend.position = "bottom")
ggsave(file.path(PROJ, "results", "studies", "S01_iv_scenarios.png"), p, width = 8, height = 5, dpi = 300, bg = "white")
cat("S01 done:", nrow(resdf), "scenarios\n")
print(resdf[resdf$dose_mg == 577.5, c("CLCR", "Cmax", "AUC24", "Ctrough", "CL_implied")])
