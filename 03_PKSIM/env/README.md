# PK-Sim Environment (macOS-first, works on Linux/Windows too)

## Requirements

| Component | Version | Notes |
|---|---|---|
| R | ≥ 4.4 | tested with 4.6.1 (CRAN, arm64) |
| `{ospsuite}` | 12.4.4 | install from the OSP r-universe: `install.packages("ospsuite", repos=c("https://open-systems-pharmacology.r-universe.dev","https://cloud.r-project.org"))` |
| `{rSharp}` | ≥ 1.2 | pulled by `{ospsuite}` |
| .NET runtime | 8.x | `DOTNET_ROOT` must point to it (e.g. `~/.dotnet`) |
| Python 3 | ≥ 3.9 | only for `patch_pksimdb.py` |

## One-time setup

```bash
export DOTNET_ROOT="$HOME/.dotnet"          # adapt to your .NET install
export PATH="$DOTNET_ROOT:$PATH"

Rscript check_env.R        # 5-point diagnostic (ospsuite, initPKSim, individual, snapshot, batch)
python3 patch_pksimdb.py   # apply the macOS snapshot-conversion fix (see docs/02)
```

## What `check_env.R` verifies

1. `{ospsuite}` loads and reports its version
2. `initPKSim()` initializes the PK-Sim core (12.3.173)
3. `createIndividual()` builds an ICRP-2002 adult from the PK-Sim database
4. `loadSimulation()` + `runSimulations()` execute a bundled simulation
5. `createSimulationBatch` / `runSimulationBatches` complete a 2-value sweep

## Notes

- The patched database is excluded from git (`*.sqlite`); `patch_pksimdb.py`
  regenerates it from the package's bundled database in ~2 s.
- On Linux/Windows the patch is harmless (the bug is macOS-specific) but not needed.
- After upgrading `{ospsuite}`, re-run the patch.
