#' Scrape RBA monetary policy decision media releases in a tidy tibble
#' @param refresh If `TRUE` (the default), the RBA website will be scraped for
#' any decisions that are not included in the package's internal data. If
#' `FALSE`, only the, pre-scraped data will be returned.
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

  past_scrape <- past_scrape %>%
    dplyr::select(-cash_rate_change, -cash_rate_level)

  new_scrape <- scrape_decisions(min_year = lubridate::year(max(past_scrape$date)))
  decisions <- dplyr::bind_rows(past_scrape, new_scrape) %>%
    dplyr::distinct()

  dec_num <- read_rba_decision_table() %>%
    dplyr::mutate(date = dplyr::if_else(date >= lubridate::ymd("2008-02-05"),
                                        date - 1,
                                        date))

  decisions %>%
    dplyr::left_join(dec_num, by = "date")
}

scrape_decisions <- function(min_year = NULL) {
  monpol_page <- read_html("https://www.rba.gov.au/monetary-policy/")

  monpol_year_url_fragments <- monpol_page %>%
    html_elements("li:nth-child(3) li li a") %>%
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

  get_text_from_mr <- function(url) {
    page <- url %>%
      read_html()

    raw_text <- page %>%
      html_elements(".rss-mr-content h2 , .rss-mr-content p") %>%
      html_text2()

    if (length(raw_text) == 0) {
      raw_text <- page %>%
        html_elements(".article-data+ div") %>%
        html_text2()
    }

    date <- page %>%
      html_elements(".rss-mr-date") %>%
      html_text2() %>%
      lubridate::dmy()

    if (length(date) == 0) {
      date <- page %>%
        html_elements("time") %>%
        html_text2() %>%
        lubridate::dmy()
    }

    if (length(date) == 0) {
      date <- page %>%
        html_elements(".item+ .item .value") %>%
        html_text2() %>%
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

    author <- author %>%
      stringr::str_remove_all(":.*") %>%
      stringr::str_to_title()

    text <- raw_text %>%
      stringr::str_flatten(collapse = " ") %>%
      stringr::str_replace_all("\r|\n", " ") %>%
      stringr::str_replace_all("\\u0092", "'") %>%
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

  monpol_decisions <- purrr::map_dfr(page_links, get_text_from_mr,
                                     .progress = "Reading RBA decisions") %>%
    dplyr::arrange(date)

  return(monpol_decisions)
}
