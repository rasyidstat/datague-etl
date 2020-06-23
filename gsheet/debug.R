# after august after 108 -> e2
h <- df$content[45]
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
e
e2

e[21]
e[23]
e2[19]
e2[22]
