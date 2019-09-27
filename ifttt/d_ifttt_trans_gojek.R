# read data from google sheet
gs_auth(cache = gs)
sheets <- gs_ls()
df <- sheets %>%
  arrange(updated) %>%
  filter(sheet_title == sheet_name) %>%
  select(sheet_title) %>%
  mutate(df = map(sheet_title, gs_title),
         df = map(df, function(x) gs_read(x, col_names=FALSE)),
         df = map(df, function(x) select(x, dt_created=X1, dt_order=X4, content=X5))) %>%
  unnest() %>%
  mutate(dt_created=mdy_hm(dt_created),
         dt_order=dmy(dt_order))
  # filter(dt_order >= pq_query("select max(dt) from transport_gojek"))

# function to change id language to end
id_to_en <- function(x) {
  x <- gsub("Senin", "Monday", x)
  x <- gsub("Selasa", "Tuesday", x)
  x <- gsub("Rabu", "Wednesday", x)
  x <- gsub("Kamis", "Thursday", x)
  x <- gsub("Jum'at|Jumat", "Friday", x)
  x <- gsub("Sabtu", "Saturday", x)
  x <- gsub("Minggu", "Sunday", x)
  x <- gsub("Januari", "January", x)
  x <- gsub("Februari|Pebruari", "February", x)
  x <- gsub("Maret", "March", x)
  x <- gsub("Mei", "May", x)
  x <- gsub("Juni", "June", x)
  x <- gsub("Juli", "July", x)
  x <- gsub("Agustus", "August", x)
  x <- gsub("Desember", "December", x)
  x
}

# function to extract html version 2
clean_gojek <- function(h) {
  output <- list()
  h <- read_html(h)
  a <- h %>%
    html_nodes("p span") %>%
    html_text()
  b <- h %>%
    html_nodes("h2") %>%
    html_text() %>%
    trimws()
  c <- h %>%
    html_nodes("strong") %>%
    html_text()
  d <- h %>%
    html_nodes("td span") %>%
    html_text()
  e <- h %>%
    html_nodes("tr td") %>%
    html_text() %>%
    trimws()
  img <- h %>%
    html_nodes("img") %>%
    html_attr("src") %>%
    subset(grepl("imgix", .))
  output$order_id <- gsub("Nomor Pemesanan: ", "", b[4])
  output$time_dep <- ymd_hm(paste(dmy(id_to_en(b[3])), c[1]))
  output$time_arrive <- ymd_hm(paste(dmy(id_to_en(b[3])), c[2]))
  output$from <- a[1]
  output$to <- a[2]
  output$distance <- as.numeric(str_extract(d[12], "\\d+\\.\\d+"))
  output$duration <- as.numeric(hms(d[13]))
  output$price <- str_extract(gsub("[[:punct:]]", "", e[23]), "\\d+")
  output$discount <- str_extract(gsub("[[:punct:]]", "", e[21]), "\\d+")
  output$driver <- a[3]
  output$driver_url <- if (length(img) > 0) img else NA
  return(output)
}

# apply to the data
df_clean <- df %>%
  filter(!is.na(dt_created)) %>%
  mutate(content_all = map(content, clean_gojek),
         content_all = map(content_all, data.frame),
         service_type = case_when(grepl("go-ride", tolower(content)) ~ "GO-RIDE",
                                  grepl("go-car", tolower(content)) ~ "GO-CAR",
                                  TRUE ~ "Others")) %>%
  unnest() %>%
  select(-content) %>%
  mutate(order_id = gsub("order id: ", "", tolower(order_id)) %>%
           toupper())
df_clean <- df_clean %>%
  mutate(from = gsub(",.*", "", from),
         to = gsub(",.*", "", to),
         price = as.numeric(price),
         discount = as.numeric(discount),
         price = ifelse(is.na(price), 0, price),
         discount = ifelse(is.na(discount), 0, discount))

# write back in local for future use
write_rds(df_clean,
          paste0(output, "/gojek_clean_", gsub("-", "", today()), ".rds"))

# finalize
df <- df_clean %>%
  select(dt = dt_order,
         service_type,
         order_id,
         from, to,
         departure_time = time_dep,
         arrival_time = time_arrive,
         distance:driver_url) %>%
  mutate(load_ts = now(),
         load_dt = today())

# remove duplicate
df <- df %>%
  group_by(order_id) %>%
  mutate(r = row_number()) %>%
  ungroup() %>%
  filter(r == 1) %>%
  select(-r)




