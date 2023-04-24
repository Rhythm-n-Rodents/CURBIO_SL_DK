%% Figure 1I

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Edit Line #55. Edit the path to the "Data" folder.
% 2. Run the code.


clc;
clear;
close all;


POOLS = ["SLR087", "d"; ...
         "SLR089", "d"; ...
         "SLR090", "d"; ...
         "SLR092", "d"; ...
         "SLR093", "d"; ...
         "SLR095", "d"; ...
         "SLR096", "h"; ...
         "SLR097", "h"; ...
         "SLR102", "d"; ...
         "SLR103", "d"]; 
     
     
%% Global variables
UNIQUE_ID = 0;

ID2SEQ = containers.Map;
LENGTH2ID = containers.Map;

SEEN_LENGTHS = [];

LONGEST_EPOCH = 0;

rate = 2000;

downsample_steps = 20;
     
for i = 1 : size(POOLS, 1)
    
    animal_ID = char(POOLS(i, 1));
    rec_type = char(POOLS(i, 2));
    
    disp(' ');
    disp([char(animal_ID), ' - ', rec_type]);
    disp(' ');

    %% Change directory
    animal_ID = char(animal_ID);
    cur_folder_path = ['..\..\Data\', animal_ID];  % Edit here
    cd(cur_folder_path)

    %% Load recording list map
    load([animal_ID, '_D_recordingListMap.mat']);
    assert(strcmp(animal_ID, recordingListMap('animal_ID')), '[recordingListMap] animal_ID inconstent');
    
    %% load bBoolsMap
    load([animal_ID, '_D_bBoolsMap.mat']);
    assert(strcmp(animal_ID, bBoolsMap('animal_ID')), '[bBoolsMap] animal_ID inconstent');
    
    
    %% Loading every recorded data
    for recordingIndex = recordingListMap(rec_type)
        %% Load data
        loaded_filename = [animal_ID, '_arena_', rec_type, num2str(recordingIndex), '_D_36data'];
        load(loaded_filename);
        disp([9, '-- ', loaded_filename]);
        SM_checkDataColumnNumber(data, 36);
        
        %% Read foraging epochs
        epochs_excel = readmatrix(['A_', animal_ID, '_annotation_epochs.xlsx'], ...
            'Sheet', 'Epochs', 'Range', ['Epochs_', rec_type, num2str(recordingIndex)]);
        disp([9, 9, str(size(epochs_excel, 1)), ' epochs']);
        
        %% Time shift
        time_shift = 0.0095;
        data = SM_data_time_shift(data, (9:35), time_shift, rate);
        
        %% Denote variables
        time = data(:, 1);
        
        %% Denote booleans
        bBools = bBoolsMap([rec_type, num2str(recordingIndex)]);

        bBools('usable') = SM_data_truncate(bBools('usable'), time_shift, rate, 'tail');

        if strcmp(rec_type, 'd')
            bBools('hbgood') = SM_data_truncate(bBools('hbgood'), time_shift, rate, 'tail');
        end

        lowpitchbool = data(:,10) < -16.5; % -16.5;
        highpitchbool = data(:,10) > 43.5; % 43.5; 
        
        foragebool = and(lowpitchbool, bBools('usable'));
        rearbool = and(highpitchbool, bBools('usable'));
        
        % encode behavioral modes (forage: 1, rear: 2, others: 0)
        encoded_behavioral_modes = zeros(size(foragebool)); % others (0)
        encoded_behavioral_modes(foragebool) = 1;
        encoded_behavioral_modes(rearbool) = 2;
        
        %% Iterate over epochs
        for epi = 1 : size(epochs_excel, 1)
            
            % epoch start/end (unit: video frame)
            epoch_start_vf = epochs_excel(epi, 1);
            epoch_end_vf = epochs_excel(epi, 2);
            
            if epochs_excel(epi, 3) < 0
                continue
            end
           
            % skip if epoch start/end is undefined
            if epoch_start_vf == -1
                continue
            end
            
            if epoch_end_vf == -1
                continue
            end
            
            % epoch start/end (unit: time in the recording)
            epoch_start_t = 1 + (epoch_start_vf - 1)/20;
            epoch_end_t = 1 + (epoch_end_vf - 1)/20;
            
            if or(epoch_start_t < time(1), epoch_end_t > time(end))
                continue
            end
            
            % skip long epochs
            if (epoch_end_t - epoch_start_t) > 150
                continue
            end
            
            % epoch start/end (unit: frames in 36data format)
            t0 = time(1);
            d = 1/rate;
            epoch_start_f = round(1 + (epoch_start_t-t0)/d);
            epoch_end_f = round(1 + (epoch_end_t-t0)/d);
            
            
            
            % data in the epoch window
            UNIQUE_ID = UNIQUE_ID + 1;
            UNIQUE_ID_str = str(UNIQUE_ID);
            
            epoch_length = epoch_end_f - epoch_start_f + 1;
            epoch_length_str = str(epoch_length);
            
            
            epoch_modes_seq = encoded_behavioral_modes(epoch_start_f: epoch_end_f);
            
            % downsample
            epoch_modes_seq = downsample(epoch_modes_seq, downsample_steps);

            
            % save to dict
            ID2SEQ(UNIQUE_ID_str) = epoch_modes_seq;
            
            if ~ismember(epoch_length, SEEN_LENGTHS)
                SEEN_LENGTHS = [SEEN_LENGTHS, epoch_length];
                LENGTH2ID(epoch_length_str) = [];
            end
            
            LENGTH2ID(epoch_length_str) = [LENGTH2ID(epoch_length_str), UNIQUE_ID];
            
            % update longest epoch
            LONGEST_EPOCH = max(LONGEST_EPOCH, epoch_length);
        end
    end
end


%% Sort epochs by the lengths
SEEN_LENGTHS = sort(SEEN_LENGTHS);


%% Figure 1I
max_len = length(downsample((0:max(SEEN_LENGTHS)), downsample_steps));

marg_all = zeros(max_len, 1);
marg_forage = zeros(max_len, 1);
marg_rear = zeros(max_len, 1);

rev_marg_all = zeros(max_len, 1);
rev_marg_forage = zeros(max_len, 1);
rev_marg_rear = zeros(max_len, 1);

% iterate over distinct epoch lenghs
for i = 1 : length(SEEN_LENGTHS)
    
    % epoch lenths
    orig_len = SEEN_LENGTHS(i);
    
    % valid epochs
    cur_trial_ids = LENGTH2ID(str(orig_len));
    
    for ep_i = 1 : length(cur_trial_ids)
        
        % current epoch id
        cur_id = cur_trial_ids(ep_i);
        
        % current epoch sequence
        cur_seq = ID2SEQ(str(cur_id));
                
        % seqs for different behavioral modes
        sample_len = length(cur_seq);
        
        % update marginal
        marg_all(1:sample_len) = marg_all(1:sample_len) + 1;
        marg_forage(1:sample_len) = marg_forage(1:sample_len) + (cur_seq == 1);
        marg_rear(1:sample_len) = marg_rear(1:sample_len) + (cur_seq == 2);
        
        rev_marg_all(end-sample_len+1 : end) = rev_marg_all(end-sample_len+1 : end) + 1;
        rev_marg_forage(end-sample_len+1 : end) = rev_marg_forage(end-sample_len+1 : end) + (cur_seq == 1);
        rev_marg_rear(end-sample_len+1 : end) = rev_marg_rear(end-sample_len+1 : end) + (cur_seq == 2);
    end
end 

marg_x = (0:max_len-1)./(rate/downsample_steps);

figure(4)
set(gcf, 'Color', 'w', 'Position', [100, 100, 700, 200], 'DefaultAxesFontSize', 12);
hold on
yyaxis left
plot(marg_x-max(marg_x), rev_marg_forage, '.', 'Color', rgb(0, 115, 189), 'MarkerSize', 1);
ylim([1, 1000]);yticks([1, 10, 100, 1000]);
set(gca, 'YScale', 'log')
yyaxis right
plot(marg_x-max(marg_x), rev_marg_rear, '.', 'Color', rgb(217, 84, 26), 'MarkerSize', 1);
ylim([1, 100]);yticks([1, 10, 100]);
xlim([-150, 0]); xticks((-150:50:0));
set(gca, 'YScale', 'log'); hold off

figure(5)
set(gcf, 'Color', 'w', 'Position', [100, 100, 700, 200], 'DefaultAxesFontSize', 12);
hold on
yyaxis left
plot(marg_x-max(marg_x), rev_marg_forage./rev_marg_all, '.', 'Color', rgb(0, 115, 189), 'MarkerSize', 1);
ylim([0, 1]); yticks((0:0.5:1));
yyaxis right
plot(marg_x-max(marg_x), rev_marg_rear./rev_marg_all, '.', 'Color', rgb(217, 84, 26), 'MarkerSize', 1);
ylim([0, 0.2]); yticks((0:0.1:0.2));
xlim([-150, 0]); xticks((-150:50:0));
hold off
