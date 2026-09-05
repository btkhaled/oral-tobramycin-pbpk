# ============================================================================
# 01_ga_objective_function.R — Fonction objectif multi-critères
# Évalue la qualité d'une formulation de tobramycine orale
# ============================================================================

source(file.path(SCRIPTS_DIR, "00_ga_setup.R"))

#' Calculer la pharmacocinétique simplifiée (modèle à 1 compartiment)
#'
#' @param F_oral Bioavailability (fraction, 0-1)
#' @param dose Dose en mg
#' @param Ka Taux d'absorption (h⁻¹)
#' @param Ke Taux d'élimination (h⁻¹)
#' @param Vd Volume de distribution (L)
#' @param t_max_hours Durée simulation (h)
#' @return Tibble avec temps et concentrations
calc_pk_analytical <- function(F_oral, dose, Ka, Ke, Vd, t_max_hours = 24) {
  # Modèle à 1 compartiment, absorption de premier ordre
  # C(t) = (F * Dose * Ka) / (Vd * (Ka - Ke)) * (exp(-Ke*t) - exp(-Ka*t))

  if (Ka <= Ke) Ka <- Ke + 0.01  # Éviter division par zéro

  time <- seq(0, t_max_hours, by = 0.1)
  conc <- (F_oral * dose * Ka) / (Vd * (Ka - Ke)) * (exp(-Ke * time) - exp(-Ka * time))
  conc[conc < 0] <- 0

  tibble(Time = time, Concentration = conc)
}

#' Calculer les paramètres PK à partir du profil concentration-temps
#'
#' @param pk_data Tibble avec colonnes Time et Concentration
#' @return Liste avec Cmax, Tmax, AUC, t_half, Ctrough
extract_pk_params <- function(pk_data) {
  conc <- pk_data$Concentration
  time <- pk_data$Time

  # Cmax et Tmax
  idx_max <- which.max(conc)
  cmax <- conc[idx_max]
  tmax <- time[idx_max]

  # AUC (règle du trapèze)
  auc <- sum(diff(time) * (head(conc, -1) + tail(conc, -1)) / 2)

  # Demi-vie (phase terminale)
  n_term <- max(3, floor(length(conc) * 0.3))
  term_idx <- tail(seq_along(conc), n_term)
  if (length(term_idx) >= 2 && all(conc[term_idx] > 1e-10)) {
    log_c <- log(conc[term_idx])
    t_term <- time[term_idx]
    fit <- lm(log_c ~ t_term)
    half_life <- -log(2) / coef(fit)[2]
    if (half_life < 0 || is.na(half_life) || half_life > 50) half_life <- PHYSIO$t_half
  } else {
    half_life <- PHYSIO$t_half
  }

  # Ctrough (dernière valeur)
  ctrough <- tail(conc, 1)

  list(
    Cmax   = cmax,
    Tmax   = tmax,
    AUC    = auc,
    t_half = half_life,
    Ctrough = ctrough
  )
}

