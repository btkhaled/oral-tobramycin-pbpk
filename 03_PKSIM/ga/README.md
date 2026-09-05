# PK-Sim GA / NSGA-II — Optimization in the Simulation Loop

## Design

The optimizer drives the **validated PK-Sim oral model** directly:

- **Chromosome (10 genes)** — see `config/parameter_bounds.csv`:
  | Gene | Meaning | PK-Sim implementation |
  |---|---|---|
  | 1 logP_mod (−2.9…+1.6) | HIP-complex lipophilicity | **permeability multiplier** on `Tobramycin\|Specific intestinal permeability (transcellular)`: mult = 10^((logP_mod − (−2.9)) × k), calibrated so that logP_mod = +1.6 ⇒ ×20 (docs/05) |
  | 2 particle size, 3-5 SEDDS composition, 6 PE, 7 polymer | formulation levers | fold into the permeability multiplier (documented mapping, docs/05) |
  | 8 chitosan, 9 enteric | binary levers | multiplier bonuses (×1.15, ×1.10 — literature-informed) |
  | 10 dose (200–1000 mg) | dose | `Events\|...\|ProtocolSchemaItem\|Dose` (base unit kg) |

- **Fitness (NSGA-II, 4 objectives)**: max F_oral, max Cmax/MIC, max AUC24/MIC, min dose — computed from each batch run (AUC dose-normalized vs the validated IV run).

- **Budget**: pop 100 × gen 100 (10,000 evals) with checkpoint every 10 generations
  (`results/ga/checkpoint_genXXX.rds`); elapsed ~2–4 h on 8 cores. Reduce `pop_size`
  in `config/ga_config.json` for a faster exploration.

- **Reproducibility**: fixed seed 42; every generation's population and front saved.

## Files

| File | Role |
|---|---|
| `fitness_pksim.R` | batch-based evaluation: chromosome → run values → PK metrics |
| `nsga2_pksim.R` | NSGA-II engine (non-dominated sorting, crowding distance, SBX, polynomial mutation) |
| `run_ga.R` | launcher: loads config, runs the loop, exports Pareto + top-10 |

## Run

```bash
Rscript run_ga.R          # full budget (~2-4 h)
# quick smoke test (pop 12 x gen 3): edit ga_config.json first
```
