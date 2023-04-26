%% Figure S3G

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

% SUBJECT = ["SLR110", "d", "SM", 4, 6];
% SUBJECT = ["SLR110", "d", "CM", 3, 5];
% SUBJECT = ["SLR102", "d", "CT", 5, 4];
% SUBJECT = ["SLR113", "d", "SP", 4, 3];
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

%% XCORR
XCORR_SEG_T = 4; % seconds
XCORR_SEG_F = rate * XCORR_SEG_T; % frames

XCORR_X = (-XCORR_SEG_T+1/rate : 1/rate : XCORR_SEG_T-1/rate)';
XCORR_RL = [];


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
    LEMG = data(:,left_emg_index);
    REMG = data(:,right_emg_index);
    
    LEMG_norm = (LEMG - mean(LEMG(alwbool)))/std(LEMG(alwbool));
    REMG_norm = (REMG - mean(REMG(alwbool)))/std(REMG(alwbool));
    
    %% Xcorr
    xcorr_LEMG_segments = SM_segment4Chronux_allowableBoolean(LEMG_norm, XCORR_SEG_F, alwbool);
    xcorr_REMG_segments = SM_segment4Chronux_allowableBoolean(REMG_norm, XCORR_SEG_F, alwbool);
    
    n_xcorr = size(xcorr_LEMG_segments, 2);
          
    for i = 1 : n_xcorr
        xcorr_REMG_LEMG = xcorr(xcorr_REMG_segments(:,i), xcorr_LEMG_segments(:,i), 'normalized');
        
        XCORR_RL = [XCORR_RL, xcorr_REMG_LEMG];
    end
end

disp(' ');


%% Figure S3G
figure('Name', 'Figure S3G')
set(gcf, 'Color', 'w', 'Position', [150, 90, 680, 180], 'DefaultAxesFontSize', 15);

% xcorr: LEMG-REMG (with transformation)
[xcorr_mean, xcorr_error, ~] = SM_sta(atanh(XCORR_RL));
xcorr_mean = tanh(xcorr_mean);
xcorr_error = tanh(xcorr_error);

plot(XCORR_X, xcorr_mean, 'LineWidth', 1, 'Color', C_COLOR); hold on
plot(XCORR_X, xcorr_error, 'LineWidth', 0.5, 'Color', C_COLOR);
xline(0, 'k--'); yline(0);
xlim([-0.5, 0.5]); ylim([-0.2, 1.1]); yticks((0:0.5:1));
xlabel('Lag time (s)'); ylabel('Cross-corr.');
hold off
clear xcorr_mean xcorr_error
