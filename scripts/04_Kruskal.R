library(tidyverse)
library(car)       
library(broom)     
library(rstatix)

# Data long ---------------------------------------------------------------

cl_long <- cl_data %>%
  select(SP, MT, PT, ICP, IC) %>%
  pivot_longer(everything(), names_to = "method", values_to = "value") %>%
  drop_na()

# Levene test was < 0.05 = NON parametric ---------------------------------

kruskal_test <- kruskal.test(value ~ method, data = cl_long)
kruskal_test # post hoc test!


# Post hoc ----------------------------------------------------------------

library(FSA)

dunn_result <- dunnTest(value ~ method, data = cl_long, method = "bonferroni")
print(dunn_result$res) %>% 
mutate(significance = ifelse(P.adj > 0.05, "Methods equivalent", "Signif. different"))


