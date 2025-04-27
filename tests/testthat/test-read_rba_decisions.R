test_that("read_rba_decisions() returns expected output", {
  all_decisions <- read_rba_decisions()

  expect_s3_class(all_decisions, "tbl_df")
  expect_length(all_decisions, 5)
  expect_gt(nrow(all_decisions), 211)
  expect_s3_class(all_decisions$date, "Date")

  decisions_from_2022_onwards <- scrape_decisions(2022)
  expect_true(nrow(decisions_from_2022_onwards) <
    nrow(all_decisions))
  expect_true(min(lubridate::year(decisions_from_2022_onwards$date)) == 2022L)
})
