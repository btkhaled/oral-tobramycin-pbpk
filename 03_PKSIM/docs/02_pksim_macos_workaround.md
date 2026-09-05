# 02 — PK-Sim snapshot conversion on macOS: root cause and workaround

**Audience:** anyone running `loadProjectFromSnapshot()` / `runSimulationsFromSnapshot()` from `{ospsuite}` on macOS (Apple Silicon or Intel).

## Symptom

`loadProjectFromSnapshot()` segfaults the R process (SIGSEGV) on macOS, right after
`✔ Converting 1 file to project format`. Upstream tracking:
[OSPSuite-R issue #1622](https://github.com/Open-Systems-Pharmacology/OSPSuite-R/issues/1622)
("Running Simulations From Snapshots Crashes on MacOS", opened 2025-09-22; fix scheduled for v13).
The R wrapper additionally hard-blocks `runSimulationsFromSnapshot()` on Darwin.

## Root cause (established empirically on this project)

macOS crash report (`R-*.ips`, faulting thread) shows the crash inside
`SQLite.Interop.dll.dylib`:

```
sqlite3_log ← lookupName ← resolveExprStep ← sqlite3WalkExprNN ← ...
            ← resolveSelectStep ← sqlite3ViewGetColumnNames ← selectExpander ...
```

i.e. the crash occurs **during SQLite view-name resolution while emitting a
warning** (`sqlite3_log`), on a .NET worker thread with a small stack. The PK-Sim
project database ships 91 views; view resolution on that thread overflows the
stack. The view SQL itself is valid (the same queries run fine in the `sqlite3`
CLI). Empirically, everything else works on macOS: `initPKSim()`,
`createIndividual()` (DB-backed), `loadSimulation()`, `runSimulations()`.

## Workaround (this repository)

Materialize the views into tables in a patched copy of the bundled database
(`pksim/env/patch_pksimdb.py`):

1. Copy `PKSimDB.sqlite` (shipped inside the installed `{ospsuite}` package, `lib/`).
2. For each of the 91 views (topological order): `DROP VIEW` + `CREATE TABLE ... AS SELECT`.
   The database is static template data; content and column layout are preserved
   (row counts verified against the original views).
3. Replace the package database with the patched copy (original kept as `.bak`).

Result: no view resolution remains at query-prepare time; conversion, simulation
runs and PKML export then work natively on macOS. All PK-Sim functionality used by
this project runs **in-process, natively, without Docker, VMs or emulators**.

## Verification performed

- Snapshot → project conversion: Amikacin v12.3.1 snapshot converts (project written).
- 11 simulations executed by the PK-Sim engine from the snapshot (native).
- Per-simulation CSV + current-version PKML export (`RunJson` path, `ExportMode` CSV|PKML).
- `createIndividual()` / `createPopulation()` (ICRP 2002) — working.

## Scope and caveats

- The patch is local and reversible (backup `PKSimDB.sqlite.bak`). It must be
  re-applied after reinstalling/upgrading the `{ospsuite}` package.
- Views are materialized at patch time; the PK-Sim DB is template data and does
  not change at runtime, so this is safe for conversion and simulation use.
- Upstream proper fix: PR scheduled for OSPSuite v13 (see issue #1622). After
  upgrading to v13 the patch becomes unnecessary.
