library(httr)
library(jsonlite)
library(glue)
library(tidyverse)


# prepare data ------------------------------------------------------------
url <- function (dt_start, dt_end) {
  glue("https://manage.grabtaxi.com/api/hub/v1/me/bookings?pickUpTimeStart={dt_start}T00%3A00%3A00%2B07%3A00&pickUpTimeEnd={dt_end}T23%3A59%3A59%2B07%3A00&perPage=300")
}

auth_code <- "xxx"

df <- GET(url("2015-01-01", "2018-09-08"), add_headers(Authorization = auth_code))
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
  select(-c(favouriteLocationInfo, reallocationInfo, driverArrived, rewards))

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
)


