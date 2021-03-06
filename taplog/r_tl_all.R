library(tidyverse)
library(mrsq)
library(lubridate)
library(stringr)

# config ------------------------------------------------------------------
data <- "~/OneDrive/Magnum Opus/datague/data" # Raw TapLog data location


# get data ----------------------------------------------------------------
source("d_tl_raw.R")


# sync data ---------------------------------------------------------------
if ("raw_taplog" %in% pq_table()) {
  # df_taplog <- pq_query("select * from raw_taplog")
  # df <- anti_join(df, 
  #                 df_taplog,
  #                 by = names(df)[1:(length(names(df))-2)])
  max_ts <- pq_query("select max(ts) mx from raw_taplog")$mx
  # max_ts <- pq_query("select max(ts) mx from raw_taplog where load_dt = '2019-01-30'")$mx
  df <- df %>%
    filter(ts > max_ts + 5)
} else {
  df %>%
    filter(dt == as.Date("1900-10-10")) %>%
    pq_write("raw_taplog")
}


# insert raw --------------------------------------------------------------
# load time variable
load_ts_c = now()
load_dt_c = today()

# execute
if (nrow(df) >= 1) {
  df %>%
    mutate(load_ts = load_ts_c,
           load_dt = load_dt_c) %>%
    pq_write("raw_taplog", append = TRUE, overwrite = FALSE)
  
  # log history
  data.frame(load_ts = load_ts_c,
             load_dt = load_dt_c,
             table = "raw_taplog",
             job = "insert",
             nrow = nrow(df),
             latest_dt = max(df$dt)) %>%
    pq_write("log_history", append = TRUE, overwrite = FALSE)
}


# insert transjakarta -----------------------------------------------------
# transform data
source("d_tl_transport_transjakarta.R")

# execute
if (nrow(df_trans) >= 1) {
  df_trans %>%
    mutate(load_ts = load_ts_c,
           load_dt = load_dt_c) %>%
    pq_write("transport_transjakarta", append = TRUE, overwrite = FALSE)
  
  df_trans_trip %>%
    mutate(load_ts = load_ts_c,
           load_dt = load_dt_c) %>%
    pq_write("transport_transjakarta_trip", append = TRUE, overwrite = FALSE)
  
  df_trans_raw %>%
    mutate(load_ts = load_ts_c,
           load_dt = load_dt_c) %>%
    pq_write("raw_transjakarta", append = TRUE, overwrite = FALSE)
  
  # log history
  data.frame(load_ts = load_ts_c,
             load_dt = load_dt_c,
             table = "transport_transjakarta",
             job = "insert",
             nrow = nrow(df),
             latest_dt = max(df$dt)) %>%
    pq_write("log_history", append = TRUE, overwrite = FALSE)
  
  # max trip_id
  data.frame(load_ts = load_ts_c,
             load_dt = load_dt_c,
             trip_id = max(df_trans$trip_id),
             type = "Transjakarta") %>%
    pq_write("log_tripid", append = TRUE, overwrite = FALSE)
}



# insert krl --------------------------------------------------------------
# transform data
source("d_tl_transport_krl.R")

# execute
if (nrow(df_krl_trip) >= 1) {
  df_krl_trip %>%
    mutate(load_ts = load_ts_c,
           load_dt = load_dt_c) %>%
    pq_write("transport_krl_trip", append = TRUE, overwrite = FALSE)
  
  df_krl_raw %>%
    mutate(load_ts = load_ts_c,
           load_dt = load_dt_c) %>%
    pq_write("raw_krl", append = TRUE, overwrite = FALSE)
  
  # log history
  data.frame(load_ts = load_ts_c,
             load_dt = load_dt_c,
             table = "transport_krl",
             job = "insert",
             nrow = nrow(df),
             latest_dt = max(df$dt)) %>%
    pq_write("log_history", append = TRUE, overwrite = FALSE)
  
  # max trip_id
  data.frame(load_ts = load_ts_c,
             load_dt = load_dt_c,
             trip_id = max(df_krl_trip$trip_id),
             type = "KRL") %>%
    pq_write("log_tripid", append = TRUE, overwrite = FALSE)
}


# insert food -------------------------------------------------------------
# transform data
source("d_tl_food.R")

# checker
df_food_mate %>%
  count(companion, sort = TRUE) %>%
  View()

# execute
if (nrow(df_food) >= 1) {
  df_food %>%
    mutate(load_ts = load_ts_c,
           load_dt = load_dt_c) %>%
    pq_write("food_transaction", append = TRUE, overwrite = FALSE)
  
  df_food_mate %>%
    mutate(load_ts = load_ts_c,
           load_dt = load_dt_c) %>%
    pq_write("food_mate", append = TRUE, overwrite = FALSE)
  
  df_food_meal %>%
    mutate(load_ts = load_ts_c,
           load_dt = load_dt_c) %>%
    pq_write("food_meal", append = TRUE, overwrite = FALSE)
  
  df_food_raw %>%
    mutate(load_ts = load_ts_c,
           load_dt = load_dt_c) %>%
    pq_write("raw_food", append = TRUE, overwrite = FALSE)
  
  # log history
  data.frame(load_ts = load_ts_c,
             load_dt = load_dt_c,
             table = "food",
             job = "insert",
             nrow = nrow(df),
             latest_dt = max(df$dt)) %>%
    pq_write("log_history", append = TRUE, overwrite = FALSE)
  
  # max trip_id
  data.frame(load_ts = load_ts_c,
             load_dt = load_dt_c,
             food_id = max(df_food$food_id)) %>%
    pq_write("log_foodid", append = TRUE, overwrite = FALSE)
}




