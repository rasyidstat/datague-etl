library(googlesheets)
library(stringr)
library(rvest)
library(lubridate)
library(tidyverse)
library(mrsq)

# config ------------------------------------------------------------------
gs <- "~/OneDrive/Magnum Opus/datague/cred/pa_gs"     # Google Sheets credential location
output <- "~/OneDrive/Magnum Opus/datague/data/gojek" # Output folder for data backup
sheet_name <- "GO-JEK Receipt (1)"                        # Name of sheets from the IFTTT
# Note: you can try your own data by modifying the config above
# Create your own IFTTT at https://ifttt.com/applets/282294p-gmail-to-sheets

# get data ----------------------------------------------------------------
source("d_ifttt_trans_gojek.R")


# sync data ---------------------------------------------------------------
if ("transport_gojek" %in% pq_table()) {
  df_gojek <- pq_query("select * from transport_gojek")
  df <- anti_join(df,
                  df_gojek,
                  by = "order_id")
} else {
  df %>%
    filter(dt == as.Date("1900-10-10")) %>%
    pq_write("transport_gojek")
}

# insert data -------------------------------------------------------------
# load time variable
load_ts_c = now()
load_dt_c = today()

# execute
if (nrow(df) >= 1) {
  df %>%
    mutate(load_ts = load_ts_c,
           load_dt = load_dt_c) %>%
    pq_write("transport_gojek", append = TRUE, overwrite = FALSE)

  # log history
  data.frame(load_ts = load_ts_c,
             load_dt = load_dt_c,
             table = "transport_gojek",
             job = "insert",
             nrow = nrow(df),
             latest_dt = max(df$dt)) %>%
    pq_write("log_history", append = TRUE, overwrite = FALSE)
}
