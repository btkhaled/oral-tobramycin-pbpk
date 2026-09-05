# ============================================================================
# 05_ga_visualization.R — Figures supplémentaires pour le manuscrit
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

source(file.path(SCRIPTS_DIR, "04_ga_results_analysis.R"), local = FALSE)

message("=== Génération des figures manuscrit ===")

# --- 1. Profils concentration-temps pour le Top 10 ----------------------------
pk_profiles <- map_dfr(top10, function(x) {
  x$pk_data %>%
    mutate(rank = x$rank,
           formulation = paste0("#", x$rank, " (F=", round(x$F_oral * 100, 1), "%)"))
})

p_profiles <- ggplot(pk_profiles, aes(x = Time, y = Concentration, color = factor(rank))) +
  geom_line(linewidth = 0.8) +
  scale_color_viridis_d(option = "turbo", name = "Ranking") +
  scale_x_continuous(name = "Temps (h)", breaks = seq(0, 24, by = 4)) +
  scale_y_continuous(name = "Concentration plasmatique (mg/L)") +
  labs(
    title = "Top 10 Formulations — Profils Concentration-Temps",
    subtitle = "Simulation PBPK simplifiée (modèle 1 compartiment)"
  ) +
  theme(legend.position = "right")

print(p_profiles)

# --- 2. Top 3 détaillé (avec zones cibles) ------------------------------------
top3_data <- map_dfr(top10[1:3], function(x) {
  x$pk_data %>%
    mutate(formulation = paste0("#", x$rank, " — F=", round(x$F_oral * 100, 1),
                                "% | Cmax/MIC=", round(x$Cmax_MIC, 1),
                                " | AUC/MIC=", round(x$AUC_MIC, 1)))
})

p_top3 <- ggplot(top3_data, aes(x = Time, y = Concentration, color = formulation)) +
  geom_line(linewidth = 1.2) +
  geom_hline(yintercept = c(8, 30), linetype = "dashed", color = c("#4CAF50", "#F44336")) +
  annotate("text", x = 0.5, y = 8.5, label = "Cmax/MIC = 8 (efficacité)", color = "#4CAF50", hjust = 0, size = 3) +
  annotate("text", x = 0.5, y = 31, label = "Cmax = 30 mg/L (toxicité)", color = "#F44336", hjust = 0, size = 3) +
  scale_color_brewer(palette = "Set1", name = "Formulation") +
  scale_x_continuous(name = "Temps (h)") +
  scale_y_continuous(name = "Concentration (mg/L)") +
  labs(
    title = "Top 3 Formulations — Détail PK avec cibles PD",
    subtitle = "Zones d'efficacité (vert) et de toxicité (rouge)"
  )

print(p_top3)

# --- 3. Contribution de chaque paramètre au fitness ---------------------------
# Analyse partielle: variance du fitness expliquée par chaque paramètre
param_contributions <- map_dbl(1:10, function(i) {
  cor_val <- cor(ga_fitness, ga_results$population[, i], use = "complete.obs")
  return(abs(cor_val))
})

contrib_df <- tibble(
  parameter = PARAM_BOUNDS$name,
  contribution = param_contributions
) %>%
  arrange(desc(contribution))

p_contrib <- ggplot(contrib_df, aes(x = reorder(parameter, contribution), y = contribution, fill = contribution)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = round(contribution, 3)), hjust = -0.1, size = 3.5) +
  scale_fill_viridis(option = "plasma", name = "Contribution") +
  coord_flip() +
  scale_y_continuous(name = "Corrélation absolue avec fitness") +
  labs(
    title = "Contribution des Paramètres au Fitness",
    subtitle = "Corrélation absolue entre paramètre et score fitness",
    x = NULL
  ) +
  theme(legend.position = "none")

print(p_contrib)

# --- 4. Distribution du fitness finale ----------------------------------------
fitness_df <- tibble(fitness = ga_fitness)

p_dist <- ggplot(fitness_df, aes(x = fitness)) +
  geom_histogram(bins = 20, fill = "#1976D2", alpha = 0.7, color = "white") +
  geom_vline(xintercept = max(ga_fitness), linetype = "dashed", color = "#D32F2F") +
  annotate("text", x = max(ga_fitness), y = Inf, label = paste("Max =", round(max(ga_fitness), 4)),
           vjust = 2, color = "#D32F2F", fontface = "bold") +
  scale_x_continuous(name = "Fitness") +
  scale_y_continuous(name = "Nombre d'individus") +
  labs(
    title = "Distribution du Fitness — Population Finale",
    subtitle = paste("N =", length(ga_fitness), "individus")
  )

print(p_dist)

# --- 5. Tableau de synthèse pour le manuscrit ---------------------------------
manuscript_table <- top10_sum %>%
  mutate(
    formulation_name = paste0("Candidate ", rank),
    logP_str = paste0(round(logP, 1)),
    ps_str = paste0(round(particle_size, 0), " nm"),
    sedds_str = paste0(round(surfactant, 0), "/", round(cosurfactant, 0), "/", round(oil, 0)),
    pe_str = paste0(round(pe_conc, 0), " mM"),
    F_str = paste0(round(F_oral * 100, 1), "%"),
    cmax_mic_str = paste0(round(Cmax_MIC, 1)),
    auc_mic_str = paste0(round(AUC_MIC, 1))
  ) %>%
  select(formulation_name, logP_str, ps_str, sedds_str, pe_str,
         polymer, chitosan, enteric, dose, F_str, cmax_mic_str, auc_mic_str, fitness)

