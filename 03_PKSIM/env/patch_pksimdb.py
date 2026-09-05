#!/usr/bin/env python3
# ============================================================================
# patch_pksimdb.py — Fix PK-Sim snapshot conversion on macOS (OSPSuite-R #1622)
# ----------------------------------------------------------------------------
# loadProjectFromSnapshot()/runSimulationsFromSnapshot() segfault on macOS:
# SQLite view-name resolution overflows the .NET worker-thread stack while
# resolving the 91 views of the bundled PK-Sim database (crash inside
# SQLite.Interop.dylib, viewGetColumnNames <-> selectExpander recursion).
# Upstream: https://github.com/Open-Systems-Pharmacology/OSPSuite-R/issues/1622
#
# Fix: materialize every VIEW into a TABLE (the database is static template
# data; content and column layout are preserved). The converter then finds no
# views to resolve and runs natively on macOS.
#
# Usage:  python3 patch_pksimdb.py
# The script locates the installed {ospsuite} package, backs up the original
# database (PKSimDB.sqlite.bak) and replaces it with the patched copy.
# Re-run after reinstalling/upgrading {ospsuite}. Unnecessary on OSPSuite v13+.
# ============================================================================
import os, re, sqlite3, shutil, sys, glob

def find_pksim_db():
    """Locate PKSimDB.sqlite inside the installed ospsuite R package."""
    candidates = []
    for lib in ["/Library/Frameworks/R.framework/Versions",
                "/usr/local/lib/R", "/usr/lib/R"]:
        candidates += glob.glob(f"{lib}/*/Resources/library/ospsuite/lib/PKSimDB.sqlite")
        candidates += glob.glob(f"{lib}/*/library/ospsuite/lib/PKSimDB.sqlite")
    # R 在 PATH 中时兜底
    try:
        import subprocess
        out = subprocess.run(["Rscript", "-e",
                              "cat(system.file('lib','PKSimDB.sqlite',package='ospsuite'))"],
                             capture_output=True, text=True, timeout=60).stdout.strip()
        if out:
            candidates.append(out)
    except Exception:
        pass
    for c in candidates:
        if os.path.isfile(c):
            return c
    raise FileNotFoundError("PKSimDB.sqlite not found — install the {ospsuite} R package first")

def materialize_views(db_path):
    con = sqlite3.connect(db_path)
    cur = con.cursor()
    views = {r[0]: r[1] for r in cur.execute(
        "SELECT name, sql FROM sqlite_master WHERE type='view'")}
    print(f"views to materialize: {len(views)}")

    def refs(sql):
        return {m for m in re.findall(
            r"(?:FROM|JOIN)\s+\[?([A-Za-z_][A-Za-z0-9_]*)\]?", sql, re.I) if m in views}

    done, order = set(), []
    def visit(v):
        if v in done: return
        for r in refs(views[v]):
            if r != v: visit(r)
        done.add(v); order.append(v)
    for v in views: visit(v)

    for v in order:
        body = re.search(r"\bAS\b(.*)$", views[v], re.S | re.I).group(1).strip()
        cur.execute(f'DROP VIEW IF EXISTS "{v}"')
        cur.execute(f'CREATE TABLE "{v}" AS {body}')
    con.commit()

    # sanity: no views remain, known hot views still queryable
    n = cur.execute("SELECT COUNT(*) FROM sqlite_master WHERE type='view'").fetchone()[0]
    for v in ("ContainerParameters_Species",
              "VIEW_INDIVIDUAL_PARAMETER_NOT_FOR_ALL_SPECIES"):
        cnt = cur.execute(f'SELECT COUNT(*) FROM "{v}"').fetchone()[0]
        print(f"  sanity {v}: {cnt} rows")
    con.close()
    print(f"remaining views: {n} | tables: OK")

def main():
    db = find_pksim_db()
    print("PK-Sim database:", db)
    bak = db + ".bak"
    if not os.path.exists(bak):
        shutil.copy(db, bak)
        print("backup written:", bak)
    tmp = db + ".patched"
    shutil.copy(bak if os.path.exists(bak) else db, tmp)
    materialize_views(tmp)
    shutil.move(tmp, db)
    print("PATCHED:", db)
    print("Done — loadProjectFromSnapshot()/runSimulationsFromSnapshot() should now")
    print("work natively on macOS. Re-run after every {ospsuite} reinstall/upgrade.")

if __name__ == "__main__":
    main()
