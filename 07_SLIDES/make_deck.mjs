// ============================================================================
// make_deck.mjs — Generate the defense deck with pptxgenjs (pure Node,
// no browser). 28 slides, real project numbers, figures from public/.
// Run:  node make_deck.mjs   ->  export/oral-tobramycin-defense.pptx
// ============================================================================
import pptxgen from "pptxgenjs";

const BLUE = "005493";
const DARK = "1A2A3A";
const RED = "C0392B";
const GREY = "5A6B7A";

const pptx = new pptxgen();
pptx.defineLayout({ name: "WIDE", width: 13.33, height: 7.5 });
pptx.layout = "WIDE";
pptx.author = "Khaled Ben Taieb";
pptx.title = "Oral Tobramycin: From BCS III to a Viable Oral Formulation";

const W = 13.33, H = 7.5;
let slideNo = 0;

function newSlide(title, subtitle) {
  slideNo++;
  const s = pptx.addSlide();
  s.background = { color: "FFFFFF" };
  if (title) {
    s.addText(title, { x: 0.6, y: 0.35, w: W - 1.2, h: 0.9, fontSize: 32, bold: true, color: BLUE });
    if (subtitle) s.addText(subtitle, { x: 0.62, y: 1.15, w: W - 1.2, h: 0.5, fontSize: 15, color: GREY });
    s.addShape("rect", { x: 0.6, y: 1.02, w: 2.2, h: 0.05, fill: { color: BLUE } });
  }
  s.addText(`${slideNo}`, { x: W - 0.8, y: H - 0.45, w: 0.5, h: 0.3, fontSize: 11, color: GREY, align: "right" });
  s.addText("oral-tobramycin-pbpk", { x: 0.6, y: H - 0.45, w: 3, h: 0.3, fontSize: 10, color: "AAAAAA" });
  return s;
}

function bullets(s, items, opts = {}) {
  const arr = items.map(([txt, lvl]) => ({ text: txt, options: {
    bullet: lvl ? { code: "2013", indent: 18 } : { code: "2022" },
    fontSize: opts.fontSize || 18, color: DARK, paraSpaceAfter: opts.space ?? 8, indentLevel: lvl || 0,
    bold: false,
  }}));
  s.addText(arr, { x: opts.x ?? 0.7, y: opts.y ?? 1.7, w: opts.w ?? 6, h: opts.h ?? 5.2, valign: "top" });
}

function table(s, rows, opts = {}) {
  const header = rows[0].map(t => ({ text: t, options: { bold: true, color: "FFFFFF", fill: { color: BLUE }, fontSize: opts.fs || 13 } }));
  const body = rows.slice(1).map((r, i) => r.map(t => ({ text: String(t), options: {
    fontSize: opts.fs || 13, color: DARK, fill: { color: i % 2 ? "F2F6FA" : "FFFFFF" } } })));
  s.addTable([header, ...body], { x: opts.x ?? 0.7, y: opts.y ?? 1.8, w: opts.w ?? 11.9,
    border: { type: "solid", color: "D5DEE8", pt: 0.5 }, rowH: opts.rowH || 0.42, align: "left" });
}

function img(s, path, opts = {}) {
  s.addImage({ path: `public/${path}`, x: opts.x ?? 0.7, y: opts.y ?? 1.75,
    w: opts.w ?? 7.5, h: opts.h ?? 5.0, sizing: { type: "contain", w: opts.w ?? 7.5, h: opts.h ?? 5.0 } });
  if (opts.caption) s.addText(opts.caption, { x: opts.x ?? 0.7, y: (opts.y ?? 1.75) + (opts.h ?? 5.0) + 0.05,
    w: opts.w ?? 7.5, h: 0.4, fontSize: 11, color: GREY, italic: true, align: "center" });
}

// ============================================================ 1. TITLE ====
{
  slideNo++;
  const s = pptx.addSlide();
  s.background = { color: DARK };
  s.addText("Oral Tobramycin", { x: 0.8, y: 1.9, w: W - 1.6, h: 1.2, fontSize: 54, bold: true, color: "FFFFFF" });
  s.addText("From BCS III to a Viable Oral Formulation", { x: 0.8, y: 3.0, w: W - 1.6, h: 0.8, fontSize: 26, color: "9CC3E4" });
  s.addText("A bibliographic study with PBPK modeling in PK-Sim\nand multi-objective formulation optimization",
    { x: 0.8, y: 4.1, w: W - 1.6, h: 0.9, fontSize: 16, color: "C9D6E2" });
  s.addText("Khaled Ben Taieb — Personal research — September 2026",
    { x: 0.8, y: 6.3, w: W - 1.6, h: 0.5, fontSize: 16, color: "FFFFFF", bold: true });
  s.addText("repository: oral-tobramycin-pbpk", { x: 0.8, y: 6.85, w: W - 1.6, h: 0.4, fontSize: 12, color: "7A92A8" });
}

