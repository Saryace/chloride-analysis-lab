
# Libraries ---------------------------------------------------------------

library(tidymodels) # for developing models
library(tidyverse) # for data processing
library(readxl) # for loading data

# Load data from Excel ----------------------------------------------------

cl_data <- read_csv("data/Chap2.csv") 

cl_methods <- c("MT","PT","ICP","IC")

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

# Include all metrics from poster -----------------------------------------

fit_lm <- function(response, predictor, train_data, test_data, intercept = TRUE) {
  
  formula <- if (intercept) {
    as.formula(paste(response, "~", predictor))
  } else {
    as.formula(paste(response, "~ 0 +", predictor))
  }
  
  mod <- lm(formula, data = train_data)
  preds <- predict(mod, newdata = test_data)
  truth <- test_data[[response]]
  
  # Manual R2 depending on intercept
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
    RMSE = sqrt(mean((truth - preds)^2))
  )
}

model_results <- map2_df(combinations$response, combinations$predictor, function(y, x) {
  bind_rows(
    fit_lm(y, x, train_data, test_data, intercept = FALSE),
    fit_lm(y, x, train_data, test_data, intercept = TRUE)
  )
})

# Export docx -------------------------------------------------------------

library(flextable) # format like docx
library(officer) # export like docx

table_export <- model_results %>%
  mutate(
    Intercept = ifelse(intercept, "Yes", "No"),
    across(where(is.numeric), ~ round(., 4))
  ) %>%
  select(Response = response, Predictor = predictor, Intercept,
         `Slope` = estimate, `Std.Error` = std_error,
         `R²` = r_squared, 
         RMSE, MAE, MSE) %>%
  arrange(Response)

# Create flextable and group by Response (merge rows)
ft <- flextable(table_export) %>%
  theme_booktabs() %>%
  autofit() %>%
  set_caption("Table: Simple Linear Regression Models for Chloride Methods") %>%
  merge_v(j = "Response") %>%
  align(j = "Response", align = "center", part = "body") %>%
  fix_border_issues()

# Export Word document with landscape layout
doc <- read_docx() %>%
  body_add_flextable(ft) %>%
  body_end_section_landscape()

print(doc, target = "docx/models-table.docx")
