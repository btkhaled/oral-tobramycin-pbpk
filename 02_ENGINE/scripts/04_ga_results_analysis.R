# ============================================================================
# 04_ga_results_analysis.R — Analyse des résultats du GA
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

# --- Charger les résultats GA -------------------------------------------------
ga_results <- readRDS(file.path(RESULTS_DIR, "ga_output.rds"))

history     <- ga_results$ga_output
top10       <- ga_results$top10
top10_sum   <- ga_results$top10_summary
n_gen       <- ga_results$n_generations
total_time  <- ga_results$total_time_min

# Utiliser le fitness brut (pas le shared fitness) pour l'analyse
if (!is.null(ga_results$fitness_raw)) {
  ga_fitness <- ga_results$fitness_raw
} else {
  ga_fitness <- ga_results$fitness
}

message("=== Analyse des résultats GA ===")
message("Générations: ", n_gen)
message("Durée: ", round(total_time, 1), " min")
message("Fitness max (brut): ", round(max(ga_fitness), 4))

# --- 1. Courbe de convergence -------------------------------------------------
convergence_data <- tibble(
  generation = 1:length(history),
  best       = map_dbl(history, ~.x$best),
  mean       = map_dbl(history, ~.x$mean),
  sd         = map_dbl(history, ~.x$sd)
)

p_convergence <- ggplot(convergence_data, aes(x = generation)) +
  geom_ribbon(aes(ymin = mean - sd, ymax = mean + sd), fill = "#E3F2FD", alpha = 0.5) +
  geom_line(aes(y = mean), color = "#1976D2", linewidth = 0.8) +
  geom_line(aes(y = best), color = "#D32F2F", linewidth = 1.2) +
  annotate("text", x = n_gen * 0.8, y = max(convergence_data$best) * 0.95,
           label = paste("Max fitness =", round(max(convergence_data$best), 4)),
           color = "#D32F2F", fontface = "bold", size = 4) +
  scale_x_continuous(name = "Génération") +
  scale_y_continuous(name = "Fitness") +
  labs(
    title = "Convergence du Genetic Algorithm",
    subtitle = paste(n_gen, "générations |", round(total_time, 1), "min | Pop =", GA_CONFIG$popSize),
    color = NULL
  ) +
  theme(legend.position = "right")

print(p_convergence)

# --- 2. Heatmap des Top 10 (paramètres de formulation) ------------------------
top10_for_heatmap <- top10_sum %>%
  select(rank, logP, particle_size, surfactant, cosurfactant, oil,
         pe_conc, polymer, chitosan, enteric, dose) %>%
  pivot_longer(-rank, names_to = "parameter", values_to = "value") %>%
  group_by(parameter) %>%
  mutate(value_scaled = (value - min(value)) / (max(value) - min(value) + 1e-10)) %>%
  ungroup()

p_heatmap <- ggplot(top10_for_heatmap, aes(x = factor(rank), y = parameter, fill = value_scaled)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = round(value, 1)), size = 3, color = "black") +
  scale_fill_viridis(option = "C", name = "Valeur\nnormalisée") +
  scale_x_discrete(name = "Ranking") +
  labs(
    title = "Top 10 Formulations — Paramètres",
    subtitle = "Valeurs normalisées (0 = min, 1 = max)",
    y = NULL
  ) +
  theme(axis.text.y = element_text(size = 10))

print(p_heatmap)

# --- 3. Comparaison PK des Top 10 ---------------------------------------------
pk_comparison <- top10_sum %>%
  select(rank, F_oral, Cmax, AUC, Cmax_MIC, AUC_MIC, t_half, Ctrough) %>%
  mutate(across(where(is.numeric), ~round(., 2)))

message("\n=== Tableau PK des Top 10 ===")
print(pk_comparison)

# --- 4. Scatter plot F vs AUC/MIC (Pareto front) -----------------------------
p_pareto <- top10_sum %>%
  mutate(
    viable = Cmax_MIC >= 8 & AUC_MIC >= 80,
    label  = paste0("#", rank)
  ) %>%
  ggplot(aes(x = F_oral * 100, y = AUC_MIC, color = viable)) +
  geom_point(size = 4, alpha = 0.8) +
  geom_text(aes(label = label), vjust = -1.2, size = 3, color = "black") +
  geom_vline(xintercept = 5, linetype = "dashed", color = "gray50") +
  geom_hline(yintercept = 80, linetype = "dashed", color = "gray50") +
  annotate("text", x = 7, y = 85, label = "Cible AUC/MIC ≥ 80", size = 3, hjust = 0) +
  scale_color_manual(values = c("TRUE" = "#4CAF50", "FALSE" = "#FF9800"),
                     labels = c("FALSE" = "Partielle", "TRUE" = "Complète")) +
  scale_x_continuous(name = "Bioavailability (%)") +
  scale_y_continuous(name = "AUC/MIC ratio") +
  labs(
    title = "Pareto Front — Efficacité vs Bioavailability",
    subtitle = "Cibles: F > 5% (pointillé vertical), AUC/MIC > 80 (pointillé horizontal)",
    color = "Targets atteints"
  )

