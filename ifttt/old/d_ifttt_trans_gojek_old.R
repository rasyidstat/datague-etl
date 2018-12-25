# read data from excel
df <- read_excel(input, sheet = "gojek")

# change time format
year(df$time) <- year(df$taptime) <- year(df$date)

# clean 'em all
df <- df %>%
  filter(type != "GO-FOOD") %>%
  mutate(duration = as.numeric(60*(taptime - time)),
         date = as.Date(date),
         discount = NA_real_,
         driver = NA_character_,
         driver_url = NA_character_) %>%
  select(dt = date,
         service_type = type,
         order_id = id,
         from, to,
         departure_time = time,
         arrival_time = taptime,
         distance, duration, 
         price, discount,
         driver, driver_url)
