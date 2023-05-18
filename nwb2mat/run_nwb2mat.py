"""
run_nwb2mat.py
Process the nwb files and convert into matlab files
"""

import os
import sys
import argparse
import numpy as np
import pandas as pd
import pynwb
import xlsxwriter
from scipy.io import savemat

# parse the args
parser = argparse.ArgumentParser(description='Convert from NWB format to MATLAB format')
parser.add_argument('--src_dir', type=str, default='./000540', help='The path to the 000540 NWB Dandiset folder')
parser.add_argument('--dest_dir', type=str, default='./Data', help='The path to stored the MATLAB files')
args = parser.parse_args()

# load nwb file names mapping
df = pd.read_csv('nwb_filenames.csv', header=0)

# create a dictionary to store the full session ids for each subject id
# key: 'SLRXXX', val: ['SLRXXX_arena_d1', 'SLRXXX_arena_d2', 'SLRXXX_arena_d3', 'SLRXXX_arena_d4', ...]
sub2fullses = dict()

# create a dictionary to store the abbreviated session ids for each subject id
# key: 'SLRXXX', val: ['d1', 'd2', 'd3', 'd4', ...]
sub2ses = dict()

# a set that stores the subjects whose percentiles have been processed
percentile_processed = set()

# a set that stores the subjects whose supplemental annotations have been initiated
annotation_initiated = set()
wb = None

"""
Session-level data
"""

