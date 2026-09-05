# PBPK Modeling of BCS IV Drugs — Literature

## 1. PBPK Fundamentals

### Key Concepts
- Physiologically-based pharmacokinetic (PBPK) modeling uses anatomical compartments
- Each compartment: organ volume, blood flow, tissue composition
- Drug-specific parameters: physicochemical, ADME
- Mechanistic absorption modeling (ACAT in PK-Sim)

### BCS IV Challenges in PBPK
- Dual limitation: solubility + permeability
- Dissolution rate-limited absorption
- Permeability-limited absorption
- Regional absorption differences
- Formulation effects critical

---

## 2. PK-Sim / Open Systems Pharmacology

### Software Capabilities
- Whole-body PBPK model
- ACAT absorption (7 GI segments)
- Multiple tissue composition models
- Population simulation
- Sensitivity analysis
- Virtual bioequivalence

### Key Tutorials
1. Introduction to PBPK with PK-Sim (OSP)
2. PBPK model building (ciprofloxacin example)
3. Age-dependence of PK
4. PBPK/PD modeling workflow
5. DDI modeling

---

## 3. BCS IV Drug Modeling Approaches

### Solubility-Limited Absorption (Class II/IV)
- Dissolution rate as input
- pH-dependent solubility
- Food effect (fed vs fasted media)
- Supersaturation/precipitation

### Permeability-Limited Absorption (Class III/IV)
- Papp as key parameter
- Regional permeability differences
- Efflux transporter effects
- Absorption window concept

### Combined Limitation (Class IV)
- Both dissolution and permeability
- Complex absorption kinetics
- Formulation-dependent behavior
- High variability expected

---

## 4. Validation Strategies

### IV Data Comparison
- Compare predicted vs observed PK parameters
- CL, Vd, t½, AUC, Cmax
- GOF plots: DV vs IPRED, DV vs PRED, CWRES vs TIME

### Oral Data Comparison (if available)
- Bioavailability prediction
- Formulation comparison
- Food effect prediction

### Population Variability
- Predicted variability vs observed
- Covariate effects

---

## 5. Sensitivity Analysis

### Parameters to Test
1. Permeability (Papp)
2. Solubility
3. Dissolution rate
4. Gastric pH
5. Transit time
6. Renal function (CLCR)
7. Body weight
8. Dose

### Methods
- One-at-a-time (OAT)
- Global sensitivity analysis
- Tornado plots
- Parameter ranking

---

## 6. Relevant Publications

### PBPK of Aminoglycosides
1. Lukacova et al. 2010 — Tobramycin PBPK (GastroPlus)
2. Ferreira et al. 2021 — PBPK of antibiotics
3. Li et al. 2021 — PopPK of tobramycin

### PBPK of BCS IV Drugs
1. General BCS IV PBPK approaches (various)
2. Solubility-permeability interplay
3. Regional absorption modeling

### PK-Sim Specific
1. Willmann et al. 2003-2007 — PK-Sim development
2. OSP tutorials and documentation
3. Community forum discussions

---

## 7. Application to Our Study

### Workflow
1. Define tobramycin compound parameters
2. Load/create PBPK model in PK-Sim
3. Validate with IV data
4. Simulate oral absorption
5. Explore permeability scenarios
6. Compare formulations
7. Population simulations
8. Sensitivity analysis

### Expected Outputs
- Oral bioavailability prediction
- Formulation ranking
- Dose optimization
- Target attainment
- Population variability
