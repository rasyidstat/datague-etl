## this script will monitor finhack leaderboard
library(tidyverse)
library(jsonlite)
library(httr)
library(mrsq)

ts <- Sys.time()
df_atm <- fromJSON("https://finhacks.id/arachne/participant/atm-cash-optimization")$data
df_fraud <- fromJSON("https://finhacks.id/arachne/participant/fraud-detection")$data
df_credit <- fromJSON("https://finhacks.id/arachne/participant/credit-scoring")$data

# combine them all
df <- bind_rows(
  mutate(df_atm, cat = "atm", ts),
  mutate(df_fraud, cat = "fraud", ts),
  mutate(df_credit, cat = "credit", ts)
) %>%
  select(id, team_name = teamName, cat, score, submission_status = submissionStatus, ts)

# push to postgres (hist table)
pq_write(df, "finhack_lb_hist")
