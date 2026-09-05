# Engine Summary — GA Maison (02_ENGINE)

> **Role:** *hypothesis generator* — forged the ×20 platform hypothesis (F34.0%, TOB-161) before the PK-Sim validator existed.
> Definitive = `03_PKSIM` (whole-body ACAT, gate 6/6, Pint0 3e-9 → F0 1.75%, mass-balance 0.1%) + `04_RESULTS/` + `06_MANUSCRIPT/ch07`.
> Cross-validation 34.0% vs 34.6% (Δ0.6 pp, 1.9% relative) is itself a validation (`03_PKSIM/docs/06_legacy_vs_pksim.md:1`).

## 1. Model (→ `archive_legacy/engine_tobramycin.R:1`, `scripts/09_advanced_pk_model.R:1`)

2-compartment open + GI depot + transit chain ODEs, RK4 dt0.01h, `ke = CL/V1 = 0.277 h⁻¹`, Hill PD `E = C^γ/(EC50^γ+C^γ)`, transit `ktr = 2.24 h⁻¹` optimum.

```
F = F0 · fHIP(logP') · fPS(size) · fSEDDS(surf,co,oil) · fPE(Cpe) · fpoly · fchit · fent · fdose  (cap 35% triple-combo literature)
Ka = Ka_ref · g(logP', PS, SEDDS)  (Ka_ref 1.5 h⁻¹, range 0.3–5.0)
```

`F0` 1.5% (literature 1–2% point within <5% envelope) vs PK-Sim `F0` 1.75% (calibrated, `03_PKSIM/docs/05`). Archive bug `F~70%` is double-drain transit+kabs (`archive_legacy/README.md`).

## 2. Chromosome (→ `config/parameter_bounds.csv:1`, `scripts/00_ga_setup.R:46`)

10 genes, 8 continuous + 2 binary:

| # | Gene | Range | Lever |
|---|---|---|---|
| 1 | `logP_modified` | -2.9 → **+1.6** (measured HIP, Asad2023) | Permeability multiplier via `fHIP` (10^(logP+2.9)·k, K=log10(20)/4.5) |
| 2 | `particle_size` | 50–500 nm | fPS: 50 nm optimal, penalty >200 nm |
| 3-5 | `surfactant` 10–60%, `cosurfactant` 5–30%, `oil` 20–70% | SEDDS triplet → fSEDDS up to 1.5× surfactant-rich |
| 6 | `pe_concentration` (C10) | 0–50 mM | fPE saturating, safety penalty >50 mM (Maher2009/Bohley2024) |
| 7 | `polymer_loading` | 0–30% | Saturating 30% |
| 8-9 | `chitosan` / `enteric` | 0/1 | ×1.30 / ×1.20 bonuses |
| 10 | `dose_mg` | 200–1000 mg | Sublinear fdose |

Cap +1.6 → max emergent ×126.3 (`03_PKSIM/ga/enhancement_model.R:1`); legacy 3.0 was artefact ×313 (see `config/README.md`).

## 3. Optimizers (→ `scripts/03_ga_run.R`, `10_nsga2_optimization.R:1`)

**GA scalar (exploratory):** fitness `F_GA = 0.40·F̂ + 0.25·Ĉmax/MIC + 0.25·ÂUC/MIC + 0.10·safety − P_penalty`, `F̂=F/0.60`, `min(1, Cmax/MIC/8)`, `min(1, AUC/MIC/80)`, penalties `Cmax>30, Ctrough>1, F<2%`; pop100 × 200 gen x0.8 mut0.1 elit10 sharing seed42 7-core.

**NSGA-II (definitive exploratory):** 4-obj `max[F, Cmax/MIC, AUC/MIC, −dose]`, non-dominated sort + crowding distance (∞ boundaries) + binary tournament (rank→crowding) + SBX ηc20 β=(2u)^(1/(ηc+1)) + poly mut ηm20 p1/10, **pop200 × 300 gen** elit20 seed42 ~5.7 min, 200 Pareto archive. PK-Sim counterpart: pop100×100 (~1–2 h, `03_PKSIM/ga/run_ga.R`).

