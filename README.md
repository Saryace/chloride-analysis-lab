## Update 25/Jun/2025

| Script                              | Objetive                                                                                                                                                          |
|-----------------|-------------------------------------------------------|
| 01_descriptive.R                    | Correlation Tables and Summary Stats                                                                                                                              |
| 02_intercept_log.R                  | Fits and evaluates all pairwise linear models between log-transformed chloride methods using train/test split 80/20 (set 1)                                       |
| 03_intercept.R                      | Fits and evaluates all pairwise linear models between chloride methods using train/test split 80/20 (set 1)                                                       |
| 04_prediction-ec-ph-log.R           | Fits linear models to predict log-transformed chloride methods using logSP, with optional covariates (pH, EC) and tests them on a 20% holdout set (set 1)         |
| 05_prediction-ec-ph.R               | Fits linear models to predict chloride methods using SP, with optional covariates (pH, EC) and tests them on a 20% holdout set (set 1)                            |
| 06_prediction-alldataset-noSP-log.R | Fits linear models to predict log-transformed chloride methods without SP, with optional covariates (pH, EC) and tests them on a 20% holdout set for all datasets |
| 07_prediction-alldataset-noSP.R     | Fits linear models to predict chloride methods using SP, with optional covariates (pH, EC) and tests them on a 20% holdout set for all datasets                   |

## DOCX files

1.  stat-per-set : Summary stats for each method, pH and EC for different sets
2.  stat-per-set-log : Summary stats for each method (log), pH and EC for different sets
3.  post-hoc-table: Post-Hoc Krustal for differences bewteen methods (Dunn's test)
4.  models-table: Data for models: Method A = Method B
5.  models-table-log: Data for models (log) Method A = Method B
6.  coef-table: coefficients for each model including pH and CE
7.  coef-table-log: coefficients for each model (log) including pH and CE
8.  coef-table-noSP: coefficients for each model including pH and CE no SP all datasets
9.  coef-table-log-noSP: coefficients for each model (log) including pH and CE no SP all datasets

## Figures

### Correlation all method (colors are differents dataset). TIFF available for better quality and publication-ready format

![](/figures/fig_corr.png)

### Correlation all method log-transformed (colors are differents dataset)

![](/figures/fig_corr_log.png)

### Observed vs. predicted methods = SP + pH +EC

![](/figures/obs_pred.png)

### Observed vs. predicted log-transformed methods = logSP + pH +EC

![](/figures/obs_pred_log.png)

### Observed vs. predicted methodsA = methodsB + pH +EC (no SP)

![](/figures/obs_pred-noSP.png)

### Observed vs. predicted log-transformed methodA = methodB + pH + EC (noSP)

![](/figures/obs_pred_log-noSP.png)
