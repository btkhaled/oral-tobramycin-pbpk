# Tobramycin BCS Classification

## Classification Status

| Property | Classification | Justification |
|----------|---------------|---------------|
| **Solubility** | HIGH | 94-100 mg/mL in water; highest single dose (400 mg) soluble in <250 mL over pH 1.2-6.8 |
| **Permeability** | LOW | Papp < 1 × 10⁻⁶ cm/s in Caco-2; absolute oral bioavailability ~1-2% |
| **BCS Class** | **III** | High solubility, low permeability |

## Critical Note

The literature predominantly classifies tobramycin as **BCS Class III**, not Class IV:

> "Tobramycin (TOB) is a BCS class III drug which is used against gram negative bacterial infections"
> — Asad et al., PLoS ONE 2023, DOI: 10.1371/journal.pone.0286668

## Regulatory Framework

### FDA M9 Guidance (2021)
- BCS Class I and III eligible for biowaivers (immediate-release, oral, systemic)
- Class III requires: high solubility + low permeability
- Biowaiver applies to test product with same formulation and strength as reference

### Why NOT Class IV?
- Solubility is NOT the limiting factor
- 94 mg/mL in water = ~200× higher than needed for BCS "high soluble" criterion
- The problem is **permeability**, not solubility

## Implications for Formulation Strategy

### Class III Strategy Focus: Permeability Enhancement
1. **Permeation enhancers** (C₁₀, SNAC, bile salts)
2. **Hydrophobic ion pairing** (HIP) → increase LogP → improve transcellular
3. **Nanoparticles** (PLGA, chitosan) → mucoadhesion, tight junction opening
4. **Lipid-based systems** (SEDDS, SMEDDS) → lymphatic transport
5. **Prodrug approach** → lipophilic prodrug → esterase activation

### NOT Needed (Class III specific)
- Solubility enhancement techniques (micronization, solid dispersions, amorphous forms)
- Dissolution rate improvement

## Cross-link to Build Finale

- Calibration: `03_PKSIM/docs/05_calibration_pint.md` — Pint0 3e-9 dm/min → F0 1.75% (24h) / 3.5% (96h), platform ×20 → F 34.6% (cross-check 34.0% vs 34.6% Δ1.9%).
- Validation: `04_RESULTS/validation/iv_validation_gate.csv` — 6/6 PASS (gate 577.5 mg).
- Manuscript: `06_MANUSCRIPT/frontmatter/abstract.tex:5` (BCS III) + `appendices/appH_physchem.tex`.

## References

1. Amidon GL, Lennernäs H, Shah VP, Crison JR. A theoretical basis for a biopharmaceutic drug classification. Pharm Res. 1995;12(3):413-420.
2. Asad M, Rasul A, Abbas G, Shah MA, Nazir I. Self-emulsifying drug delivery systems: A versatile approach to enhance the oral delivery of BCS class III drug via hydrophobic ion pairing. PLoS ONE. 2023;18(6):e0286668.
3. FDA. Guidance for Industry: M9 Biopharmaceutics Classification System-Based Biowaivers. March 2021.
4. ICH M9. Biopharmaceutics Classification System-Based Biowaivers. Step 4, 2019.
