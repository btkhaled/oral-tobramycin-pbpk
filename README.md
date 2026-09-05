# Oral Tobramycin: From BCS III to a Viable Oral Formulation

[![License: MIT](https://img.shields.io/badge/Code-MIT-yellow.svg)](LICENSE)
[![Data: CC BY-NC-ND 4.0](https://img.shields.io/badge/Data-CC--BY--NC--ND%204.0-blue.svg)](DATA-LICENSE)
[![Platform: macOS ARM64 / Linux](https://img.shields.io/badge/Platform-macOS%20ARM64%20%7C%20Linux-lightgrey)](03_PKSIM/env/README.md)
[![Engine: PK-Sim 12.4](https://img.shields.io/badge/Engine-PK--Sim%2012.4%20%2F%20OSPSuite-2ea44f)](https://www.open-systems-pharmacology.org)
[![Manuscript: 185 pp](https://img.shields.io/badge/Manuscript-185%20pp%20v1.2-005493)](06_MANUSCRIPT/main.pdf)

**A bibliographic study with physiologically based pharmacokinetic modeling in PK-Sim and multi-objective formulation optimization — targeting the first oral tobramycin.**

*Independent research program — Khaled Ben Taieb · September 2026 · `oral-tobramycin-pbpk` `v1.2`*

---

## Abstract

Tobramycin is a WHO essential aminoglycoside (MW 467.515 g/mol, logP –2.9, polycationic, 5 pKa) indispensable against *Pseudomonas aeruginosa* in cystic fibrosis and nosocomial Gram-negative infections, yet restricted to intravenous (5–7 mg/kg QD) and inhaled (TOBI® 300 mg BID) routes (oral bioavailability ≈ 1–2%). This repository resolves the BCS classification as **Class III** (high solubility 94–100 mg/mL, 20–200× the 250 mL criterion; low permeability Papp < 1×10⁻⁶ cm/s), builds a validated whole-body PBPK model in PK-Sim from the Open Systems Pharmacology amikacin model, calibrates the transcellular intestinal permeability to the clinical baseline (Pint0 3×10⁻⁹ dm/min → F0 1.75%), and optimizes a 10-dimensional formulation design space (hydrophobic ion pairing, SEDDS, nanoparticles, permeation enhancers, coatings, dose) with NSGA-II **inside the PK-Sim loop** under a cited-bounded enhancement model (cap ×126.3 at logP +1.6, Asad et al. 2023).

**Headline results — `04_RESULTS/` 90 artifacts, `06_MANUSCRIPT/main.pdf` 185 pp:**

| Result | Value | Source |
|---|---|---|
| IV validation gate (Li et al. 2021 PopPK, Hartford/Bauer) | **6/6 PASS** — 27.55 mg/L (20–30), 34.83 mg/L (20–32), AUC24 102.7 mg·h/L (CL 5.62 L/h), trough 0.033 mg/L (<1), t½ 2.04 h (2.0–3.0), renal 99.4% (>90) — 577.5 mg (7 mg/kg ×82.5 kg, 30-min infusion) | `04_RESULTS/validation/iv_validation_gate.csv` |
| Oral baseline (native drug) | **F0 1.75% (24-h window) / 3.5% (96-h extent, flip-flop)** — Pint0 3×10⁻⁹ dm/min | `04_RESULTS/studies/S02_oral_papp_calibration.csv` |
| Cited-bounded enhancement | 7 factors graded A/B/C (σ lognormal A 0.10 / B 0.25 / C 0.40), **cap logP +1.6 (measured HIP, 1500×) → max emergent ×126.3, F96 ≈ 96%** (×313 killed) | `03_PKSIM/ga/enhancement_model.R` |
| NSGA-II in PK-Sim loop (pop 100 × gen 100, seed 42, MIC 1 mg/L) | **10 checkpoints (010–100), best F96 97.1% — winner TOBP-001 ×125, 999.8 mg QD, Cmax/MIC 31.2, AUC/MIC 172** | `04_RESULTS/ga/` |
| Molecule A — legacy GA winner re-evaluated | **×73.9, 550.6 mg QD → AUC/MIC 87.3 (in-band 80–120), F96 88%, PTA Cmax/MIC≥8 : 81%** | `04_RESULTS/molecule_A/` (B1–B10) |
| Molecule B — in-loop optimum (TOBP-001) | **×125, 999.8 mg QD → AUC/MIC 172, F96 96%, PTA 99% / 99%** | `04_RESULTS/molecule_B/` (B1–B10) |
| Requirement map S08 (9× mult 1–313 at 993 mg) | **×33 → F 65.9%, Cmax/MIC 14.47, AUC/MIC 121.8, min dose 850 mg** — ×20 F48.8% (9.73/93.5) already attains AUC≥80 at 993 mg; ×313 → 450 mg | `04_RESULTS/studies/S08_requirement_map.csv` |
| Uncertainty S09 (20 000 draws) | **F96 88% [35–100] vs 96% [50–100], PTA(Cmax≥8) 81% vs 99%** | `04_RESULTS/studies/S09_uncertainty_summary_A/B.csv` |

**Cross-validation:** exploratory custom engine (2-compartment + transit + Hill) 34.0% vs PK-Sim whole-body ACAT 34.6% at the same platform multiplier (×20) — Δ 0.6 pp, 1.9% relative.

**Conventions:** `F24` = 24-h window (calibration, F0 1.75%), `F96` = 96-h window (extent, capturing flip-flop tail, F0 3.5%), `F_ss` = 7-day true QD/BID steady-state (mass balance AUCτ = F·D/CL within 0.1% via `03_PKSIM/model/make_repeated_pkml.py`).

---

## Repository Structure

```
oral-tobramycin-pbpk/
├── README.md / CITATION.cff / LICENSE (MIT) / DATA-LICENSE (CC BY-NC-ND 4.0) / run_all.R
│
├── 00_BIBLIOGRAPHY/        — 20-article evidence base @00_BIBLIOGRAPHY/BIBLIOGRAPHY_SUMMARY.md
│   ├── evidence_table.csv / references.bib (20) / search_strategy.md
│   └── key_papers/ + chapters/ + _legacy/
│
├── 01_COMPOUND_DATA/       — Tobramycin parameterization @01_COMPOUND_DATA/COMPOUND_SUMMARY.md
│   ├── TOBRAMYCIN_DATA.md / molecular_properties.json (BCS III) / pd_targets.md
│   ├── iv_pk_literature.csv / solubility_ & permeability_literature.csv
│   ├── physicochemical/bcs_classification.md
│   └── snapshots/ (5 JSON: Amikacin 78K → Tobramycin 64K → Oral 22K → QD/BID 28K)
│
├── 02_ENGINE/              — Exploratory GA engine — Phase I (hypothesis generator) @02_ENGINE/ENGINE_SUMMARY.md
│   ├── run_engine.R (11 steps, non-destructive, --pop/--gen/--out, 6 min)
│   ├── scripts/ (14: 00_ga_setup.R … 13_manuscript_figures.R, ~3350 lines)
│   ├── config/ (parameter_bounds.csv cap +1.6 + ga_config.json + legacy 3.0)
│   └── results_legacy/ + results_run_*/ + archive_legacy/
│
├── 03_PKSIM/               — PK-Sim platform — Phase II (definitive) @03_PKSIM/PKSIM_SUMMARY.md
│   ├── run_pksim.R (14 steps, dual write 04_RESULTS/ + out_dir)
│   ├── env/ (check_env.R 5/5 + pk_sim_run.R + patch_pksimdb.py 91 views)
│   ├── model/ (make_tobramycin_json.py portable + make_repeated_pkml.py + tobramycin_*.pkml 5.7M)
│   ├── studies/ (S00–S09 + molecule_battery.R + molecules/A_B.csv)
│   ├── ga/ (enhancement_model.R + fitness_pksim.R + nsga2_pksim.R + run_ga.R 100×100)
│   └── docs/ (8: 01 gate 6/6, 05 Pint0, 07 cap +1.6 ×126.3, 08 GA)
│
├── 04_RESULTS/             — Simulation outputs — 90 artifacts @04_RESULTS/README.md
│   ├── validation/ (3) + ga/ (15, 10 checkpoints) + studies/ (33) + molecule_A/B/ (12+12) + legacy_v01/ (5)
│   └── MANIFEST.csv (90, md5 100%)
│
├── 05_ANALYSIS/            — Re-analysis — 13 modules @05_ANALYSIS/run_all.R
│   ├── utils/ + 01_validation/ … 12_manuscript/ (12× scripts + figures + tables + README)
│   ├── figures/ (13) + tables/ (23) + results_run_*/ 
│   └── MANIFEST.csv (126)
│
├── 06_MANUSCRIPT/          — Thesis LaTeX (185 pp, validé tel quel) @06_MANUSCRIPT/README.md
│   ├── main.pdf (6.1M) / main.tex (ch00 synopsis → ch09 conclusion) / preamble.tex
│   ├── frontmatter/ (7) / chapters/ (10) / appendices/ (18, A–R) / figures/ (46) / tables/ (7) / code/ (11)
│   └── references.bib (37)
│
└── 07_SLIDES/              — Defense deck (28 slides)
    ├── slides.md + make_deck.mjs + public/ (14) + export/oral-tobramycin-defense.pptx (1.9M)
```

Numbered folders are canon (`00-07`); legacy symlinks (`pksim→03_PKSIM`, `results→04_RESULTS`, `data→01_COMPOUND_DATA`, etc.) are for local convenience only and are gitignored — see `.gitignore` `local symlinks`.

---

## Installation

### Requirements

| Component | Version | Notes |
|---|---|---|
| R | ≥ 4.4 (tested 4.6.1, CRAN arm64) | **CRAN build required** — Homebrew R crashes in `rSharp` (`sexp_to_parameters`) |
| `ospsuite` | 12.4.4 | `install.packages("ospsuite", repos = c("https://open-systems-pharmacology.r-universe.dev", "https://cloud.r-project.org"))` |
| `rSharp` | ≥ 1.2 | pulled by `ospsuite` |
| .NET runtime | 8.x | `DOTNET_ROOT` must point to it (e.g. `~/.dotnet`) |
| Python | ≥ 3.9 | only for `patch_pksimdb.py` |

```bash
# R packages (once)
install.packages(c("GA", "ggplot2", "dplyr", "readr", "tidyr", "purrr", "patchwork", "viridis", "scales", "jsonlite", "parallel", "doParallel", "corrplot"))

# .NET + ospsuite check (must print 5/5 before anything else)
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$DOTNET_ROOT:$PATH"
Rscript 03_PKSIM/env/check_env.R        # 5/5 OK
python3 03_PKSIM/env/patch_pksimdb.py   # 91 views → tables, ~2s, idempotent
```

---

## Usage

> **⚠️ `run_all.R` at the repository root is NOT FINISHED — please run each dossier one by one (see below).**

### One-command full reproduction (via `run_all.R` at repository root) — ⚠️ INCOMPLETE

```bash
export DOTNET_ROOT="$HOME/.dotnet"
RS=/Library/Frameworks/R.framework/Resources/bin/Rscript  # CRAN R — NOT Homebrew

# ⚠️  NOT FINISHED — use the modular pipelines below instead
$RS run_all.R                     # full 14 steps incl. GA (~1–2 h, pop100×gen100) — INCOMPLETE
$RS run_all.R --skip-ga           # reuse committed 04_RESULTS/ga/ (~2 min) — INCOMPLETE
$RS run_all.R --keep-going        # don't abort on first failing step — INCOMPLETE
```

> **Recommended:** run each dossier one by one — `02_ENGINE` → `03_PKSIM` → `05_ANALYSIS` → `06_MANUSCRIPT` → `07_SLIDES`.

`run_all.R` (when finished) will run `03_PKSIM/env/check_env.R` → `S00` gate (6/6) → `S01`/`S02`/`S03` → `GA` → `S04`–`S09` → `molecule_battery.R A/B` → `04_RESULTS/MANIFEST.csv` — **for now, use the modular pipelines**.

### Modular pipelines

```bash
# 02 — Exploratory GA engine (6 min, hypothesis generator, F34% platform)
$RS 02_ENGINE/run_engine.R                          # 11 steps: 00 → 03 (GA 100×200) → 10 (NSGA-II 200×300) → 04/11/12/05-08/13
$RS 02_ENGINE/run_engine.R --pop 12 --gen 3         # smoke test, 10s
$RS 02_ENGINE/run_engine.R --help

# 03 — PK-Sim definitive platform (1–2 h, gate 6/6, 10 checkpoints)
$RS 03_PKSIM/run_pksim.R                          # 14 steps, pop100×gen100, 90 artifacts → 04_RESULTS/
$RS 03_PKSIM/run_pksim.R --pop 20 --gen 10        # quick, 31s GA
$RS 03_PKSIM/run_pksim.R --skip-ga                # reuse 04_RESULTS/ga/
$RS 03_PKSIM/run_pksim.R --help

# 05 — Modular re-analysis (1 min, 13 modules, 126 artifacts)
$RS 05_ANALYSIS/run_all.R
$RS 05_ANALYSIS/run_all.R --skip-figures

# Manuscript & slides
make -C 06_MANUSCRIPT            # → 06_MANUSCRIPT/main.pdf (185 pp)
cd 07_SLIDES && node make_deck.mjs   # → 07_SLIDES/export/oral-tobramycin-defense.pptx
```

### Step-by-step (PK-Sim)

```bash
export DOTNET_ROOT="$HOME/.dotnet"
RS=/Library/Frameworks/R.framework/Resources/bin/Rscript

$RS 03_PKSIM/studies/S00_validation_gate.R
$RS 03_PKSIM/studies/S01_iv_scenarios.R
$RS 03_PKSIM/studies/S02_oral_calibration.R
$RS 03_PKSIM/studies/S03_population.R
$RS 03_PKSIM/ga/run_ga.R              # or: $RS 03_PKSIM/ga/run_ga.R 100 100
$RS 03_PKSIM/studies/S04_sensitivity.R
$RS 03_PKSIM/studies/S07_winner_characterization.R
$RS 03_PKSIM/studies/molecule_battery.R A 03_PKSIM/studies/molecules/A_legacy_winner.csv
$RS 03_PKSIM/studies/molecule_battery.R B 03_PKSIM/studies/molecules/B_pksim_winner.csv
```

---

## Study Suite Map

| ID | Purpose | Key outputs |
|---|---|---|
| S00 | IV validation gate (Li et al. 2021, Hartford/Bauer, 577.5 mg) | `04_RESULTS/validation/` 6/6 PASS |
| S01 | IV dose (200–800 mg) × renal function (CLCR 30–150, GFR specific) | `S01_*` 20 scenarios |
| S02 | Oral Pint calibration (11 log-spaced Pint, F0 1.75%) | `S02_*` 11 pts, Pint0 3×10⁻⁹ |
| S03 | Virtual population (100 ICRP-2002, 550 mg ×20) | `S03_*` |
| S04 | Native-drug sensitivity (OAT ±20% Pint/Dose/GFR/fu) | `S04_*` |
| S05 | Food effect (gastric emptying 15 vs 60 min) | `S05_*` |
| S06 | Fractionation (QD/BID/TID) + PTA vs MIC 0.25–4 | `S06_*` |
| S07 | Winner characterization (TOBP-001 ×125, 944 mg, F90.7%, min 350 mg) | `S07_*` 6 files |
| S08 | Requirement map (9× mult 1–313 at 993 mg) | `S08_*` 9 rows, ×33 → 65.9% |
| S09 | Uncertainty propagation (20 000 draws, A/B) | `S09_*` 1.7M + frontier |
| GA | NSGA-II in PK-Sim loop (pop100×gen100, 10 checkpoints) | `04_RESULTS/ga/` 15 files |
| Battery A/B | A-to-Z B1–B10 (true 7-day QD/BID via `make_repeated_pkml.py`) | `04_RESULTS/molecule_A/B/` 12+12 |

Traceability: `03_PKSIM/docs/04_study_design.md` + `06_MANUSCRIPT/appendices/appK_traceability.tex` + `04_RESULTS/README.md` + `05_ANALYSIS/*/README.md`.

---

## Scientific Background

1. **BCS Class III** — Solubility 94–100 mg/mL (20–200× the 250 mL criterion) vs Papp < 1×10⁻⁶ cm/s and F ≈ 1–2% → permeability-only (Asad et al. 2023, PLoS ONE).
2. **Model** — Validated amikacin OSP Model Library → tobramycin (MW 467.515, logP –2.9, fu 0.95, 3 pKa 7.7/7.8/9.1, renal GFR fraction 1.0). No prior tobramycin PK-Sim model exists.
3. **Validation** — IV 7 mg/kg 30-min infusion reproduces the clinical envelope: Hartford peak 25.3 mg/L (20–30), AUC24 102.7 mg·h/L (CL 5.62 L/h), t½ 2.04 h (2.0–3.0), trough 0.033 mg/L (<1), renal 99.4% (>90) — **6/6 PASS**.
4. **Calibration** — Willmann 1.945×10⁻¹² dm/min → F0 0.002% → **Pint0 3×10⁻⁹ → F0 1.75% (24h)/3.5% (96h)** → platform **×20 → F 34.6%** (cross-check exploratory 34.0% vs PK-Sim 34.6% Δ 1.9%).
5. **Optimization** — NSGA-II 100×100, 4 objectives (max F, max Cmax/MIC, max AUC/MIC, min dose) → **TOBP-001 ×125, F96 97.1%, Cmax/MIC 31.2, AUC/MIC 172** (Pareto front degenerates to the max corner; dose is the only opposing objective).
6. **Winner & requirement map** — S07 winner 944 mg ×79 F90.7% → minimal 350 mg Cmax/MIC 9.0 at ×79; S08 map shows **×33 (F 65.9%, AUC/MIC 121.8, min dose 850 mg) already attains AUC≥80 at 993 mg** — ×313 (F 100%, min 450 mg) is not required.
7. **Uncertainty & batteries** — S09 20k draws: F96 88% [35–100] (A) vs 96% [50–100] (B), PTA(Cmax≥8) 81% vs 99%; B1–B10 true 7-day QD/BID (mass balance 0.1%) via `make_repeated_pkml.py`.

Conventions: `F24` = 24-h window (calibration), `F96` = 96-h window (extent, flip-flop tail), `F_ss` = 7-day steady-state. All tables state the window.

---

## Data and Code Availability

- **Snapshots** `01_COMPOUND_DATA/snapshots/` (5 JSON: Amikacin 78K → Tobramycin 64K → Oral 22K → QD/BID 28K) — generated by `03_PKSIM/model/make_tobramycin_json.py` (portable).
- **Manifests** `04_RESULTS/MANIFEST.csv` (90, md5 100%) + `05_ANALYSIS/MANIFEST.csv` (126) + `02_ENGINE/results_run_*/ENGINE_MANIFEST.csv` + `03_PKSIM/results_run_*/PKSIM_OUT_MANIFEST.csv` — every artifact checksummed.
- **Traceability** `03_PKSIM/docs/03_parameter_sources.md` + `06_MANUSCRIPT/appendices/appK_traceability.tex` + `04_RESULTS/README.md` — every figure/table → study ID.
- **Legacy** `02_ENGINE/results_legacy/` + `04_RESULTS/legacy_v01/` cross-checked (34.0% vs 34.6%) — do not feed headline numbers.

---

## Known Issues

- **CRAN R vs Homebrew** — `rSharp` segfaults (`sexp_to_parameters`) on Homebrew R; use `/Library/Frameworks/R.framework/Resources/bin/Rscript`.
- **`.NET 8` required** — `DOTNET_ROOT` must point to a .NET 8+ installation before any `Rscript`.
- **91 SQLite views → tables** — `python3 03_PKSIM/env/patch_pksimdb.py` materializes the PK-Sim database views (OSPSuite-R #1622, fix scheduled for v13, idempotent).

---

## Citation

If you use this repository, please cite both the software and the thesis — GitHub's *Cite this repository* button exports `CITATION.cff` as BibTeX/RIS.

```bibtex
@software{bentaieb2026oral-software,
  title        = {Oral Tobramycin: From BCS III to a Viable Oral Formulation},
  author       = {Ben Taieb, Khaled},
  year         = {2026},
  month        = {9},
  version      = {v1.2.0},
  publisher    = {Independent Research Program — Computational Pharmaceutics},
  url          = {https://github.com/btkhaled/oral-tobramycin-pbpk},
  note         = {PBPK modeling in PK-Sim (OSP) + NSGA-II formulation optimization, 04_RESULTS/MANIFEST.csv 90 artifacts, 06_MANUSCRIPT/main.pdf 185 pp}
}

@phdthesis{bentaieb2026oral-thesis,
  title  = {Oral Tobramycin: From BCS III to a Viable Oral Formulation — A Bibliographic Study with Physiologically Based Pharmacokinetic Modeling in PK-Sim and Multi-Objective Formulation Optimization},
  author = {Ben Taieb, Khaled},
  year   = {2026},
  month  = {9},
  school = {Independent Research Program — Computational Pharmaceutics},
  url    = {https://github.com/btkhaled/oral-tobramycin-pbpk/blob/main/06_MANUSCRIPT/main.pdf},
  note   = {185 pp, 10 chapters (ch00 synopsis → ch09 conclusion) + Appendices A–R, 46 figures, 7 tables, 11 code listings. See also BIBLIOGRAPHY_SUMMARY.md, COMPOUND_SUMMARY.md, ENGINE_SUMMARY.md, PKSIM_SUMMARY.md}
}
```

See [`CITATION.cff`](CITATION.cff) (Khaled Ben Taieb — Independent Research Program — MIT for code, CC BY-NC-ND 4.0 for data/manuscript — 21 keywords, abstract, `preferred-citation`, `references` to PK-Sim and Asad et al. 2023).

---

## License

Code: **MIT** — `LICENSE` · Data and documentation: **CC BY-NC-ND 4.0** — `DATA-LICENSE` · PK-Sim / Open Systems Pharmacology: GPLv2 (external dependency, not redistributed).

**What this means:** you are free to **share** the code, data and manuscript for **non-commercial** academic purposes with attribution, but you may **not** use them commercially nor distribute modified versions without prior written consent. See `LICENSE` and `DATA-LICENSE` for the full terms.

---

> **Reproducibility:** `Rscript run_all.R` (14 steps, `03_PKSIM` → `04_RESULTS` → `05_ANALYSIS` → `06_MANUSCRIPT`) reproduces everything — `04_RESULTS/MANIFEST.csv` + `05_ANALYSIS/MANIFEST.csv` prove it. Validated `00`/`01`/`02`/`03`/`04`/`05` → `06` 185 pp.
