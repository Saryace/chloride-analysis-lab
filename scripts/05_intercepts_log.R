
# Libraries ---------------------------------------------------------------

library(tidymodels) # for developing models
library(tidyverse) # for data processing
library(readxl) # for loading data

# Load data from Excel ----------------------------------------------------

cl_data <- read_csv("data/Chap2.csv") %>% 
  filter(Set == 1) %>% 
  select(-SP,-logSP,-ID,-Set)

cl_methods <- c("logMT","logPT","logICP","logIC")

# Split train/test --------------------------------------------------------

set.seed(123) # me aseguro que sea replicable
cl_data_split <- initial_split(cl_data, prop = 0.80)
train_data <- training(cl_data_split)
test_data <- testing(cl_data_split)

# Create pairs ------------------------------------------------------------
combinations <- expand_grid(
  response = cl_methods,
  predictor = cl_methods
) %>%
  filter(response != predictor)

# Metrics for testing 20% -------------------------------------------------

fit_lm <- function(response, predictor, train_data, test_data, intercept = TRUE) {
  
  formula <- if (intercept) {
    as.formula(paste(response, "~", predictor))
  } else {
    as.formula(paste(response, "~ 0 +", predictor))
  }
  
  mod <- lm(formula, data = train_data)
  preds <- predict(mod, newdata = test_data)
  truth <- test_data[[response]]
  
  ss_res <- sum((truth - preds)^2)
  ss_tot <- if (intercept) {
    sum((truth - mean(truth))^2)
  } else {
    sum(truth^2)
  }
  r2_manual <- 1 - ss_res / ss_tot
  
  tibble(
    response = response,
    predictor = predictor,
    intercept = intercept,
    r_squared = r2_manual,
    sigma = sd(truth - preds),
    p_value = tidy(mod)$p.value[1],
    estimate = tidy(mod)$estimate[1],
    std_error = tidy(mod)$std.error[1],
    MSE = mean((truth - preds)^2),
    MAE = mean(abs(truth - preds)),
    RMSE = sqrt(mean((truth - preds)^2)),
    MSD   = mean(preds - truth, na.rm = TRUE),                       
    MAD   = mean(abs(preds - truth), na.rm = TRUE) 
  )
}

model_results <- map2_df(combinations$response, combinations$predictor, function(y, x) {
  bind_rows(
    fit_lm(y, x, train_data, test_data, intercept = FALSE),
    fit_lm(y, x, train_data, test_data, intercept = TRUE)
  )
})

# Plot for double check ---------------------------------------------------

fit_lm_preds <- function(response, predictor, train_data, test_data, intercept = TRUE) {
  formula <- if (intercept) {
    as.formula(paste(response, "~", predictor))
  } else {
    as.formula(paste(response, "~ 0 +", predictor))
  }
  
  mod <- lm(formula, data = train_data)
  preds <- predict(mod, newdata = test_data)
  truth <- test_data[[response]]
  
  tibble(
    response  = response,
    predictor = predictor,
    intercept = intercept,
    truth     = truth,
    preds     = preds
  )
}

pred_results <- map2_df(
  combinations$response, combinations$predictor,
  \(y, x) bind_rows(
    fit_lm_preds(y, x, train_data, test_data, intercept = FALSE),
    fit_lm_preds(y, x, train_data, test_data, intercept = TRUE)
  )
)

intercepts_log <- ggplot(pred_results, aes(x = truth, y = preds, color = intercept)) +
  geom_point(alpha = 0.6, size = 2) +
  geom_abline(
    slope = 1, intercept = 0,
    linetype = "dashed", color = "gray40"
  ) +  # 1:1 reference
  geom_smooth(
    data = pred_results %>% filter(intercept),
    method = "lm", formula = y ~ x,
    se = FALSE, size = 0.8
  ) +  # regression with intercept
  geom_smooth(
    data = pred_results %>% filter(!intercept),
    method = "lm", formula = y ~ 0 + x,
    se = FALSE, size = 0.8
  ) +  # regression forced through origin
  facet_grid(response ~ predictor) +
  coord_obs_pred() +
  labs(
    title = "Observed vs Predicted (Test Set)",
    x = "Observed",
    y = "Predicted",
    color = "Intercept model"
  ) +
  theme_bw() +
  theme(
    strip.text = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

ggsave("figures/intercepts/fig_intercepts-log.tiff", intercepts_log, width = 8, height = 8)
ggsave("figures/intercepts/fig_intercepts-log.png", intercepts_log, width = 8, height = 8)

# Export docx -------------------------------------------------------------

library(flextable) # format like docx
library(officer) # export like docx

table_export <- model_results %>%
  mutate(
    Intercept = ifelse(intercept, "Yes", "No"),
    across(where(is.numeric), ~ round(., 3))
  ) %>%
  select(Response = response, Predictor = predictor, Intercept,
         `Slope` = estimate, `Std.Error` = std_error,
         `R²` = r_squared, 
         RMSE, MAE, MSE,MSD,MAD) %>%
  arrange(Response)


ft <- flextable(table_export) %>%
  theme_booktabs() %>%
  autofit() %>%
  set_caption("Table: Simple Linear Regression Models for Chloride Methods") %>%
  merge_v(j = "Response") %>%
  align(j = "Response", align = "center", part = "body") 

doc <- read_docx() %>% 
  flextable::body_add_flextable(value = ft)

print(doc, target = "docx/intercepts/models-table-intercept-log.docx")