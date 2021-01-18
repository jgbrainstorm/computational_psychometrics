# Functions to simulate and estimate univariate hawkes process with gamma reponse kernel

# 1. cif
cif <- function(times, parms) {
  if(is.null(parms$shape)) {parms$shape = 1}
  lambda <- times*0
  lambda[1] <- parms$mu

  for (i in 2:length(times)) {
    z <- times[i] - times[1:(i-1)]

    lambda[i] <- parms$mu + parms$alpha * sum(
      dgamma(z, parms$shape, 1/parms$scale))
  }
	return(lambda)
}

# 2. compensator
compensator <- function(t, times = NULL, parms) {
  if(is.null(parms$shape)) {parms$shape = 1}
  out <- parms$mu * t
  if(!is.null(times)) {
    z <- t - times[which(times < t)]
    out <- out + parms$alpha * sum(
      pgamma(z, parms$shape, 1/parms$scale))
  }
  return(out)
}

# 3. loglikelihood
logl <- function(parms, times, neglog = T) {
	parms <- as.list(parms)
  t <- times[length(times)]
  out <- sum(log(cif(times, parms))) - compensator(t, times, parms)
  if (neglog) { return(-out) } else { return(out) }
}

# 4. standard errors (observed Fisher info, computed via finite difference)
se <- function(optim.object) {
  sqrt(diag(solve(optim.object$hessian)))
}

# 5. data simulation
hawkes_sim <- function(n_events, parms) {
  s <- cumsum(rexp(n_events))
  t <- s * 0
  end_time <- n_events/parms$mu * 2

  f <- function(t, s, times, parms) {
    (s - compensator(t, times, parms))^2
  }

  t[1] <- optimize(
    f,
    interval = c(0, end_time),
    s = s[1],
    times = NULL,
    parms = parms)$minimum

  for (i in 2:n_events) {
    t[i] <- optimize(
      f,
      interval = c(t[i - 1], end_time),
      s = s[i],
      times = t[1:(i - 1)],
      parms = parms)$minimum
	}
	return(t)
}

# some examples
#gamma_parms <- list("mu" = .2, "alpha" = .6, "shape" = 3, "scale" = 3)
#exp_parms <- gamma_parms[-3]

##x <- seq(1, 20, by = .5)
#plot(x, dgamma(x, gamma_parms$shape, 1/gamma_parms$scale), type = "l")

#n_events <- 5000
#times <- hawkes_sim(n_events, gamma_parms)

# rough check
#n_mu <- parms$mu * times[n_events] # s/b < n_events
#a <- (n_events - n_mu) / n_events # s/b ~ alpha
