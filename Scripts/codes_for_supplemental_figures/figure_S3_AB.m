%% Figure S3AB

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Edit Line #49. Edit the path to the "Data" folder.
% 2. Run the code.


clc;
clear;
close all;

%% Run on multiple animals
animal_IDs = ["SLR087", "SLR089", "SLR090", "SLR092", "SLR093", "SLR095", ...
              "SLR102", "SLR103", "SLR105", "SLR106", "SLR108", "SLR110", ...
              "SLR111", "SLR112", "SLR113", "SLR115", "SLR119"];
          
rec_type = 'd';
behavior = 'high';

% edges and bins for head-torso yaw angle distribution
htang_edges = (-60:3:60)';
htang_bins = (htang_edges(1:end-1) + htang_edges(2:end))/2;
    
% data from all animals
allanimals_htang_ins_cw = [];  % instantaneous htang at CW INS
allanimals_htang_exp_cw = [];  % instantaneous htang at CW EXP

allanimals_htang_ins_ccw = [];  % instantaneous htang at CCW INS
allanimals_htang_exp_ccw = [];  % instantaneous htang at CCW EXP


for animal_i = 1 : length(animal_IDs)

    %% Iterate over animals
    animal_ID = char(animal_IDs(animal_i));
    disp(animal_ID);
    disp(' ');

    % MPU peaks
    MPU_LOWER_PCT = '75';

    %% Setting muscle indeces and params
    animal_ID = char(animal_ID);
    cur_folder_path = ['..\..\Data\', animal_ID];  % Edit here
    cd(cur_folder_path)

    %% Specigy range of yaw movement rate
    SET_MPU_FMIN = true;
    mpu_fmin = 6;
    SET_MPU_FMAX = true;
    mpu_fmax = 10;

    %% Specify range of breathing rate
    SET_BREATHING_FMIN = true;
    breathing_fmin = 6;
    SET_BREATHING_FMAX = true;
    breathing_fmax = 10;

    %% Sampling rate
    rate = 2000;

    %% Load recording list map
    load([animal_ID, '_D_recordingListMap.mat']);
    assert(strcmp(animal_ID, recordingListMap('animal_ID')), '[recordingListMap] animal_ID inconstent');

    %% Load bBoolsMap
    load([animal_ID, '_D_bBoolsMap.mat']);
    assert(strcmp(animal_ID, bBoolsMap('animal_ID')), '[bBoolsMap] animal_ID inconstent');

    %% Load percentiles
    load([animal_ID, '_D_percentiles_36data.mat']);
    assert(strcmp(animal_ID, percentiles.animal_ID), '[percentiles] animal_ID inconstent');
    pcts = percentiles.pcts;

    %% INS-EXP SWPS
    INS_PHI_RANGE = [55-45, 55+45];
    EXP_PHI_RANGE = [245-45, 245+45];

    %% Data Preallocation
    % head-torso angle
    INS_CW_HTANG = [];
    EXP_CW_HTANG = [];
    INS_CCW_HTANG = [];
    EXP_CCW_HTANG = [];

    %% Color Code
    INS_COLOR = rgb(72, 209, 204);
    EXP_COLOR = rgb(199, 21, 133);

    %% Iterate over recordings
    for recordingIndex = recordingListMap(rec_type)

        %% Load data
        loaded_filename = [animal_ID, '_arena_d', num2str(recordingIndex), '_D_36data'];

        load(loaded_filename);
        disp([9, ' - ', loaded_filename]);

        SM_checkDataColumnNumber(data, 36);

        %% Time shift
        time_shift = 0.0095;
        data = SM_data_time_shift(data, (9:35), time_shift, rate);

        %% Allowed booleans
        bBools = bBoolsMap([rec_type, num2str(recordingIndex)]);
        
        bBools('b3') = SM_data_truncate(bBools('b3'), time_shift, rate, 'tail');
        bBools('usable') = SM_data_truncate(bBools('usable'), time_shift, rate, 'tail');
        
        if strcmp(behavior, 'low')
            alwbool = and(bBools('b3'), data(:,10) < -16.5);
        elseif strcmp(behavior, 'high')
            alwbool = and(bBools('b3'), data(:,10) > 43.5);
        else
            error('Undefined behavior');
        end

        %% Data Assignment
        breathing = data(:,36);
        % head
        hang = data(:,9);
        % torso
        tang = data(:,18);
        % head-torso
        htang = hang - tang;
        htang_mean = mean(htang(bBools('b3')));
        htang = htang - htang_mean;
        htvel = data(:,33);

        SM_checkDataColumnNumber(data, 36);

        %% Breathing processing
        [breathing_onsets, breathing_lengths, breathing_postinsp] = ...
            SM_breathing_processing(breathing, rate, alwbool, SET_BREATHING_FMAX, SET_BREATHING_FMIN, breathing_fmax, breathing_fmin);

        if isempty(breathing_onsets)
            continue
        end

        %% MPU processing: head-torso velocity
        % clockwise
        htvel_cw_pcts = pcts([rec_type, '_33']);
        htvel_cw_min_h = htvel_cw_pcts(MPU_LOWER_PCT);
        htvel_cw_min_p = 0.5*htvel_cw_pcts('std');

        [htvel_cw_peaks, ~] = SM_signalPeakDetection(htvel, rate, alwbool, htvel_cw_min_h, htvel_cw_min_p, SET_MPU_FMAX, SET_MPU_FMIN, mpu_fmax, mpu_fmin);

        % counterclockwise
        htvel_ccw_pcts = pcts([rec_type, '_-33']);
        htvel_ccw_min_h = htvel_ccw_pcts(MPU_LOWER_PCT);
        htvel_ccw_min_p = 0.5*htvel_ccw_pcts('std');

        [htvel_ccw_peaks, ~] = SM_signalPeakDetection(-htvel, rate, alwbool, htvel_ccw_min_h, htvel_ccw_min_p, SET_MPU_FMAX, SET_MPU_FMIN, mpu_fmax, mpu_fmin);


        %% INS & EXP head-torso velocity peaks classification
        if ~isempty(htvel_cw_peaks)
            [ins_cw, exp_cw] = SM_ins_exp_classification(htvel_cw_peaks, breathing_onsets, breathing_lengths, INS_PHI_RANGE, EXP_PHI_RANGE);
            INS_CW_HTANG = [INS_CW_HTANG ; htang(ins_cw)];
            EXP_CW_HTANG = [EXP_CW_HTANG ; htang(exp_cw)];
        end
        
        if ~isempty(htvel_ccw_peaks)
            [ins_ccw, exp_ccw] = SM_ins_exp_classification(htvel_ccw_peaks, breathing_onsets, breathing_lengths, INS_PHI_RANGE, EXP_PHI_RANGE);
            INS_CCW_HTANG = [INS_CCW_HTANG ; htang(ins_ccw)];
            EXP_CCW_HTANG = [EXP_CCW_HTANG ; htang(exp_ccw)];
        end
        

    end 
        
    %% Append data from all animals together
    allanimals_htang_ins_cw = [allanimals_htang_ins_cw ; INS_CW_HTANG];
    allanimals_htang_exp_cw = [allanimals_htang_exp_cw ; EXP_CW_HTANG];

    allanimals_htang_ins_ccw = [allanimals_htang_ins_ccw ; INS_CCW_HTANG];
    allanimals_htang_exp_ccw = [allanimals_htang_exp_ccw ; EXP_CCW_HTANG];
    
end

disp(['Number of CW INS: ', str(length(allanimals_htang_ins_cw))]);
disp(['Number of CCW INS: ', str(length(allanimals_htang_ins_ccw))]);
disp(['Number of CW EXP: ', str(length(allanimals_htang_exp_cw))]);
disp(['Number of CCW EXP: ', str(length(allanimals_htang_exp_ccw))]);


%% Change bins and edges
htang_edges = (-60:6:60)';
htang_bins = (htang_edges(1:end-1) + htang_edges(2:end))/2;


%% Hiscounts
histcnt_ins_ccw = histcounts(allanimals_htang_ins_ccw, htang_edges, 'Normalization', 'pdf');
histcnt_exp_ccw = histcounts(allanimals_htang_exp_ccw, htang_edges, 'Normalization', 'pdf');
histcnt_ins_cw = histcounts(allanimals_htang_ins_cw, htang_edges, 'Normalization', 'pdf');
histcnt_exp_cw = histcounts(allanimals_htang_exp_cw, htang_edges, 'Normalization', 'pdf');


%% Two-sample Kolmogorov-Smirnov test
% CCW
[ccw_h, ccw_p] = kstest2(allanimals_htang_ins_ccw, allanimals_htang_exp_ccw)
% CW
[cw_h, cw_p] = kstest2(allanimals_htang_ins_cw, allanimals_htang_exp_cw)


%% Plot
figure('Name', 'Figure S3A, S3B')
set(gcf, 'Color', 'w', 'Position', [50, 100, 1200, 410], 'DefaultAxesFontSize', 15);
subplot(1,2,1)
plot(htang_bins, histcnt_ins_ccw, 'Color', INS_COLOR, 'LineWidth', 1); hold on
plot(htang_bins, histcnt_exp_ccw, 'Color', EXP_COLOR, 'LineWidth', 1); hold off
xlabel('Head-torso yaw angle (deg)'); ylabel('PDF'); title('CCW (rearing)');
xlim([-60, 60]); ylim([0, 0.025]); xline(0, 'k--');

subplot(1,2,2)
plot(htang_bins, histcnt_ins_cw, 'Color', INS_COLOR, 'LineWidth', 1); hold on
plot(htang_bins, histcnt_exp_cw, 'Color', EXP_COLOR, 'LineWidth', 1); hold off
xlabel('Head-torso yaw angle (deg)'); ylabel('PDF'); title('CW (rearing)');
xlim([-60, 60]); ylim([0, 0.025]); xline(0, 'k--');
