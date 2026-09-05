PROJECT := tobramycin_pbpk
R_SCRIPTS := $(wildcard 03_PBPK_MODELING/scripts/*.R)
RESULTS_DIR := 03_PBPK_MODELING/results
FIGURES_DIR := $(RESULTS_DIR)/figures

.PHONY: all setup simulate export clean

all: simulate export

# Setup environment
setup:
	@echo "=== Installation des packages R ==="
	Rscript -e 'install.packages(c("ospsuite", "ggplot2", "dplyr", "tidyr", "readr", "purrr", "stringr", "scales", "jsonlite", "here"), repos="https://cloud.r-project.org")'

# Run all simulation scripts
simulate: setup
	@echo "=== Lancement des simulations ==="
	cd 03_PBPK_MODELING/scripts && \
	Rscript 00_setup.R && \
	Rscript 01_create_compound.R && \
	Rscript 02_iv_simulation.R && \
	Rscript 03_oral_absorption.R && \
	Rscript 04_sensitivity_analysis.R && \
	Rscript 05_oral_vs_iv.R && \
	Rscript 06_food_effect.R && \
	Rscript 07_permeability_exploration.R && \
	Rscript 08_solubility_exploration.R && \
	Rscript 09_dose_optimization.R && \
	Rscript 10_export_results.R
	@echo "=== Simulations terminées ==="

# Export results
export: simulate
	@echo "=== Export des résultats ==="
	ls -la $(RESULTS_DIR)/*.json $(RESULTS_DIR)/*.csv 2>/dev/null || true
	ls -la $(FIGURES_DIR)/*.png 2>/dev/null || true

# Clean results
clean:
	@echo "=== Nettoyage des résultats ==="
	rm -rf $(RESULTS_DIR)/*.csv
	rm -rf $(RESULTS_DIR)/*.json
	rm -rf $(FIGURES_DIR)/*.png
	@echo "=== Nettoyage terminé ==="

# Run single script
run-%:
	cd 03_PBPK_MODELING/scripts && Rscript $*.R

# Show results
show:
	@echo "=== Résultats ==="
	@ls -la $(RESULTS_DIR)/*/
	@echo ""
	@echo "=== Figures ==="
	@ls -la $(FIGURES_DIR)/*.png 2>/dev/null || echo "Pas de figures générées"

# Help
help:
	@echo "Usage:"
	@echo "  make setup      - Installer les packages R"
	@echo "  make simulate   - Lancer toutes les simulations"
	@echo "  make export     - Exporter les résultats"
	@echo "  make clean      - Nettoyer les résultats"
	@echo "  make run-00_setup - Exécuter un script spécifique"
	@echo "  make show       - Afficher les résultats"
	@echo "  make all        - Simuler + Exporter"
