# ============================================================================
# molecule_battery.R — Complete A-to-Z evaluation of ONE formulation candidate
# ----------------------------------------------------------------------------
# Usage: Rscript molecule_battery.R <molecule_id> <chromosome.csv>
#   chromosome.csv: one row with the 10 genes (logP_modified, particle_size,
#     surfactant_pct, cosurfactant_pct, oil_pct, pe_concentration,
#     polymer_loading, chitosan_coating, enteric_coating, dose_mg)
# Produces results/molecule_<id>/ : identity card, single-dose NCA, dose
# proportionality, TRUE repeated-dosing steady state (QD + BID, 7 d), PK/PD
# targets vs MIC panel, virtual population (n=100), renal impairment, food
# effect, OAT sensitivity on the 7 enhancement components, IV comparison.
# ============================================================================
suppressMessages({library(ospsuite)})
initPKSim()

args <- commandArgs(TRUE)
stopifnot(length(args) >= 2)
MOLID  <- args[1]
CHROM  <- as.list(read.csv(args[2], stringsAsFactors = FALSE))
names(CHROM) <- sub("^X", "", names(CHROM))

PROJ <- (function(){d<-getwd();for(i in 1:6){if(file.exists(file.path(d,"pksim/ga/enhancement_model.R")))return(normalizePath(d));d<-dirname(d)};stop("repo root not found")})()
source(file.path(PROJ, "pksim/ga/enhancement_model.R"))
GA <- file.path(PROJ, "pksim/ga")

OUT <- file.path(PROJ, "results", paste0("molecule_", MOLID))
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
MODEL <- file.path(PROJ, "pksim", "model", "tobramycin_oral.pkml")
MODEL_IV <- file.path(PROJ, "pksim", "model", "tobramycin_iv_validated.pkml")
P_PATH <- "Organism|PeripheralVenousBlood|Tobramycin|Plasma (Peripheral Venous Blood)"
PINT_PATH <- "Tobramycin|Specific intestinal permeability (transcellular)"
DOSE_PATH <- "Events|Tobramycin Oral Protocol|Oral Solution|Application_1|ProtocolSchemaItem|Dose"
GFR_PATH  <- "Organism|Kidney|GFR (specific)"
GT_PATH   <- "Organism|Lumen|Stomach|Gastric emptying time"
MW <- 467.515
MIC_REF <- 1
AUC_IV_PER_MG <- 102.5 / 577.5

cat("==== BATTERY", MOLID, "====\n")
dec <- decode_chromosome(CHROM)
PINT <- dec$pint
DOSE <- dec$dose_mg
cat(sprintf("P_int = %.3e dm/min (mult %.1f) | dose %.1f mg\n", PINT, dec$mult, DOSE))

## helpers ------------------------------------------------------------------
mk_sim <- function(pkml = MODEL) {
  s <- loadSimulation(pkml)
  setOutputInterval(simulation = s, startTime = 0, endTime = 5760, resolution = 10)  # 96-h output
  s
}
set_pint_dose <- function(sim, pint = PINT, dose_mg = DOSE,
                          paths = c(PINT_PATH, DOSE_PATH)) {
  setParameterValuesByPath(parameterPaths = paths,
                           values = c(pint, dose_mg / 1e6), simulation = sim)
  sim
}
profile <- function(sim) {
  res <- runSimulations(sim, silentMode = TRUE)[[1]]
  o <- getOutputValues(res, quantitiesOrPaths = P_PATH)
  df <- as.data.frame(o$data)
  data.frame(t_h = df$Time / 60, c_mgL = df[[P_PATH]] * MW / 1000)
}
nca <- function(p, dose_mg = DOSE, tmax_last = FALSE) {
  tt <- p$t_h; cc <- p$c_mgL
  k <- tt <= 24
  auc <- sum(diff(tt[k]) * (head(cc[k], -1) + tail(cc[k], -1)) / 2)
  k96 <- tt <= 96
  auc96 <- sum(diff(tt[k96]) * (head(cc[k96], -1) + tail(cc[k96], -1)) / 2)
  if (!tmax_last) {
    cmax <- max(cc[k]); tmax <- tt[k][which.max(cc[k])]
  } else {
    k2 <- tt > 144
    cmax <- max(cc[k2]); tmax <- tt[k2][which.max(cc[k2])] - 144
  }
  clast <- cc[k][sum(k)]
  data.frame(Cmax = cmax, Tmax = tmax, AUC24 = auc, AUC96 = auc96,
             F = min(100, (auc96 / dose_mg) / AUC_IV_PER_MG * 100),
             Clast = clast)
}
w <- function(name, df) write.csv(df, file.path(OUT, name), row.names = FALSE)

## B1 — identity card --------------------------------------------------------
cat("- B1 identity card\n")
ic <- describe_chromosome(CHROM)
ic$P_int_dm_min <- PINT
ic$multiplier <- dec$mult
ic$dose_mg <- DOSE
w("B1_identity_card.csv", ic)