write_csv(manuscript_table, file.path(RESULTS_DIR, "manuscript_table_top10.csv"))

# --- 6. Profil PK individuel pour chaque candidate ----------------------------
for (i in 1:10) {
  candidate_dir <- file.path(PROJECT_ROOT, "02_ENGINE", "results_legacy", "TOP_10_CANDIDATES",
                             sprintf("candidate_%02d", i))
  dir.create(candidate_dir, showWarnings = FALSE, recursive = TRUE)

  x <- top10[[i]]

  # Fiche profile
  profile_md <- sprintf("# Candidate %02d

## Paramètres de Formulation
| Paramètre | Valeur |
|-----------|--------|
| LogP modifié | %.1f |
| Taille particule | %.0f nm |
| Surfactant | %.0f%% |
| Co-surfactant | %.0f%% |
| Phase huileuse | %.0f%% |
| PE (C10) | %.0f mM |
| Polymère | %.0f%% |
| Chitosane | %s |
| Entérique | %s |
| Dose | %.0f mg |

## Résultats PK/PD
| Paramètre | Valeur |
|-----------|--------|
| Bioavailability | %.1f%% |
| Cmax | %.2f mg/L |
| Tmax | %.1f h |
| AUC | %.1f mg·h/L |
| t½ | %.1f h |
| Ctrough | %.3f mg/L |
| Cmax/MIC | %.1f |
| AUC/MIC | %.1f |
| Ka | %.2f h⁻¹ |
| Fitness | %.4f |

## Mécanisme d'action
- HIP: LogP amélioré de -2.9 à %.1f (%.0f× amélioration)
- SEDDS: %s%% huile + %s%% surfactant + %s%% co-surfactant
- PE: C10 à %.0f mM (tight junctions)
- %s
- %s

## Faisabilité industrielle
- [À compléter avec analyse fabrication]
",
    i,
    x$formulation$logP, x$formulation$particle_size,
    x$formulation$surfactant, x$formulation$cosurfactant, x$formulation$oil,
    x$formulation$pe_conc, x$formulation$polymer,
    ifelse(x$formulation$chitosan == 1, "Oui", "Non"),
    ifelse(x$formulation$enteric == 1, "Oui", "Non"),
    x$formulation$dose,
    x$F_oral * 100, x$Cmax, x$Tmax, x$AUC, x$t_half, x$Ctrough,
    x$Cmax_MIC, x$AUC_MIC, x$Ka, x$fitness,
    x$formulation$logP, 10^(x$formulation$logP + 2.9),
    round(x$formulation$oil), round(x$formulation$surfactant), round(x$formulation$cosurfactant),
    x$formulation$pe_conc,
    ifelse(x$formulation$polymer > 0, paste("NPs: polymère à", round(x$formulation$polymer), "%"), "Pas de NPs"),
    ifelse(x$formulation$chitosan == 1, "Chitosane: ouverture tight junctions (+30% F)", "")
  )

  writeLines(profile_md, file.path(candidate_dir, "profile.md"))

  # Profil PK
  p_candidate <- x$pk_data %>%
    ggplot(aes(x = Time, y = Concentration)) +
    geom_line(color = "#1976D2", linewidth = 1) +
    geom_point(color = "#0D47A1", size = 1.5) +
    geom_hline(yintercept = c(8, 30), linetype = "dashed", color = c("#4CAF50", "#F44336"), alpha = 0.5) +
    scale_x_continuous(name = "Temps (h)") +
    scale_y_continuous(name = "Concentration (mg/L)") +
    labs(
      title = paste0("Candidate ", i, " — Profil PK"),
      subtitle = sprintf("F=%.1f%% | Cmax=%.2f mg/L | AUC=%.1f mg·h/L | Cmax/MIC=%.1f | AUC/MIC=%.1f",
                          x$F_oral * 100, x$Cmax, x$AUC, x$Cmax_MIC, x$AUC_MIC)
    )

  ggsave(file.path(candidate_dir, "concentration_time.png"), p_candidate, width = 8, height = 5, dpi = 300)

  # Données CSV
  write_csv(x$pk_data, file.path(candidate_dir, "simulation_results.csv"))

  write_csv(tibble(
    parameter = c("F_oral", "Cmax", "Tmax", "AUC", "t_half", "Ctrough", "Cmax_MIC", "AUC_MIC", "Ka", "fitness"),
    value = c(x$F_oral, x$Cmax, x$Tmax, x$AUC, x$t_half, x$Ctrough, x$Cmax_MIC, x$AUC_MIC, x$Ka, x$fitness)
  ), file.path(candidate_dir, "pk_parameters.csv"))
}

message("\n=== Figures et candidats sauvegardés ===")
message("TOP_10_CANDIDATES: ", file.path(PROJECT_ROOT, "02_ENGINE", "results_legacy", "TOP_10_CANDIDATES"))
message("Résultats GA: ", RESULTS_DIR)
