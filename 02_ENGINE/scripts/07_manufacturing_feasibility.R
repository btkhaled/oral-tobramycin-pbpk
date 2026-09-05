# ============================================================================
# 07_manufacturing_feasibility.R — Faisabilité de fabrication
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

ga_results <- readRDS(file.path(RESULTS_DIR, "ga_output.rds"))
top10 <- ga_results$top10
top10_sum <- ga_results$top10_summary

message("=== Analyse de faisabilité industrielle ===")

# --- 1. Coût estimé de fabrication (USD par dose) ------------------------------
estimate_manufacturing_cost <- function(formulation) {
  # Coût de base (matières premières pour 1 dose)
  base_cost <- 0.50  # USD/dose — tobramycine générique ~$0.20-0.50

  cost <- base_cost

  # HIP (fonctionnalisation acyl chain)
  cost <- cost + 0.80  # Réactifs HIP (acyl chloride + NaOH)

  # NPs (nanoparticules) — coût par dose
  if (formulation$polymer > 0) {
    cost <- cost + formulation$polymer / 100 * 1.50  # PLGA/Chitosan ~$1.50/g
    cost <- cost + 0.30  # Equipment (homogénéisation)
  }

  # Chitosane coating
  if (formulation$chitosan == 1) {
    cost <- cost + 0.40  # Chitosan + process
  }

  # Enteric coating
  if (formulation$enteric == 1) {
    cost <- cost + 0.25  # Eudragit
  }

  # SEDDS (coût proportionnel à la quantité de tensioactifs)
  sedds_complexity <- (formulation$surfactant + formulation$cosurfactant) / 100
  cost <- cost + sedds_complexity * 0.60

  # PE (C10 — tensioactif peu coûteux)
  cost <- cost + formulation$pe_conc / 100 * 0.15

  # Particle size (nano = equipment spécifique)
  if (formulation$particle_size < 200) {
    cost <- cost + 0.80  # High-pressure homogenization
  } else if (formulation$particle_size < 400) {
    cost <- cost + 0.40  # Standard homogenization
  }

  # Encapsulation (gélule/comprimé)
  cost <- cost + 0.30  # Compression/encapsulation

  return(cost)
}

# Calculer les coûts
manufacturing_costs <- map_dbl(top10, function(x) {
  estimate_manufacturing_cost(x$formulation)
})

top10_sum <- top10_sum %>%
  mutate(
    estimated_cost_usd = round(manufacturing_costs, 2),
    cost_category = case_when(
      estimated_cost_usd < 10 ~ "Faible",
      estimated_cost_usd < 15 ~ "Modéré",
      estimated_cost_usd < 20 ~ "Élevé",
      TRUE ~ "Très élevé"
    )
  )

# --- 2. Score de faisabilité ---------------------------------------------------
score_feasibility <- function(formulation, cost) {
  score <- 100

  # Pénalité coût ($0-5: excellent, $5-10: bon, $10-15: moyen, >$15: mauvais)
  if (cost > 5) score <- score - (cost - 5) * 2
  if (cost > 10) score <- score - (cost - 10) * 3
  if (cost > 15) score <- score - (cost - 15) * 5

  # Pénalité complexité formulation (nombre d'étapes)
  n_steps <- 3
  if (formulation$polymer > 0) n_steps <- n_steps + 2
  if (formulation$chitosan == 1) n_steps <- n_steps + 1
  if (formulation$enteric == 1) n_steps <- n_steps + 1
  if (formulation$pe_conc > 0) n_steps <- n_steps + 1

  if (n_steps > 5) score <- score - (n_steps - 5) * 5

  # Pénalité taille particule (nano = difficile)
  if (formulation$particle_size < 100) score <- score - 10
  if (formulation$particle_size < 200) score <- score - 5

  # Bonus simplicité
  if (formulation$polymer == 0 && formulation$chitosan == 0 && formulation$enteric == 0) {
    score <- score + 10
  }

  # Pénalité dose élevée (comprimé volumineux)
  if (formulation$dose > 800) score <- score - 5
  if (formulation$dose > 1000) score <- score - 10

  # Pénalité surfactant élevé (irritation GI)
  if (formulation$surfactant > 50) score <- score - 3

  return(max(0, min(100, score)))
}

feasibility_scores <- map_dbl(1:10, function(i) {
  score_feasibility(top10[[i]]$formulation, manufacturing_costs[i])
})

top10_sum <- top10_sum %>%
  mutate(
    feasibility_score = round(feasibility_scores, 1),
    feasibility_grade = case_when(
      feasibility_score >= 80 ~ "A",
      feasibility_score >= 60 ~ "B",
      feasibility_score >= 40 ~ "C",
      feasibility_score >= 20 ~ "D",
      TRUE ~ "F"
    )
  )

