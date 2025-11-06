# Libraries ---------------------------------------------------------------

library(tidymodels) # for developing models
library(tidyverse) # for data processing
library(readxl) # for loading data
library(GGally) # plot corr
library(modelsummary)
library(car)    # leveneTest
library(broom) # parameters
library(psych) # to use describe
library(flextable) # for exporting .docx
library(officer) # for exporting .docx
library(FSA) # dunn'test 

# Load data ---------------------------------------------------------------

cl_data <- read_csv("data/Chap2.csv") # load all data

# Extract colnames --------------------------------------------------------

cl_methods <- c("MT","PT","ICP","IC") # select 4 methods (not SP)

cl_methods_log <- c("logMT","logPT","logICP","logIC")  # select 4 log methods (not SP)

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
# PENDIENTE 

custom_diag <- function(data, mapping, ...) {
  ggplot(data = data, mapping = mapping) +
    geom_histogram(
      aes(y = ..count..),
      bins = 10,
      position = "identity",
      alpha = 0.6
    ) +
    # you can keep this here or set it globally below
    scale_fill_manual(values = okabe_ito_dark) +
    theme_bw() +
    theme(panel.grid = element_blank(),
          axis.text = element_text(size = 8))
}

fig_corr <- ggpairs(
  cl_data %>%
    select(all_of(cl_methods), Set) %>%
    mutate(Set = paste("Set", Set)),
  columns = 1:4,
  lower = list(continuous = "smooth"),
  diag   = list(continuous = wrap(custom_diag)),
  mapping = aes(color = as.factor(Set), fill = as.factor(Set))
) +
  scale_color_manual(values = okabe_ito_dark) +
  scale_fill_manual(values = okabe_ito_dark) +   
  theme_bw()

ggsave("figures/correlation/fig_corr.tiff", fig_corr, width = 8, height = 8)
ggsave("figures/correlation/fig_corr.png", fig_corr, width = 8, height = 8)

fig_corr_log <- ggpairs(
  cl_data %>%
    select(all_of(cl_methods_log), Set) %>%
    mutate(Set = paste("Set", Set)),
  columns = 1:4,
  lower = list(continuous = "smooth"),
  diag   = list(continuous = wrap(custom_diag)),
  mapping = aes(color = as.factor(Set), fill = as.factor(Set))
) +
  scale_color_manual(values = okabe_ito_dark) +
  scale_fill_manual(values = okabe_ito_dark) +   
  theme_bw()

ggsave("figures/correlation/fig_corr_log.tiff", fig_corr_log, width = 8, height = 8)
ggsave("figures/correlation/fig_corr_log.png", fig_corr_log, width = 8, height = 8)
