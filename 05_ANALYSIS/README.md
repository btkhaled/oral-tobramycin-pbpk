# 05_ANALYSIS — Data Analysis (derived from 04_RESULTS)

This folder holds **derived** figures and tables for the manuscript and slides.
Raw simulation outputs live in `04_RESULTS/` (validation, studies, ga, molecule_A/B).
`05_ANALYSIS/` re-exports them in publication-ready form.

- `figures/` ← `04_RESULTS/studies/*.png` + `04_RESULTS/validation/*.png` (+ manuscript/figures duplicates)
- `tables/`  ← `04_RESULTS/studies/*.csv` + `04_RESULTS/ga/*.csv` → `06_MANUSCRIPT/tables/*.tex`

Regenerate via `run_all.R` (writes `04_RESULTS/MANIFEST.csv`) then copy to `05_ANALYSIS/`.
