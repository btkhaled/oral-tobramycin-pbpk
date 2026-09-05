# PKSIM Summary — PK-Sim Platform (03_PKSIM)

> **Scope:** the definitive whole-body PBPK platform that carries the thesis. Canon: `model/make_tobramycin_json.py` → `01_COMPOUND_DATA/snapshots/` → `model/tobramycin_*.pkml` → `studies/S00-S09` + `ga/` → `04_RESULTS/` → `06_MANUSCRIPT/ch06-ch07`.
> Portable via `03_PKSIM/env/patch_pksimdb.py` (91 views → tables) and `03_PKSIM/model/make_tobramycin_json.py` (now relative, not `/PKSIM_V2/`).

## 1. Model (→ `model/make_tobramycin_json.py:12`, `model/tobramycin_iv_validated.pkml:1` 63K, `model/tobramycin_oral.pkml:1` 63K)

Amikacin OSP Model Library v12.3.1 snapshot (`01_COMPOUND_DATA/snapshots/Amikacin-Model.json` 78K, via `data/snapshots/` symlink) → tobramycin by deep rename + re-parameterization:
MW 467.515, logP -2.9, fu 0.95, solubility 94000 mg/L @ pH7 (never limiting, BCS III), pKa 7.7/7.8/9.1 (3/5 kept, PK-Sim limit 3 per type, amikacin precedent Claassen2015), renal GFR fraction 1.0 (>90% unchanged), distribution PK-Sim Standard (pKa-independent). Dose 577.5 mg (7 mg/kg ×82.5kg, 30-min infusion) fixed also at simulation altered-params level (Walker 1979).

**Validation S00** `studies/S00_validation_gate.R:12` 6/6 PASS vs Li2021/Hartford/Bauer: peak 27.55 (20-30), Cmax 34.83 (20-32), AUC24 102.7 → CL5.62 (81-105, published 3.27-6.03), trough 0.033 (<1), t½ 2.04 (2-3), renal 99.4% (>90). **Fix:** `make_tobramycin_json.py` now portable (`here.parents[2] / 01_COMPOUND_DATA/snapshots/` + `03_PKSIM/model/` copy, not `/PKSIM_V2/` hard-coded).

## 2. Calibration (→ `studies/S02_oral_calibration.R:12`, `docs/05_calibration_pint.md:1`)

Willmann native `1.945e-12 dm/min` → F≈0.002% (paracellular 0) → override `Specific intestinal permeability (transcellular)`:
`PINT0 3e-9 dm/min → F0 1.75% (24h) / 3.5% (96h flip-flop)` (table: 1e-8 6.63%, 3e-8 19.16%, 1e-7 50.47%, 3e-7 86.48%) — **cross-check** platform ×20 → F34.6% (24h, Cmax4.41 AUC33.8) vs exploratory 34.0% Δ0.6pp 1.9% (`docs/06_legacy_vs_pksim.md:1`).

**Convention:** `F24` = calibration (F0 1.75%), `F96` = extent (F0 3.5%, capturing flip-flop tail 24→96h). `S02` uses 96h (`0-5760 min`), `S03/S04/S05` use 24h AUC24 (flip-flop truncation, documented as `docs/07` dual convention).

## 3. Enhancement — Cited-Bounded Emergent (→ `ga/enhancement_model.R:1`, `docs/07_multiplier_methodology.md:1`, `config/parameter_bounds.csv:1`)

7 factors vs nominal 1.0, graded A/B/C + σ lognormal A0.10/B0.25/C0.40:
logP 1-20 (B, Asad2023, +1.6 measured), SEDDS 0.20-1.60 (B, Muhammad2022/Griesser2017, `f_sedds pmin 1.6 sum/100`), NP 1-1.50 (C, Hill2019/Khaled2026, `1+0.5exp(-(size-50)/150)`), C10 1-1.60 (B, Maher2009/Bohley2024, `1+pe/50*0.6`), polymer 1-1.30 (C), chitosan ×1.15 (C), enteric ×1.10 (galenic) → **product emergent**, `K=log10(20)/4.5=0.289`, cap **+1.6 → ×126.3 F≈96%** (×313 killed, was 99.7% → now sensitivity only, `docs/07` + `studies/S08_requirement_map.R:1` mults 1-313).

