# ============================================================================
# 12_sensitivity_validation.R — Sensibilité + Validation croisée
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

message("=== Analyse de Sensibilité + Validation ===")

# --- Charger le meilleur candidat ---------------------------------------------
nsga <- readRDS(file.path(RESULTS_DIR, "nsga2_output.rds"))
best_candidate <- nsga$top10_advanced[[1]]
best_form <- best_candidate$formulation

message("Candidat #1 (Pareto rank ", best_candidate$pareto_rank, ")")
message("Formulation: ", paste(names(best_form), "=", round(unlist(best_form), 2), collapse = ", "))

# --- 1. Sensibilité One-At-A-Time (OAT) --------------------------------------
message("\n--- Sensibilité OAT ---")

param_names <- names(best_form)
sensitivity_results <- list()

for (p in 1:length(param_names)) {
  pname <- param_names[p]
  base_val <- best_form[[pname]]

  # Définir les variations
  if (PARAM_BOUNDS$type[p] == "binary") {
    test_vals <- c(0, 1)
  } else {
    range_val <- PARAM_BOUNDS$max_val[p] - PARAM_BOUNDS$min_val[p]
    test_vals <- seq(
      max(PARAM_BOUNDS$min_val[p], base_val - range_val * 0.3),
      min(PARAM_BOUNDS$max_val[p], base_val + range_val * 0.3),
      length.out = 7
    )
  }

  oat_results <- map_dbl(test_vals, function(v) {
    modified_form <- unlist(best_form)
    modified_form[p] <- v

    # Vérifier contraintes SEDDS
    if (sum(modified_form[3:5]) > 100) return(NA_real_)

    pk_params <- estimate_pk_advanced(
      modified_form[1], modified_form[2], modified_form[3], modified_form[4],
      modified_form[5], modified_form[6], modified_form[7],
      round(modified_form[8]), round(modified_form[9]), modified_form[10]
    )

    pk_data <- solve_pk_2comp(
      dose_mg = modified_form[10], F_oral = pk_params$F_oral,
      Ka = pk_params$Ka, CL = pk_params$CL, V1 = pk_params$V1,
      Q = pk_params$Q, V2 = pk_params$V2, k_transit = pk_params$k_transit,
      t_end = 24, dt = 0.05
    )

    pkpd <- calc_pkpd_metrics(pk_data, MIC = 1)
    return(pkpd$AUC_MIC)
  })

  sensitivity_results[[pname]] <- tibble(
    parameter = pname,
    test_value = test_vals,
    AUC_MIC = oat_results,
    delta_AUC_MIC = oat_results - best_candidate$AUC_MIC,
    sensitivity_index = max(abs(oat_results - best_candidate$AUC_MIC), na.rm = TRUE) / best_candidate$AUC_MIC
  )
}

