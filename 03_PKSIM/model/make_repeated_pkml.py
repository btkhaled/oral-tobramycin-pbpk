#!/usr/bin/env python3
# ============================================================================
# make_repeated_pkml.py — Generate repeated-dosing PKMLs from the single-dose
# oral PKML by replicating the Application_1 event group, exactly the way
# PK-Sim itself represents multiple applications (one Application_N per dose).
#
# Usage: python3 make_repeated_pkml.py <in.pkml> <out.pkml> <n_apps> <interval_min> [dose_kg]
#   n_apps       number of applications (e.g. 7 = one week QD)
#   interval_min minutes between applications (1440 = QD, 720 = BID)
#   dose_kg      optional: overwrite the Application Dose (base unit kg!)
# Output end time is extended to (n_apps-1)*interval + 1440 min.
# ============================================================================
import re, sys, uuid

def main():
    src, dst, n, interval = sys.argv[1], sys.argv[2], int(sys.argv[3]), float(sys.argv[4])
    dose_kg = float(sys.argv[5]) if len(sys.argv) > 5 else None
    s = open(src, encoding="utf-8-sig").read()

    # --- locate the simulation's Application_1 event group block ---
    i = s.find('<EventGroup id="')
    # find the block whose name is Application_1 and containerType="Application"
    m = re.search(r'<EventGroup id="[^"]+" name="Application_1"[^>]*containerType="Application"[^>]*>', s)
    if not m:
        sys.exit("Application_1 block not found")
    i = m.start()
    depth, j = 0, i
    pat = re.compile(r'<EventGroup\b|</EventGroup>')
    while True:
        mo = pat.search(s, j)
        depth += -1 if mo.group(0).startswith('</') else 1
        j = mo.end()
        if depth == 0:
            break
    block = s[i:j]

    # --- build copies ---
    def retag(txt, k):
        txt = txt.replace('name="Application_1"', f'name="Application_{k}"')
        txt = txt.replace('<Tag value="Application_1" />', f'<Tag value="Application_{k}" />')
        # fresh unique ids for every id= occurrence
        def sub_id(mm):
            return f'id="{uuid.uuid4().hex[:22]}"'
        txt = re.sub(r'id="[^"]+"', sub_id, txt)
        # start time
        txt = re.sub(r'(name="Start time"[^>]*value=")[^"]*(")',
                     rf'\g<1>{k * interval:g}\g<2>', txt, count=1)
        if dose_kg is not None:
            txt = re.sub(r'(name="Dose"[^>]*value=")[^"]*(")',
                         rf'\g<1>{dose_kg / 1e6:g}\g<2>', txt, count=1)
        return txt

    if dose_kg is not None:   # also fix dose of the original application
        block0 = re.sub(r'(name="Dose"[^>]*value=")[^"]*(")',
                        rf'\g<1>{dose_kg / 1e6:g}\g<2>', block, count=1)
        s = s[:i] + block0 + s[j:]
    out = block
    for k in range(1, n):
        out += "\n" + retag(block, k + 1)
    s = s[:i] + out + s[j:]

    # --- extend output interval end time to cover the whole period ---
    end_min = (n - 1) * interval + 1440
    def sub_end(mm):
        return mm.group(1) + f"{end_min:g}" + mm.group(2)
    s = re.sub(r'(name="End time"[^>]*value=")[^"]*(")', sub_end, s, count=1)

    with open(dst, "w", encoding="utf-8") as f:
        f.write(s)
    print(f"wrote {dst}: {n} applications every {interval:g} min, end {end_min:g} min"
          + (f", dose {dose_kg:g} mg" if dose_kg is not None else ""))

if __name__ == "__main__":
    main()
