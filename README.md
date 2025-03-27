# Feather River Redd Data EDI Upload Workflow

This guide provides step-by-step instructions to update the Feather River Redd Data EDI package with new data.

## Navigating to the Repository

All data processing and EDI uploads are managed in the same repository.  

1. Navigate to the [project repository](https://github.com/FlowWest/feather-redd/tree/main) and clone it to your local machine.

## Adding Data

2. Before adding the data to the repository, make sure the data contains the following fields:

| Field Name         | Data Type   | Unit             | Allowed Values/Format                     |
|--------------------|-------------|------------------|-------------------------------------------|
| `date`             | Date        | N/A              | `MM/DD/YYYY`                              |
| `survey_wk`        | Integer     | N/A              | Whole numbers                             |
| `location`         | String      | N/A              | Site/location name                        |
| `number_redds`     | Integer     | Fish             | 0 or positive integers                    |
| `number_salmon`    | Integer     | Fish             | 0 or positive integers                    |
| `depth_m`          | Numeric     | Meters           | Decimal values (e.g., 0.45)               |
| `pot_depth_m`      | Numeric     | Meters           | Decimal values (e.g., 0.60)               |
| `velocity_m_s`     | Numeric     | Meters/second    | Decimal values (e.g., 0.35)               |
| `percent_fines`    | Numeric     | Percent (%)      | 0–100                                     |
| `percent_small`    | Numeric     | Percent (%)      | 0–100                                     |
| `percent_med`      | Numeric     | Percent (%)      | 0–100                                     |
| `percent_large`    | Numeric     | Percent (%)      | 0–100                                     |
| `percent_boulder`  | Numeric     | Percent (%)      | 0–100                                     |
| `redd_width_m`     | Numeric     | Meters           | Decimal values (e.g., 1.2)                |
| `redd_length_m`    | Numeric     | Meters           | Decimal values (e.g., 2.5)                |
| `longitude`        | Numeric     | Decimal degrees  | e.g., -122.345                            |
| `latitude`         | Numeric     | Decimal degrees  | e.g., 45.678                              |
| `elevation_ft`     | Numeric     | Feet             | Positive decimal values                   |
| `accuracy_ft`      | Numeric     | Feet             | Positive decimal values                   |
| `boat_point`       | Boolean     | N/A              | `TRUE`, `FALSE`  
    
**Important Suggested Note** for cleaner update. 

During the data cleaning process for previous years, some written documentation was broken down to identify surveys conducted where no redds were observed. In order to automate that, suggestion is to keep additional record of data entries as follows:

  * `survey_week_date_reference`: table containing all site names, and yearly information of survey weeks when survey was conducted. See reference below:
  
| Field Name         | Data Type   | Unit             | Allowed Values/Format                     |
|--------------------|-------------|------------------|-------------------------------------------|
| `year`             | Integer     | N/A              | `YYYY`                                    |
| `location`         | String      | N/A              | Site/location name                        |
| `surveyed     `    | Boolean     | N/A              | `TRUE`, `FALSE`                           |
| `survey_week`      | Integer     | N/A              | Whole numbers (e.g. 1 & 2 & 3)            |

* `surveyed_sites_per_sv_week_summary` table containing yearly information on the date range of each of the survey weeks:

| Field Name         | Data Type   | Unit             | Allowed Values/Format                     |
|--------------------|-------------|------------------|-------------------------------------------|
| `year`             | Integer     | N/A              | `YYYY`                                    |
| `survey_week`      | Integer     | N/A              | Whole numbers                             |
| `start_date`       | Date        | N/A              | `MM/DD/YYYY`                              |
| `end_date`         | Date        | N/A              | `MM/DD/YYYY`                              |

Save those tables in [data-raw/edi-update-files](https://github.com/FlowWest/feather-redd/blob/main/data-raw/edi-update-files) folder following this naming convention: `yyyy_survey_week_date_reference.csv` and `yyyy_surveyed_sites_per_sv_week_summary.csv`, replacing "yyyy" with the actual year of the data.


3. Add the Excel file with new redd data into the `dwr_chinook_redd_survey_data` [folder](https://github.com/FlowWest/feather-redd/tree/main/data-raw/dwr_chinook_redd_survey_data) of your local computer copy, following this naming convention: `yyyy_Chinook_Redd_Survey_Data.xlsx`, replacing "yyyy" with the actual year of the data.

    **Additional Note**: Ensure that the data values are consistent with the expected formats and units. If unsure about the data source or format, consult with the data collection team before proceeding.

## Processing Data

Data processing will then be handled by one script located in the [data-raw/edi-update-files](https://github.com/FlowWest/feather-redd/blob/main/data-raw/edi-update-files) folder: 

  * [edi-update-script.R](https://github.com/FlowWest/feather-redd/blob/main/data-raw/edi-update-script.R)

4. On the `edi-update-script.R` script replace the `"yyyy"` for the year of data to be added throughtout the script, and uncomment those lines (lines 10-12, 19-21, line 37, 44-46, and line 87. For example lines 10 - 12 look like this:
    ```
    survey_dates_reference_updated <- read_csv("data-raw/edi-update-files/yyyy_survey_week_date_reference.cvs") |>
    ```
    ```
    bind_rows(survey_dates_reference) |>
    ```
    ```
      glimpse()
    ```

5. After confirming that the data is showing properly, run the entire `edi-update-script.R` script. If the format is not the same as [the table from step 2](https://github.com/FlowWest/feather-redd?tab=readme-ov-file#adding-data) the script won't work and data cleaning will have to be adapted to format. We will adapt this data cleaning process once the data entry protocol is unified/consistent.

6. The script will generate a CSV called `redd_data.csv` in the [data folder](https://github.com/FlowWest/feather-redd/tree/main/data).

7. After generating the CSV files, update the metadata (located [here](https://github.com/FlowWest/feather-redd/tree/main/data-raw/metadata)):

    - **Feather Redd** (`feather_redd_metadata.xlsx`): Update the minimum and maximum values for fields such as `date`, `number_redds`, `number_salmon`, etc.
    - Update the **project metadata** in `feather_redd_project_metadata.xlsx` (under the Coverage tab).
    - If applicable, adjust the language in the abstract and methods to reflect the latest updates.

### Summary of CSVs Generated for EDI Upload

- `redd_data.csv`

## EDI Update/Upload

Before starting this process, ensure you have an EDI account set up.  

8. Create or edit your `.Renviron` file to include your EDI username and password. To do this, enter the following code in R:
    ```
    usethis::edit_r_environ()
    ```
    This will open your `.Renviron` file. Add the following lines:
    ```
    edi_user_id = [enter your user name]
    edi_password = [enter your password]
    ```

    **Important Note**: Do not share your EDI credentials publicly. Store them securely.

9. The data upload to EDI is handled in the `make_metadata_xml.R` script. The necessary modifications include:

    - Change the EDI package number at line 40 (`edi_number <- "edi.TODO update"`) to the new version number. For example, if the current version is `edi.1764.1`, change it to `edi.1764.2`.

    - After successfully running the script, manually evaluate the package by logging into the [EDI website](https://portal.edirepository.org/nis/login.jsp). Navigate to the **Tools** tab and click on **Evaluate/Upload Data Packages**. 

10. In the EDI portal:
    - Add the `.xml` file under the **EML Metadata File** section.
    - Select "manually upload data" under **Data Upload Options** and click the **Evaluate** button.
    - Attach the corresponding CSV file and click **Evaluate**. Check for any errors (warning messages are generally okay).
  
11. After evaluating the package without errors, return to the `make_metadata_xml.R` script and update line 75 with the new version number that will be used for the next update. For example, if the current version is `1764.1`, update it to `1764.2`.

    The line should look like this:
    ```
    EMLaide::update_edi_package(Sys.getenv("edi_user_id"), Sys.getenv("edi_password"), "edi.1764.1", paste0(edi_number, ".xml"))
    ```

12. Uncomment this line and run the script. Note: Running this code will automatically upload the EDI package. Packages cannot be overwritten, so if changes are needed, both (1) the new EDI number on line 40 and (2) the `update_edi_package` function on line 75 must be updated, and the script must be run again.

## EDI Upload Check

To verify the new package upload, navigate to the [EDI repository portal](https://portal.edirepository.org/nis/home.jsp) and search for the updated package. 

**Additional Note**: After uploading, verify the submission on the EDI portal. Check for any errors or warnings related to the data fields, and ensure that the data appears as expected. If any issues arise, you may need to correct the files and re-upload them.

