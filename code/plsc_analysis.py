#!/usr/bin/env python3
"""
Behavioral PLSC (Partial Least Squares Correlation) analysis for the ADHD DBM project.
Relates brain structure (jacobian determinants) to behavioral/clinical measures.

Usage:
    python plsc_analysis.py

Dependencies:
    pip install --user git+https://github.com/netneurolab/pypyls.git
    (Do NOT install 'pyls' from PyPI — different package)
"""

# ============================================================
# CONFIGURATION — Edit this section before running
# ============================================================

WORKING_DIR = "/home/moncia/scratch/projects/hailab_ADHD/r_analysis"
DEMOGRAPHICS_FILE = "./Demographic_Data_ADHD_combined_Jan102026_cleaned.tsv"
MASK_FILE = "mask_shapeupdate.mnc"
OUTPUT_DIR = "plsc_results"

# Behavioral columns to include in Y matrix.
# Comment out or remove columns you don't want.
BEHAVIORAL_COLS = [
    "DKEFS_Inhibition_SS",
    "DKEFS_Letter_Fluency_SS",
    "DKEFS_Category_Fluency_SS",
    "CPT_Omission_Tscore",
    "CPT_Commission_Tscore",
    "BASC_Inattention",
    "BASC_Hyperactivity",
    "BASC_Anxiety",
    "BASC_Depression",
    "BASC_Agg",
    "BASC_Withdrawal",
    "BASC_Adap",
    # Composites removed their subscales are already included above,
    # BASC_Externalizing = Hyperactivity + Aggression
    # BASC_Internalizing = Anxiety + Depression + Withdrawal
    # BRIEFP_BRI_B = Inh_B + Shi_B + Emotional_Control
    "BRIEFP_Inh_B",
    "BRIEFP_Shi_B",
    "BRIEFP_Emotional_Control",
    "BRIEFP_Initiate",
    "BRIEFP_WorkingMemory",
    "BRIEFP_PlanOrg_B",
    "BRIEFP_OrgMat_B",
]

# Group info — data will be sorted in this order (first group stacked on top)
GROUP_COL = "Group"
GROUP_ORDER = ["ADHD", "Control"]

# Covariates for post-hoc analysis (NOT included in PLS)
COVARIATE_COLS = ["Age_years", "Sex"]

# PLS parameters
N_PERM = 5000       # Permutation tests for LV significance
N_BOOT = 1000       # Bootstrap resampling for feature reliability
N_SPLIT = 0         # Split-half reliability (set to 0 to skip — saves hours of runtime)
SEED = 42           # For reproducibility
N_PROC =   16# "max" to use all cores, or an integer

# Procrustes rotation: False recommended by CoBrALab wiki to avoid bias
# where LV1 is virtually always significant due to rotation artifact.
ROTATE = False

# Significance threshold
ALPHA = 0.05

# Minimum column std dev — columns below this are dropped (CoBrALab wiki guidance)
MIN_STD = 1e-6

# ============================================================
# END CONFIGURATION
# ============================================================

import os
import sys
import time
from datetime import datetime

import numpy as np
import pandas as pd
import nibabel as nib
from scipy.stats import zscore
import statsmodels.api as sm
import pyls


def load_mask(mask_path):
    """Load a MINC mask and return a flattened boolean array."""
    print(f"Loading mask: {mask_path}")
    mask_img = nib.load(mask_path)
    mask_data = mask_img.get_fdata()
    print(f"  Mask volume shape: {mask_data.shape}")
    mask_bool = mask_data.flatten() > 0.5
    n_voxels = np.sum(mask_bool)
    print(f"  Voxels in mask: {n_voxels:,}")
    return mask_bool, mask_data.shape


