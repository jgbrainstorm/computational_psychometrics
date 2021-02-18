library(extraDistr)

############## BASE FUNCTIONS for SM-MH
rPrior <- function(n, mu, sigma, prior)
{
  if (prior == "normal") out = rnorm(n,mu,sigma)
  if (prior == "exp") out = rexp(n,rate=sigma)
  if (prior == "Laplace") out = rlaplace(n, mu, sigma)
  return(out)
}

Prior_MH <- function(z, j, y, current, mu, sigma, prior) 
{
  n = length(z)-1
  if (prior=="normal")
  {
    c_4=dnorm(z[j], mean=mu,sd=sigma,log = TRUE)
    c_5=dnorm(current,mean=mu,sd=sigma,log = TRUE)
    c_6=pnorm(current,mean=mu,sd=sigma,lower.tail=y[n],log.p = TRUE)
    c_7=pnorm(z[j],mean=mu,sd=sigma,lower.tail=y[n],log.p = TRUE)
  }
  if (prior=="exp")
  {
    c_4=dexp(z[j], rate=sigma,log = TRUE)
    c_5=dexp(current,rate=sigma,log = TRUE)
    c_6=pexp(current,rate=sigma,lower.tail=y[n],log.p = TRUE)
    c_7=pexp(z[j],rate=sigma,lower.tail=y[n],log.p = TRUE)
  }
  if (prior=="Laplace")
  {
    c_4=dlaplace(z[j], mu=0, sigma, log=TRUE)
    c_5=dlaplace(current, mu=0, sigma, log = TRUE)
    c_6=plaplace(current, mu=0, sigma, lower.tail=y[n],log.p = TRUE)
    c_7=plaplace(z[j], mu=0, sigma, lower.tail=y[n],log.p = TRUE)
  }
  return(c_4-c_5+c_6-c_7)
}

MH_R = function(x, a, b, current, mu, sigma, prior=c("normal", "exp", "Laplace"), accept_all=FALSE)
{
  prior = match.arg(prior)
  if (any(a==0)){
    indx = which(a==0)
    x = x[-indx]
    a = a[-indx]
    b = b[-indx]
  }
  if (any(a<0)){
    indx = which(a<0)
    x[indx] = 1 - x[indx]
    a[indx] = -a[indx]
    b[indx] = -b[indx]
  }
  n=length(x)
  z=rlogis(n,location=-b/a,scale=1/a)
  z = c(z, rPrior(1,mu,sigma, prior))
  j=order(z)[sum(x)+1]
  candidate = z[j]
  if (accept_all == FALSE)
  {
    y=sapply(z[-j],function(x) 1*(x<=z[j]))
    if (j<(n+1)){
      logA = (x[j]-1)*a[j]*(z[j]-current)
      logA = logA + log(1+exp(a[j]*z[j]+b[j]))
      logA = logA - log(1+exp(a[j]*current+b[j]))
      logA = logA + Prior_MH(z, j, y, current, mu, sigma, prior)
      logalpha = logA + sum(a[-j]*(x[-j]-y[-n]))*(z[j]-current)
    }else{
      logalpha = sum(a*(x-y))*(z[j]-current)
    }
    candidate = ifelse(log(runif(1,0,1))<=logalpha, z[j], current)
  }
  return(candidate)
}

########## IRT data
## Rasch
Simdat.item = function(nP, alpha, delta, theta)
{
  return(1*(rlogis(nP,0,1)<=(alpha*theta - delta)))
}


## MIRT model with factor loadings alpha
rMIRT_R = function(theta, alpha, delta)
{
  nP = nrow(theta)
  nI = nrow(alpha)
  x=matrix(NA,nP,nI)
  for (i in 1:nI)
  {
    x[,i] = 1*(rlogis(nP,0,1)<=(theta%*%alpha[i,]+delta[i]))
  }
  return(x)
}

################# Gibbs sampler Rasch Model
nP=nrow(y); nI=ncol(y)
# priors
mu.th = 0; sigma.th = 2
mu.b = 0; sigma.b = 0.5
# start_values
delta=runif(nI,-1,1)
theta=rnorm(nP,mu.th,sigma.th)

for (iter in 1:50)
{
  init = ifelse(iter<5, 1,0)
  theta=sapply(1:nP,function(p) MH_R(y[p,], rep(1,nI), delta, theta[p], mu.th, sigma.th, 'normal',init))
  delta=sapply(1:nI,function(i) MH_R(y[,i], rep(1,nP), theta, delta[i], mu.b, sigma.b,'normal',init))
  
  # Identify
  delta = delta-mean(delta)
  
  # Update Prior
  sigma.th = sqrt(1/rgamma(1,shape=(nP-1)/2,rate=((nP-1)/2)*var(theta)))
  mu.th = rnorm(1,mean(theta),sigma.th/sqrt(nP))
}



############## Gibbs sampler 2PL
nP=nrow(y); nI=ncol(y) 
# priors
mu.th = 0; sigma.th = 2
mu.b = 0; sigma.b = 0.5
# start_values
delta=runif(nI,-1,1)
theta=rnorm(nP,mu.th,sigma.th)
alpha=rep(1,nI)

for (iter in 1:50)
{
  init = ifelse(iter<5,1,0)
  theta = sapply(1:nP,function(p) MH_R(y[p,], alpha, delta, theta[p], mu.th, sigma.th, 'normal',init))
  delta = sapply(1:nI,function(i) MH_R(y[,i], rep(1,nP), alpha[i]*theta, delta[i], mu.b, sigma.b,'normal',init))
  alpha = sapply(1:nI,function(i) MH_R(y[,i], theta, rep(delta,nP), alpha[i], 1, 0.5,'normal',init))
  
  # Identify
  alpha=alpha/alpha[1]
  shift=sum(delta)/sum(alpha)
  delta = delta-shift*alpha
  
  # Update ability prior
  sigma.th = sqrt(1/rgamma(1,shape=(nP-1)/2,rate=((nP-1)/2)*var(theta)))
  mu.th = rnorm(1,mean(theta),sigma.th/sqrt(nP))
}


