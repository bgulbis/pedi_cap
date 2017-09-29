library(tidyverse)
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