print(p_pareto)

# --- 5. Radar chart (Top 3) ---------------------------------------------------
# Normaliser les paramètres pour radar chart
radar_data <- top10_sum %>%
  filter(rank <= 3) %>%
  select(rank, F_oral, Cmax_MIC, AUC_MIC, Cmax, t_half) %>%
  mutate(
    F_norm      = F_oral / max(top10_sum$F_oral),
    CmaxMIC_norm = Cmax_MIC / max(top10_sum$Cmax_MIC),
    AUCMIC_norm  = AUC_MIC / max(top10_sum$AUC_MIC),
    Cmax_norm    = 1 - Cmax / 30,  # Inversé: plus bas = mieux
    thalf_norm   = t_half / max(top10_sum$t_half)
  ) %>%
  select(rank, F_norm, CmaxMIC_norm, AUCMIC_norm, Cmax_norm, thalf_norm) %>%
  pivot_longer(-rank, names_to = "metric", values_to = "value") %>%
  mutate(
    metric = case_when(
      metric == "F_norm"       ~ "Bioavailability",
      metric == "CmaxMIC_norm" ~ "Cmax/MIC",
      metric == "AUCMIC_norm"  ~ "AUC/MIC",
      metric == "Cmax_norm"    ~ "Safety (1-Cmax/30)",
      metric == "thalf_norm"   ~ "Half-life"
    ),
    rank = paste("Rank", rank)
  )

p_radar <- ggplot(radar_data, aes(x = metric, y = value, fill = rank, group = rank)) +
  geom_col(position = "dodge", alpha = 0.7) +
  geom_text(aes(label = round(value, 2)), position = position_dodge(width = 0.9), size = 3, vjust = -0.5) +
  scale_fill_brewer(palette = "Set1") +
  scale_y_continuous(name = "Score normalisé (0-1)", limits = c(0, 1.1)) +
  labs(
    title = "Radar Chart — Top 3 Formulations",
    subtitle = "Scores normalisés par métrique",
    fill = "Ranking"
  ) +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

print(p_radar)

# --- 6. Barplot de fitness par rank --------------------------------------------
p_fitness_bar <- top10_sum %>%
  ggplot(aes(x = reorder(factor(rank), fitness), y = fitness, fill = factor(rank))) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = round(fitness, 3)), hjust = -0.1, size = 3.5) +
  scale_fill_brewer(palette = "RdYlGn") +
  coord_flip() +
  scale_y_continuous(name = "Fitness Score") +
  labs(
    title = "Ranking des Top 10 par Fitness",
    subtitle = "Score composite (F + Cmax/MIC + AUC/MIC - Toxicité)",
    x = "Ranking", fill = "Rank"
  ) +
  theme(legend.position = "none")

print(p_fitness_bar)

# --- 7. Analyse de corrélation -----------------------------------------------
cor_data <- top10_sum %>%
  select(logP, particle_size, surfactant, pe_conc, polymer, dose,
         F_oral, Cmax, AUC, Cmax_MIC, AUC_MIC)

cor_matrix <- cor(cor_data, use = "complete.obs")

p_cor <- ggplot(
  as.data.frame(as.table(cor_matrix)),
  aes(x = Var1, y = Var2, fill = Freq)
) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(Freq, 2)), size = 2.5) +
  scale_fill_gradient2(low = "#D32F2F", mid = "white", high = "#1976D2",
                       midpoint = 0, name = "Corrélation") +
  labs(
    title = "Matrice de Corrélation — Paramètres vs Sorties",
    x = NULL, y = NULL
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
        axis.text.y = element_text(size = 8))

print(p_cor)

# --- Sauvegarder toutes les figures -------------------------------------------
ggsave(file.path(RESULTS_DIR, "convergence_plot.png"), p_convergence, width = 10, height = 6, dpi = 300)
ggsave(file.path(RESULTS_DIR, "heatmap_top10.png"), p_heatmap, width = 10, height = 7, dpi = 300)
ggsave(file.path(RESULTS_DIR, "pareto_front.png"), p_pareto, width = 8, height = 6, dpi = 300)
ggsave(file.path(RESULTS_DIR, "radar_chart.png"), p_radar, width = 10, height = 6, dpi = 300)
ggsave(file.path(RESULTS_DIR, "fitness_ranking.png"), p_fitness_bar, width = 8, height = 5, dpi = 300)
ggsave(file.path(RESULTS_DIR, "correlation_matrix.png"), p_cor, width = 10, height = 8, dpi = 300)

write_csv(cor_data, file.path(RESULTS_DIR, "correlation_data.csv"))

message("\n=== Analyse GA terminée ===")
message("Figures: ", RESULTS_DIR)
