---
theme: seriph
background: https://cover.sli.dev
title: Oral Tobramycin — From BCS III to a Viable Oral Formulation
info: |
  Research presentation — PBPK modeling in PK-Sim and multi-objective
  formulation optimization.
author: Khaled Ben Taieb
keywords: tobramycin, PBPK, PK-Sim, BCS III, oral bioavailability, NSGA-II
drawings:
  persist: false
transition: slide-left
mdc: true
---

# Oral Tobramycin
## From BCS III to a Viable Oral Formulation

A bibliographic study with PBPK modeling in PK-Sim
and multi-objective formulation optimization

<div class="absolute bottom-10">
<span class="font-700">
Khaled Ben Taieb — Personal research — September 2026
</span>
</div>

<div class="abs-br m-6 flex gap-2">
<a href="https://github.com/btkhaled/oral-tobramycin-pbpk" target="_blank" alt="GitHub"
  class="text-xl slidev-icon-btn opacity-50 !border-none !hover:text-white">repository: oral-tobramycin-pbpk</a>
</div>

---
transition: fade-out
---

# The Problem

<br>

- Tobramycin: **WHO-essential aminoglycoside** — first-line against *Pseudomonas aeruginosa* (cystic fibrosis, HAP, UTI)
- Available **only IV and inhaled** — no oral form exists
- Oral bioavailability ≈ **1–2 %** — assumed **BCS class IV** for decades

<div class="grid grid-cols-3 gap-4 pt-6">
<div class="p-4 border rounded" v-click>

**Clinical burden**
Hospitalization, catheters, TDM,
access inequity

</div>
<div class="p-4 border rounded" v-click>

**The assumption**
"Low solubility AND low permeability"
→ wrong toolbox

</div>
<div class="p-4 border rounded" v-click>

**The question**
Can a validated computational path
unlock oral tobramycin?

</div>
</div>

---
layout: two-cols
---

# Finding 1 — It is BCS Class III

Solubility is **never** the limiting factor

| Property | Value | Criterion |
|---|---|---|
| Solubility (water) | **94–100 mg/mL** | highest dose in ≤250 mL |
| Dose margin | **20–200×** | BCS "high" threshold |
| $P_{app}$ | $< 1 \times 10^{-6}$ cm/s | class III boundary |
| Oral $F$ | ≈ 1–2 % | clinical evidence |

::right::

<div class="pl-4 pt-8">

**Explicit statement** — Asad 2023 (PLoS ONE):
> "Tobramycin (TOB) is a BCS class III drug"

**Consequence**: permeability-only problem
→ solubility technologies unnecessary
→ the toolbox is *permeability enhancement*

</div>

---
layout: two-cols
---

# The Permeability Toolbox

| Strategy | Evidence | Lever |
|---|---|---|
| **HIP** (hydrophobic ion pairing) | 1500× logP shift | gene 1 |
| **SEDDS** | spontaneous emulsification | genes 3–5 |
| **Nanoparticles** (PLGA/chitosan) | MIC maintained (Hill 2019) | genes 2, 7, 8 |
| **PE** (sodium caprate C₁₀) | clinical safety record | gene 6 |
| **Enteric coating** | standard technology | gene 9 |

::right::

<div class="pl-4 pt-6">

**The optimization question:**

Which *combination*, at *what dose*,
attains antibacterial exposure targets?

→ 10-gene chromosome
→ NSGA-II multi-objective search

</div>

---
layout: default
---

# Two-Phase Computational Design

<div class="grid grid-cols-2 gap-8 pt-4">
<div>

**Phase I — Exploratory engine** (Ch. 3, 5)
- Purpose-built pure-R engine: 2-compartment PK + GI transit + Hill PD
- 8-factor bioavailability model
- GA (100×200) + NSGA-II (200×300)
- Full uncertainty program: MC n=200, CV n=26, OAT
- **Result: 34 % platform, top-10 formulations**

</div>
<div>

**Phase II — PK-Sim platform** (Ch. 4, 6, 7)
- Whole-body PBPK in PK-Sim 12.4 (Bayer/OSP)
- Built from the *validated amikacin model* (OSP Library)
- Gate-validated vs clinical data — **6/6**
- In-the-loop NSGA-II: **10,000 native evaluations**
- **Result: F = 99.7 % — targets met**

</div>
</div>

<div class="pt-6 text-sm opacity-80">
Cross-validation between engines: 34.0 % vs 34.6 % at the same multiplier (Δ 1.9 % relative) — H5 supported
</div>

---
layout: section
---

# Phase II — Building the PK-Sim Platform

The engineering story: crash → root cause → fix → model

---
layout: two-cols
---

# The macOS Crash (OSPSuite-R #1622)

**Symptom**: `loadProjectFromSnapshot()` → SIGSEGV

**Crash report** (.ips, faulting thread):

