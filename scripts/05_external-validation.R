# Libraries ---------------------------------------------------------------

library(tidymodels)
library(tidyverse)
library(readxl)
library(broom)
library(flextable)
library(officer)

# External validation datasets -------------------------------------------

non_certified_data <- read_excel("data/Chap2-Rcode-DataBase.xlsx") %>%
  filter(Set != 1) %>%
  filter(if_all(everything(), ~ !grepl("[<>]", as.character(.)))) %>%
  mutate(
    across(c(MT, PT, ICP, IC, pH, EC), as.numeric),
    logMT  = log10(MT),
    logPT  = log10(PT),
    logICP = log10(ICP),
    logIC  = log10(IC),
    DataGroup = "non-certified"
  )

spill_data <- read_excel("data/Chap2-Rcode-DataBase-S5-NDSUContaminateSoil.xlsx") %>%
  filter(if_all(everything(), ~ !grepl("[<>]", as.character(.)))) %>%
  mutate(
    across(c(MT, PT, ICP, IC, pH, EC), as.numeric),
    logMT  = log10(MT),
    logPT  = log10(PT),
    logICP = log10(ICP),
    logIC  = log10(IC),
    DataGroup = "spill"
  )

# External validation function -------------------------------------------

fit_external_validation <- function(response, predictor, intercept, scale, new_data, dataset_name) {
  
  formula <- if (intercept) {
    as.formula(paste(response, "~", predictor))
  } else {
    as.formula(paste(response, "~ 0 +", predictor))
  }
  
  mod <- lm(formula, data = cl_data)
  
  preds <- predict(mod, newdata = new_data)
  truth <- new_data[[response]]
  error <- preds - truth
  
  tibble(
    Dataset = dataset_name,
    Scale = ifelse(scale == "original", "Original scale", "Log scale"),
    Response = response,
    Predictor = predictor,
    `Regression model` = ifelse(intercept, "With intercept", "Forced through origin"),
    N = sum(!is.na(truth) & !is.na(preds)),
    RMSE = sqrt(mean(error^2, na.rm = TRUE)),
    MAE  = mean(abs(error), na.rm = TRUE),
    MSE  = mean(error^2, na.rm = TRUE),
    MSD  = mean(error, na.rm = TRUE),
    MAD  = mean(abs(error), na.rm = TRUE),
    RMSD = sqrt(mean(error^2, na.rm = TRUE))
  )
}

# External validation: non-certified -------------------------------------

external_non_certified <- pmap_df(
  list(best_models$response, best_models$predictor, best_models$intercept, best_models$scale),
  function(y, x, i, s) {
    fit_external_validation(
      response = y,
      predictor = x,
      intercept = i,
      scale = s,
      new_data = non_certified_data,
      dataset_name = "Non-certified"
    )
  }
)

# External validation: spill ---------------------------------------------

external_spill <- pmap_df(
  list(best_models$response, best_models$predictor, best_models$intercept, best_models$scale),
  function(y, x, i, s) {
    fit_external_validation(
      response = y,
      predictor = x,
      intercept = i,
      scale = s,
      new_data = spill_data,
      dataset_name = "Spill"
    )
  }
)

# Combine results ---------------------------------------------------------

external_results <- bind_rows(external_non_certified, external_spill) %>%
  mutate(across(where(is.numeric), ~ round(., 3))) %>%
  arrange(Dataset, Scale, Response, RMSE)

# Split tables ------------------------------------------------------------

external_non_certified_original <- external_results %>%
  filter(Dataset == "Non-certified", Scale == "Original scale") %>%
  dplyr::select(-Dataset, -Scale)

external_non_certified_log <- external_results %>%
  filter(Dataset == "Non-certified", Scale == "Log scale") %>%
  dplyr::select(-Dataset, -Scale)

external_spill_original <- external_results %>%
  filter(Dataset == "Spill", Scale == "Original scale") %>%
  dplyr::select(-Dataset, -Scale)

external_spill_log <- external_results %>%
  filter(Dataset == "Spill", Scale == "Log scale") %>%
  dplyr::select(-Dataset, -Scale)

# Prediction data for plots ----------------------------------------------

get_external_preds <- function(response, predictor, intercept, scale, new_data, dataset_name) {
  
  formula <- if (intercept) {
    as.formula(paste(response, "~", predictor))
  } else {
    as.formula(paste(response, "~ 0 +", predictor))
  }
  
  mod <- lm(formula, data = cl_data)
  
  preds <- predict(mod, newdata = new_data)
  truth <- new_data[[response]]
  
  tibble(
    Dataset = dataset_name,
    scale = scale,
    response = response,
    predictor = predictor,
    intercept = intercept,
    model_type = ifelse(intercept, "With intercept", "Forced through origin"),
    truth = truth,
    preds = preds
  )
}

external_preds_non_certified <- pmap_df(
  list(best_models$response, best_models$predictor, best_models$intercept, best_models$scale),
  function(y, x, i, s) {
    get_external_preds(y, x, i, s, non_certified_data, "Non-certified")
  }
)

external_preds_spill <- pmap_df(
  list(best_models$response, best_models$predictor, best_models$intercept, best_models$scale),
  function(y, x, i, s) {
    get_external_preds(y, x, i, s, spill_data, "Spill")
  }
)

