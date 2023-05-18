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

1. Download from Google Drive (original format)
2. Download from DANDI ([NWB](https://www.nwb.org/nwb-neurophysiology/) format)


Codes on this repository can be run directly on the data downloaded from Google Drive. Conversion of data from the DANDI (in NWB format) to the original format is needed before running the codes for analysis and figure generation. Conversion code is available in the folder `/nwb2mat`. Instructions are provided in the following sections.


---

### 1. Download from Google Drive (original format)

Link to the [Google Drive](https://drive.google.com/drive/folders/14tUsFh6X54gpxlsFWoynKT4JRm_1S84h?usp=sharing). Please contact the authors for access.

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

Link to DANDI [Dandiset](https://dandiarchive.org/dandiset/000540?pos=1).

| Data format (Google Drive) | Data format (NWB) | Notes |
| ----------- | ----------- | ----------- |
| `<session_id>_D_36data.mat` | `processing` >> `data_36columns` >> `data_36columns` >> `data_36columns` >> `data` | Stored as a matrix of shape `(N, 36)`. Information of each column can be found in the table of the previous section. |
| `<session_id>_D_LCmat.mat` | `processing` >> `raw_labchart_data` >> `raw_labchart_data` >> `raw_labchart_data` >> `data` | Stored as a 1-D column. Multiple channels exported by LabChart is contactnated vertically [channel_1; channel_2; ...]. Start and end indices for each LabChart channel is stored in the `unit` attribute as a string of `"(CH1_START_INDEX, CH1_END_INDEX), (CH2_START_INDEX, CH2_END_INDEX), ..."`. |
| `<session_id>_D_video.avi` | `acquisition` >> `ImageSeries` >> `external_file` | Stored as a symbolic link to the corresponding video file (avi). |
| `<session_id>_D_excel.xlsx` | `processing` >> `raw_sensor_data` >> `raw_sensor_data` >> `raw_sensor_data` >> `data` | Stored as a matrix of shape (num_samples, num_channels). For recording with head sensor only, yaw/pitch/roll angles of the head is stored in the first 3 columns. For recording with both head and torso sensors, y/p/r angles of the torso is stored in the first 3 columns and y/p/r angles of the head is stored in the first 3 columns of the second half of the columns. |
| `<session_id>_D_eventLog.mat` | `general` >> `notes` | Each annotated miscellaneous behavior (ex. grooming) is stored as a string: `"Unusable Behavior, <START_FRAME>, <END_FRAME>"`, separated by `" \| "`. The values refer to the frame indices of the video file `<session_id>_D_video.avi`. |
| `<session_ID>_D_videoDLC_torso.csv` | `processing` >> `torso_dlc` >> `torso_dlc` >> `torso_dlc` >> `data` | Stored as a matrix. X, Y coordinates (if torso sensor is used) are the second and third columns. |
| `<session_ID>_D_arena_ellipse_params.mat` | `acquisition` >> `ImageSeries:comments` | Stored in the `comments` attribute as a string. |
| `A_<animal ID>_annotation_epochs_transposed.xlsx` | `general` >> `stimulus` | Supplemental annotation is stored as a string: `"EPOCH_START_FRAME, EPOCH_END_FRAME, EPOCH_STATUS, PELLET_LOC_X, PELLET_LOC_Y, PELLET_STATUS"`. Multiple annotations are concatenated with `"\|"`. |
| `<animal_id>_D_bBoolsMap.mat` | `processing` >> `behavioral_booleans` >> `analysis` >> `analysis` >> `data` | Stored as a matrix of 3 columns: `<Usable>`, `<Head-Torso>`, and `<Usable AND Head-Torso>`. |
| `<animal_id>_percentiles_36data.mat` | `processing` >> `signal_percentiles` >> `processing` >> `processing` >> `data` | Stored as a matrix of 2 columns. The first column (str) specifies the signal from which a specific percentile is calculated. For example, `"d_27\|pct10"` gives the 10-th percentile of the 27th column (head yaw velocity) in `36data`. The second column stores the corresponding numerical value. |
| `<animal_id>_recordingListMap.mat` | N/A | List of the recording indeces is not required for NWB. Each NWB file is created from a single session |
| `<animal_id>_videoFrameBoundaries.mat` | `general` >> `notes` | Stored as a string: `"Video Boundary, <START_FRAME>, <END_FRAME>"` to be synchronized with the first and last sample of `<session_ID>_D_36data.mat`. |

<p align="center">
Details of data conversion from Google Drive to DANDI.
</p>


## Code

Codes (MATLAB) are available in the `/Scripts` folder, which contains the following subfolders:

- `/Scripts/codes_for_figures` contains the codes that can generate the figures. Please see the comments in the files for more information.
- `/Scripts/codes_for_supplemental_figures` contains the codes that can generate the supplemental figures. Please see the comments in the files for more information.
- `/Scripts/utils` contains the helper codes that are called by the other scripts.


## How to run the code

### Step 1: Prepare the software and packages

1. Install [MATLAB](https://www.mathworks.com/products/matlab.html?s_tid=hp_products_matlab) and the [MATLAB Signal Processing Toolbox](https://www.mathworks.com/products/signal.html).

2. Download [Chronux](http://chronux.org/) and add the path to the package into the MATLAB settings for spectral analysis.

3. Create a working folder (ex. `/CURBIO`) and place the folder `/Scripts` under the working folder (/CURBIO/Scripts).

4. Add the path to the subfolder `/CURBIO/Scripts/utils` into the MATLAB.

### Step 2: Download the dataset

Choose **one** of the two options below to donwload the dataset:

#### Option 1 - Download from Google Drive

1. Contact the authors for access and download all data from the [Google Drive](https://drive.google.com/drive/folders/14tUsFh6X54gpxlsFWoynKT4JRm_1S84h?usp=sharing).

2. Place the folder `/Data` under the same working folder that was created in "Step 1" (i.e., `/CURBIO/Data`).

#### Option 2 - Download from DANDI Archive

1. Download the dataset (Dandiset) from DANDI [Dandiset](https://dandiarchive.org/dandiset/000540?pos=1). Place the folder `/000540` under the working folder (i.e., `/CURBIO/000540`)

2. Download the folder `/nwb2mat` from this repository and place into the same working folder (i.e., `/CURBIO/nwb2mat`).

3. Create a Python virtual environment (for example, using [Anaconda](https://www.anaconda.com/)).

4. Install these packages in the environment:

    - numpy ([install using conda](https://anaconda.org/anaconda/numpy))
    - pandas ([install using conda](https://anaconda.org/conda-forge/pandas))
    - pynwb ([install using conda](https://anaconda.org/conda-forge/pynwb))
    - xlsxwriter ([install using pip](https://xlsxwriter.readthedocs.io/getting_started.html))
    - scipy ([install using conda](https://anaconda.org/conda-forge/scipy))

5. In the terminal, move to the `CURBIO` folder and run `/nwb2mat/run_nwb2mat.py` by the command below. It will create a folder `Data` to store data

    ```
    cd <PATH_TO_CURBIO>
    
    python nwb2mat/run_nwb2mat.py --src_dir ./000540 --dest_dir ./Data
    ```

6. Open and run `/nwb2mat/run_mat2map.m`. It will further process the data in `Data` and complete the full conversion.

Please note that Step 6 must be run after the completion of Step 5.

### Step 3: Perform analysis

You can start running the codes and see the figures in this study.


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