#' Calculer la bioavailability estimée
#'
#' @param logP LogP modifié (après HIP)
#' @param particle_size Taille particule (nm)
#' @param surfactant_pct Ratio surfactant (%)
#' @param cosurfactant_pct Ratio co-surfactant (%)
#' @param oil_pct Phase huileuse (%)
#' @param pe_conc Concentration PE (mM)
#' @param polymer_pct Charge polymère (%)
#' @param chitosan Enrobage chitosane (0/1)
#' @param enteric Enrobage entérique (0/1)
#' @return F estimée (fraction 0-1)
estimate_bioavailability <- function(logP, particle_size, surfactant_pct,
                                     cosurfactant_pct, oil_pct, pe_conc,
                                     polymer_pct, chitosan, enteric) {
  # --- Modèle de perméabilité -----------------------------------------------
  # La perméabilité dépend du LogP (optimal autour de 1-3 pour BCS III)
  # et des enhanceurs

  # Enhancement factor dû au LogP (HIP)
  # LogP optimal ~ 1-2 pour perméabilité transcellulaire
  logP_optimal <- 1.5
  logP_factor <- exp(-0.5 * ((logP - logP_optimal) / 2)^2)  # Gaussian centered
  logP_factor <- max(logP_factor, 0.1)  # Minimum 10% of base

  # Enhancement factor dû au PE (C10)
  # C10 augmente la perméabilité paracellulaire
  # Dose-response: max enhancement ~ 5× à 30 mM, plateau
  pe_factor <- 1 + 4 * (1 - exp(-pe_conc / 15))  # 1× → 5×

  # Enhancement factor dû aux NPs (mucoadhesion)
  # Les NPs augmentent le temps de résidence
  np_factor <- 1 + polymer_pct / 30 * 0.5  # max +50%

  # Enhancement dû au chitosane (tight junctions)
  chitosan_factor <- 1 + chitosan * 0.3  # +30%

  # Facteur SEDDS (émulsification améliore la dissolution)
  sedds_factor <- 1 + (surfactant_pct + cosurfactant_pct) / 100 * 0.4  # max +40%

  # Facteur enrobage entérique (protection gastrique)
  enteric_factor <- 1 + enteric * 0.2  # +20% (protection pH)

  # Facteur taille particule (plus petit = mieux)
  size_factor <- 1 + (500 - particle_size) / 500 * 0.3  # max +30%

  # --- Bioavailability de base (native) -------------------------------------
  F_base <- 0.015  # 1.5% (tobramycine native)

  # --- Multiplication des facteurs ------------------------------------------
  F_estimated <- F_base * logP_factor * pe_factor * np_factor *
                 chitosan_factor * sedds_factor * enteric_factor * size_factor

  # Plafond physique (ne peut pas dépasser ~60% pour un composé BCS III)
  F_estimated <- min(F_estimated, 0.60)
  F_estimated <- max(F_estimated, 0.001)

  return(F_estimated)
}

#' Estimer le Ka (taux d'absorption)
#'
#' @param particle_size Taille particule (nm)
#' @param surfactant_pct Surfactant (%)
#' @param pe_conc PE concentration (mM)
#' @param enteric Enrobage entérique (0/1)
#' @return Ka estimé (h⁻¹)
estimate_Ka <- function(particle_size, surfactant_pct, pe_conc, enteric) {
  # Ka de base
  Ka_base <- 1.0  # h⁻¹

  # Effet taille particule (plus petit = plus rapide)
  size_effect <- 1 + (500 - particle_size) / 500 * 0.8

  # Effet surfactant (augmente mouillabilité)
  sedds_effect <- 1 + surfactant_pct / 100 * 0.5

  # Effet PE (augmente le contact muqueux)
  pe_effect <- 1 + pe_conc / 50 * 0.3

  # Effet entérique (retard mais pas nécessairement Ka)
  enteric_effect <- 1 - enteric * 0.2  # Légère réduction

  Ka_estimated <- Ka_base * size_effect * sedds_effect * pe_effect * enteric_effect

  # Bornes réalistes
  Ka_estimated <- max(Ka_estimated, 0.3)
  Ka_estimated <- min(Ka_estimated, 5.0)

  return(Ka_estimated)
}