# iterate all rows
for i in range(df.shape[0]):

    # subject id
    subject_id = df.iloc[i]['subject_id']

    # session id
    session_id = df.iloc[i]['session_id']
    print("\n" + session_id)

    # update dictionary
    sub2fullses[subject_id] = sub2fullses.get(subject_id, []) + [session_id]
    sub2ses[subject_id] = sub2ses.get(subject_id, []) + [session_id.split('_')[-1]]
    
    # nwb unique identifier
    nwb_id = df.iloc[i]['nwb_object_id']
    if nwb_id == '<NONE>':
        nwb_id = ''
    else:
        nwb_id = '_obj-' + nwb_id

    # session time
    session_time = df.iloc[i]['session_start_time'].replace('-', '')
    
    # directory of the subject
    nwb_subdir = os.path.join(args.src_dir ,'sub-' + subject_id)

    # filename of the NWB file
    nwb_filename = 'sub-' + subject_id + '_ses-' + session_time + nwb_id + '_behavior+image.nwb'

    # path to the nwb file
    nwb_filepath = os.path.join(nwb_subdir, nwb_filename)

    # check the file exist
    if not os.path.exists(nwb_filepath):
        sys.exit("ERROR: {} does not exist!".format(nwb_filepath))
    
    # load nwb
    with pynwb.NWBHDF5IO(nwb_filepath, "r") as io:
        read_nwbfile = io.read()

        ## extract 36 data (set the next line to True)
        if True:
            data = read_nwbfile.processing['data_36columns']['data_36columns']['data_36columns'].data[:]
            assert data.shape[1] == 36

            # save as mat
            destdir = os.path.join(args.dest_dir, subject_id)
            if not os.path.exists(destdir):
                os.makedirs(destdir)
            savemat(os.path.join(destdir, session_id + '_D_36data.mat'), {'data': data})
            print("  >> 36data extracted")

        
        # extract arena_ellipse_params.mat (set the next line to True)
        if True:
            ellipse_params = read_nwbfile.acquisition['ImageSeries'].comments[:].strip()
            if ellipse_params:
                # output dict
                out_dict = {}

                ellipse_params = ellipse_params.split(';')

                for param in ellipse_params:
                    if param:
                        param_content = param.split(':')
                        param_name, param_value = param_content[0].strip(), param_content[1].strip()
                        out_dict[param_name] = float(param_value)
                        
                # save as mat (struct)
                destdir = os.path.join(args.dest_dir, subject_id)
                if not os.path.exists(destdir):
                    os.makedirs(destdir)
                savemat(os.path.join(destdir, session_id + '_D_arena_ellipse_params.mat'), {'ellipse_params': out_dict})
                print("  >> ellipse params extracted")


        # extract videoDLC_torso.csv (set the next line to True)
        if True:
            if 'torso_dlc' in read_nwbfile.processing:
                torso_dlc = read_nwbfile.processing['torso_dlc']['torso_dlc']['torso_dlc'].data[:]
                assert torso_dlc.shape[1] == 4

                # save as csv
                destdir = os.path.join(args.dest_dir, subject_id)
                if not os.path.exists(destdir):
                    os.makedirs(destdir)
                
                pd.DataFrame(torso_dlc).to_csv(os.path.join(destdir, session_id + '_D_videoDLC_torso.csv'), header=False, index=False)
                print("  >> torso DLC tracking extracted")


        # extract bBoolsMap.mat and save as a MATLAB matrix (set the next line to True)
        if True:
            bBoolsMat = read_nwbfile.processing['behavioral_booleans']['analysis']['analysis'].data[:]
            assert bBoolsMat.shape[1] == 3

            # save as mat
            destdir = os.path.join(args.dest_dir, subject_id)
            if not os.path.exists(destdir):
                os.makedirs(destdir)
            savemat(os.path.join(destdir, session_id + '_D_bBoolsMat.mat'), {'bBoolsMat': bBoolsMat})
            print("  >> bBools mat extracted >> Please run the run_mat2map.m MATLAB code after completion.")


        # extract videoFrameBoundaries as a MATLAB matrix (set the next line to True)
        if True:
            vfbs = read_nwbfile.notes[:].split('|')[1].strip().split(',')
            assert vfbs[0].strip() == 'Video Boundary'

            vfb_start, vfb_end = int(vfbs[1].strip()), int(vfbs[2].strip())
            
            # save as mat
            destdir = os.path.join(args.dest_dir, subject_id)
            if not os.path.exists(destdir):
                os.makedirs(destdir)
            savemat(os.path.join(destdir, session_id + '_D_vfbMat.mat'), {'vfbMat': [vfb_start, vfb_end]})
            print("  >> video frame boundaries extracted >> Please run the run_mat2map.m MATLAB code after completion.")


        # extract percentiles (set the next line to True)
        if True:
            # only proceed if the subject hasn't been processed
            if subject_id not in percentile_processed:

                percentiles = read_nwbfile.processing['signal_percentiles']['processing']['processing'].data[:]
                assert percentiles.shape[1] == 2

                # create a new table
                pcts_df = pd.DataFrame(percentiles, columns=['ref', 'val'])

                pcts_df['key1'] = pcts_df['ref'].map(lambda x: x.split('|')[0])
                pcts_df['key2'] = pcts_df['ref'].map(lambda x: x.split('|')[1][3:])

                # drop ref column
                pcts_df = pcts_df.drop(columns=['ref'])

                # reorder columns
                pcts_df = pcts_df[['key1', 'key2', 'val']]
            
                # save file
                destdir = os.path.join(args.dest_dir, subject_id)
                if not os.path.exists(destdir):
                    os.makedirs(destdir)

                savemat(os.path.join(destdir, subject_id + '_D_pctsTable.mat'), {'pctsTable': pcts_df.to_numpy()})
                print("  >> Subject percentiles extracted >> Please run the run_mat2map.m MATLAB code after completion.")

                # mark subject as processed
                percentile_processed.add(subject_id)

            else:
                print("  >> Subject percentiles skipped (has been processed).")

        
        # extract supplemental annotations (set the next line to True)
        if True:
            # close the previous workbook if we moved to the next subject
            if (subject_id not in annotation_initiated) and wb:
                wb.close()
                wb = None

            supp_annotation = read_nwbfile.stimulus_notes[:].split('|')
            assert supp_annotation[0] == 'epoch_start,epoch_end,epoch_status,pellet_loc_X,pellet_loc_Y,pellet_loc_status'
            assert supp_annotation[-1].strip() == ''

            supp_annotation = supp_annotation[1:-1]

            # conditition when supplemental annotations exist
            if not (len(supp_annotation) == 1 and supp_annotation[0].strip() == 'nan,nan,nan,nan,nan,nan'):

                # check if it's necessary to create the FoodLocs worksheet
                if supp_annotation[-1].strip().split(',')[-3:] == ['nan', 'nan', 'nan']:
                    foodlocs_exists = False
                else:
                    foodlocs_exists = True
                
                # create the xlsx file or resume working on an open xlsx file
                if subject_id not in annotation_initiated:
                    if wb:
                        wb.close()
                    
                    # path to save the annotation
                    destdir = os.path.join(args.dest_dir, subject_id)
                    if not os.path.exists(destdir):
                        os.makedirs(destdir)

                    wb = xlsxwriter.Workbook(os.path.join(destdir, 'A_' + subject_id + '_annotation_epochs.xlsx'))
                    ws_epochs = wb.add_worksheet('Epochs')

                    if foodlocs_exists:
                        ws_foodlocs = wb.add_worksheet('FoodLocs')

                    cur_col = 0
                    annotation_initiated.add(subject_id)

                # number of entries to fill in
                num_rows = len(supp_annotation)

                # helper function for filling information
                def help_func(x):
                    return x if x == 'nan' else float(x)

                # fill in the sheets
                # start and end column indices (alphabet)
                start_alphabet = xlsxwriter.utility.xl_col_to_name(cur_col)
                end_alphabet = xlsxwriter.utility.xl_col_to_name(cur_col+2)

                for ri in range(len(supp_annotation)):
                    row = supp_annotation[ri].strip().split(',')
                    assert len(row) == 6
                    
                    # write Epochs sheet
                    ws_epochs.write(ri, cur_col, help_func(row[0]))
                    ws_epochs.write(ri, cur_col+1, help_func(row[1]))
                    ws_epochs.write(ri, cur_col+2, help_func(row[2]))

                    # write FoodLocs sheet
                    if foodlocs_exists:
                        ws_foodlocs.write(ri, cur_col, help_func(row[3]))
                        ws_foodlocs.write(ri, cur_col+1, help_func(row[4]))
                        ws_foodlocs.write(ri, cur_col+2, help_func(row[5]))

                # define Names (note that it's 1-indexed)
                namefield_range = '$' + start_alphabet + '$1:$' + end_alphabet + '$' + str(ri+1)

                wb.define_name('Epochs_' + session_id.split('_')[-1], '=Epochs!' + namefield_range)
                print("  >> Supplemental annotation (Epochs) extracted and copied to {}".format(namefield_range))

                if foodlocs_exists:
                    wb.define_name('FoodLocs_' + session_id.split('_')[-1], '=FoodLocs!' + namefield_range)
                    print("  >> Supplemental annotation (FoodLocs) extracted and copied to {}".format(namefield_range))

                # advance the column for the next session
                cur_col += 3


