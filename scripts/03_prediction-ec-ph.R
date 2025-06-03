
# Libraries ---------------------------------------------------------------

library(tidymodels) # for developing models
library(tidyverse) # for data processing
library(readxl) # for loading data

# Load data from Excel ----------------------------------------------------

cl_data <- read_excel("data/fate_data_table.xlsx")

cl_outcomes <- cl_data %>% 
  select(-ID, -Set, -Description,-EC, -pH) %>% 
  select(starts_with("log")) %>% 
  colnames() %>% 
  dput()

# Split train/test --------------------------------------------------------

set.seed(123)
cl_data_split <- initial_split(cl_data, prop = 0.75, strata = EC)
train_data <- training(cl_data_split)
test_data <- testing(cl_data_split)

# Multivariate models (train 80%) -----------------------------------------

models <- map(cl_outcomes, function(y) {
  rec <- recipe(as.formula(paste(y, "~ EC + pH")), data = train_data)
  
  wf <- workflow() %>%
    add_model(rand_forest(mode = "regression", mtry = 2, trees = 500) %>%
                set_engine("ranger")) %>%
    add_recipe(rec)
  
  fit(wf, data = train_data)
})

# Name the models
names(models) <- cl_outcomes


# Test in testing (20%) ---------------------------------------------------

results <- map2_df(models, cl_outcomes, function(mod, outcome) {
  preds <- predict(mod, new_data = test_data) %>%
    bind_cols(truth = test_data[[outcome]])
  
  metrics <- yardstick::metrics(preds, truth = truth, estimate = .pred)
  
  metrics %>%
    mutate(outcome = outcome)
})

# Show performance
results

# Plot data ---------------------------------------------------------------

labels_ggplot <- results %>%
  filter(.metric %in% c("rmse", "rsq")) %>%
  select(outcome, .metric, .estimate) %>%
  pivot_wider(names_from = .metric, values_from = .estimate) %>%
  mutate(label = paste0("R² = ", round(rsq, 2), "\nRMSE = ", round(rmse, 2)))

plot_data <- map2_dfr(models, cl_outcomes, function(mod, outcome) {
  predict(mod, new_data = test_data) %>%
    bind_cols(observed = test_data[[outcome]]) %>%
    mutate(outcome = outcome)
})


# Plot --------------------------------------------------------------------

ggplot(plot_data, aes(x = observed, y = .pred)) +
  geom_point(alpha = 0.7) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
  coord_obs_pred(ratio = 1) +
  facet_wrap(vars(outcome)) +
  geom_text(
    data = labels_ggplot,
    aes(x = -Inf, y = Inf, label = label),
    hjust = -0.1, vjust = 1.1,
    inherit.aes = FALSE
  ) +
  labs(
    x = "Observed",
    y = "Predicted",
    title = "Predicted vs Observed Chloride based on pH + EC"
  ) +
  theme_bw()


