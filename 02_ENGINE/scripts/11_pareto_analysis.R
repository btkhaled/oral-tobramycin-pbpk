# ============================================================================
# 11_pareto_analysis.R — Analyse du front de Pareto
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

source(file.path(SCRIPTS_DIR, "00_ga_setup.R"), local = FALSE)

message("=== Analyse du Front de Pareto ===")

# Charger résultats NSGA-II
nsga <- readRDS(file.path(RESULTS_DIR, "nsga2_output.rds"))

pareto_details <- nsga$pareto_details
pareto_front   <- nsga$pareto_front
obj_matrix     <- nsga$obj_matrix
pareto_history <- nsga$pareto_history

# --- 1. Pareto Front 3D (F vs Cmax/MIC vs AUC/MIC) --------------------------
pareto_df <- bind_rows(lapply(pareto_details, function(x) {
  tibble(
    rank     = x$pareto_rank,
    F_oral   = x$F_oral * 100,
    Cmax_MIC = x$Cmax_MIC,
    AUC_MIC  = x$AUC_MIC,
    dose     = x$formulation$dose,
    fitness  = x$fitness,
    Cmax     = x$Cmax,
    AUC      = x$AUC,
    Ctrough  = x$Ctrough,
    fCT      = x$fCT,
    logP     = x$formulation$logP,
    particle_size = x$formulation$particle_size,
    surfactant = x$formulation$surfactant,
    cosurfactant = x$formulation$cosurfactant,
    oil      = x$formulation$oil,
    pe_conc  = x$formulation$pe_conc,
    polymer  = x$formulation$polymer,
    chitosan = x$formulation$chitosan,
    enteric  = x$formulation$enteric
  )
}))

# Scatter 2D: F vs AUC/MIC (couleur = Cmax/MIC)
p_pareto_2d <- ggplot(pareto_df, aes(x = F_oral, y = AUC_MIC, color = Cmax_MIC, size = dose)) +
  geom_point(alpha = 0.8) +
  scale_color_viridis(option = "plasma", name = "Cmax/MIC") +
  scale_size_continuous(range = c(2, 8), name = "Dose (mg)") +
  geom_vline(xintercept = 5, linetype = "dashed", color = "gray40", alpha = 0.5) +
  geom_hline(yintercept = 80, linetype = "dashed", color = "gray40", alpha = 0.5) +
  annotate("text", x = 5.5, y = max(pareto_df$AUC_MIC) * 0.95, label = "F = 5%", hjust = 0, size = 3, color = "gray40") +
  annotate("text", x = max(pareto_df$F_oral) * 0.5, y = 83, label = "AUC/MIC = 80", hjust = 0, size = 3, color = "gray40") +
  labs(
    title = "Front de Pareto — Bioavailability vs AUC/MIC",
    subtitle = paste(nrow(pareto_df), "solutions Pareto-optimales"),
    x = "Bioavailability (%)",
    y = "AUC/MIC"
  ) +
  theme(legend.position = "right")

print(p_pareto_2d)

# Scatter 3D simulé: F vs Cmax/MIC vs AUC/MIC ( facet dose ranges)
pareto_df <- pareto_df %>%
  mutate(dose_range = cut(dose, breaks = c(0, 400, 700, 1100), labels = c("200-400mg", "401-700mg", "701-1000mg")))

p_pareto_facet <- ggplot(pareto_df, aes(x = F_oral, y = Cmax_MIC)) +
  geom_point(aes(color = AUC_MIC, size = dose), alpha = 0.8) +
  scale_color_viridis(option = "magma", name = "AUC/MIC") +
  scale_size_continuous(range = c(2, 6), name = "Dose") +
  facet_wrap(~dose_range, scales = "free") +
  geom_hline(yintercept = 8, linetype = "dashed", color = "red", alpha = 0.5) +
  labs(
    title = "Pareto Front par tranche de dose",
    x = "Bioavailability (%)",
    y = "Cmax/MIC"
  )

print(p_pareto_facet)

# --- 2. Distribution des paramètres Pareto -----------------------------------
pareto_params <- bind_rows(lapply(pareto_details, function(x) {
  x$formulation %>% mutate(fitness = x$fitness, F_oral = x$F_oral, AUC_MIC = x$AUC_MIC)
}))

params_long <- pareto_params %>%
  pivot_longer(cols = logP:enteric, names_to = "parameter", values_to = "value")

p_params_dist <- ggplot(params_long, aes(x = parameter, y = value, fill = parameter)) +
  geom_violin(alpha = 0.6, draw_quantiles = c(0.25, 0.5, 0.75)) +
  geom_jitter(width = 0.2, alpha = 0.4, size = 1) +
  facet_wrap(~parameter, scales = "free_y", ncol = 5) +
  labs(
    title = "Distribution des Paramètres — Front de Pareto",
    subtitle = "Violon + points individuels (solutions Pareto)",
    x = NULL, y = "Valeur"
  ) +
  theme(axis.text.x = element_blank(), legend.position = "none")