## B2 — single dose + NCA ----------------------------------------------------
cat("- B2 single dose\n")
sim <- set_pint_dose(mk_sim())
p <- profile(sim)
w("B2_single_profile.csv", p)
n2 <- nca(p); n2$dose_mg <- DOSE
w("B2_single_nca.csv", n2)

## B3 — dose proportionality (5 doses, single dose) --------------------------
cat("- B3 dose proportionality\n")
doses <- unique(pmax(50, pmin(2000, round(DOSE * c(0.25, 0.5, 1, 1.5, 2)))))
dp <- do.call(rbind, lapply(doses, function(dm) {
  sim <- set_pint_dose(mk_sim(), dose_mg = dm)
  n <- nca(profile(sim), dose_mg = dm)
  cbind(data.frame(dose_mg = dm), n)
}))
w("B3_dose_proportionality.csv", dp)

## B4 — TRUE repeated dosing (7 d QD + 7 d BID) -------------------------------
cat("- B4 repeated dosing\n")
repeated_profile <- function(n_apps, interval_min, daily_mg) {
  per_app_mg <- daily_mg * interval_min / 1440     # QD: daily per app; BID: half
  tmp <- file.path(tempdir(), sprintf("rep_%s_%d_%d_%g.pkml", MOLID, n_apps, interval_min, per_app_mg))
  if (!file.exists(tmp)) {
    cmd <- sprintf("python3 %s %s %s %d %d %f",
                   shQuote(file.path(PROJ, "pksim/model/make_repeated_pkml.py")),
                   shQuote(MODEL), shQuote(tmp), n_apps, interval_min, per_app_mg)
    stopifnot(system(cmd) == 0)
  }
  sim <- loadSimulation(tmp)
  dpath <- sapply(1:n_apps, function(k) sprintf(
    "Events|Tobramycin Oral Protocol|Oral Solution|Application_%d|ProtocolSchemaItem|Dose", k))
  setParameterValuesByPath(parameterPaths = c(PINT_PATH, dpath),
                           values = c(PINT, rep(per_app_mg / 1e6, n_apps)),
                           simulation = sim)
  profile(sim)
}
ss_metrics <- function(p, daily_mg, n_int = 7, interval_h = 24) {
  tt <- p$t_h; cc <- p$c_mgL
  last <- tt > (n_int - 1) * interval_h
  tt2 <- tt[last]; cc2 <- cc[last]
  auc <- sum(diff(tt2) * (head(cc2, -1) + tail(cc2, -1)) / 2)
  cmax <- max(cc2)
  cmin <- min(cc2[tt2 < n_int * interval_h - 0.5])
  per_app <- daily_mg * interval_h / 24
  data.frame(regimen = sprintf("%d x %g mg / %dh", n_int, per_app, interval_h),
             daily_mg = daily_mg, Cmax_ss = cmax, Cmin_ss = cmin,
             AUC_tau = auc, t_ss_h = tt2[which.max(cc2)])
}
ss <- rbind(
  ss_metrics(repeated_profile(7, 1440, DOSE), DOSE, 7, 24),
  ss_metrics(repeated_profile(14, 720, DOSE), DOSE, 14, 12)
)
w("B4_steady_state.csv", ss)

## B5 — PK/PD targets vs MIC panel (from the QD steady state) -----------------
cat("- B5 PK/PD targets\n")
pss <- repeated_profile(7, 1440, DOSE)
tt <- pss$t_h; cc <- pss$c_mgL
last <- tt > 144; tt2 <- tt[last]; cc2 <- cc[last]
auc_tau <- sum(diff(tt2) * (head(cc2, -1) + tail(cc2, -1)) / 2)
mic_panel <- c(0.25, 0.5, 1, 2, 4, 8)
b5 <- do.call(rbind, lapply(mic_panel, function(m) {
  ftmic <- 100 * sum(diff(tt2)[cc2[-1] > m | cc2[-length(cc2)] > m]) / 24
  data.frame(MIC = m, Cmax_MIC = max(cc2) / m, AUC_tau_MIC = auc_tau / m,
             Cmin_MIC = min(cc2[tt2 < 167.5]) / m, fT_MIC_pct = min(100, ftmic))
}))
w("B5_targets_mic.csv", b5)

## B6 — virtual population n=100 (S03 pattern: one population run) -----------
cat("- B6 population\n")
set.seed(42)
pch <- createPopulationCharacteristics(species = "Human",
       population = "European_ICRP_2002", numberOfIndividuals = 100)
