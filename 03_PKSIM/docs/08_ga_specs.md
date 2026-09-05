# 08 — GA specifications: exploratory engine (Molecule A) vs PK-Sim in-the-loop (Molecule B)

Both optimization tracks optimize the **same 10-gene formulation chromosome** over the **same four objectives**, but with different engines, budgets and roles. All numbers below are the exact configuration used for the committed results.

## Common chromosome (10 genes)

| # | Gene | Min | Max | Type | Maps to |
|---|---|---|---|---|---|
| 1 | logP_modified | −2.9 | **+1.6** (measured HIP complex) | continuous | f_logp: 10^((logP+2.9)·K), K = log10(20)/4.5 |
| 2 | particle_size | 50 | 500 nm | continuous | f_np = 1 + 0.5·exp(−(size−50)/150) |
| 3 | surfactant_pct | 10 | 60 % | continuous | f_sedds = min(1.6, Σ/100) |
| 4 | cosurfactant_pct | 5 | 30 % | continuous | (with 3+5) |
| 5 | oil_pct | 20 | 70 % | continuous | (with 3+4) |
| 6 | pe_concentration | 0 | 50 % | continuous | f_pe = 1 + 0.6·(pe/50) |
| 7 | polymer_loading | 0 | 30 % | continuous | f_poly = 1 + 0.3·(pl/30) |
| 8 | chitosan_coating | 0 | 1 | binary | f_chit = ×1.15 if on |
| 9 | enteric_coating | 0 | 1 | binary | f_enteric = ×1.10 if on |
| 10 | dose_mg | 200 | 1000 | continuous | protocol dose (base unit kg) |

Every factor function, bound and citation lives in **one module**: `pksim/ga/enhancement_model.R` (see [docs/07](07_multiplier_methodology.md)). The multiplier is the **product** of the seven component factors — emergent, capped at ×126.3.

## Common objectives (NSGA-II, all maximized except dose)

1. F_oral — bioavailability (96-h window, dose-normalized vs the validated IV reference 102.5/577.5 mg·h/L per mg)
2. Cmax/MIC (MIC = 1 mg/L)
3. AUC24/MIC
4. −dose (minimization)

## Track A — exploratory GA (legacy engine, "Molecule A")

| Property | Value |
|---|---|
| Engine | hand-rolled 2-compartment + transit + Hill PK model, RK4, pure R (archived `archive/engine_v01/`) |
| Algorithm | classical GA (single-objective fitness aggregation) **and** custom NSGA-II (4 objectives) |
| Budget | pop 100 × 200 gen (GA); pop 200 × 300 gen (NSGA-II) |
| Result | TOB-161 and the top-10 in `results/legacy_v01/` (F = 34.0 % at its own ×23 pricing) |
| Role in the final program | **provenance + candidate generator**. Its winner chromosome is *re-evaluated in PK-Sim* through the shared enhancement model → TOB-161-A (×73.9, F96 89.3 %) — the 3-fold cross-engine divergence is a documented finding |

## Track B — NSGA-II inside the PK-Sim loop ("Molecule B")

| Property | Value |
|---|---|
| Engine | PK-Sim 12.3.173 native (validated tobramycin oral PKML), one `SimulationBatch` per generation — the whole population evaluated in a single .NET round-trip |
| Implementation | dependency-free NSGA-II (Deb 2002), `pksim/ga/nsga2_pksim.R` |
| Operators | SBX crossover ηc = 20, pcross = 0.9; polynomial mutation ηm = 20, pmut = 0.1 per gene; binary tournament on (rank, crowding); elitist μ+λ replacement |
| Budget | pop 100 × 100 generations (seed 42); checkpoints every 10 generations |
| Convergence | best F within 0.1 % of the final value by generation 20; run finalized at generation 60 (checkpoint) |
| Result | TOBP-001 — all components at their cited maxima, emergent ×125.0, 1000 mg, **F96 = 97.1 %**, Cmax/MIC 31.2, AUC/MIC 172.3 |
| Front shape | single corner point (3 of 4 objectives are synergistic); the dose question is answered by the requirement map (S08) and the 467 mg in-band option |

## Evaluation standard (both molecules)

Both winners go through the identical 10-block battery (`pksim/studies/molecule_battery.R`): identity card, single dose + NCA, dose proportionality, **true** 7-day repeated dosing (QD + BID), PK/PD targets vs MIC panel, 100-subject ICRP population, renal impairment (CLCR 100/60/40/20), food effect, component OAT, IV comparison. Results: `results/molecule_A/`, `results/molecule_B/`; thesis §8.6 + Appendix R.

## Reproduction

```bash
Rscript pksim/ga/run_ga.R 100 100          # track B (~30 min)
Rscript pksim/studies/molecule_battery.R A pksim/studies/molecules/A_legacy_winner.csv
Rscript pksim/studies/molecule_battery.R B pksim/studies/molecules/B_pksim_winner.csv
```