"""
Subject-level data
"""

# check if we have 33 distinct subject ids
assert len(sub2ses) == 33

# extract recording list for each subject (set the next line to True)
if True:
    # iterate over subject ids
    for subject_id in sorted(sub2ses.keys()):
        print("\n" + subject_id)

        recordingList_np = np.array(sorted(sub2ses[subject_id], key=lambda x: (x[0], int(x[1:]))))
        recordingList_df = pd.DataFrame(recordingList_np, columns=['rec'])

        # rec type and indices
        recordingList_df['rec_type'] = recordingList_df['rec'].map(lambda x: x[0])
        recordingList_df['rec_idx'] = recordingList_df['rec'].map(lambda x: x[1:])
        # drop
        recordingList_df = recordingList_df.drop(columns=['rec'])
        # convert to numpy
        recordingListMat = recordingList_df.to_numpy()
        assert recordingListMat.shape[1] == 2

        # save
        destdir = os.path.join(args.dest_dir, subject_id)
        if not os.path.exists(destdir):
            os.makedirs(destdir)
        savemat(os.path.join(destdir, subject_id + '_D_recordingListMat.mat'), {'recordingListMat': recordingListMat})
        print("  >> Subject recording list extracted >> Please run the run_mat2map.m MATLAB code after completion.")


print("\n\n========== Completed. ==========")
