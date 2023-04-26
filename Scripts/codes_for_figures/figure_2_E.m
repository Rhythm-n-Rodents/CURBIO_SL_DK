%% Figure 2E

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Edit Line #22. Edit the path to the "Data" folder.
% 2. Uncomment one of Line #118 or #119 for foraging or rearing
% 3. Run the code.


clc;
clear;
close all;

%% Parameters
animal_ID = 'SLR087';
rec_type = 'd';

cur_folder_path = ['..\..\Data\', animal_ID];
cd(cur_folder_path)

%% Coherence (coh)
NT = 1;

% Signal indexes
COH_INDECES = containers.Map;
%COH_INDECES('1') = [33, 36]; % ht yaw
%COH_INDECES('1') = [27, 36]; % h yaw
COH_INDECES('1') = [28, 36]; % h pitch
%COH_INDECES('1') = [29, 36]; % h roll

%% COLOR
C_COLOR = containers.Map;
%C_COLOR('1') = rgb(222, 125, 0);  % ht yaw
%C_COLOR('1') = rgb(200, 0, 0);  % h yaw
C_COLOR('1') = rgb(0, 125, 0);  % h pitch
%C_COLOR('1') = rgb(0, 0, 125);  % h roll

%%
NORM_TIME = 'after';
DEVIDED_STD = true;
rate = 2000;

T_SEG = 1; % was 4

F_SEG = rate*T_SEG;

f_max = 50;

disp([9, 'Length of time segments: ' str(T_SEG), ' seconds']);
disp(' ');


%% COH_SEGS to store all the segments
COH_SEGS = containers.Map;
COH_REQUIRED_INDECES = [];
for nt = 1 : NT
    coh_indeces = COH_INDECES(str(nt));
    for i = 1 : 2
        coh_index_str = str(coh_indeces(i));
        if ~isKey(COH_SEGS, coh_index_str)
            COH_SEGS(coh_index_str) = [];
            COH_REQUIRED_INDECES = [COH_REQUIRED_INDECES , coh_indeces(i)];
        end
    end
end

disp([9, 'will use indeces:']);
disp(COH_REQUIRED_INDECES);

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

disp(' ');

%% Durations of different behaviors
ALW_DURATIONS = [];


%% Loading data recording by recording
for recordingIndex = recordingListMap(rec_type)
    %% Load data
    loaded_filename = [animal_ID, '_arena_', rec_type, str(recordingIndex), '_D_36data'];
    load(loaded_filename);
    disp([9, ' - ', loaded_filename]);
    SM_checkDataColumnNumber(data, 36);
    
    %% Time shift
    time_shift = 0.0095;
    data = SM_data_time_shift(data, (9:35), time_shift, rate);
    
    %% Allowed booleans
    bBools = bBoolsMap([rec_type, num2str(recordingIndex)]);
    % correct booleans to match time shift
    bBools('usable') = SM_data_truncate(bBools('usable'), time_shift, rate, 'tail');
    
    if rec_type == 'd'
        bBools('b3') = SM_data_truncate(bBools('b3'), time_shift, rate, 'tail');
    end
       
    lowpitchbool = data(:,10) < -16.5;
    highpitchbool = data(:,10) > 43.5;
    
    % specify allowed boolean
    % Edit here. Uncomment one of the declarations below
    % alwbool = and(lowpitchbool, bBools('b3'));  % for foraging
    alwbool = and(highpitchbool, bBools('b3'));  % for rearing
    
    
    %% Histogram of durations of alwbool
    cur = 1;
    dur = 0;
    while cur <= length(alwbool)
        if ~alwbool(cur)
            if dur ~= 0
                ALW_DURATIONS(end+1) = dur/rate;
                dur = 0;
            end
        else
            dur = dur + 1;
        end
        cur = cur + 1;
    end
    if dur ~= 0
        ALW_DURATIONS(end+1) = dur/rate;
    end
        
    %% Seeding container.Map to store recording-wise data
    for coh_index = COH_REQUIRED_INDECES
        signal = sign(coh_index)*data(:,abs(coh_index));
        signal_segmented = SM_seg4Chronux_alwbool_normfunc(signal, F_SEG, alwbool, NORM_TIME, DEVIDED_STD);
        
        COH_SEGS(str(coh_index)) = [COH_SEGS(str(coh_index)) , signal_segmented];
        clear signal
    end
    
    disp([9, 9, '- ', str(size(signal_segmented, 2)), ' segments found']);
    
    clear alwbool data signal_segmented
end

%%
disp(' ');
disp('=================================');
disp(' ');
N = size(COH_SEGS(str(COH_REQUIRED_INDECES(1))),2);
disp(['Spectrums: Number of segments = ', str(N)]);


%% Chronux
% coherence parameters
coh_T = T_SEG;
coh_W = 2;
coh_TW = coh_T*coh_W;
coh_K = max(floor(2*coh_T*coh_W)-1, 1);
disp(['Coherence: TW = ',str(coh_TW)]);
disp(['Coherence: K = ',str(coh_K)]);

coh_params.tapers = [coh_TW, coh_K];
coh_params.pad = 1;
coh_params.Fs = rate;
coh_params.fpass = [0.1, f_max];
coh_params.err = [2, 0.05];
coh_params.trialave = 1;

% seeding containers.Map
C = containers.Map;
phi = containers.Map;
phistd = containers.Map;
Cerr = containers.Map;

for nt = 1 : NT
    ntstr = str(nt);
    coh_indeces = COH_INDECES(ntstr);
    index_1_str = str(coh_indeces(1));
    index_2_str = str(coh_indeces(2));
    %[C(ntstr), phi(ntstr), ~, ~, ~, coh_f, coh_confC, phistd(ntstr), Cerr(ntstr)] = coherencyc(COH_SEGS(index_1_str), COH_SEGS(index_2_str), coh_params);
    [C(ntstr), phi(ntstr), S12, S1, S2, coh_f, coh_confC, phistd(ntstr), Cerr(ntstr)] = coherencyc(COH_SEGS(index_1_str), COH_SEGS(index_2_str), coh_params);
    clear ntstr coh_indeces index_1_str index_2_str
end



%% Plot
figure(1)
set(gcf, 'Color', 'w', 'Position', [100, 100, 450, 800], 'DefaultAxesFontSize', 15);
% coherence
subplot(3,1,3); hold on;
for nt = 1 : NT
    ntstr = str(nt);
    cerr_nt =  Cerr(ntstr);
    plot(coh_f, C(ntstr), 'Color', C_COLOR(ntstr), 'LineWidth', 3);
    plot(coh_f, cerr_nt(1,:), 'Color', C_COLOR(ntstr), 'LineWidth', 1);
    plot(coh_f, cerr_nt(2,:), 'Color', C_COLOR(ntstr), 'LineWidth', 1);
end
plot([0, f_max],[coh_confC, coh_confC], 'k-','LineWidth',2);
xlim([0, 20]); xticks((0:5:25));
xlabel('f (Hz)'); ylabel({'|Coherence|', ''});
ylim([0, 1]); yticks((0:0.2:1));
text(16, 0.9, {['N = ', str(N)], ['T = ', str(coh_T), ' s'], ['W = ', str(coh_W), ' Hz']}, 'FontSize', 10);
axis square; hold off;


% phase (>95% CI)
for nt = 1 : NT
    
    ntstr = str(nt);
    cerr = Cerr(ntstr)';
    
    significant_f = coh_f;
    significant_phase = unwrap(phi(ntstr));
    significant_phase_lower = unwrap(phi(ntstr)) - 2*phistd(ntstr);
    significant_phase_upper = unwrap(phi(ntstr)) + 2*phistd(ntstr);
    
    for f_idx = 1 : length(coh_f)
        if min(cerr(f_idx, :)) <= coh_confC
            significant_f(f_idx) = NaN;
        end
    end

    subplot(3,1,2); hold on 
    plot(significant_f, significant_phase_lower, 'Color', C_COLOR(ntstr), 'LineWidth', 0.5);
    plot(significant_f, significant_phase_upper, 'Color', C_COLOR(ntstr), 'LineWidth', 0.5);
    plot(significant_f, significant_phase, 'Color', C_COLOR(ntstr), 'LineWidth', 2); hold off
    axis square; xticks((0:5:25)); xlim([0, 20]);
    ylabel('Phase (rad)'); ylim([-2*pi, 2*pi]); yticks((-2*pi: pi : 2*pi)); yticklabels({'-2\pi', '-\pi', '0', '\pi', '2\pi'});
    box off
end

% phase
subplot(3,1,1); hold on;
for nt = 1 : NT
    ntstr = str(nt);
    plot(coh_f', unwrap(phi(ntstr)), 'Color', C_COLOR(ntstr), 'LineWidth', 3);
    plot(coh_f', unwrap(phi(ntstr)) + 2*phistd(ntstr), 'Color', C_COLOR(ntstr), 'LineWidth', 1);
    plot(coh_f', unwrap(phi(ntstr)) - 2*phistd(ntstr), 'Color', C_COLOR(ntstr), 'LineWidth', 1);
end
xlabel('f (Hz)'); xticks((0:5:25)); xlim([0, 20]);
ylabel({'Phase (rad)', ''}); ylim([-2*pi 2*pi]); yticks((-2*pi: pi : 2*pi)); yticklabels({'-2\pi', '-\pi', '0', '\pi', '2\pi'});
%text(16, 5, {['N = ', str(N)], ['T = ', str(coh_T), ' s'], ['W = ', str(coh_W), ' Hz']}, 'FontSize', 12);
axis square; hold off;
