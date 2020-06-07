library(ggplot2)
library(RColorBrewer)

## Gregory Janesch, last edited 2020-05-10
## Description: Code for blog post 005, "Looking Normal(ly Distributed)"

N <- 4000
repeats <- 15

################################################################################
#### FIRST PLOT - t-dist, as an example
################################################################################
t_data <- rt(N, df=100, ncp=5)
shapiro.test(t_data)

ggplot(data=NULL, aes(x=t_data)) + geom_histogram(aes(y=..density..), binwidth=0.2) + geom_density() + xlim(c(0,10))


################################################################################
#### DISTRIBUTION ONE - BETA
################################################################################

x = seq(0,1,by=0.0001)
ggplot(data=NULL, aes(x=x)) + geom_line(aes(y=dbeta(x,8,2), color="Beta(8,2)")) +
    geom_line(aes(y=dbeta(x,2,8), color="Beta(2,8)")) +
    geom_line(aes(y=dbeta(x,5,5), color="Beta(5,5)")) +
    geom_line(aes(y=dbeta(x,10,10), color="Beta(10,10)")) +
    labs(title="Beta distributions") + theme(legend.title = element_blank()) + ylab("Density")

beta_normality_check <- function(alpha, beta, N=2000, times=1){
    random_samples <- matrix(rbeta(N*times, alpha, beta), nrow = N, ncol = times)
    p_values <- apply(random_samples, MARGIN = 2, function(x){shapiro.test(x)$p.value})
    return(median(p_values))
}

beta_parameters <- expand.grid(Alpha=seq(1,100,by=1), Beta=seq(1,100,by=1))
beta_parameters$P <- apply(beta_parameters, MARGIN=1,
                           function(r){beta_normality_check(r[1], r[2], N=N, times=repeats)})
ggplot(data=beta_parameters, aes(x=Alpha, y=Beta)) + geom_tile(aes(fill=P)) +
    scale_fill_distiller() + xlab("a") + ylab("b")

################################################################################
#### DISTRIBUTION TWO - GAMMA
################################################################################

x = seq(0,5,by=0.001)
ggplot(data=NULL, aes(x=x)) + geom_line(aes(y=dgamma(x,3,3), color="Gamma(3,3)")) +
    geom_line(aes(y=dgamma(x,5,3), color="Gamma(5,3)")) +
    geom_line(aes(y=dgamma(x,3,5), color="Gamma(3,5)")) + 
    labs(title="Gamma distributions") + theme(legend.title = element_blank()) + ylab("Density")

gamma_normality_check <- function(shape, rate, N=2000, times=5){
    random_samples <- matrix(rgamma(N*times, shape=shape, rate=rate), nrow=N, ncol=times)
    p_values <- apply(random_samples, MARGIN = 2, function(x){shapiro.test(x)$p.value})
    return(median(p_values))
}

g_parameters <- expand.grid(Shape=seq(10,1000,by=10), Rate=seq(10,1000,by=10))
g_parameters$P <- apply(g_parameters, MARGIN=1,
                         function(r){gamma_normality_check(r[1], r[2], N=N, times=15)})
ggplot(data=g_parameters, aes(x=Shape, y=Rate)) + geom_tile(aes(fill=P)) +
    scale_fill_distiller()


################################################################################
#### DISTRIBUTION THREE - BINOMIAL
################################################################################
x = 0:50
ggplot(data=NULL, aes(x=x)) + geom_bar(aes(y=dbinom(x,50,0.2), color="Binom(50,0.2)"), alpha=0.2, stat="identity") +
    geom_bar(aes(y=dbinom(x,50,0.5), color="Binom(50,0.5)"), alpha=0.2, stat="identity") +
    geom_bar(aes(y=dbinom(x,20,0.2), color="Binom(20,0.2)"), alpha=0.2, stat="identity") + 
    labs(title="Binomial distributions") + theme(legend.title = element_blank()) + ylab("Density")

binomial_normality_check <- function(count, prob, N=2000, times=5){
    random_samples <- matrix(rbinom(N*times, size=count, prob=prob), nrow=N, ncol=times)
    p_values <- apply(random_samples, MARGIN = 2, function(x){shapiro.test(x)$p.value})
    return(median(p_values))
}

bin_parameters <- expand.grid(Count=seq(20,3000,5), Prob=seq(0.01,0.99,by=0.01))
bin_parameters$P <- apply(bin_parameters, MARGIN=1,
                          FUN = function(r){binomial_normality_check(r[1], r[2], times=15)})
ggplot(data=bin_parameters, aes(x=Count, y=Prob)) + geom_tile(aes(fill=P)) +
    scale_fill_distiller()


################################################################################
#### DISTRIBUTION FOUR - POISSON
################################################################################
x = 0:50
ggplot(data=NULL, aes(x=x)) +
    geom_bar(aes(y=dpois(x,8), color="Poisson(8)"), alpha=0.2, stat="identity") + 
    geom_bar(aes(y=dpois(x,15), color="Poisson(15)"), alpha=0.2, stat="identity") + 
    geom_bar(aes(y=dpois(x,25), color="Poisson(25)"), alpha=0.2, stat="identity") + 
    labs(title="Poisson distributions") + theme(legend.title = element_blank()) + ylab("Density")

poisson_normality_check <- function(rate, N=2000, times=5){
    random_samples <- matrix(rpois(N*times, lambda=rate), nrow=N, ncol=times)
    p_values <- apply(random_samples, MARGIN = 2, function(x){shapiro.test(x)$p.value})
    return(median(p_values))
}

p_parameters <- expand.grid(Rate=seq(0.1,1000,by=0.1))
p_parameters$P <- apply(p_parameters, MARGIN=1,
                        FUN = function(r){poisson_normality_check(r[1], N=N, times=15)})
ggplot(data=p_parameters, aes(x=Rate, y=P)) + geom_point(alpha=0.1) + geom_smooth(color="purple")
