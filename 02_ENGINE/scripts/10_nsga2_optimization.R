# ============================================================================
# 10_nsga2_optimization.R — NSGA-II Multi-Objectif (4 objectifs)
# Maximiser: F, Cmax/MIC, AUC/MIC  |  Minimiser: Dose
# ============================================================================

# --- Configurer les chemins ---------------------------------------------------
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

source(file.path(SCRIPTS_DIR, "09_advanced_pk_model.R"), local = FALSE)
source(file.path(SCRIPTS_DIR, "02_ga_operators.R"), local = FALSE)

message("==============================================")
message("  NSGA-II — Optimisation Multi-Objectif")
message("  4 objectifs: F, Cmax/MIC, AUC/MIC, 1/Dose")
message("==============================================")

# --- Évaluer un individu → vecteur objectif (4D) ------------------------------
evaluate_objectives <- function(individual) {
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

  sedds_total <- surfactant + cosurfactant + oil
  if (sedds_total > 100) return(c(-1000, -1000, -1000, -1000))

  pk_params <- estimate_pk_advanced(
    logP, particle_size, surfactant, cosurfactant,
    oil, pe_conc, polymer, chitosan, enteric, dose
  )

  pk_data <- solve_pk_2comp(
    dose_mg = dose,
    F_oral = pk_params$F_oral,
    Ka = pk_params$Ka,
    CL = pk_params$CL,
    V1 = pk_params$V1,
    Q = pk_params$Q,
    V2 = pk_params$V2,
    k_transit = pk_params$k_transit,
    t_end = 24, dt = 0.05
  )

  pkpd <- calc_pkpd_metrics(pk_data, MIC = 1)

  # Objectifs (tous à maximiser sauf dose)
  obj_F     <- pk_params$F_oral       # Max
  obj_Cmax  <- pkpd$Cmax_MIC          # Max
  obj_AUC   <- pkpd$AUC_MIC           # Max
  obj_dose  <- 1 / dose               # Max (= min dose)

  c(obj_F, obj_Cmax, obj_AUC, obj_dose)
}

# --- Non-dominated sorting ---------------------------------------------------
# Retourne les rangs de domination (1 = front de Pareto)
non_dominated_sort <- function(obj_matrix) {
  n <- nrow(obj_matrix)
  rank <- numeric(n)
  S <- vector("list", n)  # Set des individus dominés
  n_dom <- numeric(n)     # Nombre de dominants

  for (i in 1:n) {
    S[[i]] <- integer(0)
    n_dom[i] <- 0
    for (j in 1:n) {
      if (i == j) next
      # Vérifier si i domine j (tous les objectifs ≥ et au moins un >)
      if (all(obj_matrix[i, ] >= obj_matrix[j, ]) && any(obj_matrix[i, ] > obj_matrix[j, ])) {
        S[[i]] <- c(S[[i]], j)
      } else if (all(obj_matrix[j, ] >= obj_matrix[i, ]) && any(obj_matrix[j, ] > obj_matrix[i, ])) {
        n_dom[i] <- n_dom[i] + 1
      }
    }
  }

  # Fronts successifs
  current_front <- which(n_dom == 0)
  front_rank <- 1

  while (length(current_front) > 0) {
    rank[current_front] <- front_rank

    next_front <- integer(0)
    for (i in current_front) {
      for (j in S[[i]]) {
        n_dom[j] <- n_dom[j] - 1
        if (n_dom[j] == 0) {
          next_front <- c(next_front, j)
        }
      }
    }

    current_front <- next_front
    front_rank <- front_rank + 1
  }

  return(rank)
}

# --- Crowding distance --------------------------------------------------------
crowding_distance <- function(obj_matrix, rank) {
  n <- nrow(obj_matrix)
  n_obj <- ncol(obj_matrix)
  cd <- numeric(n)

  for (r in unique(rank)) {
    idx <- which(rank == r)
    if (length(idx) <= 2) {
      cd[idx] <- Inf
      next
    }

    for (m in 1:n_obj) {
      ord <- order(obj_matrix[idx, m])
      sorted_idx <- idx[ord]

      cd[sorted_idx[1]] <- Inf
      cd[sorted_idx[length(sorted_idx)]] <- Inf

      if (obj_matrix[sorted_idx[length(sorted_idx)], m] - obj_matrix[sorted_idx[1], m] > 1e-10) {
        for (k in 2:(length(sorted_idx) - 1)) {
          cd[sorted_idx[k]] <- cd[sorted_idx[k]] +
            (obj_matrix[sorted_idx[k + 1], m] - obj_matrix[sorted_idx[k - 1], m]) /
            (obj_matrix[sorted_idx[length(sorted_idx)], m] - obj_matrix[sorted_idx[1], m])
        }
      }
    }
  }

  return(cd)
}

