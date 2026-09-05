# ============================================================================
# custom_functions.R — Fonctions utilitaires personnalisées
# ============================================================================

#' Formater un nombre avec séparateur de milliers
#' @param x Nombre à formater
#' @param digits Nombre de décimales
#' @return String formaté
format_number <- function(x, digits = 2) {
  formatC(round(x, digits), format = "f", big.mark = ",", digits = digits)
}

#' Calculer la bioavailability
#' @param auc_oral AUC orale
#' @param auc_iv AUC intraveineuse
#' @param dose_oral Dose orale (mg)
#' @param dose_iv Dose IV (mg)
#' @return Bioavailability (%)
calc_bioavailability <- function(auc_oral, auc_iv, dose_oral, dose_iv) {
  ((auc_oral / dose_oral) / (auc_iv / dose_iv)) * 100
}

#' Calculer Cmax/MIC ratio
#' @param cmax Concentration maximale (mg/L)
#' @param mic Concentration minimale inhibitrice (mg/L)
#' @return Ratio Cmax/MIC
calc_cmax_mic <- function(cmax, mic = 1) {
  cmax / mic
}

#' Calculer AUC/MIC ratio
#' @param auc Aire sous la courbe (mg·h/L)
#' @param mic MIC (mg/L)
#' @return Ratio AUC/MIC
calc_auc_mic <- function(auc, mic = 1) {
  auc / mic
}

#' Vérifier l'atteinte des cibles PD
#' @param cmax Cmax (mg/L)
#' @param auc AUC (mg·h/L)
#' @param mic MIC (mg/L)
#' @return Liste avec les résultats
check_pd_targets <- function(cmax, auc, mic = 1) {
  cmax_mic <- cmax / mic
  auc_mic  <- auc / mic

  list(
    Cmax_MIC         = cmax_mic,
    AUC_MIC          = auc_mic,
    target_Cmax      = cmax_mic >= 8,
    target_AUC       = auc_mic >= 80,
    safe_Cmax        = cmax <= 30,
    all_targets_met  = cmax_mic >= 8 & auc_mic >= 80 & cmax <= 30
  )
}

#' Créer un tableau récapitulatif
#' @param data Liste de données
#' @return Tibble formaté
create_summary_table <- function(data) {
  tibble::tibble(
    Parameter = names(data),
    Value     = as.character(unlist(data))
  )
}

#' Sauvegarder un graphique avec paramètres par défaut
#' @param p Objet ggplot
#' @param filename Nom du fichier
#' @param width Largeur en pouces
#' @param height Hauteur en pouces
save_default_plot <- function(p, filename, width = 8, height = 6) {
  ggsave(
    filename = file.path("03_PBPK_MODELING/results/figures", filename),
    plot     = p,
    width    = width,
    height   = height,
    dpi      = 300,
    bg       = "white"
  )
  message("Graphique sauvegardé: ", filename)
}

#' Lire un fichier de résultats PK
#' @param path Chemin vers le fichier CSV
#' @return Tibble avec les résultats
read_pk_results <- function(path) {
  if (!file.exists(path)) {
    warning("Fichier non trouvé: ", path)
    return(NULL)
  }
  readr::read_csv(path, show_col_types = FALSE)
}

#' Arrondir à n chiffres significatifs
#' @param x Nombre
#' @param n Nombre de chiffres significatifs
#' @return Nombre arrondi
signif_round <- function(x, n = 3) {
  round(x, n - floor(log10(abs(x))) - 1)
}
