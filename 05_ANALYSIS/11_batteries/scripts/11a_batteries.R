# 11a_batteries.R — Batteries A×73.9/B×125 B1-B10
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
# Just copy and add summary battery_pta
b6a <- read.csv(file.path(PROJECT_ROOT, "04_RESULTS/molecule_A/B6_population_summary.csv"))
b6b <- read.csv(file.path(PROJECT_ROOT, "04_RESULTS/molecule_B/B6_population_summary.csv"))
p <- ggplot(rbind(data.frame(mol="A", b6a), data.frame(mol="B", b6b)), aes(x = mol, y = PTA_Cmax8, fill = mol)) + geom_col() +
  labs(title = "B6 PTA Cmax≥8 — A 91% vs B 100%", x = "", y = "PTA (%)") + theme(legend.position = "none")
dir.create(file.path(PROJECT_ROOT, "05_ANALYSIS/11_batteries/figures"), showWarnings = FALSE)
ggsave(file.path(PROJECT_ROOT, "05_ANALYSIS/11_batteries/figures/battery_pta.png"), p, width = 6, height = 4, dpi = 300, bg = "white")
# Copy B1-B10
for (mol in c("molecule_A","molecule_B")) {
  for (f in list.files(file.path(PROJECT_ROOT, "04_RESULTS", mol), pattern="*.csv", full.names=TRUE)) {
    file.copy(f, file.path(PROJECT_ROOT, "05_ANALYSIS/11_batteries/tables", paste0(mol,"_", basename(f))), overwrite=TRUE)
  }
}
# Note B7/B9
cat("11_batteries done — note B7 renal /112.5 fixed, B9 OAT degenerate\n")
