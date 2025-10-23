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

# Shapiro-Wilk ------------------------------------------------------------
# Check normality
# https://bookdown.org/dietrichson/metodos-cuantitativos/test-de-normalidad.html
# If shapiro is < 0.05 data is not normal

shapiro_results <- cl_data %>%
  pivot_longer(
    cols = -c(ID, Set, Description, pH, EC), # everything except ID/Set/Description
    names_to = "variable",
    values_to = "value"
  ) %>%
  group_by(variable) %>% # column with methods
  summarise(
    shapiro_p = shapiro.test(value)$p.value,
    .groups = "drop"
  ) %>%
  filter(shapiro_p > 0.05) # double check all of them are < 0.05

shapiro_results # all methods are not normal (p < 0.05) !

# Levene Test -------------------------------------------------------------
# Not normal: check variance for Kruskal Wallis

cl_long <- cl_data %>%
  pivot_longer(
    cols = -c(ID, Set, Description, pH, EC), # everything except ID/Set/Description
    names_to = "variable",
    values_to = "value"
  )
levene_across_vars <- leveneTest(value ~ variable, data = cl_long)
levene_across_vars

# Levene < 0.05 -> at least one variable has significantly different variance.
# check using kruskal if they are equivalent

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


# p values for Kruskal comparison -----------------------------------------

kruskal.test(value ~ method, data = cl_long)$p.value
kruskal.test(value ~ method, data = cl_long_log)$p.value

# Kruskal < 0.05 => all method are different!

# Post hoc ----------------------------------------------------------------

dunn_result <-
  dunnTest(value ~ method, data = cl_long, method = "bonferroni")
dunn_result_log <-
  dunnTest(value ~ method, data = cl_long_log, method = "bonferroni")

post_hoc <- print(dunn_result$res) %>%
  mutate(
    Significance = ifelse(P.adj > 0.05, "Methods equivalent", "Signif. different"),
    Z = round(Z, 2),
    P.adj = round(P.adj, 4),
    Sig.Level = case_when(
      P.adj <= 0.001 ~ "***",
      P.adj <= 0.01 ~ "**",
      P.adj <= 0.05 ~ "*",
      TRUE ~ "NS"
    )
  )

post_hoc_log <- print(dunn_result_log$res) %>%
  mutate(
    Significance = ifelse(P.adj > 0.05, "Methods equivalent", "Signif. different"),
    Z = round(Z, 2),
    P.adj = round(P.adj, 4),
    Sig.Level = case_when(
      P.adj <= 0.001 ~ "***",
      P.adj <= 0.01 ~ "**",
      P.adj <= 0.05 ~ "*",
      TRUE ~ "NS"
    )
  )

post_hoc_all <- bind_rows(post_hoc, post_hoc_log) # merge results log and not log

ft_post_hoc <- flextable(post_hoc_all) %>%
  set_caption("Dunn Test for pairwise comparisons of Chloride Methods") %>%
  theme_booktabs() %>%
  autofit() %>%
  padding(padding = 2, part = "all") %>%
  fontsize(size = 9, part = "all") %>%
  align(align = "center", part = "all") %>%
  width(j = NULL, width = 1.2) %>%
  width(j = 1:ncol(post_hoc_all), width = 0.9)

doc_post_hoc <- read_docx() %>%
  body_add_flextable(ft_post_hoc) %>%
  body_add_par("")

print(doc_post_hoc, target = "docx/post-hoc-table.docx")
