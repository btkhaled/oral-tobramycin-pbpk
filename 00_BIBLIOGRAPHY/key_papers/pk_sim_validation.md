# PK-Sim Validation Literature

## 1. PK-Sim Software Overview

### Developer
Open Systems Pharmacology (OSP) — open-source

### Key Features
- Whole-body PBPK modeling
- ACAT absorption model (7 GI segments)
- Multiple tissue composition models
- Built-in population database
- R interface (ospsuite package)
- Community support and validation

### References
- Willmann et al. 2003, 2007 — PK-Sim development
- OSP documentation — tutorials and examples

---

## 2. Validation Studies

### 2.1 OSP Validation Set (Aciclovir)
- Included in ospsuite package as example
- IV and oral data available
- Well-characterized PK parameters
- Used for package validation

### 2.2 Ciprofloxacin Tutorial
- PBPK model building tutorial
- IV and oral data fitting
- Permeability optimization
- Population simulation

### 2.3 Morphine
- Age-dependence tutorial
- Pediatric scaling
- Metabolism modeling

---

## 3. Aminoglycoside PK-Sim Studies

### 3.1 Lukacova et al. 2010 — Tobramycin PBPK
- **Software**: GastroPlus (not PK-Sim, but principles apply)
- **Focus**: Pulmonary absorption in children
- **Model**: PBPK with permeability-limited tissues
- **Method**: Allometric scaling from adults
- **Result**: Validated PK prediction across ages

### 3.2 Ferreira et al. 2021 — Antibiotics PBPK
- **Software**: GastroPlus 9.5
- **Drugs**: Amikacin, gentamicin, tobramycin, vancomycin
- **Model**: PBPK with renal clearance
- **Result**: Reasonable PK prediction vs observed

### 3.3 Li et al. 2021 — PopPK Tobramycin
- **Software**: NONMEM (not PBPK, but parameters useful)
- **Model**: 2-compartment PopPK
- **Key parameters**: CL, V1, Q, V2, CLCR covariate
- **Use**: Validate PBPK predictions

---

## 4. PK-Sim Specific Documentation

### Tutorials
1. Introduction to PBPK modeling with PK-Sim
2. PBPK model building (ciprofloxacin)
3. Comparing simulations and building blocks
4. Age-dependence of PK
5. How to Build a PBPK/PD Model
6. Favorites in PK-Sim and MoBi
7. Model drug-drug interaction
8. Customizing chart settings

### GitHub Repository
- https://github.com/Open-Systems-Pharmacology/PK-Sim
- Open issues and discussions
- Model repository

---

## 5. OSP Publications

### Key Papers
1. Willmann S, et al. Development of a physiology-based whole-body population model. J Pharmacokinet Pharmacodyn. 2003.
2. Willmann S, et al. PK-Sim: a physiologically based pharmacokinetic 'whole-body' model. Clin Pharmacokinet. 2007.
3. Edginton A, et al. Whole body physiologically-based models of drug disposition. 2006.

### Community Models
- https://www.open-systems-pharmacology.org/OSPSuite-R/
- Model library and examples
- Validated compound definitions

---

## 6. Application to Our Study

### Validation Strategy
1. Load Aciclovir template (included)
2. Create tobramycin compound definition
3. Validate with IV data (Li et al. 2021)
4. Simulate oral absorption
5. Compare with literature estimates
6. Perform sensitivity analysis

### Expected Challenges
1. Unknown precise Papp value
2. Limited oral PK data for validation
3. Formulation parameters not well characterized
4. Population variability difficult to assess

### Mitigation
1. Use permeability sensitivity analysis
2. Compare with in vitro data (Asad et al. 2023)
3. Explore multiple formulation scenarios
4. Validate with known clinical outcomes
