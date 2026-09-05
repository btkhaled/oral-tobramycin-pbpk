# ============================================================================
# S03_population.R — Virtual population trial (PK-Sim native population)
# ----------------------------------------------------------------------------
# 100 virtual adults (ICRP 2002, 20-50 y, 55-95 kg, 60% male) receiving the
# optimized oral platform: 550 mg once daily, P_int = 20x baseline (HIP+SEDDS+PE
# platform, calibrated F ~ 34%). PK-Sim population simulation.
# Outputs: results/S03_population.csv, S03_population.png
# ============================================================================
suppressMessages({library(ospsuite); library(ggplot2)})
PROJ <- (function(){d<-getwd();for(i in 1:6){if(file.exists(file.path(d,"pksim/env/pk_sim_run.R")))return(normalizePath(d));d<-dirname(d)};stop("root not found")})()

PINT0 <- 3e-9          # dm/min, calibrated baseline (F0 ~ 1.75%)
PLATFORM_MULT <- 20    # optimized platform (thesis Ch. 4)
MW <- 467.515; MIC <- 1

pch <- createPopulationCharacteristics(
  species = "Human", population = "European_ICRP_2002",
  proportionOfFemales = 40, ageMin = 20, ageMax = 50,
  weightMin = 55, weightMax = 95, numberOfIndividuals = 100
)
pop <- createPopulation(populationCharacteristics = pch)

sim <- loadSimulation(file.path(PROJ, "pksim", "model", "tobramycin_oral.pkml"))
Pint <- "Tobramycin|Specific intestinal permeability (transcellular)"
# platform permeability (single global override; population variability comes
# from anatomy/physiology via the population building block)
setParameterValues(getParameter(Pint, sim), PINT0 * PLATFORM_MULT)

cat("Running 100-individual population simulation (PK-Sim native)...\n")
res <- runSimulations(sim, population = pop)
pl <- "Organism|PeripheralVenousBlood|Tobramycin|Plasma (Peripheral Venous Blood)"
out <- getOutputValues(res[[1]], quantitiesOrPaths = pl)
df <- as.data.frame(out$data)

ids <- unique(df$IndividualId)
rows <- list()
for (id in ids) {
  d2 <- df[df$IndividualId == id & df$Time <= 1440, ]
  tt <- d2$Time / 60; cc <- d2[[pl]] * MW / 1000
  auc <- sum(diff(tt) * (head(cc, -1) + tail(cc, -1)) / 2)
  rows[[length(rows) + 1]] <- data.frame(
    IndividualId = id, Cmax = max(cc), AUC24 = auc,
    Ctrough = cc[which.min(abs(tt - 24))],
    fT_MIC = 100 * sum(cc >= MIC) / length(cc))
}
popres <- do.call(rbind, rows)
popres$Cmax_MIC <- popres$Cmax / MIC
popres$AUC_MIC  <- popres$AUC24 / MIC
write.csv(popres, file.path(PROJ, "results", "studies", "S03_population.csv"), row.names = FALSE)

summ <- data.frame(
  metric = c("Cmax (mg/L)", "Cmax/MIC", "AUC24 (mg*h/L)", "Ctrough (mg/L)", "fT>MIC (%)"),
  median = round(c(median(popres$Cmax), median(popres$Cmax_MIC), median(popres$AUC24),
                   median(popres$Ctrough), median(popres$fT_MIC)), 3),
  p5  = round(sapply(popres[, c("Cmax", "Cmax_MIC", "AUC24", "Ctrough", "fT_MIC")],
                     quantile, 0.05), 3),
  p95 = round(sapply(popres[, c("Cmax", "Cmax_MIC", "AUC24", "Ctrough", "fT_MIC")],
                     quantile, 0.95), 3)
)
write.csv(summ, file.path(PROJ, "results", "studies", "S03_population_summary.csv"), row.names = FALSE)
print(summ)

p1 <- ggplot(popres, aes(Cmax_MIC)) +
  geom_histogram(bins = 25, fill = "#005493", color = "white") +
  geom_vline(xintercept = 8, linetype = 2, color = "firebrick") +
  labs(title = "Virtual population (n=100) — Cmax/MIC after 550 mg oral platform",
       subtitle = sprintf("Target attainment Cmax/MIC >= 8: %.0f%% of subjects",
                          100 * mean(popres$Cmax_MIC >= 8)),
       x = "Cmax/MIC", y = "Subjects")
ggsave(file.path(PROJ, "results", "studies", "S03_population.png"), p1, width = 7.5, height = 4.8, dpi = 300, bg = "white")
cat("S03 done\n")
