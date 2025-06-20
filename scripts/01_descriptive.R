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

# Load data ---------------------------------------------------------------

cl_data <- read_csv("data/Chap2.csv") # load data

# Extract colnames --------------------------------------------------------

cl_methods <- c("SP","MT","PT","ICP","IC")

cl_methods_log <- c("logSP","logMT","logPT","logICP","logIC")

# GGally ------------------------------------------------------------------

fig_corr <- ggpairs(
  cl_data %>% select(all_of(cl_methods), Set), 
  lower = list(continuous = 'smooth'),
  columns = 1:5,
  mapping = aes(color = as.factor(Set))) +
  theme_bw()

ggsave("figures/fig_corr.tiff", fig_corr, width = 8, height = 8)
ggsave("figures/fig_corr.png", fig_corr, width = 8, height = 8)

fig_corr_log <- ggpairs(
  cl_data %>% select(all_of(cl_methods_log), Set), 
  lower = list(continuous = 'smooth'),
  columns = 1:5,
  mapping = aes(color = as.factor(Set))) +
  theme_bw()

ggsave("figures/fig_corr_log.tiff", fig_corr_log, width = 8, height = 8)
ggsave("figures/fig_corr_log.png", fig_corr_log, width = 8, height = 8)


# Summary Stat Log --------------------------------------------------------

var_order <- c("pH","EC","SP","MT","PT","ICP","IC")
var_order_log <- c("pH","EC","logSP","logMT","logPT","logICP","logIC")
description_order <- c("certified soil samples",
                       "Agvise, Northwood, ND",
                       "Areas impacted by produce water spills",
                       "NDSU Research Projects",
                       "OSU")

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
  All(data_summary) * variable ~ Description * (Mean + SD + N) ,
  data = data_summary, 
  output = "docx/stat-per-set.docx")

datasummary(
  All(data_summary_log) * variable ~ Description * (Mean + SD + N),
  data = data_summary_log, 
  output = "docx/stat-per-set-log.docx")

# Levene Test -------------------------------------------------------------

levene_data <- data_summary %>%
  filter(Description == "certified soil samples")

levene_data_log <- data_summary_log %>%
  filter(Description == "certified soil samples")

levene_test <-
  leveneTest(data = levene_data,
             y = levene_data$value,
             group = levene_data$variable)$`Pr(>F)`[1]

levene_test_log <-
  leveneTest(data = levene_data_log,
             y = levene_data$value,
             group = levene_data$variable)$`Pr(>F)`[1]

# Both levene are < 0.005 -> check using kruskal if they are equivalent

# Kruskal -----------------------------------------------------------------

# Levene test was < 0.05 = NON parametric ---------------------------------

cl_long <- cl_data %>%
  filter(Description == "certified soil samples") %>% 
  select(all_of(cl_methods)) %>%
  pivot_longer(everything(), names_to = "method", values_to = "value") 

cl_long_log <- cl_data %>%
  filter(Description == "certified soil samples") %>% 
  select(all_of(cl_methods_log)) %>%
  pivot_longer(everything(), names_to = "method", values_to = "value") 

kruskal.test(value ~ method, data = cl_long)
kruskal.test(value ~ method, data = cl_long_log)

# Kruskal < 0.05 => all method are different!

# Post hoc ----------------------------------------------------------------

library(FSA)

dunn_result <-
  dunnTest(value ~ method, data = cl_long, method = "bonferroni")
dunn_result_log <-
  dunnTest(value ~ method, data = cl_long_log, method = "bonferroni")

post_hoc <- print(dunn_result$res) %>%
  mutate(
    significance = ifelse(P.adj > 0.05, "Methods equivalent", "Signif. different"),
    Z = round(Z, 2),
    P.adj = round(P.adj, 4),
    P.unadj = round(P.unadj, 4)
  )

post_hoc_log <- print(dunn_result_log$res) %>%
  mutate(
    significance = ifelse(P.adj > 0.05, "Methods equivalent", "Signif. different"),
    Z = round(Z, 2),
    P.adj = round(P.adj, 4),
    P.unadj = round(P.unadj, 4)
  )

post_hoc_all <- bind_rows(post_hoc, post_hoc_log)

ft_post_hoc <- flextable(post_hoc_all) %>%
  set_caption("Dunn Test for pairwise comparisons of Chloride Methods") %>%
  theme_booktabs() %>%
  autofit() %>%
  padding(padding = 2, part = "all") %>%       
  fontsize(size = 9, part = "all") %>%          
  align(align = "center", part = "all") %>%    
  width(j = NULL, width = 1.2)     %>%
  width(j = 1:ncol(post_hoc_all), width = 0.9)  

doc_post_hoc <- read_docx() %>%
  body_add_flextable(ft_post_hoc) %>%
  body_add_par("") 

print(doc_post_hoc, target = "docx/post-hoc-table.docx")
