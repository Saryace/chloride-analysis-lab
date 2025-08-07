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

# Load data ---------------------------------------------------------------

cl_data_noSP <- read_csv("data/Chap2.csv") %>% 
  select(-SP,-logSP,-ID,-Set)

# Split -------------------------------------------------------------------

set.seed(123)  
new_split <- initial_split(cl_data_noSP, prop = 0.80)
new_train <- training(new_split)
new_test <- testing(new_split)


# Models ------------------------------------------------------------------

responses <- c("MT", "PT", "ICP", "IC")
base_covariates <- c("", "pH", "EC", "pH + EC")

# Create formulas: response ~ other_log_method (+ optional covariates)
formulas_mixed <- map_dfr(responses, function(response) {
  predictors <- setdiff(responses, response)  # exclude self
  
  expand_grid(
    response = response,
    main_predictor = predictors,
    cov = base_covariates
  ) %>%
    mutate(
      formula = str_trim(
        ifelse(cov == "",
               paste(response, "~", main_predictor),
               paste(response, "~", paste(main_predictor, "+", cov)))
      )
    )
}) %>%
  distinct(formula, .keep_all = TRUE)

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


# train  ------------------------------------------------------------------

eval_results <- map2_dfr(
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
  predict(model, new_data = test_data) %>%
    bind_cols(truth = test_data[[response]]) %>%
    mutate(model = fml, response = response)
}) %>% 
  mutate(
    response_var = str_extract(model, "^[^~]+") %>% str_trim(),
    predictor_var = str_extract(model, "(?<=~ ).*$") %>% str_trim(),
    input_var = str_extract(predictor_var, "^[^+]+") %>% str_trim(),
    output_method = paste0(response_var, " vs. ", input_var)
  ) %>% 
  mutate(
    model_type = case_when(
      str_detect(model, "\\+ pH") & str_detect(model, "\\+ EC") ~ "+ pH + EC",
      str_detect(model, "\\+ pH") ~ "+ pH",
      str_detect(model, "\\+ EC") ~ "+ EC",
      TRUE ~ "Method ~ Method"
    )
  )

labels_ggplot <- eval_results %>%
  filter(.metric %in% c("rsq", "rmse")) %>%
  select(model, .metric, .estimate) %>%
  pivot_wider(names_from = .metric, values_from = .estimate) %>%
  mutate(
    label = paste0("R² = ", round(rsq, 2), "\nRMSE = ", comma(rmse, accuracy = 0.001))
  ) %>% 
  mutate(
    response_var = str_extract(model, "^[^~]+") %>% str_trim(),
    predictor_var = str_extract(model, "(?<=~ ).*$") %>% str_trim(),
    input_var = str_extract(predictor_var, "^[^+]+") %>% str_trim(),
    output_method = paste0(response_var, " vs. ", input_var)
  ) %>% 
  mutate(
    model_type = case_when(
      str_detect(model, "\\+ pH") & str_detect(model, "\\+ EC") ~ "+ pH + EC",
      str_detect(model, "\\+ pH") ~ "+ pH",
      str_detect(model, "\\+ EC") ~ "+ EC",
      TRUE ~ "Method ~ Method"
    )
  ) %>% 
  group_by(output_method) %>%
  arrange(model_type) %>%
  mutate(y_label = seq(from = 110, to = 40, length.out = n()))  

obs_pred <- ggplot(plot_data, aes(x = .pred, y = truth)) +
  geom_point(aes(color = model_type), alpha = 0.5) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
  facet_wrap(vars(output_method), ncol = 3) +
  scale_color_manual(values = okabe_ito) +
  geom_text(
    data = labels_ggplot,
    aes(x = -Inf, y = y_label, label = label, color = model_type),
    inherit.aes = FALSE,
    hjust = -0.05,
    size = 2,
    show.legend = FALSE
  ) +
  labs(
    x = "Predicted",
    y = "Observed",
    title = "Observed vs. Predicted (Test Set)",
    subtitle = "Linear models using methods + optional covariates all datasets"
  ) +
  coord_obs_pred() +
  theme_bw(base_size = 6) +
  theme(
    strip.text = element_text(size = 5, face = "bold"),
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(size = 6),
    panel.grid.minor = element_blank()
  )

ggsave("figures/obs_pred.tiff", obs_pred, width = 8, height = 8)
ggsave("figures/obs_pred.png", obs_pred, width = 8, height = 8)

# Coefficients ------------------------------------------------------------

coef_table <- map2_dfr(
  lm_models,
  names(lm_models),
  ~ tidy(.x) %>% mutate(model = .y)
) %>%
  mutate(
    significance = case_when(
      p.value <= 0.001 ~ "***",
      p.value <= 0.01  ~ "**",
      p.value <= 0.05  ~ "*",
      TRUE ~ "NS"
    )) %>% 
  mutate(across(where(is.numeric), ~ round(.x, 4)))

# Create flextable
coef_flex <- flextable(coef_table) %>%
  set_header_labels(
    model = "Model",
    term = "Term",
    estimate = "Estimate",
    std.error = "Std. Error",
    statistic = "t-Statistic",
    p.value = "p-Value"
  ) %>%
  autofit() %>%
  theme_booktabs() %>%
  fontsize(size = 10, part = "all")

save_as_docx(
  coef_flex,
  path = "docx/coef-table.docx"
)

