# ============================================================================
# S06_fractionation_pta.R — Dosing fractionation + PTA vs MIC distribution
# Regimens (platform oral, P_int = x20): QD 550, BID 275, BID 550, TID 200.
# Steady state by linear superposition of the validated single-dose profile
# (linear kinetics — exact). PTA: P(Cmax/MIC >= 8) across MIC 0.25-4 mg/L.
# Outputs: results/studies/S06_fractionation.csv, S06_pta.csv (+ png)
# ============================================================================
suppressMessages({library(ospsuite); library(ggplot2)})
PROJ <- (function(){d<-getwd();for(i in 1:6){if(file.exists(file.path(d,"pksim/env/pk_sim_run.R")))return(normalizePath(d));d<-dirname(d)};stop("root not found")})()

MW <- 467.515
sim <- loadSimulation(file.path(PROJ, "pksim", "model", "tobramycin_oral.pkml"))
PINT <- "Tobramycin|Specific intestinal permeability (transcellular)"
setParameterValues(getParameter(PINT, sim), 3e-9 * 20)
# simulate the single dose over 96 h: the oral profile exhibits flip-flop
# kinetics (absorption rate-limited by GI transit + permeability), so the
# 24 h output window truncates the tail and would corrupt the superposition
setOutputInterval(simulation = sim, startTime = 0, endTime = 5760, resolution = 10)  # base unit = min -> 96 h

r <- runSimulations(sim)[[1]]
out <- getOutputValues(r)
df <- as.data.frame(out$data)
pl <- grep("Plasma .Peripheral", names(df), value = TRUE)[1]
t_h  <- df$Time / 60
c_mg <- df[[pl]] * MW / 1000
k <- t_h <= 96   # full tail captured (flip-flop kinetics)
t1 <- t_h[k]; c1 <- c_mg[k]

# Steady state by linear superposition (exact for linear kinetics):
# ss(t) = sum_{k>=0} one(t + k*tau), t in [0, tau)
superpose <- function(dose_mg, interval_h, n = 14) {
  scale <- dose_mg / 550
  out_t <- seq(0, interval_h, length.out = 300)
  acc <- rep(0, length(out_t))
  for (k in 0:n) {
    acc <- acc + approx(t1, c1, xout = out_t + k * interval_h, rule = 2)$y
  }
  data.frame(Time = out_t, Conc = acc * scale)
}

regimens <- list(
  list(name = "QD 550",  dose = 550, interval = 24),
  list(name = "BID 275", dose = 275, interval = 12),
  list(name = "BID 550", dose = 550, interval = 12),
  list(name = "TID 200", dose = 200, interval = 8)
)
rows <- list(); pta_rows <- list()
mics <- c(0.25, 0.5, 1, 2, 4)
for (rg in regimens) {
  ss <- superpose(rg$dose, rg$interval)
  auc_ss <- sum(diff(ss$Time) * (head(ss$Conc, -1) + tail(ss$Conc, -1)) / 2)
  cmax <- max(ss$Conc); cmin <- min(ss$Conc)
  ft <- 100 * mean(ss$Conc >= 1)
  rows[[length(rows) + 1]] <- data.frame(
    regimen = rg$name, dose_mg = rg$dose, interval_h = rg$interval,
    Cmax_ss = cmax, Cmax_MIC = cmax / 1, AUC24 = auc_ss, AUC_MIC = auc_ss,
    Cmin_ss = cmin, fT_MIC = ft,
    daily_mg = rg$dose * 24 / rg$interval)
  for (m in mics) {
    pta_rows[[length(pta_rows) + 1]] <- data.frame(
      regimen = rg$name, MIC = m,
      PTA_Cmax = 100 * mean(ss$Conc / m >= 8),
      PTA_AUC  = 100 * as.numeric(auc_ss / m >= 80))
  }
}
frac <- do.call(rbind, rows); pta <- do.call(rbind, pta_rows)
write.csv(frac, file.path(PROJ, "results", "studies", "S06_fractionation.csv"), row.names = FALSE)
write.csv(pta,  file.path(PROJ, "results", "studies", "S06_pta.csv"), row.names = FALSE)

p1 <- ggplot(frac, aes(regimen, Cmax_MIC, fill = regimen)) + geom_col(show.legend = FALSE) +
  geom_hline(yintercept = 8, linetype = 2, color = "firebrick") +
  labs(title = "Fractionation at steady state — Cmax/MIC (MIC 1 mg/L)",
       x = NULL, y = "Cmax/MIC")
p2 <- ggplot(pta, aes(factor(MIC), PTA_Cmax, fill = regimen)) +
  geom_col(position = "dodge") +
  geom_hline(yintercept = 90, linetype = 2, color = "grey30") +
  labs(title = "Probability of target attainment — Cmax/MIC >= 8",
       x = "MIC (mg/L)", y = "PTA (%)", fill = "Regimen") + theme(legend.position = "bottom")
ggsave(file.path(PROJ, "results", "studies", "S06_fractionation.png"), p1,
       width = 7, height = 4.4, dpi = 300, bg = "white")
ggsave(file.path(PROJ, "results", "studies", "S06_pta.png"), p2,
       width = 8, height = 4.6, dpi = 300, bg = "white")
print(frac); print(pta)
cat("S06 done\n")
