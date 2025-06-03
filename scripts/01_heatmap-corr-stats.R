
# Libraries ---------------------------------------------------------------

library(tidymodels) # for developing models
library(tidyverse) # for data processing
library(readxl) # for loading data
library(GGally) # plot corr
library(car)    # leveneTest
library(broom) # parametros
library(psych) # to use describe

# Load data from Excel ----------------------------------------------------

cl_data <- read_excel("data/fate_data_table.xlsx") # load data


# Extract colnames --------------------------------------------------------

cl_outcomes <- cl_data %>% 
  select(-ID, -Set, -Description,-EC, -pH) %>% 
  select(starts_with("log")) %>% 
  colnames() %>% 
  dput()

cl_outcomes_log <- cl_data %>% 
  select(-ID, -Set, -Description,-EC, -pH) %>% 
  select(-starts_with("log")) %>% 
  colnames() %>% 
  dput()


# Correlation -------------------------------------------------------------

corr <- cor(cl_data %>%  select(-starts_with("log"))
            %>% select(-ID, -Set, -Description), use = "pairwise.complete.obs")

# Long data ---------------------------------------------------------------

corr_long <- as.data.frame(corr) %>%
  rownames_to_column("var1") %>%
  pivot_longer(-var1, names_to = "var2", values_to = "correlation")

# Heatmap -----------------------------------------------------------------

ggplot(corr_long, aes(x = var1, y = var2, fill = correlation)) +
  geom_tile() +
  geom_text(aes(label = round(correlation, 2)), size = 3) +
  scale_fill_gradient2(
    low = "blue",
    mid = "white",
    high = "red",
    midpoint = 0,
    limits = c(-1, 1)
  ) +
  labs(title = "Correlation Matrix",
       x = "",
       y = "",
       fill = "Pearson") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


# GGally ------------------------------------------------------------------

ggpairs(
  cl_data %>% select(-ID,-Set,-Description, -pH, -EC) %>% select(!starts_with("log")),
  lower = list(continuous = wrap("smooth", color = "red", alpha = 0.6)),
  upper = list(continuous = wrap("cor", size = 4)),
  diag = list(continuous = "densityDiag")
)


# Stats to word -----------------------------------------------------------

cl_base <- cl_data %>%
  select(SP, MT, PT, ICP, IC) 

summary_stats <- cl_base %>%
  pivot_longer(everything(), names_to = "variable", values_to = "value") %>%
  group_by(variable) %>%
  summarise(
    Mean = round(mean(value), 3),
    Min = round(min(value), 3),
    Q1 = round(quantile(value, 0.25), 3),
    Median = round(median(value), 3),
    Q3 = round(quantile(value, 0.75), 3),
    Max = round(max(value), 3),
    SD = round(sd(value), 3),
    ShapiroWilk = round(shapiro.test(value)$p.value, 4),
    Normality = ifelse(ShapiroWilk< 0.05, "No", "Yes"),
    .groups = "drop"
  )



levene_result <- leveneTest(
    value ~ method,
    data =  cl_base %>%
      pivot_longer(everything(), names_to = "method", values_to = "value")
  )
levene_p <- round(levene_result$`Pr(>F)`[1], 4)

# Create flextable
ft <- flextable(summary_stats) %>%
  set_caption("Table: Summary Statistics and Shapiro-Wilk Test for Chloride Methods") %>%
  theme_booktabs() %>%
  autofit()

# Add Levene’s result as paragraph
doc <- read_docx() %>%
  body_add_flextable(ft) %>%
  body_add_par("") %>%
  body_add_par(paste0("Levene's Test for Homogeneity of Variance: p = ", levene_p),
               style = "Normal")

# Save Word document
print(doc, target = "docx/Cl_summary_table.docx")
