#!/usr/bin/env python3
# ============================================================================
# make_tobramycin_json.py — Build Tobramycin-Model.json from the validated
# Amikacin PK-Sim snapshot (Open Systems Pharmacology Model Library v12.3.1).
# ----------------------------------------------------------------------------
# Strategy (documented in thesis Ch. 3):
#   Tobramycin and amikacin share the aminoglycoside disposition profile
#   (polycation, purely renal GFR-driven clearance, extracellular-limited
#   distribution). The validated amikacin compound building block is renamed
#   and re-parameterized with tobramycin literature values; the renal
#   glomerular-filtration process is kept unchanged. Simulations reference
#   the compound by name, so every reference is updated consistently.
# ============================================================================

import json, copy, pathlib, sys

# Portable: snapshots live in 01_COMPOUND_DATA/snapshots/ (via data/snapshots/ symlink)
# Fallback to legacy PKSIM_V2 path for backward compatibility.
def resolve_src_dst():
    here = pathlib.Path(__file__).resolve()
    # 03_PKSIM/model/make_tobramycin_json.py -> repo root = parents[2]
    proj = here.parents[2]
    src_candidates = [
        proj / "01_COMPOUND_DATA/snapshots/Amikacin-Model.json",
        proj / "data/snapshots/Amikacin-Model.json",  # via symlink
        pathlib.Path("/Users/kalo/TOBRAMYCIN PROJECT/PKSIM_V2/model/inputs/Amikacin-Model.json"),
    ]
    dst_candidates = [
        pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else None,
        proj / "01_COMPOUND_DATA/snapshots/Tobramycin-Model.json",
        proj / "03_PKSIM/model/Tobramycin-Model.json",  # keep copy for pksim/model/
    ]
    src = next((p for p in src_candidates if p and p.exists()), src_candidates[0])
    dst = next((p for p in dst_candidates if p is not None), dst_candidates[1])
    return src, dst

SRC, DST = resolve_src_dst()

d = json.load(open(SRC))

# ---------------------------------------------------------------- compound ---
c = d["Compounds"][0]
c["Name"] = "Tobramycin"

VO = {"Source": "Publication", "Description": "Tobramycin thesis parameterization (PubChem, Chen 2009, Li 2021, Asad 2023)"}

for m in c["Lipophilicity"]:
    for p in m["Parameters"]:
        if p["Name"] == "Lipophilicity":
            p["Value"] = -2.9
            p["ValueOrigin"] = VO

for m in c["FractionUnbound"]:
    for p in m["Parameters"]:
        if p["Name"].startswith("Fraction unbound"):
            p["Value"] = 0.95
            p["ValueOrigin"] = VO

for m in c["Solubility"]:
    pdict = {p["Name"]: p for p in m["Parameters"]}
    if "Solubility at reference pH" in pdict:
        pdict["Solubility at reference pH"]["Value"] = 94000.0   # mg/L (= 94 mg/mL)
        pdict["Solubility at reference pH"]["ValueOrigin"] = VO
    if "Reference pH" in pdict:
        pdict["Reference pH"]["Value"] = 7.0
        pdict["Reference pH"]["ValueOrigin"] = VO

# pKa: tobramycin has 5 basic amines (pKa 6.7, 7.6, 7.7, 7.8, 9.1 — PubChem),
# but PK-Sim compound building blocks support UP TO 3 pKa values per ionization
# type (official limit, PK-Sim documentation). Following the validated amikacin
# model precedent (Claassen 2015: 3 of 4+ amines), the 3 dominant values are
# retained: 7.7, 7.8, 9.1. Impact is negligible here: (i) solubility is never
# limiting (94 mg/mL); (ii) distribution uses PK-Sim Standard partition method
# (pKa-independent); (iii) oral permeability is explicitly overridden per
# candidate in the optimization. Documented in thesis Ch. 3 limitations.
c["PkaTypes"] = [
    {"Type": "Base", "Pka": v, "ValueOrigin": VO}
    for v in (7.7, 7.8, 9.1)
]

for p in c["Parameters"]:
    if p["Name"] == "Molecular weight":
        p["Value"] = 467.515
        p["ValueOrigin"] = VO

# renal process kept: GlomerularFiltration, GFR fraction 1.0 (purely renal,
# >90% unchanged excretion) — identical mechanism for both aminoglycosides.
# NOTE: do NOT change DataSource — simulations reference the process BY NAME
# ("Glomerular Filtration-<DataSource>"); renaming breaks the build silently.

# ---------------------------------------------------------------- protocol ---
# Validation scenario: 7 mg/kg (82.5 kg volunteer) = 577.5 mg, 30-min infusion
for p in d["Protocols"]:
    if p["ApplicationType"] == "Intravenous":
        for par in p["Parameters"]:
            if par["Name"] == "InputDose":
                par["Value"] = 577.5
                par["ValueOrigin"] = VO
            if par["Name"] == "Infusion time":
                par["Value"] = 30.0   # minutes
                par["ValueOrigin"] = VO

# ---------------------------------------------------- consistent references ---
def deep_rename(obj):
    """Rename compound references Amikacin -> Tobramycin in all strings."""
    if isinstance(obj, dict):
        return {k: deep_rename(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [deep_rename(v) for v in obj]
    if isinstance(obj, str):
        return obj.replace("Amikacin", "Tobramycin")
    return obj

d = deep_rename(d)

# --- simulation-level altered parameters -------------------------------------
# The historical Walker simulations carry altered protocol values that override
# the building block (PK-Sim precedence). Fix the infusion time to the clinical
# 30-min extended-interval standard in every individual IV simulation.
for s in d.get("Simulations", []):
    for p in s.get("Parameters", []) or []:
        if p.get("Path", "").endswith("ProtocolSchemaItem|Infusion time"):
            p["Value"] = 30.0

json.dump(d, open(DST, "w"), indent=1)
print("written:", DST)
# Also keep a copy in 03_PKSIM/model/ for pksim/model/ consumption (via symlink data/→01_COMPOUND_DATA, but keep explicit)
proj_model_copy = pathlib.Path(__file__).resolve().parents[2] / "03_PKSIM/model/Tobramycin-Model.json"
if proj_model_copy != pathlib.Path(DST) and proj_model_copy.parent.exists():
    json.dump(d, open(proj_model_copy, "w"), indent=1)
    print("also written:", proj_model_copy)
comp = json.load(open(DST))["Compounds"][0]
print("check:", comp["Name"], "| MW", comp["Parameters"][0]["Value"],
      "| logP", comp["Lipophilicity"][0]["Parameters"][0]["Value"],
      "| fu", comp["FractionUnbound"][0]["Parameters"][0]["Value"],
      "| pKa", [x["Pka"] for x in comp["PkaTypes"]])
