# ============================================================================
# S07_winner_characterization.R — Exhaustive characterization of the GA-optimal
# oral tobramycin formulation (NSGA-II in-the-loop winner).
# ----------------------------------------------------------------------------
# Reads results/ga/top10.csv (rank-1 Pareto candidate: dose + P_int multiplier)
# and characterizes it:
#   (a)  single-dose PK profile + absolute bioavailability
#   (a2) minimal target-attaining dose at the winner multiplier (dose scan)
#   (b)  steady-state fractionation (QD / BID / TID) at winner and minimal dose
#   (c)  PTA vs MIC 0.25-4 mg/L (Cmax/MIC >= 8; AUC24/MIC >= 80)
#   (d)  virtual population (100 ICRP adults) on the winner
#   (e)  food effect on the winner
# Outputs: results/studies/S07_*.csv + S07_*.png
# ============================================================================
suppressMessages({library(ospsuite); library(ggplot2); library(dplyr)})
PROJ <- (function(){d<-getwd();for(i in 1:6){if(file.exists(file.path(d,"pksim/env/pk_sim_run.R")))return(normalizePath(d));d<-dirname(d)};stop("repo root not found")})()

MW <- 467.515; MIC <- 1
PINT0 <- 3e-9
AUC_IV_PER_MG <- 102.5 / 577.5

# ---------------------------------------------------------------- winner ----
top <- read.csv(file.path(PROJ, "results", "ga", "top10.csv"))
W   <- top[1, ]
w_dose  <- W$dose_mg
w_mult  <- W$Pint_mult
w_pint  <- PINT0 * w_mult
w_id    <- W$candidate_id
cat(sprintf("Winner: %s | dose %.0f mg | P_int %.3e dm/min (x%.1f) | F %.1f%% | Cmax/MIC %.1f\n",
            w_id, w_dose, w_pint, w_mult, W$F_oral, W$Cmax_MIC))

sim <- loadSimulation(file.path(PROJ, "pksim", "model", "tobramycin_oral.pkml"))
PINT <- "Tobramycin|Specific intestinal permeability (transcellular)"
GT   <- "Organism|Lumen|Stomach|Gastric emptying time"
setParameterValues(getParameter(PINT, sim), w_pint)
setOutputInterval(simulation = sim, startTime = 0, endTime = 5760, resolution = 10) # 96 h (min)

DOSE_P <- "Events|Tobramycin Oral Protocol|Oral Solution|Application_1|ProtocolSchemaItem|Dose"
run_profile <- function(dose_mg) {
  setParameterValues(getParameter(DOSE_P, sim), dose_mg / 1e6)  # base unit kg
  r <- runSimulations(sim)[[1]]
  out <- getOutputValues(r)
  df <- as.data.frame(out$data)
  pl <- grep("Plasma .Peripheral", names(df), value = TRUE)[1]
  data.frame(Time = df$Time / 60, Conc = df[[pl]] * MW / 1000)
}
metrics <- function(d) {
  auc <- sum(diff(d$Time) * (head(d$Conc, -1) + tail(d$Conc, -1)) / 2)
  list(Cmax = max(d$Conc), Tmax = d$Time[which.max(d$Conc)], AUC_inf = auc,
       F = (auc / max(w_dose, d$Time[0] + dose_ref())) / AUC_IV_PER_MG * 100, C24 = tail(d$Conc, 1))
}
dose_ref <- function() w_dose

# ------------------------------------------------ (a) single-dose profile ----
prof <- run_profile(w_dose)
m1 <- metrics(prof)
m1$F <- (m1$AUC_inf / w_dose) / AUC_IV_PER_MG * 100
write.csv(prof, file.path(PROJ, "results", "studies", "S07_winner_profile.csv"), row.names = FALSE)
cat(sprintf("single-dose: Cmax %.2f mg/L | Tmax %.1f h | AUCinf %.1f | F %.1f%% | C(24h) %.3f\n",
            m1$Cmax, m1$Tmax, m1$AUC_inf, m1$F, m1$C24))

# --------------------------------------------- steady-state superposition ----
ss <- function(dose_mg, interval_h, n = 30) {
  grid <- seq(0, interval_h, length.out = 400)
  scale <- dose_mg / w_dose
  acc <- rep(0, length(grid))
  for (k in 0:n) acc <- acc + approx(one_full$Time, one_full$Conc,
                                     xout = grid + k * interval_h, rule = 2)$y
  data.frame(Time = grid, Conc = acc * scale)
}
one_full <- prof