# --- Tournament selection (NSGA-II) ------------------------------------------
tournament_selection_nsga2 <- function(obj_matrix, rank, cd, n_select) {
  n <- nrow(obj_matrix)
  selected <- numeric(n_select)

  for (i in 1:n_select) {
    a <- sample(1:n, 2)
    # Préférer meilleur rang, puis meilleure distance
    if (rank[a[1]] < rank[a[2]]) {
      selected[i] <- a[1]
    } else if (rank[a[2]] < rank[a[1]]) {
      selected[i] <- a[2]
    } else {
      selected[i] <- ifelse(cd[a[1]] > cd[a[2]], a[1], a[2])
    }
  }

  return(selected)
}

# --- SBX crossover -----------------------------------------------------------
sbx_nsga <- function(p1, p2, eta = 20) {
  n <- length(p1)
  c1 <- p1
  c2 <- p2

  for (i in 1:n) {
    if (runif(1) > 0.5) next

    if (PARAM_BOUNDS$type[i] == "binary") {
      if (runif(1) < 0.5) {
        c1[i] <- p2[i]
        c2[i] <- p1[i]
      }
    } else {
      u <- runif(1)
      beta <- ifelse(u <= 0.5, (2 * u)^(1/(eta+1)), (1/(2*(1-u)))^(1/(eta+1)))

      y1 <- min(p1[i], p2[i])
      y2 <- max(p1[i], p2[i])

      c1[i] <- 0.5 * ((1+beta)*y1 + (1-beta)*y2)
      c2[i] <- 0.5 * ((1-beta)*y1 + (1+beta)*y2)

      c1[i] <- max(PARAM_BOUNDS$min_val[i], min(PARAM_BOUNDS$max_val[i], c1[i]))
      c2[i] <- max(PARAM_BOUNDS$min_val[i], min(PARAM_BOUNDS$max_val[i], c2[i]))
    }
  }

  list(child1 = c1, child2 = c2)
}

# --- Polynomial mutation -----------------------------------------------------
pmx_mutation <- function(ind, eta = 20) {
  mutant <- ind
  for (i in 1:length(ind)) {
    if (runif(1) > 0.15) next

    if (PARAM_BOUNDS$type[i] == "binary") {
      mutant[i] <- 1 - mutant[i]
    } else {
      u <- runif(1)
      delta <- ifelse(u < 0.5, (2*u)^(1/(eta+1))-1, 1-(2*(1-u))^(1/(eta+1)))
      mutant[i] <- ind[i] + delta * (PARAM_BOUNDS$max_val[i] - PARAM_BOUNDS$min_val[i])
      mutant[i] <- max(PARAM_BOUNDS$min_val[i], min(PARAM_BOUNDS$max_val[i], mutant[i]))
    }
  }
  mutant
}

# --- Initialisation population ------------------------------------------------
# Allow run_engine.R to override via env vars ENGINE_POP / ENGINE_GEN (English CLI --pop / --gen)
POP_SIZE <- as.integer(Sys.getenv("ENGINE_POP_NSGA2", unset = "")); if (is.na(POP_SIZE)) POP_SIZE <- 200
if (!nzchar(Sys.getenv("ENGINE_POP_NSGA2", unset = ""))) {
  tmp_pop <- Sys.getenv("ENGINE_POP", unset = "")
  if (nzchar(tmp_pop)) POP_SIZE <- as.integer(tmp_pop)
}
if (is.na(POP_SIZE) || POP_SIZE <= 0) POP_SIZE <- 200
N_GEN    <- as.integer(Sys.getenv("ENGINE_GEN_NSGA2", unset = "")); if (is.na(N_GEN)) N_GEN <- 300
if (!nzchar(Sys.getenv("ENGINE_GEN_NSGA2", unset = ""))) {
  tmp_gen <- Sys.getenv("ENGINE_GEN", unset = "")
  if (nzchar(tmp_gen)) N_GEN <- as.integer(tmp_gen)
}
if (is.na(N_GEN) || N_GEN <= 0) N_GEN <- 300
N_OBJ    <- 4
ELITE     <- 20

