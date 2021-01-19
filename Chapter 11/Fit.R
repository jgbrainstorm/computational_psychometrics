#---- Load the package ----
require(dynr)
#---- Read in the data ----
data.simulate <- read.csv("DataModel0P100T50Run1234.csv")
data <- dynr.data(data.simulate, id = "id", time = "time", observed = c("x", "y"))

#---- Starting Values ----
startVals <- c(rho1 = .2, rho2 = .2, a12 = 0, a21 = 0, K = 3, 
               var1 = 0.01, var2 = 0.01, var_e1 = .01, var_e2 = 0.01,
               muOne1 = 2, muTwo1 = 2, varOne1 = .05, varTwo1 = .05, cov_OneTwo1 = 0)

#---- Prepare the recipes ----
# Dynamic Model
formula =list(One ~ rho1 * One * (1 - (One + a12 * Two)/K),
              Two ~ rho2 * Two * (1 - (Two + a21 * One)/K))
dynm <- prep.formulaDynamics(formula = formula,
                             startval = c(rho1 = unname(startVals["rho1"]), rho2 = unname(startVals["rho2"]),
                                          a12 = unname(startVals["a12"]), a21 = unname(startVals["a21"]),
                                          K = unname(startVals["K"])),
                             isContinuousTime = TRUE)
# Measurement Model
meas <- prep.measurement(
  values.load = matrix(c(1, 0, 
                         0, 1), ncol = 2, byrow = TRUE),
  obs.names = c("x", "y"), state.names = c("One", "Two"))

# Initial Conditions
initial <- prep.initial(
  values.inistate = c(startVals["muOne1"], startVals["muTwo1"]),
  params.inistate = c("muOne1", "muTwo1"),
  values.inicov = matrix(c(startVals["varOne1"], startVals["cov_OneTwo1"], 
                           startVals["cov_OneTwo1"], startVals["varTwo1"]), 2, 2, byrow = TRUE), 
  params.inicov = matrix(c("varOne1", "cov_OneTwo1", 
                           "cov_OneTwo1", "varTwo1"), 2, 2, byrow = TRUE))
# Noise Covariance Matrix
mdcov <- prep.noise(
  values.latent=diag(c(startVals["var1"], startVals["var2"])),
  params.latent=diag(c("var1", "var2")),
  values.observed=diag(c(startVals["var_e1"], startVals["var_e2"])),
  params.observed=diag(c("var_e1","var_e2")))
#---- Cooking materials ----
# Put all the recipes together in a Model Specification
model <- dynr.model(dynamics = dynm, measurement = meas,
                    noise = mdcov, initial = initial, 
                    data = data, outfile="mutualism.c")
# Estimate free parameters
res <- dynr.cook(dynrModel = model)
#---- Examine results ----
summary(res, digits = 2)

dynr.ggplot(res, model, style = 2, title = "Results of fitting the model to simulated data", 
            numSubjDemo = 3, text = element_text(size = 16))

