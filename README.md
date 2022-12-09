
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rbatext

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
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
#> # A tibble: 212 × 3
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
#> # … with 202 more rows
```

This returns a tidy tibble containing the full text of each monetary
policy decision since 1990.

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
