# Compound Summary — Tobramycin (01_COMPOUND_DATA)

> **Scope:** synthesis of the tobramycin parameterization that feeds the entire build finale.
> Canon files: `TOBRAMYCIN_DATA.md` (197L, sheet), `molecular_properties.json` (BCS III), `iv_pk_literature.csv` (9L), `solubility/permeability_literature.csv` (17/10L), `pd_targets.md`, `physicochemical/bcs_classification.md`, `snapshots/` (5 json).

## 1. Identity (→ `TOBRAMYCIN_DATA.md:5`, `molecular_properties.json:4`)

| Property | Value | Source |
|---|---|---|
| CAS / Formula / MW | 32986-56-4 / C18H37N5O9 / 467.515 g/mol | PubChem |
| IDs | CID 36294, DB00710, CHEBI:28950, UNII VZ8RRV54WK | PubChem/DrugBank |
| Structure | 10 chiral centers, 5 pKa 6.7/7.6/7.7/7.8/9.1, polycation at gut pH | `TOBRAMYCIN_DATA.md:25` |
| Class | Aminoglycoside, 30S subunit, WHO Essential J01GB04 | `molecular_properties.json:21` |
| LogP | -2.9 (hydrophilic) | PubChem |

SMILES `NC[C@H]...` / InChI `InChI=1S/C18H37N5O9/.../p+5/...` — see `TOBRAMYCIN_DATA.md:34`.

## 2. BCS (→ `physicochemical/bcs_classification.md:5`)

| Property | Classification | Justification |
|---|---|---|
| Solubility | **HIGH** | 94–100 mg/mL water (Chen 94, BenchChem ≥100, USP 100) = 20–200× criterion (400 mg in <250 mL pH 1.2–6.8) |
| Permeability | **LOW** | Papp <1e-6 cm/s Caco-2 (Asad2023), F 1–2% (<5% envelope) |
| **BCS Class** | **III** | High solubility, low permeability |

> Asad et al. 2023, PLoS ONE: *“Tobramycin (TOB) is a BCS class III drug”* — `bcs_classification.md:15`. The debate III vs IV (see `00_BIBLIOGRAPHY/key_papers/bcs_iv_classification.md:82`) is resolved: **native tobramycin is III** — solubility is never limiting; strategy = permeability only (HIP 1500×, C10, PLGA/KuDa, SEDDS; NOT micronization).

**Cross-link:** calibration `03_PKSIM/docs/05_calibration_pint.md` — Pint0 3e-9 dm/min → F0 1.75% (24h) / 3.5% (96h), platform ×20 → F 34.6% (cross-check 34.0% vs 34.6% Δ1.9%); validation `04_RESULTS/validation/iv_validation_gate.csv` 6/6.

## 3. PK (→ `iv_pk_literature.csv:2`, `solubility_literature.csv:1` 17L, `permeability_literature.csv:1` 10L)

**IV (Li2021 n=140 popPK, 2-cpt):**

| Population | CL (L/h) | V1 (L) | V2 (L) | Q (L/h) | t½ (h) | Vdss | Method |
|---|---|---|---|---|---|---|---|
| Normal adult | 6.03 | 15.1 | — | — | 2.5 | 0.26 | PopPK NONMEM |
| ICU | 3.27 (2.1–4.5) | 21.3 | 16.3 | 2.4 | 4.5–6.0 | 0.30 | ICU, CLCR covariate |
| CF children | 6.37/70kg | 18.7/70kg | — | — | 2.0–3.0 | 0.267 | 10 mg/kg/d QD |

Model used in build: `CL 5.5 V1 17 Q2.4 V2 16 t½2.5 Ke0.277 CLCR^0.72` (`02_ENGINE` + `03_PKSIM`).

**Oral:** F 1–2% point within <5% envelope (`permeability_literature.csv:7`), soluble across pH 1.2–6.8 (FaSSIF/FeSSIF dissolved, `solubility_literature.csv:14-17`), no human oral PK exists — hence PBPK. >90% renal unchanged, fu0.95, GFR frac 1.0.

**Solubility nuance:** DMSO 2 mg/mL (Chen) vs insoluble (Multiple) — `solubility_literature.csv:8-9` — **immaterial for BCS III** (94–100 ≫ 1.6 mg/mL criterion; see `06_MANUSCRIPT/appendices/appH_physchem.tex`).

## 4. PD (→ `pd_targets.md:5`)

| Target | Value | Context |
|---|---|---|
| **Cmax/MIC** | ≥8–10 | Concentration-dependent killing (Craig1998) |
| **AUC24/MIC** | 80–120 | Exposure-response (Li2021) |
| Cmax | 20–30 mg/L | IV peak QD |
| Trough | <1 mg/L | Nephro/oto prevention (TDM) |
| MIC90 P. aeruginosa | 0.5–2 mg/L | EUCAST/CLSI |

Dosing: trad 1.5–2 q8h, QD 5–7 q24h, Hartford q24-48h, CF 10–15 q24h QD — see `TOBRAMYCIN_DATA.md:130`. Final oral regimens (build finale): **QD 250 mg peak (8.0) / 550.6 mg in-band (87.3) / 1000 mg full (172)**, troughs 1.05–1.21 mg/L TDM (`06_MANUSCRIPT/ch07`).

## 5. Snapshots (→ `snapshots/` 5 json, see `snapshots/README.md`)

| File | Size | Role |
|---|---|---|
| `Amikacin-Model.json` | 78K | OSP validated amikacin template (GFR-driven, extracellular) |
| `Tobramycin-Model.json` | 64K | Tobramycin IV (re-parameterized via `03_PKSIM/model/make_tobramycin_json.py`) |
| `Tobramycin-Oral-Model.json` | 22K | Oral Pint0 3e-9 |
| `Tobramycin-Oral-QD-7d.json` / `BID-7d.json` | 28K each | True 7-day repeated dosing (`make_repeated_pkml.py`) |

Validated by `03_PKSIM/studies/S00_validation_gate.R` (6/6 PASS: Hartford 27.55, Cmax 34.83, AUC 102.7, trough 0.033, t½ 2.04, renal 99.4%).

## 6. How to use

- **Sheet:** `TOBRAMYCIN_DATA.md` (197L) — complete human-readable synthesis.
- **Machine:** `molecular_properties.json` (39L) — BCS III, IDs, targets.
- **PK canon:** `iv_pk_literature.csv` (9L) — **canon** (use, not `pk_parameters_literature/iv_pk.csv` duplicata); `oral_pk.csv` (12L) — F estimate 1–2%; `pk_parameters_literature/README.md` documents duplicata.
- **Physchem:** `solubility_literature.csv` (17) + `permeability_literature.csv` (10) + `physicochemical/bcs_classification.md` (48L, proof).
- **PD:** `pd_targets.md` (68L) — PK/PD + TDM + special pops (CF/ICU/renal).
- **Legacy:** `/_legacy/` (3 files) — originaux `001/02_COMPOUND_DATA`, historisés.

---
*Generated for `002 - build finale/01_COMPOUND_DATA` — Sept 2026. See also `00_BIBLIOGRAPHY/BIBLIOGRAPHY_SUMMARY.md` and `03_PKSIM/docs/03_parameter_sources.md`.*
