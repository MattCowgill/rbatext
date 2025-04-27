devtools::load_all()

# rba_decisions <- scrape_decisions()
rba_decisions <- read_rba_decisions(refresh = TRUE)
# rba_minutes <- scrape_minutes()
rba_minutes <- read_rba_minutes(refresh = TRUE)

usethis::use_data(rba_decisions, rba_minutes, internal = TRUE, overwrite = TRUE)
