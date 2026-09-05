# Tobramycin — Complete Compound Data Sheet

## Basic Information

| Property | Value | Source |
|----------|-------|--------|
| **Name** | Tobramycin | INN |
| **CAS Number** | 32986-56-4 | PubChem |
| **Molecular Formula** | C₁₈H₃₇N₅O₉ | PubChem |
| **Molecular Weight** | 467.515 g/mol | PubChem |
| **PubChem CID** | 36294 | PubChem |
| **DrugBank ID** | DB00710 | DrugBank |
| **UNII** | VZ8RRV54WK | FDA |
| **WHO Essential Medicine** | Yes | WHO EML |

## Physicochemical Properties

| Property | Value | Notes |
|----------|-------|-------|
| **Appearance** | White powder | Hygroscopic |
| **Solubility (water)** | 94-100 mg/mL | Very high |
| **Solubility (ethanol)** | Insoluble | — |
| **Solubility (DMSO)** | 2 mg/mL (conflicting) | Some report insoluble |
| **Log P** | -2.9 | Hydrophilic |
| **pKa** | 6.7, 7.6, 7.7, 7.8, 9.1 | Multiple ionizable groups |
| **BCS Classification** | **III** | High solubility, low permeability |
| **Chirality** | 10 stereocenters | Stereospecific activity |
| **Stability** | Stable at room temp | Protect from moisture |

## Structural Information

### SMILES
```
NC[C@H]1O[C@H](O[C@@H]2OC(CO)[C@@H](O)[C@H](O)[C@@H]2O)[C@H](N)[C@@H](O)[C@@H]1O
```

### InChI
```
InChI=1S/C18H37N5O9/c1-26-14-7(22)3-24(4-8(14)23)16-10(25)12(20)18(28-16)6-9(21)13(11(5-27)29-17(6)19)30-15(9)27/h7-18,23-25H,3-6,19-22H2,1-2H3/p+5/t7-,8-,9-,10-,11-,12+,13-,14-,15-,16-,17-,18-/m1/s1
```

### Functional Groups
- Primary amines (2)
- Secondary amine (1)
- Hydroxyl groups (6)
- Ether linkages
- Glycosidic bonds

## Pharmacology

### Mechanism of Action
- **Target**: 30S ribosomal subunit
- **Action**: Binds to 16S rRNA
- **Effect**: Inhibition of protein synthesis
- **Result**: Bactericidal activity
- **Post-antibiotic effect**: 1-3 hours

### Spectrum of Activity
- **Primary**: Pseudomonas aeruginosa
- **Gram-negative**: E. coli, Klebsiella, Proteus, Enterobacter, Serratia, Providencia, Citrobacter
- **Gram-positive**: Minimal (not primary indication)
- **Atypical**: Limited

### Resistance Mechanisms
- Aminoglycoside-modifying enzymes (AMEs)
- 16S rRNA methyltransferases
- Efflux pumps (major)
- Reduced permeability (minor)
- Ribosomal protection (rare)

## Pharmacokinetics

### IV PK Parameters (Adults)

| Parameter | Normal | CF | ICU | Source |
|-----------|--------|-----|-----|--------|
| CL (L/h) | 6.03 | 4.5-6.37 | 3.27-3.83 | Li et al. 2021 |
| V₁ (L) | 15.1 | 18.7 | 21.3-25.5 | Li et al. 2021 |
| V₂ (L) | — | — | 16.3 | Li et al. 2021 |
| Q (L/h) | — | — | 2.4 | Li et al. 2021 |
| t½ (h) | 2-3 | 2-3 | 4-6 | Multiple |
| Vd ss (L/kg) | 0.26 | 0.27 | 0.30 | Multiple |
| Protein binding | <10% | <10% | <10% | Standard |

### Oral PK Parameters (Estimated)

| Parameter | Value | Confidence | Notes |
|-----------|-------|------------|-------|
| F (bioavailability) | 1-2% | Low | No formal study |
| Tmax | Variable | Low | Formulation dependent |
| Cmax | Very low | Low | Poor absorption |
| AUC | Very low | Low | — |

### Renal Excretion
- **>90%** excreted unchanged in urine
- **CLCR** is primary covariate on clearance
- **Power model**: CL = θ_CL × (CLCR/81)^θ_CLCR

## Pharmacodynamics

