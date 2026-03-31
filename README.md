> **Last updated:** 03/30/2026

# Soil Chloride Measurement Methods — Evaluation Repository

This repository contains the evaluation of four soil chloride measurement methods: **Mercuric Thiocyanate (MT)**, **Potentiometric Titration (PT)**, **Inductively Coupled Plasma (ICP)**, and **Ion Chromatography (IC)** across certified, non-certified, and chloride-spill soil samples.

Certified samples are used for model training via pairwise linear calibration with 10-fold cross-validation, while non-certified and spill datasets serve as external validation. Statistical comparisons (Friedman test, Wilcoxon/Bonferroni) show ICP and IC are equivalent, while PT differs systematically. Log₁₀-transformed models show strong agreement across methods and generalize well to independent datasets.

**Sample sizes:**

| Dataset | Role | n |
|---|---|---|
| Certified soils | Training | 50 |
| Non-certified soils | External validation | 72 |
| Spill soils | External validation | 9 |

---

## Workflow

```
DATA SOURCES
============
Chap2-Rcode-DataBase.xlsx          Chap2-S5-NDSUContaminateSoil.xlsx
        |                                          |
  +-----+-----+                                   |
  |           |                                   |
Set == 1   Set != 1                               |
  |           |                                   |
  v           v                                   v
CERTIFIED   NON-CERTIFIED                       SPILL
(training n = 50)  (external val. = 72)                 (external val. n = 9)
  |           |                                   |
  +-----+-----+-----------------------------------+
                          |
                          v
                   PRE-PROCESSING
           - Cast MT, PT, ICP, IC, pH, EC to numeric
           - Compute log10 transforms
                          |
                          v
                   COMBINED DATASET
              (DataGroup: certified |
               non-certified | spill)
                          |
        +-----------------+-----------------+
        |                 |                 |
        v                 v                 v
01_descriptive.R    03_correlation.R   [all datasets]
Descriptive stats   ggpairs matrices
original + log      per dataset x scale
        |                 |
        v                 v
stat-original.docx  figures/correlation/
stat-log.docx


CERTIFIED ONLY
==============
        |
  +-----+-----+
  |           |
  v           v
02_post-hoc.R         04_models.R
Shapiro-Wilk          Pairwise linear models
Friedman test         MT, PT, ICP, IC (all pairs)
Wilcoxon + Bonf.      With / without intercept
                      10-fold CV, best by RMSE
  |                         |
  v                         v
post-hoc-table.docx   figures/model-training/
                      models-table-*.docx


EXTERNAL VALIDATION
===================
Best models from 04_models.R
+ NON-CERTIFIED + SPILL datasets
        |
        v
05_external_validation.R
Metrics: RMSE, MAE, MSE, MSD, MAD, RMSD
Observed vs. predicted plots
        |
        v
figures/external-validation/
external-validation-*.docx


KEY FINDINGS
============
  ICP ~ IC      : equivalent (original and log scale)
  PT            : differs from all other methods
  Log scale     : predictions close to 1:1 line, low bias
  Original scale: more dispersion at high concentrations
```

---

## Script Description

### 01_descriptive.R

Loads chloride datasets from certified, non-certified, and spill soil samples. Removes censored
rows (`<` or `>`), converts analytical variables (`MT`, `PT`, `ICP`, `IC`, `pH`, `EC`) to numeric,
and computes log10 transforms. Descriptive statistics (N, mean, SD, variance, SE, CV, min-max,
median, quartiles, skewness) are calculated by sample group for both original and log-transformed
variables and exported as formatted Word tables.

> Note: variance in spill samples reaches the millions due to the concentration range (300-10,000 mg/kg).

**Outputs**
- `docx/stat-original.docx`
- `docx/stat-log.docx`

---

### 02_post-hoc.R

Loads certified soil samples only. Normality is assessed with Shapiro-Wilk tests. Differences
among methods (MT, PT, ICP, IC) are tested with the Friedman test, followed by paired Wilcoxon
post-hoc comparisons with Bonferroni correction.

> ICP and IC are statistically equivalent (original and log scale). PT differs significantly from all other methods.

**Outputs**
- `docx/post-hoc-table.docx`

---

### 03_correlation.R

