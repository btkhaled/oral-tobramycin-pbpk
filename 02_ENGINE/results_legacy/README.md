# Legacy results (v0.1 — exploratory custom engine, 02_ENGINE)

**Status: superseded by PK-Sim (`04_RESULTS/` / `03_PKSIM/`) and retained for provenance.**

These outputs were produced by the exploratory pipeline of project v0.1: a hand-rolled
2-compartment + transit + Hill PK engine (archived in `02_ENGINE/archive_legacy/engine_tobramycin.R`)
driven by a classical GA (pop 100 × 200 gen) and a custom NSGA-II (pop 200 × gen 300)
over a 10-gene formulation chromosome (cap logP now fixed to **+1.6** in `02_ENGINE/config/`,
legacy 3.0 was artefact ×313).

Key files:

| File | Content | Note |
|---|---|
| `manuscript_table_final.csv` | top-10 formulations (TOB-161 …) | F 34.0% platform, Cmax 9.5, AUC/MIC 32.1 |
| `pareto_front_data.csv` | 200 non-dominated solutions (54K) | Exploratory Pareto, dose 530-1000, F 25-34% |
| `top10_advanced.csv` | PK detail of the top-10 | Via `02_ENGINE/scripts/10_nsga2_optimization.R` |
| `global_summary.csv` | PK + cost + regulatory per candidate | mfg $4.30 grade B, 505(b)(2) 7y $4.8M |
| `TOP_10_CANDIDATES/candidate_01..10/` | 10 profiles (4 files each) | e.g. `candidate_01/profile.md` 28.4% 999mg |

**Cross-check with PK-Sim:** platform bioavailability of the recommended candidate (F = 34.0 %)
is confirmed by the PK-Sim engine at the same permeability multiplier (F = 34.6 %)
— see `03_PKSIM/docs/06_legacy_vs_pksim.md` (Δ0.6 pp, 1.9% relative).
Disposition-specific metrics from this legacy run (Cmax, troughs) are **not** transferable and defer to `03_PKSIM` / `04_RESULTS/`.

**Contrast with definitive GA:** `02_ENGINE` pop200×300 (5.7 min, 200 Pareto) vs
`03_PKSIM/ga/run_ga.R` pop100×100 (1–2 h, checkpoint_gen010..100, corner ×125 F96 97.1%).
Legacy is the hypothesis generator; PK-Sim is the whole-body ACAT validator.
See `02_ENGINE/README.md` budget table and `06_MANUSCRIPT/ch05 vs ch07`.
Via symlinks: `results/legacy_v01` → `02_ENGINE/results_legacy` → `04_RESULTS/legacy_v01`.
