# 02_ENGINE — GA moteur exploratoire maison (Phase I)

**Rôle :** *hypothesis generator*. Moteur R rapide (2-compartiments + transit + Hill, RK4 dt=0.01h)
qui a forgé l’hypothèse platform 34% (F 34.0% à ×20, TOB-161 550mg Cmax/MIC 9.5 AUC/MIC 32.1)
et son programme d’incertitude complet (OAT, Monte-Carlo n=200, CV ±20%, manufacturing 10 ops $4.30 grade B,
505(b)(2) 7y $4.8M).

Le moteur définitif est `03_PKSIM/` (whole-body ACAT, validé 6/6, calibration Pint0 3e-9 → F0 1.75%,
enhancement cité-borné max ×126.3, NSGA-II in-loop). La cross-validation 34.0% vs 34.6% (Δ1.9% relatif)
est elle-même un résultat (`03_PKSIM/docs/06_legacy_vs_pksim.md`).

## Contenu

- `scripts/00_ga_setup.R` … `13_manuscript_figures.R` (14 scripts, ~3350L) — GA 100×200 + NSGA-II 200×300,
  4 objectifs max[F,Cmax/MIC,AUC/MIC,−dose], SBX ηc20, poly-mut ηm20, pop200×300 ~5.7min.
  Portable: `00_ga_setup.R:22` resolves `PROJECT_ROOT` from the script location (not hard-coded `/Users/kalo/...`).
- `config/parameter_bounds.csv` (canon, cap logP +1.6) + `ga_config.json` (corrigé +1.6, ×126.3, see `03_PKSIM/docs/07`)
- `results_legacy/` — `legacy_v01/` (pareto_front_data 200 sols, top10) + `TOP_10_CANDIDATES/candidate_01..10`
- `archive_legacy/` — `engine_tobramycin.R` (2-cpt ACAT-lite, bug F~70% archivé, ne pas promouvoir) +
  `03_PBPK_MODELING/scripts/00_setup.R`…`10_export_results.R` + `10_CODE_AND_TOOLS/`

## Budgets — exploratory vs definitive

| Engine | Location | Pop × Gen | Pareto | F | Time | Gene cap |
|---|---|---|---|---|---|---|
| Exploratory (02_ENGINE) | `02_ENGINE/scripts/10_nsga2_optimization.R` | 200 × 300 | 200 sols | 34.0% (TOB-161, 551 mg) | ~5.7 min | +1.6 (fixed) |
| Definitive (03_PKSIM) | `03_PKSIM/ga/run_ga.R` | 100 × 100 | corner ×125 | 97.1% (TOBP-001, 1000 mg, F96) | ~1–2 h | +1.6 (measured HIP) |

Legacy 3.0 was artefact ×313 (see `03_PKSIM/docs/07_multiplier_methodology.md`, `06_MANUSCRIPT/appendices/appQ_plausibility_audit.tex`).

## Quickstart — run the whole maison pipeline (non-destructive, with figures, English)

```bash
# Full pipeline — 11 steps, 6 min, writes to timestamped folder (never overwrites results_legacy/)
Rscript 02_ENGINE/run_engine.R                          # 100×200 + 200×300 + analysis + figures

# Smoke test (10s, non-destructive)
Rscript 02_ENGINE/run_engine.R --pop 12 --gen 3         # 12×3 + figures
Rscript 02_ENGINE/run_engine.R --pop 12 --gen 3 --skip-figures  # 12×3, 6 steps, no figures

# Partial + custom out
Rscript 02_ENGINE/run_engine.R --ga-only --pop 50 --gen 20
Rscript 02_ENGINE/run_engine.R --nsga2-only --pop 50 --gen 20
Rscript 02_ENGINE/run_engine.R --out /tmp/my_run --keep-going

# Outputs
ls 02_ENGINE/results_run_*/   # 27 artifacts (skip-figures) or 51 (with figures)
cat 02_ENGINE/results_run_*/ENGINE_LOG.md
cat 02_ENGINE/results_run_*/ENGINE_MANIFEST.csv  # md5
ls 02_ENGINE/results_legacy/  # untouched provenance (v0.1, 200 Pareto, TOP_10)
```

- **Non-destructive:** `ENGINE_OUT` env var → `results_run_TIMESTAMP/` (see `scripts/00_ga_setup.R:35`), legacy untouched.
- **Figures ON by default** (05,06,07,08,13 → 51 artifacts); `--skip-figures` → 6 steps, 27 artifacts, still non-destructive.
- **Help:** `Rscript 02_ENGINE/run_engine.R --help` (works from any cwd, handles `~+~` spaces).
- **Override:** `--pop N` / `--gen G` via `ENGINE_POP`/`ENGINE_GEN` (also `ENGINE_POP_NSGA2`/`ENGINE_GEN_NSGA2`).

## Rejouer pas à pas (optionnel, legacy)

```bash
# From 02_ENGINE/ (portable, no hard-coded path)
Rscript scripts/00_ga_setup.R
Rscript scripts/03_ga_run.R          # GA 100×200
Rscript scripts/10_nsga2_optimization.R  # NSGA-II 200×300 — see config/README.md

# Definitive (PK-Sim, whole-body ACAT) — 1–2 h, 03_PKSIM
Rscript ../03_PKSIM/ga/run_ga.R
```

Les résultats définitifs sont dans `04_RESULTS/` (PK-Sim). Ce dossier est archivé pour traçabilité — cross-check
`03_PKSIM/docs/06_legacy_vs_pksim.md:1` (34.0% vs 34.6% Δ1.9% = validation).