#' Fonction objectif complète (fitness)
#'
#' @param individual Vecteur de 10 gènes
#' @param return_details Retourner les détails (TRUE pour debug)
#' @return Score de fitness (plus grand = meilleur)
objective_function <- function(individual, return_details = FALSE) {
  # --- Décoder les gènes -----------------------------------------------------
  logP          <- individual[1]
  particle_size <- individual[2]
  surfactant    <- individual[3]
  cosurfactant  <- individual[4]
  oil           <- individual[5]
  pe_conc       <- individual[6]
  polymer       <- individual[7]
  chitosan      <- round(individual[8])  # Binaire
  enteric       <- round(individual[9])  # Binaire
  dose          <- individual[10]

  # --- Vérifier les contraintes de formulation -------------------------------
  # La somme SEDDS (surfactant + cosurfactant + oil) ne doit pas dépasser 100%
  sedds_total <- surfactant + cosurfactant + oil
  if (sedds_total > 100) {
    return(-1000)  # Pénalité pour formulation invalide
  }

  # --- Estimer les paramètres PK ---------------------------------------------
  F_est <- estimate_bioavailability(
    logP, particle_size, surfactant, cosurfactant,
    oil, pe_conc, polymer, chitosan, enteric
  )

  Ka <- estimate_Ka(particle_size, surfactant, pe_conc, enteric)
  Ke <- PHYSIO$Ke

  # --- Simuler le profil PK --------------------------------------------------
  pk_data <- calc_pk_analytical(F_est, dose, Ka, Ke, PHYSIO$Vd)
  pk <- extract_pk_params(pk_data)

  # --- Calculer les scores PD ------------------------------------------------
  Cmax_MIC <- pk$Cmax / PHYSIO$MIC
  AUC_MIC  <- pk$AUC / PHYSIO$MIC

  # --- Score bioavailability (0-1) -------------------------------------------
  # Normaliser F: 0% → 0, 60% → 1
  score_F <- F_est / 0.60

  # --- Score Cmax/MIC (objectif ≥ 8) ----------------------------------------
  if (Cmax_MIC >= 8) {
    score_CmaxMIC <- 1.0
  } else {
    score_CmaxMIC <- Cmax_MIC / 8  # Pénalité linéaire
  }

  # --- Score AUC/MIC (objectif ≥ 80) ----------------------------------------
  if (AUC_MIC >= 80) {
    score_AUCMIC <- 1.0
  } else {
    score_AUCMIC <- AUC_MIC / 80  # Pénalité linéaire
  }

  # --- Pénalité toxicité -----------------------------------------------------
  penalty <- 0
  if (pk$Cmax > 30) penalty <- penalty + (pk$Cmax - 30) / 30  # Cmax > 30 mg/L
  if (pk$Ctrough > 1) penalty <- penalty + (pk$Ctrough - 1)    # Trough > 1 mg/L

  # --- Fitness composite -----------------------------------------------------
  w <- OBJ_WEIGHTS
  fitness <- w$w_F * score_F +
             w$w_CmaxMIC * score_CmaxMIC +
             w$w_AUCMIC * score_AUCMIC -
             w$w_safety * penalty

  # Pénalité pour formulation irréaliste
  if (F_est < 0.02) fitness <- fitness - 0.5  # F < 2% = pas viable

  # --- Retour ----------------------------------------------------------------
  if (return_details) {
    return(list(
      fitness       = fitness,
      F_oral        = F_est,
      Ka            = Ka,
      Cmax          = pk$Cmax,
      Tmax          = pk$Tmax,
      AUC           = pk$AUC,
      t_half        = pk$t_half,
      Ctrough       = pk$Ctrough,
      Cmax_MIC      = Cmax_MIC,
      AUC_MIC       = AUC_MIC,
      penalty       = penalty,
      score_F       = score_F,
      score_CmaxMIC = score_CmaxMIC,
      score_AUCMIC  = score_AUCMIC,
      pk_data       = pk_data,
      formulation   = tibble(
        logP = logP, particle_size = particle_size,
        surfactant = surfactant, cosurfactant = cosurfactant,
        oil = oil, pe_conc = pe_conc, polymer = polymer,
        chitosan = chitosan, enteric = enteric, dose = dose
      )
    ))
  }

  return(fitness)
}

#' Wrapper pour le GA (reçoit une matrice d'individus)
#' @param pop Matrice n × 10
#' @return Vecteur de fitness
evaluate_population <- function(pop) {
  apply(pop, 1, objective_function)
}

message("=== Fonction objectif définie ===")
message("Cibles: Cmax/MIC ≥ 8, AUC/MIC ≥ 80, F maximale")
message("Poids: F=", OBJ_WEIGHTS$w_F, " Cmax/MIC=", OBJ_WEIGHTS$w_CmaxMIC,
        " AUC/MIC=", OBJ_WEIGHTS$w_AUCMIC, " Safety=", OBJ_WEIGHTS$w_safety)
