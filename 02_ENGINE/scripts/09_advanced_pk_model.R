# ============================================================================
# 09_advanced_pk_model.R — Modèle PK/PD avancé 2-compartiments
# Transit + Absorption + Effet + Hill equation
# ============================================================================

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
if (!exists("SCRIPTS_DIR")) {
  GA_DIR      <- file.path(PROJECT_ROOT, "02_ENGINE")
  RESULTS_DIR <- file.path(GA_DIR, "results_legacy")
  CONFIG_DIR  <- file.path(GA_DIR, "config")
  SCRIPTS_DIR <- file.path(GA_DIR, "scripts")
}

source(file.path(SCRIPTS_DIR, "00_ga_setup.R"), local = FALSE)

# --- Modèle 2-compartiments avec transit --------------------------------------
# dAdt[1] = -Ka * A[1]                           (GI → sang)
# dAdt[2] = Ka * A[1] - (CL+Q)*C2 + Q*C3         (sang central)
# dAdt[3] = Q*C2 - Q*C3                           (sang périphérique)
# A[1] = dose*F dans le GI (ajout transit)

solve_pk_2comp <- function(dose_mg, F_oral, Ka, CL, V1, Q, V2,
                           k_transit = 2.0, t_end = 24, dt = 0.05) {
  # k_transit: taux de transit GI (retard d'absorption)
  # Simulation Runge-Kutta 4

  times <- seq(0, t_end, by = dt)
  n <- length(times)

  # État initial: [GI, Central, Peripheral]
  A <- matrix(0, nrow = n, ncol = 3)
  A[1, 1] <- dose_mg * F_oral  # Dose dans le GI

  for (i in 1:(n - 1)) {
    A_curr <- A[i, ]
    t_curr <- times[i]

    # RK4
    k1 <- pk_derivatives(A_curr, Ka, CL, V1, Q, V2, k_transit)
    k2 <- pk_derivatives(A_curr + 0.5 * dt * k1, Ka, CL, V1, Q, V2, k_transit)
    k3 <- pk_derivatives(A_curr + 0.5 * dt * k2, Ka, CL, V1, Q, V2, k_transit)
    k4 <- pk_derivatives(A_curr + dt * k3, Ka, CL, V1, Q, V2, k_transit)

    A[i + 1, ] <- A_curr + (dt / 6) * (k1 + 2 * k2 + 2 * k3 + k4)

    # Assurer positivité
    A[i + 1, ] <- pmax(A[i + 1, ], 0)
  }

  # Concentrations
  C_central <- A[, 2] / V1

  tibble(
    Time = times,
    Conc_Central = C_central,
    A_GI = A[, 1],
    A_Central = A[, 2],
    A_Peripheral = A[, 3]
  )
}

pk_derivatives <- function(A, Ka, CL, V1, Q, V2, k_transit) {
  # A[1] = GI, A[2] = Central, A[3] = Peripheral
  C2 <- A[2] / V1
  C3 <- A[3] / V2

  dA <- numeric(3)
  dA[1] <- -Ka * A[1] * k_transit  # Absorption avec transit
  dA[2] <- Ka * A[1] * k_transit - (CL + Q) * C2 + Q * C3
  dA[3] <- Q * C2 - Q * C3

  return(dA)
}

# --- Modèle PD: Emax + Hill -----------------------------------------------
calc_pd_response <- function(C, Emax, EC50, gamma, baseline = 0) {
  # Hill equation: E = E0 + Emax * C^gamma / (EC50^gamma + C^gamma)
  E <- baseline + Emax * C^gamma / (EC50^gamma + C^gamma)
  return(E)
}

# --- Calcul AUC (trapèze) ---------------------------------------------------
calc_auc <- function(time, conc) {
  sum(diff(time) * (head(conc, -1) + tail(conc, -1)) / 2)
}

# --- Calcul Cmax/MIC et AUC/MIC ---------------------------------------------
calc_pkpd_metrics <- function(pk_data, MIC = 1) {
  C <- pk_data$Conc_Central
  t <- pk_data$Time

  Cmax <- max(C)
  Tmax <- t[which.max(C)]
  AUC <- calc_auc(t, C)
  AUC_MIC <- AUC / MIC
  Cmax_MIC <- Cmax / MIC

  # Trough (dernière valeur non-nulle)
  C_nonzero <- C[C > 1e-10]
  Ctrough <- ifelse(length(C_nonzero) > 0, tail(C_nonzero, 1), 0)

  # Time above MIC (fCT)
  above_MIC <- sum(C >= MIC) / length(C) * 100  # % du temps

  # AUC_0-24h/MIC
  AUC_24 <- calc_auc(t[t <= 24], C[t <= 24])

  list(
    Cmax = Cmax,
    Tmax = Tmax,
    AUC = AUC,
    AUC_24 = AUC_24,
    AUC_MIC = AUC_24 / MIC,
    Cmax_MIC = Cmax_MIC,
    Ctrough = Ctrough,
    fCT_above_MIC = above_MIC
  )
}

