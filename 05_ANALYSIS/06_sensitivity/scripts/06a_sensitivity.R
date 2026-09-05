# 06a_sensitivity.R — Tornado elasticities (S04 OAT ±20%)
# Portable PROJECT_ROOT (like 02_ENGINE)
if (!exists("PROJECT_ROOT")) {
  this_file <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
  if (is.null(this_file) || !nzchar(this_file)) {
    ca <- commandArgs(trailingOnly = FALSE)
    f <- ca[grep("--file=", ca)]
    if (length(f) > 0) this_file <- sub("--file=", "", f[1])
  }
  this_file <- gsub("~\\+~", " ", this_file)
  if (!is.null(this_file) && nzchar(this_file) && file.exists(this_file)) {
    PROJECT_ROOT <- normalizePath(file.path(dirname(normalizePath(this_file)), "../../.."), mustWork = FALSE)
  } else {
    PROJECT_ROOT <- normalizePath(getwd(), mustWork = FALSE)
    for (i in 1:6) {
      if (dir.exists(file.path(PROJECT_ROOT, "05_ANALYSIS")) && dir.exists(file.path(PROJECT_ROOT, "04_RESULTS"))) break
      PROJECT_ROOT <- dirname(PROJECT_ROOT)
    }
  }
}

source(file.path(PROJECT_ROOT, "05_ANALYSIS/utils/00_setup.R"))
source(file.path(PROJECT_ROOT, "05_ANALYSIS/utils/01_load_results.R"))
s04 <- read.csv(file.path(PROJECT_ROOT, "04_RESULTS/studies/S04_sensitivity.csv"))
p <- ggplot(s04, aes(x = reorder(parameter, elasticity_Cmax), y = elasticity_Cmax, fill = elasticity_Cmax > 0)) +
  geom_col() + coord_flip() + labs(title = "S04 Sensitivity — Cmax Elasticity", x = "", y = "Elasticity") + theme(legend.position = "none")
dir.create(file.path(PROJECT_ROOT, "05_ANALYSIS/06_sensitivity/figures"), showWarnings = FALSE)
ggsave(file.path(PROJECT_ROOT, "05_ANALYSIS/06_sensitivity/figures/s04_sensitivity_tornado.png"), p, width = 7, height = 5, dpi = 300, bg = "white")
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/studies/S04_sensitivity.csv"), file.path(PROJECT_ROOT, "05_ANALYSIS/06_sensitivity/tables/S04_sensitivity.csv"), overwrite = TRUE)
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/studies/S04_sensitivity_raw.csv"), file.path(PROJECT_ROOT, "05_ANALYSIS/06_sensitivity/tables/S04_sensitivity_raw.csv"), overwrite = TRUE)
cat("06_sensitivity done\n")
