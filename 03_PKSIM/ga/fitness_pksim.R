# ============================================================================
# fitness_pksim.R — Batch-based PK-Sim fitness evaluation for the GA
# ----------------------------------------------------------------------------
# Efficiency pattern: for each generation, ALL candidate chromosomes are packed
# into ONE SimulationBatch (addRunValues per chromosome) and executed with a
# single runSimulationBatches call — one .NET round-trip per generation.
#
# Variable parameters (run values):
#   - Tobramycin|Specific intestinal permeability (transcellular)  [dm/min]
#   - Events|Tobramycin Oral Protocol|Oral Solution|Application_1|
#       ProtocolSchemaItem|Dose                                     [kg]
# Linear kinetics: one 24 h oral run per candidate.
# AUC reference (dose-normalized) from the validated IV run: 102.5 mg*h/L / 577.5 mg.
# ============================================================================

suppressMessages(library(ospsuite))

.GA_ROOT <- (function(){d<-getwd();for(i in 1:6){if(file.exists(file.path(d,"pksim/ga/config/ga_config.json")))return(normalizePath(d));d<-dirname(d)};stop("repo root not found")})()

ga_cfg <- jsonlite::fromJSON(file.path(.GA_ROOT, "pksim/ga/config/ga_config.json"))
bounds <- read.csv(file.path(.GA_ROOT, "pksim/ga/config/parameter_bounds.csv"))

# single source of truth for genes -> P_int (calibration anchors, cited
# component factors, uncertainty sampling): see enhancement_model.R / docs/07
source(file.path(.GA_ROOT, "pksim/ga/enhancement_model.R"))

MW            <- 467.515
MIC           <- 1
AUC_IV_PER_MG <- 102.5 / 577.5       # mg*h/L per mg (validated IV)

PINT_PATH <- "Tobramycin|Specific intestinal permeability (transcellular)"
DOSE_PATH <- "Events|Tobramycin Oral Protocol|Oral Solution|Application_1|ProtocolSchemaItem|Dose"
RATE_PATH <- "Organism|PeripheralVenousBlood|Tobramycin|Plasma (Peripheral Venous Blood)"

#' Create the evaluator (loads the model once)
create_evaluator <- function() {
  sim <- loadSimulation(file.path(.GA_ROOT, "pksim/model/tobramycin_oral.pkml"))
  setOutputInterval(simulation = sim, startTime = 0, endTime = 5760, resolution = 10)  # 96-h output
  function(chrom_matrix) {
    batch <- createSimulationBatch(sim, parametersOrPaths = c(PINT_PATH, DOSE_PATH))
    n <- nrow(chrom_matrix)
    for (i in seq_len(n)) {
      cand <- decode_chromosome(chrom_matrix[i, ])
      batch$addRunValues(c(cand$pint, cand$dose_mg / 1e6))   # dose base unit: kg
    }
    res <- runSimulationBatches(batch, silentMode = TRUE)[[1]]
    apply_chrom_results(res, n, sapply(seq_len(n), function(i)
      decode_chromosome(chrom_matrix[i, ])$dose_mg))
  }
}

# chromosome -> (Pint [dm/min], dose [mg]) — delegated to enhancement_model.R
# (decode_chromosome returns pint, dose_mg, mult, mult_logP_only, components)

# results (list per run) -> objective matrix [F, Cmax/MIC, AUC/MIC, dose]
apply_chrom_results <- function(res_list, n, doses) {
  out <- matrix(NA_real_, nrow = n, ncol = 4,
                dimnames = list(NULL, c("F", "Cmax_MIC", "AUC_MIC", "dose")))
  for (i in seq_len(n)) {
    r <- res_list[[i]]
    if (is.null(r)) next
    o  <- getOutputValues(r, quantitiesOrPaths = RATE_PATH)
    df <- as.data.frame(o$data)
    tt <- df$Time / 60; cc <- df[[RATE_PATH]] * MW / 1000
    k  <- tt <= 96     # 96-h window: F convention consistent with S02/S08 (docs/07)
    auc <- sum(diff(tt[k]) * (head(cc[k], -1) + tail(cc[k], -1)) / 2)
    out[i, "F"]        <- (auc / doses[i]) / AUC_IV_PER_MG * 100
    out[i, "Cmax_MIC"] <- max(cc[k]) / MIC
    out[i, "AUC_MIC"]  <- auc / MIC
    out[i, "dose"]     <- doses[i]
  }
  out
}
