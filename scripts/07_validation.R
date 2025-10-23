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
# Only Set 2 to Set 5 for validation

cl_data_noSP_set_two_to_five <- read_csv("data/Chap2.csv") %>% 
  filter(Set != 1) %>% 
  mutate(Set = as.character(Set)) %>% 
  select(-SP,-logSP,-ID)

# Validation --------------------------------------------------------------

val_results_by_set <- map2_dfr(
  lm_models,
  names(lm_models),
  function(model, fml) {
    response <- str_extract(fml, "^[^~]+") %>% str_trim()
    
    preds <- predict(model, new_data = cl_data_noSP_set_two_to_five) %>%
      bind_cols(
        cl_data_noSP_set_two_to_five %>% select(Description, all_of(response))
      ) %>%
      rename(truth = !!sym(response))
    
    yardstick_met <- preds %>%
      group_by(Description) %>%
      metrics(truth = truth, estimate = .pred) %>%
      ungroup()
    
    custom_met <- preds %>%
      group_by(Description) %>%
      summarise(
        MSD  = mean(.pred - truth, na.rm = TRUE),
        MAD  = mean(abs(.pred - truth), na.rm = TRUE),
        MRSD = 100 * mean((.pred - truth) / truth, na.rm = TRUE)  # %
      ) %>%
      pivot_longer(cols = c(MSD, MAD, MRSD),
                   names_to = ".metric",
                   values_to = ".estimate") %>%
      ungroup()
    
    bind_rows(yardstick_met, custom_met) %>%
      mutate(
        dataset  = "external_validation",
        model    = fml,
        response = response
      )
  }
)

# Ver solo rsq, rmse, MSD, MAD, MRSD y ordenado
val_results_by_set %>%
  filter(.metric %in% c("rsq", "rmse", "MSD", "MAD", "MRSD")) %>%
  select(-.estimator,-dataset,-response)


# -------------------------------------------------------------------------
val_plot_data_by_set <- purrr::map2_dfr(lm_models, names(lm_models), function(model, fml) {
  response <- stringr::str_extract(fml, "^[^~]+") %>% stringr::str_trim()
  
  predict(model, new_data = cl_data_noSP_set_two_to_five) %>%
    dplyr::bind_cols(
      cl_data_noSP_set_two_to_five %>% dplyr::select(Description, dplyr::all_of(response))
    ) %>%
    dplyr::rename(truth = !!rlang::sym(response)) %>%
    dplyr::mutate(model = fml,
                  output_method = fml)
})

# Plots -------------------------------------------------------------------

okabe_ito <- c("#000000","#E69F00","#56B4E9","#009E73",
               "#F0E442","#0072B2","#D55E00","#CC79A7")

methods <- unique(val_plot_data_by_set$output_method)

plots_by_method <- map(methods, function(mth) {
  df_m  <- filter(val_plot_data_by_set, output_method == mth)
  
  ggplot(df_m, aes(x = .pred, y = truth, color = Description)) +
    geom_point(alpha = 0.65, size = 1.3) +
    geom_abline() +
    coord_obs_pred() +                           
    scale_color_manual(values = okabe_ito) +
    labs(
      x = "Predicted (ppm)",
      y = "Observed (ppm)",
      color = "Description",
      title = mth
    ) +
    theme_bw() +
    theme(
      legend.position = "bottom",
      legend.title = element_blank(),
      panel.grid.minor = element_blank(),
      plot.title  = element_text(face = "bold", size = 10),
      plot.subtitle = element_text(size = 8),
      plot.margin = margin(t = 6, r = 8, b = 6, l = 10)
    )
})

names(plots_by_method) <- methods

# Iwalk each plot  --------------------------------------------------------

invisible(iwalk(plots_by_method, function(p, mth) {
  ggsave(paste0("figures/validation_png/obs_pred_external_", mth, ".png"),  p, width = 8, height = 6, dpi = 300)
  ggsave(paste0("figures/validation_tiff/obs_pred_external_", mth, ".tiff"), p, width = 8, height = 6, dpi = 300, compression = "lzw")
}))

# Performance training set 1 ----------------------------------------------

compute_metrics <- function(truth, pred) {
  tibble::tibble(
    n     = length(truth),
    R2    = yardstick::rsq_vec(truth = truth, estimate = pred),
    RMSE  = yardstick::rmse_vec(truth = truth, estimate = pred),
    MAE   = yardstick::mae_vec(truth = truth, estimate = pred),
    MSD   = mean(pred - truth, na.rm = TRUE),                       
    MAD   = mean(abs(pred - truth), na.rm = TRUE),                  
    MRSD  = mean((pred - truth) / truth, na.rm = TRUE))            
}

# Performance metrics using Set 2 - Set 5 ---------------------------------

val_perf_table_by_set <- purrr::map2_dfr(
  lm_models, names(lm_models),
  function(model, fml) {
    response <- stringr::str_extract(fml, "^[^~]+") %>% stringr::str_trim()
    
    preds <- predict(model, new_data = cl_data_noSP_set_two_to_five) %>%
      dplyr::bind_cols(
        cl_data_noSP_set_two_to_five %>%
          dplyr::select(Set, dplyr::all_of(response))
      ) %>%
      dplyr::rename(truth = !!rlang::sym(response)) %>%
      dplyr::mutate(model = fml)
    
    preds %>%
      dplyr::group_by(Set) %>%
      dplyr::reframe(compute_metrics(truth = truth, pred = .pred)) %>%
      dplyr::mutate(
        model         = fml,
        response_var  = stringr::str_extract(fml, "^[^~]+") %>% stringr::str_trim(),
        predictor_var = stringr::str_extract(fml, "(?<=~ ).*$") %>% stringr::str_trim()
      ) %>%
      dplyr::relocate(Set, model, response_var, predictor_var)
  }
) %>%
  dplyr::arrange(Set, dplyr::desc(R2))

val_perf_table_by_set

# Create word -------------------------------------------------------------

doc <- officer::read_docx()

for (s in sort(unique(val_perf_table_by_set$Set))) {
  subtbl <- val_perf_table_by_set %>%
    dplyr::filter(Set == s) %>%
    dplyr::select(-n) 
  
  ft <- subtbl %>%
    flextable::flextable() %>%
    flextable::colformat_num(
      digits = 3        # show 3 decimals in Word
    ) %>%
    flextable::autofit()
  
  doc <- doc %>%
    officer::body_add_par(paste0("Set ", s)) %>%
    flextable::body_add_flextable(value = ft) %>%
    officer::body_add_par("")  }

print(doc, target = "docx/performance_validation_by_set.docx")

