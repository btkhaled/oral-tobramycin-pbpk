# ============================================================================
# 08_regulatory_feasibility.R — Analyse réglementaire
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
top10_sum <- read_csv(file.path(RESULTS_DIR, "manufacturing_summary.csv"))

message("=== Analyse réglementaire ===")

# --- 1. Classification FDA -----------------------------------------------------
regulatory_framework <- tibble(
  rank = 1:10,
  formulation = map_chr(top10, function(x) paste0("#", x$rank)),

  # Classification probable
  fda_category = map_chr(top10, function(x) {
    f <- x$formulation
    if (f$polymer > 0 && f$pe_conc > 0) {
      "505(b)(2)"  # Nouvelle formulation, données de référence
    } else if (f$chitosan == 1 || f$enteric == 1) {
      "505(b)(2)"
    } else {
      "505(j)"  # Generic (si bioéquivalence démontrée)
    }
  }),

  # Type d'essai clinique requis
  clinical_trial = map_chr(top10, function(x) {
    f <- x$formulation
    if (f$polymer > 0 || f$pe_conc > 20) {
      "Phase II (PK/Bioéquivalence)"
    } else {
      "Phase I (tolérance) + BE"
    }
  }),

  # Durée estimée (années)
  est_years = map_dbl(top10, function(x) {
    f <- x$formulation
    base <- 4  # Generic
    if (f$polymer > 0) base <- base + 1
    if (f$chitosan == 1) base <- base + 1
    if (f$pe_conc > 20) base <- base + 1
    base
  }),

  # Coût réglementaire estimé (M USD)
  est_cost_m_usd = map_dbl(top10, function(x) {
    f <- x$formulation
    base <- 2.0
    if (f$polymer > 0) base <- base + 1.5
    if (f$chitosan == 1) base <- base + 0.8
    if (f$pe_conc > 20) base <- base + 0.5
    base
  }),

  # Risk level
  risk_level = map_chr(top10, function(x) {
    f <- x$formulation
    if (f$polymer > 0 && f$pe_conc > 0 && f$chitosan == 1) {
      "Élevé"
    } else if (f$polymer > 0 || f$pe_conc > 0) {
      "Modéré"
    } else {
      "Faible"
    }
  }),

  # Études non cliniques requises
  preclinical = map_chr(top10, function(x) {
    f <- x$formulation
    studies <- c("Toxicologie aiguë")
    if (f$polymer > 0) studies <- c(studies, "Biodistribution NPs")
    if (f$pe_conc > 0) studies <- c(studies, "Toxicité muqueuse GI")
    if (f$chitosan == 1) studies <- c(studies, "Sécurité chitosane")
    paste(studies, collapse = ", ")
  }),

  # Conteneurs formulation
  container = map_chr(top10, function(x) {
    f <- x$formulation
    if (f$enteric == 1) {
      "Gélule entérique (HPMC-AS)"
    } else if (f$polymer > 0) {
      "Gélule en gélatine"
    } else {
      "Comprimé pelliculé"
    }
  })
)

# --- 2. Tableau synthèse --------------------------------------------------------
message("\n=== Tableau Réglementaire ===")
print(regulatory_framework %>%
  select(rank, fda_category, clinical_trial, est_years, est_cost_m_usd, risk_level))

