# 03 — Parameter Sources and Traceability

Every quantitative input of the tobramycin model, with source and confidence.
Master table: `data/compound/tobramycin_parameters.csv` (machine-readable).

## Compound parameters

| Parameter | Value | Unit | Source | Confidence |
|---|---|---|---|---|
| Molecular weight | 467.515 | g/mol | PubChem CID 36294 | High |
| logP (native) | −2.9 | — | PubChem | High |
| pKa (5 amines) | 6.7, 7.6, 7.7, 7.8, 9.1 | — | PubChem/literature | High |
| pKa in PK-Sim model | 7.7, 7.8, 9.1 | — | 3-of-5 retention (platform limit, amikacin precedent) | High (documented simplification) |
| Aqueous solubility | 94 | mg/mL | Chen 2009 (shake-flask, 25 °C) | High |
| Fraction unbound | 0.95 | — | Standard aminoglycoside reference | High |
| Renal process | Glomerular filtration, GFR fraction 1.0 | — | >90 % unchanged renal excretion | High |
| BCS class | III | — | Asad 2023 (explicit statement + evidence synthesis) | High |

## System / PK parameters

| Parameter | Value | Unit | Source | Confidence |
|---|---|---|---|---|
| CL (validated model, implied) | 5.63 | L/h | Gate: AUC24 102.5 = dose/CL; vs Li 2021 normal 6.03, ICU 3.27–3.83 | High (envelope) |
| GFR (82.5 kg volunteer) | 112.5 | mL/min | ICRP 2002 individual physiology (PK-Sim) | High |
| fu used in renal CL | 0.95 | — | standard | High |
| t½ | 2.29 | h | Gate NCA (published 2.0–3.0) | High |

## Oral calibration parameters

| Parameter | Value | Unit | Source | Confidence |
|---|---|---|---|---|
| P_int native (PK-Sim correlation) | 1.945e-12 | dm/min | Willmann correlation (logP −2.9, MW 467) | High (platform behavior) |
| **P_int0 (calibrated baseline)** | **3e-9** | dm/min | Set so F0 = 1.75 % — matches clinical 1–2 % (point estimate; <5 % envelope) | Medium (calibrated, documented) |
| Platform multiplier (optimized) | ×20 | — | HIP logP′ +1.6 (Asad 2023) + SEDDS + NP + PE mapping | Medium |
| F at ×20 | 34.6 | % | PK-Sim run (this repo) | High (engine) |

## PK/PD targets

| Target | Value | Source |
|---|---|---|
| Cmax/MIC | ≥ 8–10 | Craig 1998 |
| AUC24/MIC | 80–120 | Li 2021 |
| Trough | < 1 mg/L | TDM standard (Bauer 2008) |
| MIC (P. aeruginosa) | 1 mg/L assumed (MIC90 0.5–2) | EUCAST/CLSI mid-range |

## Traceability

- Snapshot generator: `pksim/model/make_tobramycin_json.py` (single source of truth).
- Base model: `data/snapshots/Amikacin-Model.json` (OSP Model Library v12.3.1, validated; evaluation report published by OSP).
- Thesis traceability matrix: `manuscript` Appendix K.
