# prepare data ------------------------------------------------------------
data_list <- list.files(data) %>%
  data.frame(file = .) %>%
  mutate(path = glue::glue("{data}/{file}"),
         date = str_extract(file, "[0-9]{8}") %>%
           ymd())
df_raw <- data_list %>%
  top_n(1, date) %>%
  .$path %>%
  read.csv(stringsAsFactors = FALSE)


# clean data --------------------------------------------------------------
df <- df_raw %>%
  mutate(ts = gsub("\\+07:00", "", timestamp) %>%
           ymd_hms(tz = "Asia/Jakarta"),
         dt = as.Date(timestamp)) %>%
  select(ts, dt,
         cat1:cat3,
         value = number,
         detail = note,
         latitude, longitude, accuracy) %>%
  mutate(load_ts = NA_character_,
         load_dt = NA_character_,
         load_ts = as.POSIXct(load_ts),
         load_dt = as.Date(load_dt))