def load_jacobians(file_paths, mask_bool, expected_shape):
    """Load jacobian volumes, apply mask, and stack into a subjects x voxels matrix."""
    n_subjects = len(file_paths)
    n_voxels = np.sum(mask_bool)
    X = np.zeros((n_subjects, n_voxels), dtype=np.float64)

    for i, path in enumerate(file_paths):
        if i == 0:
            # Try first file with a clear error message
            try:
                vol = nib.load(path).get_fdata()
            except Exception as e:
                print(f"\nERROR: Could not load first jacobian file with nibabel:")
                print(f"  Path: {path}")
                print(f"  Error: {e}")
                print("\nIf nibabel cannot read these MINC files, try converting to NIfTI")
                print("or install pyminc: pip install --user pyminc")
                sys.exit(1)
        else:
            vol = nib.load(path).get_fdata()

        if vol.shape != expected_shape:
            print(f"\nERROR: Volume shape mismatch for subject {i}:")
            print(f"  Expected: {expected_shape}, Got: {vol.shape}")
            print(f"  Path: {path}")
            sys.exit(1)

        X[i, :] = vol.flatten()[mask_bool]

        if (i + 1) % 10 == 0 or i == 0 or (i + 1) == n_subjects:
            print(f"  Loaded {i + 1}/{n_subjects} jacobians")

    return X


def run_posthoc_correlations(x_scores, y_scores, covariates_df):
    """
    OLS regression of covariates (Age, Sex) against LV scores.
    Returns a dict with results per covariate and score type.
    """
    # Dummy-code Sex: Female=0, Male=1
    cov_df = covariates_df.copy()
    if "Sex" in cov_df.columns:
        cov_df["Sex"] = cov_df["Sex"].map({"Female": 0, "Male": 1})

    results = {}
    for cov_name in cov_df.columns:
        cov_vals = cov_df[cov_name].values.astype(float)
        X_ols = sm.add_constant(cov_vals)

        results[cov_name] = {}
        for score_name, scores in [("x_scores", x_scores), ("y_scores", y_scores)]:
            model = sm.OLS(scores, X_ols).fit()
            results[cov_name][score_name] = {
                "beta": model.params[1],
                "t": model.tvalues[1],
                "p": model.pvalues[1],
                "r_squared": model.rsquared,
            }

    return results


def write_summary(path, run_info, df_info, results, posthoc, behavioral_cols, dropped_ids):
    """Write a human-readable summary report."""
    with open(path, "w") as f:
        f.write("=" * 70 + "\n")
        f.write("PLSC Analysis Summary — ADHD DBM Project\n")
        f.write("=" * 70 + "\n\n")

        # Run info
        f.write("Run metadata\n")
        f.write("-" * 40 + "\n")
        for k, v in run_info.items():
            f.write(f"  {k}: {v}\n")
        f.write("\n")

        # Data summary
        f.write("Data summary\n")
        f.write("-" * 40 + "\n")
        for k, v in df_info.items():
            f.write(f"  {k}: {v}\n")
        f.write("\n")

        # Behavioral columns
        f.write(f"Behavioral columns ({len(behavioral_cols)})\n")
        f.write("-" * 40 + "\n")
        for col in behavioral_cols:
            f.write(f"  - {col}\n")
        f.write("\n")

        # LV results table
        n_lvs = len(results["singvals"])
        pvals = results["permres"]["pvals"]
        varexp = results["varexp"]
        singvals = results["singvals"]

        f.write("Latent Variables\n")
        f.write("-" * 40 + "\n")
        f.write(f"  {'LV':<5} {'SingVal':>10} {'VarExp%':>10} {'Perm p':>10}")

        has_split = ("splitres" in results
                     and results["splitres"] is not None
                     and "ucorr" in results["splitres"])
        if has_split:
            f.write(f" {'ucorr':>8} {'ucorr_p':>10} {'vcorr':>8} {'vcorr_p':>10}")
        f.write("\n")

        sig_lvs = []
        for lv in range(n_lvs):
            is_sig = pvals[lv] < ALPHA
            marker = " *" if is_sig else ""
            if is_sig:
                sig_lvs.append(lv)
            line = f"  {lv + 1:<5} {singvals[lv]:>10.2f} {varexp[lv] * 100:>9.2f}% {pvals[lv]:>10.4f}"

            if has_split:
                sr = results["splitres"]
                line += f" {sr['ucorr'][lv]:>8.4f} {sr['ucorr_pvals'][lv]:>10.4f}"
                line += f" {sr['vcorr'][lv]:>8.4f} {sr['vcorr_pvals'][lv]:>10.4f}"

            f.write(line + marker + "\n")

        f.write(f"\n  * significant at alpha = {ALPHA}\n")

        if has_split:
            f.write("  Split-half reliable if BOTH ucorr_p AND vcorr_p < 0.05\n")
        f.write("\n")

        # BSR thresholds
        f.write("Bootstrap Ratio (BSR) thresholds\n")
        f.write("-" * 40 + "\n")
        f.write("  |BSR| >= 1.95  ->  p < 0.05\n")
        f.write("  |BSR| >= 2.57  ->  p < 0.01\n")
        f.write("  |BSR| >= 3.29  ->  p < 0.001\n\n")

        # Y loadings for significant LVs
        if sig_lvs:
            y_loadings = results["y_loadings"]
            y_ci = results["bootres"]["y_loadings_ci"]

            for lv in sig_lvs:
                f.write(f"Y loadings — LV{lv + 1} (p = {pvals[lv]:.4f})\n")
                f.write("-" * 40 + "\n")
                f.write(f"  {'Behavior':<30} {'Loading':>10} {'CI_low':>10} {'CI_high':>10}\n")
                for j, col in enumerate(behavioral_cols):
                    loading = y_loadings[j, lv]
                    ci_lo = y_ci[j, lv, 0]
                    ci_hi = y_ci[j, lv, 1]
                    cross_zero = " (n.s.)" if ci_lo <= 0 <= ci_hi else ""
                    f.write(f"  {col:<30} {loading:>10.4f} {ci_lo:>10.4f} {ci_hi:>10.4f}{cross_zero}\n")
                f.write("\n")

            # Post-hoc correlations
            f.write("Post-hoc covariate correlations (significant LVs)\n")
            f.write("-" * 40 + "\n")
            for lv in sig_lvs:
                f.write(f"\n  LV{lv + 1}:\n")
                if lv in posthoc:
                    for cov_name, scores in posthoc[lv].items():
                        for score_type, stats in scores.items():
                            f.write(f"    {cov_name} vs {score_type}: "
                                    f"beta={stats['beta']:.4f}, "
                                    f"t={stats['t']:.4f}, "
                                    f"p={stats['p']:.4f}, "
                                    f"R²={stats['r_squared']:.4f}\n")
            f.write("\n")
        else:
            f.write("No significant LVs found.\n\n")

        # Dropped subjects
        if dropped_ids:
            f.write(f"Subjects dropped by listwise deletion ({len(dropped_ids)})\n")
            f.write("-" * 40 + "\n")
            for sid in dropped_ids:
                f.write(f"  {sid}\n")
        else:
            f.write("No subjects dropped (no missing data).\n")

        f.write("\n" + "=" * 70 + "\n")


