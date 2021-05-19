---
title: Date Operations in MongoDB
date: 2021-05-19
linktitle: Date Operations in MongoDB
categories: ["Code"]
tags: ["MongoDB", "Python"]
draft: false
description: Some quick examples of date operations in MongoDB.
mathjax: true
slug: mongodb-dates
---

As with most database technologies, MongoDB has support for a Date-type object.  Writing up operations on date fields in MongoDB can be a little tricky,
mostly due to the fact that while the [date operators](https://docs.mongodb.com/manual/meta/aggregation-quick-reference/#date-expression-operators) are fairly straightforward, they won't work in normal `find()` queries, meaning you need to use the [aggregation syntax](https://docs.mongodb.com/manual/reference/aggregation/) for anything complicated.

<!--more-->

For these examples, I'm using the `listingsAndReviews` collection from the example databases, as it has a few different date fields that are good for illustrative purposes.  I'm also using Python and the `pymongo` library for the code.

{{< highlight python >}}
> from datetime import datetime
> import pymongo
> 
> client = pymongo.MongoClient("mongodb+srv://username:password@cluster.xxxxx.mongodb.net/sample_airbnb")
> listings = client.sample_airbnb.listingsAndReviews
{{< / highlight >}}

A typical record from the database looks like this:

![Record in listingsAndReviews.]({{< resource url="record.png" >}})

## Filtering on Dates

If you're filtering on fields that are before or after a certain date, then a normal query with `find()` and the appropriate comparison operator works perfectly fine.  The only caveat is that you'll need to pass it a Python `datetime.datetime` object instead of a string or other representation.  For instance, grabbing the records that were last scraped after 2019-03-01:

{{< highlight python >}}
> filter_after = listings.find({"last_scraped": {"$gte": datetime(2019, 3, 1)}},
>                              {"_id":1, "name":1, "last_scraped":1}).limit(5)
> list(filter_after)
[{'_id': '10057826',
  'name': 'Deluxe Loft Suite',
  'last_scraped': datetime.datetime(2019, 3, 7, 5, 0)},
 {'_id': '10021707',
  'name': 'Private Room in Bushwick',
  'last_scraped': datetime.datetime(2019, 3, 6, 5, 0)},
 {'_id': '1001265',
  'name': 'Ocean View Waikiki Marina w/prkg',
  'last_scraped': datetime.datetime(2019, 3, 6, 5, 0)},
 {'_id': '10057447',
  'name': 'Modern Spacious 1 Bedroom Loft',
  'last_scraped': datetime.datetime(2019, 3, 11, 4, 0)},
 {'_id': '10066928',
  'name': '3 chambres au coeur du Plateau',
  'last_scraped': datetime.datetime(2019, 3, 11, 4, 0)}]
{{< / highlight >}}

You can filter on a single year or month by just using the appropriate combination of greater than and less than operators.  If, on the other hand, you wanted to try returning only the records from March, regardless of year, day of month, etc., then we need the aggregation syntax:

{{< highlight python >}}
> march_only = listings.aggregate([
>     {"$project": {"name": 1, "last_scraped": 1, "month":{"$month": "$last_scraped"}}},
>     {"$match": {"month": 3}},
>     {"$limit": 5}
> ])
> list(march_only)
[{'_id': '10057826',
  'name': 'Deluxe Loft Suite',
  'last_scraped': datetime.datetime(2019, 3, 7, 5, 0),
  'month': 3},
 {'_id': '10021707',
  'name': 'Private Room in Bushwick',
  'last_scraped': datetime.datetime(2019, 3, 6, 5, 0),
  'month': 3},
 {'_id': '1001265',
  'name': 'Ocean View Waikiki Marina w/prkg',
  'last_scraped': datetime.datetime(2019, 3, 6, 5, 0),
  'month': 3},
 {'_id': '10057447',
  'name': 'Modern Spacious 1 Bedroom Loft',
  'last_scraped': datetime.datetime(2019, 3, 11, 4, 0),
  'month': 3},
 {'_id': '10066928',
  'name': '3 chambres au coeur du Plateau',
  'last_scraped': datetime.datetime(2019, 3, 11, 4, 0),
  'month': 3}]
{{< / highlight >}}

Since all values in the `last_scraped` column are from 2019, we get the same results as with the first query.  This being the aggregation pipeline, we first need to actually create the `month` value using the `$month` operator on the column, then we can match on the value and return the first five results.

*(Note: it is actually possible to do this with a find operation, but that requires passing Javascript functions to MongoDB, which isn't what this post is oriented towards.)*


## Grouping by Year/Month/Day
Also common in date operations is grouping by a certain time interval.  

{{< highlight python >}}
> scraped_by_month = listings.aggregate([{"$group": {"_id": {"month": {"$month": "$last_scraped"}},
>                                                    "count":{"$sum":1}}}]):
> list(scraped_by_month)
[{'_id': {'month': 3}, 'count': 3733}, {'_id': {'month': 2}, 'count': 1822}]
{{< / highlight >}}

The `last_scraped` column is a bit limited in its time range, but there is a `reviews` field which contains an array of reviews for each location, and those span a much larger time range.  Each review has a date associated with it, so we can pull out the reviews into separate documents with the `$unwind` operator and then group the results:

{{< highlight python >}}
> reviews_per_year = listings.aggregate([{"$unwind":"$reviews"},
>                                        {"$group": {"_id": {"year": {"$year": "$reviews.date"}},
>                                                    "count":{"$sum":1}}},
>                                        {"$sort": {"_id.year": 1}}])
> list(reviews_per_year)
[{'_id': {'year': 2009}, 'count': 5},
 {'_id': {'year': 2010}, 'count': 40},
 {'_id': {'year': 2011}, 'count': 275},
 {'_id': {'year': 2012}, 'count': 866},
 {'_id': {'year': 2013}, 'count': 2587},
 {'_id': {'year': 2014}, 'count': 6258},
 {'_id': {'year': 2015}, 'count': 13369},
 {'_id': {'year': 2016}, 'count': 23636},
 {'_id': {'year': 2017}, 'count': 39423},
 {'_id': {'year': 2018}, 'count': 54990},
 {'_id': {'year': 2019}, 'count': 8343}]
{{< / highlight >}}

It's not too surprising that the number of reviews has grown as much as it has.  Also, the collection appears to use data taken from sometime early in 2019, so the relatively small number of reviews in that year compared to 2018 makes sense.

## Grouping by Date Comparison

As a final example, suppose we're grouping by the time between the first and last reviews as a very rough proxy for how long the property has been active (since there are no better fields to use for it directly).  Dates can be subtracted like normal numbers, and MongoDB returns the difference between the times in milliseconds.  So if we wanted to count the number of records, grouping by the number of full years between the first and last reviews, then since those two times conveniently have their own fields:

{{< highlight python >}}
> review_timespans = listings.aggregate([
>     {"$match": {"first_review": {"$exists": True}}},
>     {"$project":{"timediff":{"$floor":{"$divide":[{"$subtract":["$last_review", "$first_review"]}, 1000*60*60*24*365.25]}}}},
>     {"$group": {"_id": "$timediff", "count":{"$sum":1}}},
>     {"$sort": {"_id": 1}}
> ])
> list(review_timespans)

[{'_id': 0.0, 'count': 1869},
 {'_id': 1.0, 'count': 821},
 {'_id': 2.0, 'count': 596},
 {'_id': 3.0, 'count': 402},
 {'_id': 4.0, 'count': 223},
 {'_id': 5.0, 'count': 156},
 {'_id': 6.0, 'count': 64},
 {'_id': 7.0, 'count': 31},
 {'_id': 8.0, 'count': 4},
 {'_id': 9.0, 'count': 1}]
{{< / highlight >}}

Note that not all records appear here, as some don't have reviews.

## Conclusion

This covers a few basic date operations in MongoDB, and it is nowhere near exhaustive.  MongoDB can handle dates perfectly well, but ensure that you are either familiar with the aggregation syntax or good with Javascript for MongoDB, as you will need one of those (probably both) a lot.
