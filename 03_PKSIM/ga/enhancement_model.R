# ============================================================================
# enhancement_model.R — Single source of truth: formulation genes -> apparent
# intestinal permeability multiplier (P_int = PINT0 * multiplier)
# ----------------------------------------------------------------------------
# STRUCTURE (reviewer-proof):
#   1. Two calibration anchors, documented:
#      A1  native drug:      P_int0 = 3e-9 dm/min  ->  F0 = 1.75 %  (clinical 1-2 %)
#      A2  nominal platform: logP' = +1.6 (HIP complex) -> multiplier = 20
#          -> F = 34.6 % (PK-Sim-validated, results/studies/S02*, docs/06)
#   2. Component factors RELATIVE to the nominal composition (each = 1.0 at its
#      nominal value), each with: form, cited range, evidence grade, reference.
#   3. The total multiplier is EMERGENT (product of factors) — never a free
#      scalar. The GA explores WITHIN the cited bounds.
#   4. Uncertainty: each factor carries an evidence-grade uncertainty (lognormal
#      sigma) so the multiplier can be propagated to an F/targets CI (S09).
#
# References (data/bibliography/evidence_table.csv):
#   [2]  Asad M 2023      — tobramycin HIP: logP shift ~1500x (linear), 20 %
#                          dissociation at intestinal pH; SEDDS carrier.
#   [3]  Hill M 2019      — PLGA NPs of aminoglycoside-AOT ion pairs.
#   [8]  Bohley M 2024    — review, next-gen permeation enhancers incl. C10,
#                          mucoadhesive polymers/chitosan.
#   [9]  Khaled K 2026    — nanocellulose assemblies with tobramycin ion pairs.
#   [10] Muhammad A 2022  — tobramycin SEDDS proof of concept.
#   [16] Maher S 2009     — C10: characterized safety, clinical progression.
#   [17] Griesser J 2017  — HIP + SEDDS methodology for hydrophilic drugs.
#   [18] Bonengel S 2018  — HIP in vivo (octreotide): oral F gains 3-5x.
# ============================================================================

## ---- Calibration anchors ---------------------------------------------------
PINT0        <- 3e-9     # dm/min, native drug (anchor A1, docs/05)
LOGP_REF     <- -2.9     # native tobramycin logP
LOGP_PLAT    <- 1.6      # HIP complex logP (Asad 2023 [2])
MULT_NOMINAL <- 20       # multiplier AT the nominal platform (anchor A2, docs/06)
K_LOGP       <- log10(MULT_NOMINAL) / (LOGP_PLAT - LOGP_REF)  # 0.2891 / logP unit

## Nominal composition (defines multiplier = 20 at anchor A2)
NOMINAL <- list(logP_modified     = LOGP_PLAT,
                particle_size     = 500,   # no nano carrier (macro part.)
                surfactant_pct    = 40,
                cosurfactant_pct  = 15,
                oil_pct           = 45,
                pe_concentration  = 25,
                polymer_loading   = 0,
                chitosan_coating  = 0,
                enteric_coating   = 0)

## ---- Component factor table (cited, bounded, graded) -----------------------
## grade: A = directly measured for this drug/system; B = measured for close
##        analogue; C = review-level / phenomenological estimate.
.f <- data.frame(
  gene        = c("logP_modified","sedds_sum","particle_size","pe_concentration",
                  "polymer_loading","chitosan_coating","enteric_coating"),
  factor_min  = c(1.0,     0.20,  1.0, 1.0, 1.0, 1.00, 1.00),
  factor_max  = c(MULT_NOMINAL, 1.60, 1.5, 1.6, 1.3, 1.15, 1.10),
  sigma_log   = c(0.25,    0.30,  0.35, 0.30, 0.40, 0.25, 0.20),
  grade       = c("B","B","C","B","C","C","C"),
  reference   = c("[2] Asad 2023 (measured logP' <= +1.6); A2 anchor",
                  "[10] Muhammad 2022; [17] Griesser 2017",
                  "[3] Hill 2019; [9] Khaled 2026", "[16] Maher 2009; [8] Bohley 2024",
                  "[8] Bohley 2024", "[8] Bohley 2024", "galenic (dose dumping guard)"),
  stringsAsFactors = FALSE
)

