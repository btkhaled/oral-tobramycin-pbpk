# ============================================================================
# nsga2_pksim.R — Minimal, dependency-free NSGA-II (Deb 2002)
# Objectives (maximized): F_oral, Cmax/MIC, AUC24/MIC; dose minimized (4th).
# The evaluator receives a WHOLE population matrix (one PK-Sim batch per call).
# Checkpointing every `checkpoint_every` generations; fixed seed.
# ============================================================================

nsga2_run <- function(genes, lo, hi, eval_fn, pop_size = 100, generations = 100,
                      pcross = 0.9, pmut = 0.1, etac = 20, etam = 20,
                      seed = 42, checkpoint_path = NULL, checkpoint_every = 10,
                      verbose = TRUE) {
  set.seed(seed)

  sample_pop <- function(n) {
    m <- sapply(genes, function(g) runif(n, lo[[g]], hi[[g]]))
    colnames(m) <- genes; m
  }
  evaluate <- function(m) {
    objs <- eval_fn(m)
    objs[!is.finite(objs[, 1]), 1] <- -1e6     # failed runs last
    objs
  }
  sbx <- function(p1, p2) {
    u <- runif(length(genes))
    beta <- ifelse(u <= 0.5, (2 * u)^(1 / (etac + 1)), (1 / (2 * (1 - u)))^(1 / (etac + 1)))
    ifelse(runif(length(genes)) < 0.5,
           0.5 * ((1 + beta) * p1 + (1 - beta) * p2),
           0.5 * ((1 - beta) * p1 + (1 + beta) * p2))
  }
  mutate <- function(child) {
    for (j in seq_along(genes)) if (runif(1) < pmut) {
      u <- runif(1)
      if (u < 0.5) child[j] <- child[j] - (child[j] - lo[[j]]) * (1 - runif(1)^(1 / (etam + 1)))
      else         child[j] <- child[j] + (hi[[j]] - child[j]) * (1 - runif(1)^(1 / (etam + 1)))
    }
    pmin(pmax(child, lo[genes]), hi[genes])
  }
  nondominated_ranks <- function(objs) {
    n <- nrow(objs); ranks <- integer(n)
    for (i in 1:n)
      ranks[i] <- 1 + sum(apply(objs, 1, function(o)
        all(o >= objs[i, ]) && any(o > objs[i, ])))
    ranks
  }
  crowding <- function(idx, objs) {
    d <- numeric(length(idx))
    if (length(idx) <= 2) { d[] <- Inf; return(d) }
    o <- objs[idx, , drop = FALSE]
    for (j in seq_len(ncol(o))) {
      ord <- order(o[, j]); d[ord[1]] <- d[ord[length(ord)]] <- Inf
      rng <- max(o[, j]) - min(o[, j]); if (rng == 0) next
      for (i in 2:(length(ord) - 1))
        d[ord[i]] <- d[ord[i]] + (o[ord[i + 1], j] - o[ord[i - 1], j]) / rng
    }
    d
  }

  pop <- sample_pop(pop_size)
  obj <- evaluate(pop)
  history <- list()

  for (gen in 1:generations) {
    ranks <- nondominated_ranks(obj)
    crow <- numeric(length(ranks))
    for (rk in unique(ranks)) crow[ranks == rk] <- crowding(which(ranks == rk), obj)
    parents <- replicate(pop_size, {
      a <- sample(pop_size, 2)
      if (ranks[a[1]] < ranks[a[2]] ||
          (ranks[a[1]] == ranks[a[2]] && crow[a[1]] > crow[a[2]])) a[1] else a[2]
    })
    child_m <- matrix(NA_real_, pop_size, length(genes), dimnames = list(NULL, genes))
    for (i in seq(1, pop_size, 2)) {
      p1 <- pop[parents[i], ]; p2 <- pop[parents[(i %% pop_size) + 1], ]
      if (runif(1) < pcross) { c1 <- sbx(p1, p2); c2 <- sbx(p2, p1) } else { c1 <- p1; c2 <- p2 }
      child_m[i, ] <- mutate(c1)
      if (i + 1 <= pop_size) child_m[i + 1, ] <- mutate(c2)
    }
    child_m <- pmin(pmax(child_m,
      matrix(lo[genes][rep(1, pop_size), drop = FALSE], nrow = pop_size, ncol = length(genes)),
      matrix(hi[genes][rep(1, pop_size), drop = FALSE], nrow = pop_size, ncol = length(genes))))

    child_obj <- evaluate(child_m)
    all_m <- rbind(pop, child_m); all_obj <- rbind(obj, child_obj)
    ranks <- nondominated_ranks(all_obj)
    keep <- c()
    for (rk in sort(unique(ranks))) {
      idx <- which(ranks == rk)
      if (length(keep) >= pop_size) break
      if (length(keep) + length(idx) <= pop_size) { keep <- c(keep, idx); next }
      cr <- crowding(idx, all_obj)
      keep <- c(keep, idx[order(-cr)][1:(pop_size - length(keep))]); break
    }
    keep <- keep[keep >= 1 & keep <= nrow(all_m)]
    pop <- all_m[keep, , drop = FALSE]      # keep indexes the COMBINED parent+child set
    obj <- all_obj[keep, , drop = FALSE]

    front1 <- obj[ranks[keep] == 1, , drop = FALSE]
    history[[gen]] <- list(gen = gen, front = front1,
                           best_F = max(obj[, 1]), best_Cmax_MIC = max(obj[, 2]),
                           median_dose = median(obj[, 4]))
    if (verbose && (gen %% 10 == 0 || gen == 1))
      cat(sprintf("[gen %3d] front1=%d  best F=%6.2f%%  best Cmax/MIC=%5.2f\n",
                  gen, sum(ranks[keep] == 1), max(obj[, 1]), max(obj[, 2])))
    if (!is.null(checkpoint_path) && gen %% checkpoint_every == 0)
      saveRDS(list(pop = pop, obj = obj, history = history),
              sprintf(checkpoint_path, gen))
  }
  ranks <- nondominated_ranks(obj)
  list(population = pop, objectives = obj,
       front1 = obj[ranks == 1, , drop = FALSE],
       population_front = pop[ranks == 1, , drop = FALSE], history = history)
}
