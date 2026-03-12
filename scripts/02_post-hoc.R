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

# Extract colnames --------------------------------------------------------
cl_methods <- c("MT", "PT", "ICP", "IC")
cl_methods_log <- c("logMT", "logPT", "logICP", "logIC")

# Shapiro-Wilk ------------------------------------------------------------
# If p < 0.05, reject normality

shapiro_results <- certified_data %>%
  pivot_longer(
    cols = c(all_of(cl_methods), all_of(cl_methods_log)),
    names_to = "variable",
    values_to = "value"
  ) %>%
  group_by(variable) %>%
  summarise(
    shapiro_p = shapiro.test(na.omit(value))$p.value,
    .groups = "drop"
  )

shapiro_results

# Prepare wide data -------------------------------------------------------
cl_certified <- certified_data %>%
  dplyr::select(ID, all_of(cl_methods))

cl_certified_log <- certified_data %>%
  dplyr::select(ID, all_of(cl_methods_log))

# Friedman test -----------------------------------------------------------
# Repeated measures non-parametric comparison among methods

friedman_original <- friedman.test(as.matrix(cl_certified %>% dplyr::select(-ID)))
friedman_log <- friedman.test(as.matrix(cl_certified_log %>% dplyr::select(-ID)))

friedman_original
friedman_log

# Long format for paired post hoc ----------------------------------------
cl_long <- cl_certified %>%
  pivot_longer(
    cols = -ID,
    names_to = "method",
    values_to = "value"
  )

cl_long_log <- cl_certified_log %>%
  pivot_longer(
    cols = -ID,
    names_to = "method",
    values_to = "value"
  )

# Paired Wilcoxon post hoc ------------------------------------------------
post_hoc <- pairwise.wilcox.test(
  x = cl_long$value,
  g = cl_long$method,
  paired = TRUE,
  p.adjust.method = "bonferroni"
)

post_hoc_log <- pairwise.wilcox.test(
  x = cl_long_log$value,
  g = cl_long_log$method,
  paired = TRUE,
  p.adjust.method = "bonferroni"
)

# Convert post hoc matrices to tables -------------------------------------
post_hoc_tbl <- as.data.frame(as.table(post_hoc$p.value)) %>%
  drop_na(Freq) %>%
  rename(Method1 = Var1, Method2 = Var2, P.adj = Freq) %>%
  mutate(
    Scale = "Original",
    Significance = if_else(P.adj > 0.05, "Methods equivalent", "Signif. different"),
    P.adj = round(P.adj, 4),
    Sig.Level = case_when(
      P.adj <= 0.001 ~ "***",
      P.adj <= 0.01 ~ "**",
      P.adj <= 0.05 ~ "*",
      TRUE ~ "NS"
    )
  )

post_hoc_log_tbl <- as.data.frame(as.table(post_hoc_log$p.value)) %>%
  drop_na(Freq) %>%
  rename(Method1 = Var1, Method2 = Var2, P.adj = Freq) %>%
  mutate(
    Scale = "Log",
    Significance = if_else(P.adj > 0.05, "Methods equivalent", "Signif. different"),
    P.adj = round(P.adj, 4),
    Sig.Level = case_when(
      P.adj <= 0.001 ~ "***",
      P.adj <= 0.01 ~ "**",
      P.adj <= 0.05 ~ "*",
      TRUE ~ "NS"
    )
  )

post_hoc_all <- bind_rows(post_hoc_tbl, post_hoc_log_tbl)

# Export table ------------------------------------------------------------
ft_post_hoc <- flextable(post_hoc_all) %>%
  set_caption("Paired Wilcoxon post hoc comparisons of chloride methods") %>%
  theme_booktabs() %>%
  autofit() %>%
  padding(padding = 2, part = "all") %>%
  fontsize(size = 9, part = "all") %>%
  align(align = "center", part = "all")

doc_post_hoc <- read_docx() %>%
  body_add_flextable(ft_post_hoc) %>%
  body_add_par("")

print(doc_post_hoc, target = "docx/post-hoc/post-hoc-table.docx")