# ============================================================
# MAIN
# ============================================================

def main():
    start_time = time.time()
    print("=" * 60)
    print("PLSC Analysis — ADHD DBM Project")
    print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)

    # --- Setup ---
    os.chdir(WORKING_DIR)
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    n_proc = os.cpu_count() if N_PROC == "max" else N_PROC
    print(f"Using {n_proc} processors")

    # --- Load demographics ---
    print(f"\nLoading data: {DEMOGRAPHICS_FILE}")
    df = pd.read_csv(DEMOGRAPHICS_FILE, sep="\t")
    print(f"  Total subjects loaded: {len(df)}")

    # Convert behavioral columns to numeric
    for col in BEHAVIORAL_COLS:
        if col not in df.columns:
            print(f"  WARNING: Column '{col}' not found in TSV. Skipping.")
        else:
            df[col] = pd.to_numeric(df[col], errors="coerce")

    # Filter to columns that actually exist
    behavioral_cols = [c for c in BEHAVIORAL_COLS if c in df.columns]
    print(f"  Behavioral columns found: {len(behavioral_cols)}/{len(BEHAVIORAL_COLS)}")

    # Remove columns with near-zero variance
    col_stds = df[behavioral_cols].std()
    low_var_cols = col_stds[col_stds < MIN_STD].index.tolist()
    if low_var_cols:
        print(f"  Removing {len(low_var_cols)} columns with near-zero variance: {low_var_cols}")
        behavioral_cols = [c for c in behavioral_cols if c not in low_var_cols]

    # --- NaN handling: listwise deletion ---
    before_n = len(df)
    nan_mask = df[behavioral_cols].isna().any(axis=1)
    dropped_ids = df.loc[nan_mask, df.columns[0]].tolist()  # first column assumed to be subject ID
    df = df.dropna(subset=behavioral_cols).copy()
    after_n = len(df)
    print(f"\n  Listwise deletion: {before_n} -> {after_n} subjects ({before_n - after_n} dropped)")
    if dropped_ids:
        print(f"  Dropped subject IDs: {dropped_ids}")

    # --- Sort by group ---
    df["_group_order"] = df[GROUP_COL].map({g: i for i, g in enumerate(GROUP_ORDER)})
    if df["_group_order"].isna().any():
        unexpected = df.loc[df["_group_order"].isna(), GROUP_COL].unique()
        print(f"  ERROR: Unexpected group values: {unexpected}")
        sys.exit(1)
    df = df.sort_values("_group_order").reset_index(drop=True)
    df = df.drop(columns=["_group_order"])

    group_counts = df[GROUP_COL].value_counts()
    groups = [int(group_counts.get(g, 0)) for g in GROUP_ORDER]
    print(f"\n  Group order: {GROUP_ORDER}")
    print(f"  Group sizes: {groups} (total: {sum(groups)})")

    # Save subject list for traceability
    subject_id_col = df.columns[0]
    subject_list = df[[subject_id_col, GROUP_COL]].copy()
    subject_list.to_csv(os.path.join(OUTPUT_DIR, "subject_list.csv"), index=False)
    print(f"  Saved subject list to {OUTPUT_DIR}/subject_list.csv")

    # --- Build Y matrix ---
    print("\nBuilding Y matrix...")
    Y_raw = df[behavioral_cols].values.astype(np.float64)
    Y = zscore(Y_raw, axis=0, ddof=1)
    print(f"  Y shape: {Y.shape} (subjects x behaviors)")

    # --- Check for checkpoint (skip jacobian loading and PLS if found) ---
    import pickle
    _ckpt = os.path.join(OUTPUT_DIR, "results_raw.pkl")
    pls_start = time.time()

    if os.path.exists(_ckpt):
        print(f"\nCheckpoint found — loading results from {_ckpt}")
        print("  (skipping jacobian loading, permutation tests, and bootstrap)")
        with open(_ckpt, "rb") as _f:
            results = pickle.load(_f)
        n_voxels = results["x_weights"].shape[0]
    else:
        # --- Validate jacobian paths ---
        print("\nValidating jacobian file paths...")
        jacobian_paths = df["relative_jacobian"].tolist()
        missing = [p for p in jacobian_paths if not os.path.isfile(p)]
        if missing:
            print(f"  ERROR: {len(missing)} jacobian files not found. First 5:")
            for p in missing[:5]:
                print(f"    {p}")
            sys.exit(1)
        print(f"  All {len(jacobian_paths)} jacobian files found.")

        # --- Build X matrix ---
        print("\nBuilding X matrix...")
        mask_path = os.path.join(WORKING_DIR, MASK_FILE)
        mask_bool, mask_shape = load_mask(mask_path)

        X = load_jacobians(jacobian_paths, mask_bool, mask_shape)
        print(f"  X shape: {X.shape} (subjects x voxels)")
        print(f"  X memory: {X.nbytes / 1e9:.2f} GB")
        n_voxels = int(np.sum(mask_bool))

        # --- Run behavioral PLS ---
        print("\n" + "=" * 60)
        print("Running behavioral PLS...")
        print(f"  n_perm={N_PERM}, n_boot={N_BOOT}, n_split={N_SPLIT}")
        print(f"  seed={SEED}, rotate={ROTATE}, n_proc={n_proc}")
        print("=" * 60)

        pls_kwargs = dict(
            X=X,
            Y=Y,
            groups=[sum(groups)],
            n_cond=1,
            n_perm=N_PERM,
            n_boot=N_BOOT,
            seed=SEED,
            rotate=ROTATE,
            n_proc=n_proc,
        )
        if N_SPLIT > 0:
            pls_kwargs["n_split"] = N_SPLIT

        results = pyls.behavioral_pls(**pls_kwargs)

        with open(_ckpt, "wb") as _f:
            pickle.dump(results, _f)
        print(f"  Checkpoint saved: {_ckpt}")

    pls_elapsed = time.time() - pls_start
    print(f"\nPLS completed in {pls_elapsed / 60:.1f} minutes")

    # --- Quick results overview ---
    pvals = results["permres"]["pvals"]
    varexp = results["varexp"]
    n_lvs = len(pvals)
    print(f"\n  {n_lvs} latent variables:")
    sig_lvs = []
    for lv in range(n_lvs):
        sig = "***" if pvals[lv] < 0.001 else "**" if pvals[lv] < 0.01 else "*" if pvals[lv] < 0.05 else ""
        print(f"    LV{lv + 1}: p={pvals[lv]:.4f}, varexp={varexp[lv] * 100:.2f}% {sig}")
        if pvals[lv] < ALPHA:
            sig_lvs.append(lv)

    print(f"\n  Significant LVs (p < {ALPHA}): {len(sig_lvs)}")

    # --- Post-hoc covariate correlations ---
    posthoc = {}
    if sig_lvs:
        print("\nRunning post-hoc covariate correlations...")
        cov_df = df[COVARIATE_COLS].copy()

        for lv in sig_lvs:
            posthoc[lv] = run_posthoc_correlations(
                results["x_scores"][:, lv],
                results["y_scores"][:, lv],
                cov_df,
            )
            for cov_name, scores in posthoc[lv].items():
                for score_type, stats in scores.items():
                    print(f"  LV{lv + 1} | {cov_name} vs {score_type}: "
                          f"p={stats['p']:.4f}, R²={stats['r_squared']:.4f}")

    # --- Save outputs ---
    print(f"\nSaving outputs to {OUTPUT_DIR}/...")

    # Key arrays as npz
    npz_data = dict(
        x_weights=results["x_weights"],
        y_weights=results["y_weights"],
        x_scores=results["x_scores"],
        y_scores=results["y_scores"],
        y_loadings=results["y_loadings"],
        singvals=results["singvals"],
        varexp=results["varexp"],
        pvals=results["permres"]["pvals"],
        x_weights_normed=results["bootres"]["x_weights_normed"],
        y_loadings_ci=results["bootres"]["y_loadings_ci"],
    )
    if (N_SPLIT > 0
            and "splitres" in results
            and results["splitres"] is not None
            and "ucorr" in results["splitres"]):
        npz_data["ucorr"] = results["splitres"]["ucorr"]
        npz_data["vcorr"] = results["splitres"]["vcorr"]
        npz_data["ucorr_pvals"] = results["splitres"]["ucorr_pvals"]
        npz_data["vcorr_pvals"] = results["splitres"]["vcorr_pvals"]

    npz_path = os.path.join(OUTPUT_DIR, "plsc_results_key.npz")
    np.savez(npz_path, **npz_data)
    print(f"  Saved {npz_path}")

    # Post-hoc correlations
    posthoc_rows = []                                                                          
    for lv, cov_dict in posthoc.items():
        for cov_name, score_dict in cov_dict.items():                                          
            for score_type, stats in score_dict.items():                                       
                posthoc_rows.append({"LV": lv + 1, "covariate": cov_name,                      
                                     "score": score_type, **stats})                            
    if posthoc_rows:                                                                           
        pd.DataFrame(posthoc_rows).to_csv(                                                     
            os.path.join(OUTPUT_DIR, "posthoc_correlations.csv"), index=False)                 
        print(f"  Saved posthoc_correlations.csv")  

    # Summary report
    run_info = {
        "Date": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "Seed": SEED,
        "n_perm": N_PERM,
        "n_boot": N_BOOT,
        "n_split": N_SPLIT,
        "rotate": ROTATE,
        "n_proc": n_proc,
        "PLS runtime (min)": f"{pls_elapsed / 60:.1f}",
    }
    df_info = {
        "Total subjects (before NaN removal)": before_n,
        "Subjects after listwise deletion": after_n,
        "Subjects dropped": before_n - after_n,
        "Group sizes": f"{dict(zip(GROUP_ORDER, groups))}",
        "Behavioral variables": len(behavioral_cols),
        "Voxels in mask": n_voxels,
    }

    summary_path = os.path.join(OUTPUT_DIR, "plsc_summary.txt")
    write_summary(summary_path, run_info, df_info, results, posthoc,
                  behavioral_cols, dropped_ids)
    print(f"  Saved {summary_path}")

    # --- Done ---
    total_elapsed = time.time() - start_time
    print(f"\n{'=' * 60}")
    print(f"All done! Total runtime: {total_elapsed / 60:.1f} minutes")
    print(f"Outputs: {os.path.join(WORKING_DIR, OUTPUT_DIR)}/")
    print(f"Significant LVs: {len(sig_lvs)} / {n_lvs}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
