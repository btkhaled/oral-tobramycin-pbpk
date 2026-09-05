# Tobramycin PK/PD Targets

## Primary Targets

| Target | Value | Clinical Context | Source |
|--------|-------|------------------|--------|
| **Cmax/MIC** | ≥8-10 | Concentration-dependent killing | Craig 1995, Lister 2009 |
| **AUC₂₄/MIC** | 80-120 µg·h/mL | Exposure-response | Li et al. 2021 (JAC) |
| **AUC₂₄** | 80-120 µg·h/mL (total) | Toxicity threshold | Hartford nomogram |
| **Cmax** | 20-30 mg/L | Target peak (IV once-daily) | Hartford nomogram |
| **Trough** | <1 mg/L | Nephrotoxicity/ototoxicity prevention | TDM standard |
| **MIC₉₀ P. aeruginosa** | 0.5-2 mg/L | Susceptibility breakpoint | EUCAST/CLSI |

## Exposure-Response Relationships

### Efficacy
- **Concentration-dependent killing**: Higher Cmax/MIC = better outcome
- **Post-antibiotic effect**: Prolonged for aminoglycosides (1-3 h)
- **Threshold**: Cmax/MIC ≥ 8 associated with clinical cure

### Toxicity
- **Nephrotoxicity**: Risk increases with AUC >120 µg·h/mL and trough >2 mg/L
- **Ototoxicity**: Cumulative dose-dependent; trough elevation increases risk
- **Risk factors**: Prolonged therapy, high troughs, concomitant nephrotoxins

## Dosing Strategies

| Strategy | Dose | Interval | Target |
|----------|------|----------|--------|
| Traditional (thrice daily) | 1.5-2 mg/kg | q8h | Peak 5-10, trough <1 |
| Once-daily (extended interval) | 5-7 mg/kg | q24h | Peak 20-30, trough <1 |
| Extended interval (Hartford) | 5-7 mg/kg | q24-48h (nomogram) | Based on 6-14h level |
| AUC-guided | Individualized | Variable | AUC/MIC 80-120 |

## Special Populations

### Cystic Fibrosis
- Higher CL (renal hyperfiltration)
- Larger Vd (third spacing, altered body composition)
- Dose: 10-15 mg/kg/day once daily
- TDM essential due to PK variability

### Critical Illness
- Increased Vd (fluid resuscitation, capillary leak)
- Decreased CL (acute kidney injury)
- Loading dose may be needed: 7-9 mg/kg

### Renal Impairment
- CLCR is primary covariate on clearance
- CL = θCL × (CLCR/81)^θCLCR (power model)
- Dose adjustment required

## Therapeutic Drug Monitoring

| Parameter | Timing | Method |
|-----------|--------|--------|
| Peak (Cmax) | 30 min post-infusion (IV) | Immunoassay, LC-MS/MS |
| Trough (Cmin) | Pre-dose | Immunoassay, LC-MS/MS |
| AUC₂₄ | Bayesian estimation | PopPK + 2-3 levels |
| Bayesian dosing | Software-guided | TDMx, Pmetrics |

## References

1. Craig WA. Pharmacokinetic/pharmacodynamic parameters: rationale for antibacterial dosing of mice and men. Clin Infect Dis. 1998;26:1-10.
2. Li Y, et al. Pharmacokinetic/pharmacodynamic evaluation of tobramycin in critically ill patients. J Antimicrob Chemother. 2021;76(9):2335-2343.
3. Hartford nomogram: Bauer LA. Applied Clinical Pharmacokinetics. McGraw-Hill, 2008.
4. Flume PA, et al. Cystic fibrosis pulmonary guidelines: treatment of pulmonary exacerbations. Am J Respir Crit Care Med. 2009;180:802-808.
5. Smyth A, et al. Once versus three-times daily regimens of tobramycin (TOPIC study). Lancet. 2005;365:573-578.
