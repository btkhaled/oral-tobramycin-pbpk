# Bibliography Summary — Oral Tobramycin (00_BIBLIOGRAPHY)

> **Scope:** synthesis of the 20-article evidence base that underpins the build finale.
> Canon files: `evidence_table.csv` (20), `references.bib` (20), `search_strategy.md` (PICO).
> Draft chapters `chapters/ch1-ch3` remain valid; `ch4-ch6` are pre-sim placeholders — definitive results are in `06_MANUSCRIPT/ch05-ch07` and `04_RESULTS/`.

## 1. Search (→ `search_strategy.md:5`)

**Question:** *Oral Tobramycin: From BCS III to a Viable Oral Formulation* — PICO (Population CF/Gram-negative infections; Intervention HIP/SEDDS/nanoparticles/PE; Comparison IV/inhaled; Outcome F, PK, efficacy, safety).

**Databases (Sept 2026):** PubMed/MEDLINE, Scopus, Web of Science, Google Scholar, ClinicalTrials.gov. Blocks: Drug (`tobramycin`), BCS (`BCS class III/IV, solubility, permeability`), Formulation (`SEDDS, nanoparticle, PLGA, HIP, permeation enhancer, chitosan`), Modeling (`PBPK, PK-Sim, ospsuite, GastroPlus, ACAT`), Clinical (`CF, Pseudomonas, TDM, AUC/MIC`).

**Yield:** 300–500 hits → ~50–80 included after dedup (Primary BCS 50-100 + Formulation 100-200 + PBPK 200-500). Inclusion EN/FR 1995–2026, peer-reviewed/in vitro/in silico/in vivo/clinical; exclusion abstracts-only/single cases/topical-only.

## 2. Evidence base (→ `evidence_table.csv:1`, 20 articles)

| Category (n) | Key IDs | What they give us | Relevance |
|---|---|---|---|
| **BCS foundation** (4) | Amidon1995, FDA2021, ICH2019, Wikipedia/Volpe | 4-class system, biowaiver Class I+III, solubility ≤250 mL pH1-6.8 / perm ≥85% | Foundation |
| **Formulation — HIP/SEDDS** (3) | Asad2023, Muhammad2022, Griesser2017, Bonengel2018 | Asad2023 **CRITICAL**: TOB = BCS III (explicit), HIP with docusate 1:5 → logP 1500× (–2.9→~+1.6), SEDDS 1% LogD>2, dissoc 20% pH gut, zeta flip; Bonengel octreotide pig HIP in vivo 3–5× | High |
| **Formulation — nanoparticles** (3) | Hill2019 (PLGA+AOT 178-267 nm, MIC 1.25 µg/mL), Blanco-Cabra2022 (KuDa SCPN 10-20 nm 40 wt%, biofilm), Khaled2026 (NCAs, latest) | Proof of concept oral transition, loading 2.7-4.5 µg/mg, charge-neutral diffusion | High |
| **PK modeling** (3) | Li2021 (popPK n=140 CL 3.27/6.03 V1 21.3/15.1 expθ0.72), Ferreira2021, Lukacova2010 (first TOB PBPK, GastroPlus pulm) | Parameters for validation (CL 5.5 V1 17 Q2.4 V2 16 used in `02_ENGINE` + `03_PKSIM`) | High/medium |
| **Permeation enhancers / clinical** (7) | Bohley2024 (C10/PPZ/SDC, 30d mice safety), Maher2009 (C10 gold std), Smyth2005 TOPIC QD non-inferior, Ramsey1999 TOBI 300 mg BID, Struiken2024 PTA | C10 GRAS clinical, SNAC FDA (semaglutide precedent), PPZ/SDC next-gen — safety for repeated dosing | High/foundation |

**Three pillars that carry the thesis:** (1) **Asad2023** = BCS III proof + HIP→+1.6 cap, (2) **Li2021** = CL/V1/Q/V2 + CLCR covariate for gate 6/6, (3) **Bohley2024/Maher2009** = PE safety window for C10 10-50 mM.

## 3. Key papers synthesis (→ `key_papers/*.md`)

