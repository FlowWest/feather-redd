library(readr)
library(tidyr)
library(readxl)


# reading survey_dates table
survey_dates_reference <- read_csv("data-raw/edi-update-files/survey_week_date_reference.cvs")  

# reading your new data and biding
# survey_dates_reference_updated <- read_csv("data-raw/edi-update-files/yyyy_survey_week_date_reference.cvs") |>
#   bind_rows(survey_dates_reference) |> 
#   glimpse()


# reading survey_sites reference table
survey_sites_reference <- read_csv("data-raw/edi-update-files/surveyed_sites_per_sv_week_summary.csv")

# reading your new data and binding
# survey_sites_reference_updated <-read_csv("data-raw/edi-update-files/yyyy_surveyed_sites_per_sv_week_summary.csv") |>
#   bind_rows(survey_sites_reference) |> 
#   glimpse()



# join with survey_dates to get start and end dates
survey_combined <- survey_sites_reference_updated |> 
  left_join(survey_dates_reference_updated, by = c("year", "survey_week"))

surveyed_sites <- survey_combined |>  
  mutate(start_date  = as.Date(start_date),
         end_date = as.Date(end_date)) |> 
  select(year, location, surveyed, start_date, end_date) |> # keeping just fields of interest
  glimpse()


# Save the cleaned dataset
# write_csv(surveyed_sites, "data/updated_surveyed_sites_table.csv")  

# reading redd data file 
redd_data <- readxl::read_excel(here::here("data-raw", "edi-update-files", "redd_data_for_binding_update.xlsx")) |>
  glimpse()

# reading your new redd data
# redd_data_updated <- readxl::read_excel(here::here("data-raw, "dwr_chinook_redd_survey_data", "yyyy_Chinook_Redd_Survey_Data.xlsx")) |>
#   bind_rows(redd_data) |> 
#   glimpse()


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
# write_csv(redd_data, "data/updated_redd_observation_w_zeros.csv") # by running this scrip, data will be overwitten 

