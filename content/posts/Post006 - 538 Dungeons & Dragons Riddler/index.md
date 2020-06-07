---
title: 538 Dungeons & Dragons Riddler
date: 2020-05-23
linktitle: 538 Dungeons & Dragons Riddler
categories: ["Statistics"]
tags: ["R", "Simulation", "Statistics"]
draft: false
description: Analytical and simulation solutions to a 538 Riddler Classic for 2020-05-15.
mathjax: true
slug: 538-dnd-riddler
---

This problem was [the Riddler Classic on 538 for May 15, 2020](https://fivethirtyeight.com/features/can-you-find-the-best-dungeons-dragons-strategy/).  The problem is as follows:

> *The fifth edition of Dungeons & Dragons introduced a system of "advantage and disadvantage." When you roll a die "with advantage," you roll the die twice and keep the higher result. Rolling "with disadvantage" is similar, except you keep the lower result instead. The rules further specify that when a player rolls with both advantage and disadvantage, they cancel out, and the player rolls a single die. Yawn!* \
*There are two other, more mathematically interesting ways that advantage and disadvantage could be combined. First, you could have "advantage of disadvantage," meaning you roll twice with disadvantage and then keep the higher result. Or, you could have "disadvantage of advantage," meaning you roll twice with advantage and then keep the lower result. With a fair 20-sided die, which situation produces the highest expected roll: advantage of disadvantage, disadvantage of advantage or rolling a single die?* \
*Extra Credit: Instead of maximizing your expected roll, suppose you need to roll N or better with your 20-sided die. For each value of N, is it better to use advantage of disadvantage, disadvantage of advantage or rolling a single die?*

This problem seemed like it could be tackled from both a coding/simulation angle and an analytical angle.  So I did both.  The solutions can be found [here](https://fivethirtyeight.com/features/somethings-fishy-in-the-state-of-the-riddler/); while the path I take is a bit different, the results are the same.

<!--more-->

The problem breaks down into four separate steps:

1. Calculate the distributions for rolling with advantage and rolling with disadvantage.
2. Calculate the distributions for the advantage of the disadvantage (which I'll call AOD for short) and the disadvantage of the advantage (DOA).
3. Determine the expected values of the AOD, DOA, and single die rolls, and compare.
4. For the extra credit, determine the probabilities of getting a roll of at least \\(N\\).



## Simulation

Figuring out the distributions of the different rolls is fairly easy.  First we need the advantage and disadvantage distributions:

{{< highlight r >}}
D <- 20   #number of sides on the die
advantage <- matrix(data=NA, nrow=D, ncol=D)
disadvantage <-  matrix(data=NA, nrow=D, ncol=D)

for(i in 1:D){
    for(j in 1:D){
        advantage[i,j] = max(i,j)
        disadvantage[i,j] = min(i,j)
    }
}
{{< / highlight >}}

We can get expected values and counts of the rolls pretty easily from this

{{< highlight r >}}
> mean(advantage)
[1] 13.825

> table(advantage)
advantage
 1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 
 1  3  5  7  9 11 13 15 17 19 21 23 25 27 29 31 33 35 37 39
{{< / highlight >}}

But our interest is in the AOD and DOA.  We could try to go through this by generating another matrix like the ones for the advantage and disadvantage rolls, though we'd need to weight the cells based on the probabilities of each roll.  A much less sophisticated (but equally effective) option is to note that the matrix lists out every possible outcome, with the weights accounted for by the number of times each value appears.  Thus, we can brute-force this by computing the advantages and disadvantages for each combination of elements in the corresponding matrix:

{{< highlight r >}}
advantage_vector <- as.numeric(advantage)   # Get it into vector form
disadvantage_vector <- as.numeric(disadvantage)   # Get it into vector form
adv_of_disadv <- matrix(data=NA, nrow=D^2, ncol=D^2)
disadv_of_adv <- matrix(data=NA, nrow=D^2, ncol=D^2)

for(i in 1:D^2){
    for(j in 1:D^2){
        adv_of_disadv[i,j] <- max(disadvantage_vector[i], disadvantage_vector[j])
        disadv_of_adv[i,j] <- min(advantage_vector[i], advantage_vector[j])
    }
}
{{< / highlight >}}

Something like this would obviously not work for more complicated rolls, as there's a polynomial increase in the number of matrix elements from the number of sides on the die and an exponential increase from the number of dice you're comparing.  Going much larger would exhaust computer memory quite quickly.  But since we only have \\(20^4 = 160,000\\) elements, it's not a big deal.  Then, like before, we can get the expected values quite easily:

{{< highlight r >}}
> mean(adv_of_disadv)
[1] 9.833338

> mean(disadv_of_adv)
[1] 11.16666
{{< / highlight >}}

The expected value for a single fair die is just the average of the values on its faces, which works out here to be 10.5.  So the disadvantage of the advantage has the best expected value.  Looking at the probabilities graphically backs this up, as the bulk of the DOA probability seems to be at and above 11:

![Probabilities for rolls under the three conditions.]({{< resource url="p1_probability.png" >}})

For the extra credit, we need to find the probability of getting a value of at least \\(N\\) on a roll.  The single die is the easy case: Its values follow a discrete uniform distribution, so there's a 20/20 chance of rolling a 1 or better, 19/20 for at least 2, and so on until 1/20 for 20 or better (and it can't be better than that for a d20 die). The other two cases are only slightly harder, since we don't have a nice theoretical result (yet).  But we do have the probabilities of each event, courtesy of the 400-by-400 tables above.  We tabulate the results and divide by 160,000 to get probabilities for the individual die rolls, then take the appropriate cumulative sums:

{{< highlight r >}}
AOD_probs <- table(adv_of_disadv)/160000
DOA_probs <- table(disadv_of_adv)/160000
extra_credit <- data.frame(MinRoll = 1:20, OneDie = 20:1/20,
                           AOD = rev(cumsum(rev(AOD_probs))),
                           DOA = rev(cumsum(rev(DOA_probs))))
{{< / highlight >}}

| Min. Roll | One Die | AOD | DOA |
| ------- | ------ | --- | --- |
|      1  |   **1.000** | **1.000** | **1.000** |
|      2  |   0.950 | 0.990 | **0.995** |
|      3  |   0.900 | 0.964 | **0.980** |
|      4  |   0.850 | 0.923 | **0.956** |
|      5  |   0.800 | 0.870 | **0.922** |
|      6  |   0.750 | 0.809 | **0.879** |
|      7  |   0.700 | 0.740 | **0.828** |
|      8  |   0.650 | 0.666 | **0.770** |
|      9  |   0.600 | 0.590 | **0.706** |
|     10  |   0.550 | 0.513 | **0.636** |
|     11  |   0.500 | 0.438 | **0.562** |
|     12  |   0.450 | 0.364 | **0.487** |
|     13  |   0.400 | 0.294 | **0.410** |
|     14  |   **0.350** | 0.230 | 0.334 |
|     15  |   **0.300** | 0.172 | 0.260 |
|     16  |   **0.250** | 0.121 | 0.191 |
|     17  |   **0.200** | 0.078 | 0.130 |
|     18  |   **0.150** | 0.044 | 0.077 |
|     19  |   **0.100** | 0.020 | 0.036 |
|     20  |   **0.050** | 0.005 | 0.010 |

The maximum probability for each column is in bold.  \\(N=1\\) is a trivial case, as you can't roll less than 1, so you'll always get a high enough roll.  For 2 to 13, the disadvantage of the advantage proves to have the highest probability of success, while the single die is your best chance for when your roll must be at least 14.

## Analytical Solution

From a more theoretical view, this problem amounts to calculating the distributions for [order statistics](https://en.wikipedia.org/wiki/Order_statistic), which give the distributions of various rankings (e.g., maximum, minimum, third-smallest) for a collection of variables drawn from the same distribution.  We'll start by letting \\(F(x)\\) denote the cumulative distribution function (CDF) for a random variable \\(X\\), and letting \\( F_G(x) \\) denote the CDF for some statistic \\(G(x)\\).

Consider \\(X_{(j)}\\) as the \\(j\\)th order statistic from a sample of \\(n\\) variables -- that is, there are \\(j-1\\) values below it and \\(n-j\\) above -- then the CDF is given as

$$F_{X_{(j)}}(x) = \sum_{k=j}^n {n \choose k} F(x)^k [1-F(x)]^{n-k}$$

Since the individual dice rolls are samples from a discrete uniform distribution with possible values from 1 to 20, when rolling for advantage or disadvantage, \\(F(x) = x/20\\).  The case for rolling with advantage is the maximum of two rolls, so it is the second order statistic:

$$ F_{ADV}(x) = F_{X_{(2)}}(x) = {2 \choose 2} \left( \frac{x}{20} \right)^2 \left( 1-\frac{x}{20} \right)^0 = \frac{x^2}{400}$$

Similarly, a roll for disadvantage has a CDF of:

$$F_{DIS}(x) = F_{X_{(1)}}(x) = {2 \choose 1} \left( \frac{x}{20} \right)^1 \left( 1-\frac{x}{20} \right)^1 + {2 \choose 2} \left( \frac{x}{20} \right)^2 \left( 1-\frac{x}{20} \right)^0 = \frac{40x-x^2}{400}$$

Since these are cumulative sums at integer values from 1 to \\(1\leq x \leq 20\\), the probability for a single value \\(X=x\\) to arise is the CDF at \\(x\\) minus the CDF at \\(x-1\\).  So the probability of a specific value \\(x\\) resulting from a roll with advantage is

$$P(X_{ADV} = x) = \frac{x^2}{400} - \frac{(x-1)^2}{400} = \frac{2x-1}{400}$$

This agrees with the distribution of the counts from the simulation aside from the normalizing factor of 400:

{{< highlight r >}}
> table(advantage)
advantage
 1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 
 1  3  5  7  9 11 13 15 17 19 21 23 25 27 29 31 33 35 37 39 

> 2*(1:20)-1
[1]  1  3  5  7  9 11 13 15 17 19 21 23 25 27 29 31 33 35 37 39
{{< / highlight >}}

Similarly, for rolling with disadvantage,

$$P(X_{DIS} = x) = \frac{40x-x^2}{400} - \frac{40(x-1-(x-1)^2}{400} = \frac{41 - 2x}{400}$$

Which again matches the simulation above (not repeated here for brevity).  This now brings us to the AOD and DOA. The advantage of disadvantage is just the second order statistic of two disadvantage rolls, so we largely repeat the work we did above, just with the \\(F_{DIS}(x)\\) for our CDF:

$$F_{AOD}(x) = {2 \choose 2} \left( \frac{40x-x^2}{400}\right)^2 = \frac{1600x^2 - 80x^3 + x^4}{400^2} $$

And the probability for a specific value is then

$$P(X_{AOD} = x) = \frac{4x^3 - 246x^2 + 3444x - 1681}{400^2}$$

Sure enough, this matches the distribution of values from before:

{{< highlight r >}}
> table(adv_of_disadv)
adv_of_disadv
    1     2     3     4     5     6     7     8     9    10    11    12    13    14    15    16    17 
 1521  4255  6545  8415  9889 10991 11745 12175 12305 12159 11761 11135 10305  9295  8129  6831  5425 
   18    19    20 
 3935  2385   799

> AOD_stats <- sapply(1:20, function(x){4*x^3 - 246*x^2 + 3444*x - 1681})
> AOD_stats
[1]  1521  4255  6545  8415  9889 10991 11745 12175 12305 12159 11761 11135 10305  9295  8129
[16]  6831  5425  3935  2385   799
{{< / highlight >}}

And we get the same expected value as well:

{{< highlight r >}}
> sum((1:20)*AOD_stats/400^2)
[1] 9.833338
{{< / highlight >}}

Next, the DOA is the first order statistic for \\(F_{ADV}(x)\\) with \\(n=2\\) rolls:

$$F_{DOA}(x) = {2 \choose 1}\left(\frac{x^2}{400}\right) \left(1 - \frac{x^2}{400}\right) + {2 \choose 2} \left(\frac{x^2}{400}\right)^2 = \frac{800x^2 - x^4}{400^2}$$

Making the probability of a specific value

$$ P(X_{DOA} = x) = \frac{-4x^3 + 6x^2 + 1596x - 799}{400^2} $$

Again, we match the simulation:

{{< highlight r >}}
> table(disadv_of_adv)
disadv_of_adv
    1     2     3     4     5     6     7     8     9    10    11    12    13    14    15    16    17 
  799  2385  3935  5425  6831  8129  9295 10305 11135 11761 12159 12305 12175 11745 10991  9889  8415 
   18    19    20 
 6545  4255  1521

> DOA_stats <- sapply(1:20, function(x){-4*x^3 + 6*x^2 + 1596*x - 799})
> DOA_stats
 [1]   799  2385  3935  5425  6831  8129  9295 10305 11135 11761 12159 12305 12175 11745 10991
[16]  9889  8415  6545  4255  1521

> sum((1:20)*DOA_stats/400^2)
[1] 11.16666
{{< / highlight >}}

The extra credit is pretty quick.  The CDF deals with the cumulative probability up to a point:

$$ F(x) = P(X \leq x) $$

So to figure out the probability of getting a roll of \\(N\\) or better, we need to compute 1 minus the corresponding CDF at \\(x=N-1\\).  Since we have the CDFs for the AOD and DOA already:

{{< highlight r >}}
AOD_CDF <- function(x){(1600*x^2 - 80*x^3 + x^4)/400^2}
DOA_CDF <- function(x){(800*x^2 - x^4)/400^2}
extra_credit2 <- data.frame(MinRoll = 1:20, OneDie = 20:1/20,
                            AOD = sapply(1:20, function(x){1-AOD_CDF(x-1)}),
                            DOA = sapply(1:20, function(x){1-DOA_CDF(x-1)}))
{{< / highlight >}}


Once again, the results are the same:

| Min. Roll | One Die | AOD | DOA |
| ------- | ------ | --- | --- |
|      1  |   **1.000** | **1.000** | **1.000** |
|      2  |   0.950 | 0.990 | **0.995** |
|      3  |   0.900 | 0.964 | **0.980** |
|      4  |   0.850 | 0.923 | **0.956** |
|      5  |   0.800 | 0.870 | **0.922** |
|      6  |   0.750 | 0.809 | **0.879** |
|      7  |   0.700 | 0.740 | **0.828** |
|      8  |   0.650 | 0.666 | **0.770** |
|      9  |   0.600 | 0.590 | **0.706** |
|     10  |   0.550 | 0.513 | **0.636** |
|     11  |   0.500 | 0.438 | **0.562** |
|     12  |   0.450 | 0.364 | **0.487** |
|     13  |   0.400 | 0.294 | **0.410** |
|     14  |   **0.350** | 0.230 | 0.334 |
|     15  |   **0.300** | 0.172 | 0.260 |
|     16  |   **0.250** | 0.121 | 0.191 |
|     17  |   **0.200** | 0.078 | 0.130 |
|     18  |   **0.150** | 0.044 | 0.077 |
|     19  |   **0.100** | 0.020 | 0.036 |
|     20  |   **0.050** | 0.005 | 0.010 |


## Conclusion
Even before 538's solutions went up, the fact that analytical and simulation solutions were the same made it clear that this was a good answer.  The solutions that 538 posted are a bit more clever and concise than mine, though, so I encourage you to read those if you're interested in the problem.

This was also a good problem for practicing the use of order statistics, given that we start from a fairly simple distribution and move into something more analytically complicated (and with some real-world relevance, if you're a Dungeons & Dragons player).