// ========================================================= 2. PROBLEM ====
{
  const s = newSlide("The Problem", "An essential antibiotic locked out of the oral route");
  bullets(s, [
    ["Tobramycin: WHO-essential aminoglycoside — first-line against Pseudomonas aeruginosa (CF, HAP, UTI)", 0],
    ["Available only IV and inhaled — no oral formulation exists", 0],
    ["Oral bioavailability ≈ 1–2 % — assumed BCS class IV for decades", 0],
    ["Clinical burden: hospitalization, catheters, access inequity in low-resource settings", 1],
    ["The wrong assumption (\"low solubility AND low permeability\") drives the wrong toolbox", 1],
    ["Research question: can a validated computational path unlock oral tobramycin?", 0],
  ], { fontSize: 19 });
}

// ===================================================== 3. BCS III ========
{
  const s = newSlide("Finding 1 — It is BCS Class III, not IV", "Solubility is never the limiting factor");
  table(s, [
    ["Property", "Value", "Criterion"],
    ["Solubility (water)", "94–100 mg/mL", "highest dose soluble in ≤250 mL"],
    ["Dose margin", "20–200×", "BCS 'high' threshold"],
    ["Papp", "< 1×10⁻⁶ cm/s", "class III boundary"],
    ["Oral F", "≈ 1–2 %", "clinical evidence"],
  ], { y: 1.8, w: 11.9 });
  s.addText([
    { text: "Explicit statement — Asad 2023 (PLoS ONE): ", options: { fontSize: 17, color: DARK, breakLine: true } },
    { text: "\u201CTobramycin (TOB) is a BCS class III drug\u201D", options: { fontSize: 20, italic: true, bold: true, color: BLUE, breakLine: true } },
    { text: "", options: { breakLine: true } },
    { text: "Consequence: a permeability-only problem → solubility technologies are unnecessary → the toolbox is permeability enhancement.", options: { fontSize: 17, color: DARK } },
  ], { x: 0.7, y: 4.6, w: 11.9, h: 2.2, valign: "top" });
}

// ================================================== 4. TOOLBOX ===========
{
  const s = newSlide("The Permeability Toolbox", "Five validated levers, one 10-gene chromosome");
  table(s, [
    ["Strategy", "Evidence", "GA lever"],
    ["HIP — hydrophobic ion pairing", "1500× logP shift (Asad 2023)", "gene 1"],
    ["SEDDS", "spontaneous emulsification", "genes 3–5"],
    ["Nanoparticles (PLGA/chitosan)", "MIC maintained (Hill 2019)", "genes 2, 7, 8"],
    ["PE — sodium caprate C₁₀", "clinical safety record", "gene 6"],
    ["Enteric coating", "standard technology", "gene 9"],
  ], { y: 1.8, w: 11.9 });
  s.addText("The optimization question: which combination, at what dose, attains antibacterial exposure targets?",
    { x: 0.7, y: 6.0, w: 11.9, h: 0.6, fontSize: 18, bold: true, color: BLUE });
}

// ============================================== 4b. ENHANCEMENT MODEL =====
{
  const s = newSlide("The Enhancement Model — Cited, Bounded, Emergent", "No free multiplier: 7 factors × 2 anchors");
  table(s, [
    ["Component", "Form", "Max", "Grade"],
    ["HIP logP' (Asad 2023)", "10^((logP+2.9)·K), gene capped +1.6", "20x", "B"],
    ["SEDDS fraction (Muhammad 2022)", "min(1.6, sum/100)", "1.6x", "B"],
    ["Nanoparticle size (Hill 2019)", "1+0.5·exp(-(size-50)/150)", "1.5x", "C"],
    ["C10 loading (Maher 2009)", "1+0.6·(pe/50)", "1.6x", "B"],
    ["Polymer (Bohley 2024)", "1+0.3·(pl/30)", "1.3x", "C"],
    ["Chitosan / enteric", "x1.15 / x1.10 if on", "1.27x", "C"],
  ], { y: 1.75, w: 11.9, fs: 12, rowH: 0.42 });
  s.addText("Anchors: native P_int0 = 3e-9 (F = 1.75 %) · nominal x20 platform — emergent maximum x126.3, optimizer attains x125",
    { x: 0.7, y: 6.5, w: 11.9, h: 0.5, fontSize: 13, bold: true, color: BLUE });
}

