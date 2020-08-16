---
title: Matrix to LaTeX
date: 2020-08-16
linktitle: Matrix to LaTeX
categories: ["Code"]
tags: ["Julia", "LaTeX", "Multiple Languages", "Python", "R"]
draft: false
description: Turning a two-dimensional array into a LaTeX string in Julia, Python, and R.
mathjax: true
slug: matrix-to-latex
---

notes:
- new to julia
- not including math environment controls in the LaTeX code
- matrix used: [3 4 5;6 7 9; 4 5 122]
- np.apply_along_axis doesn't work reliably (see https://github.com/numpy/numpy/issues/8352)
- Python has tricky print things:
>>> print(array_to_LaTeX(A))
\begin{bmatrix} 3 & 4 & 5 \\ 6 & 7 & 9 \\ 4 & 5 & 122 \end{bmatrix}
>>> array_to_LaTeX(A)
'\\begin{bmatrix} 3 & 4 & 5 \\\\ 6 & 7 & 9 \\\\ 4 & 5 & 122 \\end{bmatrix}'


I recently had to go through some matrix operations in R and then write up the results in LaTeX.  Formatting the R output to get it into a form for LaTeX isn't particularly hard, but it's tedious and it's regular enough that it seemed like it would be easy to code it up.  So I decided to try it for R, Python, and Julia.

<!--more-->

## Matrices in LaTeX

There are some specific ways to format a matrix in LaTeX, but the basics are using "&" as a delimiter between elements in a row and "\\\\" between lines.  Note that the double backslash for the line delimiter is *not* an [escape sequence](https://en.wikipedia.org/wiki/Escape_sequence) (though I had to escape the backslashes for the purposes of this post), but the fact that it looks like one will cause some trouble in a bit.

The matrix we will be working with is a basic 3-by-3 square matrix:

\\begin{bmatrix}
3 & 4 & 5 \\\\
6 & 7 & 9 \\\\
4 & 5 & 122 \\\\
\\end{bmatrix}

The goal is to generate LaTeX code needed to create this, so that it can just be copy-pasted directly into a LaTeX document (though I'm not including the code to enable the math environment in LaTeX):
{{< highlight tex >}}
\begin{bmatrix} 3 & 4 & 5 \\ 6 & 7 & 9 \\ 4 & 5 & 122 \end{bmatrix}
{{< / highlight >}}
This seems like it might be easy enough, but there are a few catches regarding string formatting.


## R

As I said, this problem emerged from working with R, so that's where I started.  The function here is pretty simple, taking a two-dimensional matrix `arr` and using `apply()` and `paste()` to combine and collapse the elements:

{{< highlight r >}}
> array_to_LaTeX <- function(arr){
>     rows <- apply(arr, MARGIN=1, paste, collapse = " & ")
>     matrix_string <- paste(rows, collapse = " \\\\ ")
>     return(paste("\\begin{bmatrix}", matrix_string, "\\end{bmatrix}"))
> }
{{< / highlight >}}

Here's where the escape sequences start creating problems, as trying to write `\begin{bmatrix}` and `\end{bmatrix}` with just single backslashes doesn't work.  `\b` is the escape sequence for a backspace ([at least in C](https://en.wikipedia.org/wiki/Escape_sequences_in_C) -- Python renders `\b` as `\x08` in a string, so I'm guessing R does the same even if it doesn't show that), while `\e` doesn't match anything in R and prompts an error:

{{< highlight r >}}
> "\end{bmatrix}"
Error: '\e' is an unrecognized escape in character string starting ""\e"
{{< / highlight >}}

Trying to print the result of this function directly doesn't quite give the desired output, since R renders the escape characters but LaTeX doesn't use escape sequences like that:
{{< highlight r >}}
> A <- matrix(c(3,4,5,6,7,9,4,5,122), ncol=3, byrow=TRUE)
> array_to_LaTeX(A)
[1] "\\begin{bmatrix} 3 & 4 & 5 \\\\ 6 & 7 & 9 \\\\ 4 & 5 & 122 \\end{bmatrix}"
{{< / highlight >}}

But it turns out `cat()` will print things out with the escaping backslashes suppressed, so we just run the output through that:

{{< highlight r >}}
> cat(array_to_LaTeX(A))
\begin{bmatrix} 3 & 4 & 5 \\ 6 & 7 & 9 \\ 4 & 5 & 122 \end{bmatrix}
{{< / highlight >}}

## Python

Python -- or rather, `numpy` -- ended up being a bit more difficult than R due to one major issue on top of the escape character issues.  There is a `numpy.apply_along_axis()` function which acts as an analogue of R's `apply()` function, but it turns out this works a little weirdly for strings:

{{< highlight python >}}
> import numpy as np
> A = np.array([[3, 4, 5], [6, 7, 9], [4, 5, 122]])
> np.apply_along_axis(lambda x: ' & '.join(x.tolist()), axis=1, arr=B) 
array(['3 & 4 & 5', '6 & 7 & 9', '4 & 5 & 1'], dtype='<U9')
{{< / highlight >}}

Notice that the last line is truncated -- part of "122" has been cut off.  This is a [known and fairly old](https://github.com/numpy/numpy/issues/8352) problem, which appears to be the result of `numpy` trying to guess the datatype of the output based purely on the first element returned by `numpy.apply_along_axis()`.  In this case, it's coming up with a string of length 9 for the first element, so it fits all subsequent elements into that type, truncating if it doesn't fit.  It's a subtle issue.

Ultimately, I fell back on something a bit more basic: list comprehensions and `str.join()`.

{{< highlight python >}}
> def array_to_LaTeX(arr):
>     arr = arr.astype("str")
>     nrow = arr.shape[0]
>     rows = [" & ".join(arr[i,:].tolist()) for i in range(nrow)]
>     return "\\begin{bmatrix} " + " \\\\ ".join(rows) + " \\end{bmatrix}"
{{< / highlight >}}

I expect that there are scalable solutions, but considering that any matrix you're trying to print in LaTeX will by constrained to fit on one page, this is fine.  The issues with escaping the backslashes remain the same as with R, including the issue with just viewing the output of the function versus printing it with a function:

{{< highlight python >}}
> array_to_LaTeX(A)
'\\begin{bmatrix} 3 & 4 & 5 \\\\ 6 & 7 & 9 \\\\ 4 & 5 & 122 \\end{bmatrix}'
> print(array_to_LaTeX(A))
\begin{bmatrix} 3 & 4 & 5 \\ 6 & 7 & 9 \\ 4 & 5 & 122 \end{bmatrix}

{{< / highlight >}}

## Julia

I'll state up front that I don't have much experience with Julia, so this is probably not the best way to go about it.  In particular, I had trouble finding an easy-to-use analogue to R's `apply()`, so I ended up more or less replicating the Python version since Julia has list comprehensions and a `join()` function of its own:

{{< highlight julia >}}
> function array_to_LaTeX(arr)
>     arr = string.(arr)
>     nrow = size(arr)[1]
>     rows = [join(arr[row,:], " & ") for row in range(1, 3, step=1)]
>     return string("\begin{bmatrix} ", join(rows, " \\ "), " \end{bmatrix}")
> end
> 
> A = [3 4 5; 6 7 9; 4 5 122]
> array_to_LaTeX(A)
"\begin{bmatrix} 3 & 4 & 5 \\ 6 & 7 & 9 \\ 4 & 5 & 122 \end{bmatrix}"
{{< / highlight >}}

Interestingly, Julia seems to be treating the strings as literals from the start -- there's no escape character issues going on (though that's not stopping the blog's code highlighting from highlighting `\b` regardless).
