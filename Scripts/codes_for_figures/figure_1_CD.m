%% Figure 1CD

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Edit Line #25. Edit the path to the 'SLR087' folder
% 2. Run the code

clc;
clear;
close all;

%% General parameters
animal_ID = 'SLR087';
muscle_name = 'NONE';
rec_type = 'd';

disp([char(animal_ID), ' - ', rec_type, ' - ', muscle_name]);
disp(' ');

animal_ID = char(animal_ID);
cur_folder_path = ['../../Data/', animal_ID];  % [Edit here]

cd(cur_folder_path)


%% Sampling rate
rate = 2000;


%% Load recording list map
load([animal_ID, '_D_recordingListMap.mat']);
if ~strcmp(animal_ID, recordingListMap('animal_ID'))
    error('[recordingListMap] animal_ID inconstent');
end

%% Load bBoolsMap
load([animal_ID, '_D_bBoolsMap.mat']);
if ~strcmp(animal_ID, bBoolsMap('animal_ID'))
    error('[bBoolsMap] animal_ID inconstent');
end

%% Load video frame boundary
load([animal_ID, '_D_videoFrameBoundaries.mat']);


%% Iterate over recordings
for recordingIndex = recordingListMap(rec_type)
   
    %% Load data
    loaded_filename = [animal_ID, '_arena_', rec_type, num2str(recordingIndex), '_D_36data'];
    load(loaded_filename);
    disp([9, ' - ', loaded_filename]);
    SM_checkDataColumnNumber(data, 36);
    
    %% Load DLC predictions
    try
        dlc_excel = readmatrix([animal_ID, '_arena_', rec_type, num2str(recordingIndex),'_D_videoDLC_torso.csv']);
    catch
        disp([9, 'No DLP data']);
    end
    
    %% Time shift
    time_shift = 0.0095;
    data = SM_data_time_shift(data, (9:35), time_shift, rate);
    
    %% Allowed booleans
    bBools = bBoolsMap([rec_type, num2str(recordingIndex)]);
    if strcmp(rec_type, 'd')
        bBools('b3') = SM_data_truncate(bBools('b3'), time_shift, rate, 'tail');
    elseif strcmp(rec_type, 'x')
        bBools('usable') = SM_data_truncate(bBools('usable'), time_shift, rate, 'tail');
    elseif strcmp(rec_type, 'h')
        bBools('usable') = SM_data_truncate(bBools('usable'), time_shift, rate, 'tail');
    end
    
    %% Data Assignment
    time = data(:,1);
    breathing = data(:,36);
    
    if strcmp(rec_type, 'd')
        % yaw angle
        hang = data(:,9);
        tang = data(:,18);
        htang = hang - tang;
        htang_mean = mean(htang(bBools('b3')));
        htang = htang - htang_mean;
                
        % yaw angular velocity
        hvel = data(:,27);
        tvel = data(:,30);
        htvel = data(:,33);
        
        % pitch
        pang = data(:,10);
        pvel = data(:,28);
        
        % append calibrated htang to the last column
        data = [data, htang];
    end
      
  
    
    %% Figure 1D
    if recordingIndex == 13
        
        XLIM = [118, 132];
        
        disp(' ');
        disp('**Figure 1D**');
        
        figure('Name', 'Figure 1D')
        set(gcf, 'Color', 'w',  'WindowState', 'maximized', 'DefaultAxesFontSize', 10);
        subplot(5,1,1)
        hold on
        plot(time, hang-htang_mean, 'Color', rgb(0,115,189), 'LineWidth', 1)
        plot(time, tang, 'Color', rgb(217,84,26), 'LineWidth', 1)
        xline(118.65, 'k', 'LineWidth', 0.5);
        xline(131.05, 'k', 'LineWidth', 0.5);
        hold off
        xlim(XLIM); set(gca, 'FontSize', 20);
        subplot(5,1,2)
        plot(time, htang, 'Color', rgb(222,125,0), 'LineWidth', 1)
        xline(131.05, 'k', 'LineWidth', 0.5);
        xline(118.65, 'k', 'LineWidth', 0.5);
        yline(0, 'k', 'LineWidth', 0.5);
        xlim(XLIM); set(gca, 'FontSize', 20);
        subplot(5,1,3)
        plot(time, htvel, 'Color', rgb(222,125,0), 'LineWidth', 1)
        xline(118.65, 'k', 'LineWidth', 0.5);
        xline(131.05, 'k', 'LineWidth', 0.5);
        yline(0, 'k', 'LineWidth', 0.5);
        xlim(XLIM); set(gca, 'FontSize', 20);
        subplot(5,1,4)
        plot(time, pang, 'Color', rgb(0,128,0), 'LineWidth', 1)
        xline(118.65, 'k', 'LineWidth', 0.5);
        xline(131.05, 'k', 'LineWidth', 0.5);
        yline(0, 'k', 'LineWidth', 0.5);
        xlim(XLIM); set(gca, 'FontSize', 20);
        subplot(5,1,5)
        plot(time, breathing, 'Color', rgb(128,0,0), 'LineWidth', 1)
        xlim(XLIM); set(gca, 'FontSize', 20);
        xline(118.65, 'k', 'LineWidth', 0.5);
        xline(131.05, 'k', 'LineWidth', 0.5);
    end
    
    
    %% Figure 1C
    if mod(recordingIndex, 2) == 1
        
        dlc_x = dlc_excel(:,2);
        dlc_y = -dlc_excel(:,3);

        valid_videoframeboundary = dic_VFBs([rec_type, num2str(recordingIndex)]);
        valid_videoframes = (valid_videoframeboundary(1) : valid_videoframeboundary(2));
        
        theta = (0: pi/100 : 2*pi);

        figure(10);
        set(gcf, 'Color', 'w',  'Position', [50, 50, 850, 850]); hold on
        
        % plot trajectory
        plot(dlc_x, dlc_y, 'Color', rgb(150, 150, 150), 'LineWidth', 0.5);
        
        % plot trajector of example data
        if recordingIndex == 13
            example_trajectory_x = dlc_x(2354:2602);
            example_trajectory_y = dlc_y(2354:2602);
        end
        hold off
        axis equal

        set(gca,'visible','off');

    end
end

%% Plot example trajectory
figure(10); hold on
plot(example_trajectory_x, example_trajectory_y, 'r', 'LineWidth', 3);