// =================================================== 5. TWO PHASES =======
{
  const s = newSlide("Two-Phase Computational Design", "One optimization logic, two engines");
  bullets(s, [
    ["Phase I — Exploratory engine (pure R, Chapters 3 & 5)", 0],
    ["2-compartment PK + GI transit + Hill PD + 8-factor bioavailability model", 1],
    ["GA (100×200) + NSGA-II (200×300); MC n=200, CV n=26, OAT", 1],
    ["Result: 34 % platform, top-10 formulations, manufacturing $4.30/dose (grade B)", 1],
    ["Phase II — PK-Sim platform (Chapters 4, 6, 7)", 0],
    ["Whole-body PBPK built from the validated amikacin model (OSP Library)", 1],
    ["Gate-validated vs clinical data — 6/6; calibrated oral transfer function", 1],
    ["In-the-loop NSGA-II: ~6,100 native evaluations (pop 100, converged gen 60)", 1],
  ], { fontSize: 17 });
  s.addText("Cross-validation between engines: 34.0 % vs 34.6 % at the same multiplier (Δ 1.9 % relative) — hypothesis H5 supported",
    { x: 0.7, y: 6.35, w: 11.9, h: 0.6, fontSize: 14, bold: true, color: BLUE });
}

// ================================================ 6. SECTION DIVIDER =====
{
  slideNo++;
  const s = pptx.addSlide();
  s.background = { color: BLUE };
  s.addText("Phase II — Building the PK-Sim Platform", { x: 1, y: 2.8, w: W - 2, h: 1.2, fontSize: 40, bold: true, color: "FFFFFF" });
  s.addText("The engineering story: crash → root cause → fix → validated model",
    { x: 1, y: 4.0, w: W - 2, h: 0.6, fontSize: 20, color: "C9D6E2" });
}

// ==================================================== 7. CRASH ===========
{
  const s = newSlide("The macOS Crash — OSPSuite-R issue #1622", "Symptom → crash report → root cause → fix");
  s.addText([
    { text: "Symptom: ", options: { bold: true, fontSize: 16, color: DARK } },
    { text: "loadProjectFromSnapshot() → SIGSEGV on macOS (wrapper hard-blocks Darwin)", options: { fontSize: 16, color: DARK, breakLine: true } },
    { text: "Crash report (.ips, faulting thread):", options: { bold: true, fontSize: 16, color: DARK, breakLine: true } },
    { text: "SQLite.Interop.dylib:\n  sqlite3_log ← lookupName ← resolveExprStep\n  ← sqlite3ViewGetColumnNames ↔ selectExpander\n  (~90 inlined frames — stack overflow)", options: { fontFace: "Courier New", fontSize: 13, color: "FFFFFF", fill: { color: DARK }, breakLine: true } },
  ], { x: 0.7, y: 1.7, w: 6.2, h: 4.6, valign: "top", paraSpaceAfter: 8 });
  bullets(s, [
    ["Root cause: SQLite view-name resolution overflows the .NET worker-thread stack while emitting a warning", 0],
    ["Fix: materialize all 91 views into tables (static template data; content preserved) — patch_pksimdb.py", 0],
    ["Result: PK-Sim runs natively on macOS — conversion, simulations, PKML export, populations", 0],
    ["Upstream: issue #1622, fix scheduled v13; workaround reusable by the community", 0],
  ], { x: 7.1, y: 1.7, w: 5.6, h: 5.0, fontSize: 15 });
}

