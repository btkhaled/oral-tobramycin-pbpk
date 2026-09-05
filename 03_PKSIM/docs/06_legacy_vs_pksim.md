# 06 — Legacy Custom Engine vs PK-Sim (Cross-Check)

Two independent implementations produced the headline bioavailability result:

| | Legacy engine (v0.1, archived) | PK-Sim 12.4 (this repo) |
|---|---|---|
| Structure | Hand-rolled 2-compartment ODEs + GI transit chain (RK4, pure R) | Whole-body PBPK (PK-Sim standard distribution, ACAT oral absorption, GFR renal process) |
| Disposition | CL, V1, Q, V2 fixed at Li 2021 values (CL_ref 4.76 L/h @ CLCR 81 → CL@120 = 6.03) | PK-Sim physiology (GFR 6.75 L/h × fu 0.95 → CL 6.41 L/h; Vd from PK-Sim Standard partition) |
| Absorption | 8 phenomenological enhancement factors, calibrated to literature bands | Regional ACAT + explicit P_int override calibrated to F0 (3e-9 dm/min) |
| Oral baseline F0 | 1.5 % (input) / emergent 2.8 % | **1.75 % (emergent, calibrated)** |
| Platform optimum (×20 P_int) | **F = 34.0 %** (GA/NSGA-II optimum, TOB-161) | **F = 34.64 %** (direct PK-Sim run at the same multiplier) |
| Agreement | — | **Δ = 0.6 pp (1.9 % relative)** |

## Interpretation

- The agreement is remarkable given the structural differences: the phenomenological
  enhancement-factor model and the mechanistic ACAT absorption both saturate at
  nearly the same apparent permeability.
- The legacy engine's published Cmax/AUC figures (e.g., Cmax 9.5 mg/L at 550 mg,
  F = 34 %) and the PK-Sim equivalents (Cmax 4.4 mg/L at the same P_int — the PK-Sim
  disposition volume being larger than the legacy V1) differ in absolute peak, as
  expected from different distribution assumptions. **The F estimate is the
  transferable, cross-validated quantity**; disposition-specific metrics defer to
  the PK-Sim model (this repo, `results/studies/`).
- Legacy results remain in `results/legacy_v01/` for provenance and are labeled
  as exploratory; they do not feed the headline numbers of the final thesis.
