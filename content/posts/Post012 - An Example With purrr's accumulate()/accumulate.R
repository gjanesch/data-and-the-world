library(MASS)
library(tidyverse)

data(Boston)

# cols to ignore: chas (indicator), rm (discrete, only a few values), rad (index)
# cols to use: crim, zn, indus, nox, age, dis, tax, ptratio, black, lstat
# col to predict: medv

cols_to_use <- c("crim", "zn", "indus", "nox", "age", "dis", "tax", "ptratio", "black", "lstat")
correlations <- cor(Boston[,c(cols_to_use, "medv")])[1:10,11]
strongest_to_least_corr <- names(sort(abs(correlations), decreasing = TRUE))

predictor_strings <- accumulate(strongest_to_least_corr, function(a,b){paste(a,b,sep=" + ")})
model_strings <- paste("medv ~", predictor_strings)

unadj_R2 <- numeric(10)
adj_R2 <- numeric(10)

for(i in 1:10){
    model <- lm(model_strings[i], data=Boston)
    m <- summary(model)
    unadj_R2[i] <- m$r.squared
    adj_R2[i] <- m$adj.r.squared
}

R2_data <- data.frame(NumPredictors=1:10, AdjR2=adj_R2, UnadjR2=unadj_R2)
ggplot(data=R2_data, aes(x=NumPredictors)) + geom_line(aes(y=UnadjR2, color="Unadjusted")) +
    geom_line(aes(y=AdjR2, color="Adjusted")) + xlab("# of predictors") + ylab("R^2") +
    theme(legend.title = element_blank()) + scale_x_continuous(breaks = seq(1, 10, by = 1))