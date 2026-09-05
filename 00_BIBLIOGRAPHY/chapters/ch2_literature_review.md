# Chapter 2: Literature Review

## 2.1 The Biopharmaceutics Classification System

### 2.1.1 Historical Development
The BCS was introduced by Amidon et al. (1995) as a scientific framework for classifying drug substances based on two fundamental properties:
- **Aqueous solubility**: Determines dissolution rate
- **Intestinal permeability**: Determines absorption rate

### 2.1.2 Classification Criteria

| Parameter | High | Low |
|-----------|------|-----|
| Solubility | Highest dose soluble in ≤250 mL over pH 1-6.8 | Not meeting criteria |
| Permeability | ≥85% absorbed or absolute F ≥85% | <85% absorbed |

### 2.1.3 Regulatory Significance
- **FDA M9 Guidance (2021)**: Biowaivers for Class I and III
- **ICH M9 (2019)**: International harmonization
- **EMA**: Similar framework
- Biowaiver eligibility: Immediate-release, oral, systemic action

### 2.1.4 Extensions
- **BDDCS** (Wu & Benet 2005): Predicts drug disposition
- **QBCS**: Quantitative classification
- **Six-class system**: Subdivides based on dissolution rate

## 2.2 Tobramycin: Physicochemical and Pharmacological Profile

### 2.2.1 Chemical Structure
- Aminoglycoside antibiotic
- MW: 467.5 Da
- 10 stereocenters
- 5 ionizable groups (pKa 6.7-9.1)
- Polycationic at physiological pH

### 2.2.2 Solubility Profile
| Medium | Solubility | Notes |
|--------|-----------|-------|
| Water | 94-100 mg/mL | Very high |
| PBS pH 7.2 | ~10 mg/mL | Reduced vs water |
| Ethanol | Insoluble | — |
| DMSO | 2 mg/mL (conflicting) | Some report insoluble |

**Conclusion**: Clearly meets BCS "highly soluble" criterion.

### 2.2.3 Permeability Profile
- Papp in Caco-2: <1 × 10⁻⁶ cm/s (low)
- Oral bioavailability: ~1-2%
- Mechanism of low permeability:
  - Polycationic nature (multiple positive charges)
  - High polar surface area
  - LogP -2.9 (hydrophilic)
  - Poor passive transcellular diffusion

**Conclusion**: Clearly meets BCS "low permeability" criterion.

### 2.2.4 Classification Resolution
**Tobramycin = BCS Class III** (not IV as commonly stated)

Key evidence:
1. Asad et al. (2023): "Tobramycin is a BCS class III drug"
2. Solubility clearly high
3. Problem is permeability only
4. Formulation strategies should target permeability

## 2.3 Tobramycin Pharmacokinetics

### 2.3.1 IV Pharmacokinetics

#### Adult Population PK (Li et al. 2021)
- **Model**: 2-compartment
- **CL**: 3.27 L/h (ICU), 6.03 L/h (normal)
- **V₁**: 21.3 L (ICU), 15.1 L (normal)
- **CLCR covariate**: Power model (θ = 0.72)
- **Residual error**: 28.5%

#### Pediatric CF PK (Hennig et al.)
- **CL**: 6.37 L/h/70 kg
- **V₁**: 18.7 L/70 kg
- **Dosing**: 10 mg/kg/day once daily

### 2.3.2 Oral Pharmacokinetics
- **Bioavailability**: ~1-2% (estimated)
- **No clinical data** available for oral formulation
- **Prediction gap**: Requires PBPK modeling

### 2.3.3 Special Populations
| Population | PK Changes | Clinical Implication |
|-----------|------------|---------------------|
| CF | ↑ CL, ↑ Vd | Higher doses needed |
| ICU | ↓ CL, ↑ Vd | Loading dose, TDM |
| Elderly | ↓ CL | Dose reduction |
| Pediatric | Age-dependent | Allometric scaling |

## 2.4 Formulation Strategies for BCS Class III Drugs

### 2.4.1 Permeability Enhancement Approaches

#### Hydrophobic Ion Pairing (HIP)
- **Principle**: Complexation with lipophilic counter-ion
- **Example**: Tobramycin + sodium docusate
- **Result**: LogP improved 1500× (Asad et al. 2023)
- **Limitation**: Dissociation in GI fluids

#### Permeation Enhancers (PEs)
- **C10 (sodium caprate)**: GRAS, paracellular mechanism
- **SNAC**: FDA-approved for semaglutide
- **PPZ (1-phenylpiperazine)**: Novel, 30-day safety data
- **SDC (sodium deoxycholate)**: Bile salt, membrane fluidization

#### Nanoparticles
- **PLGA NPs**: Mucoadhesion, sustained release
- **Chitosan NPs**: Tight junction opening
- **KuDa SCPNs**: Charge neutralization

### 2.4.2 Lipid-Based Systems

#### SEDDS/SMEDDS
- Spontaneous emulsification in GI fluids
- Enhances lymphatic transport
- Protects drug from degradation
- Can incorporate HIP complexes

#### Liposomes
- Mostly pulmonary focus
- Oral potential for lymphatic targeting

### 2.4.3 Comparison of Strategies

| Strategy | Mechanism | Evidence Level | Scalability |
|----------|-----------|----------------|-------------|
| HIP + SEDDS | Lipophilisation + emulsification | In vitro (Asad 2023) | Moderate |
| PLGA NPs | Mucoadhesion, sustained release | In vitro (Hill 2019) | Good |
| C10 PE | Tight junction opening | Clinical (other drugs) | Good |
| SNAC | Tight junction opening | FDA-approved | Excellent |

## 2.5 PBPK Modeling in Drug Development

### 2.5.1 PBPK Fundamentals
- Mechanistic, physiology-based approach
- Predicts concentration-time profiles
- Enables virtual experiments
- Supports regulatory submissions

### 2.5.2 PK-Sim / Open Systems Pharmacology
- **Software**: PK-Sim (GUI) + ospsuite (R package)
- **Absorption**: ACAT model (7 GI segments)
- **Features**: Population simulation, sensitivity analysis
- **Validation**: Extensive literature support

### 2.5.3 PBPK for BCS IV Drugs
- Dual limitation: solubility + permeability
- Dissolution rate as input
- Regional absorption differences
- Formulation effects critical

### 2.5.4 Application to Oral Tobramycin
- Validate with IV data
- Predict oral absorption
- Explore formulation scenarios
- Optimize dosing

## 2.6 Knowledge Gaps

1. **No in vivo PK data** for oral tobramycin
2. **No PBPK modeling** of oral absorption
3. **Optimal strategy unknown**
4. **Food effect** not characterized
5. **Population variability** not assessed

## 2.7 References

1. Amidon GL, et al. Pharm Res. 1995;12(3):413-420.
2. Asad M, et al. PLoS ONE 2023;18(6):e0286668.
3. Hill M, et al. J Funct Biomater 2019;10(2):26.
4. Blanco-Cabra N, et al. NPJ Biofilms Microbiomes 2022;8:52.
5. Li Y, et al. J Antimicrob Chemother 2021;76(9):2335-2343.
6. Bohley M, et al. Adv Sci 2024;11(33):2400843.
7. Khaled K, et al. Molecules 2026;31(12):2139.
8. FDA M9 Guidance. 2021.
9. ICH M9. 2019.
10. Wu F, Benet LZ. Pharm Res. 2005;22:11-23.
