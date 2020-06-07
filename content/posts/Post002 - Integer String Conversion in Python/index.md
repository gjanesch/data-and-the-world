---
title: Integer String Conversion in Python
date: 2020-02-24
linktitle: Integer String Conversion in Python
categories: ["Code"]
tags: ["Python"]
draft: false
description: A quick class for converting numeric strings between a few different bases.
mathjax: true
slug: python-integer-string-conversion
---

Handling numbers as strings is one of those data things that's a pretty consistent pain.  I, personally, have had to deal with translating between binary and hexadecimal strings with some regularity.  And this is a situational need, so there's not much reason to expect something pre-built.  So I threw together a quick class myself.

<!--more-->
    
{{< highlight python3 >}}
class IntegerConverter:
    """Simple class for converting between numeric strings in several different bases."""
    informats = {"bin":2, "oct":8, "dec":10, "hex":16}
    outformats = {"bin":"b", "oct":"o", "dec":"d", "hex":"X"}
    
    def convert_string(self, in_string, informat="bin", outformat="hex", length=None):
        integer_value = int(in_string, self.informats[informat])
        if length is None:
            return format(integer_value, self.outformats[outformat])
        else:
            return format(integer_value, f"0{length}{self.outformats[outformat]}")
{{< / highlight >}}

A quick example:

{{< highlight python3 >}}
> ic = IntegerConverter()
> ic.convert_string("10", "bin", "dec")
'2'
> ic.convert_string("10", "hex", "dec")
'16'
{{< / highlight >}}

The core of it simply translates from a specified string and format to an integer, and then to a string with a new base.  The former step is fairly easy, but in order to be flexible enough for my use, the integer-to-string step requires two formatting operations -- one to properly construct the [format string](https://docs.python.org/3/library/string.html#formatspec) passed to `format()`, and the `format()` call itself.  There's no neat, concise way I can find to translate from an integer to a string with an arbitrary base, and it'd be overkill for what I need anyway since there's only a few bases that I'm concerned with.

The `length` argument is there to handle instances where I need zero-padded strings that are a certain length.

{{< highlight python3 >}}
> ic.convert_string("160", "dec", "hex", length=4)
'00A0'
{{< / highlight >}}

If `length` is specified but the number of characters needed to store it is greater than that, the string will use as many characters as needed and no warning or error will come up.

{{< highlight python3 >}}
> ic.convert_string("01AF81", "hex", "bin", length=5)
'11010111110000001'
{{< / highlight >}}


Finally, there's a subtle but important key for this whole snippet to work.  For most languages, you have to be pretty mindful about the size of the numeric type you're dealing with - neglecting it can cause some tricky problems.  But according to [the Python docs themselves](https://docs.python.org/3/c-api/long.html):

> *All integers are implemented as "long" integer objects of arbitrary size.*

So this will, in theory, be capable of translating arbitrarily large numeric strings.

{{< highlight python3 >}}
> ic.convert_string("160000000000000000000000000000000000000000000000000000000000000000", "dec", "hex")
'184F03E93FF9F4DAA797ED6E38ED64BF6A1F0100000000000000000'
{{< / highlight >}}
