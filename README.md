## Update 10/22/2025
| Script               | Objective                                                                                                                                                                              | Outputs                                                                                       |
|----------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| **01_descriptive-table.R** | Compute descriptive statistics for each method (MT, PT, ICP, IC) by set                                                                                                               | `docx/stat-per-set.docx`  <br> `docx/stat-per-set-log.docx`                                   |
| **02_post-hoc.R**          | Perform Dunn test pairwise comparisons for raw and log variables                                                                                                                     | `docx/post-hoc-table.docx`                                                                     |
| **03_correlation.R**       | Create GGally pairplots colored by set (raw and log variables)                                                                                                                       | `figures/fig_corr.tiff`  <br> `figures/fig_corr_log.tiff`  <br> `figures/fig_corr.png`  <br> `figures/fig_corr_log.png` |
| **04_intercepts.R**        | Fit linear regressions (Method ~ Method) with and without intercept; evaluate performance (20% test data) including slope, SE, R², RMSE, MAE, MSE, MSD, MAD, MRSD                    | `docx/models-table-intercept.docx`                                                             |
| **05_intercepts_log.R**    | Same as above using log-transformed variables; compare with and without intercept, compute performance metrics (R², RMSE, MAE, MSE, MSD, MAD, MRSD)                                 | `docx/models-table-intercept-log.docx`                                                         |
| **06_training-testing.R**  | Train models on Set 1 (80%) and test on 20%; compute R², RMSE, MAE, MSE, MSD, MAD, MRSD; visualize observed vs predicted                        | `figures/testing_set_one.tiff`  <br> `figures/testing_set_one.png`  <br> `docx/performance_set1.docx` |
| **07_validation.R**        | Evaluate external validation (Sets 2–5) for all linear models (Method ~ Method); plot observed vs predicted and export per-Set performance tables (R², RMSE, MAE, MSD, MAD, MRSD) | `figures/validation_png/obs_pred_external_<response>~<predictor>.png`  <br> `figures/validation_tiff/obs_pred_external_<response>~<predictor>.tiff`  <br> `docx/performance_validation_by_set.docx` |

## Figures

### Correlation all method (colors are differents dataset). TIFF available for better quality and publication-ready format

![](/figures/fig_corr.png)

### Correlation all method log-transformed (colors are differents dataset)

![](/figures/fig_corr_log.png)

### Observed vs. predicted methods

![](/figures/testing_set_one.png)