if (nzchar(Sys.getenv("ENGINE_POP", unset = "")) || nzchar(Sys.getenv("ENGINE_GEN", unset = ""))) {
  message("Override NSGA-II POP_SIZE -> ", POP_SIZE, " N_GEN -> ", N_GEN, " (via --pop/--gen)")
}

set.seed(42)

message("\n--- Initialisation population (N=", POP_SIZE, ") ---")
population <- initialize_population(POP_SIZE, nrow(PARAM_BOUNDS), PARAM_BOUNDS)

# Évaluation initiale
obj_matrix <- t(apply(population, 1, evaluate_objectives))

# Filtrer les individus invalides
valid <- apply(obj_matrix, 1, function(x) all(x > -100))
message("Individus valides: ", sum(valid), "/", POP_SIZE)

if (sum(valid) < POP_SIZE) {
  # Remplacer les invalides
  n_invalid <- sum(!valid)
  new_inds <- initialize_population(n_invalid, nrow(PARAM_BOUNDS), PARAM_BOUNDS)
  population[!valid, ] <- new_inds
  obj_matrix[!valid, ] <- t(apply(new_inds, 1, evaluate_objectives))
}

# --- Boucle NSGA-II -----------------------------------------------------------
message("\n--- Début NSGA-II (", N_GEN, " générations) ---")

GA_START <- Sys.time()
pareto_history <- list()

for (gen in 1:N_GEN) {
  gen_start <- Sys.time()

  # Non-dominated sorting
  rank <- non_dominated_sort(obj_matrix)
  cd <- crowding_distance(obj_matrix, rank)

  # Sélection
  parent_idx <- tournament_selection_nsga2(obj_matrix, rank, cd, POP_SIZE * 2)
  parents <- population[parent_idx, ]

  # Croisement + Mutation
  offspring <- matrix(0, POP_SIZE, nrow(PARAM_BOUNDS))
  for (i in seq(1, POP_SIZE, by = 2)) {
    if (i + 1 > POP_SIZE) {
      offspring[i, ] <- parents[i, ]
      next
    }
    if (runif(1) < 0.85) {
      children <- sbx_nsga(parents[i, ], parents[i+1, ], eta = 20)
      offspring[i, ] <- children$child1
      offspring[i+1, ] <- children$child2
    } else {
      offspring[i, ] <- parents[i, ]
      offspring[i+1, ] <- parents[i+1, ]
    }
  }

  # Mutation
  for (i in 1:POP_SIZE) {
    offspring[i, ] <- pmx_mutation(offspring[i, ], eta = 15)
    attempts <- 0
    while (!validate_individual(offspring[i, ], PARAM_BOUNDS) && attempts < 10) {
      offspring[i, ] <- pmx_mutation(offspring[i, ], eta = 15)
      attempts <- attempts + 1
    }
    if (!validate_individual(offspring[i, ], PARAM_BOUNDS)) {
      offspring[i, ] <- initialize_population(1, nrow(PARAM_BOUNDS), PARAM_BOUNDS)
    }
  }

  # Injection aléatoire (5%)
  n_inject <- max(5, round(POP_SIZE * 0.05))
  inject_idx <- sample(1:POP_SIZE, n_inject)
  offspring[inject_idx, ] <- initialize_population(n_inject, nrow(PARAM_BOUNDS), PARAM_BOUNDS)

  # Évaluation offspring
  offspring_obj <- t(apply(offspring, 1, evaluate_objectives))

  # Combiner parent + offspring
  combined_pop <- rbind(population, offspring)
  combined_obj <- rbind(obj_matrix, offspring_obj)

  # Nouvelle population par NSGA-II selection
  comb_rank <- non_dominated_sort(combined_obj)
  comb_cd <- crowding_distance(combined_obj, comb_rank)

  # Trier par rang puis distance
  new_order <- order(comb_rank, -comb_cd)
  top_idx <- new_order[1:POP_SIZE]

  population <- combined_pop[top_idx, ]
  obj_matrix <- combined_obj[top_idx, ]

  # Historique
  n_pareto <- sum(comb_rank[top_idx] == 1)
  best_F <- max(obj_matrix[, 1])
  best_Cmax <- max(obj_matrix[, 2])
  best_AUC <- max(obj_matrix[, 3])

  pareto_history[[gen]] <- list(
    gen = gen,
    n_pareto = n_pareto,
    best_F = best_F,
    best_Cmax = best_Cmax,
    best_AUC = best_AUC,
    rank = comb_rank[top_idx]
  )

  # Log
  gen_time <- as.numeric(difftime(Sys.time(), gen_start, units = "secs"))
  if (gen %% 25 == 0 || gen == 1) {
    message(sprintf(
      "Gen %3d | Pareto: %d | Best F: %.3f | Best Cmax/MIC: %.1f | Best AUC/MIC: %.1f | Time: %.1fs",
      gen, n_pareto, best_F, best_Cmax, best_AUC, gen_time
    ))
  }
}

