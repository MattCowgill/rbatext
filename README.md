
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rbatext

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/MattCowgill/rbatext/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/MattCowgill/rbatext/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The Board of the Reserve Bank of Australia is responsible for monetary
policy. It meets 11 times each year. After each meeting, the Governor of
the RBA issues a statement outlining the reasons the Board did, or did
not, adjust interest rates at that meeting.\*

This R package contains the text of those decisions in a tidy tibble. It
also contains a function - `read_rba_decisions()` - that makes it easy
to scrape future decisions from the RBA website.

## Installation

You can install `rbatext` from GitHub with:

``` r
# install.packages("remotes")
remotes::install_github("MattCowgill/rbatext")
```

## RBA decisions

The key function in the package is `read_rba_decisions()`. You use it
like this:

``` r
library(rbatext)

decisions <- read_rba_decisions()

decisions
#> # A tibble: 219 × 3
#>    date       author        text                                                
#>    <date>     <chr>         <chr>                                               
#>  1 1990-01-23 Bernie Fraser The Governor of the Reserve Bank (Mr Bernie Fraser)…
#>  2 1990-02-15 Bernie Fraser The Reserve Bank acted in the domestic money market…
#>  3 1990-04-04 Bernie Fraser The Reserve Bank proposes to operate in the domesti…
#>  4 1990-08-02 Bernie Fraser The Reserve Bank will be operating in the domestic …
#>  5 1990-10-15 Bernie Fraser The Reserve Bank will be operating in the domestic …
#>  6 1990-12-18 Bernie Fraser Given current and prospective developments in the A…
#>  7 1991-04-04 Bernie Fraser The Reserve Bank will be operating in the domestic …
#>  8 1991-05-16 Bernie Fraser The Reserve Bank believes that some further reducti…
#>  9 1991-09-03 Bernie Fraser The Reserve Bank will be operating in the domestic …
#> 10 1991-11-06 Bernie Fraser The Reserve Bank will be operating in the money mar…
#> # ℹ 209 more rows
```

This returns a tidy tibble containing the full text of each monetary
policy decision since 1990.

### Working with this text data

