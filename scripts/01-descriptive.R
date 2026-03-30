# Libraries ---------------------------------------------------------------
library(tidyverse)
library(readxl)
library(psych)
library(flextable)
library(officer)

# Load data ---------------------------------------------------------------
certified_data <- read_excel("data/Chap2-Rcode-DataBase.xlsx") %>%
  filter(Set == 1) %>%
  mutate(
    across(c(MT, PT, ICP, IC, pH, EC), as.numeric),
    logMT  = log10(MT),
    logPT  = log10(PT),
    logICP = log10(ICP),
    logIC  = log10(IC),
    DataGroup = "certified"
  )

non_certified_data <- read_excel("data/Chap2-Rcode-DataBase.xlsx") %>%
  filter(Set != 1) %>%
  mutate(
    across(c(MT, PT, ICP, IC, pH, EC), as.numeric),
    logMT  = log10(MT),
    logPT  = log10(PT),
    logICP = log10(ICP),
    logIC  = log10(IC),
    DataGroup = "non-certified"
  )

spill_data <- read_excel("data/Chap2-Rcode-DataBase-S5-NDSUContaminateSoil.xlsx") %>%
  mutate(
    across(c(MT, PT, ICP, IC, pH, EC), as.numeric),
    logMT  = log10(MT),
    logPT  = log10(PT),
    logICP = log10(ICP),
    logIC  = log10(IC),
    DataGroup = "spill"
  )

# Variables ---------------------------------------------------------------
cl_methods <- c("MT", "PT", "ICP", "IC", "pH", "EC")
cl_methods_log <- c("logMT", "logPT", "logICP", "logIC", "pH", "EC")

# Combine data ------------------------------------------------------------
cl_data <- bind_rows(certified_data, non_certified_data, spill_data)

# Function to calculate stats --------------------------------------------
calc_stats <- function(data, vars) {
  data %>%
    group_by(DataGroup) %>%
    summarise(
      across(
        all_of(vars),
        list(
          N = ~ sum(!is.na(.)),
          Mean = ~ mean(., na.rm = TRUE),
          SD = ~ sd(., na.rm = TRUE),
          Var = ~ var(., na.rm = TRUE),
          SE = ~ sd(., na.rm = TRUE) / sqrt(sum(!is.na(.))),
          CV = ~ (sd(., na.rm = TRUE) / mean(., na.rm = TRUE)) * 100,
          Min = ~ min(., na.rm = TRUE),
          Max = ~ max(., na.rm = TRUE),
          Median = ~ median(., na.rm = TRUE),
          Q1 = ~ quantile(., 0.25, na.rm = TRUE) %>% as.numeric(),
          Q3 = ~ quantile(., 0.75, na.rm = TRUE) %>% as.numeric(),
          Skew = ~ psych::skew(., na.rm = TRUE)
        ),
        .names = "{.col}_{.fn}"
      ),
      .groups = "drop"
    )
}

# Calculate statistics ----------------------------------------------------
stats_original <- calc_stats(cl_data, cl_methods)
stats_log <- calc_stats(cl_data, cl_methods_log)

# Reshape: original -------------------------------------------------------
stats_long <- stats_original %>%
  pivot_longer(
    cols = -DataGroup,
    names_to = "Description",
    values_to = "Value"
  ) %>%
  separate(
    Description,
    into = c("Variable", "Statistic"),
    sep = "_",
    extra = "merge"
  ) %>%
  pivot_wider(
    names_from = DataGroup,
    values_from = Value
  ) %>%
  dplyr::select(Variable, Statistic, certified, `non-certified`, spill)

# Create flextable with formatting ---------------------------------------
ft <- flextable(stats_long) %>%
  colformat_double(j = c("certified", "non-certified", "spill"), digits = 2) %>%
  autofit() %>%
  theme_vanilla()

# Save to Word ------------------------------------------------------------
doc <- read_docx() %>%
  body_add_flextable(ft)

print(doc, target = "docx/descriptive/stats-original.docx")

# Reshape: log ------------------------------------------------------------
stats_long_log <- stats_log %>%
  pivot_longer(
    cols = -DataGroup,
    names_to = "Description",
    values_to = "Value"
  ) %>%
  separate(
    Description,
    into = c("Variable", "Statistic"),
    sep = "_",
    extra = "merge"
  ) %>%
  pivot_wider(
    names_from = DataGroup,
    values_from = Value
  ) %>%
  dplyr::select(Variable, Statistic, certified, `non-certified`, spill)

# Create flextable for log table -----------------------------------------
ft_log <- flextable(stats_long_log) %>%
  colformat_double(j = c("certified", "non-certified", "spill"), digits = 2) %>%
  autofit() %>%
  theme_vanilla()

# Save to Word ------------------------------------------------------------
doc_log <- read_docx() %>%
  body_add_flextable(ft_log)

print(doc_log, target = "docx/descriptive/stats-log.docx")