Produces pairwise correlation matrix figures (`ggpairs`) for MT, PT, ICP, and IC across the three
datasets (certified, non-certified, spill), in both original and log10 scale. Diagonal panels show
distributions; lower panels show scatterplots; upper panels show correlation coefficients.

**Outputs**
- `figures/correlation/fig_corr.png` / `.tiff`
- `figures/correlation/fig_corr_log.png` / `.tiff`
- `figures/correlation/fig_corr_non_certified.png` / `.tiff`
- `figures/correlation/fig_corr_non_certified_log.png` / `.tiff`
- `figures/correlation/fig_corr_spill.png` / `.tiff`
- `figures/correlation/fig_corr_spill_log.png` / `.tiff`

---

### 04_models.R

Develops pairwise linear calibration models among MT, PT, ICP, and IC using certified samples,
on both original and log10 scales. Models are fitted with and without intercept and evaluated
using 10-fold cross-validation. The best model per pair is selected by RMSE.

> IC, ICP, and MT show slopes close to 1 and low RMSE. PT shows lower slopes and higher error, indicating systematic differences.

**Outputs**
- `figures/model-training/fig_model_original.png` / `.tiff`
- `figures/model-training/fig_model_log.png` / `.tiff`
- `docx/model-training/models-table-intercept-all.docx`
- `docx/model-training/models-table-best-per-pair.docx`

---

### 05_external_validation.R

Applies the best models from `04_models.R` to non-certified and spill datasets. Computes
prediction metrics (RMSE, MAE, MSE, MSD, MAD, RMSD) and generates observed vs. predicted plots
and summary tables.

> Log scale predictions closely follow the 1:1 line with minimal bias. Original scale shows more dispersion at high concentrations.

**Outputs**
- `figures/external-validation/fig_non_certified_original.png` / `.tiff`
- `figures/external-validation/fig_non_certified_log.png` / `.tiff`
- `figures/external-validation/fig_spill_original.png` / `.tiff`
- `figures/external-validation/fig_spill_log.png` / `.tiff`
- `docx/external-validation/non-certified-external-validation.docx`
- `docx/external-validation/spill-external-validation.docx`

## Figures

All figures are generated by running the scripts in order. Outputs are written to `figures/`.

### Correlation matrices — certified samples

| Original scale | Log₁₀ scale |
|---|---|
| ![Correlation certified original](figures/correlation/fig_corr.png) | ![Correlation certified log](figures/correlation/fig_corr_log.png) |

Pairwise correlation matrix (GGally `ggpairs`) for MT, PT, ICP, and IC. Log₁₀ transformation reduces right-skew and improves linearity.

### Correlation matrices — non-certified samples

| Original scale | Log₁₀ scale |
|---|---|
| ![](figures/correlation/fig_corr_non_certified.png) | ![](figures/correlation/fig_corr_non_certified_log.png) |

Correlation structure among methods for non-certified soils used in external validation.

### Correlation matrices — spill samples

| Original scale | Log₁₀ scale |
|---|---|
| ![](figures/correlation/fig_corr_spill.png) | ![](figures/correlation/fig_corr_spill_log.png) |

Correlation structure for NDSU contaminated (spill) soils. High variance in original scale reflects the wide concentration range.

### Calibration models — certified samples

| Original scale | Log₁₀ scale |
|---|---|
| ![](figures/model-training/fig_model_original.png) | ![](figures/model-training/fig_model_log.png) |

Observed vs. predicted plots for pairwise linear models trained on certified samples, with and without intercept. Best model per pair selected by 10-fold CV RMSE. Log₁₀ scale is recommended for method interconversion.

### External validation — non-certified samples

| Original scale | Log₁₀ scale |
|---|---|
| ![](figures/external-validation/fig_non_certified_original.png) | ![](figures/external-validation/fig_non_certified_log.png) |

Best models from certified training applied to non-certified soils. Metrics: RMSE, MAE, MSE, MSD, MAD, RMSD.

### External validation — spill samples

| Original scale | Log₁₀ scale |
|---|---|
| ![](figures/external-validation/fig_spill_original.png) | ![](figures/external-validation/fig_spill_log.png) |

External validation on NDSU contaminated soils. Original scale shows increased dispersion at high concentrations; log scale preserves strong linear relationships.