### Gibbs sampler BI-FACTOR model
BIfactor = function(x, C, nIter=100)
{
  nD = ncol(C)
  m=nrow(x)
  n=ncol(x)
  mu.pv=rep(0,nD)
  delta=runif(n,-1,1)
  lambda=rep(1,nD)
  pv=matrix(0,m,nD)
  for (j in 1:nD) pv[,j]=rnorm(m,mu.pv[j],1)
  
  ### vectors
  a_n=vector("numeric", n)
  b_n=vector("numeric", n)
  a_m=vector("numeric", m)
  b_m=vector("numeric", m)
  a_nm=vector("numeric", n*m)
  b_nm=vector("numeric", n*m)
  
  store_lambda= matrix(0,nD,nIter)
  store_delta = matrix(0,m,nIter)
  
  for (iter in 1:nIter)
  {
    init=(iter<2)
    
    # Update \delta_i
    for (i in 1:n)
    {
      for (p in 1:m)
      {
        b_m[p]=0; a_m[p]=1
        for (j in 1:nD)
        {
          b_m[p]=b_m[p]+C[i,j]*lambda[j]*pv[p,j]	
        }
      }
      delta[i]=MH_R(x[,i], a_m, b_m, delta[i], 0, 1, 'normal', init)
    }
    # Update \theta_{pj}
    for (p in 1:m)
    {
      for (j in 1:nD)
      {
        for (i in 1:n)
        {
          a_n[i]=lambda[j]*C[i,j]
          b_n[i]=delta[i]
          for (h in 1:nD)
          {
            if (h!=j) b_n[i]=b_n[i]+lambda[h]*C[i,h]*pv[p,h]
          }
        }
        pv[p,j]=MH_R(x[p,],a_n, b_n, pv[p,j], mu.pv[j], 1,'normal', init) 
      }
    }
    
    for (j in 1:nD) 
    {
      ip=0
      for (i in 1:n)
      {    		
        for (p in 1:m)
        {
          ip=ip+1
          b_nm[ip]=delta[i]
          a_nm[ip]=C[i,j]*pv[p,j]
          for (h in 1:nD)
          {
            if (h!=j) b_nm[ip]=b_nm[ip]+lambda[h]*C[i,h]*pv[p,h]	
          }
        }    
      }
      lambda[j]=MH_R(as.vector(x),a_nm,b_nm,lambda[j],1,2,'exp', init)
    }
    
    delta = delta - mean(delta)
    
    ## update prior plausible values
    for (j in 1:nD){
      pv[,j] = pv[,j]/sd(pv[,j])
      mu.pv[j] = rnorm(1,mean(pv[,j]),1/sqrt(m))
    }
    
    store_lambda[,iter] = lambda
    store_delta[,iter] = delta
  }
  out=list(delta=store_delta, lambda=store_lambda)
}


##### Gibbs sampler Logistic regression
GibbsLogistic_R = function(dat, out=1, covariates, lasso=FALSE, lambda=NULL, nIter = 1000, center=TRUE)
{
  dat = cbind(dat,1)
  covariates = c(covariates,ncol(dat))
  nb = length(covariates)
  est_lambda = is.null(lambda)
  tr_beta = matrix(0,nb,nIter)
  if (est_lambda){
    tr_lambda = rep(0,nIter)
  }else
  {
    tr_lambda = rep(lambda,nIter)
  }
  est_lambda = is.null(lambda)
  
  M=10
  
    # centre covariates
  if (center)
  {
    mean_x = colMeans(dat)
    for (i in covariates[1:(nb-1)]) dat[,i] = dat[,i]-mean_x[i]
  }
  
  if (lasso&est_lambda) lambda = rgamma(1,3,1)
  
  beta=runif(nb,-1,1)
  for (iter in 1:nIter)
  {
    for (i in 1:(nb-1))
    {
      b = as.matrix(dat[,covariates[-i]])%*%beta[-i]
      beta[i] = ifelse(lasso,
                       MH(dat[,out], dat[,covariates[i]], b, beta[i], 0, 1/lambda, 
                          prior = "Laplace", 
                          accept_all = ifelse(iter<M,1,0)),
                       MH(dat[,out], dat[,covariates[i]], b, beta[i], 0, 2,
                          prior = 'normal', 
                          accept_all = ifelse(iter<M,1,0)))
    }
    b = as.matrix(dat[,covariates[-nb]])%*%beta[-nb]
    beta[nb] = MH(dat[,out], dat[,covariates[nb]], b, beta[nb], 0, 4,
                  prior = 'normal', 
                  accept_all = ifelse(iter<M,1,0))
    
    if (lasso&est_lambda)
    {
      lambda = rgamma(1,shape=3+nb-1,rate=1+sum(abs(beta)[1:(nb-1)]))
      tr_lambda[iter] = lambda
    }
    
    tr_beta[,iter] = beta
  }
  
  if (center){
    for (i in 1:(nb-1)) tr_beta[nb,] = tr_beta[nb,] - tr_beta[i,]*mean_x[covariates[i]]
  }
  return(list(alpha=tr_beta[nb,], beta=tr_beta[1:(nb-1),], lambda=tr_lambda))
}
