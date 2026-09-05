# ============================================================================
# 06_comparison_analysis.R — Comparaison entre les Top 10 candidats
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

message("=== Analyse comparative des Top 10 ===")

# --- 1. Tableau comparatif multi-critères --------------------------------------
comparison_table <- top10_sum %>%
  mutate(
    score_F       = F_oral / 0.60,
    score_CmaxMIC = ifelse(Cmax_MIC >= 8, 1, Cmax_MIC / 8),
    score_AUCMIC  = ifelse(AUC_MIC >= 80, 1, AUC_MIC / 80),
    penalty_safety = ifelse(Ctrough > 1, Ctrough - 1, 0),
    score_total   = score_F * 0.4 + score_CmaxMIC * 0.25 + score_AUCMIC * 0.25 - penalty_safety * 0.1
  ) %>%
  select(rank, logP, particle_size, surfactant, cosurfactant, oil,
         pe_conc, polymer, chitosan, enteric, dose,
         F_oral, Cmax, AUC, t_half, Ctrough, Cmax_MIC, AUC_MIC,
         score_F, score_CmaxMIC, score_AUCMIC, penalty_safety, score_total)

write_csv(comparison_table, file.path(RESULTS_DIR, "comparison_table.csv"))

# --- 2. Clustering des formulations -------------------------------------------
# Normaliser les paramètres pour clustering
cluster_data <- top10_sum %>%
  select(logP, particle_size, surfactant, cosurfactant, oil,
         pe_conc, polymer, dose) %>%
  scale()

# Distance euclidienne
dist_matrix <- dist(cluster_data, method = "euclidean")

# Classification hiérarchique (Ward)
hc <- hclust(dist_matrix, method = "ward.D2")

# Couper en 3 clusters
clusters <- cutree(hc, k = 3)

top10_sum <- top10_sum %>%
  mutate(cluster = factor(clusters))

p_dendro <- ggplot(
  data.frame(x = 1:10, cluster = factor(clusters[order(hc$order)])),
  aes(x = x, fill = cluster)
) +
  geom_tile(aes(y = 0), width = 0.9, height = 0.5) +
  scale_fill_brewer(palette = "Set2", name = "Cluster") +
  scale_x_continuous(breaks = 1:10, name = "Candidat") +
  labs(
    title = "Classification des Top 10 Formulations",
    subtitle = "Classification hiérarchique (méthode de Ward)",
    y = NULL
  ) +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())

print(p_dendro)

# --- 3. Analyse par cluster ---------------------------------------------------
cluster_summary <- top10_sum %>%
  group_by(cluster) %>%
  summarise(
    n              = n(),
    avg_F          = mean(F_oral),
    avg_Cmax_MIC   = mean(Cmax_MIC),
    avg_AUC_MIC    = mean(AUC_MIC),
    avg_fitness    = mean(fitness),
    candidates     = paste(rank, collapse = ", "),
    .groups = "drop"
  )

message("\n=== Résumé par Cluster ===")
print(cluster_summary)

# --- 4. Spider plot comparaison Top 3 vs moyenne -----------------------------
# (Version simplifiée avec barres groupées)
comparison_metrics <- top10_sum %>%
  filter(rank <= 3) %>%
  select(rank, F_oral, Cmax_MIC, AUC_MIC) %>%
  pivot_longer(-rank, names_to = "metric", values_to = "value") %>%
  mutate(
    metric = case_when(
      metric == "F_oral"     ~ "Bioavailability",
      metric == "Cmax_MIC"   ~ "Cmax/MIC",
      metric == "AUC_MIC"    ~ "AUC/MIC"
    ),
    value_scaled = case_when(
      metric == "Bioavailability" ~ value / max(top10_sum$F_oral),
      metric == "Cmax/MIC"        ~ value / max(top10_sum$Cmax_MIC),
      metric == "AUC/MIC"         ~ value / max(top10_sum$AUC_MIC)
    ),
    rank = paste("Rank", rank)
  )

p_spider <- ggplot(comparison_metrics, aes(x = metric, y = value_scaled, fill = rank, group = rank)) +
  geom_col(position = "dodge", alpha = 0.8) +
  geom_text(aes(label = round(value_scaled, 2)), position = position_dodge(width = 0.9), size = 3, vjust = -0.5) +
  scale_fill_brewer(palette = "Set1", name = "Ranking") +
  scale_y_continuous(name = "Score normalisé", limits = c(0, 1.1)) +
  labs(
    title = "Comparaison Top 3 — Scores Normalisés",
    x = NULL
  ) +
  theme(axis.text.x = element_text(angle = 15, hjust = 1))

print(p_spider)

# --- 5. Matrice de similarité -------------------------------------------------
# Distance de Jaccard pour les paramètres binaires + corrélation pour continus
similarities <- matrix(0, 10, 10)
for (i in 1:10) {
  for (j in 1:10) {
    # Similarité sur paramètres continus (1 - distance normalisée)
    dist_cont <- sum(abs(top10_sum[i, 2:7] - top10_sum[j, 2:7]) /
                     (PARAM_BOUNDS$max_val[1:6] - PARAM_BOUNDS$min_val[1:6])) / 6
    # Similarité sur binaires
    sim_bin <- 1 - mean(top10_sum[i, 8:9] != top10_sum[j, 8:9])
    similarities[i, j] <- (1 - dist_cont) * 0.7 + sim_bin * 0.3
  }
}

sim_df <- as.data.frame(as.table(similarities))
names(sim_df) <- c("Candidate_i", "Candidate_j", "Similarity")

p_sim <- ggplot(sim_df, aes(x = Candidate_i, y = Candidate_j, fill = Similarity)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(Similarity, 2)), size = 2.5) +
  scale_fill_viridis(option = "magma", name = "Similarité") +
  scale_x_discrete(labels = paste0("#", 1:10)) +
  scale_y_discrete(labels = paste0("#", 1:10)) +
  labs(
    title = "Matrice de Similarité — Top 10",
    subtitle = "Combinaison: 70% paramètres continus + 30% binaires"
  )

print(p_sim)

# --- 6. Save results ----------------------------------------------------------
ggsave(file.path(RESULTS_DIR, "cluster_dendrogram.png"), p_dendro, width = 8, height = 3, dpi = 300)
ggsave(file.path(RESULTS_DIR, "top3_comparison.png"), p_spider, width = 8, height = 5, dpi = 300)
ggsave(file.path(RESULTS_DIR, "similarity_matrix.png"), p_sim, width = 8, height = 7, dpi = 300)

write_csv(cluster_summary, file.path(RESULTS_DIR, "cluster_summary.csv"))
write_csv(sim_df, file.path(RESULTS_DIR, "similarity_matrix.csv"))

message("\n=== Analyse comparative terminée ===")
