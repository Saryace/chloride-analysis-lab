# Libraries ---------------------------------------------------------------

library(tidymodels) # for developing models
library(tidyverse) # for data processing
library(readxl) # for loading data
library(GGally) # plot corr
library(modelsummary)
library(broom) # parameters
library(psych) # to use describe
library(flextable) # for exporting .docx
library(officer) # for exporting .docx

# Load data ---------------------------------------------------------------

certified_data <- read_excel("data/Chap2-Rcode-DataBase.xlsx") %>%
  filter(Set == 1) %>%
  filter(if_all(everything(), ~ !grepl("[<>]", as.character(.)))) %>%
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
  filter(if_all(everything(), ~ !grepl("[<>]", as.character(.)))) %>%
  mutate(
    across(c(MT, PT, ICP, IC, pH, EC), as.numeric),
    logMT  = log10(MT),
    logPT  = log10(PT),
    logICP = log10(ICP),
    logIC  = log10(IC),
    DataGroup = "non-certified"
  )

spill_data <- read_excel("data/Chap2-Rcode-DataBase-S5-NDSUContaminateSoil.xlsx") %>%
  filter(if_all(everything(), ~ !grepl("[<>]", as.character(.)))) %>%
  mutate(
    across(c(MT, PT, ICP, IC, pH, EC), as.numeric),
    logMT  = log10(MT),
    logPT  = log10(PT),
    logICP = log10(ICP),
    logIC  = log10(IC),
    DataGroup = "spill"
  )

# Extract colnames --------------------------------------------------------

cl_methods <- c("MT","PT","ICP","IC") # dplyr::select 4 methods (not SP)

cl_methods_log <- c("logMT","logPT","logICP","logIC")  # dplyr::select 4 log methods (not SP)

# Okabeito ----------------------------------------------------------------
# standard daltonism see Okabe and Ito paper

okabe_ito_dark <- c(
  "#E69F00", # orange
  "#56B4E9", # sky blue
  "#009E73", # bluish green
  "#D55E00", # vermillion
  "#0072B2" # blue
)

# GGally ------------------------------------------------------------------
# Crear con colores ajustados 4 versiones: sin diagonal y con histogramas

custom_diag <- function(data, mapping, ...) {
  ggplot(data = data, mapping = mapping) +
    geom_histogram(
      aes(y = after_stat(count)),
      bins = 10,
      position = "identity",
      alpha = 0.6,
      fill = okabe_ito_dark[2],
      color = "white"
    ) +
    theme_bw() +
    theme(
      panel.grid = element_blank(),
      axis.text = element_text(size = 8)
    )
}


fig_corr <- ggpairs(
  certified_data %>%
    dplyr::select(all_of(cl_methods)),
  columns = 1:4,
  lower = list(continuous = "smooth"),
  diag   = list(continuous = wrap(custom_diag))
) +
  theme_bw()

ggsave("figures/correlation/fig_corr.tiff", fig_corr, width = 8, height = 8, dpi = 300)
ggsave("figures/correlation/fig_corr.png", fig_corr, width = 8, height = 8, dpi = 300)

fig_corr_log <- ggpairs(
  certified_data %>%
    dplyr::select(all_of(cl_methods_log)),
  columns = 1:4,
  lower = list(continuous = "smooth"),
  diag   = list(continuous = wrap(custom_diag))
) +
  theme_bw()

ggsave("figures/correlation/fig_corr_log.tiff", fig_corr_log, width = 8, height = 8, dpi = 300)
ggsave("figures/correlation/fig_corr_log.png", fig_corr_log, width = 8, height = 8, dpi = 300)

# Non-certified -----------------------------------------------------------

fig_corr_non_certified <- ggpairs(
  non_certified_data %>%
    dplyr::select(all_of(cl_methods)),
  columns = 1:4,
  lower = list(continuous = "smooth"),
  diag = list(continuous = wrap(custom_diag))
) +
  theme_bw()

ggsave("figures/correlation/fig_corr_non_certified.png", fig_corr_non_certified, width = 8, height = 8, dpi = 300)
ggsave("figures/correlation/fig_corr_non_certified.tiff", fig_corr_non_certified, width = 8, height = 8, dpi = 300)

# Non-certified log -------------------------------------------------------

fig_corr_non_certified_log <- ggpairs(
  non_certified_data %>%
    dplyr::select(all_of(cl_methods_log)),
  columns = 1:4,
  lower = list(continuous = "smooth"),
  diag = list(continuous = wrap(custom_diag))
) +
  theme_bw()

ggsave("figures/correlation/fig_corr_non_certified_log.png", fig_corr_non_certified_log, width = 8, height = 8, dpi = 300)
ggsave("figures/correlation/fig_corr_non_certified_log.tiff", fig_corr_non_certified_log, width = 8, height = 8, dpi = 300)

# Spill -------------------------------------------------------------------

fig_corr_spill <- ggpairs(
  spill_data %>%
    dplyr::select(all_of(cl_methods)),
  columns = 1:4,
  lower = list(continuous = "smooth"),
  diag = list(continuous = wrap(custom_diag))
) +
  theme_bw()

ggsave("figures/correlation/fig_corr_spill.png", fig_corr_spill, width = 8, height = 8, dpi = 300)
ggsave("figures/correlation/fig_corr_spill.tiff", fig_corr_spill, width = 8, height = 8, dpi = 300)

# Spill log ---------------------------------------------------------------

fig_corr_spill_log <- ggpairs(
  spill_data %>%
    dplyr::select(all_of(cl_methods_log)),
  columns = 1:4,
  lower = list(continuous = "smooth"),
  diag = list(continuous = wrap(custom_diag))
) +
  theme_bw()

ggsave("figures/correlation/fig_corr_spill_log.png", fig_corr_spill_log, width = 8, height = 8, dpi = 300)
ggsave("figures/correlation/fig_corr_spill_log.tiff", fig_corr_spill_log, width = 8, height = 8, dpi = 300)