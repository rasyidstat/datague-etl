# transform data ----------------------------------------------------------
df_trans_raw <- df %>%
  filter(grepl("Transjakarta", cat2)) %>%
  select(ts:cat3, detail)

trip_id_max <- tryCatch(pq_query("select max(trip_id) from log_tripid"), 
                        error = function(e) 0) %>%
  as.numeric()

df_trans_raw <- df_trans_raw %>%
  arrange(ts) %>%
  group_by(dt) %>%
  mutate(ts_lag = lag(ts),
         cat2_lag = lag(cat2),
         cat3_lag = lag(cat3),
         ts_lag2 = lag(ts, 2),
         cat2_lag2 = lag(cat2, 2),
         cat3_lag2 = lag(cat3, 2),
         diff = difftime(ts, ts_lag, units = "mins"),
         groupid = case_when(diff >= 180 ~ 1,
                             diff >= 70 & cat2 == cat2_lag ~ 1,
                             TRUE ~ 0),
         groupid = cumsum(groupid),
         status = case_when(cat2 == "Transjakarta Tap" & cat2_lag == "Transjakarta" ~ "Waiting",
                            cat2 == "Transjakarta" & cat2_lag == "Transjakarta Tap" ~ "On Trip")) %>%
  ungroup() %>%
  mutate(trip_id = group_indices(., dt, groupid),
         trip_id = trip_id + trip_id_max,
         trip_id = as.integer(trip_id),
         diff = as.numeric(diff))

# trip
df_trans_trip <- df_trans_raw %>%
  filter(status == "On Trip") %>%
  select(dt, trip_id,
         start_halte = cat3_lag2, end_halte = cat3,
         start_time = ts_lag2, departure_time = ts_lag, arrival_time = ts) %>%
  mutate(waiting_duration = difftime(departure_time, start_time, units = "mins"),
         trip_duration = difftime(arrival_time, departure_time, units = "mins"),
         total_duration = difftime(arrival_time, start_time, units = "mins")) %>%
  mutate_at(vars(contains("_duration")), funs(as.numeric))

# daily sumary
df_trans <- df_trans_raw %>%
  group_by(dt, trip_id, groupid) %>%
  mutate(r = row_number()) %>%
  summarise(start_halte = max(case_when(r == min(r) ~ cat3), na.rm = TRUE),
            end_halte = max(case_when(r == max(r) ~ cat3), na.rm = TRUE),
            transit_halte = paste(case_when(r != min(r) & 
                                              r != max(r) & 
                                              cat2 != "Transjakarta Tap" ~ cat3) %>%
                                    na.omit(),
                                  collapse = ", "),
            transit_halte = ifelse(transit_halte == "", NA_character_, transit_halte),
            transit_cnt = sum(case_when(r != min(r) & 
                                          r != max(r) & 
                                          cat2 != "Transjakarta Tap" ~ 1,
                                        TRUE ~ 0)) %>%
              as.integer(),
            start_time = max(case_when(r == min(r) ~ ts), na.rm = TRUE),
            departure_time = max(case_when(r == 2 ~ ts), na.rm = TRUE),
            arrival_time = max(case_when(r == max(r) ~ ts), na.rm = TRUE),
            waiting_duration = sum(case_when(status == "Waiting" ~ diff,
                                             TRUE ~ 0)),
            trip_duration = sum(case_when(status == "On Trip" ~ diff,
                                          TRUE ~ 0)),
            total_duration = sum(case_when(!is.na(status) ~ diff,
                                           TRUE ~ 0)),
            detail = max(case_when(detail == "" ~ NA_character_,
                                   TRUE ~ detail), na.rm = TRUE)) %>%
  select(-groupid)

df_trans <- df_trans %>%
  mutate(waiting_duration = as.numeric(waiting_duration),
         trip_duration = as.numeric(trip_duration),
         total_duration = as.numeric(total_duration))



