# ============================================================================
# run_ga.R — Launcher: NSGA-II optimization inside the PK-Sim loop
# Usage: Rscript pksim/ga/run_ga.R [pop_size] [generations]
# Outputs: results/ga/{pareto_front.csv, top10.csv, convergence.csv, nsga2_final.rds,
#                     checkpoint_genXXX.rds}
# ============================================================================
suppressMessages(library(dplyr))
PROJ <- (function(){d<-getwd();for(i in 1:6){if(file.exists(file.path(d,"pksim/env/pk_sim_run.R")))return(normalizePath(d));d<-dirname(d)};stop("repo root not found")})()
GA <- file.path(PROJ, "pksim", "ga")
dir.create(file.path(PROJ, "results", "ga"), recursive = TRUE, showWarnings = FALSE)

args <- commandArgs(TRUE)
POP  <- if (length(args) >= 1) as.integer(args[1]) else 100
GEN  <- if (length(args) >= 2) as.integer(args[2]) else 100

source(file.path(GA, "fitness_pksim.R"))     # defines genes context + evaluator
source(file.path(GA, "nsga2_pksim.R"))

genes <- bounds$name
lo <- setNames(as.numeric(bounds$min_val), genes)
hi <- setNames(as.numeric(bounds$max_val), genes)

evaluator <- create_evaluator()
cat(sprintf("NSGA-II in the PK-Sim loop: pop %d x gen %d (seed 42, MIC %.1f mg/L)\n",
            POP, GEN, MIC))
cat(sprintf("P_int0 = %.1e dm/min | platform x20 = %.1e | AUC_IV/mg = %.4f\n\n",
            PINT0, PINT0 * MULT_NOMINAL, AUC_IV_PER_MG))

t0 <- Sys.time()
result <- nsga2_run(genes, lo, hi, evaluator, pop_size = POP, generations = GEN,
                    seed = 42,
                    checkpoint_path = file.path(PROJ, "results", "ga", "checkpoint_gen%03d.rds"),
                    checkpoint_every = 10)
el <- round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1)
cat("\nelapsed:", el, "min\n")

front <- as.data.frame(result$front1)
names(front) <- c("F_oral", "Cmax_MIC", "AUC_MIC", "dose_mg")
front <- front %>% arrange(desc(F_oral))
front$candidate_id <- sprintf("TOBP-%03d", seq_len(nrow(front)))
front$Pint_mult <- sapply(seq_len(nrow(front)), function(i) NA)  # filled below
for (i in seq_len(nrow(front))) {
  row <- result$population_front[which(apply(result$objectives, 1,
          function(o) all(o == front[i, c("F_oral", "Cmax_MIC", "AUC_MIC", "dose_mg")])))[1], ]
  front$Pint_mult[i] <- decode_chromosome(row)$mult
}
write.csv(front, file.path(PROJ, "results", "ga", "pareto_front.csv"), row.names = FALSE)
top10 <- head(front, 10)
write.csv(top10, file.path(PROJ, "results", "ga", "top10.csv"), row.names = FALSE)

conv <- do.call(rbind, lapply(result$history, function(h)
  data.frame(gen = h$gen, best_F = h$best_F, best_Cmax_MIC = h$best_Cmax_MIC)))
write.csv(conv, file.path(PROJ, "results", "ga", "convergence.csv"), row.names = FALSE)
saveRDS(result, file.path(PROJ, "results", "ga", "nsga2_final.rds"))

cat("\n=== GA complete ===\nTop-10 (in-the-loop, PK-Sim):\n")
print(top10, row.names = FALSE)
