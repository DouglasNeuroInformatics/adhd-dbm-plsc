import numpy as np
import pandas as pd
import os

WORKING_DIR     = os.environ.get("WORKING_DIR",    "/home/moncia/scratch/projects/hailab_ADHD/r_analysis")
PLSC_OUTPUT_DIR = os.environ.get("PLSC_OUTPUT_DIR", os.path.join(WORKING_DIR, "plsc_outputs_bootstrap_1000"))
os.chdir(WORKING_DIR)


results  = np.load(os.path.join(PLSC_OUTPUT_DIR, "plsc_results_key.npz"))
subjects = pd.read_csv(os.path.join(PLSC_OUTPUT_DIR, "subject_list.csv"))



x_scores = results["x_scores"]  # 81 x 22
y_scores = results["y_scores"]  # 81 x 22

df = subjects.copy()
for lv in range(5):
    df[f"x_lv{lv+1}"] = x_scores[:, lv]
    df[f"y_lv{lv+1}"] = y_scores[:, lv]

df.to_csv(os.path.join(PLSC_OUTPUT_DIR, "lv_scores.csv"), index=False)
print(f"Saved {os.path.join(PLSC_OUTPUT_DIR, 'lv_scores.csv')}")
print(df.head())
