---
title: MST3K Episode vs Movie Scores
date: 2020-02-09
linktitle: MST3K Episode vs Movie Scores
categories: ["Analysis"]
tags: ["Analysis", "Webscraping", "Python", "R"]
draft: false
description: Looking at how the IMDB scores of episodes of Mystery Science Theater 3000 align with the movies they make fun of.
mathjax: true
slug: mst3k-correlations
---


First broadcast in 1988, *Mystery Science Theater 3000* is a television show whose nominal story involves a guy being trapped in space by a couple of mad scientist types...which is actually just an excuse to have a few guys make fun of really, really bad movies.  This raises a few unusual questions about the series (as far as TV series go, anyway), like how the movie quality relates to the episode quality.  Thankfully, this isn't too hard to get data on, as we can just look at the IMDB ratings for both.

<!--more-->

The ratings were all pulled from IMDB -- a Python package called [IMDbPY](https://imdbpy.readthedocs.io/en/latest/index.html) was used for the episodes, while the films' information was collected manually since there was no neat way to get their IDs.  There were a reasonable number of ratings on both sides, with episodes having typically several hundred ratings and the films having at least that many.  *MST3K* is often credited with bringing some of these films to life again, which is likely part of the reason.  The data that I collected is [here]({{ resource url="MST3k.csv" >}}).

A couple notes:

* *MST3K*'s very first season, broadcast on local station KTMA in Minnesota, had some oddities in the format.  As a result, we're ignoring those episodes.
* A number of episodes have a short or two before the movie proper.  We're ignoring the shorts' scores and just looking at the movies'.
* [IMDB scores are **not** the average scores of the viewers](https://help.imdb.com/article/imdb/track-movies-tv/weighted-average-ratings/GWT2DSBYVT2F25SK), supposedly to curb vote spamming.  It's not clear how it works since it's proprietary, and they do actually supply the arithmetic means, but I'll note that one of the most notorious films featured in the series, *Manos: The Hands of Fate*, has just over one-sixth of its ratings as 10/10 and pretty much everything else at the bottom of the ratings scale, so I'm inclined to go with IMDB's adjusted ratings.

![Screenshot from Feb 9, 2020.]({{< resource url="images/20200209_IMDB_Manos.png" >}})

We'll start with a quick look at just the episode ratings versus the movie ratings.  Since IMDB's ratings only go to the tenths place, there are quite a few overlapping points, so we jitter the points slightly (with a linear regression on top):

![Episode vs Movie Score]({{< resource url="images/plot1_ep_vs_movie.png" >}})

Turns out there's not a lot to see here -- there's no pattern to the data, and the correlation for this data is a mere -0.0582.

There's been three different guys stuck in space over the course of the series: Joel up to partway through season 5, Mike from when Joel left to the end of season 10, and Jonah for seasons 11 and 12.  Do any of them show stronger correlations by themselves?

![Episode vs Movie Score, grouped by guy in space]({{< resource url="images/plot2_ep_vs_movie_by_guy.png" >}})

A little bit.  Joel was apparantly pretty consistent during his time in space (correlation -0.0110), while Mike and Jonah has stronger but still not that good correlations (-0.1468 and -0.1803 respectively), giving a weak suggestion that the worse their movies were, the better the episode.  Joel also had the best average score of 7.85, with Mike and Jonah averaging 7.53 and 7.55 respectively.  (Which is a little disappointing, since I always liked Mike the best.)

One final look - is there anything interesting about scores over time?

![Scores Over Time]({{< resource url="images/plot3_over_time.png" >}})

Since Joel was the first guy in space and had the best scores before, it makes sense that there's a slight downward trend in episode ratings over time.  The movies, perhaps more interestingly, are actually pretty steady over time on average.  But there's a pretty major difference in the variation of the scores -- the episode ratings' first and third quartiles are 7.4 and 8, while they're 2.3 and 4 for the movie ratings.  In particular, the episode ratings have a standard deviation of 0.507 points, while the movies are at 1.119 points.

There are undoubtedly finer breakdowns that could be done here.  I know that a number of the dubbed foreign-language films that *MST3K* riffed on were the more high-scoring ones on IMDB, many of the Godzilla and Gamera films in particular.  There's also a lot of thematic options -- there were a lot of films from the 50's and 60's focusing on juvenile delinquents, and quite a few that had giant (usually cheesy) monsters.
