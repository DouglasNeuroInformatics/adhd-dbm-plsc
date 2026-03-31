import numpy as np                                                                         
import os
                                                                                           
RESULTS_DIR = "plsc_results_1000_bootstrap_no_groups"                                      
results = np.load(f"{RESULTS_DIR}/plsc_results_key.npz")
                                                                                           
for key in results.files:
    arr = results[key]
    if arr.ndim == 3:
        # Save each slice separately                                                       
        os.makedirs(f"{RESULTS_DIR}/{key}", exist_ok=True)
        for i in range(arr.shape[0]):                                                      
            np.savetxt(f"{RESULTS_DIR}/{key}/{key}_{i}.csv", arr[i], delimiter=",")        
        print(f"Saved {key}/ — shape {arr.shape}")
    else:                                                                                  
        np.savetxt(f"{RESULTS_DIR}/{key}.csv", arr, delimiter=",")
        print(f"Saved {key}.csv — shape {arr.shape}")        