# --- 3. Risques par formulation ------------------------------------------------
risk_analysis <- tibble(
  rank = 1:10,
  formulation = map_chr(top10, function(x) paste0("#", x$rank)),

  # Risques spécifiques
  risk_1 = map_chr(top10, function(x) {
    f <- x$formulation
    if (f$polymer > 0) "NPs:/toxicité pulmonaire si inhalation accidentelle" else "Risque minimal"
  }),

  risk_2 = map_chr(top10, function(x) {
    f <- x$formulation
    if (f$pe_conc > 0) "PE: irritation GI potentielle" else "Risque minimal"
  }),

  risk_3 = map_chr(top10, function(x) {
    f <- x$formulation
    if (f$chitosan == 1) "Chitosane: variabilité source (degré déacétylation)" else "Risque minimal"
  }),

  # Stratégie d'atténuation
  mitigation = map_chr(top10, function(x) {
    f <- x$formulation
    strategies <- c()
    if (f$polymer > 0) strategies <- c(strategies, "Étude toxicologie NPs (30j)")
    if (f$pe_conc > 0) strategies <- c(strategies, "Essai tolérance GI (escalade dose)")
    if (f$chitosan == 1) strategies <- c(strategies, "Contrôle qualité chitosane (certificat CofA)")
    if (length(strategies) == 0) strategies <- "Protocole standard"
    paste(strategies, collapse = "; ")
  }),

  # Priorité de développement
  priority = case_when(
    top10_sum$fitness >= 0.7 & top10_sum$feasibility_score >= 60 ~ "Haute",
    top10_sum$fitness >= 0.5 & top10_sum$feasibility_score >= 40 ~ "Moyenne",
    TRUE ~ "Basse"
  )
)

# --- 4. Visualisations ---------------------------------------------------------
p_reg <- regulatory_framework %>%
  ggplot(aes(x = reorder(factor(rank), est_years), y = est_years, fill = risk_level)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0(est_years, " ans")), hjust = -0.1, size = 3.5) +
  scale_fill_manual(values = c("Faible" = "#4CAF50", "Modéré" = "#FFC107", "Élevé" = "#F44336"),
                    name = "Niveau risque") +
  coord_flip() +
  scale_y_continuous(name = "Durée estimée (ans)") +
  labs(
    title = "Durée de Développement Réglementaire",
    subtitle = "Estimation basée sur la complexité formulation",
    x = "Ranking"
  )

print(p_reg)

p_cost_reg <- regulatory_framework %>%
  ggplot(aes(x = reorder(factor(rank), est_cost_m_usd), y = est_cost_m_usd, fill = fda_category)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = paste0("$", est_cost_m_usd, "M")), hjust = -0.1, size = 3.5) +
  scale_fill_manual(values = c("505(b)(2)" = "#1976D2", "505(j)" = "#388E3C"),
                    name = "Catégorie FDA") +
  coord_flip() +
  scale_y_continuous(name = "Coût réglementaire estimé (M USD)") +
  labs(
    title = "Coût du Développement Réglementaire",
    subtitle = "Incluant études non cliniques et cliniques",
    x = "Ranking"
  )

print(p_cost_reg)

# --- 5. Tableau récapitulatif global ------------------------------------------
global_summary <- top10_sum %>%
  left_join(regulatory_framework, by = "rank") %>%
  left_join(risk_analysis %>% select(rank, priority), by = "rank") %>%
  select(rank, F_oral, Cmax_MIC, AUC_MIC, fitness,
         estimated_cost_usd, feasibility_grade,
         fda_category, est_years, est_cost_m_usd, risk_level, priority) %>%
  mutate(across(where(is.numeric), ~round(., 2)))

message("\n=== Tableau Global (PK + Manufacturing + Regulatory) ===")
print(global_summary)

# --- Save -----------------------------------------------------------------------
ggsave(file.path(RESULTS_DIR, "regulatory_timeline.png"), p_reg, width = 8, height = 5, dpi = 300)
ggsave(file.path(RESULTS_DIR, "regulatory_cost.png"), p_cost_reg, width = 8, height = 5, dpi = 300)

write_csv(regulatory_framework, file.path(RESULTS_DIR, "regulatory_framework.csv"))
write_csv(risk_analysis, file.path(RESULTS_DIR, "risk_analysis.csv"))
write_csv(global_summary, file.path(RESULTS_DIR, "global_summary.csv"))

message("\n=== Analyse réglementaire terminée ===")
message("Fichiers: ", RESULTS_DIR)
