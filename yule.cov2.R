yule.cov2 <- 
function (phy, formula, data = NULL) 
{
  if (is.null(data)) 
    data <- parent.frame()
  n <- length(phy$tip.label)
  nb.node <- phy$Nnode
  if (!is.null(phy$node.label)) 
    phy$node.label <- NULL
  bt <- sort(branching.times(phy))
  bt <- rev(bt)
  ni <- cumsum(rev(table(bt))) + 1
  X <- model.matrix(formula, data)
  Xi <- X[phy$edge[, 1], , drop = FALSE]
  Xj <- X[phy$edge[, 2], , drop = FALSE]
  dev <- function(b) {
    2 * sum(((1/(1 + exp(-(Xi %*% b)))) + (1/(1 + exp(-(Xj %*% 
                                                          b))))) * phy$edge.length/2) - 2 * (sum(log(ni[-length(ni)])) + 
                                                                                               sum(log((1/(1 + exp(-(X[-(1:(n + 1)), , drop = FALSE] %*% 
                                                                                                                       b)))))))
  }
  out <- nlm(function(p) dev(p), p = c(rep(0, ncol(X) - 1), 
                                       -1), hessian = TRUE)
  Dev <- out$minimum
  para <- matrix(NA, ncol(X), 2)
  para[, 1] <- out$estimate
  if (any(out$gradient == 0)) 
    warning("The likelihood gradient seems flat in at least one dimension (null gradient):\ncannot compute the standard-errors of the parameters.\n")
  else para[, 2] <- sqrt(diag(solve(out$hessian)))
  rownames(para) <- colnames(X)
  colnames(para) <- c("Estimate", "StdErr")
  X <- model.matrix(~1, data = data.frame(X))
  Xi <- X[phy$edge[, 1], , drop = FALSE]
  Xj <- X[phy$edge[, 2], , drop = FALSE]
  Dev.null <- nlm(function(p) dev(p), p = -1)$minimum
  cat("\n---- Yule Model with Covariates ----\n\n")
  cat("    Phylogenetic tree:", deparse(substitute(phy)), "\n")
  cat("       Number of tips:", n, "\n")
  cat("      Number of nodes:", nb.node, "\n")
  cat("             Deviance:", Dev, "\n")
  cat("       Log-likelihood:", -Dev/2, "\n\n")
  cat("  Parameter estimates:\n")
  print(para)
  cat("\n")
  cat("Null Deviance:", Dev.null, "\n")
  cat("  Test of the fitted model: ")
  chi <- Dev.null - Dev
  df <- nrow(para) - 1
  cat("chi^2 =", round(chi, 3), "  df =", df, "  P =", round(1 - 
                                                               pchisq(chi, df), 3), "\n")
  P <- round(1 - pchisq(chi, df), 3)
}