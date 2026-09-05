# 04 — Study Design

All studies run on the **validated PK-Sim tobramycin model** (`pksim/model/tobramycin_iv_validated.pkml` for IV, `tobramycin_oral.pkml` for oral). Batch runs use the native `createSimulationBatch` mechanism.

| ID | Study | Design | Outputs | Status |
|---|---|---|---|---|
| S00 | IV validation gate | 577.5 mg (7 mg/kg), 30-min infusion; 6 criteria vs published envelope | `results/validation/` | ✅ 6/6 PASS |
| S01 | IV dose × renal function | doses {200, 400, 577.5, 800} mg × CLCR {30, 65, 90, 112.5, 150} mL/min (via `Organism\|Kidney\|GFR (specific)`) | `results/studies/S01_*` | ✅ 20 scenarios |
| S02 | Oral P_int calibration | log-spaced P_int 1e-11 … 2e-4 dm/min (11 points); F = dose-normalized AUC ratio vs IV | `results/studies/S02_*` | ✅ curve + P_int0 |
| S03 | Virtual population | 100 ICRP-2002 adults (20–50 y, 55–95 kg, male), oral platform 550 mg QD, P_int = 20× baseline (AUC24, fT not time-weighted — see note below) | `results/studies/S03_*` | ✅ |
| S04 | Native sensitivity | `{ospsuite}` SensitivityAnalysis on the oral model: PK-PK metrics vs P_int, dose, GFR, fu (AUC24) | `results/studies/S04_*` | ✅ (S04_sensitivity.csv OAT ±20%) |
| S05 | Food effect | gastric emptying **15 min (fasted) vs 60 min (fed)** — code `Organism\|Lumen\|Stomach\|Gastric emptying time` 15→60 (doc header 0.5→1.5h was stale); BCS III ⇒ extent unchanged, Tmax delayed | `results/studies/S05_*` | ✅ (S05_food_effect.csv) |
| S06 | Fractionation + PTA | platform oral: QD 550 / BID 275 / BID 550 / TID 200 (steady state by linear superposition); PTA vs MIC distribution 0.25–4 mg/L | `results/studies/S06_*` | ⏳ ready-to-run |
| GA | NSGA-II in the PK-Sim loop | see `pksim/ga/README.md` | `results/ga/` | ⏳ ready-to-run |

## Key physiological findings so far

- Renal function drives IV exposure as expected (AUC24 315 → 80 mg·h/L from CLCR 30 → 150 mL/min; implied CL 1.83 → 7.18 L/h): dose adjustment tables in S01 output.
- Oral F is a saturating function of P_int: baseline F0 = 1.75 % at P_int0 = 3e-9 dm/min (F24 calibration) / 3.5% (F96 extent, 96h window); the ×20 platform multiplier yields F24 34.6% / F96 48.8% — matching the legacy custom-engine optimum (34.0%) obtained by a fully independent implementation (`docs/06_legacy_vs_pksim.md`).
- The AUC24/MIC 80–120 target is **not** attainable by single oral dosing at safe doses (peak-driven index Cmax/MIC ≥ 8 is). Fractionation (S06, 96h superposition, PTA MIC 0.25-4) and TDM-guided AUC dosing are the honest clinical answers; see the thesis discussion (`06_MANUSCRIPT/ch08`).

> **Note on windows:** `F24` (S03/S04/S05, AUC24) vs `F96` (S02/S06/S07/S08/fitness, 0-5760 min 96h, capturing flip-flop tail) — dual convention documented in `docs/05` and `docs/07`. `S03` fT = `mean(Conc≥MIC)` is resolution-dependent, not time-weighted.
