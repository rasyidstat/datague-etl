library(httr)
library(jsonlite)
library(glue)
library(tidyverse)


# prepare data ------------------------------------------------------------
url <- function (dt_start, dt_end) {
  glue("https://manage.grabtaxi.com/api/hub/v1/me/bookings?pickUpTimeStart={dt_start}T00%3A00%3A00%2B07%3A00&pickUpTimeEnd={dt_end}T23%3A59%3A59%2B07%3A00&perPage=300")
}

auth_code <- "xxx"

df <- GET(url("2015-01-01", "2018-12-31"), add_headers(Authorization = auth_code))
# write_rds(df, "d_oth_trans_grab.rds")
df <- read_rds("d_oth_trans_grab.rds")


# clean data --------------------------------------------------------------
df <- fromJSON(content(df, "text"))
df <- df$data
df_col <- df %>%
  select(code:dropOffLongitude)
df_receipt <- df$receipt
df_city <- df$city
df_driver <- df$driver
df_taxi <- df$taxiType
df_user <- df$userGroup
df_meta <- df$metaData
df_meta1 <- df_meta$favouriteLocationInfo
df_meta2 <- df_meta$reallocationInfo
df_meta3 <- df_meta$driverArrived
df_meta4 <- df_meta$rewards
df_meta <- df_meta %>%
  select(flags, fareLowerBounds, fareUpperBounds,
         instantWin, fakeBooking, 
         estimatedPickupTime, estimatedDropoffTime, surge, surcharge, additionalBookingFee,
         promotionText, rewardId, dropOffTime)

df_all <- bind_cols(
  df_col,
  df_receipt,
  df_city,
  df_driver,
  df_taxi,
  df_meta,
  df_meta1,
  df_meta2,
  df_meta3,
  df_meta4
) %>%
  select(-previousBookingCodes)

# sync data ---------------------------------------------------------------
if ("raw_grab" %in% pq_table()) {
  df_raw <- pq_query("select * from raw_grab")
  df_all <- anti_join(df_all, 
                      df_raw,
                      by = "code")
}

# insert to db ------------------------------------------------------------
load_ts_c = now()
load_dt_c = today()

# execute
if (nrow(df_all) >= 1) {
  df_all %>%
    mutate(load_ts = load_ts_c,
           load_dt = load_dt_c) %>%
    pq_write("raw_grab", append = TRUE, overwrite = FALSE)
  
  # log history
  data.frame(load_ts = load_ts_c,
             load_dt = load_dt_c,
             table = "raw_grab",
             job = "insert",
             nrow = nrow(df_all),
             latest_dt = max(as.Date(ymd_hms(df_all$estimatedPickupTime)))) %>%
    pq_write("log_history", append = TRUE, overwrite = FALSE)
}


# super clean -------------------------------------------------------------
df_clean <- df_all
names(df_clean) <- names(df_all) %>%
  gsub("([a-z])([A-Z])", "\\1_\\L\\2", ., perl = TRUE)
df_clean <- df_clean %>%
  mutate(start_time = as.POSIXct(pick_up_time/1000, origin = "1970-01-01"),
         dt = as.Date(start_time),
         end_time = ymd_hms(drop_off_time, tz = "Asia/Jakarta"),
         end_time = ifelse(drop_off_time == "0001-01-01T00:00:00Z", NA, end_time),
         end_time = as.POSIXct(end_time, origin =  "1970-01-01"),
         departure_time_est = ymd_hms(estimated_pickup_time, tz = "Asia/Jakarta"),
         arrival_time_est = ymd_hms(estimated_dropoff_time, tz = "Asia/Jakarta")) %>%
  mutate(departure_time = ifelse(end_time > arrival_time_est, departure_time_est, end_time),
         arrival_time = ifelse(end_time > arrival_time_est, end_time, arrival_time_est),
         departure_time = as.POSIXct(departure_time, origin =  "1970-01-01"),
         arrival_time = as.POSIXct(arrival_time, origin =  "1970-01-01"),
         duration = as.numeric(arrival_time - start_time))
df_clean <- df_clean %>%
  select(dt, 
         service_type = name2,
         order_id = code,
         from_detail = pick_up_address,
         from = pick_up_keywords,
         from_longitude = pick_up_longitude,
         from_latitude = pick_up_latitude,
         to_detail = drop_off_address,
         to = drop_off_keywords,
         to_longitude = drop_off_longitude,
         to_latitude = drop_off_latitude,
         start_time,
         departure_time,
         arrival_time,
         end_time,
         departure_time_est,
         arrival_time_est,
         distance,
         duration,
         price = total_fare,
         discount = promo_discount,
         price_real = meter_fare,
         payment_type,
         currency = currency_symbol,
         surge,
         surcharge,
         driver = name1,
         plate_number,
         service_area_abb = code1,
         service_area = name,
         note = remarks)


# insert to db clean ------------------------------------------------------
if (nrow(df_clean) >= 1) {
  df_clean %>%
    mutate(load_ts = load_ts_c,
           load_dt = load_dt_c) %>%
    pq_write("transport_grab", append = TRUE, overwrite = FALSE)
  
  # log history
  data.frame(load_ts = load_ts_c,
             load_dt = load_dt_c,
             table = "transport_grab",
             job = "insert",
             nrow = nrow(df_all),
             latest_dt = max(as.Date(ymd_hms(df_all$estimatedPickupTime)))) %>%
    pq_write("log_history", append = TRUE, overwrite = FALSE)
}