# ---------------- (a2) minimal target-attaining dose at the winner multiplier --
# The NSGA-II front degenerates to the max corner (F/Cmax/AUC objectives are
# synergistic; only dose opposes). The clinically relevant regimen is the
# dose-minimal candidate still attaining Cmax/MIC >= 8 at steady state.
dose_scan <- data.frame(dose_mg = c(150, 250, 350, 450, 550, 700, 850, 1000))
dose_scan$Cmax_ss <- sapply(dose_scan$dose_mg, function(dm) max(ss(dm, 24)$Conc))
dose_scan$Cmax_MIC <- dose_scan$Cmax_ss / MIC
write.csv(dose_scan, file.path(PROJ, "results", "studies", "S07_dose_scan.csv"), row.names = FALSE)
hit <- dose_scan$dose_mg[dose_scan$Cmax_MIC >= 8]
w_dose_min <- if (length(hit)) min(hit) else w_dose
cat(sprintf("Minimal target-attaining dose at x%.0f: %.0f mg (Cmax_ss/MIC = %.2f)\n",
            w_mult, w_dose_min,
            dose_scan$Cmax_ss[dose_scan$dose_mg == w_dose_min] / MIC))

# ------------------------------------------- (b) fractionation + (c) PTA ----
mics <- c(0.25, 0.5, 1, 2, 4)
regimens <- list(
  list(name = sprintf("QD %.0f (min target dose)", w_dose_min), dose = w_dose_min, interval = 24),
  list(name = sprintf("QD %.0f (GA winner)", w_dose),           dose = w_dose,       interval = 24),
  list(name = sprintf("BID %.0f", w_dose / 2),                  dose = w_dose / 2,   interval = 12),
  list(name = sprintf("BID %.0f", w_dose),                      dose = w_dose,       interval = 12)
)
frac_rows <- list(); pta_rows <- list()
for (rg in regimens) {
  ssd <- ss(rg$dose, rg$interval)
  auc <- sum(diff(ssd$Time) * (head(ssd$Conc, -1) + tail(ssd$Conc, -1)) / 2)
  cmax <- max(ssd$Conc); cmin <- min(ssd$Conc)
  frac_rows[[length(frac_rows) + 1]] <- data.frame(
    regimen = rg$name, dose_mg = rg$dose, interval_h = rg$interval,
    Cmax_ss = cmax, AUC_ss = auc, Cmin_ss = cmin,
    Cmax_MIC = cmax / MIC, AUC_MIC = auc / MIC,
    fT_MIC = 100 * mean(ssd$Conc >= MIC), daily_mg = rg$dose * 24 / rg$interval)
  for (m in mics) pta_rows[[length(pta_rows) + 1]] <- data.frame(
    regimen = rg$name, MIC = m,
    PTA_Cmax = 100 * mean(ssd$Conc / m >= 8),
    PTA_AUC  = 100 * as.numeric(auc / m >= 80))
}
frac <- do.call(rbind, frac_rows); pta <- do.call(rbind, pta_rows)
write.csv(frac, file.path(PROJ, "results", "studies", "S07_winner_fractionation.csv"), row.names = FALSE)
write.csv(pta,  file.path(PROJ, "results", "studies", "S07_winner_pta.csv"), row.names = FALSE)
print(frac); print(pta)

# ------------------------------------------- (d) population on the winner ----
pch <- createPopulationCharacteristics(
  species = "Human", population = "European_ICRP_2002",
  proportionOfFemales = 40, ageMin = 20, ageMax = 50,
  weightMin = 55, weightMax = 95, numberOfIndividuals = 100)
