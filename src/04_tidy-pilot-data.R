library(tidyverse)
library(edwr)

dir_raw <- "data/raw/pilot1"

id <- read_data(dir_raw, "identifiers", FALSE) %>%
    as.id()

# patients ---------------------------------------------

demographics <- read_data(dir_raw, "demographics", FALSE) %>%
    as.demographics() %>%
    select(millennium.id, age, length.stay)

measures <- read_data(dir_raw, "measures", FALSE) %>%
    as.measures()

height <- measures %>%
    filter(measure == "height",
           measure.units == "cm") %>%
    arrange(millennium.id, measure.datetime) %>%
    distinct(millennium.id, .keep_all = TRUE) %>%
    select(millennium.id, height = measure.result)

weight <- measures %>%
    filter(measure == "weight",
           measure.units == "kg") %>%
    arrange(millennium.id, measure.datetime) %>%
    distinct(millennium.id, .keep_all = TRUE) %>%
    select(millennium.id, weight = measure.result)

labs <- read_data(dir_raw, "labs", FALSE) %>%
    as.labs() %>%
    tidy_data() %>%
    filter(!is.na(lab.result)) %>%
    arrange(millennium.id, lab.datetime, lab) %>%
    distinct(millennium.id, lab, .keep_all = TRUE) %>%
    select(millennium.id, lab, lab.result) %>%
    spread(lab, lab.result)

orders <- read_data(dir_raw, "orders", FALSE) %>%
    select(millennium.id = `Encounter Identifier`,
           mpp = `Mnemonic (Primary Generic) FILTER ON`) %>%
    distinct()

data_patients <- demographics %>%
    left_join(id, by = "millennium.id") %>%
    left_join(height, by = "millennium.id") %>%
    left_join(weight, by = "millennium.id") %>%
    left_join(labs, by = "millennium.id") %>%
    left_join(orders, by = "millennium.id") %>%
    select(fin, everything(), -millennium.id)

write_csv(data_patients, "data/external/data_patients_pilot.csv")

# antibiotics ------------------------------------------

meds_abx <- med_lookup("anti-infectives") %>%
    mutate_at("med.name", str_to_lower)

meds_inpt <- read_data(dir_raw, "meds-inpt", FALSE) %>%
    as.meds_inpt() %>%
    arrange(millennium.id, med.datetime, med) %>%
    group_by(millennium.id, med) %>%
    mutate(duration = difftime(last(med.datetime), first(med.datetime), units = "days"))

data_inpt_abx <- meds_inpt %>%
    distinct(millennium.id, med, .keep_all = TRUE) %>%
    select(millennium.id, med, med.dose, med.dose.units, duration) %>%
    filter(med %in% meds_abx$med.name) %>%
    left_join(id[c("millennium.id", "fin")], by = "millennium.id") %>%
    ungroup() %>%
    select(fin, everything(), -millennium.id)

data_dc_abx <- read_data(dir_raw, "meds-home", FALSE) %>%
    as.meds_home() %>%
    filter(med %in% meds_abx$med.name) %>%
    left_join(id[c("millennium.id", "fin")], by = "millennium.id") %>%
    ungroup() %>%
    select(fin, everything(), -millennium.id)

write_csv(data_inpt_abx, "data/external/data_inpatient_abx_pilot.csv")
write_csv(data_dc_abx, "data/external/data_discharge_abx_pilot.csv")
