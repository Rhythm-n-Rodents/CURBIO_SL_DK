%% Figure S1D

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Uncomment one of the SUBJECT declarations (Lines #23 - #27)
% 2. Edit Line #58. Edit the path to the "Data" folder.
% 3. Run the code.


clc;
clear;
close all;


%% Subject
% Edit here: uncomment one of the SUBJECT declarations
% format: [animal_id, rec_type, muscle_name, left_EMG_index, right_EMG_index]

%SUBJECT = ["SLR110", "d", "SM", 4, 6];
%SUBJECT = ["SLR110", "d", "CM", 3, 5];
%SUBJECT = ["SLR102", "d", "CT", 5, 4];
%SUBJECT = ["SLR113", "d", "SP", 4, 3];
SUBJECT = ["SLR113", "d", "BC", 6, 5];


%% Assign variables
animal_ID = char(SUBJECT(1));
rec_type = char(SUBJECT(2));
muscle_name = char(SUBJECT(3));
left_emg_index = str2double(SUBJECT(4));
right_emg_index = str2double(SUBJECT(5));

emg_index_list = [left_emg_index, right_emg_index];

disp([char(animal_ID), ' - ', rec_type, ' - ', muscle_name]);

% muscle color
switch muscle_name
    case "SM"
        C_COLOR = rgb(61, 133, 198);
    case "CM"
        C_COLOR = rgb(103, 78, 167);
    case "CT"
        C_COLOR = rgb(166, 77, 121);
    case "SP"
        C_COLOR = rgb(34, 139, 34);
    case "BC"
        C_COLOR = rgb(107, 142, 35);
end

rate = 2000;

%% Move to directory
cur_folder_path = ['..\..\Data\', animal_ID];  % Edit here
cd(cur_folder_path)


%% Peak detect params
EMG_UPPER_PCT = '99.99';
str_left_emg_peak_lower_pct = '90';
str_right_emg_peak_lower_pct = '90';

%% Specify thresholds for EMG peaks
EMG_LOWER_PCT_MAP = containers.Map;
EMG_LOWER_PCT_MAP(str(left_emg_index)) = str_left_emg_peak_lower_pct;
EMG_LOWER_PCT_MAP(str(right_emg_index)) = str_right_emg_peak_lower_pct;

%% Target indeces
if strcmp(rec_type, 'd')
    target_index_list = [27, 33, -27, -33];
elseif or(strcmp(rec_type, 'h'), strcmp(rec_type, 'd'))
    target_index_list = [27, -27];
elseif strcmp(rec_type, 'x')
    target_index_list = (36);
end

%% STA Params
STA_TIME = 0.20; % in seconds
STA_FRAME = rate * STA_TIME;
disp(' ');
disp(['STA_TIME = ', str(STA_TIME), ' seconds']);
disp(' ');

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

%% Load percentiles
load([animal_ID, '_D_percentiles_36data.mat']);
if ~strcmp(animal_ID, percentiles.animal_ID)
    error('[percentiles] animal_ID inconstent');
end
pcts = percentiles.pcts;

%% staMap
staMap = containers.Map;
for emg_index = emg_index_list
    for target_index = target_index_list
        staMap([str(emg_index), '_', str(target_index)]) = [];
    end
    staMap([str(emg_index), '_', str(emg_index), '_hcw']) = [];
    staMap([str(emg_index), '_', str(emg_index), '_hccw']) = [];
    staMap([str(emg_index), '_', str(emg_index), '_htcw']) = [];
    staMap([str(emg_index), '_', str(emg_index), '_htccw']) = [];
end


%% Iterate over recordings
for recordingIndex = recordingListMap(rec_type)
    
    if and(strcmp(animal_ID, 'SLR110'), recordingIndex == 7)
        continue
    end
   
    %% Load data
    loaded_filename = [animal_ID, '_arena_', rec_type, num2str(recordingIndex), '_D_36data'];
    load(loaded_filename);
    disp([9, ' - ', loaded_filename]);
    SM_checkDataColumnNumber(data, 36);
    
    %% Time shift
    time_shift = 0.0095;
    data = SM_data_time_shift(data, (9:35), time_shift, rate);
    
    %% Allowed booleans
    bBools = bBoolsMap([rec_type, num2str(recordingIndex)]);
    if strcmp(rec_type, 'd')
        bBools('b3') = SM_data_truncate(bBools('b3'), time_shift, rate, 'tail');
        alwbool = and(bBools('b3'), data(:,10) < -16.5);
    elseif strcmp(rec_type, 'x')
        bBools('usable') = SM_data_truncate(bBools('usable'), time_shift, rate, 'tail');
        alwbool = bBools('usable');
    elseif strcmp(rec_type, 'h')
        bBools('usable') = SM_data_truncate(bBools('usable'), time_shift, rate, 'tail');
        alwbool = and(bBools('usable'), data(:,10) < -16.5);
    end
    
    %% Data Assignment
    if ismember(rec_type, ['h', 'd']) 
        hang = data(:,9);
        hvel = data(:,27);
    end
    
    if strcmp(rec_type, 'd')
        tang = data(:,18);
        htang = hang - tang;
        htang_mean = mean(htang(bBools('b3')));
        htang = htang - htang_mean;
        htvel = data(:,33);
        data = [data, htang];
    end
    
    %% EMG processing
    emgPeakMap = containers.Map;
    for emg_index = emg_index_list
        emg_pcts = pcts([rec_type, '_', str(emg_index)]);
        emg_lower_pct = EMG_LOWER_PCT_MAP(str(emg_index));
        emg_data = data(:, emg_index);
        [~, emg_peaks] = matlab_findpeaks(emg_data, 'MinPeakHeight', emg_pcts(emg_lower_pct), 'MinPeakProminence', 0.5*emg_pcts('std'));
        emg_peaks = emg_peaks(emg_data(emg_peaks) < emg_pcts(EMG_UPPER_PCT));
        emg_peaks = emg_peaks(alwbool(emg_peaks));
        emgPeakMap(str(emg_index)) = emg_peaks;
        clear emg_peaks emg_pcts emg_data 
    end
         
    %% STA
    for emg_index = emg_index_list
        
        emg_peaks = emgPeakMap(str(emg_index));
        
        if or(strcmp(rec_type, 'h'), strcmp(rec_type, 'd'))
            % EMG peaks that occurs when the head is turing cw/ccw
            cw_emgpeaks = emg_peaks(hvel(emg_peaks) > 0);
            ccw_emgpeaks = emg_peaks(hvel(emg_peaks) < 0);
            % hvel during cw
            staMap([str(emg_index), '_27']) = [staMap([str(emg_index), '_27']) , SM_etat_routine(hvel, cw_emgpeaks, STA_FRAME, alwbool)];
            % hvel during ccw
            staMap([str(emg_index), '_-27']) = [staMap([str(emg_index), '_-27']) , SM_etat_routine(hvel, ccw_emgpeaks, STA_FRAME, alwbool)];
            % self EMG during cw
            staMatrix = SM_etat_routine(data(:,emg_index), cw_emgpeaks, STA_FRAME, alwbool);
            staMap([str(emg_index), '_', str(emg_index), '_hcw']) = [staMap([str(emg_index), '_', str(emg_index), '_hcw']) , staMatrix];
            clear staMatrix
            % self EMG during ccw
            staMatrix = SM_etat_routine(data(:,emg_index), ccw_emgpeaks, STA_FRAME, alwbool);
            staMap([str(emg_index), '_', str(emg_index), '_hccw']) = [staMap([str(emg_index), '_', str(emg_index), '_hccw']) , staMatrix];
            clear staMatrix
            clear cw_emgpeaks ccw_emgpeaks
        end
        
        if strcmp(rec_type, 'd')
            % EMG peaks that occurs when the head-torso is cw/ccw
            cw_emgpeaks = emg_peaks(htvel(emg_peaks) > 0);
            ccw_emgpeaks = emg_peaks(htvel(emg_peaks) < 0);
            % htvel during cw
            staMap([str(emg_index), '_33']) = [staMap([str(emg_index), '_33']) , SM_etat_routine(htvel, cw_emgpeaks, STA_FRAME, alwbool)];
            % htvel during ccw
            staMap([str(emg_index), '_-33']) = [staMap([str(emg_index), '_-33']) , SM_etat_routine(htvel, ccw_emgpeaks, STA_FRAME, alwbool)];
            % self EMG during htcw
            staMap([str(emg_index), '_', str(emg_index), '_htcw']) = [staMap([str(emg_index), '_', str(emg_index), '_htcw']) , SM_etat_routine(data(:,emg_index), cw_emgpeaks, STA_FRAME, alwbool)];
            % self EMG during htccw
            staMap([str(emg_index), '_', str(emg_index), '_htccw']) = [staMap([str(emg_index), '_', str(emg_index), '_htccw']) , SM_etat_routine(data(:,emg_index), ccw_emgpeaks, STA_FRAME, alwbool)];
        end
    end
end

disp(' ');


%% STA (Figure S1D)
if ismember(rec_type, ['h', 'd'])

    sta_taxis = (-STA_TIME : 1/rate : STA_TIME)';

    %% Figure S1D
    figure('Name', 'Figure S1D')
    set(gcf, 'Color', 'w', 'Position', [410, 80, 400, 900], 'DefaultAxesFontSize', 12);
    
    % Left EMG
    prefix = [str(left_emg_index), '_'];
    
    % LEMG - Head
    subplot(4,1,1); hold on
    % cw
    [sta_mean, sta_error, ~] = SM_sta(staMap([prefix, '27']));
    plot(sta_taxis, sta_mean, 'LineWidth', 1, 'Color', rgb(43,57,144));
    plot(sta_taxis, sta_error, 'LineWidth', 0.5, 'Color', rgb(43,57,144));
    clear sta_mean sta_error sta_n
    % ccw
    [sta_mean, sta_error, ~] = SM_sta(staMap([prefix, '-27']));
    plot(sta_taxis, sta_mean, 'LineWidth', 1, 'Color', rgb(190,30,45));
    plot(sta_taxis, sta_error, 'LineWidth', 0.5, 'Color', rgb(190,30,45));
    clear sta_mean sta_error sta_n
    %
    xline(0); yline(0); xlim([-0.2, 0.2]); ylabel('Head'); title(['Left ', muscle_name]); hold off
    
    % LEMG - Head-torso
    if strcmp(rec_type, 'd')
        subplot(4,1,2); hold on
        % cw
        [sta_mean, sta_error, ~] = SM_sta(staMap([prefix, '33']));
        plot(sta_taxis, sta_mean, 'LineWidth', 1, 'Color', rgb(13,116,187));
        plot(sta_taxis, sta_error, 'LineWidth', 0.5, 'Color', rgb(13,116,187));
        clear sta_mean sta_error sta_n
        % ccw
        [sta_mean, sta_error, ~] = SM_sta(staMap([prefix, '-33']));
        plot(sta_taxis, sta_mean, 'LineWidth', 1, 'Color', rgb(217,86,39));
        plot(sta_taxis, sta_error, 'LineWidth', 0.5, 'Color', rgb(217,86,39));
        clear sta_mean sta_error sta_n
        %
        xline(0); yline(0); xlim([-0.2, 0.2]); ylabel('Head-Torso'); hold off
    end
    
    % right EMG
    prefix = [str(right_emg_index), '_'];
    
    % REMG - Head
    subplot(4,1,3); hold on
    % cw
    [sta_mean, sta_error, ~] = SM_sta(staMap([prefix, '27']));
    plot(sta_taxis, sta_mean, 'LineWidth', 1, 'Color', rgb(43,57,144));
    plot(sta_taxis, sta_error, 'LineWidth', 0.5, 'Color', rgb(43,57,144));
    clear sta_mean sta_error sta_n
    % ccw
    [sta_mean, sta_error, ~] = SM_sta(staMap([prefix, '-27']));
    plot(sta_taxis, sta_mean, 'LineWidth', 1, 'Color', rgb(190,30,45));
    plot(sta_taxis, sta_error, 'LineWidth', 0.5, 'Color', rgb(190,30,45));
    clear sta_mean sta_error sta_n
    %
    xline(0); yline(0); xlim([-0.2, 0.2]); ylabel('Head'); title(['Right ', muscle_name]); hold off
    
    % REMG - Head-torso
    if strcmp(rec_type, 'd')
        subplot(4,1,4); hold on
        % cw
        [sta_mean, sta_error, ~] = SM_sta(staMap([prefix, '33']));
        plot(sta_taxis, sta_mean, 'LineWidth', 1, 'Color', rgb(13,116,187));
        plot(sta_taxis, sta_error, 'LineWidth', 0.5, 'Color', rgb(13,116,187));
        clear sta_mean sta_error sta_n
        % ccw
        [sta_mean, sta_error, ~] = SM_sta(staMap([prefix, '-33']));
        plot(sta_taxis, sta_mean, 'LineWidth', 1, 'Color', rgb(217,86,39));
        plot(sta_taxis, sta_error, 'LineWidth', 0.5, 'Color', rgb(217,86,39));
        clear sta_mean sta_error sta_n
        %
        xline(0); yline(0); xlim([-0.2, 0.2]); xlabel('Time from EMG peaks(s)'); ylabel('Head-Torso');
        hold off
    else
        subplot(4,1,3); xlabel('Time from EMG peaks(s)');
    end
end