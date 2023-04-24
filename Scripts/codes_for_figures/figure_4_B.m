%% Figure 4B

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Edit Line #25. Edit the path to the "Data" folder.
% 2. Run the code.


clc;
clear;
close all;


%% General parameters
animal_ID = 'SLR116';
rec_type = 'h';

rate = 2000;

%% Load raw EMG data
cd(['..\..\Data\', animal_ID]);

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

for recordingIndex = 12
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
    
    alwbool = and(bBools('usable'), data(:,10) < -16.5);

    % data
    time = SM_replaceVectorWithNaNatBoolean0(data(:, 1), alwbool);
    breathing = SM_replaceVectorWithNaNatBoolean0(data(:, 36), alwbool);
    lvi = SM_replaceVectorWithNaNatBoolean0(data(:, 3), alwbool).*2500;
    rvi = SM_replaceVectorWithNaNatBoolean0(data(:, 4), alwbool).*2500;
    ldn = SM_replaceVectorWithNaNatBoolean0(data(:, 5), alwbool).*2500;
    rdn = SM_replaceVectorWithNaNatBoolean0(data(:, 6), alwbool).*2500;
    hyvel = SM_replaceVectorWithNaNatBoolean0(data(:, 27), alwbool);
    hpvel = SM_replaceVectorWithNaNatBoolean0(data(:, 10), alwbool);
    
    figure()
    set(gcf, 'Color', 'w', 'Position', [100, 100, 560, 890], 'DefaultAxesFontSize', 15);
    ax1 = subplot(7, 1, 1);
    plot(time, breathing)
    xlim([-inf, inf])
    xticklabels({});
    yticklabels({});
    
    ax2 = subplot(7, 1, 2);
    plot(time, lvi)
    xlim([-inf, inf])
    xticklabels({});
    
    ax3 = subplot(7, 1, 3);
    plot(time, rvi)
    xlim([-inf, inf])
    xticklabels({});
    
    ax4 = subplot(7, 1, 4);
    plot(time, ldn)
    xlim([-inf, inf])
    xticklabels({});
    
    ax5 = subplot(7, 1, 5);
    plot(time, rdn)
    xlim([-inf, inf])
    xticklabels({});
    
    ax6 = subplot(7, 1, 6);
    plot(time, hyvel)
    xlim([-inf, inf])
    xticklabels({});
    
    ax7 = subplot(7, 1, 7);
    
    linkaxes([ax1, ax2, ax3, ax4, ax5, ax6, ax7], 'x');
    xlim([61.5, 63.5]);
end


%% Differential EMG signals
load('SLR116_arena_h12_D_LCmat.mat');

t_start = 61.5;
t_end = 63.5;

lvi_raw = (data(datastart(1):dataend(1)) - data(datastart(2):dataend(2))).*2500;
rvi_raw = (data(datastart(3):dataend(3)) - data(datastart(4):dataend(4))).*2500;
ldn_raw = (data(datastart(5):dataend(5)) - data(datastart(6):dataend(6))).*2500;
rdn_raw = (data(datastart(7):dataend(7)) - data(datastart(8):dataend(8))).*2500;

lvi_raw = SM_filterAlongColumns(lvi_raw', 20000, 300, 3, 'high');
rvi_raw = SM_filterAlongColumns(rvi_raw', 20000, 300, 3, 'high');
ldn_raw = SM_filterAlongColumns(ldn_raw', 20000, 300, 3, 'high');
rdn_raw = SM_filterAlongColumns(rdn_raw', 20000, 300, 3, 'high');

lvi_raw = SM_filterAlongColumns(lvi_raw, 20000, 9999, 3, 'low').*2500;
rvi_raw = SM_filterAlongColumns(rvi_raw, 20000, 9999, 3, 'low').*2500;
ldn_raw = SM_filterAlongColumns(ldn_raw, 20000, 9999, 3, 'low').*2500;
rdn_raw = SM_filterAlongColumns(rdn_raw, 20000, 9999, 3, 'low').*2500;

time = (0: 1/20000 : (length(lvi_raw)-1)/20000);

figure(2)
subplot(4,1,1)
plot(time, lvi_raw)
xlim([t_start, t_end])
subplot(4,1,2)
plot(time, rvi_raw)
xlim([t_start, t_end])
subplot(4,1,3)
plot(time, ldn_raw)
xlim([t_start, t_end])
subplot(4,1,4)
plot(time, rdn_raw)
xlim([t_start, t_end])