GA_END <- Sys.time()
GA_TIME <- as.numeric(difftime(GA_END, GA_START, units = "mins"))
message("\n=== NSGA-II terminé en ", round(GA_TIME, 1), " minutes ===")

# --- Extraire le front de Pareto ---------------------------------------------
final_rank <- non_dominated_sort(obj_matrix)
pareto_front <- which(final_rank == 1)

message("Front de Pareto: ", length(pareto_front), " solutions")

# Évaluer chaque solution du Pareto front en détail
pareto_details <- list()
for (i in seq_along(pareto_front)) {
  idx <- pareto_front[i]
  details <- objective_function_advanced(population[idx, ], return_details = TRUE)
  details$pareto_rank <- i
  details$obj_values <- obj_matrix[idx, ]
  pareto_details[[i]] <- details
}

# Trier par fitness composite
pareto_fitness <- sapply(pareto_details, function(x) x$fitness)
pareto_order <- order(pareto_fitness, decreasing = TRUE)
pareto_details <- pareto_details[pareto_order]

# Top 10 du Pareto front
top10_advanced <- head(pareto_details, 10)

# Tableau récapitulatif
top10_adv_summary <- bind_rows(lapply(top10_advanced, function(x) {
  bind_cols(x$formulation, tibble(
    pareto_rank   = x$pareto_rank,
    fitness       = x$fitness,
    F_oral        = x$F_oral,
    Cmax          = x$Cmax,
    Tmax          = x$Tmax,
    AUC           = x$AUC,
    AUC_24        = x$AUC_24,
    Cmax_MIC      = x$Cmax_MIC,
    AUC_MIC       = x$AUC_MIC,
    Ctrough       = x$Ctrough,
    fCT           = x$fCT,
    Ka            = x$Ka,
    k_transit     = x$k_transit,
    obj_F         = x$obj_F,
    obj_Cmax      = x$obj_Cmax,
    obj_AUC       = x$obj_AUC,
    obj_dose      = x$obj_dose,
    penalty       = x$penalty
  ))
}))

message("\n=== Top 10 Avancé ===")
print(top10_adv_summary %>%
  select(pareto_rank, logP, particle_size, surfactant, cosurfactant, oil,
         pe_conc, polymer, chitosan, enteric, dose,
         F_oral, Cmax_MIC, AUC_MIC, fCT, fitness) %>%
  mutate(across(where(is.numeric), ~round(., 2))))

# --- Sauvegarder --------------------------------------------------------------
saveRDS(list(
  population       = population,
  obj_matrix       = obj_matrix,
  pareto_front     = pareto_front,
  pareto_details   = pareto_details,
  top10_advanced   = top10_advanced,
  top10_adv_summary = top10_adv_summary,
  pareto_history   = pareto_history,
  config           = list(pop_size = POP_SIZE, n_gen = N_GEN, n_obj = N_OBJ),
  total_time_min   = GA_TIME
), file.path(RESULTS_DIR, "nsga2_output.rds"))

write_csv(top10_adv_summary, file.path(RESULTS_DIR, "top10_advanced.csv"))

message("\n=== Résultats NSGA-II sauvegardés ===")
message("Fichier: ", file.path(RESULTS_DIR, "nsga2_output.rds"))
