library(tidyverse)
library(lubridate)
library(edwr)

dir_raw <- "data/raw"

# run MBO query
#   * Patients - by ICD
#       - Facility (Curr): HC Childrens
#       - Date Only - Admit: 1/1/2017 - 9/30/2017
#       - Diagnosis Code: A22.1;A37.11;B25.0;B44.0;B44.1;J10.00;J10.01;J10.08;
#           J11.00;J11.08;J12.0;J12.1;J12.2;J12.3;J12.81;J12.89;J12.9;J13;J14;
#           J15.0;J15.1;J15.20;J15.211;J15.212;J15.29;J15.3;J15.4;J15.5;J15.6;
#           J15.7;J15.8;J15.9;J16.0;J16.8;J17;J18.0;J18.2;J18.1;J18.8;J18.9

pts <- read_data(dir_raw, "patients", FALSE) %>%
    as.patients() %>%
    filter(age < 18,
           discharge.datetime <= mdy("9/30/2017", tzone = "US/Central"))

mbo_id <- concat_encounters(pts$millennium.id)

# run MBO query
#   * Location History

locations <- read_data(dir_raw, "locations", FALSE) %>%
    as.locations() %>%
    tidy_data()

icu <- c("Neonatal", "Pediatric Intensive Care")

excl_icu <- locations %>%
    filter(location %in% icu) %>%
    distinct(millennium.id)

include <- anti_join(pts, excl_icu, by = "millennium.id")

mbo_id <- concat_encounters(include$millennium.id)

# run MBO query
#   * Clinical Event - Prompt
#       - Clinical Event: Invasive Ventilation Mode;Non-Invasive Ventilation Mode;nitric oxide;ECMO
#   * Diagnosis - ICD-9/10-CM

# * Patients requiring ventilatory support including mechanical ventilation,
# continuous positive airway pressure therapy, bilevel positive airway pressure
# therapy, extracorporeal membrane oxygenation therapy or nitric oxide therapy
# during hospital course
# * Patients with pneumonitis due to inhalation of food and/or vomitus (J69.0)

