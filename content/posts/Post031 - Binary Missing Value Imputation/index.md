---
title: Binary Missing Value Imputation
date: 2021-11-21
linktitle: Binary Missing Value Imputation
categories: ["Code"]
tags: ["R"]
draft: false
description: An attempt to impute missing values in binary data using other binary columns
mathjax: true
slug: binary-missing-imputation
---

A few datasets that I've seen have come with several different columns representing binary responses to questions.  Naturally, there are missing values scattered throughout, so some amount of imputation had to occur.  I decided to try coding up a way to do this by picking the mode of rows that were as similar as possible to the row with missing values.

The data being considered is a set of binary response variables to something like yes-no survey questions, not for something like one-hot columns.  This method is also just generally very slow, so it's not recommended for much -- it just seemed like an interesting experiment.

<!--more-->

## Two Methods

I thought about two different ways to do this.  One was to try to subset only the complete rows, then impute every missing value just from them.  Assuming that rows which are more similar in value are better for imputation, the [Hamming distance](https://en.wikipedia.org/wiki/Hamming_distance) would be quick-to-compute and easy to interpret, since you just compute the exclusive-or of the two rows and then sum the total number of true/1 values (easy thanks to type coercion).

So this process looks like the following:

1. Locate all rows with missing values in them.
2. Create a subset of the dataframe containing only the complete rows.
3. For each row with missing data:
  - XOR the row of interest with each row in the complete-row subset.
  - Take row-wise sums for each XOR result to get the Hamming distance.
  - Find the rows with the smallest Hamming distance.  ("Smallest" since there's no guarantee of rows with zero distance.)
  - Determine the mode of the features in those complete rows which are missing in the row of interest.
  - Substitute those values into the original row.

The second method is a variation where the complete-row dataframe is recreated after imputing a set of rows that are missing the same values, in the hope that those newly complete rows would be able to contribute some useful information to the other rows with missing data. Imputing the rows with the fewest missing values first would allow that are more "reasonable" (in the sense of having more non-imputed values) to have more influence on rows with more missing values, which to me sounds better than imputing the mostly-missing rows first and then using them for imputing the rows with fewer missing values.

Of course, it could easily end up turning out that the imputations introduce cumulative errors that end up corrupting later rows more heavily -- I'm not sure, and again, I don't have any theoretical justification for any of this.  The second method also going to be slower due to recalculating or modifying the complete-row dataframe after every imputation.

The second method looks a little different:

1. Locate all rows with missing values in them.
2. Create a subset of the dataframe containing only the complete rows.
3. Break down the rows with missing values by the patterns of missingness (number of missing values and which columns are missing).
4. Pick one pattern of missingness with the fewest number of missing values, and for each row that adheres to it:
  - XOR the row of interest with each row in the complete-row subset.
  - Take row-wise sums for each XOR'd row to get the Hamming distance.
  - Find the rows with the smallest Hamming distance.
  - Determine the mode of the features in those complete rows which are missing in the row of interest.
  - Substitute those values into the original row.
5. Recreate the complete-row dataframe with the newly-completed rows.
6. Repeat steps 4 and 5 for each pattern of missingness.



## First Method

First, create a basic dataset with 50 to 100 missing values scattered throughout each column:

{{< highlight r >}}
> library(tidyverse)
> 
> set.seed(12345)
> binary_df <- as.data.frame(matrix(rbinom(1e4, 1, 0.5), ncol=10))
> for(i in 1:10){
>     num_NA <- sample(50:100, 1)
>     NA_row <- sample(nrow(binary_df), num_NA)
>     binary_df[NA_row,i] <- NA
> }
> head(binary_df, 10)
   V1 V2 V3 V4 V5 V6 V7 V8 V9 V10
1   1  0  1  0  0  0  1  0  0   1
2   1 NA  1  1  1  0  0  0  1   1
3   1  0  1  0  1  1  0  0  0  NA
4   1  0 NA  1  0  0  0  0  0   0
5   0  1  0  1  0  1  0  0  1   1
6   0  0  1  1  1  1  1 NA  0   0
7   0  0 NA  1 NA  0  0  1 NA  NA
8   1  1  0  0  1  1  1  1  1  NA
9   1  1  0  0  1  0  1  1  0   1
10  1 NA  1  1  1  0  0  0 NA   0
{{< / highlight >}}

Then locate rows with missing data and subset the complete rows out of it.

{{< highlight r >}}
> rows_with_NAs <- which(rowSums(is.na(binary_df)) > 0)
> complete_row_df <- binary_df[-rows_with_NAs,]
> nrow(complete_row_df)
[1] 462
{{< / highlight >}}

And finally, impute the rows:

{{< highlight r >}}
> most_common_value <- function(vec){
>     return(as.integer(names(sort(table(vec), decreasing=TRUE))[1]))
> }
> 
> for(r in rows_with_NAs){
>     target_row <- binary_df[r,]
>     missing_cols <- names(target_row)[as.logical(is.na(target_row))]
>     complete_row_without_col <- complete_row_df %>% select(-all_of(missing_cols))
>     
>     target_row_clean <- target_row %>% select(-all_of(missing_cols))
>     
>     difference_count <- apply(complete_row_without_col, MARGIN = 1, function(x){sum(xor(x, target_row_clean))})
>     rows_with_min_diff <- which(difference_count == min(difference_count))
>     min_diff_data <- complete_row_df[rows_with_min_diff, missing_cols, drop=FALSE]
>     imputed_values <- sapply(min_diff_data, most_common_value)
>     binary_df[r, missing_cols] <- imputed_values
> }
> 
> head(binary_df, 10)
   V1 V2 V3 V4 V5 V6 V7 V8 V9 V10
1   1  0  1  0  0  0  1  0  0   1
2   1  1  1  1  1  0  0  0  1   1
3   1  0  1  0  1  1  0  0  0   1
4   1  0  1  1  0  0  0  0  0   0
5   0  1  0  1  0  1  0  0  1   1
6   0  0  1  1  1  1  1  1  0   0
7   0  0  0  1  0  0  0  1  0   1
8   1  1  0  0  1  1  1  1  1   1
9   1  1  0  0  1  0  1  1  0   1
10  1  1  1  1  1  0  0  0  0   0
{{< / highlight >}}


## Second Method

I'm using the same initial dataframe as before.

To more easily sort out the rows with issues, it would make sense to find all existing patterns of missingness in the rows, and then store the indices of all rows with that pattern together.  This is actually made fairly convenient by the `group_data()` function from `dplyr`, which returns information on the grouping structure of the data.

{{< highlight r >}}
> missingness_df <- binary_df %>%
>     rowwise() %>%
>     mutate(NumMissing = sum(is.na(c_across(V1:V10))),
>            MissingPattern = paste0(1*is.na(c_across(V1:V10)), collapse="")) %>%
>     select(NumMissing, MissingPattern)
> 
> missingness_df$Row <- 1:nrow(missingness_df)
> 
> missingness_df <- missingness_df %>%
>     group_by(NumMissing, MissingPattern) %>%
>     group_data() %>%
>     filter(NumMissing > 0)
> 
> head(missingness_df)
# A tibble: 6 × 3
  NumMissing MissingPattern       .rows
       <int> <chr>          <list<int>>
1          1 0000000001            [47]
2          1 0000000010            [35]
3          1 0000000100            [38]
4          1 0000001000            [32]
5          1 0000010000            [32]
6          1 0000100000            [38]
{{< / highlight >}}

The output of the above code is a dataframe with three columns:
- `NumMissing`, the number of missing values in the data
- `MissingPattern`, a string describing the pattern of the missing values (1 is missing, 0 is not)
- `.rows`, a list of the indices of the rows from the original dataframe that have that pattern of missingness

The data is already sorted on the `NumMissing` column in ascending order, courtesy of the grouping operation, so we can immediately iterate over `missingness_df`'s rows.

The structure of the imputation loop is fairly different -- instead of performing all the operations for one row at a time, the pattern of missingness lets us setup to do all rows with that pattern relatively quickly.  (There's no reason why this couldn't be applied to the first method of imputation, that's just how it ended up.)

{{< highlight r >}}
> for(mr in 1:nrow(missingness_df)){
>     pattern <- missingness_df[mr,]$MissingPattern
>     missing_columns <- (unlist(strsplit(pattern, split = "")) == "1")
>     missing_row_indices <- missingness_df[mr,]$.rows[[1]]
>     
>     complete_rows <- binary_df %>% select(V1:V10) %>% complete.cases() %>% filter(binary_df, .)
>     complete_row_without_col <- complete_rows[, !missing_columns]
>     
>     for(r in missing_row_indices){
>         target_row_clean <- binary_df[r, !missing_columns]
>         
>         difference_count <- apply(complete_row_without_col, MARGIN = 1, function(x){sum(xor(x, target_row_clean))})
>         rows_with_min_diff <- which(difference_count == min(difference_count))
>         min_diff_data <- complete_rows[rows_with_min_diff, , drop=FALSE]
>         imputed_values <- sapply(min_diff_data, most_common_value)
>         binary_df[r, ] <- imputed_values
>     }
> }
> 
> head(binary_df, 10)
   V1 V2 V3 V4 V5 V6 V7 V8 V9 V10
1   1  0  1  0  0  0  1  0  0   1
2   1  1  1  1  1  0  0  0  1   1
3   1  0  1  0  1  1  0  0  0   1
4   1  0  1  1  0  0  0  0  0   0
5   0  1  0  1  0  1  0  0  1   1
6   0  0  1  1  1  1  1  1  0   0
7   0  0  0  1  1  0  0  1  0   1
8   1  1  0  0  1  1  1  1  1   1
9   1  1  0  0  1  0  1  1  0   1
10  1  0  1  1  1  0  0  0  1   0
{{< / highlight >}}

## Final Notes

Again, I don't know if either of these methods is known or particularly good or not.  There's probably some use in trying to weight rows based on similarity, rather than the more strict inclusion rule that I used.  I know that there were at least a few instances where the set of most similar rows comprised only a few records, so bringing in information from other rows may help compensate (and may act as a reasonable "in-between" method relative to the two I coded up).
