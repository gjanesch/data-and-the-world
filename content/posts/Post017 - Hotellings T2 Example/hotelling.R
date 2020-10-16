library(tidyverse)

data(iris)

ggplot(data=iris) + geom_boxplot()

iris_long <- iris %>% pivot_longer(Sepal.Length:Sepal.Width)
ggplot(data=iris_long) + geom_boxplot(aes(x=Species, y=value)) + facet_wrap(~name)
iris_wide <- iris %>% select(Species, Sepal.Length) %>% mutate(fake_index = rep(1:50, 3)) %>%
    pivot_wider(names_from=Species, values_from=Sepal.Length) %>% select(-fake_index)

library(glue)


TwoSampleT2Test <- function(X, Y){
    nx <- nrow(X)
    ny <- nrow(Y)
    delta <- colMeans(X) - colMeans(Y)
    p <- ncol(X)
    Sx <- cov(X)
    Sy <- cov(Y)
    S_pooled <- ((nx-1)*Sx + (ny-1)*Sy)/(nx+ny-2)
    
    t_squared <- (nx*ny)/(nx+ny) * t(delta) %*% solve(S_pooled) %*% (delta)
    statistic <- t_squared * (nx+ny-p-1)/(p*(nx+ny-2))
    
    p_value <- pf(statistic, p, nx+ny-p-1, lower.tail = FALSE)
    print(glue("Test statistic: {statistic}
                Degrees of freedom: {p} and {nx+ny-p-1}
                p-value: {p_value}"))
    
    return(list(TestStatistic=statistic, p_value=p_value))
}

data(iris)
versicolor <- iris[iris$Species == "versicolor", 1:2]
virginica <- iris[iris$Species == "virginica", 1:2]
TwoSampleT2Test(versicolor, virginica)
## only returning invisible because it's consistent with other tests.