# ============================================================================
# 03_ga_run.R — Lancer le Genetic Algorithm (avec fitness sharing)
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

source(file.path(SCRIPTS_DIR, "02_ga_operators.R"), local = FALSE)

message("==============================================")
message("  GENETIC ALGORITHM — Optimisation Formulation")
message("  Tobramycine orale (BCS III)")
message("  Auteur: Khaled Ben Taieb")
message("==============================================")

# --- Fitness sharing (niching) ------------------------------------------------
# Penalise les individus trop proches pour maintenir la diversité
compute_shared_fitness <- function(fitness_raw, population, sigma_share = 2.0) {
  n <- length(fitness_raw)
  # Matrice de distances euclidiennes normalisées
  bounds_range <- PARAM_BOUNDS$max_val - PARAM_BOUNDS$min_val
  bounds_range[bounds_range == 0] <- 1

  shared_fitness <- numeric(n)
  for (i in 1:n) {
    niche_count <- 0
    for (j in 1:n) {
      dist_ij <- sqrt(sum(((population[i, ] - population[j, ]) / bounds_range)^2))
      if (dist_ij < sigma_share) {
        niche_count <- niche_count + (1 - dist_ij / sigma_share)
      }
    }
    shared_fitness[i] <- fitness_raw[i] / max(niche_count, 1)
  }
  return(shared_fitness)
}

# --- Initialiser la population ------------------------------------------------
set.seed(GA_CONFIG$seed)

message("\n--- Initialisation population ---")
population <- initialize_population(
  GA_CONFIG$popSize,
  nrow(PARAM_BOUNDS),
  PARAM_BOUNDS
)

message("Population: ", nrow(population), " individus × ", ncol(population), " gènes")

# --- Évaluation initiale ------------------------------------------------------
message("\n--- Évaluation initiale ---")
fitness_raw <- evaluate_population(population)
fitness <- compute_shared_fitness(fitness_raw, population, sigma_share = 1.5)

message("Fitness brut — Min: ", round(min(fitness_raw), 4),
        " | Max: ", round(max(fitness_raw), 4),
        " | Mean: ", round(mean(fitness_raw), 4))
message("Fitness partagé — Min: ", round(min(fitness), 4),
        " | Max: ", round(max(fitness), 4),
        " | Mean: ", round(mean(fitness), 4))

# --- Boucle principale du GA --------------------------------------------------
message("\n--- Début de l'évolution ---")

history <- list()
best_fitness_history <- numeric(GA_CONFIG$maxiter)
mean_fitness_history <- numeric(GA_CONFIG$maxiter)
stability_counter <- 0
best_fitness_ever <- -Inf
no_improve_counter <- 0

GA_START_TIME <- Sys.time()
final_gen <- GA_CONFIG$maxiter

for (gen in 1:GA_CONFIG$maxiter) {
  gen_start <- Sys.time()

  # --- Sélection des parents ---
  parent_indices <- tournament_selection(fitness, GA_CONFIG$popSize * 2, k_size = 3)
  parents <- population[parent_indices, ]

  # --- Croisement ---
  offspring <- matrix(0, nrow = GA_CONFIG$popSize, ncol = nrow(PARAM_BOUNDS))

  for (i in seq(1, GA_CONFIG$popSize, by = 2)) {
    if (i + 1 > GA_CONFIG$popSize) {
      offspring[i, ] <- parents[i, ]
      next
    }

    if (runif(1) < GA_CONFIG$pcrossover) {
      children <- sbx_crossover(parents[i, ], parents[i + 1, ], eta = 15, bounds = PARAM_BOUNDS)
      offspring[i, ]     <- children$child1
      offspring[i + 1, ] <- children$child2
    } else {
      offspring[i, ]     <- parents[i, ]
      offspring[i + 1, ] <- parents[i + 1, ]
    }
  }

  # --- Mutation (augmentée pour plus de diversité) ---
  for (i in 1:GA_CONFIG$popSize) {
    # 20% de mutation pour maintenir la diversité
    if (runif(1) < 0.20) {
      offspring[i, ] <- polynomial_mutation(offspring[i, ], eta = 10, bounds = PARAM_BOUNDS)
    }

    attempts <- 0
    while (!validate_individual(offspring[i, ], PARAM_BOUNDS) && attempts < 10) {
      offspring[i, ] <- polynomial_mutation(offspring[i, ], eta = 10, bounds = PARAM_BOUNDS)
      attempts <- attempts + 1
    }

    if (!validate_individual(offspring[i, ], PARAM_BOUNDS)) {
      offspring[i, ] <- initialize_population(1, nrow(PARAM_BOUNDS), PARAM_BOUNDS)
    }
  }

  # --- Injection aléatoire de nouveaux individus (10% par génération) ---
  n_inject <- max(2, round(GA_CONFIG$popSize * 0.10))
  inject_idx <- sample(1:GA_CONFIG$popSize, min(n_inject, GA_CONFIG$popSize))
  new_inds <- initialize_population(length(inject_idx), nrow(PARAM_BOUNDS), PARAM_BOUNDS)
  offspring[inject_idx, ] <- new_inds

  # --- Évaluation des offspring ---
  offspring_fitness_raw <- evaluate_population(offspring)

  # --- Élitisme + fitness sharing ---
  all_fitness_raw <- c(fitness_raw, offspring_fitness_raw)
  all_pop <- rbind(population, offspring)
  all_fitness_shared <- compute_shared_fitness(all_fitness_raw, all_pop, sigma_share = 1.5)

  top_indices <- order(all_fitness_shared, decreasing = TRUE)[1:GA_CONFIG$popSize]
  population    <- all_pop[top_indices, ]
  fitness_raw   <- all_fitness_raw[top_indices]
  fitness       <- all_fitness_shared[top_indices]

  # --- Historique ---
  best_raw <- max(fitness_raw)
  best_fitness_history[gen] <- best_raw
  mean_fitness_history[gen] <- mean(fitness_raw)

  history[[gen]] <- list(
    gen        = gen,
    best       = best_raw,
    mean       = mean(fitness_raw),
    sd         = sd(fitness_raw),
    best_shared = max(fitness)
  )

  # --- Arrêt prématuré ---
  if (best_raw > best_fitness_ever + 0.0001) {
    best_fitness_ever <- best_raw
    stability_counter <- 0
  } else {
    stability_counter <- stability_counter + 1
  }

  # --- Log ---
  gen_time <- as.numeric(difftime(Sys.time(), gen_start, units = "secs"))
  if (gen %% 10 == 0 || gen == 1) {
    message(sprintf(
      "Gen %3d | Best raw: %.4f | Mean raw: %.4f | Diversité: %.3f | Stability: %d/%d | Time: %.1fs",
      gen, best_raw, mean(fitness_raw), sd(fitness_raw),
      stability_counter, GA_CONFIG$run, gen_time
    ))
  }

  # --- Arrêt si stable ---
  if (stability_counter >= GA_CONFIG$run * 2) {
    message("\n✓ Arrêt après ", gen, " générations (stable ", GA_CONFIG$run * 2, " générations)")
    final_gen <- gen
    break
  }
}

