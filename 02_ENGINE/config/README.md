# 02_ENGINE/config — Bounds (canon vs legacy)

**Canon (use):**

- `parameter_bounds.csv` — 10 genes, **cap logP +1.6** (measured HIP, Asad2023) → max emergent multiplier ×126.3
- `ga_config.json` — physio Vd17 CL5.5 t½2.5 Ke0.277 Ka1.5 + weights 0.40/0.25/0.25/0.10 + GA pop100×200 run20 seed42, **max logP 1.6** (fixed, was 3.0)

**Legacy (archive):**

- `parameter_bounds_legacy.csv` / `ga_config_legacy.json` — max logP 3.0 → artefact ×313 corner (free multiplier, not cited). Kept for provenance; do not run. See `03_PKSIM/docs/07_multiplier_methodology.md` (2 anchors + 7 factors graded A/B/C, cap ×126.3) and `06_MANUSCRIPT/appendices/appQ_plausibility_audit.tex`.

**Rule:** optimizer must use **+1.6** cap. ×313 is sensitivity-only (see `03_PKSIM/docs/07`).

**History:** fixed in build finale (was 3.0 in `001/Formulation_Candidate/GA_OPTIMIZATION/config/`).
