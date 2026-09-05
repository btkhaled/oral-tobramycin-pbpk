# ============================================================================
# 02_ga_operators.R — Opérateurs génétiques (croisement, mutation, sélection)
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

source(file.path(SCRIPTS_DIR, "01_ga_objective_function.R"), local = FALSE)

#' Initialiser une population aléatoire
#'
#' @param n_pop Taille de la population
#' @param n_genes Nombre de gènes
#' @param bounds Tibble des bornes (min, max, type)
#' @return Matrice n_pop × n_genes
initialize_population <- function(n_pop, n_genes, bounds) {
  pop <- matrix(0, nrow = n_pop, ncol = n_genes)

  for (i in 1:n_genes) {
    if (bounds$type[i] == "binary") {
      pop[, i] <- sample(0:1, n_pop, replace = TRUE)
    } else {
      pop[, i] <- runif(n_pop, bounds$min_val[i], bounds$max_val[i])
    }
  }

  return(pop)
}

#' Sélection par tournoi
#'
#' @param population Matrice population
#' @param fitness Vecteur de fitness
#' @param n_select Nombre d'individus à sélectionner
#' @param k_size Taille du tournoi
#' @return Indices des parents sélectionnés
tournament_selection <- function(fitness, n_select, k_size = 3) {
  n_pop <- length(fitness)
  selected <- numeric(n_select)

  for (i in 1:n_select) {
    candidates <- sample(1:n_pop, k_size)
    winner <- candidates[which.max(fitness[candidates])]
    selected[i] <- winner
  }

  return(selected)
}

#' Croisement Simulated Binary Crossover (SBX)
#'
#' @param parent1 Vecteur parent 1
#' @param parent2 Vecteur parent 2
#' @param eta Distribution index (contrôle le spread)
#' @param bounds Tibble des bornes
#' @return Deux enfants
sbx_crossover <- function(parent1, parent2, eta = 20, bounds) {
  n_genes <- length(parent1)
  child1 <- parent1
  child2 <- parent2

  for (i in 1:n_genes) {
    if (runif(1) < 0.5) next  # Pas de croisement pour ce gène

    if (bounds$type[i] == "binary") {
      # Croisement binaire: swap
      if (runif(1) < 0.5) {
        child1[i] <- parent2[i]
        child2[i] <- parent1[i]
      }
    } else {
      # SBX pour gènes continus
      y1 <- min(parent1[i], parent2[i])
      y2 <- max(parent1[i], parent2[i])

      # Calcul des bornes étendues
      lb <- bounds$min_val[i]
      ub <- bounds$max_val[i]

      # U aléatoire
      u <- runif(1)

      # Calcul des enfants
      if (u <= 0.5) {
        beta <- (2 * u)^(1 / (eta + 1))
      } else {
        beta <- (1 / (2 * (1 - u)))^(1 / (eta + 1))
      }

      child1[i] <- 0.5 * ((1 + beta) * y1 + (1 - beta) * y2)
      child2[i] <- 0.5 * ((1 - beta) * y1 + (1 + beta) * y2)

      # Clip aux bornes
      child1[i] <- max(lb, min(ub, child1[i]))
      child2[i] <- max(lb, min(ub, child2[i]))
    }
  }

  return(list(child1 = child1, child2 = child2))
}

#' Mutation polynomial
#'
#' @param individual Vecteur individu
#' @param eta Distribution index
#' @param bounds Tibble des bornes
#' @return Individu muté
polynomial_mutation <- function(individual, eta = 20, bounds) {
  n_genes <- length(individual)
  mutant <- individual

  for (i in 1:n_genes) {
    if (runif(1) > GA_CONFIG$pmutation) next  # Pas de mutation

    if (bounds$type[i] == "binary") {
      # Mutation binaire: flip
      mutant[i] <- 1 - mutant[i]
    } else {
      # Mutation polynomiale
      lb <- bounds$min_val[i]
      ub <- bounds$max_val[i]
      delta <- ub - lb

      u <- runif(1)
      if (u < 0.5) {
        deltaq <- (2 * u)^(1 / (eta + 1)) - 1
      } else {
        deltaq <- 1 - (2 * (1 - u))^(1 / (eta + 1))
      }

      mutant[i] <- individual[i] + deltaq * delta
      mutant[i] <- max(lb, min(ub, mutant[i]))
    }
  }

  return(mutant)
}

#' Vérifier la validité d'un individu
#'
#' @param individual Vecteur individu
#' @param bounds Tibble des bornes
#' @return Logical (TRUE si valide)
validate_individual <- function(individual, bounds) {
  # Vérifier les bornes
  for (i in 1:nrow(bounds)) {
    if (bounds$type[i] == "binary") {
      if (!individual[i] %in% c(0, 1)) return(FALSE)
    } else {
      if (individual[i] < bounds$min_val[i] || individual[i] > bounds$max_val[i]) {
        return(FALSE)
      }
    }
  }

  # Vérifier contraintes formulation
  sedds_total <- individual[3] + individual[4] + individual[5]
  if (sedds_total > 100) return(FALSE)

  return(TRUE)
}

message("=== Opérateurs GA définis ===")
message("Sélection: Tournoi (k=3)")
message("Croisement: SBX (η=20)")
message("Mutation: Polynomial (η=20)")
message("Validation: Bornes + contraintes SEDDS")
