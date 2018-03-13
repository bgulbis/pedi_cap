library(tidyverse)
library(lubridate)
library(edwr)
library(icd)

dir_raw <- "data/raw/pilot2b"

# run MBO query
#   * Patients - by ICD
#       - Facility (Curr): HC Childrens
#       - Date Only - Admit: 3/1/2018 - 3/9/2018
#       - Diagnosis Code: A22.1;A37.11;B25.0;B44.0;B44.1;J10.00;J10.01;J10.08;
#           J11.00;J11.08;J12.0;J12.1;J12.2;J12.3;J12.81;J12.89;J12.9;J13;J14;
#           J15.0;J15.1;J15.20;J15.211;J15.212;J15.29;J15.3;J15.4;J15.5;J15.6;
#           J15.7;J15.8;J15.9;J16.0;J16.8;J17;J18.0;J18.2;J18.1;J18.8;J18.9

pts <- read_data(dir_raw, "patients", FALSE) %>%
    as.patients() %>%
    filter(
        age < 18,
        visit.type == "Inpatient",
        discharge.datetime >= mdy("3/1/2018", tz = "US/Central")
    )

mbo_id <- concat_encounters(pts$millennium.id)

# run MBO query
#   * Location History

locations <- read_data(dir_raw, "location", FALSE) %>%
    as.locations() %>%
    tidy_data()

icu <- c("HC NICE", "HC NICW", "HC PICU")

excl_icu <- locations %>%
    filter(location %in% icu) %>%
    distinct(millennium.id)

include <- anti_join(pts, excl_icu, by = "millennium.id")

mbo_id <- concat_encounters(include$millennium.id)

# run MBO query
#   * Clinical Event - Prompt
#       - Clinical Event: Invasive Ventilation Mode;Non-Invasive Ventilation Mode;nitric oxide;ECMO
#   * Diagnosis - ICD-9/10-CM

# exclude if ICD code J69.0
diagnosis <- read_data(dir_raw, "diagnosis", FALSE) %>%
    as.diagnosis() %>%
    tidy_data()

excl_icd <- diagnosis %>%
    filter(diag.code == "J69.0") %>%
    distinct(millennium.id)

include <- anti_join(include, excl_icd, by = "millennium.id")

# exclude if vent, cpap, bipap, ecmo, or nitric
excl_vent <- read_data(dir_raw, "vent", FALSE) %>%
    as.events() %>%
    distinct(millennium.id)

include <- anti_join(include, excl_vent, by = "millennium.id")

write_rds(include, "data/tidy/include_pts_pilot2b.Rds", "gz")

mbo_id <- concat_encounters(include$millennium.id)

# abx <- med_lookup("anti-infectives") %>%
#     mutate_at("med.name", str_to_lower)
#
# mbo_abx <- concat_encounters(abx$med.name)

# run MBO queries:
#   * Clinical Events - Prompt
#       - Clinical Event: SpO2 percent;Respiratory Rate
#   * Demographics
#   * Identifiers - by Millennium Encounter Id
#   * Labs - Prompt
#       - Lab: Creatinine Lvl;WBC;Sed Rate;CRP;C-Reactive Protein;Procalcitonin Lvl
#   * Clinical Events - Measures
#   * Medications - Inpatient - All
#   * Medications - Home and Discharge
#       - Order Type: Prescription/Discharge Order
#   * Orders
#       - Mnemonic (Primary Generic) FILTER ON: CDM PEDI Pneumonia CAP > 60 days Admission