print(p_params_dist)

# --- 3. Evolution du front de Pareto -----------------------------------------
pareto_evol <- tibble(
  generation = map_dbl(pareto_history, ~.x$gen),
  n_pareto   = map_dbl(pareto_history, ~.x$n_pareto),
  best_F     = map_dbl(pareto_history, ~.x$best_F),
  best_Cmax  = map_dbl(pareto_history, ~.x$best_Cmax),
  best_AUC   = map_dbl(pareto_history, ~.x$best_AUC)
)

p_evol_F <- ggplot(pareto_evol, aes(x = generation, y = best_F * 100)) +
  geom_line(color = "#1976D2", linewidth = 1) +
  geom_point(color = "#0D47A1", size = 2) +
  scale_x_continuous(name = "Génération") +
  scale_y_continuous(name = "F max (%)") +
  labs(title = "Évolution de la Bioavailability Max", subtitle = "Front de Pareto")

p_evol_AUC <- ggplot(pareto_evol, aes(x = generation, y = best_AUC)) +
  geom_line(color = "#388E3C", linewidth = 1) +
  geom_point(color = "#1B5E20", size = 2) +
  scale_x_continuous(name = "Génération") +
  scale_y_continuous(name = "AUC/MIC max") +
  labs(title = "Évolution de l'AUC/MIC Max", subtitle = "Front de Pareto")

print(p_evol_F)
print(p_evol_AUC)

# --- 4. Heatmap Top 10 -------------------------------------------------------
top10_hm <- nsga$top10_adv_summary %>%
  select(pareto_rank, logP, particle_size, surfactant, cosurfactant, oil,
         pe_conc, polymer, dose, F_oral, Cmax_MIC, AUC_MIC, fCT) %>%
  pivot_longer(-pareto_rank, names_to = "parameter", values_to = "value") %>%
  group_by(parameter) %>%
  mutate(value_scaled = (value - min(value)) / (max(value) - min(value) + 1e-10)) %>%
  ungroup()

p_top10_hm <- ggplot(top10_hm, aes(x = factor(pareto_rank), y = parameter, fill = value_scaled)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = round(value, 1)), size = 2.5, color = "black") +
  scale_fill_viridis(option = "C", name = "Normalisé") +
  labs(
    title = "Top 10 NSGA-II — Paramètres et Résultats",
    x = "Rang Pareto", y = NULL
  )

print(p_top10_hm)

# --- 5. Matrice de corrélation Pareto ----------------------------------------
cor_pareto <- cor(pareto_df %>% select(F_oral, Cmax_MIC, AUC_MIC, dose, logP, particle_size,
                                        surfactant, pe_conc, polymer), use = "complete.obs")

cor_long <- as.data.frame(as.table(cor_pareto))
names(cor_long) <- c("Var1", "Var2", "Freq")

p_cor_pareto <- ggplot(cor_long, aes(x = Var1, y = Var2, fill = Freq)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(Freq, 2)), size = 2.5) +
  scale_fill_gradient2(low = "#D32F2F", mid = "white", high = "#1976D2", midpoint = 0) +
  labs(title = "Corrélations — Solutions Pareto", x = NULL, y = NULL) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
        axis.text.y = element_text(size = 8))

print(p_cor_pareto)

# --- Save figures --------------------------------------------------------------
ggsave(file.path(RESULTS_DIR, "pareto_front_2d.png"), p_pareto_2d, width = 10, height = 7, dpi = 300)
ggsave(file.path(RESULTS_DIR, "pareto_facet_dose.png"), p_pareto_facet, width = 12, height = 6, dpi = 300)
ggsave(file.path(RESULTS_DIR, "pareto_params_distribution.png"), p_params_dist, width = 14, height = 8, dpi = 300)
ggsave(file.path(RESULTS_DIR, "pareto_evolution_F.png"), p_evol_F, width = 8, height = 5, dpi = 300)
ggsave(file.path(RESULTS_DIR, "pareto_evolution_AUC.png"), p_evol_AUC, width = 8, height = 5, dpi = 300)
ggsave(file.path(RESULTS_DIR, "pareto_heatmap_top10.png"), p_top10_hm, width = 12, height = 7, dpi = 300)
ggsave(file.path(RESULTS_DIR, "pareto_correlation.png"), p_cor_pareto, width = 10, height = 8, dpi = 300)

write_csv(pareto_df, file.path(RESULTS_DIR, "pareto_front_data.csv"))

message("\n=== Analyse Pareto terminée ===")
message("Figures: ", RESULTS_DIR)