// ==================================================== 8. MODEL BUILD =====
{
  const s = newSlide("Model Build — Amikacin → Tobramycin", "No published tobramycin PK-Sim model exists (structured search: 0 results)");
  table(s, [
    ["Parameter", "Value", "Note"],
    ["Molecular weight", "467.515 g/mol", "PubChem"],
    ["logP", "−2.9", "native drug"],
    ["Fraction unbound", "0.95", "minimal binding"],
    ["Solubility", "94 mg/mL", "never limiting (BCS III)"],
    ["pKa (bases)", "7.7, 7.8, 9.1", "3 of 5 amines — platform limit"],
    ["Renal process", "GFR fraction 1.0", "purely renal clearance"],
  ], { y: 1.75, w: 7.2, fs: 12 });
  s.addText([
    { text: "Silent traps found & fixed (Ch. 4):", options: { bold: true, fontSize: 14, color: RED, breakLine: true } },
    { text: "renal process matched by name — renaming breaks clearance silently", options: { fontSize: 13, color: DARK, bullet: { code: "2022" }, breakLine: true } },
    { text: "simulation-level altered parameters override building blocks (infusion 4→30 min)", options: { fontSize: 13, color: DARK, bullet: { code: "2022" }, breakLine: true } },
    { text: "formulation type = Formulation_Dissolved, linked in the simulation's protocol selection", options: { fontSize: 13, color: DARK, bullet: { code: "2022" }, breakLine: true } },
    { text: "units are base units: dose in kg, gastric emptying in minutes", options: { fontSize: 13, color: DARK, bullet: { code: "2022" } } },
  ], { x: 8.1, y: 1.75, w: 4.6, h: 5.0, valign: "top", paraSpaceAfter: 6 });
}

// ==================================================== 9. GATE ============
{
  const s = newSlide("IV Validation Gate — 6/6 PASS", "577.5 mg (7 mg/kg), 30-min infusion, 82.5-kg volunteer");
  table(s, [
    ["Metric", "PK-Sim", "Published target", "Verdict"],
    ["Hartford peak (30 min post-inf)", "25.3 mg/L", "20–30 mg/L", "PASS"],
    ["Cmax end of infusion", "34.8 mg/L", "20–35 (V1 envelope)", "PASS"],
    ["AUC24 → implied CL", "102.5 → 5.63 L/h", "CL 3.27–6.03 (Li 2021)", "PASS"],
    ["Trough 24 h", "0.033 mg/L", "< 1 mg/L", "PASS"],
    ["t½ NCA effective", "2.29 h", "2.0–3.0 h", "PASS"],
    ["Renal excretion 24 h", "99.4 %", "> 90 %", "PASS"],
  ], { y: 1.7, w: 7.6, fs: 12 });
  img(s, "val_iv_profile.png", { x: 8.5, y: 1.7, w: 4.3, h: 4.4 });
  s.addText("The model reproduces the published clinical envelope — validated substrate for the oral program.",
    { x: 0.7, y: 6.5, w: 11.9, h: 0.5, fontSize: 15, bold: true, color: BLUE });
}

// ============================================= 9b. DUAL CONVENTION ======
{
  const s = newSlide("Two Windows, One Truth — F24 vs F96", "Flip-flop kinetics forces the distinction");
  table(s, [
    ["", "24-h window (F24)", "96-h window (F96)"],
    ["Native (x1)", "1.75 % — calibration to clinical 1-2 %", "3.5 % — extent incl. flip-flop tail"],
    ["Nominal platform (x20)", "34.6 % (legacy cross-check 34.0 %)", "~49 %"],
    ["Winner (x125)", "91.6 %", "97.1 %"],
  ], { y: 1.8, w: 11.9, fs: 13, rowH: 0.55 });
  bullets(s, [
    ["Clinical 1–2 % is a 24-h-era estimate: calibration uses F24, extent claims use F96", 0],
    ["Both conventions reported side by side throughout — no hidden window switches", 0],
  ], { y: 5.3, w: 11.9, h: 1.6, fontSize: 16 });
}

// ==================================================== 10. CALIBRATION ====
{
  const s = newSlide("The Oral Transfer Function F(P_int)", "Calibrated, not fitted silently");
  img(s, "s02_calibration.png", { x: 0.6, y: 1.7, w: 8.4, h: 5.0 });
  bullets(s, [
    ["Native PK-Sim P_int for logP −2.9: ~0 (correlation saturates; paracellular off by default)", 0],
    ["Calibrated baseline: P_int₀ = 3×10⁻⁹ dm/min → F₀ = 1.75 % (clinical 1–2 %)", 0],
    ["Extent curve (96 h) saturates past ×100; 24-h window saturates earlier — both conventions reported", 0],
    ["Every GA candidate = an emergent multiplier on P_int₀ — 7 cited factors, max ×125 (measured logP cap)", 0],
  ], { x: 9.2, y: 1.7, w: 3.6, h: 5.2, fontSize: 13 });
}