- **BCS (`bcs_iv_classification.md:5`):** solubility 94–100 mg/mL ≫ 250 mL criterion → HIGH (20–200×), perm Papp<1e-6 + F 1–2% → LOW → **BCS III** (Asad explicit). IV label in older literature conflates “hard to absorb” with “low solubility”. ICH/FDA M9 biowaiver applies to III — regulatory path exists; focus = permeability only (not micronization).
- **Absorption (`tobramycin_pk_absorption.md:3`):** HIP 1500× is partition, not perm; dissoc 20% at 4 h limits, PLGA MIC preserved, KuDa charge-neutral 10-20 nm, C10 PPZ SDC 30d mice no permanent opening — all in vitro/mice, gap = no oral PK in humans.
- **Formulation (`oral_tobramycin_formulation.md:72`):** predicted bioavail per lever HIP+SEDDS 10–30%, PLGA 5–15%, KuDa 5–20%, C10 5–20%, SNAC 10–25% — no head-to-head, no PBPK, no food/regional data, no trials → our gap.
- **PBPK (`pbpk_modeling_bcs_iv.md:3` + `pk_sim_validation.md:3`):** PK-Sim ACAT 7 GI segments, population, sensitivity; GastroPlus precedent (Lukacova pulm, Ferreira), PK-Sim tutorials (aciclovir→cipro→morphine), NO shareable TOB-PK-Sim model found — hence amikacin OSP snapshot (`01_COMPOUND_DATA/snapshots/Amikacin-Model.json`) + `03_PKSIM/model/make_tobramycin_json.py`.

## 4. Chapters mapping (→ `chapters/ch1-ch6` vs `06_MANUSCRIPT/`)

- **ch1_intro (106L) / ch2_literature_review (183L) / ch3_pbpk_methodology (188L):** still valid — BCS table I-IV, sol/perm evidence, Li2021/Ramsey/Smyth, 6-step workflow (compound→base→IV→oral→OAT→pop). Keep as foundations.
- **ch4_results (34L):** placeholder `*This chapter will be populated*` → **do not expand here**. Definitive: `06_MANUSCRIPT/ch05` (GA exploratory F34%), `ch06` (gate 6/6, S01-S06, flip-flop), `ch07` (NSGA-II ×125 F96 97.1%, S08 reqmap, batteries A/B), `04_RESULTS/` + `05_ANALYSIS/`.
- **ch5_discussion (112L) / ch6_conclusion (83L):** pre-sim thresholds F<5%/>15% and 400–800 mg generic — superseded by `06_MANUSCRIPT/ch08` (H1–H5 Supported, trough 1.05–1.21 TDM) + `ch09` (5 findings, ×20 F34.6% → ×125 ceiling, 250 mg peak / 550 mg in-band / 1000 mg full, 467 mg floor).

## 5. Gaps that the build finale closes (→ `03_PKSIM/docs/04_study_design.md`, `06_MANUSCRIPT/ch08`)

- **Before:** no oral PK, no oral PBPK for TOB, no combinatorial multi-objective opt, no food/regional/pop variability.
- **Now:** calibrated Pint0 3e-9 → F0 1.75%, cited-bounded enhancement (7 factors A/B/C σ, cap ×126.3, logP +1.6 measured), true 7-day dosing mass-balance 0.1%, S00 gate 6/6 S01 20 scenarios S02 11 pts S03 100 ICRP S04 OAT S05 food 15 vs 60 min S06 QD/BID/TID S07 winner S08 9×8 reqmap S09 20k uncertainty, batteries A (×73.9) / B (×125) B1-B10, pop PTA 95/79% vs 100/97%.

## 6. How to use

- **Single source:** `evidence_table.csv` (20, columns `article_id … notes`) — filter by `category`/`relevance`.
- **Citations:** `references.bib` (20, BibTeX) — build with `bibtex` (see `06_MANUSCRIPT/Makefile`).
- **Protocol:** `search_strategy.md` (PICO, 5 DB, blocks 1-5, inclusion 1995–2026 EN/FR).
- **Deep dives:** `key_papers/*.md` (1-page per theme, summary table p.127).
- **Traceability:** every figure/table in `06_MANUSCRIPT/appendices/appK_traceability.tex` + `03_PKSIM/docs/03_parameter_sources.md`.

---
*Generated for `002 - build finale/00_BIBLIOGRAPHY` — Sept 2026. See also `06_MANUSCRIPT/frontmatter/abstract.tex:5` (BCS III) and `03_PKSIM/docs/06_legacy_vs_pksim.md` (34.0% vs 34.6% cross-check).*
