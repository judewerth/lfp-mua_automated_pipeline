## MATLAB-based automated pipeline for joint LFP and MUA Analysis
# This repoistory contains:
1) Terrabytes worth of recording data summarized into daily files.
2) Structure to autmotically process and summarize data during recordings (for Intan systems).
3) Functions to access these summmarized files.
4) Code utilizing these functions to produce figures (with example PNGs).
   
# 1. Recording Data
<img width="646" height="571" alt="Screenshot 2025-12-09 121314" src="https://github.com/user-attachments/assets/91140c58-d5ed-4e6f-9678-75af746671eb" />

- Data is saved in "Daily Files" (YYMMDD), a "-" means the file is full.
- Minutes which were no recorded are stored as "NO DATA"
- Minutes which have a compatible rhd file are compressed into a summary array containing the average value for 7 LFP power bands and 3 threshold spike counts (Our recording setup has 4 organoids per batch with 32 electrodes each).

# 2. Functionality to add to Recording Data
<img width="585" height="457" alt="Screenshot 2025-12-09 122157" src="https://github.com/user-attachments/assets/8503f985-b60d-4531-b752-3b4634cd4858" />

- This script will automatically process and summarize any rhd file containing the file prefix.
- rhd files should be in the same directory as this script or adjust the code as needed.

# 3. Functionality to easily access the Summarized Data Files
<img width="898" height="412" alt="Screenshot 2025-12-09 122746" src="https://github.com/user-attachments/assets/03dcaa59-5541-4b89-901f-826e155892ad" />

- In MATLAB, the user simply needs to define the recording experiments (drugs treatments in this case).
- If lists are left empty, the script will access "Recording_Log.xlsx" to define the recording window for analysis.
- FetchData will use the input struct and access all "Daily Files" and create a large concatenated array spanning all avaiable data between time points.

# 4. Produce figures based on input timepoints.
![firingmap](https://github.com/user-attachments/assets/f833df35-3954-446f-938d-827ac6c01a78)
![lfpplot](https://github.com/user-attachments/assets/50c06cc9-fc23-41c8-8b66-b6dbc4a44506)
<img width="1384" height="912" alt="LFP_BarPlots-Controlexample" src="https://github.com/user-attachments/assets/b9616439-3bb7-4e44-a60b-4f6f7783e837" />

  
