# Chapter 3: Methodology — PBPK Modeling Approach

## 3.1 Software and Tools

### 3.1.1 PK-Sim (GUI)
- **Version**: 12.x (latest)
- **Developer**: Open Systems Pharmacology
- **License**: Open source (academic use)
- **Platform**: Windows, Linux, macOS

### 3.1.2 ospsuite R Package
- **Version**: 12.x
- **Function**: Load, manipulate, simulate PBPK models
- **Language**: R (≥4.0)
- **Dependencies**: rSharp, .NET runtime

### 3.1.3 Additional Tools
- **R**: Statistical computing and visualization
- **ggplot2**: Publication-quality figures
- **dplyr/tidyr**: Data manipulation
- **readr**: CSV import/export

## 3.2 Model Development Workflow

### Step 1: Compound Definition
1. Enter physicochemical parameters
2. Define ADME properties
3. Specify transporter interactions
4. Set PK-Sim compound ID

### Step 2: Base Model Creation
1. Select template (standard human adult)
2. Load compound definition
3. Set administration route and dose
4. Run initial simulation

### Step 3: Validation (IV Route)
1. Compare with observed PK data
2. Assess GOF plots
3. Optimize parameters if needed
4. Document validation metrics

### Step 4: Oral Absorption Setup
1. Configure ACAT model
2. Set dissolution parameters
3. Define permeability scenarios
4. Run oral simulations

### Step 5: Sensitivity Analysis
1. Identify key parameters
2. Define parameter ranges
3. Run OAT sensitivity
4. Generate tornado plots

### Step 6: Population Simulation
1. Define virtual populations
2. Set dosing regimens
3. Run Monte Carlo simulations
4. Assess variability and target attainment

## 3.3 Compound Parameters

### 3.3.1 Physicochemical Properties
| Parameter | Value | Unit |
|-----------|-------|------|
| MW | 467.515 | g/mol |
| Log P | -2.9 | — |
| pKa | 6.7, 7.6, 7.7, 7.8, 9.1 | — |
| Solubility | 94 | mg/mL |
| BCS | III | — |

### 3.3.2 ADME Parameters
| Parameter | Value | Unit |
|-----------|-------|------|
| Protein binding (fu) | 0.95 | fraction |
| Renal excretion | >90% | unchanged |
| Hepatic metabolism | negligible | — |
| Oral bioavailability | ~1.5% | estimated |

### 3.3.3 PK Parameters (Population PK)
| Parameter | Value | Unit | Source |
|-----------|-------|------|--------|
| CL | 5.5 | L/h | Li et al. 2021 |
| V₁ | 17 | L | Li et al. 2021 |
| Q | 2.4 | L/h | Li et al. 2021 |
| V₂ | 16 | L | Li et al. 2021 |
| CLCR exponent | 0.72 | — | Li et al. 2021 |

## 3.4 Simulation Scenarios

### 3.4.1 Validation Scenarios
| Scenario | Dose | Route | Population |
|----------|------|-------|------------|
| IV bolus | 5 mg/kg | IV bolus | Adult 70 kg |
| IV infusion | 5 mg/kg | 30 min infusion | Adult 70 kg |

### 3.4.2 Oral Exploration Scenarios
| Scenario | Dose | Route | Formulation |
|----------|------|-------|-------------|
| Solution fasted | 400 mg | Oral | Solution |
| Solution fed | 400 mg | Oral | Solution |
| Suspension | 400 mg | Oral | Suspension |
| SEDDS | 400 mg | Oral | SEDDS |
| Nanoparticles | 400 mg | Oral | NPs |

### 3.4.3 Sensitivity Analysis Scenarios
| Parameter | Range | Levels |
|-----------|-------|--------|
| Permeability (Papp) | 0.5-5 × 10⁻⁶ cm/s | 4 |
| CLCR | 30-150 mL/min | 4 |
| Dose | 200-800 mg | 4 |
| Gastric pH | 1-5 | 3 |

### 3.4.4 Population Simulation Scenarios
| Population | Age | Weight | CLCR |
|-----------|-----|--------|------|
| Healthy adult | 30 yr | 70 kg | 120 mL/min |
| CF adult | 30 yr | 65 kg | 100 mL/min |
| Renal impairment | 50 yr | 70 kg | 50 mL/min |
| Elderly | 70 yr | 70 kg | 65 mL/min |

## 3.5 Model Validation

### 3.5.1 Validation Metrics
| Metric | Target | Acceptance |
|--------|--------|------------|
| AFE (Average Fold Error) | 1 | 0.5-2.0 |
| AAFE (Absolute AFE) | 1 | <2.0 |
| RMSE | <30% | Acceptable |
| R² | >0.9 | Good fit |

### 3.5.2 Goodness-of-Fit Plots
1. DV vs IPRED (Individual Predicted)
2. DV vs PRED (Population Predicted)
3. CWRES vs TIME
4. CWRES vs DV

## 3.6 Output Parameters

### Primary Outputs
- Cmax (mg/L)
- Tmax (h)
- AUC₀₋∞ (mg·h/L)
- Bioavailability (F, %)
- Half-life (h)

### Secondary Outputs
- Steady-state concentrations
- Accumulation ratio
- Target attainment (Cmax/MIC, AUC/MIC)
- Population variability (CV%)

## 3.7 Software Configuration

### R Setup
```r
# Required packages
library(ospsuite)
library(ggplot2)
library(dplyr)
library(readr)

# Simulation settings
simulationOptions$numberOfCores <- 4
simulationOptions$showProgressBar <- TRUE
```

### PK-Sim Settings
- Absorption model: ACAT
- Number of GI segments: 7
- Transit time model: Default
- Dissolution model: pH-dependent

## 3.8 Limitations

1. Unknown precise Papp value
2. Limited oral PK data for validation
3. Formulation parameters not well characterized
4. Population variability difficult to assess
5. Model is only as good as input parameters

## 3.9 References

1. Open Systems Pharmacology. PK-Sim Documentation. https://docs.open-systems-pharmacology.org/
2. Open Systems Pharmacology. ospsuite R Package. https://github.com/open-systems-pharmacology/ospsuite-r
3. Willmann S, et al. PK-Sim development. 2003-2007.
4. Li Y, et al. J Antimicrob Chemother 2021;76(9):2335-2343.
5. Asad M, et al. PLoS ONE 2023;18(6):e0286668.
