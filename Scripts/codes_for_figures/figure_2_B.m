%% Figure 2B

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Edit Line #103. Edit the path to the "Data" folder.
% 2. Run the code.


clc;
clear;
close all;


%% Target signal
% breathing: 36
% head-torso yaw velocity: 33
% head pitch velocity: 28
% head roll velocity: 29

%% Behavioral state
behavioral_state = 'foraging';

%% General parameters
if strcmp(behavioral_state, 'foraging')
    POOLS = ["SLR087", "d"];
else
    POOLS = ["SLR087", "d"; ...
             "SLR089", "d"; ...
             "SLR090", "d"; ...
             "SLR092", "d"; ...
             "SLR093", "d"; ...
             "SLR095", "d"; ...
             "SLR102", "d"; ...
             "SLR103", "d"; ...
             "SLR105", "d"; ...
             "SLR106", "d"; ...
             "SLR108", "d"; ...
             "SLR110", "d"; ...
             "SLR111", "d"; ...
             "SLR112", "d"; ...
             "SLR113", "d"; ...
             "SLR115", "d"; ...
             "SLR119", "d"];
end

DATA_BREATHING = [];
DATA_HTYAW = [];
DATA_HPITCH = [];
DATA_HROLL = [];


%% Hyperparameters
NORM_TIME = 'after';
DEVIDED_STD = false;
rate = 2000;
T_SEG = 4;
F_SEG = rate*T_SEG;
f_max = 20;

disp(['T_SEG = ', str(T_SEG)]);
disp(' ');


%% Chronux hyperparameters
spec_T = T_SEG;
spec_W = 1;
spec_TW = spec_T*spec_W;
spec_K = floor(2*spec_T*spec_W)-1;
disp(['Coherence: TW = ',str(spec_TW)]);
disp(['Coherence: K = ',str(spec_K)]);
disp('==========');

spec_params.tapers = [spec_TW, spec_K];
spec_params.pad = 1;
spec_params.Fs = rate;
spec_params.fpass = [0.1, f_max];
spec_params.err = [2, 0.05];
spec_params.trialave = 1;


%% Number of animals
if isrow(POOLS)
    NUM_ANIMALS = 1;
else
    NUM_ANIMALS = size(POOLS, 1);
end


for i = 1 : NUM_ANIMALS
    animal_ID = char(POOLS(i, 1));
    rec_type = char(POOLS(i, 2));

    disp(' ');
    disp([char(animal_ID), ' - ', rec_type]);
    disp(' ');
    
    %% Change directory
    animal_ID = char(animal_ID);
    cur_folder_path = ['..\..\Data\', animal_ID];
    cd(cur_folder_path)

    %% Load recording list map
    load([animal_ID, '_D_recordingListMap.mat']);
    assert(strcmp(animal_ID, recordingListMap('animal_ID')), '[recordingListMap] animal_ID inconstent');

    %% Load bBoolsMap
    load([animal_ID, '_D_bBoolsMap.mat']);
    assert(strcmp(animal_ID, bBoolsMap('animal_ID')), '[bBoolsMap] animal_ID inconstent');

    %% Loading every recorded data
    for recordingIndex = recordingListMap(rec_type)
        %% Load data
        loaded_filename = [animal_ID, '_arena_', rec_type, num2str(recordingIndex), '_D_36data'];
        load(loaded_filename);
        disp([9, '-- ', loaded_filename]);
        SM_checkDataColumnNumber(data, 36);

        %% Time shift
        time_shift = 0.0095;
        data = SM_data_time_shift(data, (9:35), time_shift, rate);

        %% Allowed booleans
        bBools = bBoolsMap([rec_type, num2str(recordingIndex)]);
        bBools('usable') = SM_data_truncate(bBools('usable'), time_shift, rate, 'tail');
        if strcmp(rec_type, 'd')
            bBools('b3') = SM_data_truncate(bBools('b3'), time_shift, rate, 'tail');
        end
        
        if strcmp(behavioral_state, 'foraging')
            alwbool = and(bBools('b3'), data(:,10) < -16.5);
        else
            alwbool = and(bBools('b3'), data(:,10) > 43.5);
        end

        %% Denote data
        time = data(:,1);
        htyaw = data(:, 33);
        hpitch = data(:, 28);
        hroll = data(:, 29);
        breathing = data(:, 36);
           
        %% segmentation
        DATA_HTYAW = [DATA_HTYAW, SM_seg4Chronux_alwbool_normfunc(htyaw, F_SEG, alwbool, NORM_TIME, DEVIDED_STD)];
        DATA_HPITCH = [DATA_HPITCH, SM_seg4Chronux_alwbool_normfunc(hpitch, F_SEG, alwbool, NORM_TIME, DEVIDED_STD)];
        DATA_HROLL = [DATA_HROLL, SM_seg4Chronux_alwbool_normfunc(hroll, F_SEG, alwbool, NORM_TIME, DEVIDED_STD)];
        DATA_BREATHING = [DATA_BREATHING, SM_seg4Chronux_alwbool_normfunc(breathing, F_SEG, alwbool, NORM_TIME, DEVIDED_STD)];
    end

end

disp(' ')
disp(['Total segments: ', str(size(DATA_BREATHING, 2))]);

%% Spectrums
[S_breathing, ~, Serr_breathing] = mtspectrumc(DATA_BREATHING, spec_params);
[S_htyaw, f, Serr_htyaw] = mtspectrumc(DATA_HTYAW, spec_params);
[S_hpitch, ~, Serr_hpitch] = mtspectrumc(DATA_HPITCH, spec_params);
[S_hroll, ~, Serr_hroll] = mtspectrumc(DATA_HROLL, spec_params);

f = f';
Serr_htyaw = Serr_htyaw';
Serr_hpitch = Serr_hpitch';
Serr_hroll = Serr_hroll';
Serr_breathing = Serr_breathing';

% check dimensions
assert(iscolumn(S_htyaw));
assert(iscolumn(f));
assert(size(Serr_htyaw, 2)==2);

%% plot spectrums
figure()
set(gcf, 'Color', 'w', 'Position', [100, 100, 1114, 358], 'DefaultAxesFontSize', 15);

% breathing
subplot(1,4,1)
plot(f, log10(S_breathing), 'Color', rgb(128, 0, 0), 'LineWidth', 2); hold on;
plot(f, log10(Serr_breathing), 'Color', rgb(128, 0, 0), 'LineWidth', 0.5);
xticks((0:5:50)); title('Breathing');
axis square; hold off

% head-torso yaw vel
subplot(1,4,2)
plot(f, log10(S_htyaw), 'Color', rgb(222, 125, 0), 'LineWidth', 2); hold on;
plot(f, log10(Serr_htyaw), 'Color', rgb(222, 125, 0), 'LineWidth', 0.5);
xticks((0:5:50)); title('Head-torso yaw');
axis square; hold off

% head pitch vel
subplot(1,4,3)
plot(f, log10(S_hpitch), 'Color', rgb(128, 128, 0), 'LineWidth', 2); hold on;
plot(f, log10(Serr_hpitch), 'Color', rgb(128, 128, 0), 'LineWidth', 0.5);
xticks((0:5:50)); title('Head pitch');
axis square; hold off

% head roll vel
subplot(1,4,4)
plot(f, log10(S_hroll), 'Color', rgb(128, 128, 128), 'LineWidth', 2); hold on;
plot(f, log10(Serr_hroll), 'Color', rgb(128, 128, 128), 'LineWidth', 0.5);
xticks((0:5:50)); title('Head roll');
axis square; hold off
