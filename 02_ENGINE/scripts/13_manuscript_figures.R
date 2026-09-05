# ============================================================================
# 13_manuscript_figures.R — Figures finales pour le manuscrit
# ============================================================================

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

message("=== Génération des Figures Manuscrit ===")

# Charger résultats
nsga <- readRDS(file.path(RESULTS_DIR, "nsga2_output.rds"))
ga_res <- readRDS(file.path(RESULTS_DIR, "ga_output.rds"))

# --- Figure 1: Profils PK du Top 3 Pareto ------------------------------------
message("\n--- Figure 1: Profils PK Top 3 ---")

top3_profiles <- map_dfr(1:3, function(i) {
  x <- nsga$top10_advanced[[i]]
  x$pk_data %>%
    mutate(
      candidate = paste0("Candidate #", i, " (F=", round(x$F_oral*100, 1),
                          "%, AUC/MIC=", round(x$AUC_MIC, 1), ")")
    )
})

p_fig1 <- ggplot(top3_profiles, aes(x = Time, y = Conc_Central, color = candidate)) +
  geom_line(linewidth = 1.2) +
  geom_hline(yintercept = c(8, 20, 30), linetype = c("dashed", "dotted", "dashed"),
             color = c("#4CAF50", "#FF9800", "#F44336"), alpha = 0.6) +
  annotate("text", x = 23, y = 8.5, label = "MIC = 1 µg/mL", color = "#4CAF50", hjust = 1, size = 3) +
  annotate("text", x = 23, y = 20.5, label = "Cmax toxique", color = "#FF9800", hjust = 1, size = 3) +
  annotate("text", x = 23, y = 30.5, label = "Limite sécurité", color = "#F44336", hjust = 1, size = 3) +
  scale_color_brewer(palette = "Set1", name = "Formulation") +
  scale_x_continuous(name = "Temps (h)", breaks = seq(0, 24, 4)) +
  scale_y_continuous(name = "Concentration plasmatique (mg/L)", limits = c(0, NA)) +
  labs(
    title = "Figure 1. Profils pharmacocinétiques des 3 meilleures formulations",
    subtitle = "Modèle 2-compartiments avec transit GI — Simulations PBPK"
  ) +
  theme(legend.position = "bottom")

print(p_fig1)

# --- Figure 2: Pareto Front 2D -----------------------------------------------
message("\n--- Figure 2: Pareto Front ---")

pareto_df <- bind_rows(lapply(nsga$pareto_details, function(x) {
  tibble(
    F_oral = x$F_oral * 100, Cmax_MIC = x$Cmax_MIC, AUC_MIC = x$AUC_MIC,
    dose = x$formulation$dose, fitness = x$fitness
  )
}))

p_fig2 <- ggplot(pareto_df, aes(x = F_oral, y = AUC_MIC)) +
  geom_point(aes(color = Cmax_MIC, size = dose), alpha = 0.7) +
  scale_color_viridis(option = "plasma", name = "Cmax/MIC") +
  scale_size_continuous(range = c(2, 8), name = "Dose (mg)") +
  geom_vline(xintercept = 5, linetype = "dashed", color = "gray50") +
  geom_hline(yintercept = 80, linetype = "dashed", color = "gray50") +
  annotate("text", x = 6, y = 85, label = "Cible AUC/MIC ≥ 80", size = 3, hjust = 0) +
  annotate("text", x = 5.5, y = max(pareto_df$AUC_MIC)*0.95, label = "F = 5%", size = 3, hjust = 0) +
  labs(
    title = "Figure 2. Front de Pareto — Bioavailability vs AUC/MIC",
    subtitle = paste(nrow(pareto_df), "solutions Pareto-optimales (NSGA-II)")
  ) +
  theme(legend.position = "right")

print(p_fig2)

# --- Figure 3: Comparaison avec la littérature --------------------------------
message("\n--- Figure 3: Comparaison littérature ---")

# Données de référence (IV + natif oral)
ref_data <- tibble(
  formulation = c("IV 400mg (réf.)", "Oral natif (1.5%)", "Candidate #1", "Candidate #2", "Candidate #3"),
  F_oral = c(100, 1.5, nsga$top10_advanced[[1]]$F_oral*100,
             nsga$top10_advanced[[2]]$F_oral*100, nsga$top10_advanced[[3]]$F_oral*100),
  Cmax = c(20, 0.04, nsga$top10_advanced[[1]]$Cmax,
           nsga$top10_advanced[[2]]$Cmax, nsga$top10_advanced[[3]]$Cmax),
  AUC = c(80, 0.12, nsga$top10_advanced[[1]]$AUC,
          nsga$top10_advanced[[2]]$AUC, nsga$top10_advanced[[3]]$AUC),
  type = c("Référence", "Littérature", "Optimisé", "Optimisé", "Optimisé")
)

