## this script will monitor finhack participant
library(tidyverse)
library(jsonlite)
library(httr)
library(mrsq)

# live tracker
df_all <- fromJSON("res.json")
df_fraud_ss <- data.frame(score = df_all$data$participant$`fraud-detection`$score, cat = "fraud")
df_atm_ss <- data.frame(score = df_all$data$participant$`atm-cash-optimization`$score, cat = "atm")
df_credit_ss <- data.frame(score = df_all$data$participant$`credit-scoring`$score, cat = "credit")
df_final <- rbind(df_fraud_ss, df_credit_ss, df_atm_ss)
df_final %>%
  group_by(cat) %>%
  arrange(desc(score)) %>%
  filter(row_number() <= 5) %>%
  summarise(max_score = max(score),
            min_score = min(score)) %>%
  ungroup() %>%
  mutate(diff = scales::percent(max_score - min_score),
         max_score = scales::percent(max_score),
         min_score = scales::percent(min_score) ) %>%
  left_join(df_final %>%
              group_by(cat) %>%
              summarise(submission_cnt = n(),
                        unscored_cnt = sum(ifelse(score == 0, 1, 0), na.rm = TRUE),
                        unscored_pct = scales::percent(unscored_cnt / submission_cnt) )) %>%
  rojek::go_kable()
df_final %>%
  write_rds(glue::glue("finhack_submission_{format(Sys.time(), '%Y%m%d%H%M%S')}.rds"))