# Combiner et trier par sensibilité
sens_all <- bind_rows(sensitivity_results)
sens_ranking <- sens_all %>%
  group_by(parameter) %>%
  summarise(max_sensitivity = max(sensitivity_index, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(max_sensitivity))

message("\n=== Indice de sensibilité (AUC/MIC) ===")
print(sens_ranking)

# Tornado plot
p_tornado <- sens_all %>%
  filter(!is.na(AUC_MIC)) %>%
  ggplot(aes(x = AUC_MIC, y = reorder(parameter, sensitivity_index))) +
  geom_vline(xintercept = best_candidate$AUC_MIC, linetype = "dashed", color = "red") +
  geom_point(aes(color = test_value), size = 3, alpha = 0.8) +
  scale_color_viridis(option = "turbo", name = "Valeur paramètre") +
  labs(
    title = "Analyse de Sensibilité — AUC/MIC",
    subtitle = "One-At-A-Time (OAT) sur le meilleur candidat",
    x = "AUC/MIC",
    y = NULL
  )

print(p_tornado)

# Spider plot de sensibilité
p_spider_sens <- sens_all %>%
  filter(!is.na(AUC_MIC)) %>%
  group_by(parameter) %>%
  mutate(AUC_MIC_norm = (AUC_MIC - min(AUC_MIC, na.rm = TRUE)) /
                          (max(AUC_MIC, na.rm = TRUE) - min(AUC_MIC, na.rm = TRUE) + 1e-10)) %>%
  ungroup() %>%
  ggplot(aes(x = test_value, y = AUC_MIC_norm, color = parameter, group = parameter)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_color_viridis_d(option = "turbo", name = "Paramètre") +
  labs(
    title = "Sensibilité Relative — AUC/MIC normalisé",
    x = "Valeur du paramètre (normalisée)",
    y = "AUC/MIC normalisé"
  ) +
  theme(legend.position = "right")

print(p_spider_sens)

# --- 2. Validation croisée (k-fold) ------------------------------------------
message("\n--- Validation croisée (k=5) ---")

# Simuler de la variabilité inter-individuelle
set.seed(123)
n_cv <- 50  # Simulations
cv_results <- list()

for (k in 1:n_cv) {
  # Variation aléatoire des paramètres (±20%)
  noise <- rnorm(10, 0, 0.20)
  perturbed_form <- unlist(best_form)

  # Seulement les paramètres continus
  for (p in 1:10) {
    if (PARAM_BOUNDS$type[p] == "continuous") {
      perturbed_form[p] <- perturbed_form[p] * (1 + noise[p])
      perturbed_form[p] <- max(PARAM_BOUNDS$min_val[p], min(PARAM_BOUNDS$max_val[p], perturbed_form[p]))
    }
  }

  # Vérifier contraintes
  if (sum(perturbed_form[3:5]) > 100) next

  pk_params <- estimate_pk_advanced(
    perturbed_form[1], perturbed_form[2], perturbed_form[3], perturbed_form[4],
    perturbed_form[5], perturbed_form[6], perturbed_form[7],
    round(perturbed_form[8]), round(perturbed_form[9]), perturbed_form[10]
  )

  pk_data <- solve_pk_2comp(
    dose_mg = perturbed_form[10], F_oral = pk_params$F_oral,
    Ka = pk_params$Ka, CL = pk_params$CL, V1 = pk_params$V1,
    Q = pk_params$Q, V2 = pk_params$V2, k_transit = pk_params$k_transit,
    t_end = 24, dt = 0.05
  )

  pkpd <- calc_pkpd_metrics(pk_data, MIC = 1)

  cv_results[[k]] <- tibble(
    run = k,
    F_oral = pk_params$F_oral,
    Cmax = pkpd$Cmax,
    AUC = pkpd$AUC,
    Cmax_MIC = pkpd$Cmax_MIC,
    AUC_MIC = pkpd$AUC_MIC,
    fCT = pkpd$fCT_above_MIC
  )
}

cv_df <- bind_rows(cv_results)

message("\n=== Résultats Validation Croisée ===")
cv_summary <- cv_df %>%
  summarise(
    F_mean = mean(F_oral), F_sd = sd(F_oral), F_cv = sd(F_oral)/mean(F_oral)*100,
    Cmax_mean = mean(Cmax), Cmax_sd = sd(Cmax),
    AUC_MIC_mean = mean(AUC_MIC), AUC_MIC_sd = sd(AUC_MIC), AUC_MIC_cv = sd(AUC_MIC)/mean(AUC_MIC)*100,
    Cmax_MIC_mean = mean(Cmax_MIC), Cmax_MIC_sd = sd(Cmax_MIC),
    fCT_mean = mean(fCT), fCT_sd = sd(fCT)
  )

print(cv_summary)

# Boxplot validation
p_cv <- cv_df %>%
  select(F_oral, Cmax_MIC, AUC_MIC, fCT) %>%
  mutate(across(everything(), ~. / max(.))) %>%
  pivot_longer(everything(), names_to = "metric", values_to = "normalized_value") %>%
  mutate(metric = case_when(
    metric == "F_oral"     ~ "F (%)",
    metric == "Cmax_MIC"   ~ "Cmax/MIC",
    metric == "AUC_MIC"    ~ "AUC/MIC",
    metric == "fCT"         ~ "fCT > MIC (%)"
  )) %>%
  ggplot(aes(x = metric, y = normalized_value, fill = metric)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 1) +
  scale_fill_brewer(palette = "Set2", guide = "none") +
  labs(
    title = "Validation Croisée — Distribution des Métriques",
    subtitle = paste(n_cv, "simulations avec variabilité ±20%"),
    x = NULL, y = "Valeur normalisée"
  )

print(p_cv)

# --- 3. Distribution des métriques CV ----------------------------------------
p_cv_dist <- cv_df %>%
  select(Cmax_MIC, AUC_MIC) %>%
  pivot_longer(everything(), names_to = "metric", values_to = "value") %>%
  ggplot(aes(x = value, fill = metric)) +
  geom_density(alpha = 0.5) +
  geom_vline(data = tibble(metric = c("Cmax_MIC", "AUC_MIC"), target = c(8, 80)),
             aes(xintercept = target, color = metric), linetype = "dashed") +
  scale_fill_manual(values = c("#1976D2", "#388E3C"), name = "Métrique") +
  scale_color_manual(values = c("#D32F2F", "#D32F2F"), guide = "none") +
  labs(
    title = "Distribution des Métriques PK/PD (Validation Croisée)",
    x = "Valeur", y = "Densité"
  )

print(p_cv_dist)

# --- 4. Heatmap variabilité inter-individuelle --------------------------------
# Simulations Monte Carlo
set.seed(456)
n_mc <- 200
mc_results <- list()

for (i in 1:n_mc) {
  # Variation log-normale des paramètres physiologiques
  CL_var <- 5.5 * rlnorm(1, 0, 0.3)   # ±30%
  V1_var <- 17 * rlnorm(1, 0, 0.2)
  V2_var <- 16 * rlnorm(1, 0, 0.2)
  Q_var <- 2.4 * rlnorm(1, 0, 0.2)

  pk_params <- estimate_pk_advanced(
    best_form$logP, best_form$particle_size, best_form$surfactant,
    best_form$cosurfactant, best_form$oil, best_form$pe_conc,
    best_form$polymer, best_form$chitosan, best_form$enteric, best_form$dose
  )

  pk_data <- solve_pk_2comp(
    dose_mg = best_form$dose, F_oral = pk_params$F_oral,
    Ka = pk_params$Ka, CL = CL_var, V1 = V1_var,
    Q = Q_var, V2 = V2_var, k_transit = pk_params$k_transit,
    t_end = 24, dt = 0.05
  )

  pkpd <- calc_pkpd_metrics(pk_data, MIC = 1)

  mc_results[[i]] <- tibble(
    run = i, CL = CL_var, V1 = V1_var, V2 = V2_var,
    F_oral = pk_params$F_oral, Cmax = pkpd$Cmax,
    AUC_MIC = pkpd$AUC_MIC, Cmax_MIC = pkpd$Cmax_MIC
  )
}

mc_df <- bind_rows(mc_results)

# Tornado monte carlo
p_mc_tornado <- mc_df %>%
  summarise(
    CL_cor = cor(CL, AUC_MIC),
    V1_cor = cor(V1, AUC_MIC),
    V2_cor = cor(V2, AUC_MIC)
  ) %>%
  pivot_longer(everything(), names_to = "parameter", values_to = "correlation") %>%
  ggplot(aes(x = abs(correlation), y = reorder(parameter, correlation), fill = correlation)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = round(correlation, 3)), hjust = -0.1, size = 3.5) +
  scale_fill_gradient2(low = "#D32F2F", mid = "white", high = "#1976D2", midpoint = 0) +
  labs(
    title = "Sensibilité Monte Carlo — Paramètres Physiologiques",
    subtitle = paste(n_mc, " simulations (variabilité inter-individuelle)"),
    x = "Corrélation absolue avec AUC/MIC",
    y = NULL
  ) +
  theme(legend.position = "none")

print(p_mc_tornado)

# --- Save -----------------------------------------------------------------------
ggsave(file.path(RESULTS_DIR, "sensitivity_tornado.png"), p_tornado, width = 10, height = 6, dpi = 300)
ggsave(file.path(RESULTS_DIR, "sensitivity_spider.png"), p_spider_sens, width = 10, height = 7, dpi = 300)
ggsave(file.path(RESULTS_DIR, "validation_cv_boxplot.png"), p_cv, width = 8, height = 5, dpi = 300)
ggsave(file.path(RESULTS_DIR, "validation_cv_distribution.png"), p_cv_dist, width = 10, height = 5, dpi = 300)
ggsave(file.path(RESULTS_DIR, "monte_carlo_tornado.png"), p_mc_tornado, width = 8, height = 4, dpi = 300)

write_csv(sens_all, file.path(RESULTS_DIR, "sensitivity_data.csv"))
write_csv(cv_df, file.path(RESULTS_DIR, "validation_cv_data.csv"))
write_csv(mc_df, file.path(RESULTS_DIR, "monte_carlo_data.csv"))

message("\n=== Sensibilité + Validation terminées ===")