p_fig3_F <- ggplot(ref_data, aes(x = reorder(formulation, F_oral), y = F_oral, fill = type)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = round(F_oral, 1)), hjust = -0.1, size = 3.5) +
  scale_fill_manual(values = c("Référence" = "#9E9E9E", "Littérature" = "#FF9800", "Optimisé" = "#1976D2")) +
  coord_flip() +
  scale_y_continuous(name = "Bioavailability (%)") +
  labs(title = "Figure 3a. Comparaison des Bioavailability", x = NULL)

p_fig3_Cmax <- ggplot(ref_data, aes(x = reorder(formulation, Cmax), y = Cmax, fill = type)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = round(Cmax, 1)), hjust = -0.1, size = 3.5) +
  geom_hline(yintercept = 8, linetype = "dashed", color = "#4CAF50") +
  scale_fill_manual(values = c("Référence" = "#9E9E9E", "Littérature" = "#FF9800", "Optimisé" = "#1976D2")) +
  coord_flip() +
  scale_y_continuous(name = "Cmax (mg/L)") +
  labs(title = "Figure 3b. Comparaison des Cmax", x = NULL)

library(patchwork)
p_fig3 <- p_fig3_F + p_fig3_Cmax +
  plot_annotation(title = "Figure 3. Comparaison avec les données de référence",
                  subtitle = "Tobramycine IV vs orale native vs formulations optimisées")

print(p_fig3)

# --- Figure 4: Facteurs d'amélioration ---------------------------------------
message("\n--- Figure 4: Facteurs d'amélioration ---")

factors_df <- nsga$top10_advanced[[1]]$factors %>%
  as_tibble() %>%
  pivot_longer(everything(), names_to = "factor", values_to = "enhancement") %>%
  mutate(
    enhancement_pct = (enhancement - 1) * 100,
    factor = case_when(
      factor == "logP"      ~ "HIP (LogP)",
      factor == "PE"        ~ "PE (C10)",
      factor == "NP"        ~ "NPs (mucoadhesion)",
      factor == "chitosan"  ~ "Chitosane",
      factor == "sedds"     ~ "SEDDS",
      factor == "enteric"   ~ "Entérique",
      factor == "size"      ~ "Taille particule",
      factor == "dose"      ~ "Dose",
      TRUE ~ factor
    )
  )

p_fig4 <- ggplot(factors_df, aes(x = reorder(factor, enhancement), y = enhancement, fill = factor)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(round(enhancement*100, 0), "%")), hjust = -0.1, size = 3.5) +
  scale_fill_viridis_d(option = "turbo", guide = "none") +
  coord_flip() +
  scale_y_continuous(name = "Facteur d'enhancement (×1)") +
  labs(
    title = "Figure 4. Contribution de chaque stratégie formulationnelle",
    subtitle = "Candidate #1 — Amélioration par rapport au tobramycine native"
  )

print(p_fig4)

# --- Figure 5: Convergence GA vs NSGA-II -------------------------------------
message("\n--- Figure 5: Convergence comparée ---")

# Convergence simple GA
ga_conv <- tibble(
  generation = map_dbl(ga_res$ga_output, ~.x$gen),
  best_fitness = map_dbl(ga_res$ga_output, ~.x$best),
  type = "GA simple (fitness unique)"
)

# Convergence NSGA-II
nsga_conv <- tibble(
  generation = map_dbl(nsga$pareto_history, ~.x$gen),
  best_fitness = map_dbl(nsga$pareto_history, ~.x$best_AUC),
  type = "NSGA-II (4 objectifs)"
)

p_fig5 <- bind_rows(ga_conv, nsga_conv) %>%
  ggplot(aes(x = generation, y = best_fitness, color = type)) +
  geom_line(linewidth = 1) +
  scale_color_manual(values = c("#FF9800", "#1976D2"), name = "Algorithme") +
  scale_x_continuous(name = "Génération") +
  scale_y_continuous(name = "Performance maximale") +
  labs(
    title = "Figure 5. Comparaison de convergence — GA vs NSGA-II",
    subtitle = "NSGA-II atteint de meilleures solutions en explorant l'espace multi-objectif"
  ) +
  theme(legend.position = "bottom")

