library(dplyr)
library(tidyr)
library(stringr)
library(readxl)
library(readr)

survey_dates <- read.csv("data-raw/qc-processing-files/survey_wk/survey_week_date_reference_dates.csv")  |> 
    mutate(survey_week = as.numeric(survey_week))

survey_sites <- read.csv("data-raw/qc-processing-files/survey_wk/survey_week_date_reference_sites.csv") 
survey_sites <- survey_sites |> 
  select(1:7)

survey_sites_clean <- survey_sites |> 
  mutate(survey_week = strsplit(as.character(survey_week), " & ")) |> 
  unnest(survey_week) |> 
  mutate(survey_week = as.numeric(survey_week)) 

# join with survey_dates to get start and end dates
survey_combined <- survey_sites_clean %>%
  left_join(survey_dates, by = c("year", "survey_week"))

# convert survey weeks into separate columns for start and end dates
survey_wide <- survey_combined |> 
  pivot_wider(names_from = survey_week,
              values_from = c(start_date, end_date),
              names_prefix = "survey_wk_")

# select columns of interest
survey_summary <- survey_wide |> 
  select(year, location, surveyed, 
         start_date_survey_wk_1, end_date_survey_wk_1,
         start_date_survey_wk_2, end_date_survey_wk_2,
         start_date_survey_wk_3, end_date_survey_wk_3,
         start_date_survey_wk_4, end_date_survey_wk_4,
         start_date_survey_wk_5, end_date_survey_wk_5,
         start_date_survey_wk_6, end_date_survey_wk_6,
         start_date_survey_wk_7, end_date_survey_wk_7,
         start_date_survey_wk_8, end_date_survey_wk_8) |> 
  rename_with(~ str_replace(., "survey_wk_", "survey_"), starts_with("start_date_survey_wk_")) |> 
  rename_with(~ str_replace(., "survey_wk_", "survey_"), starts_with("end_date_survey_wk_")) |> 
  mutate(across(starts_with("start_date_survey_"), 
                ~ case_when(is.na(.) | . == "NULL" ~ "Not Surveyed", TRUE ~ as.character(.)))) |> 
  mutate(across(starts_with("end_date_survey_"), 
                ~ case_when(is.na(.) | . == "NULL" ~ "Not Surveyed", TRUE ~ as.character(.)))) |> 
  glimpse()

# Save the cleaned dataset
write_csv(survey_summary, "data/test_survey_table.csv")  

