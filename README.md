# CURBIO_SL_DK

Repository of the article **A change in behavioral state switches the pattern of motor output that underlies rhythmic head and orofacial movements** by Liao &amp; Kleinfeld. Current Biology (2023).

Link to the paper: https://www.sciencedirect.com/science/article/pii/S0960982223004566

---

<p align="center">
<img src="https://ars.els-cdn.com/content/image/1-s2.0-S0960982223004566-fx1.jpg" />
</p>
<p align="center">
Graphical abstract (source: https://ars.els-cdn.com/content/image/1-s2.0-S0960982223004566-fx1.jpg)
</p>


## Data

Data can be downloaded from the following two sources:

### 1. Download from Google Drive (original format)

Link to the [Google Drive](https://drive.google.com/drive/folders/14tUsFh6X54gpxlsFWoynKT4JRm_1S84h?usp=sharing)

**Notes:**

- The `/Data` folder on the Google Drive contains 33 folders, each folder corresponding to an animal investigated in this study.

- Experimental procedures for each animal can be found in Table S4 in [Supplemental Information](https://ars.els-cdn.com/content/image/1-s2.0-S0960982223004566-mmc1.pdf).

- The `animal ID` is in the format of **SLRXXX** (for example, `SLR087`).

- The `session ID` is named in thr format of **<animal_ID>\_arena\_<recording_id>**. Some example session IDs are `SLR087_arena_d1` and `SLR126_arena_h2`.

- The prefix `h` in the `recording ID` means only the head sensor is taking data during the session (ex. `h2`). The prefix `d` means that both the head and torso sensors are used (ex. `d1`).

- For the signal processing details, please refer to the paper.


#### Details of the data format

- In each animal folder (ex. `SLR087`) these data files are available:

  - `<session_ID>_D_36data.mat` is the **main time series data** used for analysis. The shape of the matrix should be (*number of timestep sampled at 2kHz*, *36*), abbreviated as the `36data`. The variables stored in each column are described below (variables that were frequently studied are displayed **in Bold**). Information of the EMG envelope channels (columns 3-6) are listed in the **Appendix** section below.
  
  
    | | Variable |  | Variable |  | Variable |  | Variable |
    | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- |
    | 1 | **Time** | 11 | Head roll angle | 21 | Torso acceleration Ax | 31 | Torso pitch velocity |
    | 2 | N/A | 12 | Head acceleration Ax | 22 | Torso acceleration Ay | 32 | Torso roll velocity |
    | 3 | **EMG envelope #1** | 13 | Head acceleration Ay | 23 | Torso acceleration Az | 33 | **Head-torso yaw velocity** |
    | 4 | **EMG envelope #2**| 14 | Head acceleration Az | 24 | Torso angular velocity Wx | 34 | Head-torso pitch velocity |
    | 5 | **EMG envelope #3** | 15 | Head angular velocity Wx | 25 | Torso angular velocity Wy | 35 | Head-torso roll velocity |
    | 6 | **EMG envelope #4** | 16 | Head angular velocity Wy | 26 | Torso angular velocity Wz | 36 | **Breathing** |
    | 7 | N/A | 17 | Head angular velocity Wz | 27 | Head yaw velocity |  |  |
    | 8 | N/A | 18 | **Torso yaw angle** | 28 | Head pitch velocity |  |  |
    | 9 | **Head yaw angle** | 19 | Torso pitch angle | 29 | Head roll velocity |  |  |
    | 10 | **Head pitch angle** | 20 | N/A | 30 | Torso yaw velocity |  |  |

  - `<session_ID>_D_LCmat.mat` is the raw data exported from LabChart (the data acquisition system). The signals were processed and stored as part of the `36data`.
  
  - `<session_ID>_D_video.avi` is the recorded video of the session.
  
  - `<session_ID>_D_excel.xlsx` is the raw data taken by the head sensor (or head and torsor sensors). The signals were processed and stored as part of the `36data`.
  
  - `<session_ID>_D_eventLog.mat` is the annotated bahaviors of the animal during the session (ex. grooming, dog-shaking). The annotations were processed and stored as part of the `bBoolsMap.mat` data (see below).

  - `<animal_ID>_D_bBoolsMap.mat` contains the boolean values for each frame from each session.
  
  - `<animal_ID>_D_percentiles_36data.mat` stores the percentiles of the selected variables from the `36data`.
  
  - `<animal_ID>_D_recordingListMap.mat` lists the recording_id for each animal.
  
  - `<animal_ID>_D_videoFrameBoundaries.mat` stores the start and end frames of the video file that map to the beginning and the end of the `36data`.
    
- In some selected animal folders these data files are available:

  - `A_<animal ID>_annotation_epochs.xlsx` contains the start/end frames and the location of the food pellet of each foraging trial.

  - `A_<animal ID>_annotation_epochs_transposed.xlsx` is a transposed version of `A_<animal ID>_annotation_epochs.xlsx` solely for the purpose of NWB data conversion.
  
  - `<session_ID>_D_videoDLC_torso.csv` contains the coordinates of the torso using the [DeepLabCut](https://github.com/DeepLabCut/DeepLabCut) package.
  
  - `<session_ID>_D_arena_ellipse_params.mat` stores the parameters of the boundary of the arena floor observed by the camera.


### 2. Download from DANDI (NWB format)

Link to DANDI (will be available soon).

| Data format (Google Drive) | Data format (NWB) | Notes |
| ----------- | ----------- | ----------- |
| `<session_id>_D_36data.mat` |  |  |
| `<session_id>_D_LCmat.mat` |  |  |
| `<session_id>_D_video.avi` |  |  |
| `<session_id>_D_excel.xlsx` |  |  |
| `<session_id>_D_eventLog.mat` | `NWBFile.notes` | Each annotated miscellaneous behavior (ex. grooming) is stored as a tuple of length = 3: (`Unusable Behavior`, `<START_FRAME>`, `<END_FRAME>`). The values refer to the frame indeces of the video file `<session_id>_D_video.avi`. |
| `<session_ID>_D_videoDLC_torso.csv` |  |  |
| `<session_ID>_D_arena_ellipse_params.mat` |  |  |
| `A_<animal ID>_annotation_epochs_transposed.xlsx` | `NWBFile.scratch` | Each supplemental annotation is stored as a tuple of 6 elements: (`EPOCH_START_FRAME`, `EPOCH_END_FRAME`, `EPOCH_STATUS`, `PELLET_LOC_X`, `PELLET_LOC_Y`, `PELLET_STATUS`). |
| `<animal_id>_D_bBoolsMap.mat` | `NWBFile.analysis` | Stored as a tuple of 3 tuples as the elements: (`tuple_1`, `tuple_2`, `tuple_3`). |
| `<animal_id>_percentiles_36data.mat` | `NWBFile.processing` | Stored as a tuple of two elements. The first element is a tuple that stores the column from `<session_ID>_D_36data.mat` that used to calculate certain percentile. The second element is a tuple that stores the corresponding values. |
| `<animal_id>_recordingListMap.mat` | N/A | List of the recording indeces is not required for NWB. Each NWB file is created from a single session |
| `<animal_id>_videoFrameBoundaries.mat` | `NWBFile.notes` | Stored as a tuple of length = 3: (`Video Boundary`, `<START_FRAME>`, `<END_FRAME>`) that correspond to the first and last sample of `<session_ID>_D_36data.mat`. |

<p align="center">
Details of data conversion from Google Drive to DANDI.
</p>





## Code

Codes (MATLAB) are available in the `/Scripts` folder, which contains the following subfolders:

- `/Scripts/codes_for_figures` contains the codes that can generate the figures. Please see the comments in the files for more information.
- `/Scripts/codes_for_supplemental_figures` contains the codes that can generate the supplemental figures. Please see the comments in the files for more information.
- `/Scripts/utils` contains the helper codes that are called by the other scripts.


#### To run the code:

1. Install [MATLAB](https://www.mathworks.com/products/matlab.html?s_tid=hp_products_matlab) and the [MATLAB Signal Processing Toolbox](https://www.mathworks.com/products/signal.html).

2. Download [Chronux](http://chronux.org/) and add the path to the package into the MATLAB settings for spectral analysis.

3. Create a working folder (ex. `/CURBIO`) and place the folder `/Scripts` under the working folder (/CURBIO/Scripts).

4. Add the path to the subfolder `/CURBIO/Scripts/utils` into the MATLAB.

5. Download all data from the [Google Drive](https://drive.google.com/drive/folders/14tUsFh6X54gpxlsFWoynKT4JRm_1S84h?usp=sharing) and place the folder `/Data` under the same working folder (/CURBIO/Data). Notes: Currently the codes do not support the NWB format data. Please download the data from Google Drive if you want to run the codes.

6. You can start running the codes and see the figures.


## Appendix

Information of the EMG envelope channels (columns 3-6 in `36data`). Only animals with EMG recordings are listed. Please also see Table S1 in the paper.



| Animal ID | EMG envelope #1 | EMG envelope #2 | EMG envelope #3 | EMG envelope #4 |
| ----------- | ----------- | ----------- | ----------- | ----------- | 
| SLR094 | RSP | RSP | LSP | LSP |
| SLR096 | RCT | RSP | LSP | LCT |
| SLR097 | RCT | RSP | LSP | LCT |
| SLR099 | LVI | LNL | RNL | RDN |
| SLR100 | LNS | LDN | RDN | RDN |
| SLR102 | RCT | RCT | LCT | LCT |
| SLR103 | RCT | RCT | LCT | LCT |
| SLR105 | RCT | RCT | LCT | LCT |
| SLR106 | RCT | RCT | LCT | LCT |
| SLR107 | LCM | N/A | N/A | RCM |
| SLR108 | LCM | N/A | RCM | N/A |
| SLR110 | LCM | LSM | RCM | RSM |
| SLR111 | LCM | LSM | RCM | RSM |
| SLR112 | RSP | RBC | LBC | LSP |
| SLR113 | RSP | LSP | RBC | LBC |
| SLR114 | RSM | RSM | LSM | LSM |
| SLR115 | RSP | LSP | RBC | LBC |
| SLR116 | LVI | RVI | LDN | RDN |
| SLR117 | LVI | RVI | LDN | RDN |
| SLR119 | LSM | LCM | LCT | LSP |
| SLR120 | LDN | LCT | LSP | LBC |
| SLR121 | LDN | LCT | LSP | LBC |
| SLR122 | LDN | LSM | LCM | LCT |
| SLR123 | LCM | LCT | LBC | LSM |
| SLR124 | LCM | LSP | LBC | LSM |
| SLR125 | LVI | RVI | LNL | RNL |
| SLR126 | LVI | RVI | LNL | RNL |


<p align="center">
Abbreviations. L: left side, R: right side, SM: sternomastoid, CM: cleidomastoid, CT: clavotrapezius, SP: splenius, BC: biventer cervicis, VI: vibrissa intrinsic, NL: nasolabialis, DN: deflector nasi, NS: nasalis (analysis for nasalis is not published). 
</p>
