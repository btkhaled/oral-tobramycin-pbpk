# 04_RESULTS — Simulation Outputs (TOUT)

> **Canon:** `04_RESULTS/` is the single source of truth for all PK-Sim outputs.
> Every simulation writes here in real time via symlinks `pksim→03_PKSIM`, `results→04_RESULTS`, `data→01_COMPOUND_DATA`.
> `03_PKSIM/results_run_*/` is a timestamped mirror for provenance (see `03_PKSIM/run_pksim.R` dual write).

## Structure (90 artifacts, `04_RESULTS/MANIFEST.csv` 90, md5 100%)

| Subfolder | Content | Key files |
|---|---|---|
| `validation/` (3) | S00 gate 6/6 PASS | `iv_validation_gate.csv` 27.55/34.83/102.7/0.033/2.04/99.4% + `iv_results_volunteer1.csv` 242 rows + `iv_validation_profile.png` |
| `ga/` (15) | NSGA-II in-loop pop100×100 seed42 (or 20×10 smoke) | `checkpoint_gen010..100.rds` (10, every 10) + `convergence.csv` 100 rows + `pareto_front.csv` 97.1% + `top10.csv` + `nsga2_final.rds` + `pareto_population.rds` |
| `studies/` (33) | S01-S09 | S01 20× dose×CLCR, S02 11 pts Pint0 3e-9, S03 100 ICRP, S04 OAT, S05 15 vs 60, S06 QD/BID/TID, S07 winner 944 mg x79, S08 9×8 reqmap, S09 1.7M samples |
| `molecule_A/B/` (12+12) | Batteries B1-B10 true 7-day | B1 identity, B2 NCA 1.9M, B3 dose-prop, B4 steady, B5 MIC, B6 pop 100, B7 renal /112.5, B8 food 15/90, B9 OAT, B10 IV |
| `legacy_v01/` (5) | Exploratory 2-cpt (34.0% vs 34.6% Δ1.9%) | `pareto_front_data.csv` 200, `top10_advanced.csv` |

## Windows

- **F24 vs F96:** S03/S04/S05 use `AUC24` (24h, truncates flip-flop) vs S02/S06/S07/S08/fitness use `96h` (0-5760 min, extent) — dual convention `03_PKSIM/docs/05` + `docs/07`.
- **Dose:** 550 mg (S04-06, S03) vs 944 mg winner (S07) vs 993 mg cap (S08) vs 1000 mg (B) — see `S07_dose_scan.csv`.

## How to reproduce

```bash
Rscript 03_PKSIM/run_pksim.R                  # full 100×100, 1-2h, 10 checkpoints, 90 artifacts → 04_RESULTS/
Rscript 03_PKSIM/run_pksim.R --pop 20 --gen 10 # quick, 1 checkpoint, 31s GA
Rscript 03_PKSIM/run_pksim.R --skip-ga        # reuse 04_RESULTS/ga/ (~2 min)
ls 04_RESULTS/MANIFEST.csv && cat 04_RESULTS/validation/iv_validation_gate.csv
```

See also `03_PKSIM/PKSIM_SUMMARY.md` + `03_PKSIM/docs/04_study_design.md` + `06_MANUSCRIPT/appendices/appK_traceability.tex`.