GA_END_TIME <- Sys.time()
GA_TOTAL_TIME <- as.numeric(difftime(GA_END_TIME, GA_START_TIME, units = "mins"))
message("\n=== GA terminé en ", round(GA_TOTAL_TIME, 1), " minutes ===")
message("Générations: ", final_gen)

# --- Extraire le top 10 (diversifié) ------------------------------------------
message("\n--- Top 10 formulations (diversifiées) ---")

# Trier par fitness brut (pas partagé) et prendre le top 10
top10_indices <- order(fitness_raw, decreasing = TRUE)[1:min(10, nrow(population))]
top10_pop <- population[top10_indices, ]
top10_fitness <- fitness_raw[top10_indices]

# Évaluer chaque top 10 en détail
top10_details <- list()
for (i in 1:length(top10_indices)) {
  details <- objective_function(top10_pop[i, ], return_details = TRUE)
  details$rank <- i
  details$fitness <- top10_fitness[i]
  top10_details[[i]] <- details
}

# Créer le tableau récapitulatif
top10_summary <- bind_rows(lapply(top10_details, function(x) {
  bind_cols(x$formulation, tibble(
    rank         = x$rank,
    fitness      = x$fitness,
    F_oral       = x$F_oral,
    Cmax         = x$Cmax,
    Tmax         = x$Tmax,
    AUC          = x$AUC,
    t_half       = x$t_half,
    Ctrough      = x$Ctrough,
    Cmax_MIC     = x$Cmax_MIC,
    AUC_MIC      = x$AUC_MIC,
    Ka           = x$Ka
  ))
}))

# Afficher le top 10
print(top10_summary %>%
  select(rank, logP, particle_size, surfactant, cosurfactant, oil,
         pe_conc, polymer, chitosan, enteric, dose,
         F_oral, Cmax, AUC, Cmax_MIC, AUC_MIC, fitness) %>%
  mutate(across(where(is.numeric), ~round(., 2))))

# Vérifier la diversité
n_unique <- top10_summary %>% select(-rank) %>% distinct() %>% nrow()
message("\nFormulations uniques dans le top 10: ", n_unique, "/10")

# --- Sauvegarder les résultats ------------------------------------------------
saveRDS(list(
  ga_output      = history,
  population     = population,
  fitness_raw    = fitness_raw,
  fitness        = fitness,
  top10          = top10_details,
  top10_summary  = top10_summary,
  config         = GA_CONFIG,
  param_bounds   = PARAM_BOUNDS,
  physio         = PHYSIO,
  total_time_min = GA_TOTAL_TIME,
  n_generations  = final_gen
), file.path(RESULTS_DIR, "ga_output.rds"))

write_csv(top10_summary, file.path(RESULTS_DIR, "top10_formulations.csv"))

message("\n=== Résultats GA sauvegardés ===")
message("Fichier: ", file.path(RESULTS_DIR, "ga_output.rds"))
message("Top 10:  ", file.path(RESULTS_DIR, "top10_formulations.csv"))
