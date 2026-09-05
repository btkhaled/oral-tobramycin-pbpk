# ============================================================================
# 01_create_compound.R — Définir le composé Tobramycine dans PK-Sim
# ============================================================================

source(file.path(SCRIPTS_DIR, "00_setup.R"))

# --- Créer le composé PK-Sim ------------------------------------------------

# Chemin vers le template Aciclovir (incluse dans ospsuite)
template_path <- system.file("extdata", "Aciclovir.pkml", package = "ospsuite")

# Charger le template
sim <- loadSimulation(template_path)

# --- Définir les paramètres de la tobramycine --------------------------------

# Paramètres physicochimiques
tobramycin_params <- list(
  name           = "Tobramycin",
  molecularWeight = 467.515,
  logP           = -2.9,
  pKa            = c(6.7, 7.6, 7.7, 7.8, 9.1),
  solubility     = 94,  # mg/mL
  fractionUnbound = 0.95
)

# --- Modifier le composé dans la simulation ----------------------------------

# Note: Dans PK-Sim, les paramètres sont définis via le GUI ou les building blocks.
# Ici, on prépare les paramètres pour utilisation dans les scripts suivants.

# Sauvegarder les paramètres pour usage ultérieur
compound_config <- list(
  name            = tobramycin_params$name,
  MW              = tobramycin_params$molecularWeight,
  logP            = tobramycin_params$logP,
  pKa             = tobramycin_params$pKa,
  solubility      = tobramycin_params$solubility,
  fu              = tobramycin_params$fractionUnbound,
  CL              = 5.5,    # L/h (référence)
  V1              = 17,     # L (référence)
  Q               = 2.4,    # L/h
  V2              = 16,     # L
  CLCR_ref        = 81,     # mL/min (normalise)
  CLCR_exponent   = 0.72,   # Power model
  oral_BA         = 0.015,  # 1.5% estimé
  BCS             = "III",
  absorption_model = "ACAT"
)

# Sauvegarder en JSON
jsonlite::write_json(
  compound_config,
  path       = file.path(RESULTS_DIR, "compound_config.json"),
  pretty     = TRUE,
  auto_unbox = TRUE
)

message("=== Composé Tobramycine configuré ===")
message("Nom: ", compound_config$name)
message("MW: ", compound_config$MW, " g/mol")
message("LogP: ", compound_config$logP)
message("BCS: ", compound_config$BCS)
message("F oral estimé: ", compound_config$oral_BA * 100, "%")
message("Config sauvegardée: ", file.path(RESULTS_DIR, "compound_config.json"))