### PK/PD Targets

| Target | Value | Clinical Context |
|--------|-------|------------------|
| Cmax/MIC | ≥8-10 | Efficacy |
| AUC₂₄/MIC | 80-120 µg·h/mL | Exposure-response |
| Cmax | 20-30 mg/L | Target peak (IV) |
| Trough | <1 mg/L | Toxicity prevention |
| MIC₉₀ (P. aeruginosa) | 0.5-2 mg/L | Susceptibility |

### Toxicity
- **Nephrotoxicity**: Dose-dependent, trough >2 mg/L
- **Ototoxicity**: Cumulative, irreversible
- **Neuromuscular block**: Rare, high doses
- **Risk factors**: Prolonged therapy, high troughs, concomitant nephrotoxins

## Clinical Use

### Approved Routes
1. **IV**: 5-7 mg/kg once daily (extended interval) or 1.5-2 mg/kg q8h
2. **Inhalation**: 300 mg BID (TOBI) — 4 weeks on / 4 weeks off

### Indications
- Serious Gram-negative infections (P. aeruginosa)
- Cystic fibrosis pulmonary exacerbations
- Hospital-acquired pneumonia
- Complicated urinary tract infections

### Dosing Strategies

| Strategy | Dose | Interval | Target |
|----------|------|----------|--------|
| Traditional | 1.5-2 mg/kg | q8h | Peak 5-10, trough <1 |
| Extended interval | 5-7 mg/kg | q24h | Peak 20-30, trough <1 |
| Hartford nomogram | 5-7 mg/kg | q24-48h | Based on 6-14h level |
| CF pediatric | 10-15 mg/kg/day | Once daily | TDM-guided |

### Therapeutic Drug Monitoring (TDM)
- Peak: 30 min post-infusion
- Trough: Pre-dose
- AUC: Bayesian estimation (2-3 levels)
- Software: TDMx, Pmetrics

## Formulation Challenges

### Why No Oral Formulation Exists
1. **Very low permeability** (polycationic, LogP -2.9)
2. **Oral bioavailability ~1-2%**
3. **GI degradation** (aminoglycosides unstable at low pH?)
4. **Large molecular weight** (467 Da)
5. **Multiple charge states** (5 ionizable groups)

### Potential Strategies (Literature)
1. **HIP + SEDDS**: LogP 1500× improved (Asad et al. 2023)
2. **PLGA NPs**: MIC maintained (Hill et al. 2019)
3. **KuDa NPs**: Biofilm penetration (Blanco-Cabra et al. 2022)
4. **Permeation enhancers**: C10, SNAC (Bohley et al. 2024)
5. **NCAs**: Oral transition focus (Khaled et al. 2026)

## Regulatory Information

| Agency | Status | Notes |
|--------|--------|-------|
| FDA | Approved (IV, INH) | No oral formulation |
| EMA | Approved (IV, INH) | No oral formulation |
| WHO EML | Essential medicine | — |
| BCS biowaiver | Not eligible (Class III, no oral product) | — |

## Safety Profile

### Pregnancy Category
- D (US) — Evidence of risk

### Contraindications
- Hypersensitivity to tobramycin or aminoglycosides
- Cross-allergenicity with other aminoglycosides

### Drug Interactions
- **Nephrotoxins**: Additive nephrotoxicity (vancomycin, NSAIDs, cisplatin)
- **Loop diuretics**: Enhanced ototoxicity
- **Neuromuscular blockers**: Potentiation

## Storage
- **IV**: 2-8°C, protect from light
- **Inhalation**: 20-25°C, protect from light
- **Powder**: Room temperature, desiccant

## References

1. PubChem Compound Summary: Tobramycin. CID 36294. https://pubchem.ncbi.nlm.nih.gov/compound/36294
2. DrugBank: Tobramycin. DB00710. https://go.drugbank.com/drugs/DB00710
3. Asad et al. PLoS ONE 2023;18(6):e0286668.
4. Li et al. J Antimicrob Chemother 2021;76(9):2335-2343.
5. Hill et al. J Funct Biomater 2019;10(2):26.
6. Blanco-Cabra et al. NPJ Biofilms Microbiomes 2022;8:52.
7. Bohley et al. Adv Sci 2024;11(33):2400843.
8. FDA. M9 Guidance. 2021.