// ==================================================== 11. STUDIES ========
{
  const s = newSlide("Physiological Studies — S01…S05", "All PK-Sim-native, batch-executed");
  table(s, [
    ["Study", "Design", "Key result"],
    ["S01 — IV × renal (20 scenarios)", "doses × CLCR 30–150 mL/min", "CL 1.83 → 7.18 L/h; trough 3.0 at CLCR 30"],
    ["S03 — Virtual population (n=100)", "ICRP 2002, nominal ×20 platform", "Cmax/MIC median 4.5 [1.4–13.2]"],
    ["S04 — Elasticities (±20 %)", "P_int, dose, GFR, f_u", "P_int +0.95 Cmax; GFR −0.84 AUC; f_u −0.88"],
    ["S05 — Food effect", "GET 15 vs 60 min", "Cmax −20 %, extent unchanged (BCS III)"],
  ], { y: 1.8, w: 11.9, fs: 13 });
  img(s, "s04_elasticities.png", { x: 2.9, y: 4.9, w: 7.5, h: 2.2 });
}

// ==================================================== 12. S06 ============
{
  const s = newSlide("S06 — Flip-Flop Kinetics & the Nominal Limit", "A genuine kinetic discovery");
  bullets(s, [
    ["Single oral dose: terminal decline is absorption-rate-limited — C(24 h) = 0.72 mg/L", 0],
    ["→ steady-state superposition requires a 96 h window (flip-flop kinetics)", 0],
    ["Nominal platform (×20) at 550–600 mg: AUC_ss/MIC ≤ 50 — map shows attainment from 993 mg", 0],
    ["QD 550: Cmax_ss 5.4, AUC_ss 49.6 — BID 275: 3.4 / 24.2", 0],
    ["Conclusion: the optimization must push the platform further", 0],
  ], { fontSize: 17 });
  img(s, "s06_fractionation.png", { x: 7.4, y: 1.9, w: 5.4, h: 3.4 });
}

// ========================================== 12b. REQUIREMENT MAP ========
{
  const s = newSlide("The Requirement Map — S08", "What a real formulation must deliver, dose by dose");
  img(s, "s08_requirement_map.png", { x: 0.6, y: 1.7, w: 8.0, h: 4.9 });
  bullets(s, [
    ["x20 at 993 mg: BOTH targets met (9.7 / 93.5) — the nominal multiplier suffices", 0],
    ["Beyond x33: buys dose reduction, not new attainment", 0],
    ["x125 ceiling: same targets at 467 mg — troughs at the line", 0],
    ["Tiered, falsifiable: >=x20 for targets · x125 max", 0],
  ], { x: 8.8, y: 1.7, w: 3.9, h: 5.0, fontSize: 13 });
}

// ==================================================== 13. GA LOOP ========
{
  const s = newSlide("In-the-Loop NSGA-II — Converged at Generation 60", "One SimulationBatch per generation; seed 42; cited-bounds enhancement model");
  table(s, [
    ["Gen", "best F96", "best Cmax/MIC", "median dose"],
    ["1", "92.2 %", "20.4", "834 mg"],
    ["10", "96.6 %", "30.2", "1000 mg"],
    ["60", "97.1 %", "31.2", "1000 mg"],
  ], { y: 1.8, w: 6.6, fs: 14 });
  bullets(s, [
    ["The front degenerates to the corner — exposure objectives are synergistic; only dose opposes", 0],
    ["The finding: the optimum sits at the cited-bounds corner (×125) — the best the evidence supports", 0],
    ["The clinically relevant question shifts: what is the minimal dose that still attains the targets?", 0],
  ], { x: 7.5, y: 1.8, w: 5.3, h: 4.5, fontSize: 15 });
  s.addText("The degeneracy is itself a finding — answered by the winner's dose scan (next).",
    { x: 0.7, y: 6.4, w: 11.9, h: 0.5, fontSize: 14, italic: true, color: GREY });
}

