# Libraries ---------------------------------------------------------------

library(tidymodels)
library(tidyverse)
library(readxl)
library(broom)
library(flextable)
library(officer)

# Load data ---------------------------------------------------------------

certified_data <- read_excel("data/Chap2-Rcode-DataBase.xlsx") %>%
  filter(Set == 1) %>%
  mutate(
    across(c(MT, PT, ICP, IC, pH, EC), as.numeric),
    logMT  = log10(MT),
    logPT  = log10(PT),
    logICP = log10(ICP),
    logIC  = log10(IC),
    DataGroup = "certified"
  )

cl_data <- certified_data %>%
  dplyr::select(-DataGroup)

# Variables ---------------------------------------------------------------

cl_methods <- c("MT", "PT", "ICP", "IC")
cl_methods_log <- c("logMT", "logPT", "logICP", "logIC")

# Create model combinations -----------------------------------------------

comb_original <- expand_grid(
  response = cl_methods,
  predictor = cl_methods
) %>%
  filter(response != predictor) %>%
  mutate(scale = "original")

comb_log <- expand_grid(
  response = cl_methods_log,
  predictor = cl_methods_log
) %>%
  filter(response != predictor) %>%
  mutate(scale = "log")

combinations <- bind_rows(comb_original, comb_log)

# Cross validation --------------------------------------------------------

set.seed(123)

folds <- vfold_cv(cl_data, v = 10)

# Cross-validated model function -----------------------------------------

fit_lm_cv <- function(response, predictor, intercept = TRUE) {
  
  formula <- if (intercept) {
    as.formula(paste(response, "~", predictor))
  } else {
    as.formula(paste(response, "~ 0 +", predictor))
  }
  
  map_df(folds$splits, function(split) {
    
    train_data <- analysis(split)
    test_data  <- assessment(split)
    
    mod <- lm(formula, data = train_data)
    
    preds <- predict(mod, newdata = test_data)
    truth <- test_data[[response]]
    
    tibble(
      RMSE = sqrt(mean((truth - preds)^2, na.rm = TRUE)),
      MAE  = mean(abs(truth - preds), na.rm = TRUE),
      MSE  = mean((truth - preds)^2, na.rm = TRUE),
      MSD  = mean(truth - preds, na.rm = TRUE),        # bias (signed)
      MAD  = median(abs(truth - preds), na.rm = TRUE)  # robust
    )
    
  }) %>%
    summarise(
      RMSE = mean(RMSE, na.rm = TRUE),
      MAE  = mean(MAE,  na.rm = TRUE),
      MSE  = mean(MSE,  na.rm = TRUE),
      MSD  = mean(MSD,  na.rm = TRUE),
      MAD  = mean(MAD,  na.rm = TRUE)
    ) %>% 
    mutate(
      response = response,
      predictor = predictor,
      intercept = intercept
    )
}

# Run all models ----------------------------------------------------------

model_results <- pmap_df(
  list(combinations$response, combinations$predictor, combinations$scale),
  function(y, x, s) {
    
    bind_rows(
      fit_lm_cv(y, x, TRUE),
      fit_lm_cv(y, x, FALSE)
    ) %>%
      mutate(scale = s)
    
  }
)

# Rank all models ---------------------------------------------------------

model_results <- model_results %>%
  arrange(scale, response, predictor, RMSE)

# dplyr::select best model within each pairwise combination ----------------------

