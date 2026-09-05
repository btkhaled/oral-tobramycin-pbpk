# ============================================================================
# S04_sensitivity.R — Local sensitivity (elasticity) via PK-Sim batch runs
# ----------------------------------------------------------------------------
# NOTE: the {ospsuite} SensitivityAnalysis task computes sensitivities of the
# PK parameters attached to each output; the CLI-exported simulation carries
# no attached PK parameters, so we use the equivalent and fully PK-Sim-computed
# one-at-a-time perturbation design: each parameter is scaled by {0.8, 1.2}
# and elasticities of Cmax and AUC24 are computed as
#     E = (Δmetric/metric) / (Δparam/param)
# Endpoints: platform oral run (P_int = 20x baseline).
# Outputs: results/studies/S04_sensitivity.csv (+ png)
# ============================================================================
suppressMessages({library(ospsuite); library(ggplot2)})
PROJ <- (function(){d<-getwd();for(i in 1:6){if(file.exists(file.path(d,"pksim/env/pk_sim_run.R")))return(normalizePath(d));d<-dirname(d)};stop("root not found")})()

MW <- 467.515; MIC <- 1
sim <- loadSimulation(file.path(PROJ, "pksim", "model", "tobramycin_oral.pkml"))
PINT <- "Tobramycin|Specific intestinal permeability (transcellular)"
P_DOSE <- "Events|Tobramycin Oral Protocol|Oral Solution|Application_1|ProtocolSchemaItem|Dose"
P_GFR  <- "Organism|Kidney|GFR (specific)"
P_FU   <- "Tobramycin|Fraction unbound (plasma)"

params <- list(
  "P_int (x20 platform)"     = list(path = PINT,   base = 3e-9 * 20),
  "Dose (550 mg)"            = list(path = P_DOSE, base = 550 / 1e6),
  "GFR (specific)"           = list(path = P_GFR,  base = 0.266),
  "Fraction unbound"         = list(path = P_FU,   base = 0.95)
)

run_metrics <- function() {
  r <- runSimulations(sim)[[1]]
  out <- getOutputValues(r)
  df <- as.data.frame(out$data)
  pl <- grep("Plasma .Peripheral", names(df), value = TRUE)[1]
  d2 <- df[df$Time <= 1440, ]; tt <- d2$Time / 60; cc <- d2[[pl]] * MW / 1000
  auc <- sum(diff(tt) * (head(cc, -1) + tail(cc, -1)) / 2)
  c(Cmax = max(cc), AUC = auc)
}

# platform permeability (x20 baseline)
set_par <- function(p, v) setParameterValues(getParameter(p, sim), v)
set_par(PINT, 3e-9 * 20)
# baseline (all parameters at nominal)
base <- run_metrics()
cat(sprintf("baseline: Cmax=%.3f  AUC=%.3f\n", base[["Cmax"]], base[["AUC"]]))

get_par <- function(p) getParameter(p, sim)

rows <- list()
for (nm in names(params)) {
  p <- params[[nm]]
  orig <- get_par(p$path)$value
  for (delta in c(0.8, 1.2)) {
    set_par(p$path, p$base * delta)
    m <- run_metrics()
    rows[[length(rows) + 1]] <- data.frame(
      parameter = nm, delta = delta,
      Cmax = m[["Cmax"]], AUC = m[["AUC"]],
      elasticity_Cmax = ((m[["Cmax"]] - base[["Cmax"]]) / base[["Cmax"]]) / (delta - 1),
      elasticity_AUC  = ((m[["AUC"]]  - base[["AUC"]])  / base[["AUC"]])  / (delta - 1))
    set_par(p$path, orig)   # restore
  }
}
res <- do.call(rbind, rows)
write.csv(res, file.path(PROJ, "results", "studies", "S04_sensitivity_raw.csv"), row.names = FALSE)

elastic <- do.call(rbind, lapply(names(params), function(nm) {
  r2 <- res[res$parameter == nm, ]
  data.frame(parameter = nm,
             elasticity_Cmax = mean(r2$elasticity_Cmax),
             elasticity_AUC  = mean(r2$elasticity_AUC))
}))
write.csv(elastic, file.path(PROJ, "results", "studies", "S04_sensitivity.csv"), row.names = FALSE)
print(elastic)

el <- tidyr::pivot_longer(elastic, cols = c(elasticity_Cmax, elasticity_AUC),
                          names_to = "metric", values_to = "elasticity")
p <- ggplot(el, aes(reorder(parameter, abs(elasticity)), elasticity, fill = metric)) +
  geom_col(position = "dodge") + coord_flip() +
  labs(title = "Local sensitivity (elasticity) — platform oral 550 mg",
       subtitle = "E = 1: proportional; E < 0: inverse. Batch runs on the PK-Sim engine.",
       x = NULL, y = "Elasticity (Cmax / AUC24)", fill = "Endpoint") + theme(legend.position = "bottom")
ggsave(file.path(PROJ, "results", "studies", "S04_sensitivity.png"), p,
       width = 8, height = 4.6, dpi = 300, bg = "white")
cat("S04 done\n")
