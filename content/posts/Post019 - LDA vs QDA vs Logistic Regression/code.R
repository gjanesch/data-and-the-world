library(tidyverse)
library(caret)
# additional requirements: MASS, nnet

penguins <- read.csv("https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2020/2020-07-28/penguins.csv")

penguin_measurements <- penguins[sample(nrow(penguins)),] %>%
    select(species, bill_length_mm, bill_depth_mm, flipper_length_mm, body_mass_g) %>%
    drop_na()

penguin_measurements %>% pivot_longer(cols=bill_length_mm:body_mass_g) %>%
    ggplot() + geom_histogram(aes(x=value)) + facet_wrap(~species+name, scales="free")


Adelie <- penguin_measurements %>% filter(species=="Adelie") %>% select(-species)
Chinstrap <- penguin_measurements %>% filter(species=="Chinstrap") %>% select(-species)
Gentoo <- penguin_measurements %>% filter(species=="Gentoo") %>% select(-species)

library(MVN)
mvn(Adelie, mvnTest="energy")$multivariateNormality
mvn(Chinstrap, mvnTest="energy")$multivariateNormality
mvn(Gentoo, mvnTest="energy")$multivariateNormality


## penguins -- run where they're all good
lda_penguins <- train(data=penguin_measurements, species ~ ., method="lda",
                      trControl=trainControl(method="cv", number=10))
qda_penguins <- train(data=penguin_measurements, species ~ ., method="qda",
                      trControl=trainControl(method="cv", number=10))
logistic_penguins <- train(data=penguin_measurements, species ~ ., method="multinom",
                           trControl=trainControl(method="cv", number=10))

lda_penguins$results
qda_penguins$results
logistic_penguins$results


## wifi attempt - the one with different covariances
## data source: https://archive.ics.uci.edu/ml/datasets/Wireless+Indoor+Localization
wifi <- read.table("wifi_localization.txt")
wifi <- wifi[sample(nrow(wifi)),]
lda_wifi <- train(data=wifi, as.factor(V8) ~ ., method="lda",
                  trControl=trainControl(method="cv", number=10))
qda_wifi <- train(data=wifi, as.factor(V8) ~ ., method="qda",
                  trControl=trainControl(method="cv", number=10))
logistic_wifi <- train(data=wifi, as.factor(V8) ~ ., method="multinom",
                       trControl=trainControl(method="cv", number=10))

wifi_vars <- sapply(1:4, function(x){diag(cov(wifi[wifi$V8 == x, 1:7]))})

## adult dataset - mixed formats
adults <- read.csv("adult.data", header=FALSE, stringsAsFactors=TRUE)
names(adults) <- c("age", "workclass", "fnlwgt", "education", "education_num",
                   "marital_status", "occupation", "relationship", "race",
                   "sex", "capital_gain", "capital_loss", "hours_per_week",
                   "native_country", "salary")
adults <- adults %>%
    select(age, fnlwgt, education, sex, capital_gain, capital_loss, salary) %>%
    mutate(education=fct_collapse(education,
                                  NoHS=c(" 10th", " 11th", " 12th", " 1st-4th",
                                         " 5th-6th", " 7th-8th", " 9th", " Preschool"),
                                  Associates=c(" Assoc-acdm", " Assoc-voc"),
                                  Bachelors=" Bachelors", Doctorate=" Doctorate",
                                  Masters=" Masters", HSgrad=" HS-grad",
                                  ProfSchool=" Prof-school", SomeCollege=" Some-college"),
           capital_gain = 1*(capital_gain>0),
           capital_loss = 1*(capital_loss>0))

lda_adults <- train(data=adults, salary ~ ., method="lda",
                    trControl=trainControl(method="cv", number=10))
qda_adults <- train(data=adults, salary ~ ., method="qda",
                    trControl=trainControl(method="cv", number=10))
logistic_adults <- train(data=adults, salary ~ ., method="multinom",
                         trControl=trainControl(method="cv", number=10))