// ==================================================== 14. WINNER =========
{
  const s = newSlide("The Winner — TOBP-001", "1000 mg once daily · P_int ×125 (cited max) · F96 = 97.1 %");
  table(s, [
    ["Regimen", "Cmax_ss/MIC", "AUC_ss/MIC", "Cmin_ss (mg/L)"],
    ["QD 250 (minimal peak dose)", "8.0", "~43", "~0.4"],
    ["QD 1000 (winner)", "32.2", "172.3", "1.21"],
    ["BID 500", "17.6", "172.2", "2.34"],
  ], { y: 1.75, w: 7.4, fs: 12 });
  s.addText([
    { text: "AUC/MIC = 172 — ABOVE the 80–120 IV target band (in-band from 467 mg)", options: { bold: true, fontSize: 17, color: BLUE, breakLine: true } },
    { text: "Minimal target-attaining dose: 250 mg QD (Cmax/MIC = 8.0)", options: { fontSize: 15, color: DARK, bullet: { code: "2022" }, breakLine: true } },
    { text: "Population (n=100): Cmax/MIC 40.9 [15.8–88.8] PTA 100 % · AUC/MIC 238, PTA≥80: 97 %", options: { fontSize: 15, color: DARK, bullet: { code: "2022" } } },
  ], { x: 0.7, y: 5.0, w: 7.4, h: 2.0, valign: "top", paraSpaceAfter: 6 });
  img(s, "S07_winner_population.png", { x: 8.3, y: 1.75, w: 4.5, h: 3.6 });
  s.addText("Virtual population — 100 % peak attainment",
    { x: 8.3, y: 5.4, w: 4.5, h: 0.4, fontSize: 11, color: GREY, italic: true, align: "center" });
}


// ==================================================== 14b. ID CARD ======
{
  const s = newSlide("Formulation Identity Card — TOBP-001", "Decoded chromosome: what the pharmacist must manufacture");
  table(s, [
    ["Component", "Specification"],
    ["HIP complex (ion pairing)", "apparent logP' = +1.6 (measured complex; lit. 1500x shift)"],
    ["Nanoparticle platform", "polymer NPs, particle size ≈ 50 nm"],
    ["SEDDS system", "surfactant-rich ceiling: 60% / 29% co / 70% oil"],
    ["Permeation enhancer", "sodium caprate (C10) 50 mM"],
    ["Mucoadhesive polymer", "29.3% loading"],
    ["Coatings", "chitosan (TJ modulation) + enteric HPMC-AS"],
    ["Dose", "1000 mg once daily"],
    ["PK-Sim implementation", "P_int override 3.75e-7 dm/min = ×125 (cited max)"],
  ], { y: 1.7, w: 7.5, fs: 12, rowH: 0.44 });
  img(s, "S07_winner_profile.png", { x: 8.4, y: 1.7, w: 4.4, h: 3.5 });
  s.addText("Single dose: F96 97.1% | Cmax 31.2 mg/L | AUC96 172.3 — flip-flop tail visible",
    { x: 8.4, y: 5.3, w: 4.4, h: 0.8, fontSize: 11, color: GREY, italic: true, align: "center" });
}

// ==================================================== 14c. REGIMEN MENU ==
{
  const s = newSlide("One Platform, Three Operating Points", "Identity-card comparison (steady state, MIC 1 mg/L)");
  table(s, [
    ["Card", "Dose (mg)", "P_int mult", "F96 (%)", "Cmax_ss/MIC", "AUC_ss/MIC", "Cmin_ss (mg/L)"],
    ["TOBP-001 (winner)", "1000", "×125", "97.1", "32.2", "172.3", "1.21"],
    ["TOBP-250 (sparing)", "250", "×125", "~96", "8.0", "~43", "~0.4"],
    ["TOB-161-A (legacy)", "550", "×73.9", "89.3", "13.6", "87.3", "1.05"],
  ], { y: 1.8, w: 11.9, fs: 13, rowH: 0.5 });
  bullets(s, [
    ["Card 1 answers \"what is the ceiling\" — near-IV exposure (AUC/MIC 172 > 80–120)", 0],
    ["Card 2 answers \"what is the minimum\" — a quarter of the dose still guards the peak (Cmax/MIC = 8)", 0],
    ["Card 3 is the conservative platform the physiological studies characterized in depth", 0],
    ["TDM selects the operating point per patient and per local MIC (PTA tables, Appendix N)", 0],
  ], { y: 4.6, w: 11.9, h: 2.4, fontSize: 16 });
}

// ========================================= 14d. HEAD-TO-HEAD BATTERY =====
{
  const s = newSlide("Two Candidates, One Battery — A vs B", "Same model, same enhancement mapping, same 10-block protocol");
  table(s, [
    ["", "TOB-161-A (legacy GA)", "TOBP-001 (PK-Sim GA)"],
    ["Multiplier", "x73.9", "x125.0 (cited max)"],
    ["Dose QD", "550.6 mg", "1000 mg"],
    ["F96 / F24", "89.3 % / 77.9 %", "97.1 % / 91.6 %"],
    ["AUC_ss/MIC", "87.3 (IN BAND)", "172.3 (above; in-band from 467 mg)"],
    ["Cmin_ss", "1.05 mg/L", "1.21 mg/L"],
    ["Population PTA", "95 % peak / 79 % AUC", "100 % peak / 97 % AUC"],
    ["Food effect", "extent same, Cmax -31 %", "extent same, Cmax -32 %"],
  ], { y: 1.7, w: 11.9, fs: 12, rowH: 0.44 });
  s.addText("TOB-161-A: the conservative in-band option · TOBP-001: the upper design point — the space between is the experimental search interval",
    { x: 0.7, y: 6.5, w: 11.9, h: 0.5, fontSize: 14, bold: true, color: BLUE });
}