# --- 3. Analyse des étapes clés -----------------------------------------------
manufacturing_steps <- tibble(
  rank = 1:10,
  formulation = map_chr(top10, function(x) paste0("#", x$rank)),
  steps = map_chr(top10, function(x) {
    f <- x$formulation
    steps <- c("Dissolution tobramycine HIP")

    if (f$polymer > 0) {
      steps <- c(steps, "Préparation NPs polymère (nanoprécipitation)")
      steps <- c(steps, "Incorporation tobramycine dans NPs")
    }

    steps <- c(steps, "Préparation phase huileuse SEDDS")

    if (f$pe_conc > 0) {
      steps <- c(steps, "Ajout C10 (permeation enhancer)")
    }

    steps <- c(steps, "Mélange SEDDS (homogénéisation)")

    if (f$polymer > 0) {
      steps <- c(steps, "Incorporation NPs dans SEDDS")
    }

    if (f$chitosan == 1) {
      steps <- c(steps, "Enrobage chitosane (fluid bed)")
    }

    if (f$enteric == 1) {
      steps <- c(steps, "Enrobage entérique (Eudragit)")
    }

    steps <- c(steps, "Compression / remplissage gélule", "Contrôle qualité (libération in vitro)")

    paste(steps, collapse = " → ")
  }),
  n_steps = map_int(top10, function(x) {
    f <- x$formulation
    n <- 3  # Base
    if (f$polymer > 0) n <- n + 2
    if (f$pe_conc > 0) n <- n + 1
    if (f$chitosan == 1) n <- n + 1
    if (f$enteric == 1) n <- n + 1
    n + 2  # Compression + QC
  }),
  estimated_time_hours = n_steps * 1.5,  # ~1.5h par étape
  batch_scale_kg = map_dbl(top10, function(x) x$formulation$dose / 1000 * 10000)  # 10k doses
)

# --- 4. Visualisations --------------------------------------------------------
p_cost <- top10_sum %>%
  ggplot(aes(x = reorder(factor(rank), estimated_cost_usd), y = estimated_cost_usd, fill = cost_category)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0("$", estimated_cost_usd)), hjust = -0.1, size = 3.5) +
  scale_fill_manual(values = c("Faible" = "#4CAF50", "Modéré" = "#FFC107",
                               "Élevé" = "#FF9800", "Très élevé" = "#F44336"),
                    name = "Catégorie coût") +
  coord_flip() +
  scale_y_continuous(name = "Coût estimé (USD/dose)") +
  labs(
    title = "Coût de Fabrication Estimé — Top 10",
    subtitle = "Estimation incluant matières premières et procédés",
    x = "Ranking"
  )

print(p_cost)

p_feasibility <- top10_sum %>%
  ggplot(aes(x = reorder(factor(rank), feasibility_score), y = feasibility_score, fill = feasibility_grade)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(feasibility_grade, " (", feasibility_score, ")")),
            hjust = -0.1, size = 3.5) +
  scale_fill_manual(values = c("A" = "#4CAF50", "B" = "#8BC34A", "C" = "#FFC107",
                               "D" = "#FF9800", "F" = "#F44336"),
                    name = "Grade") +
  coord_flip() +
  scale_y_continuous(name = "Score de faisabilité (0-100)") +
  labs(
    title = "Faisabilité de Fabrication — Top 10",
    subtitle = "Score composite (coût + complexité + procédé)",
    x = "Ranking"
  )

print(p_feasibility)

# --- 5. Matrice coût vs efficacité --------------------------------------------
p_cost_eff <- top10_sum %>%
  mutate(
    label = paste0("#", rank),
    viable = Cmax_MIC >= 8 & AUC_MIC >= 80
  ) %>%
  ggplot(aes(x = estimated_cost_usd, y = fitness, color = viable, label = label)) +
  geom_point(size = 4, alpha = 0.8) +
  geom_text(vjust = -1.2, size = 3, color = "black") +
  geom_vline(xintercept = 15, linetype = "dashed", color = "gray50") +
  annotate("text", x = 16, y = max(top10_sum$fitness), label = "Coût max acceptable", hjust = 0, size = 3, color = "gray50") +
  scale_color_manual(values = c("TRUE" = "#4CAF50", "FALSE" = "#FF9800"),
                     labels = c("FALSE" = "Partielle", "TRUE" = "Complète")) +
  scale_x_continuous(name = "Coût estimé (USD/dose)") +
  scale_y_continuous(name = "Fitness Score") +
  labs(
    title = "Compromis Coût vs Efficacité",
    subtitle = "Pointillé: coût maximal acceptable ($15/dose)",
    color = "Cibles atteintes"
  )

print(p_cost_eff)

# --- 6. Tableau synthèse manufacturing ----------------------------------------
mfg_summary <- top10_sum %>%
  select(rank, F_oral, Cmax_MIC, AUC_MIC, fitness,
         estimated_cost_usd, cost_category, feasibility_score, feasibility_grade) %>%
  mutate(across(where(is.numeric), ~round(., 2)))

message("\n=== Tableau Manufacturing ===")
print(mfg_summary)

# --- Save -----------------------------------------------------------------------
ggsave(file.path(RESULTS_DIR, "manufacturing_cost.png"), p_cost, width = 8, height = 5, dpi = 300)
ggsave(file.path(RESULTS_DIR, "feasibility_score.png"), p_feasibility, width = 8, height = 5, dpi = 300)
ggsave(file.path(RESULTS_DIR, "cost_vs_efficacy.png"), p_cost_eff, width = 8, height = 6, dpi = 300)

write_csv(mfg_summary, file.path(RESULTS_DIR, "manufacturing_summary.csv"))
write_csv(manufacturing_steps, file.path(RESULTS_DIR, "manufacturing_steps.csv"))

message("\n=== Analyse manufacturing terminée ===")
