# Manuscript — Personal Research (LaTeX, English)

**Title:** *Oral Tobramycin: From BCS III to a Viable Oral Formulation*

## Build

```bash
make          # pdflatex + bibtex + pdflatex x2  ->  main.pdf
make clean
```

Requires TeX Live 2023+ (pdflatex, bibtex; packages: booktabs, siunitx, natbib,
hyperref, cleveref, tikz, listings — all in TeX Live full).

## Current version

- **v0.2** (committed): 129 pages; methodology and results based on the legacy
  custom R engine (`archive/engine_v01/`), full uncertainty program, manufacturing
  and regulatory assessments.

## v1.0 update plan (in progress)

Chapter 3 (methodology) and Chapter 4 (results) are being updated to the
**PK-Sim engine**:

- Ch3: model construction from the validated amikacin snapshot, parameterization
  (`docs/03_parameter_sources.md`), the 3-pKa building-block limit, the macOS
  snapshot-conversion workaround (`docs/02_pksim_macos_workaround.md`),
  native batch runs and sensitivity analysis.
- Ch4: validation gate (6/6), IV scenarios, oral P_int calibration
  (`docs/05_calibration_pint.md`), virtual population, fractionation + PTA,
  NSGA-II-in-the-loop results.
- Legacy results move to a clearly labeled appendix; the cross-check
  (legacy 34.0 % vs PK-Sim 34.6 %) becomes a validation argument.

## Layout

```
main.tex, preamble.tex, references.bib, Makefile
frontmatter/   title page, declaration, abstract, résumé, nomenclature, TOC
chapters/      ch00 synopsis ... ch06 conclusion
appendices/    A Pareto · B Monte Carlo · C sensitivity · D cross-validation
               E evidence table · F candidate sheets · G code · H physico-chem
               I PK literature · J scenarios · K traceability · L glossary
figures/       publication figures (300 dpi)
tables/        generated table bodies
code/          listings of the core scripts
```
