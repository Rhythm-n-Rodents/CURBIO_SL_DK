%% run_mat2map.m

% This code generates MATLAB containers.Map required for analysis.
% Before running this code, please run the /nwb2mat/run_nwb2mat.py first.

clear
clc
close all


%% General parameters

src_folder = '../Data';

if ~exist(src_folder, 'dir')
   error('The ../Data folder does not exist. Please make sure you have run run_nwb2mat.py before running this code.');
end


%% Extract subject information
% list all files in ../Data
src_contents = dir(src_folder);

% all subfolders in ../Data
src_subfolders = src_contents([src_contents(:).isdir]);

% remove . and .. from the list
src_subfolders = src_subfolders(~ismember({src_subfolders(:).name},{'.','..'}));

% check the number of subjects
assert(length(src_subfolders) == 33, ...
    ['The number of subject subfolders is not correct (should be 33 but got ', num2str(length(src_subfolders)), ').']);

src_subfolders = struct2table(src_subfolders);

% extract the list of the animals
subject_ids = src_subfolders(:, 1);
disp('Subject IDs:');
disp(subject_ids);
disp('=============');

clear src_contents src_subfolders 


%% subject level - recordingListMap.mat
% Convert ../Data/<subject_id>/<subject_id>_D_recordingListMat.mat to a
% Container Map

% iterate over the subjects
for subject_cell_i = 1 : size(subject_ids, 1)

    % extract subject_id (str)
    subject_id = subject_ids{subject_cell_i, 1};
    subject_id = subject_id{1, 1};
    disp(' ');
    disp(subject_id);

    % subject subfolder
    subject_subfolder = [src_folder, '/', subject_id, '/'];
    disp(['  >> file will be save to: ', subject_subfolder]);


    %% [Task 1] Convert recordingListMat.mat > recordingListMap.mat
    % load mat file
    load([subject_subfolder, subject_id, '_D_recordingListMat.mat']);
    
    % create map
    recordingListMap = containers.Map;
    recordingListMap('animal_ID') = subject_id;
    
    % update recording list
    for row_i = 1 : size(recordingListMat, 1)
        rec_type = char(recordingListMat{row_i, 1});
        rec_idx = str2double(char(recordingListMat{row_i, 2}));
        
        % check if rec_type is alreaded stored as a key
        if isKey(recordingListMap, rec_type)
            % update list and sort (won't be too slow because N < 30)
            recordingListMap(rec_type) = sort([recordingListMap(rec_type), rec_idx]);
        else
            % initiate list
            recordingListMap(rec_type) = rec_idx;
        end
    end

    % save map
    save([subject_subfolder, subject_id, '_D_recordingListMap.mat'], 'recordingListMap');
    disp('  >> recordingListMap.mat is saved');

    % (Notes) we keep the recordingListMap in the Workspace for future use
    clear recordingListMat rec_type rec_idx
    
    
    %% [Task 2] Combine <session_id>_D_vfbMat.mat into videoFrameBoundaries
    % create map
    dic_VFBs = containers.Map;
    dic_VFBs('animal_ID') = subject_id;
    
    for rec_type = ['h', 'd']
        % if rec_type exists
        if isKey(recordingListMap, rec_type)
            % iterate over the recording indices
            for rec_idx = recordingListMap(rec_type)
                % session id
                session_id = [subject_id, '_arena_', rec_type, num2str(rec_idx)];

                % load vfbMat
                load([subject_subfolder, session_id, '_D_vfbMat.mat']);

                % update map
                dic_VFBs([rec_type, num2str(rec_idx)]) = double(vfbMat);

                clear vfbMat
            end
        end
    end

    % save map
    save([subject_subfolder, subject_id, '_D_videoFrameBoundaries.mat'], 'dic_VFBs');
    disp('  >> videoFrameBoundaries.mat is saved');

    clear dic_VFBs


    %% [Task 3] Combine <session_id>_D_bBoolsMat.mat into bBoolsMap
    % create map
    bBoolsMap = containers.Map;
    bBoolsMap('animal_ID') = subject_id;
    
    for rec_type = ['h', 'd']
        % if rec_type exists
        if isKey(recordingListMap, rec_type)
            % iterate over the recording indices
            for rec_idx = recordingListMap(rec_type)
                % session id
                session_id = [subject_id, '_arena_', rec_type, num2str(rec_idx)];

                % load bBoolsMat
                load([subject_subfolder, session_id, '_D_bBoolsMat.mat']);

                % temp session map ('usable', 'hbgood', 'b3')
                tmp_map = containers.Map;
                tmp_map('usable') = bBoolsMat(:, 1);
                tmp_map('hbgood') = bBoolsMat(:, 2);
                tmp_map('b3') = bBoolsMat(:, 3);

                % update map
                bBoolsMap([rec_type, num2str(rec_idx)]) = tmp_map;
                clear tmp_map
            end
        end
    end

    % save map
    save([subject_subfolder, subject_id, '_D_bBoolsMap.mat'], 'bBoolsMap');
    disp('  >> bBoolsMap.mat is saved');

    clear bBoolsMap


    %% [Task 4] Convert <subject_id>_D_pctsTable.mat into <subject_id>_D_percentiles_36data.mat
    % create struct
    percentiles = struct;
    percentiles.animal_ID = subject_id;

    % create map
    pcts = containers.Map;

    % load <subject_id>_D_pctsTable.mat
    load([subject_subfolder, subject_id, '_D_pctsTable.mat']);

    % iterate over rows in the pctsTable
    for row_i = 1 : size(pctsTable, 1)
        key1 = pctsTable{row_i, 1};
        key2 = pctsTable{row_i, 2};
        val = str2double(pctsTable{row_i, 3});

        % check if key1 is in pcts
        if ~isKey(pcts, key1)
            pcts(key1) = containers.Map;
        end

        % update key2 into key1
        map_copy = pcts(key1);
        map_copy(key2) = val;
        pcts(key1) = map_copy;
    end
    
    % update struct
    percentiles.pcts = pcts;

    clear pcts

    % save struct
    save([subject_subfolder, subject_id, '_D_percentiles_36data.mat'], '-struct', 'percentiles');
    disp('  >> percentiles_36data.mat is saved');

    clear percentiles
end

disp(' ');
disp('============= Completed =============');




























