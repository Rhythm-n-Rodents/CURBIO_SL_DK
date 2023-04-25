%% Figure 6A

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Edit Line #36. Edit the path to the "Data" folder.
% 2. Run the code.


clc;
clear;
close all;


%% Run on multiple animals
animal_IDs = ["SLR087"];    
rec_type = 'd';
behavior = 'low';

for animal_i = 1 : length(animal_IDs)

    %% Iterate over animals
    animal_ID = char(animal_IDs(animal_i));
    disp(animal_ID);
    disp(' ');

    % MPU peaks
    MPU_LOWER_PCT = '75'; % was 75 was was 90
    disp(['MPU_LOWER_PCT = ', MPU_LOWER_PCT]);

    %% Setting muscle indeces and params
    animal_ID = char(animal_ID);
    cur_folder_path = ['..\..\Data\', animal_ID];
    cd(cur_folder_path)

    %% Specigy range of yaw movement rate
    SET_MPU_FMIN = true;
    mpu_fmin = 8; % was 8
    SET_MPU_FMAX = true;
    mpu_fmax = 14; % was 14

    %% Specify range of breathing rate
    SET_BREATHING_FMIN = true;
    breathing_fmin = 8;
    SET_BREATHING_FMAX = true;
    breathing_fmax = 14;

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

    %% Load video boundary frames
    load([animal_ID, '_D_videoFrameBoundaries.mat']);
    assert(strcmp(animal_ID, dic_VFBs('animal_ID')), '[dic_VFBs] animal_ID inconstent');

    %% INS-EXP SWPS
    INS_PHI_RANGE = [55-45, 55+45]; % [45, 135], mid @ 55
    EXP_PHI_RANGE = [245-45, 245+45]; % [225, 315], mid @ 245

    disp(['Definition of inspiratory sweeps: ', str(INS_PHI_RANGE)]);
    disp(['Definition of expiratory sweeps: ', str(EXP_PHI_RANGE)]);

    %% Color Code
    INS_COLOR = rgb(72, 209, 204);
    EXP_COLOR = rgb(199, 21, 133);

    %% Iterate over recordings
    for recordingIndex = 24
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
            error('undefined behavior');
        end

        %% Data Assignment
        time = data(:,1);
        breathing = data(:,36);

        % head
        hang = data(:,9);
        hvel = data(:,27);
        pang = data(:,10);
        pvel = data(:,28);

        % torso
        tang = data(:,18);
        tvel = data(:,30);

        % head-torso
        htang = hang - tang;
        htang_mean = mean(htang(bBools('b3')));
        htang = htang - htang_mean;
        htvel = data(:,33);

        data = [data, htang];
        SM_checkDataColumnNumber(data, 37);

        %% Breathing processing
        [breathing_onsets, breathing_lengths, breathing_postinsp] = ...
            SM_breathing_processing(breathing, rate, alwbool, SET_BREATHING_FMAX, SET_BREATHING_FMIN, breathing_fmax, breathing_fmin);

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

        if or(isempty(htvel_cw_peaks), isempty(htvel_ccw_peaks))
            continue
        end

        %% INS & EXP head-torso velocity peaks classification
        [ins_cw, exp_cw] = SM_ins_exp_classification(htvel_cw_peaks, breathing_onsets, breathing_lengths, INS_PHI_RANGE, EXP_PHI_RANGE);
        [ins_ccw, exp_ccw] = SM_ins_exp_classification(htvel_ccw_peaks, breathing_onsets, breathing_lengths, INS_PHI_RANGE, EXP_PHI_RANGE);
        
        % plot
        figure('Name', ['INS/EXP - ', rec_type, '-', str(recordingIndex)]);

        subplot(3,1,1)
        plot(time, breathing, 'LineWidth', 1, 'Color', rgb(128, 0, 0))
        xlim([99.5, 100.1]); ylim([-0.2, 0.2]);

        subplot(3,1,2)
        plot(time, htvel); hold on
        plot(time(ins_cw), htvel(ins_cw), '.', 'MarkerSize', 10, 'Color', INS_COLOR);
        plot(time(ins_ccw), htvel(ins_ccw), '.', 'MarkerSize', 10, 'Color', INS_COLOR);
        plot(time(exp_cw), htvel(exp_cw), '.', 'MarkerSize', 10, 'Color', EXP_COLOR);
        plot(time(exp_ccw), htvel(exp_ccw), '.', 'MarkerSize', 10, 'Color', EXP_COLOR);
        yline(0);
        xlim([99.5, 100.1]); hold off

        subplot(3,1,3)
        plot(time, htang); hold on
        plot(time(ins_cw), htang(ins_cw), '.', 'MarkerSize', 10, 'Color', INS_COLOR);
        plot(time(ins_ccw), htang(ins_ccw), '.', 'MarkerSize', 10, 'Color', INS_COLOR);
        plot(time(exp_cw), htang(exp_cw), '.', 'MarkerSize', 10, 'Color', EXP_COLOR);
        plot(time(exp_ccw), htang(exp_ccw), '.', 'MarkerSize', 10, 'Color', EXP_COLOR);
        yline(20);
        xlim([99.5, 100.1]); ylim([10, 70]); hold off
    end 
end
