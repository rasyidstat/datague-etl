# transform data ----------------------------------------------------------
df_krl_raw <- df %>%
  filter(grepl("KRL", cat2)) %>%
  select(ts:cat3, detail)
# edit data
# write.csv(df_krl_raw, "temp2.csv", row.names = FALSE)
# df_krl_raw <- read.csv("temp2.csv", stringsAsFactors = FALSE) %>%
#   mutate(ts = as.POSIXct(ts),
#          dt = as.Date(dt),
#          detail = "")

trip_id_max <- tryCatch(pq_query("select max(trip_id)
                                 from log_tripid
                                 where type = 'KRL'"),
                        error = function(e) 0) %>%
  as.numeric()

trip_id_max <- ifelse(length(trip_id_max) == 0, 0, trip_id_max)

## filter once clean
# df_krl_raw <- df_krl_raw %>%
#   filter(!row_number() %in% c(42,43)) %>%
#   mutate(cat2 = ifelse(row_number() == 13, "KRL Tap", cat2),
#          cat3 = ifelse(row_number() == 13, "", cat3))

df_krl_raw <- df_krl_raw %>%
  arrange(ts) %>%
  group_by(dt) %>%
  mutate(ts_lag = lag(ts),
         cat2_lag = lag(cat2),
         cat3_lag = lag(cat3),
         ts_lag2 = lag(ts, 2),
         cat2_lag2 = lag(cat2, 2),
         cat3_lag2 = lag(cat3, 2),
         diff = difftime(ts, ts_lag, units = "mins"),
         status = case_when(cat2 == "KRL Tap" & cat2_lag == "KRL" ~ "Waiting",
                            cat3 == "KRL Sit" & cat2_lag == "KRL Tap" ~ "Depart to Sit",
                            cat2 == "KRL" & cat2_lag == "KRL Tap" & cat3_lag != "KRL Sit" ~ "On Trip",
                            cat2 == "KRL" & cat3_lag == "KRL Sit" ~ "On Trip (Sit)"),
         groupid = case_when(diff >= 180 ~ 1,
                             diff >= 30 & cat2 == cat2_lag & cat3_lag != "KRL Sit" ~ 1,
                             TRUE ~ 0),
         groupid = cumsum(groupid)) %>%
  ungroup() %>%
  mutate(trip_id = group_indices(., dt, groupid),
         trip_id = trip_id + trip_id_max,
         trip_id = as.integer(trip_id),
         diff = as.numeric(diff))

# trip
df_krl_trip <- df_krl_raw %>%
  filter(status %in% c("On Trip", "Depart to Sit", "On Trip (Sit)")) %>%
  mutate(start_halte = case_when(status == "On Trip" ~ cat3_lag2,
                                 status == "Depart to Sit" ~ cat3_lag2),
         end_halte = case_when(status == "On Trip" ~ cat3,
                               status == "On Trip (Sit)" ~ cat3),
         start_time = case_when(status == "On Trip" ~ ts_lag2,
                                status == "Depart to Sit" ~ ts_lag2),
         departure_time = case_when(status == "On Trip" ~ ts_lag,
                                    status == "Depart to Sit" ~ ts_lag),
         arrival_time = case_when(status == "On Trip" ~ ts,
                                  status == "On Trip (Sit)" ~ ts),
         sitting_time = case_when(status == "Depart to Sit" ~ ts)) %>%
  group_by(dt, trip_id) %>%
  summarise(start_halte = max(start_halte, na.rm = TRUE),
            end_halte = max(end_halte, na.rm = TRUE),
            start_time = max(start_time, na.rm = TRUE),
            departure_time = max(departure_time, na.rm = TRUE),
            arrival_time = max(arrival_time, na.rm = TRUE),
            sitting_time = max(sitting_time, na.rm = TRUE)) %>%
  mutate(waiting_duration = difftime(departure_time, start_time, units = "mins"),
         trip_duration = difftime(arrival_time, departure_time, units = "mins"),
         waiting_sit_duration = difftime(arrival_time, sitting_time, units = "mins"),
         total_duration = difftime(arrival_time, start_time, units = "mins")) %>%
  mutate_at(vars(contains("_duration")), funs(as.numeric)) %>%
  mutate(waiting_sit_duration = ifelse(is.infinite(waiting_sit_duration),
                                       NA, waiting_sit_duration))

# finalize
df_krl_trip <- df_krl_trip %>%
  mutate(load_ts = now(),
         load_dt = today())

df_krl_raw <- df_krl_raw %>%
  mutate(load_ts = now(),
         load_dt = today())


