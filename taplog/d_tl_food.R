# four tables
# -> raw_food
# -> food_transaction
# -> food_mate
# -> food_meal


# transform data ----------------------------------------------------------
df_food_raw <- df %>%
  filter(cat1 == "Food") %>%
  select(-c(load_ts, load_dt))

food_id_max <- tryCatch(pq_query("select max(food_id) from log_foodid"), 
                        error = function(e) 0) %>%
  as.numeric()

df_food_raw <- df_food_raw %>%
  mutate(food = stringr::str_extract(detail, "(?<=F(:|;)).*") %>%
           trimws("both"),
         location = stringr::str_extract(detail, "(?<=L(:|;)).*") %>%
           trimws("both"),
         companion = stringr::str_extract(detail, "(?<=W(:|;)).*") %>%
           trimws("both") %>%
           # stringr::str_replace_all("\\*", "") %>%
           stringr::str_replace_all("Batik", "Alam, Bella, Cam, Hardi, Jamar, Olivia, Tohir") %>%
           stringr::str_replace_all("Mira,", "Miranti,") %>%
           stringr::str_replace_all("Herry,", "Hery,"),
         companion = ifelse(grepl("Nur ", detail), stringr::str_replace_all(detail, "Luqman", "Luqman A"), 
                         companion),
         event = stringr::str_extract(detail, "(?<=E(:|;)).*") %>%
           trimws("both"),
         food = ifelse(cat3 != "" & !(cat3 %in% c("Breakfast", "Dinner")),
                       cat3, food),
         food = ifelse(!grepl("^F:", detail) & detail != "", detail, food))


# location fixing ---------------------------------------------------------
df_food_raw <- df_food_raw %>%
  mutate(location = case_when(location == "A&W" ~ "A&W, Bandara Soetta",
                              location == "Food Fighter" ~ "Food Fighter, Blok M",
                              location == "Bubur Ayam KBA" ~ "KBA atas kiri",
                              location == "Daerah kost Blok A" ~ "KBA atas kanan",
                              location == "Dekat KBA" ~ "KBA atas tengah",
                              location == "Gokana, Platinum" ~ "Gokana, Pasaraya Blok M",
                              location == "Kantin Lt 2" ~ "Kantin Lt 6",
                              location == "KBA (ke kanan)" ~ "KBA bawah kanan",
                              location == "KBA Tengah" ~ "KBA atas tengah",
                              location == "KBA" & food == "Nasi, Ayam Goreng" ~ "KBA bawah kanan",
                              location == "KBA" & grepl("Ayam Goreng", food) ~ "KBA atas kanan",
                              location == "KFC Cikini" ~ "KFC, Cikini",
                              location == "Platinum, Pasaraya Blok M" ~ "Gokana, Pasaraya Blok M",
                              location == "Nasi Padang, Pujasera" ~ "Pujasera, Blok M",
                              grepl("Pujasera Blok M", location) ~ "Pujasera, Blok M",
                              location == "Raa Cha" ~ "Raa Cha, Pasaraya Blok M",
                              location == "Warteg dekat KBA" ~ "KBA atas kiri",
                              location == "Warteg dekat KBA kanan" ~ "KBA atas kanan",
                              cat3 == "Nasi, Rendang (KBA)" ~ "Nasi Padang dekat KBA",
                              cat3 == "Bubur Ayam (KBA)" ~ "KBA atas kiri",
                              cat3 %in% c("2 Telur Pedas, 2 Gorengan",
                                          "2 Telur Pedas, Gorengan",
                                          "2 Telur Semur",
                                          "2 Telur Semur, Gorengan",
                                          "Lontong Sayur, Tahu",
                                          "Nasi Uduk, Telur Ceplok",
                                          "Nasi Uduk, Telur Pedas",
                                          "Nasi Uduk, Telur Pedas, Gorengan",
                                          "Telur Semur, 2 Tahu") ~ "Nasi Uduk dekat kos",
                              cat3 == "Ayam Geprek Bensu" ~ "I am Geprek Bensu, KBA",
                              # grepl("Ketoprak", cat3) ~ "Ketoprak dekat kos",
                              cat3 %in% c("Kwetiau KBA", "Nasi Goreng KBA") ~ "Nasi Goreng dekat KBA",
                              cat3 == "Mi Goreng" ~ "Mi Goreng dekat kos",
                              cat3 %in% c("Nasi, Ayam Bakar", "Nasi, Lele") ~ "Kos Bu Hj. Atun",
                              cat3 %in% c("Ayam Goreng", "Nasi, Ayam Goreng") ~ "Matahari",
                              location == "Nasi Goreng KBA" ~ "Nasi Goreng dekat KBA",
                              cat3 == "Nasi, Rendang (KBA)" ~ "Nasi Padang dekat KBA",
                              location == "Bandara Kuala Lunpur" ~ "Bandara Kuala Lumpur",
                              TRUE ~ location))


# food fixing -------------------------------------------------------------
df_food_raw <- df_food_raw %>%
  mutate(food = case_when(grepl("Bandara Kuala Lunpur", food) ~ "Many things",
                          grepl(" \\(.*\\)", food) ~ gsub(" \\(.*\\)", "", food),
                          grepl(" KBA", food) ~ gsub(" KBA", "", food),
                          TRUE ~ food)) %>%
  arrange(ts) %>%
  mutate(food_id = row_number(),
         food_id = food_id + food_id_max,
         food_id = as.integer(food_id))



# trx table ---------------------------------------------------------------
df_food <- df_food_raw %>%
  select(dt, ts, food_id, type = cat2, 
         food, location, price = value, companion, event,
         longitude, latitude, accuracy)


# food mate table ---------------------------------------------------------
df_food_mate <- df_food %>%
  select(dt, ts, food_id, companion) %>%
  mutate(companion = stringr::str_replace_all(companion, "Family", "Father, Mother, Brother, Sister")) %>%
  mutate(companion = map(strsplit(companion, ","), trimws)) %>%
  unnest() %>%
  filter(!grepl("F(.*)", companion)) %>%
  mutate(is_partial = ifelse(grepl("\\*", companion), TRUE, FALSE),
         companion = stringr::str_replace_all(companion, "\\*", ""))


# food meal table ---------------------------------------------------------
df_food_meal <- df_food %>%
  select(dt, ts, food_id, food) %>%
  mutate(food = map(strsplit(food, ","), trimws)) %>%
  unnest() %>%
  mutate(quantity = stringr::str_extract(food, "^[0-9]"),
         quantity = ifelse(is.na(quantity), 1, quantity),
         quantity = as.integer(quantity),
         food = stringr::str_replace_all(food, "^[0-9]", "") %>%
           trimws)