**Offsets:** `NOMINAL size500→f_np 1.024≠1.0` (documented), `f_sedds min 0.35 vs table 0.20` unreachable, dual `sigma_log` 0.25-0.40 (display) vs `grade_sigma` A/B/C actually used in `S09` — annotated, not blocking.

Single source `ga/enhancement_model.R` — `decode_chromosome()` → `mult = Pint/PINT0`, used by `ga/fitness_pksim.R`, `ga/run_ga.R`, `studies/molecule_battery.R`.

## 4. Studies S00-S09 (→ `studies/S00-S09`, `docs/04_study_design.md:1`)

| ID | Purpose | Mechanism (key) | Fix/Note |
|---|---|---|---|
| **S00** | IV gate vs Li2021/Hartford/Bauer 577.5 mg 30min | `iv_results_volunteer1.csv` col2 Time col3 µmol/L*MW + trapezoid AUC24, t½=0.693*AUC/Cmax | 6/6 PASS, `ok<-TRUE` stub |
| **S01** | IV dose×CLCR 20 combos (200-800 ×30-150) | `createSimulationBatch` `GFR (specific)` + Dose kg, `GFRspec=0.266*CLCR/112.5` | **Correct** `GFR (specific)`×Vol (plain GFR has no effect), 24h correct for IV |
| **S02** | Pint calibration 11 pts 96h → F0 1.75% | `setOutputInterval 0-5760`, `F=(AUC/dose)/(102.5/577.5)` | **Correct 96h** (flip-flop), PINT0 3e-9 emerges |
| **S03** | n=100 ICRP 20-50y 55-95kg 60%M on platform 550mg ×20 | `createPopulationCharacteristics(European_ICRP_2002)` global Pint×20 | `fT>MIC` not time-weighted, AUC24 truncates vs 96h (doc dual) |
| **S04** | OAT elasticity ±20% Pint/Dose/GFR/fu | `setParameterValues` + `runMetrics` (SensitivityAnalysis empty on CLI) | 24h AUC truncation, but elasticity robust |
| **S05** | Food 15→60 min BCS III extent unchanged | `Gastric emptying time` | Header `0.5h→1.5h` vs code `15→60` (code correct, doc stale) |
| **S06** | Fractionation QD550/BID275/BID550/TID200 + PTA 0.25-4 via superposition 96h | `ss(t)=sum one(t+k*tau) n=14` | **Correct 96h**, dose linear |
| **S07** | Winner rank1 `ga/top10.csv` exhaustive (profile, min dose Cmax≥8, fractionation, PTA, pop, food) | `w_pint=PINT0*w_mult`, `scale=dose/w_dose` | **Fix #3:** `sim_w` now sets **Dose** `w_dose/1e6` (was 550 default) — `studies/S07_winner_characterization.R:121` patched |
| **S08** | Reqmap `mult 1-313` → `F993 Cmax/AUC min_dose` at 993 mg, clamp `F≤100%` | `run_single(mult,dose)` 96h, `pmin(conc,dose/10)` | Most robust 96h + `min(100,F)` |
| **S09** | Uncertainty 20k draws → F/targets CI95 & frontier A/B | `approx(log mult)` interp F/Cmax/AUC/Cmin, `sample_multiplier` dose-linear | Dual sigma display vs grade (A/B/C used) |
| **Battery** | A-to-Z `B1` identity `B2` NCA `B3` dose-prop `B4` true 7d QD/BID via `make_repeated_pkml.py` `B5` MIC `B6` pop `B7` renal `B8` food `B9` OAT `B10` IV | `decode_chromosome` → Pint/Dose | **Fix #4:** `GFR_BASE*clcr/112.5` (was `/100` +12.5%, `studies/molecule_battery.R:194` patched) |

