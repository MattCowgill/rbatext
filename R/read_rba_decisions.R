#' Scrape RBA monetary policy decision media releases in a tidy tibble
#' @param use_existing If `TRUE` (the default), pre-scraped data, stored as
#' the object `rba_decisions`, will be used in the returned object, and only
#' newer decisions scraped from the RBA. If `FALSE`, all decisions will be
#' scraped fresh.
#' @author Matt Cowgill
#' @examples
#' \dontrun{
#' # Scrape all monetary policy decisions from the RBA website
#' all_decisions <- read_rba_decisions()
#' }
#' @import rvest
#' @export

read_rba_decisions <- function(refresh = TRUE) {
  past_scrape <- rba_decisions

  if (isFALSE(refresh)) {
    return(past_scrape)
  }

  new_scrape <- scrape_decisions(min_year = lubridate::year(max(past_scrape$date)))
  ret <- dplyr::bind_rows(past_scrape, new_scrape) %>%
    dplyr::distinct()
  return(ret)
}

scrape_decisions <- function(min_year = NULL) {
  monpol_page <- read_html("https://www.rba.gov.au/monetary-policy/")

  monpol_year_url_fragments <- monpol_page %>%
    html_elements("li:nth-child(5) li li a") %>%
    html_attr("href")

  monpol_year_urls <- paste0(
    "https://www.rba.gov.au",
    monpol_year_url_fragments
  )

  if (!is.null(min_year)) {
    years <- gsub(
      "https://www.rba.gov.au/monetary-policy/int-rate-decisions/|/",
      "",
      monpol_year_urls
    ) %>%
      as.numeric()

    monpol_year_urls <- monpol_year_urls[years >= min_year]
  }

  get_page_links <- function(url) {
    date_url_fragments <- read_html(url) %>%
      html_elements(".list-articles a") %>%
      html_attr("href")

    paste0(
      "https://www.rba.gov.au",
      date_url_fragments
    )
  }

  get_text_from_mr <- function(url) {
    page <- url %>%
      read_html()

    raw_text <- page %>%
      html_elements("div.rss-mr-content") %>%
      html_text2()

    if (length(raw_text) == 0) {
      raw_text <- page %>%
        html_elements(".article-data+ div") %>%
        html_text2()
    }

    date <- page %>%
      html_elements("time") %>%
      html_text() %>%
      lubridate::dmy()

    if (length(date) == 0) {
      date <- page %>%
        html_elements("#content > section > div > div.box-article-info.article-data > div:nth-child(2) > span.value") %>%
        html_text() %>%
        lubridate::dmy()
    }

    title <- page %>%
      html_elements("span.rss-mr-title") %>%
      html_text()

    if (date >= as.Date("2006-11-08")) {
      statement_by <- gsub(",.*", "", title)
      author <- gsub("Statement by |Statement By", "", statement_by)
    } else {
      statement_by <- gsub(":.*", "", title)
      author <- gsub("Statement by the Governor, Mr ", "", statement_by)
    }

    text <- gsub("\r|\n", " ", raw_text) %>%
      stringr::str_squish()

    dplyr::tibble(
      date = date,
      author = author,
      text = text
    )
  }

  page_links_list <- purrr::map(monpol_year_urls, get_page_links)
  page_links_long <- unlist(page_links_list)
  page_links <- page_links_long[page_links_long != "https://www.rba.gov.au"]

  monpol_decisions <- purrr::map_dfr(page_links, get_text_from_mr) %>%
    dplyr::arrange(date)

  return(monpol_decisions)
}
