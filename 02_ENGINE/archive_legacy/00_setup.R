# ============================================================================
# 00_setup.R — Configuration de l'environnement de travail
# Projet: Oral Tobramycin — PBPK Modeling
# ============================================================================

# --- Librairies --------------------------------------------------------------
library(ospsuite)      # PBPK modeling (Open Systems Pharmacology)
library(ggplot2)       # Visualisation
library(dplyr)         # Manipulation de données
library(tidyr)         # Reshaping data
library(readr)         # Import CSV
library(purrr)         # Fonctions fonctionnelles
library(stringr)       # Manipulation de strings
library(scales)        # Échelles pour graphiques

# --- Configuration globale ---------------------------------------------------
PROJECT_ROOT <- here::here()  # ou chemin manuel
DATA_DIR      <- file.path(PROJECT_ROOT, "02_COMPOUND_DATA")
SIM_DIR       <- file.path(PROJECT_ROOT, "03_PBPK_MODELING")
RESULTS_DIR   <- file.path(SIM_DIR, "results")
SCRIPTS_DIR   <- file.path(SIM_DIR, "scripts")
FIGURES_DIR   <- file.path(RESULTS_DIR, "figures")

# Créer les dossiers de sortie si nécessaire
dir.create(RESULTS_DIR,   showWarnings = FALSE, recursive = TRUE)
dir.create(FIGURES_DIR,   showWarnings = FALSE, recursive = TRUE)

# --- Paramètres de simulation ------------------------------------------------
SIM_OPTIONS <- list(
  numberOfCores      = parallel::detectCores() - 1,
  showProgressBar    = TRUE,
  checkInputs        = TRUE,
  resetSeedOnRun     = TRUE
)

# --- Thème graphique ---------------------------------------------------------
THEME_PLOT <- theme_minimal(base_size = 12) +
  theme(
    legend.position  = "bottom",
    strip.text       = element_text(face = "bold"),
    plot.title       = element_text(hjust = 0.5, face = "bold")
  )

theme_set(THEME_PLOT)

# --- Fonctions utilitaires ---------------------------------------------------

#' Charger une simulation PK-Sim
load_sim <- function(pkml_file) {
  sim <- loadSimulation(pkml_file)
  message("Simulation chargée: ", sim$name)
  return(sim)
}

#' Lancer une simulation et retourner les résultats
run_sim <- function(sim) {
  results <- runSimulations(simulations = sim, simulationOptions = do.call(SimulationRunOptions$new, SIM_OPTIONS))
  return(results[[1]])
}

#' Extraire les concentrations plasmatiques
get_plasma_conc <- function(sim_results, mol = NULL) {
  if (is.null(mol)) {
    # Chercher la première molécule disponible
    mol <- getMoleculeNamesFromResults(sim_results)[1]
  }
  df <- as.data.frame(getOutputValues(simResults = sim_results, molecule = mol))
  return(df)
}

#' Calculer les paramètres PK à partir des données de concentration
calc_pk <- function(conc_df, time_col = "Time", conc_col = "Concentration") {
  time <- conc_df[[time_col]]
  conc <- conc_df[[conc_col]]

  # Cmax et Tmax
  idx_max <- which.max(conc)
  cmax <- conc[idx_max]
  tmax <- time[idx_max]

  # AUC par la règle du trapèze
  auc <- sum(diff(time) * (head(conc, -1) + tail(conc, -1)) / 2)

  # Demi-vie (estimation par régression log-linéaire sur la phase terminale)
  n_terminal <- max(3, length(conc) %/% 3)
  terminal_idx <- tail(seq_along(conc), n_terminal)
  if (length(terminal_idx) >= 2 && all(conc[terminal_idx] > 0)) {
    log_conc <- log(conc[terminal_idx])
    time_term <- time[terminal_idx]
    fit <- lm(log_conc ~ time_term)
    half_life <- -log(2) / coef(fit)[2]
  } else {
    half_life <- NA_real_
  }

  tibble::tibble(
    Cmax   = cmax,
    Tmax   = tmax,
    AUC    = auc,
    t_half = half_life
  )
}

#' Sauvegarder un graphique
save_plot <- function(p, filename, width = 8, height = 6) {
  ggsave(
    filename = file.path(FIGURES_DIR, filename),
    plot     = p,
    width    = width,
    height   = height,
    dpi      = 300
  )
  message("Graphique sauvegardé: ", filename)
}

# --- Chargement du composé ---------------------------------------------------
COMPOUND_FILE <- file.path(DATA_DIR, "physicochemical", "molecular_properties.json")
COMPOUND <- jsonlite::fromJSON(COMPOUND_FILE)

message("=== Environnement configuré ===")
message("Projet: ", PROJECT_ROOT)
message("Composé: ", COMPOUND$compound_name)
message("BCS Class: ", COMPOUND$classification$bcs_class)
message("Cores: ", SIM_OPTIONS$numberOfCores)
