
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rbatext

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/MattCowgill/rbatext/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/MattCowgill/rbatext/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

This R package enables easy access to the full text of the [Reserve Bank
of Australia’s](https://www.rba.gov.au/) monetary policy
[decisions](https://www.rba.gov.au/monetary-policy/int-rate-decisions/2025/)
and
[minutes](https://www.rba.gov.au/monetary-policy/rba-board-minutes/2025/).

The package contains two key functions - `read_rba_decisions()` and
`read_rba_minutes()`.

## Installation

You can install `rbatext` from GitHub with:

``` r
# install.packages("remotes")
remotes::install_github("MattCowgill/rbatext")
```

## Reading RBA decisions and minutes

The functions `read_rba_decisions()` and `read_rba_minutes()` do what
they say on the tin:

``` r
library(rbatext)
```

``` r
decisions <- read_rba_decisions()

decisions
#> # A tibble: 233 × 5
#>    date       author        text                cash_rate_change cash_rate_level
#>    <date>     <chr>         <chr>                          <dbl>           <dbl>
#>  1 1990-01-23 Bernie Fraser The Governor of th…            -0.75            17.2
#>  2 1990-02-15 Bernie Fraser The Reserve Bank a…            -0.5             16.8
#>  3 1990-04-04 Bernie Fraser The Reserve Bank p…            -1.25            15.2
#>  4 1990-08-02 Bernie Fraser The Reserve Bank w…            -1               14  
#>  5 1990-10-15 Bernie Fraser The Reserve Bank w…            -1               13  
#>  6 1990-12-18 Bernie Fraser Given current and …            -1               12  
#>  7 1991-04-04 Bernie Fraser The Reserve Bank w…            -0.5             11.5
#>  8 1991-05-16 Bernie Fraser The Reserve Bank b…            -1               10.5
#>  9 1991-09-03 Bernie Fraser The Reserve Bank w…            -1                9.5
#> 10 1991-11-06 Bernie Fraser The Reserve Bank w…            -1                8.5
#> # ℹ 223 more rows
```

This returns a tidy tibble containing the full text of each monetary
policy decision since 1990.

``` r
minutes <- read_rba_minutes()

minutes
#> # A tibble: 201 × 5
#>    date       title                       text  cash_rate_change cash_rate_level
#>    <date>     <chr>                       <chr>            <dbl>           <dbl>
#>  1 2006-10-03 Minutes of the Monetary Po… Minu…             0               6   
#>  2 2006-11-07 Minutes of the Monetary Po… Minu…             0.25            6.25
#>  3 2006-12-05 Minutes of the Monetary Po… Minu…             0               6.25
#>  4 2007-02-06 Minutes of the Monetary Po… Minu…             0               6.25
#>  5 2007-03-06 Minutes of the Monetary Po… Minu…             0               6.25
#>  6 2007-04-03 Minutes of the Monetary Po… Minu…             0               6.25
#>  7 2007-05-01 Minutes of the Monetary Po… Minu…             0               6.25
#>  8 2007-06-05 Minutes of the Monetary Po… Minu…             0               6.25
#>  9 2007-07-03 Minutes of the Monetary Po… Minu…             0               6.25
#> 10 2007-08-07 Minutes of the Monetary Po… Minu…             0.25            6.5 
#> # ℹ 191 more rows
```

This returns a tidy tibble with the minutes of monetary policy meetings
(first of the RBA Board, now of the RBA Monetary Policy Board) since
2006.

The package contains historical text stored as an internal data object.
The functions, when run, scrape the RBA website for any new
minutes/decisions.

## Example 1: Working with this text data

Here’s an example of how to use the wonderful
[`{tidytext}`](https://www.tidytextmining.com) package to work with this
text data.

First we ‘unnest’ the text statements, counting the number of
occurrences of each word in each year:

``` r
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following object is masked from 'package:testthat':
#> 
#>     matches
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
#> # A tibble: 17,875 × 3
#> # Groups:   year, word [17,875]
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
#> # ℹ 17,865 more rows
```

Then we remove ‘stop words’ (common words like ‘the’ or ‘if’), as well
as removing numbers from the text:

``` r
word_counts <- raw_word_counts %>% 
  anti_join(stop_words,
            by = "word") %>% 
  filter(is.na(suppressWarnings(as.numeric(word))))

word_counts
#> # A tibble: 12,321 × 3
#> # Groups:   year, word [12,321]
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
#> # ℹ 12,311 more rows
```

Then we calculate the [term frequency-inverse document
frequency](https://www.tidytextmining.com/tfidf) of each word for each
year. This is the number of times a word is used in a given year,
adjusted by the number of times the word is used across all years.

``` r

year_tfidfs <- word_counts %>% 
  bind_tf_idf(word, year, n)

year_tfidfs
#> # A tibble: 12,321 × 6
#> # Groups:   year, word [12,321]
#>     year word             n      tf   idf   tf_idf
#>    <dbl> <chr>        <int>   <dbl> <dbl>    <dbl>
#>  1  1990 abating          1 0.00118 1.92  0.00226 
#>  2  1990 acceptable       1 0.00118 3.53  0.00415 
#>  3  1990 account          4 0.00471 0.482 0.00227 
#>  4  1990 accounts         1 0.00118 1.58  0.00186 
#>  5  1990 accumulating     2 0.00235 2.43  0.00571 
#>  6  1990 achieving        1 0.00118 0.818 0.000963
#>  7  1990 acted            1 0.00118 3.53  0.00415 
#>  8  1990 action           4 0.00471 1.13  0.00531 
#>  9  1990 activity         8 0.00941 0.231 0.00217 
#> 10  1990 adjustment       2 0.00235 0.818 0.00193 
#> # ℹ 12,311 more rows
```

Now we have this measure of which words best characterise the statements
issued in a given year. Let’s create a table showing the top 3 words for
each year, ranked by tf-idf:

``` r
year_tfidfs %>% 
  group_by(year) %>% 
  mutate(rank = rank(desc(tf_idf),
                     ties.method = "first")) %>% 
  filter(rank <= 5) %>% 
  arrange(rank) %>% 
  group_by(year) %>% 
  summarise(top_words = paste(word, collapse = ", ")) %>% 
  knitr::kable()
```

| year | top_words                                                      |
|-----:|:---------------------------------------------------------------|
| 1990 | imports, reduction, percentage, reserve, excessive             |
| 1991 | percentage, competitiveness, reserve, tender, reduction        |
| 1992 | overnight, reserve, encouragement, government’s, security      |
| 1993 | foreign, overnight, position, flow, reserve                    |
| 1994 | weight, loans, loan, apply, valuation                          |
| 1996 | salary, objective, enterprise, awote, negotiations             |
| 1997 | day, earnings, figures, settlements, consideration             |
| 1998 | assumption, adoption, agreement, evaluating, predicted         |
| 1999 | designed, expansionary, chance, exclude, offers                |
| 2000 | oil, buoyant, benign, direct, distorted                        |
| 2001 | transitional, corporate, weakened, dampen, weaker              |
| 2002 | firmer, house, imbalances, upturn, east                        |
| 2003 | farm, tradeables, climate, upwards, expansionary               |
| 2005 | constitute, deficiency, fourteenth, signalling, unacceptable   |
| 2006 | background, accelerating, compression, fourth, successive      |
| 2007 | communication, wholesale, pose, consideration, sound           |
| 2008 | evaluate, opposing, opposite, spend, tougher                   |
| 2009 | companies, access, leverage, durable, train                    |
| 2010 | caution, degree, loan, diminishing, america                    |
| 2011 | related, production, resources, confined, rebuilding           |
| 2012 | rated, corporations, europe, carbon, europe’s                  |
| 2013 | sensitive, bit, adjusts, values, exceptionally                 |
| 2014 | appropriately, configured, safe, instruments, consistently     |
| 2015 | arise, commercial, varied, key, remarkably                     |
| 2016 | remarkably, complicate, purposes, appreciating, supervisory    |
| 2017 | mining, boom, transition, debt, apartments                     |
| 2018 | nationwide, gradual, bit, trade, skills                        |
| 2019 | disposable, times, scenario, disputes, downside                |
| 2020 | coronavirus, yield, facility, billion, virus                   |
| 2021 | billion, yield, bond, program, facility                        |
| 2022 | pandemic, incoming, job, ukraine, war                          |
| 2023 | savings, timeframe, costly, entrenched, painful                |
| 2024 | midpoint, sustainably, returning, smp, timeframe               |
| 2025 | sustainably, uncertainties, midpoint, returning, alternatively |

## The small print

\*Prior to December 2007, a media release was only issued if the Board
decided to adjust monetary policy. Since that time, statements have been
issued after each meeting, regardless of the outcome.

Note that this package has an ‘experimental’ badge. The package works
and is stable. However, changes to the format or structure of the RBA
website would break the package’s key function. For this reason, the
function is somewhat ‘brittle’. I do not intend to submit this package
to CRAN. I may at some point merge this package with
[readrba](https://github.com/MattCowgill/readrba).
