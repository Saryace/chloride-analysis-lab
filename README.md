## Update 06/08/2025

| Script                         | Objetive                                                                                                                                                                                                                                                                                                                                                                              |
|----------------------|--------------------------------------------------|
| 01_descriptive.R               | Correlation Tables + Summary Stats + Levene Test + Kruskal-Wallis + PostHoc. Significance stars were assigned based on p-values: ´`***´` for p ≤ 0.001, ´`**´` for p ≤ 0.01, ´`*´` for p ≤ 0.05, and `NS` for non-significant results (p \> 0.05). Outputs: fig_corr.tiff, fig_corr_log.tiff, stats: stat-per-set-log.docx, stat-per-set.docx, posthoc:post-hoc-table.docx            |
| 02_intercept_log.R             | Fits and evaluates all pairwise linear models between log-transformed chloride methods using train/test split 80/20 (set 1). Intercept "Yes" means y=β0​+β1​x, while intercept "No" means forced to zero y=β1​x. Output: models-table-log.docx                                                                                                                                           |
| 03_intercept.R                 | Fits and evaluates all pairwise linear models between log-transformed chloride methods using train/test split 80/20 (set 1). Intercept "Yes" means y=β0​+β1​x, while intercept "No" means forced to zero y=β1​x. Output: models-table.docx                                                                                                                                               |
| 04_prediction-alldataset-log.R | Fits linear models to predict log-transformed chloride methods, with optional covariates (pH, EC) and tests them on a 20% holdout set for all datasets. Output:obs_pred_log.tiff, coef_table_log.docx, with significance stars per term assigned based on p-values: ´`***´` for p ≤ 0.001, ´`**´` for p ≤ 0.01, ´`*´` for p ≤ 0.05, and `NS` for non-significant results (p \> 0.05). |
| 05_prediction-alldataset.R     | Fits linear models to predict chloride methods, with optional covariates (pH, EC) and tests them on a 20% holdout set for all datasets. Output: obs_pred.tiff, coef_table.docx with significance stars per term assigned based on p-values: ´`***´` for p ≤ 0.001, ´`**´` for p ≤ 0.01, ´`*´` for p ≤ 0.05, and `NS` for non-significant results (p \> 0.05).                         |

## DOCX files

1.  stat-per-set : Summary stats for each method, pH and EC for different sets
2.  stat-per-set-log : Summary stats for each method (log), pH and EC for different sets
3.  post-hoc-table: Post-Hoc Krustal for differences bewteen methods (Dunn's test)
4.  models-table: Data for models: Method A = Method B
5.  models-table-log: Data for models (log) Method A = Method B
6.  coef-table: coefficients for each model including pH and CE
7.  coef-table-log: coefficients for each model (log) including pH and CE

## Figures

### Correlation all method (colors are differents dataset). TIFF available for better quality and publication-ready format

![](/figures/fig_corr.png)

### Correlation all method log-transformed (colors are differents dataset)

![](/figures/fig_corr_log.png)

### Observed vs. predicted methods

![](/figures/obs_pred.png)

### Observed vs. predicted log-transformed methods 

![](/figures/obs_pred_log.png)
