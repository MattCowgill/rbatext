## code to prepare `rba_decisions` dataset goes here
devtools::load_all()

rba_decisions <- read_rba_decisions(refresh = TRUE)

usethis::use_data(rba_decisions, overwrite = TRUE)
