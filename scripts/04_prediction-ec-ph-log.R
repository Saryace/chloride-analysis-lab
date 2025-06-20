
# Libraries ---------------------------------------------------------------

library(tidymodels) # for developing models
library(tidyverse) # for data processing
library(readxl) # for loading data

# Load data from Excel ----------------------------------------------------

cl_data <- read_csv("data/Chap2.csv") %>% 
  filter(Set == 1)

cl_methods_log <- c("logSP","logMT","logPT","logICP","logIC")
base_covariates <- c("pH", "EC", "EC + pH")

# Split train/test --------------------------------------------------------

set.seed(123)
cl_data_split <- initial_split(cl_data, prop = 0.80)
train_data <- training(cl_data_split)
test_data <- testing(cl_data_split)

# Multivariate models (train 80%) -----------------------------------------

responses <- c("logMT", "logPT", "logICP", "logIC")
base_covariates <- c("", "pH", "EC", "pH + EC")

# Build formulas: response ~ logSP (+ optional base)
formulas <- cross_df(list(response = responses, base = base_covariates)) %>%
  mutate(
    formula = str_trim(
      ifelse(base == "",
             paste(response, "~ logSP"),
             paste(response, "~ logSP +", base))
    )
  ) %>%
  pull(formula)

# Fit models (assuming train_data is already defined)
lm_models <- map(formulas, ~ {
  rec <- recipe(as.formula(.x), data = train_data)
  workflow() %>%
    add_model(linear_reg() %>% set_engine("lm")) %>%
    add_recipe(rec) %>%
    fit(data = train_data)
})
names(lm_models) <- formulas

# Test in testing (20%) ---------------------------------------------------

eval_results <- map2_dfr(
  lm_models,
  names(lm_models),
  function(model, fml) {
    response <- str_extract(fml, "^[^~]+") %>% str_trim()
    
    preds <- predict(model, new_data = test_data) %>%
      bind_cols(test_data %>% select(all_of(response))) %>%
      rename(truth = !!sym(response))
    
    metrics(preds, truth = truth, estimate = .pred) %>%
      mutate(model = fml, response = response)
  }
)

# Plot data ---------------------------------------------------------------

labels_ggplot <- eval_results %>%
  filter(.metric %in% c("rmse", "rsq")) %>%
  select(model, .metric, .estimate) %>%
  pivot_wider(names_from = .metric, values_from = .estimate) %>%
  mutate(
    label = paste0("R² = ", format(round(rsq, 2), nsmall = 2),
                   "\nRMSE = ", signif(rmse, 4)),
    model_clean = gsub("^.*~", "", model) %>% str_trim()
  )

plot_data <- map2_dfr(lm_models, names(lm_models), function(model, name) {
  response <- str_extract(name, "^[^~]+") %>% str_trim()
  
  preds <- predict(model, new_data = test_data) %>%
    bind_cols(test_data %>% select(all_of(response))) %>%
    rename(truth = !!sym(response)) %>%
    mutate(model = name)
})

# Plot --------------------------------------------------------------------

obs_pred <- ggplot(plot_data, aes(x = .pred, y = truth)) +
  geom_point(alpha = 0.6, color = "#0072B2") +
  geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
  facet_wrap(~ model, ncol = 4) +
  geom_text(
    data = labels_ggplot,
    aes(x = -Inf, y = Inf, label = label),
    inherit.aes = FALSE,
    hjust = -0.05,
    vjust = 1.1,
    size = 3
  ) +
  labs(
    x = "Predicted",
    y = "Observed",
    title = "Observed vs. Predicted (Test Set)",
    subtitle = "Linear models using logSP and pH and EC as covariates"
  ) +
  coord_obs_pred() +  # for identity line to look proportional
  theme_bw(base_size = 12) +
  theme(
    strip.text = element_text(size = 6, face = "bold"),
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(size = 10, color = "grey30"),
    panel.grid.minor = element_blank()
  )


ggsave("figures/obs_pred_log.tiff", obs_pred, width = 8, height = 8)