// ============================================== 14e. PTA vs MIC ===========
{
  const s = newSlide("Target Attainment vs MIC — True 7-Day Dosing", "Battery B5 block, both candidates");
  img(s, "battery_pta.png", { x: 1.4, y: 1.7, w: 10.5, h: 5.0 });
  s.addText("fT>MIC 99.6 % at MIC 1 for both · TOBP-001 holds the peak to MIC 2, TOB-161-A to MIC 1",
    { x: 0.7, y: 6.8, w: 11.9, h: 0.4, fontSize: 14, bold: true, color: BLUE });
}

// ==================================================== 15. TRADE-OFF ======
{
  const s = newSlide("The Trade-Off — Trough Liability", "The optimization inverts the clinical question");
  bullets(s, [
    ["Both candidates sit AT the 1 mg/L line (QD troughs 1.05–1.21) — BID pushes above it (2.34)", 0],
    ["The problem flips from \"can we absorb enough?\" to \"how do we safely dose what we can now absorb?\"", 0],
    ["Clinical answer: QD regimens for trough safety; BID 500 for fT>MIC 100% with TDM", 0],
    ["Bayesian TDM is structural, not optional — the virtual population provides the prior", 0],
    ["Food effect on the winner: Cmax −32 %, extent unchanged (F96 97.1/97.2 %) — dose away from meals", 0],
  ], { fontSize: 17 });
  img(s, "S07_winner_pta.png", { x: 7.4, y: 1.9, w: 5.4, h: 3.6 });
}

// ============================================== 15b. S09 FRONTIER =========
{
  const s = newSlide("Uncertainty, Propagated — S09 Frontier", "20,000 draws through the validated response curve");
  img(s, "S09_frontier.png", { x: 0.6, y: 1.7, w: 8.0, h: 4.9 });
  bullets(s, [
    ["Per-component lognormal sigmas by evidence grade (A 0.10 · B 0.25 · C 0.40)", 0],
    ["TOBP-001: F96 96 % [51–100] · AUC/MIC 172 [97–179] — robust", 0],
    ["TOB-161-A: F96 88 % [35–100] · AUC 87 [39–99] — dose-limited", 0],
    ["Not assumed away — quantified", 0],
  ], { x: 8.8, y: 1.7, w: 3.9, h: 5.0, fontSize: 13 });
}

// ========================================== 15c. MASS BALANCE ============
{
  const s = newSlide("Trust, Verified — Mass Balance & True Dosing", "The engine checks its own arithmetic");
  table(s, [
    ["Check", "Predicted", "Simulated", "Verdict"],
    ["AUC_tau = F·D/CL (TOB-161-A)", "87.38 mg·h/L", "87.25 (true 7-day QD)", "0.15 % OK"],
    ["AUC_tau = F·D/CL (TOBP-001)", "172.20 mg·h/L", "172.28 (true 7-day QD)", "0.05 % OK"],
    ["Superposition vs true dosing", "49.6 (screening)", "48.0 (true QD 550, x20)", "~3 % OK"],
  ], { y: 1.8, w: 11.9, fs: 13, rowH: 0.6 });
  bullets(s, [
    ["Repeated dosing = PKML Application replication (one Application_k per dose — exactly how PK-Sim represents it)", 0],
    ["Screening sweeps may use superposition; headline values use true dosing", 0],
  ], { y: 5.2, w: 11.9, h: 1.6, fontSize: 16 });
}

