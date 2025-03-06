library(EDIutils)
library(tidyverse)
library(EMLaide)
library(readxl)
library(EML)

datatable_metadata <-
  dplyr::tibble(filepath = c("data/redd_observation_w_zeros.csv", "data/surveyed_sites_table.csv" ),
                attribute_info = c("data-raw/metadata/feather_redd_metadata.xlsx", "data-raw/metadata/feather_redd_surveyed_sites_metadata.xlsx"),
                datatable_description = c("Redd observations from Feather River redd surveys", "Surveyed locations" ),
                datatable_url = paste0("https://raw.githubusercontent.com/FlowWest/feather-redd/main/data/",
                                       c("redd_observation_w_zeros.csv", "surveyed_sites_table.csv")))

other_entity_metadata_1 <- list("file_name" = "General_Chinook_Salmon_Redd_Survey_Methods_with_Yearly_Summaries",
                                "file_description" = "Survey Methods",
                                "file_type" = "pdf",
                                "physical" = create_physical("data-raw/metadata/General_Chinook_Salmon_Redd_Survey_Methods_with_Yearly_Summaries.pdf",
                                                             data_url = "https://raw.githubusercontent.com/FlowWest/feather-redd/main/data-raw/metadata/General_Chinook_Salmon_Redd_Survey_Methods_with_Yearly_Summaries.pdf"))

other_entity_metadata_1$physical$dataFormat <- list("externallyDefinedFormat" = list("formatName" = "pdf"))

# save cleaned data to `data/`
excel_path <- "data-raw/metadata/feather_redd_project_metadata.xlsx" 
sheets <- readxl::excel_sheets(excel_path)
metadata <- lapply(sheets, function(x) readxl::read_excel(excel_path, sheet = x))
names(metadata) <- sheets

abstract_docx <- "data-raw/metadata/abstract.docx"
methods_docx <- "data-raw/metadata/methods.md"

#edi_number <- reserve_edi_id(user_id = Sys.getenv("EDI_USER_ID"), password = Sys.getenv("EDI_PASSWORD"))
edi_number <- "edi.1802.2"

dataset <- list() %>%
  add_pub_date() %>%
  add_title(metadata$title) %>%
  add_personnel(metadata$personnel) %>%
  add_keyword_set(metadata$keyword_set) %>%
  add_abstract(abstract_docx) %>%
  add_license(metadata$license) %>%
  add_method(methods_docx) %>%
  add_maintenance(metadata$maintenance) %>%
  add_project(metadata$funding) %>%
  add_coverage(metadata$coverage, metadata$taxonomic_coverage) %>%
  add_datatable(datatable_metadata) |>
  add_other_entity(other_entity_metadata_1)

# GO through and check on all units
custom_units <- data.frame(id = c("redds", "salmon", "decimal degrees", "decimal degrees", "feet", "feet", "year"), #todo update custom units
                           unitType = c("dimensionless", "dimensionless", "dimensionless", "dimensionless", "dimensionless", "dimensionless", "dimensionless"),
                           parentSI = c(NA, NA, NA, NA, NA, NA, NA),
                           multiplierToSI = c(NA, NA, NA, NA, NA, NA, NA),
                           description = c("number of redds", "number of salmon ", "decimal degrees", "decimal degrees","feet", "feet", "year"))


unitList <- EML::set_unitList(custom_units)

eml <- list(packageId = edi_number,
            system = "EDI",
            access = add_access(),
            dataset = dataset,
            additionalMetadata = list(metadata = list(unitList = unitList))
)
edi_number
EML::write_eml(eml, paste0(edi_number, ".xml"))
EML::eml_validate(paste0(edi_number, ".xml"))
EMLaide::evaluate_edi_package(Sys.getenv("edi_user_id"), Sys.getenv("edi_password"), paste0(edi_number, ".xml"))
# EMLaide::upload_edi_package(Sys.getenv("edi_user_id"), Sys.getenv("edi_password"), paste0(edi_number, ".xml"))
