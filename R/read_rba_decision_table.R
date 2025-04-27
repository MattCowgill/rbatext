#' Read a table of RBA monetary policy decisions
#' https://www.rba.gov.au/statistics/cash-rate/
#' @keywords internal

read_rba_decision_table <- function() {
  url <- "https://www.rba.gov.au/statistics/cash-rate/"

  page <- url %>%
    read_html()

  raw_table <- page %>%
    html_elements("#datatable") %>%
    html_table() %>%
    purrr::pluck(1)

  # Take a range like "-0.50 to -1.00" and return "-0.75"
  midpoint_if_range <- function(x) {
    numbers <- stringr::str_extract_all(x, "-?\\d+\\.\\d+")[[1]]
    if (length(numbers) == 2) {
      mean(as.numeric(numbers))
    } else if (length(numbers) == 1) {
      as.numeric(numbers)
    } else {
      NA_real_
    }
  }

  raw_table %>%
    dplyr::select("date" = 1,
                  "cash_rate_change" = 2,
                  "cash_rate_level" = 3) %>%
    dplyr::filter(!stringr::str_detect(date,
                              "Legend|Cash rate")) %>%
    dplyr::mutate(dplyr::across(dplyr::starts_with("cash_rate"),
                         \(x) purrr::map_dbl(x, midpoint_if_range))) %>%
    dplyr::mutate(date = lubridate::dmy(date))
}
