#' Scrape minutes of RBA Board/Monetary Policy Board in a tidy tibble
#' @param refresh If `TRUE` (the default), the RBA website will be scraped for
#' any minutes that are not included in the package's internal data. If
#' `FALSE`, only the, pre-scraped data will be returned.
#' @author Matt Cowgill
#' @examples
#' \dontrun{
#' # Scrape all monetary policy minutes from the RBA website
#' all_decisions <- read_rba_minutes()
#' }
#' @import rvest
#' @export

read_rba_minutes <- function(refresh = TRUE) {
  past_scrape <- rba_minutes

  if (isFALSE(refresh)) {
    return(past_scrape)
  }

  new_scrape <- scrape_minutes(min_year = lubridate::year(max(past_scrape$date)))
  ret <- dplyr::bind_rows(past_scrape, new_scrape) %>%
    dplyr::distinct()
  return(ret)
}

scrape_minutes <- function(min_year = NULL) {
  monpol_page <- read_html("https://www.rba.gov.au/monetary-policy/")

  monpol_year_url_fragments <- monpol_page %>%
    html_elements("li:nth-child(5) li li a") %>%
    html_attr("href")

  monpol_year_urls <- paste0(
    "https://www.rba.gov.au",
    monpol_year_url_fragments
  )

  if (!is.null(min_year)) {
    years <- stringr::str_sub(
      monpol_year_urls,
      -5, -2
    )%>%
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

  get_text_from_mins <- function(url) {
    page <- url %>%
      read_html()

    raw_text <- page %>%
      html_elements("#content") %>%
      html_text2()

    if (length(raw_text) == 0) {
      raw_text <- page %>%
        html_elements(".article-data+ div") %>%
        html_text2()
    }

    date <- url %>%
      stringr::str_extract("\\d{4}-\\d{2}-\\d{2}") %>%
      lubridate::ymd()


    title <- page %>%
      html_elements(".page-title") %>%
      html_text()

    text <- gsub("\r|\n", " ", raw_text) %>%
      stringr::str_squish() %>%
      stringr::str_replace_all("\\u0092", "'")

    if (is.na(date)) {
      date <- text %>%
        stringr::str_extract("\\d{1,2} \\w+ \\d{4}") %>%
        lubridate::dmy()
    }

    dplyr::tibble(
      date = date,
      title = title,
      # author = author,
      text = text
    )
  }

  page_links_list <- purrr::map(monpol_year_urls, get_page_links)
  page_links_long <- unlist(page_links_list)
  page_links <- page_links_long[page_links_long != "https://www.rba.gov.au"]

  monpol_decisions <- purrr::map_dfr(page_links, get_text_from_mins,
                                     .progress = "Scraping RBA minutes") %>%
    dplyr::arrange(date)

  return(monpol_decisions)
}
