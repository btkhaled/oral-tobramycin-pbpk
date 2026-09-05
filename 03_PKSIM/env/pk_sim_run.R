# ============================================================================
# pk_sim_run.R — Native macOS PK-Sim snapshot runner (issue #1622 workaround)
# ----------------------------------------------------------------------------
# Replicates ospsuite::runSimulationsFromSnapshot WITHOUT the macOS guard.
# The underlying crash (SQLite view resolution stack overflow in the PK-Sim
# converter) is FIXED by the materialized-views PKSimDB.sqlite installed by
# env/patch_pksimdb.py. With the patched database, the PK-Sim CLI core runs
# natively on macOS ARM64: simulations are built at the CURRENT schema and
# exported as CSV (+PKML on request) by PK-Sim itself.
# ============================================================================

pk_sim_init <- function() {
  suppressMessages(library(ospsuite))
  initPKSim()
  invisible(TRUE)
}

#' Run simulations from a PK-Sim snapshot (JSON), export results
#' @param snapshot   path to .json snapshot
#' @param output     output directory
#' @param exportCSV  export per-simulation result CSVs (default TRUE)
#' @param exportPKML export the simulations as .pkml files (needed for GA batches)
#' @exportPKML path
pk_sim_run <- function(snapshot, output, exportCSV = TRUE, exportPKML = FALSE,
                       exportJSON = FALSE, exportXML = FALSE, timeout_s = 600) {
  pk_sim_init()
  stopifnot(file.exists(snapshot))
  dir.create(output, recursive = TRUE, showWarnings = FALSE)
  output <- normalizePath(output)

  # stage the snapshot in a temp folder (mirrors upstream logic)
  temp_dir <- file.path(tempdir(), paste0("snaprun_", format(Sys.time(), "%H%M%S")))
  dir.create(temp_dir, recursive = TRUE)
  file.copy(snapshot, temp_dir)

  opts <- rSharp::newObjectFromName("PKSim.CLI.Core.RunOptions.JsonRunOptions")
  opts$set("InputFolder", temp_dir)
  opts$set("OutputFolder", output)
  opts$set("RunForAllOutputs", FALSE)
  logfile <- file.path(output, "pksim_cli.log")
  tryCatch(opts$set("LogFilesFullPath", logfile), error = function(e) message("log set skipped: ", e$message))
  tryCatch(opts$set("LogLevel", "Debug"), error = function(e) NULL)
  ex_json <- if (isTRUE(exportJSON)) 1L else 0L
  ex_csv  <- if (isTRUE(exportCSV)) 2L else 0L
  ex_xml  <- if (isTRUE(exportXML)) 4L else 0L
  ex_pkml <- if (isTRUE(exportPKML)) 8L else 0L
  opts$set("ExportMode", ex_json + ex_csv + ex_xml + ex_pkml)

  t0 <- Sys.time()
  invisible(rSharp::callStatic("PKSim.R.Api", "RunJson", opts))
  el <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)
  message("PK-Sim run completed in ", el, " s -> ", output)
  invisible(output)
}

#' Convert snapshot to .pksim5 project (optionally running simulations)
pk_sim_convert <- function(snapshot, output, runSimulations = FALSE) {
  pk_sim_init()
  stopifnot(file.exists(snapshot))
  dir.create(output, recursive = TRUE, showWarnings = FALSE)
  output <- normalizePath(output)
  temp_dir <- file.path(tempdir(), paste0("snapconv_", format(Sys.time(), "%H%M%S")))
  dir.create(temp_dir, recursive = TRUE)
  file.copy(snapshot, temp_dir)
  opts <- rSharp::newObjectFromName("PKSim.CLI.Core.RunOptions.SnapshotRunOptions")
  opts$set("InputFolder", temp_dir)
  opts$set("OutputFolder", output)
  opts$set("RunSimulations", isTRUE(runSimulations))
  opts$set("ExportMode", 0L)
  logfile <- file.path(output, "pksim_cli.log")
  tryCatch(opts$set("LogFilesFullPath", logfile), error = function(e) message("log set skipped: ", e$message))
  tryCatch(opts$set("LogLevel", "Debug"), error = function(e) NULL)
  t0 <- Sys.time()
  invisible(rSharp::callStatic("PKSim.R.Api", "RunSnapshot", opts))
  el <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)
  message("PK-Sim conversion completed in ", el, " s -> ", output)
  invisible(output)
}