external_preds <- bind_rows(external_preds_non_certified, external_preds_spill)

# Plot: non-certified original -------------------------------------------

plot_non_certified_original <- external_preds %>%
  filter(Dataset == "Non-certified", scale == "original") %>%
  ggplot(aes(x = truth, y = preds, color = model_type)) +
  geom_point(alpha = 0.6, size = 2) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray40") +
  facet_grid(response ~ predictor) +
  coord_obs_pred() +
  labs(
    title = "External validation (Non-certified – Original scale)",
    x = "Observed",
    y = "Predicted",
    color = "Regression model"
  ) +
  theme_bw()

ggsave(
  "figures/external-validation/fig_non_certified_original.png",
  plot_non_certified_original,
  width = 8, height = 8, dpi = 300
)

ggsave(
  "figures/external-validation/fig_non_certified_original.tiff",
  plot_non_certified_original,
  width = 8, height = 8, dpi = 300
)

# Plot: non-certified log ------------------------------------------------

plot_non_certified_log <- external_preds %>%
  filter(Dataset == "Non-certified", scale == "log") %>%
  ggplot(aes(x = truth, y = preds, color = model_type)) +
  geom_point(alpha = 0.6, size = 2) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray40") +
  facet_grid(response ~ predictor) +
  coord_obs_pred() +
  labs(
    title = "External validation (Non-certified – Log scale)",
    x = "Observed",
    y = "Predicted",
    color = "Regression model"
  ) +
  theme_bw()

ggsave(
  "figures/external-validation/fig_non_certified_log.png",
  plot_non_certified_log,
  width = 8, height = 8, dpi = 300
)

ggsave(
  "figures/external-validation/fig_non_certified_log.tiff",
  plot_non_certified_log,
  width = 8, height = 8, dpi = 300
)

# Plot: spill original ---------------------------------------------------

plot_spill_original <- external_preds %>%
  filter(Dataset == "Spill", scale == "original") %>%
  ggplot(aes(x = truth, y = preds, color = model_type)) +
  geom_point(alpha = 0.6, size = 2) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray40") +
  facet_grid(response ~ predictor) +
  coord_obs_pred() +
  labs(
    title = "External validation (Spill – Original scale)",
    x = "Observed",
    y = "Predicted",
    color = "Regression model"
  ) +
  theme_bw()

ggsave(
  "figures/external-validation/fig_spill_original.png",
  plot_spill_original,
  width = 8, height = 8, dpi = 300
)

ggsave(
  "figures/external-validation/fig_spill_original.tiff",
  plot_spill_original,
  width = 8, height = 8, dpi = 300
)

# Plot: spill log --------------------------------------------------------

plot_spill_log <- external_preds %>%
  filter(Dataset == "Spill", scale == "log") %>%
  ggplot(aes(x = truth, y = preds, color = model_type)) +
  geom_point(alpha = 0.6, size = 2) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray40") +
  facet_grid(response ~ predictor) +
  coord_obs_pred() +
  labs(
    title = "External validation (Spill – Log scale)",
    x = "Observed",
    y = "Predicted",
    color = "Regression model"
  ) +
  theme_bw()

ggsave(
  "figures/external-validation/fig_spill_log.png",
  plot_spill_log,
  width = 8, height = 8, dpi = 300
)

ggsave(
  "figures/external-validation/fig_spill_log.tiff",
  plot_spill_log,
  width = 8, height = 8, dpi = 300
)

# DOCX export: non-certified ---------------------------------------------

ft_non_certified_original <- flextable(external_non_certified_original) %>%
  theme_booktabs() %>%
  autofit() %>%
  set_caption("External validation of selected models using non-certified samples (Original scale)")

ft_non_certified_log <- flextable(external_non_certified_log) %>%
  theme_booktabs() %>%
  autofit() %>%
  set_caption("External validation of selected models using non-certified samples (Log scale)")

doc_non_certified <- read_docx() %>%
  body_add_par(
    "Selected models were trained on certified samples and externally evaluated on non-certified samples.",
    style = "Normal"
  ) %>%
  body_add_par("", style = "Normal") %>%
  flextable::body_add_flextable(value = ft_non_certified_original) %>%
  body_add_par("", style = "Normal") %>%
  flextable::body_add_flextable(value = ft_non_certified_log)

print(doc_non_certified, target = "docx/external-validation/non-certified-external-validation.docx")

# DOCX export: spill -----------------------------------------------------

ft_spill_original <- flextable(external_spill_original) %>%
  theme_booktabs() %>%
  autofit() %>%
  set_caption("External validation of selected models using spill samples (Original scale)")

ft_spill_log <- flextable(external_spill_log) %>%
  theme_booktabs() %>%
  autofit() %>%
  set_caption("External validation of selected models using spill samples (Log scale)")

doc_spill <- read_docx() %>%
  body_add_par(
    "Selected models were trained on certified samples and externally evaluated on spill samples.",
    style = "Normal"
  ) %>%
  body_add_par("", style = "Normal") %>%
  flextable::body_add_flextable(value = ft_spill_original) %>%
  body_add_par("", style = "Normal") %>%
  flextable::body_add_flextable(value = ft_spill_log)

print(doc_spill, target = "docx/external-validation/spill-external-validation.docx")