print(p_fig5)

# --- Figure 6: Radar Top 3 Pareto ---------------------------------------------
message("\n--- Figure 6: Radar Top 3 ---")

# Normaliser pour radar
radar_data <- nsga$top10_adv_summary %>%
  filter(pareto_rank <= 3) %>%
  mutate(
    F_norm      = F_oral / max(nsga$top10_adv_summary$F_oral),
    CmaxMIC_norm = Cmax_MIC / max(nsga$top10_adv_summary$Cmax_MIC),
    AUCMIC_norm = AUC_MIC / max(nsga$top10_adv_summary$AUC_MIC),
    Safety_norm = 1 - Ctrough / max(nsga$top10_adv_summary$Ctrough),
    fCT_norm    = fCT / 100
  ) %>%
  select(pareto_rank, F_norm, CmaxMIC_norm, AUCMIC_norm, Safety_norm, fCT_norm) %>%
  pivot_longer(-pareto_rank, names_to = "metric", values_to = "value") %>%
  mutate(
    metric = case_when(
      metric == "F_norm"       ~ "Bioavailability",
      metric == "CmaxMIC_norm" ~ "Cmax/MIC",
      metric == "AUCMIC_norm"  ~ "AUC/MIC",
      metric == "Safety_norm"  ~ "Sécurité",
      metric == "fCT_norm"     ~ "Time > MIC"
    ),
    candidate = paste("Candidate", pareto_rank)
  )

p_fig6 <- ggplot(radar_data, aes(x = metric, y = value, fill = candidate, group = candidate)) +
  geom_col(position = "dodge", alpha = 0.7) +
  geom_text(aes(label = round(value, 2)), position = position_dodge(width = 0.9), size = 3, vjust = -0.5) +
  scale_fill_brewer(palette = "Set1", name = "Candidate") +
  scale_y_continuous(name = "Score normalisé", limits = c(0, 1.15)) +
  labs(
    title = "Figure 6. Profil des 3 meilleures formulations Pareto",
    x = NULL
  ) +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))

print(p_fig6)

# --- Save all figures ----------------------------------------------------------
ggsave(file.path(RESULTS_DIR, "fig1_pk_profiles_top3.png"), p_fig1, width = 10, height = 6, dpi = 300)
ggsave(file.path(RESULTS_DIR, "fig2_pareto_front.png"), p_fig2, width = 10, height = 7, dpi = 300)
ggsave(file.path(RESULTS_DIR, "fig3_literature_comparison.png"), p_fig3, width = 14, height = 6, dpi = 300)
ggsave(file.path(RESULTS_DIR, "fig4_enhancement_factors.png"), p_fig4, width = 10, height = 5, dpi = 300)
ggsave(file.path(RESULTS_DIR, "fig5_convergence_comparison.png"), p_fig5, width = 10, height = 5, dpi = 300)
ggsave(file.path(RESULTS_DIR, "fig6_radar_top3.png"), p_fig6, width = 10, height = 6, dpi = 300)

# --- Tableau récapitulatif manuscrit ------------------------------------------
message("\n--- Tableau récapitulatif ---")

manuscript_table <- nsga$top10_adv_summary %>%
  mutate(
    formulation_id = paste0("TOB-", formatC(pareto_rank, width = 2, format = "d", flag = "0")),
    sedds_composition = paste0(round(surfactant), "/", round(cosurfactant), "/", round(oil)),
    enhancement_vs_native = round(F_oral / 0.015, 0)
  ) %>%
  select(formulation_id, logP, particle_size, sedds_composition, pe_conc,
         polymer, chitosan, enteric, dose,
         F_oral, Cmax, AUC_24, Cmax_MIC, AUC_MIC, fCT, Ctrough,
         enhancement_vs_native, fitness) %>%
  mutate(across(where(is.numeric), ~round(., 2)))

write_csv(manuscript_table, file.path(RESULTS_DIR, "manuscript_table_final.csv"))

message("\n=== Figures manuscrit générées ===")
message("Résultats: ", RESULTS_DIR)
message("\n--- Top 3 Résumé ---")
for (i in 1:3) {
  x <- nsga$top10_advanced[[i]]
  message(sprintf(
    "Candidate #%d: F=%.1f%% | Cmax=%.1f mg/L | AUC=%.0f | Cmax/MIC=%.1f | AUC/MIC=%.1f | fCT=%.0f%%",
    i, x$F_oral*100, x$Cmax, x$AUC, x$Cmax_MIC, x$AUC_MIC, x$fCT
  ))
}
