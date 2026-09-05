# 01_load_results.R — Load all 04_RESULTS artifacts (90) + manifest
load_manifest <- function() read.csv(file.path(PROJECT_ROOT, "04_RESULTS/MANIFEST.csv"))
load_validation <- function() list(
  gate = read.csv(file.path(PROJECT_ROOT, "04_RESULTS/validation/iv_validation_gate.csv")),
  profile = read.csv(file.path(PROJECT_ROOT, "04_RESULTS/validation/iv_results_volunteer1.csv"))
)
load_ga <- function() list(
  convergence = read.csv(file.path(PROJECT_ROOT, "04_RESULTS/ga/convergence.csv")),
  pareto = read.csv(file.path(PROJECT_ROOT, "04_RESULTS/ga/pareto_front.csv")),
  top10 = read.csv(file.path(PROJECT_ROOT, "04_RESULTS/ga/top10.csv"))
)
# Helper to copy 04 -> 05 with rename
sync_05_from_04 <- function() {
  # figures: 04/studies/*.png + 04/validation/*.png -> 05/figures/ (with rename for manuscript)
  src_figs <- c(
    list.files(file.path(PROJECT_ROOT, "04_RESULTS/studies"), pattern="\\.png$", full.names=TRUE),
    list.files(file.path(PROJECT_ROOT, "04_RESULTS/validation"), pattern="\\.png$", full.names=TRUE)
  )
  for (f in src_figs) file.copy(f, file.path(PROJECT_ROOT, "05_ANALYSIS/figures", basename(f)), overwrite=TRUE)
  # tables: 04/studies/*.csv + 04/ga/*.csv -> 05/tables/
  src_tabs <- c(
    list.files(file.path(PROJECT_ROOT, "04_RESULTS/studies"), pattern="\\.csv$", full.names=TRUE),
    list.files(file.path(PROJECT_ROOT, "04_RESULTS/ga"), pattern="\\.csv$", full.names=TRUE)
  )
  for (f in src_tabs) file.copy(f, file.path(PROJECT_ROOT, "05_ANALYSIS/tables", basename(f)), overwrite=TRUE)
  # validation
  file.copy(file.path(PROJECT_ROOT, "04_RESULTS/validation/iv_validation_gate.csv"),
            file.path(PROJECT_ROOT, "05_ANALYSIS/tables/iv_validation_gate.csv"), overwrite=TRUE)
}
