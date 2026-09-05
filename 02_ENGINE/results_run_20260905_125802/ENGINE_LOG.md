# 02_ENGINE run log — 2026-09-05 13:04:11

- **Root:** `/Users/kalo/TOBRAMYCIN PROJECT/002 - build finale`
- **Rscript:** `/Library/Frameworks/R.framework/Resources/bin/Rscript`
- **Out:** `/Users/kalo/TOBRAMYCIN PROJECT/002 - build finale/02_ENGINE/results_run_20260905_125802` (non-destructive)
- **Figures:** ON
- **Steps:** 11

## Status

```
                                               step exit seconds
1                   02_ENGINE/scripts/00_ga_setup.R    0     0.8
2                     02_ENGINE/scripts/03_ga_run.R    0    12.7
3         02_ENGINE/scripts/10_nsga2_optimization.R    0   338.5
4        02_ENGINE/scripts/04_ga_results_analysis.R    0     1.8
5            02_ENGINE/scripts/11_pareto_analysis.R    0     3.1
6     02_ENGINE/scripts/12_sensitivity_validation.R    0     3.3
7           02_ENGINE/scripts/05_ga_visualization.R    0     3.2
8        02_ENGINE/scripts/06_comparison_analysis.R    0     1.3
9  02_ENGINE/scripts/07_manufacturing_feasibility.R    0     1.4
10    02_ENGINE/scripts/08_regulatory_feasibility.R    0     1.2
11        02_ENGINE/scripts/13_manuscript_figures.R    0     2.3
```

## Manifest

- `ENGINE_MANIFEST.csv` : 51 artifacts
- Total bytes: 11345816

## Cross-check

- Exploratory F platform 34.0% (TOB-161, 551 mg, ×20) vs PK-Sim 34.6% (Δ1.9%) — see `03_PKSIM/docs/06_legacy_vs_pksim.md`
- Definitive: `04_RESULTS/ga` (PK-Sim NSGA-II 100×100, corner ×125 F96 97.1%)
- Legacy: `02_ENGINE/results_legacy/` untouched (provenance)

