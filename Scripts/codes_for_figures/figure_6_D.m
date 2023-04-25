%% Figure 6D

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Edit Line #55. Edit the path to the "Data" folder.
% 2. Run the code.


clc;
clear;
close all;


%% Run on multiple animals

animal_IDs = ["SLR087"];

% uncomment to view results from all animals
% animal_IDs = ["SLR087", "SLR089", "SLR090", "SLR092", "SLR093", "SLR095", ...
%               "SLR102", "SLR103", "SLR105", "SLR106", "SLR108", "SLR110", ...
%               "SLR111", "SLR112", "SLR113", "SLR115", "SLR119"];

rec_type = 'd';
behavior = 'low';

% edges and bins for head-torso yaw angle distribution
htang_edges = (-60:3:60)';
htang_bins = (htang_edges(1:end-1) + htang_edges(2:end))/2;
    
% histcounts for all animals
allcounts_htang_ins_cw = [];
allcounts_htang_exp_cw = [];

allcounts_htang_ins_ccw = [];
allcounts_htang_exp_ccw = [];


for animal_i = 1 : length(animal_IDs)

    %% Iterate over animals
    animal_ID = char(animal_IDs(animal_i));
    disp(animal_ID);
    disp(' ');

    % MPU peaks
    MPU_LOWER_PCT = '75';
    disp(['MPU_LOWER_PCT = ', MPU_LOWER_PCT]);

    %% Setting muscle indeces and params
    animal_ID = char(animal_ID);
    cur_folder_path = ['..\..\Data\', animal_ID];  % Edit here
    cd(cur_folder_path)

    %% Specigy range of yaw movement rate
    SET_MPU_FMIN = true;
    mpu_fmin = 8;
    SET_MPU_FMAX = true;
    mpu_fmax = 14;

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
    INS_PHI_RANGE = [55-45, 55+45];
    EXP_PHI_RANGE = [245-45, 245+45];

    disp(['Definition of inspiratory sweeps: ', str(INS_PHI_RANGE)]);
    disp(['Definition of expiratory sweeps: ', str(EXP_PHI_RANGE)]);


    %% Data Preallocation
    % head-torso angle
    INS_CW_HTANG = [];
    EXP_CW_HTANG = [];
    INS_CCW_HTANG = [];
    EXP_CCW_HTANG = [];

    %% Color Code
    INS_COLOR = rgb(64, 187, 236);  % rgb(72, 209, 204)
    EXP_COLOR = rgb(199, 23, 132);  % rgb(199, 21, 133)

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
        % torso
        tang = data(:,18);
        % head-torso
        htang = hang - tang;
        htang_mean = mean(htang(bBools('b3')));
        htang = htang - htang_mean;
        htvel = data(:,33);
        
        % htang = data(:, 37)
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

        %% htang dependence
        INS_CW_HTANG = [INS_CW_HTANG ; htang(ins_cw)];
        EXP_CW_HTANG = [EXP_CW_HTANG ; htang(exp_cw)];
        INS_CCW_HTANG = [INS_CCW_HTANG ; htang(ins_ccw)];
        EXP_CCW_HTANG = [EXP_CCW_HTANG ; htang(exp_ccw)];
    end 
    disp(' ');

    %% INS-EXP Dependency
    figure('Name', animal_ID)
    set(gcf, 'Color', 'w', 'Position', [50, 100, 1000, 800], 'DefaultAxesFontSize', 15);

    %% htang
    % K-S test
    [htang_cw_h, htang_cw_p] = kstest2(EXP_CW_HTANG, INS_CW_HTANG);
    [htang_ccw_h, htang_ccw_p] = kstest2(EXP_CCW_HTANG, INS_CCW_HTANG);
    
    disp('KS P-values');
    htang_ccw_p
    htang_cw_p

    % plot - CCW
    subplot(2,2,1); hold on
    histogram(EXP_CCW_HTANG, htang_edges, 'Normalization', 'pdf', 'FaceColor', EXP_COLOR, 'EdgeColor', 'none');
    histogram(INS_CCW_HTANG, htang_edges, 'Normalization', 'pdf', 'FaceColor', INS_COLOR, 'EdgeColor', 'none');
    xline(0, 'k--', 'LineWidth', 2);
    xlim([htang_edges(1), htang_edges(end)]); xticks((htang_edges(1) : 30 : htang_edges(end)));
    title('CCW'); axis square; hold off
    
    % plot - CW
    subplot(2,2,2); hold on
    histogram(EXP_CW_HTANG, htang_edges, 'Normalization', 'pdf', 'FaceColor', EXP_COLOR, 'EdgeColor', 'none');
    histogram(INS_CW_HTANG, htang_edges, 'Normalization', 'pdf', 'FaceColor', INS_COLOR, 'EdgeColor', 'none');
    xline(0, 'k--', 'LineWidth', 2);
    xlim([htang_edges(1), htang_edges(end)]); xticks((htang_edges(1) : 30 : htang_edges(end)));
    title('CW'); axis square; hold off
    

    [INS_CW_HTANG_PROB, EXP_CW_HTANG_PROB] = SM_ins_exp_prior_post_conversion(INS_CW_HTANG, EXP_CW_HTANG, htang_edges);
    [INS_CCW_HTANG_PROB, EXP_CCW_HTANG_PROB] = SM_ins_exp_prior_post_conversion(INS_CCW_HTANG, EXP_CCW_HTANG, htang_edges);

    
    % plot - CCW
    subplot(2,2,3)
    bccw = bar(htang_bins, [INS_CCW_HTANG_PROB, EXP_CCW_HTANG_PROB], 1.0, 'stacked', 'EdgeColor', 'none');
    bccw(1).FaceColor = INS_COLOR;
    bccw(2).FaceColor = EXP_COLOR;
    bccw(1).FaceAlpha = 0.8;
    bccw(2).FaceAlpha = 0.8;
    xline(0, 'k--', 'LineWidth', 2);
    yline(0.5, 'w--', 'LineWidth', 2);
    xlim([htang_edges(1), htang_edges(end)]); xticks((htang_edges(1) : 30 : htang_edges(end)));
    axis square
    
    % plot - CW
    subplot(2,2,4)
    bcw = bar(htang_bins, [INS_CW_HTANG_PROB, EXP_CW_HTANG_PROB], 1.0, 'stacked', 'EdgeColor', 'none');
    bcw(1).FaceColor = INS_COLOR;
    bcw(2).FaceColor = EXP_COLOR;
    bcw(1).FaceAlpha = 0.8;
    bcw(2).FaceAlpha = 0.8;
    xline(0, 'k--', 'LineWidth', 2);
    yline(0.5, 'w--', 'LineWidth', 2);
    xlim([htang_edges(1), htang_edges(end)]); xticks((htang_edges(1) : 30 : htang_edges(end)));
    axis square
    
    
    %% Append result
    allcounts_htang_ins_cw = [allcounts_htang_ins_cw, histcounts(INS_CW_HTANG, htang_edges, 'Normalization', 'pdf')'];
    allcounts_htang_exp_cw = [allcounts_htang_exp_cw, histcounts(EXP_CW_HTANG, htang_edges, 'Normalization', 'pdf')'];

    allcounts_htang_ins_ccw = [allcounts_htang_ins_ccw, histcounts(INS_CCW_HTANG, htang_edges, 'Normalization', 'pdf')'];
    allcounts_htang_exp_ccw = [allcounts_htang_exp_ccw, histcounts(EXP_CCW_HTANG, htang_edges, 'Normalization', 'pdf')'];
end


%% Calculate averages
allcounts_htang_ins_cw_avg = mean(allcounts_htang_ins_cw, 2);
allcounts_htang_ins_ccw_avg = mean(allcounts_htang_ins_ccw, 2);
allcounts_htang_exp_cw_avg = mean(allcounts_htang_exp_cw, 2);
allcounts_htang_exp_ccw_avg = mean(allcounts_htang_exp_ccw, 2);


%% Plot results from all animals
figure(100)
set(gcf, 'Color', 'w', 'Position', [50, 100, 1200, 400], 'DefaultAxesFontSize', 15);

subplot(1,2,1)
hold on
% all animals
plot(htang_bins, allcounts_htang_ins_ccw, 'Color', INS_COLOR, 'LineWidth', 1);
plot(htang_bins, allcounts_htang_exp_ccw, 'Color', EXP_COLOR, 'LineWidth', 1);
% averages
plot(htang_bins, allcounts_htang_ins_ccw_avg, 'c', 'LineWidth', 2);
plot(htang_bins, allcounts_htang_exp_ccw_avg, 'r', 'LineWidth', 2);
hold off
xlim([htang_edges(1), htang_edges(end)]);

subplot(1,2,2)
hold on
% all animals
plot(htang_bins, allcounts_htang_ins_cw, 'Color', INS_COLOR, 'LineWidth', 1);
plot(htang_bins, allcounts_htang_exp_cw, 'Color', EXP_COLOR, 'LineWidth', 1);
% averages
plot(htang_bins, allcounts_htang_ins_cw_avg, 'c', 'LineWidth', 2);
plot(htang_bins, allcounts_htang_exp_cw_avg, 'r', 'LineWidth', 2);
hold off
xlim([htang_edges(1), htang_edges(end)]);