pop <- createPopulation(populationCharacteristics = pch)
sim_w <- loadSimulation(file.path(PROJ, "pksim", "model", "tobramycin_oral.pkml"))
setParameterValues(getParameter(PINT, sim_w), w_pint)
setParameterValues(getParameter(DOSE_P, sim_w), w_dose / 1e6)  # fix: winner dose was missing (default 550 mg)
popres <- runSimulations(sim_w, population = pop)
pl <- "Organism|PeripheralVenousBlood|Tobramycin|Plasma (Peripheral Venous Blood)"
outp <- getOutputValues(popres[[1]], quantitiesOrPaths = pl)
dfp <- as.data.frame(outp$data)
prow <- list()
for (id in unique(dfp$IndividualId)) {
  d2 <- dfp[dfp$IndividualId == id & dfp$Time <= 1440, ]
  tt <- d2$Time / 60; cc <- d2[[pl]] * MW / 1000
  auc <- sum(diff(tt) * (head(cc, -1) + tail(cc, -1)) / 2)
  prow[[length(prow) + 1]] <- data.frame(IndividualId = id, Cmax = max(cc),
    AUC24 = auc, Ctrough = cc[which.min(abs(tt - 24))])
}
popres_df <- do.call(rbind, prow)
popres_df$Cmax_MIC <- popres_df$Cmax / MIC
popres_df$AUC_MIC  <- popres_df$AUC24 / MIC
write.csv(popres_df, file.path(PROJ, "results", "studies", "S07_winner_population.csv"), row.names = FALSE)
cat(sprintf("population: Cmax/MIC median %.2f [%.2f-%.2f] | PTA(Cmax/MIC>=8) = %.0f%%\n",
            median(popres_df$Cmax_MIC), quantile(popres_df$Cmax_MIC, .05),
            quantile(popres_df$Cmax_MIC, .95), 100 * mean(popres_df$Cmax_MIC >= 8)))

# ------------------------------------------------- (e) food effect on winner -
fe <- lapply(c(15, 60), function(gmin) {
  setParameterValues(getParameter(GT, sim), gmin)
  d <- run_profile(w_dose)
  auc <- sum(diff(d$Time) * (head(d$Conc, -1) + tail(d$Conc, -1)) / 2)
  data.frame(state = ifelse(gmin <= 15, "fasted", "fed"), Cmax = max(d$Conc),
             Tmax = d$Time[which.max(d$Conc)], AUC_inf = auc,
             F_pct = (auc / w_dose) / AUC_IV_PER_MG * 100)
})
fed <- do.call(rbind, fe)
setParameterValues(getParameter(GT, sim), 15)
write.csv(fed, file.path(PROJ, "results", "studies", "S07_winner_food.csv"), row.names = FALSE)
print(fed)

# ------------------------------------------------------------------ figures --
p1 <- ggplot(prof[prof$Time <= 48, ], aes(Time, Conc)) +
  geom_line(color = "#005493", linewidth = 1) +
  geom_hline(yintercept = 8, linetype = 2, color = "firebrick") +
  labs(title = sprintf("%s — single-dose oral profile (%.0f mg, PK-Sim)", w_id, w_dose),
       subtitle = sprintf("Cmax %.2f mg/L | F %.1f%% | flip-flop absorption", m1$Cmax, m1$F),
       x = "Time (h)", y = "Plasma concentration (mg/L)")
ggsave(file.path(PROJ, "results", "studies", "S07_winner_profile.png"), p1,
       width = 8, height = 4.8, dpi = 300, bg = "white")

p2 <- ggplot(popres_df, aes(Cmax_MIC)) +
  geom_histogram(bins = 25, fill = "#005493", color = "white") +
  geom_vline(xintercept = 8, linetype = 2, color = "firebrick") +
  labs(title = sprintf("Virtual population (n=100) — %s", w_id),
       subtitle = sprintf("PTA Cmax/MIC >= 8: %.0f%% (MIC 1 mg/L)",
                          100 * mean(popres_df$Cmax_MIC >= 8)),
       x = "Cmax/MIC", y = "Subjects")
ggsave(file.path(PROJ, "results", "studies", "S07_winner_population.png"), p2,
       width = 7.5, height = 4.8, dpi = 300, bg = "white")

p3 <- ggplot(pta, aes(factor(MIC), PTA_Cmax, fill = regimen)) +
  geom_col(position = "dodge") +
  geom_hline(yintercept = 90, linetype = 2, color = "grey30") +
  labs(title = sprintf("PTA — Cmax/MIC >= 8 (%s)", w_id),
       x = "MIC (mg/L)", y = "PTA (%)", fill = "Regimen") + theme(legend.position = "bottom")
ggsave(file.path(PROJ, "results", "studies", "S07_winner_pta.png"), p3,
       width = 8, height = 4.6, dpi = 300, bg = "white")

cat("\nS07 done — winner characterized\n")
