# ============================================================================
# S05_food_effect.R — Fasted vs fed gastric emptying (BCS III: extent unchanged)
# Fed state: slower gastric emptying (Stomach transit 0.5 h -> 1.5 h).
# Outputs: results/studies/S05_food_effect.csv (+ png)
# ============================================================================
suppressMessages({library(ospsuite); library(ggplot2)})
PROJ <- (function(){d<-getwd();for(i in 1:6){if(file.exists(file.path(d,"pksim/env/pk_sim_run.R")))return(normalizePath(d));d<-dirname(d)};stop("root not found")})()

MW <- 467.515; MIC <- 1
sim <- loadSimulation(file.path(PROJ, "pksim", "model", "tobramycin_oral.pkml"))
PINT <- "Tobramycin|Specific intestinal permeability (transcellular)"
GT   <- "Organism|Lumen|Stomach|Gastric emptying time"
setParameterValues(getParameter(PINT, sim), 3e-9 * 20)
IV_REF_AUC_PER_MG <- 102.5 / 577.5

# Gastric emptying time base unit = MINUTES (default 15 min fasted).
# Fed state: 60 min (physiological postprandial delay).
run_state <- function(stomach_min) {
  setParameterValues(getParameter(GT, sim), stomach_min)
  r <- runSimulations(sim)[[1]]
  out <- getOutputValues(r)
  df <- as.data.frame(out$data)
  pl <- grep("Plasma .Peripheral", names(df), value = TRUE)[1]
  d2 <- df[df$Time <= 1440, ]; tt <- d2$Time / 60; cc <- d2[[pl]] * MW / 1000
  auc <- sum(diff(tt) * (head(cc, -1) + tail(cc, -1)) / 2)
  data.frame(state = ifelse(stomach_min <= 15, "fasted", "fed"),
             gastric_min = stomach_min, Cmax = max(cc),
             Tmax = tt[which.max(cc)], AUC24 = auc,
             F_pct = (auc / 550) / IV_REF_AUC_PER_MG * 100)
}
res <- rbind(run_state(15), run_state(60))
res$Cmax_MIC <- res$Cmax / MIC
write.csv(res, file.path(PROJ, "results", "studies", "S05_food_effect.csv"), row.names = FALSE)

p <- ggplot(res, aes(gastric_min, Tmax)) + geom_col(fill = "#005493") +
  labs(title = "Food effect — oral platform 550 mg (PK-Sim)",
       subtitle = "Fed delays Tmax; extent (AUC/F) unchanged — solubility never limiting (BCS III)",
       x = "Gastric emptying time (min)", y = "Tmax (h)")
ggsave(file.path(PROJ, "results", "studies", "S05_food_effect.png"), p,
       width = 7, height = 4.4, dpi = 300, bg = "white")
print(res)
cat("S05 done\n")
