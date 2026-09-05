# ============================================================================
# S09_multiplier_uncertainty.R — Attainability frontier WITH uncertainty
# ----------------------------------------------------------------------------
# Propagates the component-factor uncertainties (enhancement_model.R, lognormal
# sigmas by evidence grade) through the validated F(multiplier) response and
# the steady-state PK/PD targets, for BOTH molecules.
# Analytic: interpolates the native PK-Sim S08 map (96-h convention) — no
# re-simulation needed. Outputs per-molecule CSVs + the frontier figure.
# ============================================================================
suppressMessages({library(ggplot2)})
PROJ <- (function(){d<-getwd();for(i in 1:6){if(file.exists(file.path(d,"pksim/ga/enhancement_model.R")))return(normalizePath(d));d<-dirname(d)};stop("repo root not found")})()
source(file.path(PROJ, "pksim/ga/enhancement_model.R"))
OUT <- file.path(PROJ, "results", "studies")
dir.create(OUT, showWarnings = FALSE)

s08 <- read.csv(file.path(OUT, "S08_requirement_map.csv"))
s08 <- s08[order(s08$mult), ]
# interpolators on the validated map (log-mult grid)
F_of_mult   <- function(m) approx(log(s08$mult), s08$F_993,        xout = log(m), yleft = s08$F_993[1],        yright = 100)$y
CMAX_of_mult<- function(m) approx(log(s08$mult), s08$Cmax_ss_MIC_993, xout = log(m), yleft = 0, yright = max(s08$Cmax_ss_MIC_993))$y
AUC_of_mult <- function(m) approx(log(s08$mult), s08$AUC_ss_MIC_993,  xout = log(m), yleft = 0, yright = max(s08$AUC_ss_MIC_993))$y
CMIN_of_mult<- function(m) approx(log(s08$mult), s08$Cmin_ss_993,  xout = log(m), yleft = s08$Cmin_ss_993[1], yright = 0)$y

molecules <- list(
  A = list(file = file.path(PROJ, "pksim/studies/molecules/A_legacy_winner.csv"), dose = 550.57),
  B = list(file = file.path(PROJ, "pksim/studies/molecules/B_pksim_winner.csv"),  dose = 1000)
)

res_list <- list()
for (mid in names(molecules)) {
  chrom <- as.list(read.csv(molecules[[mid]]$file, stringsAsFactors = FALSE))
  names(chrom) <- sub("^X", "", names(chrom))
  u <- sample_multiplier(chrom, n = 20000, seed = 42)
  m <- u$mults
  df <- data.frame(
    molecule = mid, mult = m,
    F96 = F_of_mult(m),
    Cmax_ss_MIC = CMAX_of_mult(m) * molecules[[mid]]$dose / 993,
    AUC_ss_MIC  = AUC_of_mult(m)  * molecules[[mid]]$dose / 993,
    Cmin_ss     = CMIN_of_mult(m) * molecules[[mid]]$dose / 993
  )
  summ <- data.frame(
    molecule = mid, dose_mg = molecules[[mid]]$dose,
    mult_point = u$point,
    mult_lo = u$ci[1], mult_hi = u$ci[3],
    F_point = F_of_mult(u$point),
    F_lo = quantile(df$F96, .025), F_hi = quantile(df$F96, .975),
    Cmax_MIC_med = median(df$Cmax_ss_MIC),
    Cmax_MIC_lo = quantile(df$Cmax_ss_MIC, .025), Cmax_MIC_hi = quantile(df$Cmax_ss_MIC, .975),
    AUC_MIC_med = median(df$AUC_ss_MIC),
    AUC_MIC_lo = quantile(df$AUC_ss_MIC, .025), AUC_MIC_hi = quantile(df$AUC_ss_MIC, .975),
    Cmin_med = median(df$Cmin_ss),
    PTA_Cmax8 = 100 * mean(df$Cmax_ss_MIC >= 8),
    PTA_AUC80 = 100 * mean(df$AUC_ss_MIC >= 80),
    PTA_AUC120 = 100 * mean(df$AUC_ss_MIC <= 120)
  )
  write.csv(df, file.path(OUT, sprintf("S09_uncertainty_samples_%s.csv", mid)), row.names = FALSE)
  write.csv(summ, file.path(OUT, sprintf("S09_uncertainty_summary_%s.csv", mid)), row.names = FALSE)
  res_list[[mid]] <- df
  cat("S09", mid, sprintf(": mult %.1f [%.1f-%.1f] -> F96 %.1f%% [%.1f-%.1f] | AUC/MIC %.0f [%.0f-%.0f] | PTA(Cmax>=8) %.0f%% PTA(AUC in band) %.0f%%\n",
      u$point, u$ci[1], u$ci[3],
      summ$F_point, summ$F_lo, summ$F_hi,
      summ$AUC_MIC_med, summ$AUC_MIC_lo, summ$AUC_MIC_hi,
      summ$PTA_Cmax8, summ$PTA_AUC80))
}

# frontier figure: F vs multiplier with CI band + molecule points
grid <- data.frame(mult = exp(seq(log(0.5), log(150), length.out = 300)))
grid$F96 <- F_of_mult(grid$mult)
pts <- do.call(rbind, lapply(names(molecules), function(mid) {
  s <- read.csv(file.path(OUT, sprintf("S09_uncertainty_summary_%s.csv", mid)))
  data.frame(molecule = mid, mult = s$mult_point, F96 = s$F_point,
             lo = s$mult_lo, hi = s$mult_hi, Flo = s$F_lo, Fhi = s$F_hi)
}))
p <- ggplot(grid, aes(mult, F96)) +
  geom_line(linewidth = 1.1, color = "#2c5f8a") +
  geom_errorbarh(data = pts, aes(xmin = lo, xmax = hi, y = F96), height = 2, color = "#c0392b") +
  geom_errorbar(data = pts, aes(ymin = Flo, ymax = Fhi, x = mult), width = 2, color = "#c0392b") +
  geom_point(data = pts, aes(mult, F96, fill = molecule), size = 3.4, shape = 21, color = "black") +
  geom_hline(yintercept = 80, linetype = "dashed", color = "grey40") +
  annotate("text", x = 1.2, y = 82, label = "F = 80 %", size = 3.2, color = "grey30") +
  scale_x_log10(breaks = c(1, 5, 20, 50, 100, 150)) +
  labs(title = "Attainability frontier with component uncertainty (S09)",
       subtitle = "F(96 h) vs apparent-permeability multiplier; red = CI95 propagated from cited factor sigmas",
       x = "Permeability multiplier (x, log scale)", y = "Oral bioavailability F (%), 96-h window") +
  theme_minimal(base_size = 12)
ggsave(file.path(OUT, "S09_frontier.png"), p, width = 8.5, height = 5.5, dpi = 200)
cat("S09 complete ->", OUT, "\n")
