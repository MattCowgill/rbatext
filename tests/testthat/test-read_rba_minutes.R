test_that("read_rba_minutes() returns expected output", {
  all_minutes <- read_rba_minutes()

  expect_s3_class(all_minutes, "tbl_df")
  expect_length(all_minutes, 3)
  expect_gt(nrow(all_minutes), 200)
  expect_s3_class(all_minutes$date, "Date")

  mins_from_2022_onwards <- scrape_minutes(2022)
  expect_true(nrow(mins_from_2022_onwards) <
                nrow(all_minutes))
  expect_true(min(lubridate::year(mins_from_2022_onwards$date)) == 2022L)
})
