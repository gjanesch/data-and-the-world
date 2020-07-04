## Description: demonstrate the use of Markdown text effects for labels in ggplot2, by changing the effect on text for plots of PCA components

## https://amitlevinson.com/post/learning-tfidf-with-political-theorists/

library(glue)
library(tidyverse)
library(ggtext)

data(iris)
pca <- prcomp(iris %>% select(matches("Sepal|Petal")))
transformation <- as.data.frame(pca$rotation)

transformation <- transformation %>% mutate(Var=row.names(.)) %>%
    pivot_longer(cols=c(PC1, PC2, PC3, PC4)) %>%
    mutate(VarStyle=ifelse(value>0, "**", "*"),
           MarkdownVar=glue("{VarStyle}{Var}{VarStyle}"))

ggplot(transformation, aes(x=MarkdownVar, y=value, fill=value>0)) +
    geom_col() + coord_flip() + facet_wrap(~name, scales="free_y") +
    theme(axis.text.y=element_markdown())

transformation <- transformation %>%
    mutate(VarColor=ifelse(value>0, "#00A000", "#A00000"),
           ColoredVar=glue("<span style='color:{VarColor}'>{Var}</span>"))

ggplot(transformation, aes(x=ColoredVar, y=value, fill=value>0)) +
    geom_col() + coord_flip() + facet_wrap(~name, scales="free_y") +
    theme(axis.text.y=element_markdown())
