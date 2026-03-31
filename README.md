# ADHD Deformation-Based Morphometry: Brain-Behaviour Relationships

**Code:** Cian Monnin  
**Lab:** Hailab, CoBrALab

## Overview

This project investigates relationships between brain structure and behavioural/cognitive measures in children with ADHD versus matched controls. 
T1ws were preprocessed with Synthtrip_N3.
preprocessed images then processed via **deformation-based morphometry (DBM)**.
These are related to 22 clinical and neuropsychological measures via both univariate linear models and multivariate Partial Least Squares Correlation (PLSC).

## Dataset

- **N = 87** participants (ADHD and typically-developing controls), reduced to **N = 81** after QC exclusions
- Age range: approximately 9–12 years
- Groups are matched on age and sex (see `report.md` for group comparison statistics)
- Participant data is not included in this repository (identifiable). See `data/README.md` for the data schema and external paths.

## Repository Structure

```
.
├── code/
│   ├── plsc_analysis.py          # Main PLSC analysis (brain × behaviour)
│   ├── plsc_plots.R              # Behavioural loading plots
│   ├── plsc_brain_maps.R         # Brain map visualisations of PLSC weights
│   ├── basic_stats_combined.r    # Descriptive statistics and group comparisons
│   ├── npz_to_csv.py             # Utility: convert .npz result arrays to CSV
│   ├── post_hoc.py               # Post-hoc correlational analyses
│   ├── post_hoc.r                # Post-hoc group comparisons (R)
│   ├── trillium_models.r         # Univariate linear model specifications
│   ├── trillium_outputs.r        # Extract and summarise Trillium model outputs
│   ├── check_outputs.r           # Validate model output completeness
│   └── hpc/                      # HPC cluster submission scripts (SLURM)
│       ├── plsc_submission.sh
│       ├── trillium_submission.sh
│       ├── trillium_outputs_submission.sh
│       ├── single_test.sh
│       ├── clean_data.sh
│       └── mnc_convert.sh
└── data/
    └── README.md                 # Data schema, QC exclusions, external paths
```

## Analyses

### 1. Descriptive Statistics and Group Comparisons
`code/basic_stats_combined.r`

Chi-squared (sex × group) and Welch t-tests (age × group) before and after QC exclusions. Results confirm well-matched groups.

### 2. Univariate Linear Models
`code/trillium_models.r`, `code/trillium_outputs.r`

Linear models predicting log Jacobian determinants at each voxel from individual behavioural measures (BASC Hyperactivity/Inattention, Symptom Severity, BRIEFP BRI/Emotional Control, DKEFS Inhibition, CPT Omission/Commission), run via the Trillium framework on the compute cluster. Results FDR-corrected across voxels.

**Finding:** Age was the dominant predictor (significant at 5–10% FDR). No behavioural measure reached significance.

### 3. Multivariate PLSC
`code/plsc_analysis.py`

Partial Least Squares Correlation relating the full voxel-wise Jacobian matrix (X) to all 22 clinical measures simultaneously (Y). Age and sex excluded from Y matrix and tested post-hoc.

| Parameter | Value |
|---|---|
| Participants | 81 |
| Voxels (after mask) | ~15M |
| Behavioural measures | 22 |
| Permutations | 5000 |
| Bootstraps | 1000 |

**Finding:** LV1 (49.75% variance, p = 0.0002) likely captures group-level differences. See `report.md` for full results.

### 4. Post-hoc Analyses
`code/post_hoc.py`, `code/post_hoc.r`

OLS regression of age and sex onto PLSC latent variable scores. Visualisation of LV scores by diagnostic group.

## Reproducing the Analysis

### Environment

**Python** (PLSC and utilities):
```bash
# Install pypyls — do NOT install 'pyls' from PyPI (different package)
pip install git+https://github.com/netneurolab/pypyls.git

# Or using uv (pyproject.toml provided):
uv sync
```


### Running on a Cluster

SLURM submission scripts are in `code/hpc/`. The main PLSC analysis (computationally intensive: 5000 permutations × 1000 bootstraps) is submitted via:
```bash
sbatch code/hpc/plsc_submission.sh
```

Univariate Trillium models:
```bash
sbatch code/hpc/trillium_submission.sh
```

