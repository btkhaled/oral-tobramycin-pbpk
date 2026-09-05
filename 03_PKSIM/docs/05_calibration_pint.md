# 05 — Oral Permeability Calibration (F vs P_int)

## Why a calibration is needed

PK-Sim computes the specific transcellular intestinal permeability from the
Willmann-type correlation on logP and effective molecular weight. For tobramycin
(logP −2.9, MW 467.5) the correlation returns **P_int = 1.945e-12 dm/min —
effectively zero** (F_absorbed ≈ 0.002 %). Clinically, tobramycin oral
bioavailability is ≈ 1–2 % (point estimate; <5 % envelope), driven by residual
paracellular and transporter-mediated uptake that the default correlation does
not represent (the paracellular term is 0 by default; see PK-Sim documentation,
"Specific Intestinal Permeability").

The standard PK-Sim practice for such cases is to provide an experimentally
justified override of **`Specific intestinal permeability (transcellular)`**
(mucosal basolateral permeability is rescaled automatically by the platform).

## Calibration

`pksim/studies/S02_oral_calibration.R` scans P_int over 11 log-spaced values and
computes F as the dose-normalized AUC ratio (oral 550 mg vs IV 577.5 mg, same
individual, AUC24 = 102.5 mg·h/L from the validated IV run).

| P_int (dm/min) | P_int (cm/s) | F (%) | Cmax (mg/L) |
|---|---|---|---|
| 1e-10 | 1.7e-12 | 0.005 | 0.0003 |
| **3e-9** | **5e-11** | **1.75** | **0.097** |
| 1e-8 | 1.7e-10 | 6.63 | 0.560 |
| 3e-8 | 5e-10 | 19.16 | 2.17 |
| 1e-7 | 1.7e-9 | 50.47 | 6.97 |
| 3e-7 | 5e-9 | 86.48 | 15.21 |
| 1e-6 | 1.7e-8 | 99.81 | 24.42 |

**Baseline: P_int0 = 3e-9 dm/min ⇒ F0 = 1.75 %** — matches the clinical point
estimate (1–2 %).

## Platform mapping and cross-check

The formulation platform (hydrophobic ion pairing raising apparent logP′ to
+1.5/+1.6, delivered through SEDDS with nanoparticles and 50 mM sodium caprate)
maps to an apparent-permeability multiplier. **×20 ⇒ F = 34.64 %** (Cmax
4.41 mg/L, AUC24 33.8 mg·h/L at 550 mg).

This independently confirms the exploratory custom-engine optimum (F = 34.0 %,
`docs/06_legacy_vs_pksim.md`): two implementations — a hand-rolled
2-compartment + transit + Hill engine and the full PK-Sim whole-body PBPK —
converge on the same platform bioavailability.

## Consequences for the optimization

- The GA permeability gene is a **multiplier on P_int0** (linear in the
  chromosomal logP′ gene), bounded by PK-Sim's mechanistic saturation
  (F → ~100 % at ×330).
- Peak-driven efficacy (Cmax/MIC ≥ 8, MIC 1 mg/L) is attainable at F ≥ ~15 %
  with 400–600 mg; the AUC24/MIC 80–120 band is not reachable by single oral
  dosing (F would need ~100 % at impractical doses) — quantified honestly in
  the thesis.