// ==================================================== 16. CROSS-CHECK ====
{
  const s = newSlide("Cross-Platform Validation — Two Engines, One Answer", "Hypothesis H5");
  table(s, [
    ["", "Legacy custom engine (Phase I)", "PK-Sim 12.4 (Phase II)"],
    ["Structure", "2-ct ODEs + transit + Hill (RK4)", "Whole-body PBPK (ACAT + GFR)"],
    ["Baseline F₀", "1.5–2.8 %", "1.75 % (calibrated)"],
    ["Platform F at ×20", "34.0 %", "34.6 %"],
    ["Agreement", "Δ = 0.6 pp — 1.9 % relative", ""],
  ], { y: 1.8, w: 11.9, fs: 14 });
  s.addText("Phase I was not discarded work — it was the hypothesis generator whose central number the definitive platform confirmed.",
    { x: 0.7, y: 5.6, w: 11.9, h: 0.6, fontSize: 17, bold: true, color: BLUE });
}

// ========================================== 16b. REGIMENS ================
{
  const s = newSlide("Clinical Regimens — From the Battery", "QD for trough safety · BID for interval coverage · TDM structural");
  table(s, [
    ["Regimen", "Cmax_ss/MIC", "AUC_ss/MIC", "Cmin_ss", "Role"],
    ["QD 250 (TOBP-001 platform)", "8.0", "~43", "~0.4", "peak guard, safest trough"],
    ["QD 550.6 (TOB-161-A)", "13.6", "87.3", "1.05", "in-band, trough at line"],
    ["QD 1000 (TOBP-001)", "32.2", "172.3", "1.21", "full exposure, TDM mandatory"],
    ["BID 500 (TOBP-001)", "17.6", "172.2", "2.34", "fT 100%, trough above line"],
  ], { y: 1.8, w: 11.9, fs: 12, rowH: 0.5 });
  s.addText("Renal impairment CLCR 100 to 20: AUC x3.4–3.5 — dose adaptation mandatory, as with IV",
    { x: 0.7, y: 6.5, w: 11.9, h: 0.5, fontSize: 14, bold: true, color: BLUE });
}

// ==================================================== 17. ROADMAP ========
{
  const s = newSlide("Roadmap — Experimental De-Risking", "505(b)(2) · ~7 years · ~$4.8 M · manufacturing grade B ≈ $4.30/dose");
  table(s, [
    ["Phase", "Action"],
    ["0–6 months", "Caco-2/Ussing permeability of the HIP complex — the direct ×20/×125 test; prototype capsule + release"],
    ["6–12 months", "Rat/dog oral PK with model refinement; GLP toxicology of the full platform"],
    ["1–3 years", "Phase I SAD/food-effect → Phase II CF outpatients under Bayesian TDM"],
    ["Regulatory", "FDA 505(b)(2); precedent: oral SNAC platforms"],
  ], { y: 1.8, w: 11.9, fs: 14, rowH: 0.7 });
  s.addText("The ×125 ceiling is what the evidence permits, not what it guarantees — each tier is falsifiable.",
    { x: 0.7, y: 6.4, w: 11.9, h: 0.5, fontSize: 14, italic: true, color: GREY });
}

// ==================================================== 18. BOTTOM LINE ====
{
  slideNo++;
  const s = pptx.addSlide();
  s.background = { color: DARK };
  s.addText("Bottom Line", { x: 1, y: 0.8, w: W - 2, h: 0.8, fontSize: 34, bold: true, color: BLUE === "005493" ? "6FB1E3" : BLUE });
  s.addText(
    "An IV-only essential antibiotic now has a validated computational path\nto oral administration — with named regimens, quantified exposure,\nhonest trade-offs, and a costed de-risking program.",
    { x: 1, y: 2.0, w: W - 2, h: 1.8, fontSize: 22, color: "FFFFFF" });
  s.addText([
    { text: "250 mg — the dose that guards the peak", options: { fontSize: 19, color: "9CC3E4", bullet: { code: "2022" }, breakLine: true } },
    { text: "1000 mg — the dose that rivals the intravenous bag (AUC/MIC 172)", options: { fontSize: 19, color: "9CC3E4", bullet: { code: "2022" }, breakLine: true } },
    { text: "TDM — the driver's seat (troughs at the line, managed by monitoring)", options: { fontSize: 19, color: "9CC3E4", bullet: { code: "2022" } } },
  ], { x: 1, y: 4.2, w: W - 2, h: 1.6, valign: "top", paraSpaceAfter: 10 });
  s.addText("Thank you — Questions", { x: 1, y: 6.4, w: W - 2, h: 0.6, fontSize: 24, bold: true, color: "FFFFFF" });
}

// ==================================================== WRITE ==============
await pptx.writeFile({ fileName: "export/oral-tobramycin-defense.pptx" });
console.log(`Deck written: export/oral-tobramycin-defense.pptx (${slideNo} slides)`);