Here’s an example of how to use the wonderful
[`{tidytext}`](https://www.tidytextmining.com) package to work with this
text data.

First we ‘unnest’ the text statements, counting the number of
occurrences of each word in each year:

``` r
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
library(lubridate)
#> 
#> Attaching package: 'lubridate'
#> The following objects are masked from 'package:base':
#> 
#>     date, intersect, setdiff, union
library(tidytext)

raw_word_counts <- decisions %>% 
  mutate(year = year(date)) %>% 
  unnest_tokens(word, text) %>% 
  group_by(year, word) %>% 
  count() 

raw_word_counts
#> # A tibble: 16,799 × 3
#> # Groups:   year, word [16,799]
#>     year word      n
#>    <dbl> <chr> <int>
#>  1  1990 0.5       1
#>  2  1990 1         2
#>  3  1990 10        1
#>  4  1990 12        2
#>  5  1990 13        1
#>  6  1990 15        3
#>  7  1990 16        1
#>  8  1990 1988      1
#>  9  1990 1989      2
#> 10  1990 1990      3
#> # ℹ 16,789 more rows
```

Then we remove ‘stop words’ (common words like ‘the’ or ‘if’), as well
as removing numbers from the text:

``` r
word_counts <- raw_word_counts %>% 
  anti_join(stop_words,
            by = "word") %>% 
  filter(is.na(suppressWarnings(as.numeric(word))))

word_counts
#> # A tibble: 11,575 × 3
#> # Groups:   year, word [11,575]
#>     year word             n
#>    <dbl> <chr>        <int>
#>  1  1990 abating          1
#>  2  1990 acceptable       1
#>  3  1990 account          4
#>  4  1990 accounts         1
#>  5  1990 accumulating     2
#>  6  1990 achieving        1
#>  7  1990 acted            1
#>  8  1990 action           4
#>  9  1990 activity         8
#> 10  1990 adjustment       2
#> # ℹ 11,565 more rows
```

Then we calculate the [term frequency-inverse document
frequency](https://www.tidytextmining.com/tfidf) of each word for each
year. This is the number of times a word is used in a given year,
adjusted by the number of times the word is used across all years.

``` r

year_tfidfs <- word_counts %>% 
  bind_tf_idf(word, year, n)

year_tfidfs
#> # A tibble: 11,575 × 6
#> # Groups:   year, word [11,575]
#>     year word             n      tf   idf   tf_idf
#>    <dbl> <chr>        <int>   <dbl> <dbl>    <dbl>
#>  1  1990 abating          1 0.00118 2.08  0.00245 
#>  2  1990 acceptable       1 0.00118 3.47  0.00408 
#>  3  1990 account          4 0.00471 0.470 0.00221 
#>  4  1990 accounts         1 0.00118 1.67  0.00197 
#>  5  1990 accumulating     2 0.00235 2.37  0.00557 
#>  6  1990 achieving        1 0.00118 0.758 0.000891
#>  7  1990 acted            1 0.00118 3.47  0.00408 
#>  8  1990 action           4 0.00471 1.07  0.00503 
#>  9  1990 activity         8 0.00941 0.288 0.00271 
#> 10  1990 adjustment       2 0.00235 0.758 0.00178 
#> # ℹ 11,565 more rows
```

Now we have this measure of which words best characterise the statements
issued in a given year. Let’s create a table showing the top 3 words for
each year, ranked by tf-idf:

``` r
year_tfidfs %>% 
  group_by(year) %>% 
  mutate(rank = rank(desc(tf_idf),
                     ties.method = "first")) %>% 
  filter(rank <= 3) %>% 
  arrange(rank) %>% 
  group_by(year) %>% 
  summarise(top_words = paste(word, collapse = ", ")) %>% 
  knitr::kable()
```

| year | top_words                             |
|-----:|:--------------------------------------|
| 1990 | imports, reduction, percentage        |
| 1991 | percentage, competitiveness, reserve  |
| 1992 | overnight, reserve, encouragement     |
| 1993 | foreign, overnight, flow              |
| 1994 | weight, loan, loans                   |
| 1996 | salary, objective, enterprise         |
| 1997 | day, earnings, figures                |
| 1998 | assumption, adoption, agreement       |
| 1999 | designed, expansionary, chance        |
| 2000 | buoyant, benign, direct               |
| 2001 | transitional, corporate, weakened     |
| 2002 | firmer, house, imbalances             |
| 2003 | farm, tradeables, climate             |
| 2005 | constitute, deficiency, fourteenth    |
| 2006 | background, accelerating, compression |
| 2007 | communication, wholesale, pose        |
| 2008 | evaluate, restrain, opposing          |
| 2009 | companies, access, durable            |
| 2010 | caution, degree, loan                 |
| 2011 | related, production, resources        |
| 2012 | rated, corporations, europe           |
| 2013 | bit, sensitive, adjusts               |
| 2014 | appropriately, configured, safe       |
| 2015 | arise, commercial, varied             |
| 2016 | remarkably, complicate, purposes      |
| 2017 | mining, boom, transition              |
| 2018 | nationwide, bit, gradual              |
| 2019 | disposable, times, scenario           |
| 2020 | coronavirus, yield, facility          |
| 2021 | billion, yield, bond                  |
| 2022 | pandemic, ukraine, incoming           |
| 2023 | savings, timeframe, people            |

### The small print

\*Prior to December 2007, a media release was only issued if the Board
decided to adjust monetary policy. Since that time, statements have been
issued after each meeting, regardless of the outcome.

Note that this package has an ‘experimental’ badge. The package works
and is stable. However, changes to the format or structure of the RBA
website would break the package’s key function. For this reason, the
function is somewhat ‘brittle’. I do not intend to submit this package
to CRAN. I may at some point merge this package with
[readrba](https://github.com/MattCowgill/readrba).
