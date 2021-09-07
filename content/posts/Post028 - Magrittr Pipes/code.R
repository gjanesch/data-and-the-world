library(tidyverse)
library(magrittr)

## The Basic Pipe (%>%)

mtcars %>% filter(mpg > 30) %>% select(mpg:wt)

mtcars %>% filter(mpg > 20) %>% select(mpg:wt) %>%
{
    print(nrow(.))
    if(nrow(.) > 10)
        head(., 10)
    else if(nrow(.) > 5)
        head(., 5)
    else
        .
}

numeric_averages <- . %>%
    select_if(is.numeric) %>%
    summarize(across(.fns=mean))

## The Tee Pipe (%T>%)

iris %T>%
    plot %>%
    group_by(Species) %>%
    summarize(MaxSepalLength=max(Sepal.Length), MinSepalLength = min(Sepal.Length))

## The Exposition Pipe (%$%)

iris %$% plot(Sepal.Length, Sepal.Width)

## Assignment Pipe
x <- c(1,2,3,4)
x %<>% sum
x

x <- c(1,2,3,4)
x %>% sqrt %<>% sum
x

## Aliased Functions
sse <- . %>% resid %>% raise_to_power(2) %>% sum
x <- seq(0,10, by=0.1)
y <- x*5 + rnorm(length(x))
model <- lm(y ~ x)
sse(model)