pop <- createPopulation(pch)
sim <- set_pint_dose(mk_sim())
resP <- runSimulations(sim, population = pop)[[1]]
oP <- getOutputValues(resP, quantitiesOrPaths = P_PATH)
dfP <- as.data.frame(oP$data)
ids <- unique(dfP$IndividualId)
poprows <- do.call(rbind, lapply(ids, function(id) {
  d2 <- dfP[dfP$IndividualId == id & dfP$Time <= 1440, ]
  cc <- d2[[P_PATH]] * MW / 1000; tt <- d2$Time / 60
  auc <- sum(diff(tt) * (head(cc, -1) + tail(cc, -1)) / 2)
  data.frame(subject = id, Cmax = max(cc), AUC24 = auc,
             Cmax_MIC = max(cc) / MIC_REF, AUC_MIC = auc / MIC_REF)
}))
w("B6_population.csv", poprows)
b6 <- data.frame(n = nrow(poprows),
                 Cmax_MIC_median = median(poprows$Cmax_MIC),
                 Cmax_MIC_p5 = quantile(poprows$Cmax_MIC, .05),
                 Cmax_MIC_p95 = quantile(poprows$Cmax_MIC, .95),
                 AUC_MIC_median = median(poprows$AUC_MIC),
                 AUC_MIC_p5 = quantile(poprows$AUC_MIC, .05),
                 AUC_MIC_p95 = quantile(poprows$AUC_MIC, .95),
                 PTA_Cmax8 = 100 * mean(poprows$Cmax_MIC >= 8),
                 PTA_AUC80 = 100 * mean(poprows$AUC_MIC >= 80))
w("B6_population_summary.csv", b6)

## B7 — renal impairment (CLCR -> GFR specific scaling) -----------------------
cat("- B7 renal impairment\n")
GFR_BASE <- 0.266 * (112.5 / 112.5)  # validated baseline, l/min/kg (S01: GFRspec=0.266*CLCR/112.5)
b7 <- do.call(rbind, lapply(c(100, 60, 40, 20), function(clcr) {
  sim <- set_pint_dose(mk_sim())
  setParameterValuesByPath(parameterPaths = GFR_PATH,
                           values = GFR_BASE * clcr / 112.5, simulation = sim)
  n <- nca(profile(sim))
  cbind(data.frame(CLCR = clcr), n)
}))
w("B7_renal_impairment.csv", b7)

## B8 — food effect -----------------------------------------------------------
cat("- B8 food effect\n")
b8 <- do.call(rbind, lapply(c(15, 90), function(gmin) {
  sim <- set_pint_dose(mk_sim())
  setParameterValuesByPath(parameterPaths = GT_PATH, values = gmin, simulation = sim)
  p <- profile(sim)
  n <- nca(p)
  cbind(data.frame(state = ifelse(gmin <= 15, "fasted", "fed"), gastric_min = gmin), n)
}))
w("B8_food_effect.csv", b8)

## B9 — OAT sensitivity on the 7 enhancement components -----------------------
cat("- B9 OAT sensitivity\n")
comp_names <- c("logP", "sedds", "nanoparticle", "pe_C10", "polymer", "chitosan", "enteric")
b9 <- do.call(rbind, lapply(comp_names, function(cn) {
  do.call(rbind, lapply(c(0.8, 1.2), function(fac) {
    comp <- dec$components
    comp[cn] <- comp[cn] * fac
    pint2 <- PINT0 * prod(comp)
    sim <- set_pint_dose(mk_sim(), pint = pint2)
    n <- nca(profile(sim))
    data.frame(component = cn, factor = fac, P_int = pint2,
               multiplier = prod(comp), F_pct = n$F, Cmax = n$Cmax)
  }))
}))
w("B9_oat_sensitivity.csv", b9)

## B10 — IV comparison at the same daily dose ---------------------------------
cat("- B10 IV comparison\n")
simIV <- loadSimulation(MODEL_IV)
setParameterValuesByPath(parameterPaths = c("Organism|Kidney|GFR (specific)",
  "Events|Walker 1979 Volunteer 1|Application_1|ProtocolSchemaItem|Dose"),
  values = c(0.266, DOSE / 1e6), simulation = simIV)
resIV <- runSimulations(simIV, silentMode = TRUE)[[1]]
oIV <- getOutputValues(resIV, quantitiesOrPaths = P_PATH)
dfIV <- as.data.frame(oIV$data)
ccIV <- dfIV[[P_PATH]] * MW / 1000; ttIV <- dfIV$Time / 60
kIV <- ttIV <= 24
aucIV <- sum(diff(ttIV[kIV]) * (head(ccIV[kIV], -1) + tail(ccIV[kIV], -1)) / 2)
b10 <- data.frame(route = c("IV", "oral (this formulation)"),
                  dose_mg = c(DOSE, DOSE),
                  Cmax = c(max(ccIV[kIV]), n2$Cmax),
                  AUC24 = c(aucIV, n2$AUC24))
b10$relative_exposure_pct <- 100 * b10$AUC24 / aucIV
w("B10_iv_comparison.csv", b10)

cat("==== BATTERY", MOLID, "COMPLETE ->", OUT, "====\n")
