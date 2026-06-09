# ADHD Deformation-Based Morphometry: Brain-Behaviour Relationships

**Code:** Cian Monnin  

## Overview

This project investigates relationships between brain structure and behavioural/cognitive measures in children with ADHD versus matched controls.
T1-weighted images were preprocessed with [Synthstrip_N3](https://github.com/CoBrALab/synthstrip_N3), then processed via **deformation-based morphometry (DBM)** using `optimized_antsMultivariateTemplateConstruction`.
The resulting log relative Jacobian determinants are related to 19 clinical and neuropsychological measures via both univariate linear models and multivariate Partial Least Squares Correlation (PLSC).

## Dataset

- **N = 87** participants (ADHD and typically-developing controls), reduced to **N = 81** after QC exclusions
- Age range: 7–16 years
- Groups are matched on age and sex
- Participant data is not included in this repository (identifiable).

## Repository Structure

```
.
├── code/
│   ├── README.md                 # Full pipeline walkthrough
│   ├── pipeline_config.sh        # Shared defaults (paths, PLSC parameters)
│   ├── plsc_analysis.py          # Main PLSC analysis (brain x behaviour)
│   ├── plsc_plots.R              # Behavioural loading plots
│   ├── plsc_brain_maps.R         # Brain map visualisations (combined)
│   ├── plsc_brain_maps_load.R    # Load BSR volumes for plotting
│   ├── plsc_brain_maps_plot.R    # Render brain map panels
│   ├── bsr_to_mnc.r              # Convert bootstrap ratio arrays to MINC
│   ├── basic_stats_combined.r    # Descriptive statistics and group comparisons
│   ├── npz_to_csv.py             # Utility: convert .npz result arrays to CSV
│   ├── post_hoc.py               # Post-hoc OLS regressions (age, sex)
│   ├── post_hoc.r                # Post-hoc group comparisons (R)
│   ├── trillium_models.r         # Univariate linear model specifications
│   ├── trillium_outputs.r        # Extract and summarise Trillium model outputs
│   ├── trillium_plots.r          # Univariate result visualisations
│   ├── check_outputs.r           # Validate model output completeness
│   ├── write_mask.r              # Generate brain mask from template
│   └── hpc/                      # SLURM submission scripts
│       ├── plsc_config.sh        # Cluster-specific paths and parameters
│       ├── plsc_submission.sh
│       ├── plsc_post_submission.sh
│       ├── trillium_submission.sh
│       ├── trillium_outputs_submission.sh
│       ├── trillium_plot_only.sh
│       ├── clean_data.sh         # Build cleaned demographics from raw input
│       ├── mnc_convert.sh        # NIfTI to MINC conversion
│       └── mnc_convert_submission.sh
└── pyproject.toml
```

Outputs (plots, model results, MINC volumes) are generated into `analysis/` and are not committed.

## Analyses

### 1. Descriptive Statistics and Group Comparisons
`code/basic_stats_combined.r`

Chi-squared (sex x group) and Welch t-tests (age x group) before and after QC exclusions. Results confirm well-matched groups.

### 2. Univariate Linear Models
`code/trillium_models.r`, `code/trillium_outputs.r`, `code/trillium_plots.r`

Linear models predicting log Jacobian determinants at each voxel from individual behavioural measures (BASC Hyperactivity/Inattention, Symptom Severity, BRIEFP BRI/Emotional Control, DKEFS Inhibition, CPT Omission/Commission), run via the Trillium framework on the compute cluster. Results FDR-corrected across voxels.

**Finding:** Age was the dominant predictor (significant at 5-10% FDR). No behavioural measure reached significance.

### 3. Multivariate PLSC
`code/plsc_analysis.py`

Partial Least Squares Correlation relating the full voxel-wise Jacobian matrix (X) to 19 clinical measures simultaneously (Y). Three composite scores (BASC Externalizing, BASC Internalizing, BRIEFP BRI) were excluded to avoid collinearity with their subscales. Age and sex excluded from Y matrix and tested post-hoc.

| Parameter | Value |
|---|---|
| Participants | 81 |
| Voxels (after mask) | ~15M |
| Behavioural measures | 19 |
| Permutations | 5000 |
| Bootstraps | 1000 |

**Finding:** LV1 (48.94% variance, p = 0.0002) likely captures group-level differences.

### 4. Post-hoc Analyses
`code/post_hoc.py`, `code/post_hoc.r`

OLS regression of age and sex onto PLSC latent variable scores. Visualisation of LV scores by diagnostic group.

## Reproducing the Analysis

### Environment

**Python** (PLSC and utilities):
```bash
# pypyls -- do NOT install 'pyls' from PyPI (different package)
pip install git+https://github.com/netneurolab/pypyls.git
```

On Alliance Canada clusters (Trillium, Niagara, etc.):
```bash
module load cobralab
uv pip install "setuptools<72" "numpy<2"
uv pip install --no-build-isolation git+https://github.com/netneurolab/pypyls.git
```

**R** packages: `RMINC`, `MRIcrotome`, `tidyverse`, `ggplot2`. Available via `module load cobralab` on Alliance clusters.

### Running the Pipeline

All scripts are parameterized by `ANALYSIS_NAME`. See [`code/README.md`](code/README.md) for the full step-by-step walkthrough. In brief:

```bash
# 1. Convert NIfTI to MINC (jacobians, mask, template)
bash code/hpc/mnc_convert.sh <ANALYSIS_NAME>

# 2. Build cleaned demographics file
bash code/hpc/clean_data.sh <ANALYSIS_NAME>

# 3. Univariate models
cd code/hpc
sbatch trillium_submission.sh <ANALYSIS_NAME>
sbatch trillium_outputs_submission.sh <ANALYSIS_NAME>   # after step 3 completes

# 4. PLSC (~5 hrs)
sbatch plsc_submission.sh <ANALYSIS_NAME>
sbatch plsc_post_submission.sh <ANALYSIS_NAME>           # after step 4 completes
```

Edit `code/hpc/plsc_config.sh` to change cluster paths, PLSC parameters (N_BOOT, N_PERM, etc.), or output directories.