**Paths:** `03_PKSIM/docs/figures/.gitkeep` added, `env/pk_sim_run.R:1` header `patch_pksimdb.R→.py` corrected.

## 5. GA In-Loop (→ `ga/run_ga.R:1`, `ga/nsga2_pksim.R:1`, `ga/fitness_pksim.R:1`, `docs/08_ga_specs.md:1`)

`run_ga.R` pop100×gen100 seed42 10k evals checkpoint every 10 → `04_RESULTS/ga/{pareto_front,top10,convergence}.csv` + `checkpoint_gen*.rds`.
`nsga2_pksim.R` 4-obj `max F, Cmax/MIC, AUC/MIC, -dose` (SBX etac20 pc0.9, poly etam20 pm0.1, crowding) — **Fix #2 documented:** dose was **maximized** (`all(o>=...)`) → front degenerates to max dose corner (explains S07/S08 “synergistic”); correct is `o[1:3]>= && o[4]<=` — documented in `docs/08` and `06_MANUSCRIPT/ch07`, not regenerated (front corner = dose is only opposing objective, see `S07` min 250 mg).
`fitness_pksim.R` batch `PINT_PATH + DOSE_PATH (kg/1e6)` 96h → `F Cmax_MIC AUC_MIC`.

**Config:** `parameter_bounds.csv` logP -2.9→1.6 correct at measured HIP, `ga_config.json` weights/Dose_ref400/BW70/maxiter200 vs `run_ga 100` stale but unused (Pareto not weighted).

## 6. Batteries (→ `studies/molecule_battery.R:1`, `studies/molecules/A_B.csv:1`)

A `1.5|50|50|30|20|50|30|1|1|550.57` (×73.9) vs B `1.6|50|59.98|29.23|69.99|50|29.27|1.6|1.6|999.8` (×125, at bounds max, `f_sedds pmin 1.6`, `f_chit/enteric >0.5→1.15/1.10`). B1-B10 true 7d via `make_repeated_pkml.py` (UUID, `Start k*interval`, `Dose/1e6`), B7 now `/112.5`, B8 food 15/90 vs S05 15/60 same conclusion, B9 OAT 0.8/1.2×.

## 7. How to Run

```bash
export DOTNET_ROOT="$HOME/.dotnet"
RS=/Library/Frameworks/R.framework/Resources/bin/Rscript

# Env + patch (once)
$RS 03_PKSIM/env/check_env.R          # 5/5
python3 03_PKSIM/env/patch_pksimdb.py # 91 views → tables

# Gate + studies
$RS 03_PKSIM/studies/S00_validation_gate.R        # 6/6 PASS
$RS 03_PKSIM/studies/S01_iv_scenarios.R           # 20
$RS 03_PKSIM/studies/S02_oral_calibration.R       # 11 pts, Pint0 3e-9
$RS 03_PKSIM/studies/S03_population.R             # 100 ICRP

# GA (in-loop, 1–2 h, pop100×100 seed42)
$RS 03_PKSIM/ga/run_ga.R

# Downstream
$RS 03_PKSIM/studies/S04_sensitivity.R
$RS 03_PKSIM/studies/S07_winner_characterization.R # now dose-fixed
$RS 03_PKSIM/studies/molecule_battery.R A 03_PKSIM/studies/molecules/A_legacy_winner.csv
$RS 03_PKSIM/studies/molecule_battery.R B 03_PKSIM/studies/molecules/B_pksim_winner.csv # B7 now /112.5
```

Via symlinks: `pksim/`, `results/`, `data/` → `03_PKSIM/`, `04_RESULTS/`, `01_COMPOUND_DATA/`. Traceability `06_MANUSCRIPT/appendices/appK_traceability.tex` + `docs/03_parameter_sources.md`.

---
*Generated for `03_PKSIM` — Sept 2026. See also `00_BIBLIOGRAPHY/BIBLIOGRAPHY_SUMMARY.md`, `01_COMPOUND_DATA/COMPOUND_SUMMARY.md`, `02_ENGINE/ENGINE_SUMMARY.md`.*
