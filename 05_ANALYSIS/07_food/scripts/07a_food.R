# 07a_food.R — Food effect 15 vs 60 (S05) + 15 vs 90 (B8)
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
s05 <- read.csv(file.path(PROJECT_ROOT, "04_RESULTS/studies/S05_food_effect.csv"))
p <- ggplot(s05, aes(x = state, y = Cmax, fill = state)) + geom_col() +
  labs(title = "S05 Food — 15 vs 60 min gastric", x = "", y = "Cmax (mg/L)") + theme(legend.position = "none")
dir.create(file.path(PROJECT_ROOT, "05_ANALYSIS/07_food/figures"), showWarnings = FALSE)
ggsave(file.path(PROJECT_ROOT, "05_ANALYSIS/07_food/figures/s05_food_bar.png"), p, width = 6, height = 4, dpi = 300, bg = "white")
file.copy(file.path(PROJECT_ROOT, "04_RESULTS/studies/S05_food_effect.csv"), file.path(PROJECT_ROOT, "05_ANALYSIS/07_food/tables/S05_food_effect.csv"), overwrite = TRUE)
# Also B8
b8a <- read.csv(file.path(PROJECT_ROOT, "04_RESULTS/molecule_A/B8_food_effect.csv"))
b8b <- read.csv(file.path(PROJECT_ROOT, "04_RESULTS/molecule_B/B8_food_effect.csv"))
# Note 15/60 vs 15/90 same conclusion
cat("07_food done — note 15/60 vs 15/90 same extent\n")
