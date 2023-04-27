%% Figure S3CDEF

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Edit Line #48. Edit the path to the "Data" folder.
% 2. Run the code.


clc;
clear;
close all;


%% Run on multiple animals
% animal_IDs = ["SLR087", "SLR089", "SLR090", "SLR092", "SLR093", "SLR095", ...
%               "SLR102", "SLR103", "SLR105", "SLR106", "SLR108", "SLR110", ...
%               "SLR111", "SLR112", "SLR113", "SLR115", "SLR119"];

animal_IDs = ["SLR087"];
          
rec_type = 'd';
behavior = 'low';

% edges and bins for head-torso yaw velocity distribution
htvel_edges = (-750:25:750)';
htvel_bins = (htvel_edges(1:end-1) + htvel_edges(2:end))/2;
    
% histcounts for all animals
allcounts_htvel_ins = [];
allcounts_htvel_exp = [];


for animal_i = 1 : length(animal_IDs)

    %% Iterate over animals
    animal_ID = char(animal_IDs(animal_i));
    disp(animal_ID);
    disp(' ');

    % MPU peaks
    MPU_LOWER_PCT = '75';

    %% Setting muscle indeces and params
    cur_folder_path = ['..\..\Data\', animal_ID];
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


    %% Data Preallocation
    % to-the-wall distance
    INS_CW_XY = [];
    EXP_CW_XY = [];
    INS_CCW_XY = [];
    EXP_CCW_XY = [];

    INS_CW_R = [];
    EXP_CW_R = [];
    INS_CCW_R = [];
    EXP_CCW_R = [];

    ALL_R = [];

    % locomotion
    INS_V = [];
    EXP_V = [];

    % head-torso velocity
    INS_CW_HTVEL = [];
    EXP_CW_HTVEL = [];
    INS_CCW_HTVEL = [];
    EXP_CCW_HTVEL = [];


    %% Color Code
    INS_COLOR = rgb(64, 187, 236);
    EXP_COLOR = rgb(199, 23, 132);

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
        

        %% htvel dependence
        INS_CW_HTVEL = [INS_CW_HTVEL ; htvel(ins_cw)];
        EXP_CW_HTVEL = [EXP_CW_HTVEL ; htvel(exp_cw)];
        INS_CCW_HTVEL = [INS_CCW_HTVEL ; htvel(ins_ccw)];
        EXP_CCW_HTVEL = [EXP_CCW_HTVEL ; htvel(exp_ccw)];


        %% to-wall distance
        % read DLC tracking data (torso tracking)
        dlc_excel = readmatrix([animal_ID, '_arena_', rec_type, num2str(recordingIndex), '_D_videoDLC_torso.csv']);
        % video boundaries
        vb = dic_VFBs([rec_type, num2str(recordingIndex)]);
        % only takes the tracking data in the video boundary
        dlc_excel = dlc_excel(vb(1):vb(2), :);
        assert(size(dlc_excel, 1) == vb(2)-vb(1)+1);
        
        % read ellipse params
        ellipse_params = load([animal_ID, '_arena_', rec_type, num2str(recordingIndex), '_D_arena_ellipse_params']);
        ellipse_params = ellipse_params.ellipse_params;
        
        % transforms DLC tracking
        [dlc_x, dlc_y] = SM_ellipse2circle(dlc_excel(:,2), -dlc_excel(:,3), ellipse_params);  % dlc_x.shape = (M, 1)
        
        % DLC is taking at 20 Hz -> lowpass at 4 Hz
        dlc_x = SM_filterAlongColumns(dlc_x, 20, 4, 3, 'low');
        dlc_y = SM_filterAlongColumns(dlc_y, 20, 4, 3, 'low');
        
        % upsampling
        dlc_x = SM_splineAlongColumns_specifiedLength(dlc_x, length(time));
        dlc_y = SM_splineAlongColumns_specifiedLength(dlc_y, length(time));

        INS_CW_XY = [INS_CW_XY ; [dlc_x(ins_cw), dlc_y(ins_cw)]];
        EXP_CW_XY = [EXP_CW_XY ; [dlc_x(exp_cw), dlc_y(exp_cw)]];
        INS_CCW_XY = [INS_CCW_XY ; [dlc_x(ins_ccw), dlc_y(ins_ccw)]];
        EXP_CCW_XY = [EXP_CCW_XY ; [dlc_x(exp_ccw), dlc_y(exp_ccw)]];
        
        INS_CW_R = 0.5 - (INS_CW_XY(:,1).^2 + INS_CW_XY(:,2).^2).^0.5;
        EXP_CW_R = 0.5 - (EXP_CW_XY(:,1).^2 + EXP_CW_XY(:,2).^2).^0.5;
        INS_CCW_R = 0.5 - (INS_CCW_XY(:,1).^2 + INS_CCW_XY(:,2).^2).^0.5;
        EXP_CCW_R = 0.5 - (EXP_CCW_XY(:,1).^2 + EXP_CCW_XY(:,2).^2).^0.5;
        
        ALL_R = [ALL_R ; 0.5 - (dlc_x.^2 + dlc_y.^2).^0.5];

        %% locomotion speed
        vx = diff(dlc_x)*rate;
        vy = diff(dlc_y)*rate;
        vx = [vx ; vx(end)];
        vy = [vy ; vy(end)];
        
        ins_v = ([vx(ins_cw) ; vx(ins_ccw)].^2 + [vy(ins_cw) ; vy(ins_ccw)].^2).^0.5;
        exp_v = ([vx(exp_cw) ; vx(exp_ccw)].^2 + [vy(exp_cw) ; vy(exp_ccw)].^2).^0.5;
        
        INS_V = [INS_V ; ins_v];
        EXP_V = [EXP_V ; exp_v];
    end 
    disp(' ');


    %% INS-EXP Dependency
    figure('Name', animal_ID)
    set(gcf, 'Color', 'w', 'Position', [50, 100, 800, 800], 'DefaultAxesFontSize', 12);

    %% wd (wall distance)
    wd_edges = (0: 0.05 :0.5);  % (bin_size = 1 cm)
    wd_bins = (wd_edges(1:end-1) + wd_edges(2:end))/2;
    wd_weights = 1./wd_bins.^2;

    % K-S test
    [wd_h, wd_p] = kstest2([INS_CW_R ; INS_CCW_R], [EXP_CW_R ; EXP_CCW_R]);

    [ins_r_n, ~] = histcounts([INS_CW_R ; INS_CCW_R], wd_edges, 'Normalization', 'pdf');
    [exp_r_n, ~] = histcounts([EXP_CW_R ; EXP_CCW_R], wd_edges, 'Normalization', 'pdf');

    subplot(2,2,2); hold on
    plot(wd_bins, exp_r_n, 'Color', EXP_COLOR, 'LineWidth', 2);
    plot(wd_bins, ins_r_n, 'Color', INS_COLOR, 'LineWidth', 2); 
    xlim([wd_edges(1), wd_edges(end)]); 
    xticks((wd_edges(1) : 0.1 : wd_edges(end)));
    xlabel('Distance to the wall (m)'); ylabel('PDF'); title(str(wd_p));
    axis square
    hold off
    

    INS_X = [INS_CW_XY(:,1) ; INS_CCW_XY(:,1)];
    INS_Y = [INS_CW_XY(:,2) ; INS_CCW_XY(:,2)];

    EXP_X = [EXP_CW_XY(:,1) ; EXP_CCW_XY(:,1)];
    EXP_Y = [EXP_CW_XY(:,2) ; EXP_CCW_XY(:,2)];

    
    subplot(2,2,1); hold on
    scatter(EXP_X, EXP_Y, 5, 'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', EXP_COLOR, 'MarkerFaceAlpha', 0.5);
    scatter(INS_X, INS_Y, 5, 'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', INS_COLOR, 'MarkerFaceAlpha', 0.5);
    plot(0.5*cos((0: pi/100: 2*pi)), 0.5*sin((0: pi/100: 2*pi)), 'k', 'LineWidth', 1);
    xlim([-0.5, 0.5]); xticks([-0.5: 0.25: 0.5]);
    ylim([-0.5, 0.5]); yticks([-0.5: 0.25: 0.5]);
    axis square
    hold off

    
    %% locomotion
    v_edges = (0:0.02:0.8);
    v_bins = (v_edges(1:end-1) + v_edges(2:end))/2;
    
    % K-S test
    [v_h, v_p] = kstest2(INS_V, EXP_V);
    
    curve_locomotion_exp = histcounts(EXP_V, v_edges, 'Normalization', 'pdf');
    curve_locomotion_ins = histcounts(INS_V, v_edges, 'Normalization', 'pdf');
    
    subplot(2,2,3); hold on
    plot(v_bins, curve_locomotion_exp, 'Color', EXP_COLOR, 'LineWidth', 2);
    plot(v_bins, curve_locomotion_ins, 'Color', INS_COLOR, 'LineWidth', 2);
    xlim([0, 0.8]), xticks((0:0.2:0.8));
    xlabel('Locomotion speed (m/s)'); ylabel('PDF'); title(str(v_p));
    axis square
    hold off
    

    %% htvel
    % K-S test
    [ccw_htvel_h, ccw_htvel_p] = kstest2(EXP_CCW_HTVEL, INS_CCW_HTVEL);
    [cw_htvel_h, cw_htvel_p] = kstest2(EXP_CW_HTVEL, INS_CW_HTVEL);
    
    ccw_htvel_p
    cw_htvel_p
    
    subplot(2,2,4); hold on
    histogram(EXP_CW_HTVEL, htvel_edges, 'Normalization', 'Probability', 'FaceColor', EXP_COLOR, 'EdgeColor', 'none');
    histogram(INS_CW_HTVEL, htvel_edges, 'Normalization', 'Probability', 'FaceColor', INS_COLOR, 'EdgeColor', 'none');
    histogram(EXP_CCW_HTVEL, htvel_edges, 'Normalization', 'Probability', 'FaceColor', EXP_COLOR, 'EdgeColor', 'none');
    histogram(INS_CCW_HTVEL, htvel_edges, 'Normalization', 'Probability', 'FaceColor', INS_COLOR, 'EdgeColor', 'none');
    xline(0, 'k--', 'LineWidth', 2);
    xlim([htvel_edges(1), htvel_edges(end)]); hold off
    xticks((htvel_edges(1) : 250 : htvel_edges(end)));
    xlabel('Head-torso yaw velocity (deg/s)'); ylabel('Cond. Prob.'); title('CCW | CW ');
    axis square;
    hold off
end