# --- Estimation des paramètres PK enrichie -----------------------------------
estimate_pk_advanced <- function(logP, particle_size, surfactant, cosurfactant,
                                 oil, pe_conc, polymer, chitosan, enteric, dose) {
  # --- Bioavailability (modèle enrichi) ---
  # 1. LogP optimization (HIP)
  logP_opt <- 1.5
  logP_effect <- exp(-0.3 * ((logP - logP_opt) / 1.5)^2)

  # 2. Permeation enhancer (C10) — modèle sigmoidal
  PE_max <- 6  # Enhancement factor max
  PE_EC50 <- 20  # Concentration pour 50% enhancement
  PE_effect <- 1 + (PE_max - 1) * pe_conc^1.5 / (PE_EC50^1.5 + pe_conc^1.5)

  # 3. NPs (mucoadhesion + protection)
  NP_effect <- 1 + polymer / 100 * 0.8  # max +80%

  # 4. Chitosane (tight junctions + mucoadhesion)
  chitosan_effect <- 1 + chitosan * 0.4  # +40%

  # 5. SEDDS (émulsification)
  sedds_effect <- 1 + (surfactant + cosurfactant) / 100 * 0.6  # max +60%

  # 6. Entérique (protection gastrique)
  enteric_effect <- 1 + enteric * 0.25  # +25%

  # 7. Particle size (surface area)
  size_effect <- 1 + (500 - particle_size) / 500 * 0.5  # max +50%

  # 8. Effet dose (saturation à haute dose)
  dose_effect <- 1 - 0.1 * (dose / 1000)^2  # Légère saturation > 600mg

  # Bioavailability de base
  F_base <- 0.015

  F_est <- F_base * logP_effect * PE_effect * NP_effect * chitosan_effect *
           sedds_effect * enteric_effect * size_effect * dose_effect

  F_est <- min(F_est, 0.65)
  F_est <- max(F_est, 0.001)

  # --- Ka (absorption rate) ---
  Ka_base <- 0.8
  Ka <- Ka_base * size_effect * sedds_effect * PE_effect *
        (1 - enteric * 0.15)  # Entérique retarde
  Ka <- max(Ka, 0.2)
  Ka <- min(Ka, 5.0)

  # --- CL (clearance) ---
  CL <- 5.5  # L/h (fixe, dépend de la fonction rénale)

  # --- Vd ---
  V1 <- 17   # L (central)
  V2 <- 16   # L (périphérique)

  # --- Q (inter-compartmental clearance) ---
  Q <- 2.4   # L/h

  # --- Transit rate ---
  k_transit <- 1.5 + sedds_effect * 0.5  # SEDDS améliore le transit

  list(
    F_oral = F_est,
    Ka = Ka,
    CL = CL,
    V1 = V1,
    V2 = V2,
    Q = Q,
    k_transit = k_transit,
    factors = list(
      logP = logP_effect,
      PE = PE_effect,
      NP = NP_effect,
      chitosan = chitosan_effect,
      sedds = sedds_effect,
      enteric = enteric_effect,
      size = size_effect,
      dose = dose_effect
    )
  )
}