best_models <- model_results %>%
  group_by(scale, response, predictor) %>%
  slice_min(order_by = RMSE, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  arrange(scale, response, RMSE)

# Prediction dataset for plots (all models) -------------------------------

fit_lm_preds <- function(response, predictor, intercept = TRUE) {
  
  formula <- if (intercept) {
    as.formula(paste(response, "~", predictor))
  } else {
    as.formula(paste(response, "~ 0 +", predictor))
  }
  
  mod <- lm(formula, data = cl_data)
  
  preds <- predict(mod, newdata = cl_data)
  truth <- cl_data[[response]]
  
  tibble(
    response = response,
    predictor = predictor,
    intercept = intercept,
    truth = truth,
    preds = preds
  )
}

pred_results <- pmap_df(
  list(combinations$response, combinations$predictor, combinations$scale),
  function(y, x, s) {
    
    bind_rows(
      fit_lm_preds(y, x, TRUE),
      fit_lm_preds(y, x, FALSE)
    ) %>%
      mutate(scale = s)
    
  }
) %>%
  mutate(
    model_type = ifelse(
      intercept,
      "With intercept",
      "Forced through origin"
    )
  )

# Split prediction results ------------------------------------------------

pred_results_original <- pred_results %>%
  filter(scale == "original")

pred_results_log <- pred_results %>%
  filter(scale == "log")

# Observed vs predicted plot: original ------------------------------------

intercepts_original <- ggplot(
  pred_results_original,
  aes(x = truth, y = preds, color = model_type)
) +
  geom_point(alpha = 0.6, size = 2) +
  geom_abline(
    slope = 1, intercept = 0,
    linetype = "dashed", color = "gray40"
  ) +
  geom_smooth(
    data = pred_results_original %>% filter(intercept),
    method = "lm",
    formula = y ~ x,
    se = FALSE,
    linewidth = 0.8
  ) +
  geom_smooth(
    data = pred_results_original %>% filter(!intercept),
    method = "lm",
    formula = y ~ 0 + x,
    se = FALSE,
    linewidth = 0.8
  ) +
  facet_grid(response ~ predictor) +
  coord_obs_pred() +
  labs(
    title = "Observed vs Predicted (Certified Soil Samples – Original scale)",
    x = "Observed",
    y = "Predicted",
    color = "Regression model"
  ) +
  theme_bw() +
  theme(
    strip.text = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

ggsave(
  "figures/model-training/fig_model_original.png",
  intercepts_original,
  width = 8, height = 8, dpi = 300
)

ggsave(
  "figures/model-training/fig_model_original.tiff",
  intercepts_original,
  width = 8, height = 8, dpi = 300
)

# Observed vs predicted plot: log -----------------------------------------

intercepts_log <- ggplot(
  pred_results_log,
  aes(x = truth, y = preds, color = model_type)
) +
  geom_point(alpha = 0.6, size = 2) +
  geom_abline(
    slope = 1, intercept = 0,
    linetype = "dashed", color = "gray40"
  ) +
  geom_smooth(
    data = pred_results_log %>% filter(intercept),
    method = "lm",
    formula = y ~ x,
    se = FALSE,
    linewidth = 0.8
  ) +
  geom_smooth(
    data = pred_results_log %>% filter(!intercept),
    method = "lm",
    formula = y ~ 0 + x,
    se = FALSE,
    linewidth = 0.8
  ) +
  facet_grid(response ~ predictor) +
  coord_obs_pred() +
  labs(
    title = "Observed vs Predicted (Certified Soil Samples – Log scale)",
    x = "Observed",
    y = "Predicted",
    color = "Regression model"
  ) +
  theme_bw() +
  theme(
    strip.text = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

ggsave(
  "figures/model-training/fig_model_log.png",
  intercepts_log,
  width = 8, height = 8, dpi = 300
)

ggsave(
  "figures/model-training/fig_model_log.tiff",
  intercepts_log,
  width = 8, height = 8, dpi = 300
)

# Extract slopes for all models -------------------------------------------

coef_results <- pmap_df(
  list(combinations$response, combinations$predictor, combinations$scale),
  function(y, x, s) {
    
    bind_rows(
      
      broom::tidy(
        lm(as.formula(paste(y, "~", x)), data = cl_data)
      ) %>%
        filter(term == x) %>%
        mutate(
          response = y,
          predictor = x,
          intercept = TRUE,
          scale = s
        ),
      
      broom::tidy(
        lm(as.formula(paste(y, "~ 0 +", x)), data = cl_data)
      ) %>%
        filter(term == x) %>%
        mutate(
          response = y,
          predictor = x,
          intercept = FALSE,
          scale = s
        )
      
    )
    
  }
)

# Merge coefficients + CV metrics ----------------------------------------

table_export <- model_results %>%
  left_join(
    coef_results %>%
      dplyr::select(response, predictor, intercept, scale, estimate, std.error),
    by = c("response", "predictor", "intercept", "scale")
  ) %>%
  mutate(
    `Regression model` = ifelse(
      intercept,
      "With intercept",
      "Forced through origin"
    ),
    Scale = ifelse(scale == "original", "Original scale", "Log scale"),
    across(where(is.numeric), ~ round(., 3))
  ) %>%
  dplyr::select(
    Scale,
    Response = response,
    Predictor = predictor,
    `Regression model`,
    `Slope` = estimate,
    `Std.Error` = std.error,
    RMSE,
    MAE,
    MSE,
    MSD,  
    MAD 
  ) %>%
  arrange(Scale, Response, Predictor, RMSE)

# Best-model table --------------------------------------------------------

best_table_export <- best_models %>%
  left_join(
    coef_results %>%
      dplyr::select(response, predictor, intercept, scale, estimate, std.error),
    by = c("response", "predictor", "intercept", "scale")
  ) %>%
  mutate(
    `Regression model` = ifelse(
      intercept,
      "With intercept",
      "Forced through origin"
    ),
    Scale = ifelse(scale == "original", "Original scale", "Log scale"),
    across(where(is.numeric), ~ round(., 3))
  ) %>%
  dplyr::select(
    Scale,
    Response = response,
    Predictor = predictor,
    `Regression model`,
    `Slope` = estimate,
    `Std.Error` = std.error,
    RMSE,
    MAE,
    MSE,
    MSD,  
    MAD 
  ) %>%
  arrange(Scale, Response, RMSE)

# Split all-model table ---------------------------------------------------

table_export_original <- table_export %>%
  filter(Scale == "Original scale") %>%
  dplyr::select(-Scale)

table_export_log <- table_export %>%
  filter(Scale == "Log scale") %>%
  dplyr::select(-Scale)

# Split best-model table --------------------------------------------------

best_table_export_original <- best_table_export %>%
  filter(Scale == "Original scale") %>%
  dplyr::select(-Scale)

best_table_export_log <- best_table_export %>%
  filter(Scale == "Log scale") %>%
  dplyr::select(-Scale)

# Export DOCX: all models -------------------------------------------------

ft_original <- flextable(table_export_original) %>%
  theme_booktabs() %>%
  autofit() %>%
  set_caption(
    "Cross-validated linear regression models for chloride analytical methods (Original scale)"
  ) %>%
  merge_v(j = "Response") %>%
  align(j = "Response", align = "center", part = "body")

ft_log <- flextable(table_export_log) %>%
  theme_booktabs() %>%
  autofit() %>%
  set_caption(
    "Cross-validated linear regression models for chloride analytical methods (Log scale)"
  ) %>%
  merge_v(j = "Response") %>%
  align(j = "Response", align = "center", part = "body")

doc_all <- read_docx() %>%
  body_add_par("", style = "Normal") %>%
  flextable::body_add_flextable(value = ft_original) %>%
  body_add_par("", style = "Normal") %>%
  flextable::body_add_flextable(value = ft_log)

print(doc_all, target = "docx/model-training/models-table-intercept-all.docx")

# Export DOCX: best models only ------------------------------------------

ft_best_original <- flextable(best_table_export_original) %>%
  theme_booktabs() %>%
  autofit() %>%
  set_caption(
    "Best cross-validated linear regression model for each chloride method pair (Original scale)"
  ) %>%
  merge_v(j = "Response") %>%
  align(j = "Response", align = "center", part = "body")

ft_best_log <- flextable(best_table_export_log) %>%
  theme_booktabs() %>%
  autofit() %>%
  set_caption(
    "Best cross-validated linear regression model for each chloride method pair (Log scale)"
  ) %>%
  merge_v(j = "Response") %>%
  align(j = "Response", align = "center", part = "body")

doc_best <- read_docx() %>%
  body_add_par("", style = "Normal") %>%
  flextable::body_add_flextable(value = ft_best_original) %>%
  body_add_par("", style = "Normal") %>%
  flextable::body_add_flextable(value = ft_best_log)

print(doc_best, target = "docx/model-training/models-table-best-per-pair.docx")