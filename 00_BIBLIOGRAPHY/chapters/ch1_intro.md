# Chapter 1: Introduction

## 1.1 Background

### The Challenge of Oral Drug Delivery
Oral administration remains the preferred route for drug delivery due to patient compliance, ease of administration, and cost-effectiveness. However, many drugs cannot be administered orally due to poor physicochemical properties, particularly low solubility and/or low permeability across biological membranes.

### The Biopharmaceutics Classification System (BCS)
The BCS, introduced by Amidon et al. in 1995, provides a scientific framework for classifying drug substances based on their solubility and intestinal permeability:

| Class | Solubility | Permeability | Example |
|-------|-----------|--------------|---------|
| I | High | High | Metoprolol |
| II | Low | High | Diclofenac |
| III | High | Low | Ranitidine |
| IV | Low | Low | Furosemide |

This classification system has become fundamental in drug development, regulatory decision-making, and bioequivalence assessment (FDA M9, ICH M9).

### BCS Class IV Drugs: The Greatest Challenge
BCS Class IV compounds represent the most challenging category for oral drug delivery. These drugs exhibit both low solubility and low permeability, resulting in:
- Poor and erratic oral bioavailability
- High inter- and intra-subject variability
- Dose-dependent absorption
- Limited predictability of in vitro-in vivo relationships
- Typically require parenteral administration

## 1.2 Tobramycin: A Case Study

### Therapeutic Importance
Tobramycin is a potent aminoglycoside antibiotic essential for treating serious Gram-negative infections, particularly:
- Pseudomonas aeruginosa infections in cystic fibrosis (CF)
- Hospital-acquired pneumonia
- Complicated urinary tract infections
- Febrile neutropenia

It is listed on the World Health Organization's List of Essential Medicines.

### Current Administration Routes
Despite its clinical importance, tobramycin is currently administered only via:
1. **Intravenous (IV)**: 5-7 mg/kg once daily or 1.5-2 mg/kg q8h
2. **Inhalation**: 300 mg BID (TOBI®) — 4 weeks on / 4 weeks off

### The Oral Delivery Gap
No oral formulation of tobramycin exists, primarily due to:
- Very low oral bioavailability (~1-2%)
- Polycationic nature limiting membrane permeation
- Large molecular weight (467.5 Da)
- Multiple ionizable groups (pKa 6.7-9.1)

### Classification Debate
While tobramycin is commonly described as a BCS Class IV drug, recent literature suggests it may be more accurately classified as **BCS Class III** (high solubility, low permeability):
- Water solubility: 94-100 mg/mL (clearly "high")
- Permeability: Very low (polycationic aminoglycoside)
- Asad et al. (2023) explicitly state: "Tobramycin (TOB) is a BCS class III drug"

This distinction is critical because:
- BCS III drugs may qualify for biowaivers (FDA M9)
- Permeability enhancement alone may suffice
- Different formulation strategies apply

## 1.3 Research Rationale

### Clinical Need
- CF patients require chronic antibiotic therapy
- IV administration requires hospitalization and trained personnel
- Oral alternatives would improve quality of life
- Resource-limited settings lack IV infrastructure

### Formulation Opportunities
Several promising approaches have emerged:
1. **Hydrophobic ion pairing (HIP)**: 1500× LogP improvement (Asad et al. 2023)
2. **Self-emulsifying systems (SEDDS/SMEDDS)**: Enhanced permeation
3. **Nanoparticles**: Sustained release, mucoadhesion
4. **Permeation enhancers**: Tight junction modulation

### Modeling Opportunity
PBPK modeling with PK-Sim/ospsuite enables:
- In silico prediction of oral absorption
- Virtual formulation comparison
- Population variability assessment
- Dose optimization without clinical trials

## 1.4 Research Objectives

### Primary Objective
To evaluate the feasibility of oral tobramycin administration through PBPK modeling and simulation using the Open Systems Pharmacology Suite (PK-Sim/ospsuite).

### Specific Objectives
1. Develop and validate a PBPK model for tobramycin IV administration
2. Predict oral bioavailability across different permeability scenarios
3. Compare formulation strategies (solution, SEDDS, nanoparticles, permeation enhancers)
4. Assess sensitivity of key parameters (permeability, renal function, dose)
5. Evaluate target attainment (AUC/MIC, Cmax/MIC) in virtual populations
6. Identify optimal dosing regimens for oral tobramycin

## 1.5 Thesis Structure

| Chapter | Content |
|---------|---------|
| 1 | Introduction and research rationale |
| 2 | Literature review (BCS, tobramycin PK, formulation strategies) |
| 3 | Methodology (PBPK modeling approach, PK-Sim/ospsuite) |
| 4 | Results (simulations, sensitivity analysis, formulation comparison) |
| 5 | Discussion (implications, limitations, future perspectives) |
| 6 | Conclusion |
