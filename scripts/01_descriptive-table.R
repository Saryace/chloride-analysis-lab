# Libraries ---------------------------------------------------------------

library(tidymodels) # for developing models
library(tidyverse) # for data processing
library(readxl) # for loading data
library(GGally) # plot corr
library(modelsummary)
library(car) # leveneTest
library(broom) # parameters
library(psych) # to use describe
library(flextable) # for exporting .docx
library(officer) # for exporting .docx
library(FSA) # dunn'test

# Load data ---------------------------------------------------------------

cl_data <- read_csv("data/Chap2.csv") # load all data

# Extract colnames --------------------------------------------------------

cl_methods <- c("MT", "PT", "ICP", "IC") # select 4 methods (not SP)

cl_methods_log <- c("logMT", "logPT", "logICP", "logIC") # select 4 log methods (not SP)

# Summary Stat Log --------------------------------------------------------

var_order <- c("pH", "EC", "MT", "PT", "ICP", "IC")
var_order_log <- c("logMT", "logPT", "logICP", "logIC")
description_order <- c(
  "certified soil samples",
  "Agvise, Northwood, ND",
  "Areas impacted by produce water spills",
  "NDSU Research Projects",
  "OSU"
)

data_summary <- cl_data %>%
  select(all_of(cl_methods), pH, EC, Description) %>%
  pivot_longer(
    cols = -Description,
    names_to = "variable",
    values_to = "value"
  ) %>%
  mutate(variable = factor(variable, levels = var_order)) %>%
  mutate(Description = factor(Description, levels = description_order))

data_summary_log <- cl_data %>%
  select(all_of(cl_methods_log), pH, EC, Description) %>%
  pivot_longer(
    cols = -Description,
    names_to = "variable",
    values_to = "value"
  ) %>%
  mutate(variable = factor(variable, levels = var_order_log)) %>%
  mutate(Description = factor(Description, levels = description_order))

datasummary(
  All(data_summary) * variable ~ Description * (Mean + SD + N),
  data = data_summary,
  output = "docx/descriptive/stat-per-set.docx"
)

datasummary(
  All(data_summary_log) * variable ~ Description * (Mean + SD + N),
  data = data_summary_log,
  output = "docx/descriptive/stat-per-set-log.docx"
)