## 4. UQ & Manufacturing (→ `scripts/12_sensitivity_validation.R`, `07_manufacturing_feasibility.R`, `08_regulatory_feasibility.R`)

- **OAT** 60 evals `SI = max|ΔAUC|/AUC*` — SI dose 0.42, logP 0.34, chitosan 0.29, enteric 0.20, PE 0.10, PS 0.09 (`06_MANUSCRIPT/appendices/appC_sensitivity.tex`).
- **Monte-Carlo** n=200 log-normal CL/V1/V2 CV20–30% — median Cmax/MIC 8.8 [6.9–10.2] ≥8 in 55%, AUC/MIC 32.5 [24.6–44.1] 80–120 in 0% (`appB_montecarlo.tex`), all safe trough.
- **Cross-validation** ±20% all inputs 50 runs → 26 informative — F27.2–32.7% Cmax/MIC≥8 in 20/26 (77%) (`appD_validation.tex`).
- **Mfg** 10 ops HIP→NP nanoprecip→loading→SEDDS→C10→homog→NP incorp→chitosan fluid-bed→enteric→capsule QC $0.50 base $4.25–4.35 feas 60–65 B, 15h ~10000 kg solvents (`scripts/07`).
- **Reg** 505(b)(2) 7y $4.8M Phase II PK/BE enteric HPMC-AS, elevated risk NP inhal→30d tox, C10→GI, chitosan CoA (`scripts/08`).

## 5. Results (→ `results_legacy/pareto_front_data.csv` 54K, `TOP_10_CANDIDATES/candidate_01/profile.md:1`)

**TOB-161 (rank 161, lead of 401–700 mg band):** 551 mg **F34.0%** 23× `F0` Cmax 9.54 Tmax 0.30 Ka5.0 ktr2.24 Cmax/MIC 9.5 AUC/MIC 32.1 fT30% Cmin0.16 — vs PK-Sim TOBP-001 ×125 F96 97.1% Cmax31.2 AUC172.3 (same chromosome re-evaluated ×73.9 in `06_MANUSCRIPT/ch07`).

**Pareto:** F25–34%, AUC/MIC24–60, dose530–1000, Cmax/MIC9.2–12.4 — dose is the only opposing objective (front degenerates to corner in `03_PKSIM`).

**Cluster:** Ward 3 clusters Jaccard0.92–1 Eucl<0.05 one basin (`scripts/06`).

## 6. How to Run

```bash
# From 02_ENGINE/ (portable, see scripts/00_ga_setup.R:22)
Rscript scripts/00_ga_setup.R              # libs + PHYSIO + PARAM_BOUNDS + OBJ_WEIGHTS + GA_CONFIG
Rscript scripts/03_ga_run.R                # GA 100×200 — fitness sharing, seed42
Rscript scripts/10_nsga2_optimization.R    # NSGA-II 200×300 — see config/README.md for bounds
Rscript scripts/04_ga_results_analysis.R   # → top10
Rscript scripts/11_pareto_analysis.R       # Pareto front
Rscript scripts/12_sensitivity_validation.R # OAT/MC/CV

# Definitive (whole-body ACAT) — 1–2 h
Rscript ../03_PKSIM/ga/run_ga.R            # pop100×100, same 10 genes → dose+Pint multiplier
```

Definitive results = `04_RESULTS/` (PK-Sim, `04_RESULTS/legacy_v01` mirrors this folder). Traceability `06_MANUSCRIPT/appendices/appK_traceability.tex`.

---
*Generated for `02_ENGINE` — Sept 2026. See also `00_BIBLIOGRAPHY/BIBLIOGRAPHY_SUMMARY.md` and `03_PKSIM/docs/06_legacy_vs_pksim.md`.*