```text
SQLite.Interop.dylib:
  sqlite3_log ← lookupName ← resolveExprStep
    ← sqlite3ViewGetColumnNames ↔ selectExpander
    (~90 inlined frames — stack overflow)
```

::right::

<div class="pl-4">

**Root cause**
SQLite view-name resolution overflows
the .NET worker-thread stack while
*emitting a warning*

**The fix** — `patch_pksimdb.py`
Materialize all **91 views** into tables
(static template data; content preserved)
→ PK-Sim runs **natively on macOS**

Upstream: issue #1622, fix scheduled v13
</div>

---
layout: two-cols
---

# Model Build — Amikacin → Tobramycin

No published tobramycin PK-Sim model exists
(structured search: 0 results — documented)

| Parameter | Value |
|---|---|
| MW | 467.515 g/mol |
| logP | −2.9 |
| $f_u$ | 0.95 |
| Solubility | 94 mg/mL |
| pKa (bases) | 7.7, 7.8, 9.1 *(3 of 5 — platform limit)* |
| Renal process | GFR fraction 1.0 |

::right::

<div class="pl-4 pt-4 text-sm">

**Silent traps found & fixed** (documented Ch. 4):
- renal process matched **by name** — renaming breaks clearance silently
- simulation-level **altered parameters** override building blocks (infusion 4→30 min)
- formulation type = `Formulation_Dissolved`, linked in the *simulation's* protocol selection
- units are base units: **dose in kg**, gastric emptying in **minutes**

</div>

---
layout: default
---

# IV Validation Gate — 6/6 PASS

| Metric | PK-Sim | Published target | Verdict |
|---|---|---|---|
| Hartford peak (30 min post-inf) | **25.3 mg/L** | 20–30 mg/L | ✅ |
| Cmax end of infusion | 34.8 mg/L | 20–35 (V₁ envelope) | ✅ |
| AUC24 → implied CL | 102.5 → **5.63 L/h** | CL 3.27–6.03 (Li 2021) | ✅ |
| Trough 24 h | **0.033 mg/L** | < 1 mg/L | ✅ |
| $t_{1/2}$ NCA effective | **2.29 h** | 2.0–3.0 h | ✅ |
| Renal excretion 24 h | **99.4 %** | > 90 % | ✅ |

<br>

The model reproduces the published clinical envelope of IV tobramycin —
validated substrate for the oral program.

<img src="/val_iv_profile.png" class="h-40 rounded shadow mx-auto" />

---
layout: image-right
image: /s02_calibration.png
---

# The Oral Transfer Function F(P_int)

PK-Sim's native P_int for logP −2.9: **~0** (correlation saturates; paracellular off)

<br>

**Calibrated baseline**: P_int₀ = 3×10⁻⁹ dm/min → **F₀ = 1.75 %**
(matches clinical point estimate 1–2 %)

<br>

**The curve saturates beyond ×300** —
enormous headroom above any
single-strategy claim (best: 10–25 %)

<br>

Every formulation candidate = a
**multiplier on P_int₀** — the GA gene
maps directly to the transfer function

---
layout: default
---

# Physiological Studies — S01…S05

<div class="grid grid-cols-2 gap-4">
<div>

**S01 — IV × renal function** (20 scenarios)
CL 1.83 → 7.18 L/h (CLCR 30→150)
trough 3.03 mg/L at CLCR 30 → interval extension

**S03 — Virtual population** (n=100, ICRP)
nominal platform: Cmax/MIC median **4.5** [1.4–13.2]

</div>
<div>

**S04 — Elasticities**
P_int **+0.95** on Cmax · dose 1.00
GFR **−0.84** on AUC · f_u **−0.88**

**S05 — Food effect**
fed: Tmax +0.8 h, Cmax **−26 %**,
**extent unchanged** — BCS III signature ✅

</div>
</div>

<img src="/s04_elasticities.png" class="h-32 rounded shadow mx-auto mt-2" />

---
layout: default
---

# S06 — Flip-Flop Kinetics & the Nominal Limit

- Single oral dose: terminal decline is **absorption-rate-limited** — C(24 h) = 0.72 mg/L
- → 96 h output window required for correct steady-state superposition

<br>

| Regimen (×20 platform) | Cmax_ss/MIC | AUC_ss/MIC |
|---|---|---|
| QD 550 | 5.4 | 49.6 |
| BID 275 | 3.4 | 24.2 |

<br>

**Nominal platform cannot reach the targets** (Cmax/MIC ≥ 8; AUC/MIC 80–120)
→ the optimization must push the platform further

---
layout: two-cols
---

# In-the-Loop NSGA-II

Population 100 × 100 generations · seed 42
**one SimulationBatch per generation** — 10,000 native PK-Sim evaluations

Convergence:

| Gen | best F | best Cmax/MIC |
|---|---|---|
| 1 | 98.3 % | 31.8 |
| 10 | 99.6 % | 43.3 |
| 40 | **99.7 %** | 43.8 |

