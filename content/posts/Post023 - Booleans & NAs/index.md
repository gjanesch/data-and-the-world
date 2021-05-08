---
title: Booleans & NAs
date: 2021-05-07
linktitle: Booleans & NAs
categories: ["Code"]
tags: ["Julia","Python","R"]
draft: false
description: A quick look at interactions with NAs and boolean operators.
mathjax: true
slug: booleans-and-NAs
---

Missing values are inevitable in data science, and handling them is a constant issue.  In the case of Boolean logic, it can behave fairly differently depending on the order of arguments and exactly how it is set up, unlike a lot of other data types.  Whether this is useful or not depends on the scenario, but the behavior is something to keep in mind.

<!--more-->

Most programming languages that I'm aware of have the capacity for [short-circuit evaluation](https://en.wikipedia.org/wiki/Short-circuit_evaluation), which can allow for certain Boolean expressions to be evaluated given only one argument.  Specifically, an OR will always be true if the first value is true, and an AND will always be false if the first argument is false.  Other operators like XOR can't be short-circuited due to actually needing to know both values to determine the output.

If the second argument is a missing value, you may expect the same as before, and you'd be right.  Since you can't short circuit an AND when the first argument is true or an OR when the first argument is false, those being missing isn't surprising.

{{< highlight julia >}}
# in Julia; R and pandas.NA in Python behave the same
> true & missing
missing
> false & missing
false
> true | missing
true
> false | missing
missing
{{< / highlight >}}

If the missing data is the first argument, however, what should happen is less clear.  There's an argument to be made for Boolean expressions short-circuiting to "missing" or "NA" in that case, but it turns out that's not what happens -- instead, it behaves exactly like if the missing value was second:

{{< highlight r >}}
# in R
> NA & TRUE
NA
> NA & FALSE
FALSE
> NA | TRUE
TRUE
> NA | FALSE
NA
{{< / highlight >}}

R's documentation describes this like so:

>NA is a valid logical object. Where a component of x or y is NA, the result will be NA if the outcome is ambiguous. In other words NA & TRUE evaluates to NA, but NA & FALSE evaluates to FALSE.

Julia and `pandas.NA` operate in the same way, so presumably they use the same reasoning.


## A Note Regarding Pandas
Above, I always referred to Python's missing data type as `pandas.NA` for one particular reason.  In the past, Python's `pandas` would use `numpy.NaN` to fill in missing values.  Those won't work in boolean operations, since their introduction would coerce any numeric data to floats, where AND and OR aren't going to work.

{{< highlight python >}}
> import numpy as np
> a = np.array([True, np.NaN])
> a
array([ 1., nan])
> a.dtype
dtype('float64')
> a & a
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: ufunc 'bitwise_and' not supported for the input types, and the inputs could 
not be safely coerced to any supported types according to the casting rule ''safe''
{{< / highlight >}}

In version 1.0.0, however, pandas.NA was added, which [can be used in conjunction with boolean operators](https://pandas.pydata.org/pandas-docs/stable/user_guide/boolean.html):

{{< highlight python >}}
> import pandas as pd
> pd.NA & True
<NA>
> pd.NA & False
False
> pd.NA | True
True
> pd.NA | False
<NA>
{{< / highlight >}}
