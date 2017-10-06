library(tidyverse)
library(stringr)
library(edwr)

dir_raw <- "data/raw"

demographics <- read_data(dir_raw, "demographics", FALSE) %>%
    as.demographics() %>%
    select(millennium.id, age, length.stay)

labs <- read_data(dir_raw, "labs", FALSE) %>%
    as.labs() %>%
    tidy_data() %>%
    filter(!is.na(lab.result)) %>%
    arrange(millennium.id, lab.datetime, lab) %>%
    distinct(millennium.id, lab, lab.result)

data_labs <- labs %>%
    select(millennium.id, lab, lab.result) %>%
    distinct(millennium.id, lab, .keep_all = TRUE) %>%
    spread(lab, lab.result)

data_patients <- demographics %>%
    left_join(data_labs, by = "millennium.id")

meds_abx <- med_lookup("anti-infectives") %>%
    mutate_at("med.name", str_to_lower)

meds_inpt <- read_data(dir_raw, "meds-inpt", FALSE) %>%
    as.meds_inpt() %>%
    arrange(millennium.id, med.datetime, med) %>%
    group_by(millennium.id, med) %>%
    mutate(duration = difftime(last(med.datetime), first(med.datetime), units = "days"))

data_inpt_abx <- meds_inpt %>%
    distinct(millennium.id, med, .keep_all = TRUE) %>%
    select(millennium.id, med, med.dose, med.dose.units, duration)

data_dc_abx <- read_data(dir_raw, "meds-home", FALSE) %>%
    as.meds_home() %>%
    filter(med %in% meds_abx$med.name)

orders <- read_data(dir_raw, "orders", FALSE)
