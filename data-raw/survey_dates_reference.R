library(dplyr)
library(tidyr)
library(stringr)
library(readxl)
library(readr)

# the goal of creating this table is to have a reference of when surveys were conducted
# Feather redd team provided a table with date references for each year's survey week. We have debrief that into "survey_week_date_reference_2014_2023.csv"
survey_dates <- read.csv("data-raw/qc-processing-files/survey_wk/survey_week_date_reference_2014_2023.csv")  |> 
  mutate(survey_week = as.numeric(survey_wk),
         start_date = as.Date(start_date, format = "%m/%d/%Y"), 
         end_date = as.Date(end_date, format = "%m/%d/%Y"))|> 
  select(-survey_wk) |> 
  filter(!is.na(survey_week)) |>  # Removing rows where survey_week is something other than a number (HF, HFWk1) since not explained on documentation
  glimpse()

# feather redd data team also provided documentation of a yearly description for which survey week was each site surveyed "General Chinook Salmon Redd Survey Methods with Yearly Summaries"
# survey_week_site_reference_2014_2023.csv was manually created as a translation of that document
survey_sites <- read.csv("data-raw/qc-processing-files/survey_wk/survey_week_site_reference_2014_2023.csv") 
survey_sites <- survey_sites |> 
  select(2, 3, 6, 8) |> 
  glimpse()


survey_sites_clean <- survey_sites |> 
  mutate(survey_week = str_replace_all(as.character(survey_week), "\\s?&\\s?", " & ")) |> 
  mutate(survey_week = strsplit(survey_week, " & ")) |>  
  unnest(survey_week) |>  
  mutate(survey_week = as.numeric(survey_week)) |> 
  # for 2023, since survey weeks are 10 but survey week goes from 1-9 and then 11, will modify 10 to match 11
  mutate(survey_week = 
           case_when(
             year == "2023" & survey_week == 10 ~ 11, 
             TRUE ~ survey_week))

# join with survey_dates to get start and end dates
survey_combined <- survey_sites_clean |> 
  left_join(survey_dates, by = c("year", "survey_week"))

surveyed_sites <- survey_combined |>  # 2023 tailerpark pending
  mutate(start_date  = as.Date(start_date),
         end_date = as.Date(end_date)) |> 
  select(year, location, surveyed, start_date, end_date) |> # keeping just fields of interest
  glimpse()
  
  
# Save the cleaned dataset
write_csv(surveyed_sites, "data/surveyed_sites_table.csv")  
