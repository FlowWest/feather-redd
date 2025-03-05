library(dplyr)
library(tidyr)
library(stringr)
library(readxl)
library(readr)

# the goal of creating this table is to have a reference of when surveys were conducted
# Feather redd team provided a table with date references for each year's survey week. We have debrief that into "survey_week_date_reference_2014_2023.csv"
# for the survey weeks that do not correspond to a number, I am assigning a numeric value, for the sake of code simplicity

survey_dates_raw <- read.csv("data-raw/qc-processing-files/survey_wk/survey_week_date_reference_2014_2023.csv")  

# filtering out non-numeric survey weeks
survey_dates <- survey_dates_raw |> 
  mutate(survey_wk = case_when(
    survey_wk == "HF" & year == "2014" ~ "10",
    survey_wk == "HF2" & year == "2014" ~ "11",
    survey_wk == "HFWk1" & year == "2015" ~ "14",
    survey_wk == "High Flow 1-1" & year == "2017" ~ "12", 
    # survey_wk == "Low Flow 1-1" & year == "2017" ~ "13", # keeping code but date already corresponds to another sv_wk
    TRUE ~ survey_wk  
  )) |> 
  mutate(survey_week = as.numeric(survey_wk),
         start_date = as.Date(start_date, format = "%m/%d/%Y"),
         end_date = as.Date(end_date, format = "%m/%d/%Y"))|>
  select(-survey_wk) |>
  filter(!is.na(survey_week)) |>  # Removing Low Flow 1 -1
  glimpse()

# feather redd data team also provided documentation of a yearly description for which survey week was each site surveyed "General Chinook Salmon Redd Survey Methods with Yearly Summaries"
# survey_week_site_reference_2014_2023.csv was manually created as a translation of that document
survey_sites <- read.csv("data-raw/qc-processing-files/survey_wk/survey_week_site_reference_2014_2023_0220update.csv") 
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


# The goal below is to add redd data entries with a redd count of 0 for when surveys were preformed but no redds were observed
# reading feather redd data (with survey week)

redd_data <- read.csv("data-raw/qc-processing-files/survey_wk/redd_observations_survey_wk_clean.csv")

glimpse(survey_sites_clean)


# todo identify those locations/dates when survey_sites_clean surveyed == TRUE, but redd_data has no records
surveyed_sites_summary <- survey_combined |> 
  filter(surveyed == "TRUE") |> 
  glimpse()

yes_redd_data <- redd_data |> 
  mutate(survey_week = as.numeric(survey_wk)) |> 
  select(date, survey_week, location, latitude, longitude) |> 
  glimpse()

no_redd_data <- surveyed_sites_summary |> 
  left_join(yes_redd_data, by = c("survey_week", "location")) |> 
  filter(is.na(date)) |> View()
