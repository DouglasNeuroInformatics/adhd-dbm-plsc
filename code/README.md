## Setup

All scripts take `ANALYSIS_NAME` as the first argument. This determines where inputs
are read from and where outputs are written:

```
dbm/.../smooth/<ANALYSIS_NAME>/              ← jacobian .mnc files
r_analysis/analysis/<ANALYSIS_NAME>/
  data/                                      ← demographics + mask + template
  plsc_outputs_boot<N>_perm<N>_<YYYYMMDD_HH>/
    plots/
    bsr_minc/
```

Edit `hpc/plsc_config.sh` to change PLSC parameters (N_BOOT, N_PERM, etc.) or
paths before running.

---

## 1. Data preparation

Convert jacobian, mask, and template NIfTI files to MINC:
```bash
bash hpc/mnc_convert.sh <ANALYSIS_NAME>
```

Append jacobian paths to demographics file and save to `analysis/<ANALYSIS_NAME>/data/cleaned_<ANALYSIS_NAME>.tsv`:
```bash
bash hpc/clean_data.sh <ANALYSIS_NAME>
```

---

## 2. PLSC

Run the main analysis (~5 hrs):
```bash
sbatch hpc/plsc_submission.sh <ANALYSIS_NAME>
```

Run post-processing (runs in sequence: npz_to_csv → bsr_to_mnc → post_hoc → plsc_plots → plsc_brain_maps):
```bash
sbatch hpc/plsc_post_submission.sh <ANALYSIS_NAME>
```

To reprocess a specific older run without re-running PLSC:
```bash
PLSC_OUTPUT_DIR=/path/to/plsc_outputs_boot1000_perm5000_20260401_1200 \
  sbatch hpc/plsc_post_submission.sh <ANALYSIS_NAME>
```

---

## 3. Univariate (Trillium)

```bash
sbatch hpc/trillium_submission.sh <ANALYSIS_NAME>         # runs trillium_models.r
sbatch hpc/trillium_outputs_submission.sh <ANALYSIS_NAME>  # runs trillium_outputs.r
```
