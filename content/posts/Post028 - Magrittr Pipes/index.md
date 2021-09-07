---
title: The Four Pipes of magrittr
date: 2021-09-07
linktitle: The Four Pipes of magrittr
categories: ["Code"]
tags: ["R"]
draft: false
description: A quick overview of the four different pipe operators found in the tidyverse's magrittr package.
mathjax: true
slug: magrittr-pipes
---

The `magrittr` package is a part of the extended tidyverse -- i.e., not one of the ones normally loaded.  It is the one that supplies the pipe operator (`%>%`), but it turns out that the package actually contains *four* pipe operators in total.  All are intended to streamline and improve the readability of code, though the three non-basic ones are a bit more situational, and I've rarely seen them used, so I thought I would go into them a bit.

The CRAN page for `magrittr` is [here](https://cloud.r-project.org/web/packages/magrittr/index.html); much of this post is based off of the package's vignettes and documentation.

<!--more-->

## The Basic Pipe (%>%)

The most common one, which is probably known by everyone using the tidyverse.  It is also largely intended for use with the tidyverse itself, or other functions which have a `data` argument as the first argument in their call.  It's pretty common for running several transformations or other operations at once, and remains considerably cleaner than trying to nest all of that together.

{{< highlight r >}}
> mtcars %>% filter(mpg > 30) %>% select(mpg:wt)
                mpg cyl disp  hp drat    wt
Fiat 128       32.4   4 78.7  66 4.08 2.200
Honda Civic    30.4   4 75.7  52 4.93 1.615
Toyota Corolla 33.9   4 71.1  65 4.22 1.835
Lotus Europa   30.4   4 95.1 113 3.77 1.513
{{< / highlight >}}

Expresssions and lambda functions can also be used in a chain:

{{< highlight r >}}
> ## return 10 rows if there are more than 10, 5 if there are 6-10 rows, and
> ## everything otherwise
> mtcars %>% filter(mpg > 20) %>% select(mpg:wt) %>%
> {
>     print(nrow(.))
>     if (nrow(.) > 10)
>         head(., 10)
>     else if(nrow(.) > 5)
>         head(., 5)
>     else
>         .
>}
[1] 14
                mpg cyl  disp  hp drat    wt
Mazda RX4      21.0   6 160.0 110 3.90 2.620
Mazda RX4 Wag  21.0   6 160.0 110 3.90 2.875
Datsun 710     22.8   4 108.0  93 3.85 2.320
Hornet 4 Drive 21.4   6 258.0 110 3.08 3.215
Merc 240D      24.4   4 146.7  62 3.69 3.190
Merc 230       22.8   4 140.8  95 3.92 3.150
Fiat 128       32.4   4  78.7  66 4.08 2.200
Honda Civic    30.4   4  75.7  52 4.93 1.615
Toyota Corolla 33.9   4  71.1  65 4.22 1.835
Toyota Corona  21.5   4 120.1  97 3.70 2.465
{{< / highlight >}}

You can also make quick univariate functions by having `.` as the first argument and just piping it to successive functions.  Here's one for taking numeric averages of all numeric columns in a dataframe:

{{< highlight r >}}
> numeric_averages <- . %>%
>     select_if(is.numeric) %>%
>     summarize(across(.fns=mean))
> numeric_averages(iris)
  Sepal.Length Sepal.Width Petal.Length Petal.Width
1     5.843333    3.057333        3.758    1.199333
{{< / highlight >}}

Plenty of other languages have analogues of this pipe -- `magrittr`'s documentation refers to the `|>` operator in F# (and I know Julia uses the same one) and mentions the Unix pipe `|` as well.

## The Tee Pipe (%T>%)

The documentation says:

> Pipe a value forward into a function- or call expression and return the original value instead of the result. This is useful when an expression is used for its side-effect, say plotting or printing.

Essentially, you can insert a `plot` or `print` or something else that doesn't return an actual result into the chain, and using `%T>%` will let the previous step's output bypass that step.  As an example, the following code produces both a plot and a dataframe:

{{< highlight r >}}
> iris %T>%
>     plot %>%
>     group_by(Species) %>%
>     summarize(MaxSepalLength=max(Sepal.Length), MinSepalLength = min(Sepal.Length))
# A tibble: 3 x 3
  Species    MaxSepalLength MinSepalLength
  <fct>               <dbl>          <dbl>
1 setosa                5.8            4.3
2 versicolor            7              4.9
3 virginica             7.9            4.9
{{< / highlight >}}

![Image description.]({{< resource url="irisplot.png" >}})

I could see this being useful if you want to run several transformations on a dataframe at once, but want to output something that details the state of the dataframe after each transformation.


## The Exposition Pipe (%$%)

The documentation:

> Expose the names in \[left-hand expression\] to the \[right-hand\] expression. This is useful when functions do not have a built-in data argument.

In other words, similar to how you can supply a dataframe's column names to many tidyverse functions or the `lm()` function in base R, this pipe allows you to do that with functions that don't normally allow that.  This seems like it would be the next most useful pipe in the package after the basic pipe, though I still haven't seen this one much.  A trivial example:

{{< highlight r >}}
> iris %$% plot(Sepal.Length, Sepal.Width)
{{< / highlight >}}

![Image description.]({{< resource url="irisplot2.png" >}})

An example in the documenation uses `cor()`, which also seems like a good use case.


## The Assignment Pipe (%<>%)

This one is fairly simple: it just reassigns the result of the pipe chain to the starting variable.

{{< highlight r >}}
> x <- c(1,2,3,4)
> x %<>% sum
> x
[1] 10
{{< / highlight >}}

Note that this only seems to work for sure it's the first operator in the sequence.  (There may be trickier cases, but I didn't really investigate them.)

{{< highlight r >}}
> x <- c(1,2,3,4)
> x %>% sqrt %<>% sum
[1] 6.146264
> x
[1] 1 2 3 4
{{< / highlight >}}

## Aliased Functions

A technical note in the documentation states the following:

> ...Another note is that special attention is advised when using non-magrittr operators in a pipe-chain (+, -, $, etc.), as operator precedence will impact how the chain is evaluated. In general it is advised to use the aliases provided by magrittr.

So if we wanted a simple calculation of the sum of squared errors for a linear regression:

{{< highlight r >}}
> sse <- . %>% resid %>% raise_to_power(2) %>% sum
> x <- seq(0,10, by=0.1)
> y <- x*5 + rnorm(length(x))
> model <- lm(y ~ x)
> sse(model)
[1] 99.2017
{{< / highlight >}}

The full list of aliases can be found in the `magrittr::extract` help topic.  Note that two of the aliases will mask or be masked by other main tidyverse functions -- `purrr::set_names` and `tidyr::extract` -- depending on the load order (I didn't check functions in libraries that are part of the tidyverse but aren't loaded by `library(tidyverse)`).

## Note on Libraries

Since `magrittr` isn't loaded with the core tidyverse, it might seem weird that the basic pipe operator can be used at all if its not loaded.  If you search the help for the operator using 

{{< highlight r >}}
??`%>%`
{{< / highlight >}}

it looks like basically *every* library in the tidyverse loads the operator.  However, `%>%` doesn't appear in the CRAN documentation of the other libraries (at least the ones I checked), and the help topic `dplyr::reexports` mentions that the pipe is just imported from `magrittr`, which is presumably what the other libraries are doing.
