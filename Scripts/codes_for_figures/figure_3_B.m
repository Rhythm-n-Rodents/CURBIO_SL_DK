%% Figure 3B

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Edit Line #23. Edit the path to the "Data" folder.
% 2. Run the code.

clc;
clear;
close all;

%% General parameters
animal_ID = 'SLR110';
rec_type = 'd';

rate = 2000;

%% Load raw EMG data
cd(['..\..\Data\', animal_ID]);  % Edit here

% Load recording list map
load([animal_ID, '_D_recordingListMap.mat']);
if ~strcmp(animal_ID, recordingListMap('animal_ID'))
    error('[recordingListMap] animal_ID inconstent');
end

% Load bBoolsMap
load([animal_ID, '_D_bBoolsMap.mat']);
if ~strcmp(animal_ID, bBoolsMap('animal_ID'))
    error('[bBoolsMap] animal_ID inconstent');
end

for recordingIndex = 2
    % load data
    loaded_filename = [animal_ID, '_arena_', rec_type, str(recordingIndex), '_D_36data'];
    load(loaded_filename);
    disp([9, ' - ', loaded_filename]);
    SM_checkDataColumnNumber(data, 36);

    % time shift
    time_shift = 0.0095;
    data = SM_data_time_shift(data, (9:35), time_shift, rate);

    % allowed booleans
    bBools = bBoolsMap([rec_type, num2str(recordingIndex)]);
    bBools('usable') = SM_data_truncate(bBools('usable'), time_shift, rate, 'tail');
    bBools('b3') = SM_data_truncate(bBools('b3'), time_shift, rate, 'tail');
    
    alwbool = and(bBools('b3'), data(:,10) < -16.5);
    
    % data
    htyang = data(:,9) - data(:,18);
    htyang = htyang - mean(htyang(bBools('b3')));
    
    % data
    time = SM_replaceVectorWithNaNatBoolean0(data(:, 1), alwbool);
    breathing = SM_replaceVectorWithNaNatBoolean0(data(:, 36), alwbool);
    lsm = SM_replaceVectorWithNaNatBoolean0(data(:, 4), alwbool).*2500;
    rsm = SM_replaceVectorWithNaNatBoolean0(data(:, 6), alwbool).*2500;
    lcm = SM_replaceVectorWithNaNatBoolean0(data(:, 3), alwbool).*2500;
    rcm = SM_replaceVectorWithNaNatBoolean0(data(:, 5), alwbool).*2500;
    htyvel = SM_replaceVectorWithNaNatBoolean0(data(:, 33), alwbool);
    htyang = SM_replaceVectorWithNaNatBoolean0(htyang, alwbool);
    
    figure()
    set(gcf, 'Color', 'w', 'Position', [100, 100, 560, 890], 'DefaultAxesFontSize', 15);
    ax1 = subplot(7, 1, 1);
    plot(time, breathing)
    xlim([-inf, inf])
    xticklabels({});
    yticklabels({});
    
    ax2 = subplot(7, 1, 2);
    plot(time, lsm)
    xlim([-inf, inf])
    xticklabels({});
    
    ax3 = subplot(7, 1, 3);
    plot(time, rsm)
    xlim([-inf, inf])
    xticklabels({});
    
    ax4 = subplot(7, 1, 4);
    plot(time, lcm)
    xlim([-inf, inf])
    xticklabels({});
    
    ax5 = subplot(7, 1, 5);
    plot(time, rcm)
    xlim([-inf, inf])
    xticklabels({});
    
    ax6 = subplot(7, 1, 6);
    plot(time, htyvel)
    xlim([-inf, inf])
    xticklabels({});
    
    ax7 = subplot(7, 1, 7);
    plot(time, htyang)
    xlim([-inf, inf])
    
    linkaxes([ax1, ax2, ax3, ax4, ax5, ax6, ax7], 'x');
    xlim([231, 236])
end


%% Differential EMG signals
load('SLR110_arena_d2_D_LCmat.mat');

t_start = 231;
t_end = 236;

lcm_raw = data(datastart(1):dataend(1)) - data(datastart(2):dataend(2));
lsm_raw = data(datastart(3):dataend(3)) - data(datastart(4):dataend(4));
rcm_raw = data(datastart(5):dataend(5)) - data(datastart(6):dataend(6));
rsm_raw = data(datastart(7):dataend(7)) - data(datastart(8):dataend(8));

lcm_raw = SM_filterAlongColumns(lcm_raw', 20000, 300, 3, 'high');
lsm_raw = SM_filterAlongColumns(lsm_raw', 20000, 300, 3, 'high');
rcm_raw = SM_filterAlongColumns(rcm_raw', 20000, 300, 3, 'high');
rsm_raw = SM_filterAlongColumns(rsm_raw', 20000, 300, 3, 'high');

lcm_raw = SM_filterAlongColumns(lcm_raw, 20000, 9999, 3, 'low').*2500;
lsm_raw = SM_filterAlongColumns(lsm_raw, 20000, 9999, 3, 'low').*2500;
rcm_raw = SM_filterAlongColumns(rcm_raw, 20000, 9999, 3, 'low').*2500;
rsm_raw = SM_filterAlongColumns(rsm_raw, 20000, 9999, 3, 'low').*2500;

time = (0: 1/20000 : (length(lcm_raw)-1)/20000);

figure(2)
subplot(4,1,1)
plot(time, lsm_raw)
xlim([t_start, t_end])
subplot(4,1,2)
plot(time, rsm_raw)
xlim([t_start, t_end])
subplot(4,1,3)
plot(time, lcm_raw)
xlim([t_start, t_end])
subplot(4,1,4)
plot(time, rcm_raw)
xlim([t_start, t_end])