# --- Fonction objectif avancée (multi-objectifs) ----------------------------
objective_function_advanced <- function(individual, return_details = FALSE) {
  # Décoder les gènes
  logP          <- individual[1]
  particle_size <- individual[2]
  surfactant    <- individual[3]
  cosurfactant  <- individual[4]
  oil           <- individual[5]
  pe_conc       <- individual[6]
  polymer       <- individual[7]
  chitosan      <- round(individual[8])
  enteric       <- round(individual[9])
  dose          <- individual[10]

  # Contraintes
  sedds_total <- surfactant + cosurfactant + oil
  if (sedds_total > 100) return(rep(-1000, 4))

  # Paramètres PK
  pk_params <- estimate_pk_advanced(
    logP, particle_size, surfactant, cosurfactant,
    oil, pe_conc, polymer, chitosan, enteric, dose
  )

  # Simulation PK 2-compartiments
  pk_data <- solve_pk_2comp(
    dose_mg = dose,
    F_oral = pk_params$F_oral,
    Ka = pk_params$Ka,
    CL = pk_params$CL,
    V1 = pk_params$V1,
    Q = pk_params$Q,
    V2 = pk_params$V2,
    k_transit = pk_params$k_transit,
    t_end = 24,
    dt = 0.05
  )

  # Métriques PK/PD
  pkpd <- calc_pkpd_metrics(pk_data, MIC = 1)

  # --- Objectif 1: Bioavailability (maximiser) ---
  obj_F <- pk_params$F_oral / 0.65

  # --- Objectif 2: Cmax/MIC (maximiser, cible ≥ 8) ---
  if (pkpd$Cmax_MIC >= 8) {
    obj_Cmax <- 1.0
  } else {
    obj_Cmax <- pkpd$Cmax_MIC / 8
  }

  # --- Objectif 3: AUC/MIC (maximiser, cible ≥ 80) ---
  if (pkpd$AUC_MIC >= 80) {
    obj_AUC <- 1.0
  } else {
    obj_AUC <- pkpd$AUC_MIC / 80
  }

  # --- Objectif 4: Minimiser dose (pour acceptabilité) ---
  obj_dose <- 1 - (dose - 200) / 800  # 200mg → 1, 1000mg → 0
  obj_dose <- max(0, min(1, obj_dose))

  # --- Pénalités ---
  penalty <- 0
  if (pkpd$Cmax > 35) penalty <- penalty + (pkpd$Cmax - 35) / 35  # Toxicité
  if (pkpd$Ctrough > 2) penalty <- penalty + (pkpd$Ctrough - 2) / 2  # Accumulation
  if (pk_params$F_oral < 0.03) penalty <- penalty + 0.3  # F trop faible

  # --- Fitness composite (pondéré) ---
  fitness <- 0.30 * obj_F +
             0.25 * obj_Cmax +
             0.30 * obj_AUC +
             0.15 * obj_dose -
             0.10 * penalty

  fitness <- max(fitness, -10)

  if (return_details) {
    return(list(
      fitness       = fitness,
      F_oral        = pk_params$F_oral,
      Ka            = pk_params$Ka,
      CL            = pk_params$CL,
      V1            = pk_params$V1,
      V2            = pk_params$V2,
      Q             = pk_params$Q,
      k_transit     = pk_params$k_transit,
      Cmax          = pkpd$Cmax,
      Tmax          = pkpd$Tmax,
      AUC           = pkpd$AUC,
      AUC_24        = pkpd$AUC_24,
      Cmax_MIC      = pkpd$Cmax_MIC,
      AUC_MIC       = pkpd$AUC_MIC,
      Ctrough       = pkpd$Ctrough,
      fCT           = pkpd$fCT_above_MIC,
      penalty       = penalty,
      obj_F         = obj_F,
      obj_Cmax      = obj_Cmax,
      obj_AUC       = obj_AUC,
      obj_dose      = obj_dose,
      factors       = pk_params$factors,
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

# --- Wrapper population -------------------------------------------------------
evaluate_population_advanced <- function(pop) {
  apply(pop, 1, objective_function_advanced)
}

message("=== Modèle PK/PD avancé défini ===")
message("2-compartiments + transit + Hill equation")
message("Objectifs: F + Cmax/MIC + AUC/MIC + Dose")

# --- Test rapide --------------------------------------------------------------
message("\n--- Test du modèle ---")
test_ind <- c(1.5, 100, 40, 20, 30, 30, 20, 1, 1, 500)
test_result <- objective_function_advanced(test_ind, return_details = TRUE)
message("F_oral: ", round(test_result$F_oral * 100, 1), "%")
message("Cmax: ", round(test_result$Cmax, 2), " mg/L")
message("AUC: ", round(test_result$AUC, 1), " mg·h/L")
message("Cmax/MIC: ", round(test_result$Cmax_MIC, 1))
message("AUC/MIC: ", round(test_result$AUC_MIC, 1))
message("fCT > MIC: ", round(test_result$fCT, 1), "%")
message("Fitness: ", round(test_result$fitness, 4))
message("Facteurs: ", paste(round(unlist(test_result$factors), 2), collapse = " × "))
