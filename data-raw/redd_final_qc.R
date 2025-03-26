library(dplyr)
library(tidyr)
library(stringr)
library(readxl)
library(readr)
library(lubridate)

# The goal of this script:
# (1) Adding data entries for those dates when surveys were conducted but no data was collected due to redds not being observed
# (2) Creating a reference table of when surveys were conducted.


### Creating reference table ----
# Feather redd team provided a table with date references for each year's survey week. We have debrief that into "survey_week_date_reference_2014_2023.csv"
# for the survey weeks that do not correspond to a number, I am assigning a numeric value, for the sake of code simplicity

survey_dates_raw <- read.csv("data-raw/qc-processing-files/survey_wk/survey_week_date_reference.csv")  

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

## CODE FOR UPDATE ----
# Save the dataset
# write_csv(survey_dates, "data-raw/edi-update-files/survey_week_date_reference.csv")


# feather redd data team also provided documentation of a yearly description for which survey week was each site surveyed "General Chinook Salmon Redd Survey Methods with Yearly Summaries"
# survey_week_site_reference_2014_2023.csv was manually created as a translation of that document
survey_sites <- read.csv("data-raw/qc-processing-files/survey_wk/surveyed_sites_per_sv_week_summary.csv") 
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

## CODE FOR UPDATE ----
# Save the dataset
# write_csv(survey_sites_clean, "data-raw/edi-update-files/surveyed_sites_per_sv_week_summary.csv")


# join with survey_dates to get start and end dates
survey_combined <- survey_sites_clean |> 
  left_join(survey_dates, by = c("year", "survey_week"))

surveyed_sites <- survey_combined |>  
  mutate(start_date  = as.Date(start_date),
         end_date = as.Date(end_date)) |> 
  select(year, location, surveyed, start_date, end_date) |> # keeping just fields of interest
  glimpse()
  
  
# Save the cleaned dataset
write_csv(surveyed_sites, "data/surveyed_sites_table.csv")  


### Adding zeros to data ----

# The goal below is to add redd data entries with a redd count of 0 for when surveys were preformed but no redds were observed
# reading feather redd data (with survey week)

redd_data <- read.csv("data-raw/qc-processing-files/survey_wk/redd_observations_survey_wk_clean.csv") |> 
  mutate(date = as.Date(date)) |> 
  glimpse()

glimpse(survey_sites_clean)

## CODE FOR UPDATE ----
# Save the dataset
# write.xlsx(redd_data, "data-raw/edi-update-files/redd_data_for_binding_update.xlsx")

# todo identify those locations/dates when survey_sites_clean surveyed == TRUE, but redd_data has no records
surveyed_sites_summary <- survey_combined |> 
  filter(surveyed == "TRUE") |> 
  glimpse()

yes_redd_data <- redd_data |> 
  mutate(survey_week = as.numeric(survey_wk),
         year = year(date)) |> 
  select(date, survey_week, location, year) |> 
  glimpse()

no_redd_data <- surveyed_sites_summary |> 
  left_join(yes_redd_data, by = c("survey_week", "location", "year")) |> 
  filter(is.na(date)) |> # adding this to filter out when there are no redd data/dates associated with that survey_wk/location/year
  glimpse()

#checks to see if join shows what it isn't on data
yes_redd_data |> 
  filter(year == "2014", location == "belowbigholeeast") |> 
  View()
yes_redd_data |> 
  filter(year == "2015", location == "developing") |> 
   View()

# adding those records on to redd data 
zeros_added <- no_redd_data |> 
  mutate(number_redds = 0,
         date = start_date) |> # assigning start_date instead of the exact date
  rename(survey_wk = survey_week) |> 
  select(-c(start_date, end_date, surveyed, year)) |> 
  glimpse()

redd_data_updated <- redd_data |> 
  bind_rows(zeros_added) |> 
  select(-survey_wk) |> # remove survey_week
  glimpse()

# save redd data with zeros added
write_csv(redd_data_updated, "data/redd_observation_w_zeros.csv")
