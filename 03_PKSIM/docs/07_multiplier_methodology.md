# 07 — Enhancement multiplier methodology: from free scalar to cited, bounded, emergent quantity

**Audience:** reviewers and reproducers. This document answers the question
*"where does the permeability multiplier come from?"* with two calibration
anchors, seven cited component factors, and an uncertainty propagation.

## The problem this replaces

Earlier versions mapped the formulation chromosome to an apparent intestinal
permeability multiplier through ad-hoc constants inside the fitness function
(`chitosan ×1.15`, `SEDDS min(1.6,…)`, …) and allowed the logP gene to run to
+3.0 — beyond the measured hydrophobic ion-pair (HIP) complex. A reviewer could
rightly object that the multiplier was a free scalar: the optimizer could (and
did) exploit unmeasured extrapolation up to ×313, driving F to a saturation
corner that said more about the parameterization than about any formulation.

## The structure that replaces it

Everything lives in one module — `pksim/ga/enhancement_model.R` — shared by the
GA fitness, the molecule studies, and the uncertainty analysis. No duplicated
constants.

### 1. Two calibration anchors (measured, reproducible)

| Anchor | Quantity | Value | Evidence |
|---|---|---|---|
| **A1** native drug | P_int0 → F0 | 3×10⁻⁹ dm/min → **F = 1.75 %** | calibrated to clinical oral F 1–2 % (docs/05) |
| **A2** nominal platform | multiplier at logP′ = +1.6 | **×20** → F = 34.6 % | PK-Sim-validated (results/studies/S02, docs/06); cross-checked by the legacy engine (34.0 %) |

Anchor A2 defines the *nominal composition*: HIP complex at the **measured**
logP′ = +1.6 (Asad 2023), reference SEDDS (Σ excipients = 100 %), C10 at 25 %,
no nanoparticle carrier, no chitosan, no enteric coating.

### 2. Seven component factors, each cited and bounded

Factors are *relative to the nominal composition* (each equals 1.0 at its
nominal value). The multiplier is their product — **emergent, never free**:

| Component | Form | Min | Max | Grade | Reference |
|---|---|---|---|---|---|
| logP′ (HIP complex) | 10^((logP−(−2.9))·K), K calibrated by A2 | 1.0 | **20** (at measured logP′ = +1.6) | B | Asad 2023 |
| SEDDS (Σ = surf+cosurf+oil) | min(1.6, Σ/100) | 0.20 | 1.60 | B | Muhammad 2022; Griesser 2017 |
| Nanoparticle size | 1 + 0.5·exp(−(size−50)/150) | 1.0 | 1.50 | C | Hill 2019; Khaled 2026 |
| C10 enhancer | 1 + 0.6·(pe/50) | 1.0 | 1.60 | B | Maher 2009; Bohley 2024 |
| Mucoadhesive polymer | 1 + 0.3·(pl/30) | 1.0 | 1.30 | C | Bohley 2024 |
| Chitosan coating | ×1.15 on/off | 1.0 | 1.15 | C | Bohley 2024 |
| Enteric coating | ×1.10 on/off | 1.0 | 1.10 | C | galenic |

Grades: **A** = measured for this drug/system; **B** = measured for a close
analogue (HIP of another peptide, SEDDS of this drug, C10 clinical); **C** =
review-level/phenomenological estimate. The full chromosome → multiplier
decode is bit-identical to the pre-audit version (max |Δ| = 2.8×10⁻¹⁴ over 200
random chromosomes) — so every previously validated study remains valid.

### 3. The one deliberate change: the logP gene ceiling

The gene bound moves from +3.0 to **+1.6 = the measured complex**. Beyond the
measured HIP complex is unmeasured extrapolation; a model may *report* what
such extrapolation would imply (S08 requirement map), but an *optimizer* must
not be allowed to claim it as a design point. Consequence:

- **max emergent multiplier = ×126.3** (all factors at cited maxima)
- F at ×126 ≈ 96 % — high, but **not** the old ×313 saturation corner
- the "F = 99.7 %" headline dies here, replaced by a defensible maximum

### 4. Uncertainty propagation (answers "how wrong could this be?")

Each factor carries a lognormal uncertainty σ by grade (A: 0.10, B: 0.25,
C: 0.40). `sample_multiplier()` draws n log-space samples and returns the
multiplier distribution. Example — nominal platform (point ×36 incl. chitosan +
enteric):

```
point ×36 | CI95 ×[6.1, 210]   (n = 20 000, seed 42)
```

Study **S09** (`pksim/studies/S09_multiplier_uncertainty.R`) propagates this
through the validated F(multiplier) response and the PK/PD targets, producing
the *attainability frontier with uncertainty* — the thesis figures/tables that
replace the point-claim.

## What the optimizer can and cannot claim now

- The GA explores **within** the cited bounds; its Pareto front is a real
  trade-off (dose ↔ F ↔ trough), not a saturation artifact.
- The requirement statement is falsifiable: *a formulation achieving the
  cited-maximum components would deliver ≈×126 apparent permeability; the
  direct test is Caco-2/Ussing of the HIP complex across ion-pair loading.*
- The ×313 corner survives only as a **sensitivity statement** (what would be
  needed to cut the dose to 450 mg), never as a design point.