::right::

<div class="pl-4 pt-6">

**The front degenerates to the corner** —
exposure objectives are synergistic;
only dose opposes

**The finding**: bioavailability
saturates at **×313** — matching the
calibration curve's knee

The clinically relevant question shifts:
*what is the minimal dose that still attains the targets?*

</div>

---
layout: two-cols
---

# The Winner — TOBP-001

**993 mg once daily · P_int ×313 · F = 99.7 %**

- Systemic exposure **indistinguishable from IV**
- **AUC24/MIC = 177** — *above* the 80–120 IV target band
- Dose scan: **minimal target dose = 250 mg QD** (Cmax/MIC = 8.0)
- BID 496: peak PTA 77.5 % @ MIC 0.25 → 34.5 % @ MIC 1

::right::

<div class="pl-4">

<img src="/S07_winner_population.png" class="rounded shadow" />

Population (n=100) on the winner:
**Cmax/MIC median 28.3 [15.7–38.1]
— PTA 100 % at MIC 1 mg/L**

</div>

---
layout: two-cols
---

# The Trade-Off — Trough Liability

Exposure-attaining doses accumulate:
Cmin_ss **4.2 mg/L** (993 QD) vs the **1 mg/L** nephrotoxicity line

<br>

**The clinical answer:**
- **BID 250–496 mg** — peaks maintained, troughs at the safety boundary
- **Bayesian TDM structural, not optional** (as for IV aminoglycosides)
- PTA tables by MIC → regimen selection per local epidemiology

::right::

<div class="pl-4">

<img src="/S07_winner_pta.png" class="rounded shadow" />

Food effect on the winner:
Cmax −26 %, **extent unchanged (F ≈ 100 %)** —
dosing away from meals for peak assurance

</div>

---
layout: default
---

# Cross-Platform Validation — Two Engines, One Answer

| | Legacy custom engine (Phase I) | PK-Sim 12.4 (Phase II) |
|---|---|---|
| Structure | 2-ct ODEs + transit + Hill (RK4) | Whole-body PBPK (ACAT + GFR) |
| Baseline F₀ | 1.5–2.8 % | 1.75 % (calibrated) |
| **Platform F at ×20** | **34.0 %** | **34.6 %** |
| Agreement | $\Delta$ = 0.6 pp — **1.9 % relative** | |

<br>

Phase I was not discarded work — it was the **hypothesis generator**
whose central number the definitive platform confirmed.

---
layout: default
---

# Deliverables

<div class="grid grid-cols-2 gap-6 pt-2">
<div>

**Repository** `oral-tobramycin-pbpk`
- PK-Sim snapshots + validated model artifact (.pkml)
- Environment layer incl. the **#1622 patch** (reusable)
- Study suite S00–S07 (fresh-clone tested)
- NSGA-II in-the-loop suite + checkpoints

**Thesis** — 169 pp, English
10 chapters · 44 figures · 16 appendices

</div>
<div>

**Scientific contributions**
1. BCS III classification resolution
2. First oral tobramycin PBPK program
3. Reusable platform-defect workaround
4. In-the-loop optimization framework
5. Cross-validated, reproducible pipeline

**New kinetic insight**: flip-flop absorption
of the oral platform (96 h tail)

</div>
</div>

---
layout: two-cols
---

# Roadmap — Experimental De-Risking

| Phase | Action |
|---|---|
| **0–6 mo** | Caco-2/Ussing permeability of the HIP complex across ion-pair loading — *the direct ×313 test*; prototype capsule + release |
| **6–12 mo** | Rat/dog oral PK with model refinement; GLP toxicology of the full platform |
| **1–3 y** | Phase I SAD/food-effect → Phase II CF outpatients under Bayesian TDM |
| **Regulatory** | FDA **505(b)(2)** — ~7 years, ~$4.8 M; precedent: oral SNAC platforms |

::right::

<div class="pl-4 pt-6">

**Manufacturing**
ten standard unit operations
feasibility **grade B**
≈ **$4.30/dose**

The ×313 requirement is *aggressive*
but inside the enhancement range
the HIP literature claims (1500× logP)

</div>

---
layout: center
class: text-center
---

# Bottom Line

<div class="text-3xl font-700 pt-6 pb-8">
An IV-only essential antibiotic now has a
validated computational path to oral administration —
with named regimens, quantified exposure,
honest trade-offs, and a costed de-risking program.
</div>

**250 mg — the dose that guards the peak**
**993 mg — the dose that rivals the intravenous bag**
**TDM — the driver's seat**

---

# Thank You

<br>

## Questions

<div class="pt-8 text-sm opacity-80">

Khaled Ben Taieb · repository: `oral-tobramycin-pbpk`
Full thesis: 169 pp — *Oral Tobramycin: From BCS III to a Viable Oral Formulation*

</div>
