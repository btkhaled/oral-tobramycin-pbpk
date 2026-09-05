# archive_legacy — 03_PBPK_MODELING (archived)

**Status:** archived — do not promote to results.

| File | Role | Note |
|---|---|---|
| `engine_tobramycin.R` | 2-cpt + transit + Hill, RK4 dt0.01h, pure-R ACAT-lite | **Bug:** native F ~70% (vs PK-Sim F0 1.75%) — double-drain transit + kabs, `summary_results.json` F 69% vs literature 1–2%. Invalidates oral conclusions from this engine alone. |
| `00_setup.R`…`10_export_results.R` | Legacy PBPK chain 00-10 | Kept for lineage (see `02_ENGINE/scripts/00_ga_setup.R` portable fix) |
| `00_setup_legacy.R` | Duplicate of `00_setup.R` | Duplicate kept for diff |
| `module_summary.csv` / `summary_results.json` | Legacy results | F~70% artefact — defer to `03_PKSIM` / `04_RESULTS/` |
| `10_CODE_AND_TOOLS/` (Makefile, custom_functions.R, ospsuite_config.R, renv.lock, session_info.txt) | Tooling | Migrated from `001/10_CODE_AND_TOOLS/` |

**Why archived:** the exploratory engine forged the hypothesis platform (×20 → F34.0%, TOB-161) but its absolute F was mis-calibrated. The PK-Sim engine (`03_PKSIM`, gate 6/6, Pint0 3e-9 → F0 1.75%, mass-balance 0.1%) is the definitive substrate. Cross-check 34.0% vs 34.6% (Δ1.9% relative) is itself a validation (`03_PKSIM/docs/06_legacy_vs_pksim.md`, `06_MANUSCRIPT/ch07_results_ga.tex`).

**Debug journal:** `06_MANUSCRIPT/appendices/appO_debug_journal.tex` (SQLite #1622) and `appQ_plausibility_audit.tex` (integrity audit).

Do not run these scripts in the build finale — use `02_ENGINE/scripts/` (fixed) or `03_PKSIM/studies/` (definitive).
