# ============================================================================
# 00_ga_setup.R — Configuration du Genetic Algorithm
# Projet: Optimization de formulations orales de tobramycine
# Objectif: Top 10 formulations viables (BCS III → oral)
# ============================================================================

# --- Librairies --------------------------------------------------------------
library(GA)           # Genetic Algorithm (sequential or parallel)
library(ggplot2)      # Visualisation
library(dplyr)        # Manipulation
library(tidyr)        # Reshaping
library(readr)        # Import CSV
library(purrr)        # Fonctions fonctionnelles
library(patchwork)    # Combiner ggplots
library(viridis)      # Couleurs
library(scales)       # Échelles
library(jsonlite)     # JSON I/O
library(parallel)     # Parallel computing
library(doParallel)   # Parallel backend

# --- Configuration du projet --------------------------------------------------
# --- Configurer les chemins si pas déjà définis --------------------------------
if (!exists("PROJECT_ROOT")) {
  this_file <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
  if (is.null(this_file) || !nzchar(this_file)) {
    ca <- commandArgs(trailingOnly = FALSE)
    f <- ca[grep("--file=", ca)]
    if (length(f) > 0) this_file <- sub("--file=", "", f[1])
  }
  if (!is.null(this_file) && nzchar(this_file) && file.exists(this_file)) {
    PROJECT_ROOT <- normalizePath(file.path(dirname(normalizePath(this_file)), "../.."), mustWork = FALSE)
  } else {
    PROJECT_ROOT <- normalizePath(getwd(), mustWork = FALSE)
    for (i in 1:6) {
      if (dir.exists(file.path(PROJECT_ROOT, "02_ENGINE")) && dir.exists(file.path(PROJECT_ROOT, "03_PKSIM"))) break
      PROJECT_ROOT <- dirname(PROJECT_ROOT)
    }
  }
}
GA_DIR       <- file.path(PROJECT_ROOT, "02_ENGINE")
ENGINE_OUT   <- Sys.getenv("ENGINE_OUT", unset = "")
if (nzchar(ENGINE_OUT)) {
  RESULTS_DIR <- normalizePath(ENGINE_OUT, mustWork = FALSE)
} else {
  RESULTS_DIR <- file.path(GA_DIR, "results_legacy")
}
CONFIG_DIR   <- file.path(GA_DIR, "config")
SCRIPTS_DIR  <- file.path(GA_DIR, "scripts")

dir.create(RESULTS_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(CONFIG_DIR,  showWarnings = FALSE, recursive = TRUE)

# --- Paramètres physiologiques de référence -----------------------------------
PHYSIO <- list(
  Vd         = 17,       # L (volume de distribution central)
  CL         = 5.5,      # L/h (clearance)
  t_half     = 2.5,      # h
  Ke         = log(2) / 2.5,  # 0.277 h⁻¹ (taux d'élimination)
  Ka_ref     = 1.5,      # h⁻¹ (taux d'absorption de référence)
  BW         = 70,       # kg
  Dose_ref   = 400,      # mg
  MIC        = 1,        # µg/mL (MIC P. aeruginosa)
  CLCR_ref   = 81        # mL/min (normalisé)
)

# --- Bornes des paramètres de formulation (Gènes) ----------------------------
PARAM_BOUNDS <- tibble(
  gene_id     = 1:10,
  name        = c(
    "logP_modified",        # 1: LogP après HIP (-2.9 à +1.6, cap measured HIP; see 03_PKSIM/docs/07)
    "particle_size",        # 2: Taille particule (50-500 nm)
    "surfactant_pct",       # 3: Ratio surfactant SEDDS (10-60%)
    "cosurfactant_pct",     # 4: Ratio co-surfactant (5-30%)
    "oil_pct",              # 5: Phase huileuse (20-70%)
    "pe_concentration",     # 6: Permeation enhancer C10 (0-50 mM)
    "polymer_loading",      # 7: Charge polymère NPs (0-30%)
    "chitosan_coating",     # 8: Enrobage chitosane (0 ou 1)
    "enteric_coating",      # 9: Enrobage entérique (0 ou 1)
    "dose_mg"               # 10: Dose (200-1000 mg)
  ),
  min_val     = c(-2.9, 50, 10, 5, 20, 0, 0, 0, 0, 200),
  max_val     = c(1.6, 500, 60, 30, 70, 50, 30, 1, 1, 1000),  # 1.6 = measured HIP (Asad2023), cap ×126.3; legacy 3.0 was artefact ×313
  type        = c("continuous", "continuous", "continuous", "continuous",
                  "continuous", "continuous", "continuous", "binary", "binary",
                  "continuous")
)

# --- Poids de la fonction objectif --------------------------------------------
OBJ_WEIGHTS <- list(
  w_F       = 0.40,    # Bioavailability
  w_CmaxMIC = 0.25,    # Cmax/MIC target
  w_AUCMIC  = 0.25,    # AUC/MIC target
  w_safety  = 0.10     # Toxicity penalty
)

# --- Paramètres du GA ---------------------------------------------------------
GA_CONFIG <- list(
  popSize       = 100,      # Taille population
  maxiter       = 200,      # Max générations
  run           = 20,       # Arrêt si stable 20 générations
  crossoverRate = 0.8,      # Taux croisement
  mutationRate  = 0.1,      # Taux mutation
  pcrossover    = 0.8,      # Probabilité croisement
  pmutation     = 0.1,      # Probabilité mutation
  elitism       = 10,       # Individus élitistes préservés
  seed          = 42,       # Reproductibilité
  parallel      = TRUE,     # Calcul parallèle
  n_cores       = max(1, parallel::detectCores() - 1)
)

# Optional overrides from run_engine.R (English CLI: --pop / --gen) — after GA_CONFIG is defined
ENGINE_POP <- Sys.getenv("ENGINE_POP", unset = "")
ENGINE_GEN <- Sys.getenv("ENGINE_GEN", unset = "")
if (nzchar(ENGINE_POP)) {
  GA_CONFIG$popSize <- as.integer(ENGINE_POP)
  message("Override GA popSize -> ", GA_CONFIG$popSize, " (via --pop)")
}
if (nzchar(ENGINE_GEN)) {
  GA_CONFIG$maxiter <- as.integer(ENGINE_GEN)
  message("Override GA maxiter -> ", GA_CONFIG$maxiter, " (via --gen)")
}

# --- Thème graphique ---------------------------------------------------------
THEME_GA <- theme_minimal(base_size = 12) +
  theme(
    legend.position  = "bottom",
    strip.text       = element_text(face = "bold"),
    plot.title       = element_text(hjust = 0.5, face = "bold"),
    panel.grid.minor = element_blank()
  )

theme_set(THEME_GA)

# --- Sauvegarder la configuration --------------------------------------------
config <- list(
  physio      = PHYSIO,
  params      = as.list(PARAM_BOUNDS),
  weights     = OBJ_WEIGHTS,
  ga          = GA_CONFIG
)

write_json(config, file.path(CONFIG_DIR, "ga_config.json"), pretty = TRUE, auto_unbox = TRUE)
write_csv(PARAM_BOUNDS, file.path(CONFIG_DIR, "parameter_bounds.csv"))

message("=== Configuration GA initialisée ===")
message("Population: ", GA_CONFIG$popSize)
message("Max générations: ", GA_CONFIG$maxiter)
message("Paramètres: ", nrow(PARAM_BOUNDS))
message("Config: ", file.path(CONFIG_DIR, "ga_config.json"))
