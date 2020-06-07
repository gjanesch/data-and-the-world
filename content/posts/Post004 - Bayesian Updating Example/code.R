library(tidyverse)
library(gganimate)
library(transformr)

# results of uses of Thunder (1 is a hit, 0 is a miss)
results <- c(1,0,1,1,1,0,1,1,0,1, 1,0,1,0,0,1,1,1,1,1,
             0,1,1,1,1,1,1,0,0,1, 0,0,1,0,1,0,1,1,0,1,
             0,0,1,1,1,0,1,1,1,1, 0,0,1,1,1,1,1,1,1,1,
             0,1,1,0,1,1,1,1,0,1, 1,1,1,1,0,1,1,1,0,1,
             0,1,1,1,1,1,1,1,1,1, 0,1,1,0,1,0,0,0,0,1,
             1,1,1,1,1,1,1,0,1,1, 1,1,1,1,1,0,1,1,1,0,
             0,0,1,1,1,1,1,1,0,1, 0,1,0,1,1,1,1,1,1,0,
             1,1,0,1,1,1,0,1,1,0, 0,1,0,1,1,1,1,0,1,1,
             1,0,0,0,1,1,0,1,1,1, 1,0,0,1,0,1,1,0,1,0,
             0,1,1,0,1,0,1,1,1,0, 1,1,1,1,1,0,0,1,1,1,
             0,1,1,0,1,1,1,1)

N <- length(results)
L <- 200  #number of points for plotting density

x <- seq(0,1,length.out = L)

weak_prior <- list(alpha=5, beta=5)
strong_prior <- list(alpha=75, beta=75)

# need to include data for each value of x at each trial in order to get gganimate to
# animate it
z <- data.frame(Trial = rep(1:N, each=L),
                X = rep(x, times=N),
                weak_alpha = rep(weak_prior$alpha + cumsum(results==1), each=L),
                weak_beta = rep(weak_prior$beta + cumsum(results==0), each=L),
                strong_alpha = rep(strong_prior$alpha + cumsum(results==1), each=L),
                strong_beta = rep(strong_prior$beta + cumsum(results==0),each=L))

z <- z %>% mutate(Weak = dbeta(X, weak_alpha, weak_beta),
                  Strong = dbeta(X, strong_alpha, strong_beta))

                  
# plots - priors, animated update process, and final
g0 <- ggplot(data=NULL, aes(x=x)) + geom_line(aes(y=dbeta(x, weak_prior$alpha, weak_prior$beta), color="Weak")) +
      geom_line(aes(y=dbeta(x, strong_prior$alpha, strong_prior$beta), color="Strong")) + ylab("Density") +
      scale_color_manual(values=c("Weak"="blue", "Strong"="green")) + ylim(c(0,16)) + labs(color="Prior")

g <- ggplot(data=z, aes(x=X)) + geom_line(aes(y=Weak, color="Weak")) + geom_line(aes(y=Strong, color="Strong")) + 
     ylab("Density") + scale_color_manual(values=c("Weak"="blue", "Strong"="green")) + labs(color="Prior") +
     ylim(c(0,16)) + transition_states(Trial) + ggtitle("Priors after {closest_state} updates")

last_row <- tail(z,1)
gfin <- ggplot(data=NULL, aes(x=x)) + geom_line(aes(y=dbeta(x, last_row$weak_alpha, last_row$weak_beta), color="Weak")) +
        geom_line(aes(y=dbeta(x, last_row$strong_alpha, last_row$strong_beta), color="Strong")) + ylab("Density") +
        scale_color_manual(values=c("Weak"="blue", "Strong"="green")) + ylim(c(0,16)) + labs(color="Prior")

anim_save("updating_priors.gif", g, nframes=2*N)

# 99% credible intervals
qbeta(c(0.005, 0.995), 150, 68)
qbeta(c(0.005, 0.995), 220, 138)
