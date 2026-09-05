# ============================================================================
# check_env.R — 5-point diagnostic of the PK-Sim/{ospsuite} environment
# Run: Rscript check_env.R   (with DOTNET_ROOT set)
# ============================================================================
ok <- function(label, cond, detail = "") {
  status <- ifelse(isTRUE(cond), "OK  ", "FAIL")
  cat(sprintf("[%s] %s %s\n", status, label, detail))
  invisible(isTRUE(cond))
}

r1 <- ok("ospsuite loads", requireNamespace("ospsuite", quietly = TRUE),
         tryCatch(as.character(packageVersion("ospsuite")), error = function(e) ""))
if (!r1) quit(save = "no", status = 1)
suppressMessages(library(ospsuite))

r2 <- tryCatch({ initPKSim(); TRUE }, error = function(e) {
  cat("   error:", conditionMessage(e), "\n"); FALSE })
ok("initPKSim (PK-Sim core)", r2)

r3 <- tryCatch({
  ch <- createIndividualCharacteristics(species = "Human",
        population = "European_ICRP_2002", gender = "MALE", weight = 70, age = 30)
  ind <- createIndividual(individualCharacteristics = ch)
  length(ind$distributedParameters$paths) > 50
}, error = function(e) { cat("   error:", conditionMessage(e), "\n"); FALSE })
ok("createIndividual (DB-backed)", r3)

r4 <- tryCatch({
  sim <- loadSimulation(system.file("extdata", "Aciclovir.pkml", package = "ospsuite"))
  res <- runSimulations(sim)[[1]]
  !is.null(res)
}, error = function(e) { cat("   error:", conditionMessage(e), "\n"); FALSE })
ok("loadSimulation + runSimulations", r4)

r5 <- tryCatch({
  sim <- loadSimulation(system.file("extdata", "Aciclovir.pkml", package = "ospsuite"))
  b <- createSimulationBatch(sim, parametersOrPaths = "Organism|Kidney|GFR (specific)")
  b$addRunValues(0.25); b$addRunValues(0.30)
  res <- runSimulationBatches(b)
  length(res[[1]]) == 2
}, error = function(e) { cat("   error:", conditionMessage(e), "\n"); FALSE })
ok("createSimulationBatch sweep", r5)

cat("\nSummary:", sum(c(r1, r2, r3, r4, r5)), "/ 5 checks passed\n")
cat("If the snapshot conversion is needed, run first: python3 patch_pksimdb.py\n")
quit(save = "no", status = ifelse(all(r1, r2, r3, r4, r5), 0, 1))
