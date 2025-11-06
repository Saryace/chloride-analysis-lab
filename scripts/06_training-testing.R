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
library(ggrepel)
library(patchwork)

# Load data ---------------------------------------------------------------
# Only Set 1 certified samples
cl_data_noSP_set_one <- read_csv("data/Chap2.csv") %>% 
  filter(Set == 1) %>% 
  select(-SP,-logSP,-ID,-Set)

# Split -------------------------------------------------------------------
set.seed(123)  
new_split <- initial_split(cl_data_noSP_set_one, prop = 0.80)
new_train <- training(new_split)
new_test <- testing(new_split)

# Models ------------------------------------------------------------------

responses <- c("MT", "PT", "ICP", "IC")

formulas_mixed <- map_dfr(responses, function(response) {
  predictors <- setdiff(responses, response)  # exclude same model
  expand_grid(
    response = response,
    main_predictor = predictors
  ) %>%
    mutate(
      formula = paste(response, "~", main_predictor)
    )
}) %>%
  distinct(formula, .keep_all = TRUE)

formulas_mixed

# train -------------------------------------------------------------------

formulas <- formulas_mixed$formula

lm_models <- map(formulas, ~ {
  rec <- recipe(as.formula(.x), data = new_train)
  workflow() %>%
    add_model(linear_reg() %>% set_engine("lm")) %>%
    add_recipe(rec) %>%
    fit(data = new_train)
})

names(lm_models) <- formulas

# testing -----------------------------------------------------------------

test_results <- map2_dfr(
  lm_models,
  names(lm_models),
  function(model, fml) {
    response <- str_extract(fml, "^[^~]+") %>% str_trim()
    preds <- predict(model, new_data = new_test) %>%
      bind_cols(new_test %>% select(all_of(response))) %>%
      rename(truth = !!sym(response))
    metrics(preds, truth = truth, estimate = .pred) %>%
      mutate(model = fml, response = response)
  }
)

# ggplot ------------------------------------------------------------------

plot_data <- map2_dfr(lm_models, names(lm_models), function(model, fml) {
  response <- str_extract(fml, "^[^~]+") %>% str_trim()
  predict(model, new_data = new_test) %>%
    bind_cols(truth = new_test[[response]]) %>%
    mutate(model = fml, response = response)
}) %>% 
  mutate(
    response_var = str_extract(model, "^[^~]+") %>% str_trim(),
    predictor_var = str_extract(model, "(?<=~ ).*$") %>% str_trim(),
    input_var = str_extract(predictor_var, "^[^+]+") %>% str_trim(),
    output_method = paste0(response_var, " ~ ", input_var)
  ) 

labels_ggplot <- test_results %>%
  filter(.metric %in% c("rsq", "rmse")) %>%
  select(model, .metric, .estimate) %>%
  pivot_wider(names_from = .metric, values_from = .estimate) %>%
  mutate(
    label = paste0("R² = ", round(rsq, 3), "\nRMSE = ", comma(rmse, accuracy = 0.001))
  ) %>% 
  mutate(
    response_var = str_extract(model, "^[^~]+") %>% str_trim(),
    predictor_var = str_extract(model, "(?<=~ ).*$") %>% str_trim(),
    input_var = str_extract(predictor_var, "^[^+]+") %>% str_trim(),
    output_method = paste0(response_var, " ~ ", input_var)
  ) %>% 
  group_by(output_method) 

obs_pred <- ggplot(plot_data, aes(x = .pred, y = truth)) +
  geom_point(color = "grey50", alpha = 0.5) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  facet_wrap(vars(output_method), ncol = 3) +
  coord_obs_pred() +
  geom_text(
    data = labels_ggplot,
    aes(x = -Inf, y = 50, label = label),
    inherit.aes = FALSE,
    hjust = -0.05,
    size = 3,
    show.legend = FALSE
  ) +
  labs(
    x = "Predicted (ppm)",
    y = "Observed (ppm)"
  ) +
  theme_bw() +
  theme(
    strip.text = element_text(size = 8, face = "bold"),
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(size = 8),
    panel.grid.minor = element_blank()
  )

ggsave("figures/model-performance/testing_set_one.tiff", obs_pred, width = 8, height = 8)
ggsave("figures/model-performance/testing_set_one.png", obs_pred, width = 8, height = 8)


# Performance training set 1 ----------------------------------------------

compute_metrics <- function(truth, pred) {
  tibble::tibble(
    n     = length(truth),
    R2    = yardstick::rsq_vec(truth = truth, estimate = pred),
    RMSE  = yardstick::rmse_vec(truth = truth, estimate = pred),
    MAE   = yardstick::mae_vec(truth = truth, estimate = pred),
    MSE  = mean((pred - truth)^2, na.rm = TRUE),
    MSD   = mean(pred - truth, na.rm = TRUE),                       
    MAD   = mean(abs(pred - truth), na.rm = TRUE),                  
    MRSD  = mean((pred - truth) / truth, na.rm = TRUE))            
}

# Check new test 20% set one ----------------------------------------------

perf_table <- purrr::map2_dfr(
  lm_models, names(lm_models),
  function(model, fml) {
    response <- stringr::str_extract(fml, "^[^~]+") %>% stringr::str_trim()
    
    preds <- predict(model, new_data = new_test) %>%
      dplyr::bind_cols(new_test %>% dplyr::select(dplyr::all_of(response))) %>%
      dplyr::rename(truth = !!rlang::sym(response)) %>%
      dplyr::mutate(model = fml)
    out <- compute_metrics(truth = preds$truth, pred = preds$.pred)
    out %>%
      dplyr::mutate(
        model   = fml,
        response_var  = stringr::str_extract(fml, "^[^~]+") %>% stringr::str_trim(),
        predictor_var = stringr::str_extract(fml, "(?<=~ ).*$") %>% stringr::str_trim()
      ) %>%
      dplyr::relocate(model, response_var, predictor_var)
  }
) %>%
  dplyr::arrange(dplyr::desc(R2))

perf_table

perf_ft <- perf_table %>%
  dplyr::mutate(
    R2    = round(R2, 3),
    RMSE  = round(RMSE, 3),
    MAE   = round(MAE, 3),
    MSE   = round(MSE, 3),
    MSD   = round(MSD, 3),
    MAD   = round(MAD, 3),
    MRSD  = round(MRSD, 3)) %>% 
  flextable::flextable() %>%
  flextable::autofit()

perf_ft

# Export to Word
doc <- officer::read_docx() %>%
  body_add_flextable(perf_ft)
print(doc, target = "docx/model-performance/performance_set1.docx")

