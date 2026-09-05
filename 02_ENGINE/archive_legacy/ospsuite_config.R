# ============================================================================
# ospsuite_config.R — Configuration ospsuite
# ============================================================================

# Ce fichier configure les options globales pour ospsuite.

# --- Vérification de l'installation -------------------------------------------
check_ospsuite <- function() {
  required_packages <- c("ospsuite", "ggplot2", "dplyr", "readr")

  installed <- installed.packages()[, "Package"]
  missing   <- setdiff(required_packages, installed)

  if (length(missing) > 0) {
    message("Packages manquants: ", paste(missing, collapse = ", "))
    message("Installation...")
    install.packages(missing)
  }

  # Vérifier ospsuite
  if (!requireNamespace("ospsuite", quietly = TRUE)) {
    stop("ospsuite non installé. Exécutez: install.packages('ospsuite')")
  }

  message("✓ Tous les packages sont installés")
}

# --- Options de simulation ----------------------------------------------------
get_simulation_options <- function() {
  list(
    numberOfCores    = max(1, parallel::detectCores() - 1),
    showProgressBar  = TRUE,
    checkInputs      = TRUE,
    resetSeedOnRun   = TRUE
  )
}

# --- Thème par défaut ---------------------------------------------------------
get_default_theme <- function() {
  theme_minimal(base_size = 12) +
    theme(
      legend.position  = "bottom",
      strip.text       = element_text(face = "bold"),
      plot.title       = element_text(hjust = 0.5, face = "bold"),
      axis.text.x      = element_text(angle = 45, hjust = 1)
    )
}

# --- Exécuter la vérification -------------------------------------------------
check_ospsuite()

message("=== Configuration ospsuite ===")
message("Cores: ", get_simulation_options()$numberOfCores)