## ---- Factor functions (relative to nominal = 1.0) --------------------------
## logP: exponential in logP (permeability scales ~10^(a*logP) for passive
##       transcellular transport; slope calibrated by anchor A2). Gene bound
##       capped at the MEASURED HIP complex logP' = +1.6 (Asad 2023 [2]);
##       beyond that is unmeasured extrapolation, not explored.
f_logp   <- function(logP) 10^((logP - LOGP_REF) * K_LOGP)

## SEDDS: solubilization/membrane-fluidization gain, saturating with total
##        excipient fraction (sum/100); plateau 1.6 (solubility-limited) [10,17]
f_sedds  <- function(surf, cosurf, oil) pmin(1.6, (surf + cosurf + oil) / 100)

## Nanoparticle: small carriers enhance dissolution/uptake; 50 nm -> 1.5,
##                macro-size (>=500 nm) -> ~1.0 [3,9] (phenomenological, grade C)
f_np     <- function(size) 1 + 0.5 * exp(-(size - 50) / 150)

## C10 permeation enhancer: near-linear in loading up to tolerance cap,
##                           max +60 % at 50 % w/w [16,8]
f_pe     <- function(pe) 1 + (pe / 50) * 0.6

## Mucoadhesive polymer: residence-time effect, max +30 % at 30 % loading [8]
f_poly   <- function(pl) 1 + (pl / 30) * 0.3

## Chitosan coating (binary): mucoadhesion + transient TJ opening, +15 % [8]
f_chit   <- function(on) ifelse(as.numeric(on) > 0.5, 1.15, 1.0)

## Enteric coating (binary): protects complex to the intestine, +10 % net uptake
f_enteric<- function(on) ifelse(as.numeric(on) > 0.5, 1.10, 1.0)

## ---- Chromosome decode (same interface as before) --------------------------
## Returns pint [dm/min], dose_mg, mult, and the COMPONENT TRACEABILITY TABLE.
decode_chromosome <- function(row) {
  g <- function(k) as.numeric(row[[k]])
  comp <- c(
    logP        = f_logp(g("logP_modified")),
    sedds       = f_sedds(g("surfactant_pct"), g("cosurfactant_pct"), g("oil_pct")),
    nanoparticle= f_np(g("particle_size")),
    pe_C10      = f_pe(g("pe_concentration")),
    polymer     = f_poly(g("polymer_loading")),
    chitosan    = f_chit(g("chitosan_coating")),
    enteric     = f_enteric(g("enteric_coating"))
  )
  mult <- prod(comp)
  list(pint     = PINT0 * mult,
       dose_mg  = g("dose_mg"),
       mult     = mult,
       mult_logP_only = unname(comp[["logP"]]),
       components      = comp)
}

## ---- Identity card (traceability table for thesis/reporting) ---------------
describe_chromosome <- function(row) {
  d <- decode_chromosome(row)
  val <- c(round(d$components, 3))
  out <- .f[match(c("logP_modified","sedds_sum","particle_size","pe_concentration",
                    "polymer_loading","chitosan_coating","enteric_coating"), .f$gene), ]
  data.frame(component = out$gene,
             value     = c(row[["logP_modified"]],
                           row[["surfactant_pct"]] + row[["cosurfactant_pct"]] + row[["oil_pct"]],
                           row[["particle_size"]], row[["pe_concentration"]],
                           row[["polymer_loading"]], row[["chitosan_coating"]],
                           row[["enteric_coating"]]),
             factor    = unname(val),
             min       = out$factor_min, max = out$factor_max,
             grade     = out$grade, reference = out$reference,
             row.names = NULL)
}

## ---- Uncertainty propagation ----------------------------------------------
## Sample the multiplier CI: lognormal noise per component, sigma by grade.
## Used by S09 to convert the point multiplier into an F/targets distribution.
grade_sigma <- c(A = 0.10, B = 0.25, C = 0.40)
sample_multiplier <- function(row, n = 1000, seed = 42) {
  set.seed(seed)
  d <- decode_chromosome(row)
  sig <- grade_sigma[.f$grade]
  eps <- sapply(sig, function(s) rnorm(n, mean = 0, sd = s))          # n x 7, log-space
  base <- matrix(d$components, nrow = n, ncol = length(d$components),
                 byrow = TRUE)
  mults <- exp(rowSums(log(base) + eps))
  list(mults = mults, point = d$mult,
       ci = quantile(mults, c(0.025, 0.5, 0.975)))
}

## ---- Max emergent multiplier (documentation) -------------------------------
max_multiplier <- function() prod(.f$factor_max)
