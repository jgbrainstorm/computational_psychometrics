source("hawkes_functions.R")

# Data generation: 10,000 events from Hawkes process with gamma kernel
parms <- list("mu" = .1, "alpha" = .6, "shape" = 15, "scale" = .5)
set.seed(1001)
times <- hawkes_sim(10, parms)

# Fit Hawkes model with gamma and exponential kernels
gamma_hawkes <- optim(unlist(parms),
	 logl, times = times, method = "L-BFGS-B",
	 lower = rep(.00001, 4), upper = c(1, 1, 20, 20),
   hessian = T)

exp_hawkes <- optim(unlist(parms[-3]),
   logl, times = times, method = "L-BFGS-B",
   lower = rep(.00001, 3), upper = c(1, 1, 20),
   hessian = T)

# Likelihood ratio test of model fit
lr <- 2 * (exp_hawkes$value - gamma_hawkes$value)
cat("Likelihood ratio test of nested models.",
  "LR:", lr, "p-value: ", pchisq(lr, 1, lower.tail = F))

# 95% confidence intervals on overall intensity parameter
gamma_alpha <- gamma_hawkes$par["alpha"]
gamma_alpha_se <- se(gamma_hawkes)["alpha"]
cat("95% CI on overall intensity, gamma kernel.",
  "Lower:",  gamma_alpha - gamma_alpha_se * 1.96,
  "Upper:",  gamma_alpha + gamma_alpha_se * 1.96)

exp_alpha <- exp_hawkes$par["alpha"]
exp_alpha_se <-  se(exp_hawkes)["alpha"]
cat("95% CI on overall intensity, exponential kernel.",
  "Lower:",  exp_alpha - exp_alpha_se * 1.96,
  "Upper:",  exp_alpha + exp_alpha_se * 1.96)

