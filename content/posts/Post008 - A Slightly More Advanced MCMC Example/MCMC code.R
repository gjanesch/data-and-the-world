## Greg Janesch, last edited 2020-06-03
## Description: Code for "A Slightly Advanced MCMC Example" blog post

library(tidyverse)
library(patchwork)


# Calculates the likelihoods of the given x and y values
likelihood <- function(X, y, betas){
    e <- exp(X %*% betas)
    px <- e/(1+e)
    return(px^y * ((1-px)^(1-y)))
}

# Calculates the prior probability density
prior <- function(betas){
    return(prod(sapply(betas, dnorm, mean=0, sd=10)))
}

# Calculates log of the posterior density
log_posterior <- function(X, y, betas){
    log_prior <- log(prior(betas))
    log_likelihoods <- log(likelihood(X, y, betas))
    return(log_prior + sum(log_likelihoods))
}

MCMC <- function(X, y, n, beta_start=c(0,0,0,0), jump_dist_sd=0.1){
    B <- ncol(X)   # number of betas (coefficients)
    beta <- matrix(nrow=n, ncol=B)
    beta[1,] <- beta_start
    
    for(i in 2:n){
        current_betas <- beta[i-1,]
        new_betas <- current_betas + rnorm(B, mean=0, sd=jump_dist_sd)
        
        for(j in 1:B){
            test_betas <- current_betas
            test_betas[j] <- new_betas[j]
            
            rr <- log_posterior(X, y, test_betas) - log_posterior(X, y, current_betas)
            if(log(runif(1)) < rr){
                beta[i,j] <- new_betas[j]
            } else {
                beta[i,j] <- current_betas[j]
            }
        }
    }
    return(beta)
}

###############################################################################

start.time <- Sys.time()

set.seed(1000)
burn_in_length <- 10000
N <- 50000   # total number of points
data(Default, package="ISLR")

Def2 <- Default %>%
    mutate(default = as.integer(as.character(default) == "Yes")) %>%
    mutate(student = as.integer(as.character(student) == "Yes"))

Def2 <- Def2 %>% mutate(balance=balance/1000) %>% mutate(income=income/1000)

y <- Def2$default
X <- cbind(1, as.matrix(Def2[,2:4]))   # pad with a column of ones for intercept

beta <- MCMC(X, y, n=N, jump_dist_sd=0.05)  # would throw an error before first Def2
beta2 <- beta[(burn_in_length+1):N,]

MCMC_results <- apply(beta2, MARGIN=2, function(x){c(mean(x), quantile(x, c(0.025, 0.5, 0.975)))})
colnames(MCMC_results) <- c("Intercept", "student", "balance", "income")

glm_model <- glm(default ~ student + balance + income, data=Def2, family=binomial(link="logit"))

sc <- summary(glm_model)$coefficients
glm_95 <- rbind(z[,1] - 1.96*z[,2], z[,1] + 1.96*z[,2])

g <- ggplot(data=NULL, aes(x=1:N)) + xlab("") + geom_vline(xintercept=burn_in_length, color="red")
p_int <- g + geom_line(aes(y=beta[,1])) + ylab("Intercept")
p_stu <- g + geom_line(aes(y=beta[,2])) + ylab("Student")
p_bal <- g + geom_line(aes(y=beta[,3])) + ylab("Balance")
p_inc <- g + geom_line(aes(y=beta[,4])) + ylab("Income")
(p_int + p_stu) / (p_bal + p_inc)

g2 <- ggplot(data=NULL) + ylab("") + theme_minimal()
p2_int <- g2 + geom_histogram(aes(x=beta2[,1])) + geom_vline(xintercept=c(MCMC_results[2,1], MCMC_results[4,1])) + geom_vline(xintercept=glm_95[,1], linetype=2, color = "blue") + xlab("Intercept")
p2_stu <- g2 + geom_histogram(aes(x=beta2[,2])) + geom_vline(xintercept=c(MCMC_results[2,2], MCMC_results[4,2])) + geom_vline(xintercept=glm_95[,2], linetype=2, color = "blue") + xlab("Intercept")
p2_bal <- g2 + geom_histogram(aes(x=beta2[,3])) + geom_vline(xintercept=c(MCMC_results[2,3], MCMC_results[4,3])) + geom_vline(xintercept=glm_95[,3], linetype=2, color = "blue") + xlab("Intercept")
p2_inc <- g2 + geom_histogram(aes(x=beta2[,4])) + geom_vline(xintercept=c(MCMC_results[2,4], MCMC_results[4,4])) + geom_vline(xintercept=glm_95[,4], linetype=2, color = "blue") + xlab("Intercept")
(p2_int + p2_stu) / (p2_bal + p2_inc)
