%% Figure S1C_part2

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Edit Line #114. Edit the path to the "Data" folder.
% 2. Run the code.


clc;
clear;
close all;

%% Behavioral mode
behavior_mode = 'low';


%% Hyperparameters
NORM_TIME = 'after';
DEVIDED_STD = true;
rate = 2000;
T_SEG = 4;
F_SEG = rate*T_SEG;
f_max = 50;

disp(['T_SEG = ', str(T_SEG)]);
disp(' ');

%% Chronux hyperparameters
coh_T = T_SEG;
coh_W = 1;
coh_TW = coh_T*coh_W;
coh_K = floor(2*coh_T*coh_W)-1;
disp(['Coherence: TW = ',str(coh_TW)]);
disp(['Coherence: K = ',str(coh_K)]);
disp('==========');

coh_params.tapers = [coh_TW, coh_K];
coh_params.pad = 1;
coh_params.Fs = rate;
coh_params.fpass = [0.1, f_max];
coh_params.err = [2, 0.05];
coh_params.trialave = 1;


%% Parameters
MUSCLE_LIST = ["SM", "CM", "CT", "SP", "BC"];


for muscle_idx = 1 : length(MUSCLE_LIST)
    
    muscle_name = str(MUSCLE_LIST(muscle_idx));
    disp(muscle_name);

    switch muscle_name  % [animal_id, rec_type, channel # of 36-data]

        case "SM"
            C_COLOR = rgb(61, 133, 198);
            AnimalID_ChNum = ["SLR110", 4, 'd'; ... % L
                              "SLR111", 4, 'd'];    % L

        case "CM"
            C_COLOR = rgb(103, 78, 167);
            AnimalID_ChNum = ["SLR108", 3, 'd'; ... % L
                              "SLR110", 3, 'd'; ... % L
                              "SLR111", 3, 'd'];    % L
        case "CT"
            C_COLOR = rgb(166, 77, 121);
            AnimalID_ChNum = ["SLR102", 5, 'd'; ... % L
                              "SLR103", 5, 'd'; ... % L
                              "SLR105", 5, 'd'; ... % L
                              "SLR106", 5, 'd'];    % L
        case "SP"
            C_COLOR = rgb(34, 139, 34);
            AnimalID_ChNum = ["SLR112", 6, 'd'; ... % L
                              "SLR113", 4, 'd'; ... % L
                              "SLR115", 4, 'd'];    % L
                          
        case "BC"
            C_COLOR = rgb(107, 142, 35);
            AnimalID_ChNum = ["SLR112", 5, 'd'; ... % L
                              "SLR113", 6, 'd'; ... % L
                              "SLR115", 6, 'd'];    % L
    end
    
    % define number of animals
    if isrow(AnimalID_ChNum)
        num_animals = 1;
    else
        num_animals = size(AnimalID_ChNum, 1);
    end
    disp(['Number of animals: ', str(num_animals)]);

    % print information of animals
    for ai = 1:num_animals
        disp([char(AnimalID_ChNum(ai, 1)), ' - #', str(AnimalID_ChNum(ai, 2))]);
    end
    disp(' ');

    
    % muscle-wise variables
    SEGS_A = [];
    SEGS_B = [];

    for ai = 1 : num_animals
        animal_ID = char(AnimalID_ChNum(ai, 1));
        rec_type = char(AnimalID_ChNum(ai, 3));
        disp(animal_ID)

        % move dir
        cur_folder_path = ['..\..\Data\', animal_ID];
        cd(cur_folder_path)

        % Load recording list map
        load([animal_ID, '_D_recordingListMap.mat']);
        assert(strcmp(animal_ID, recordingListMap('animal_ID')), '[recordingListMap] animal_ID inconstent');

        % Load bBoolsMap
        load([animal_ID, '_D_bBoolsMap.mat']);
        assert(strcmp(animal_ID, bBoolsMap('animal_ID')), '[bBoolsMap] animal_ID inconstent');

        % Signal pairs for coherence
        a_idx = str2double(AnimalID_ChNum(ai, 2));
        b_idx = 33;

        % COH_SEGS to store all the segments
        segs_a = [];
        segs_b = [];

        %% Loading data
        for recordingIndex = recordingListMap(rec_type)
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
            bBools('b3') = SM_data_truncate(bBools('b3'), time_shift, rate, 'tail');
                
            if strcmp(behavior_mode, 'low')
                alwbool = and(bBools('b3'), data(:,10) < -16.5);
            elseif strcmp(behavior_mode, 'high')
                alwbool = and(bBools('b3'), data(:,10) > 43.5);
            end

            % signal segmentation for chronux
            a_segments = SM_seg4Chronux_alwbool_normfunc(data(:, a_idx), F_SEG, alwbool, NORM_TIME, DEVIDED_STD);
            b_segments = SM_seg4Chronux_alwbool_normfunc(data(:, b_idx), F_SEG, alwbool, NORM_TIME, DEVIDED_STD);

            % append
            segs_a = [segs_a, a_segments];
            segs_b = [segs_b, b_segments];

            clear alwbool data a_segments b_segments
        
        end  % end of recordings 

        disp(' ');
        disp(['Number of segments = ', str(size(segs_a, 2))]);
        disp(' ');

        % append to list
        SEGS_A = [SEGS_A, segs_a];
        SEGS_B = [SEGS_B, segs_b];

    end  % end of animals
    
    disp(' ')
    disp([muscle_name, ' - Total segments: ', str(size(SEGS_A, 2))]);

    %% Muscle coherence (all animals)
    [C, phi, ~, ~, ~, f, conf, phistd, cerr] = coherencyc(SEGS_A, SEGS_B, coh_params);
    f = f';
    conf = conf(1, 1);
    cerr = cerr';

    % shift phase manually by 2pi (Figure S1C)
    if strcmp(muscle_name, 'CT')
        phi = phi + 2*pi;
    elseif strcmp(muscle_name, 'SP')
        phi = phi + 2*pi;
    elseif strcmp(muscle_name, 'BC')
        phi = phi + 2*pi;
    end
    
    % check dimensions
    assert(iscolumn(C));
    assert(iscolumn(f));
    assert(iscolumn(phi));
    assert(iscolumn(phistd));
    assert(size(cerr, 2)==2);
    
    figure('Name', muscle_name)
    set(gcf, 'Color', 'w', 'Position', [100, 100, 420, 900], 'DefaultAxesFontSize', 15);
    
    % phase (all frequencies)
    subplot(3,1,1); 
    plot(f, unwrap(phi) + 2*phistd, 'Color', C_COLOR, 'LineWidth', 0.5); hold on 
    plot(f, unwrap(phi) - 2*phistd, 'Color', C_COLOR, 'LineWidth', 0.5);
    plot(f, unwrap(phi), 'Color', C_COLOR, 'LineWidth', 2); hold off
    axis square; xticks((0:5:25)); xlim([0,25]);
    ylabel('Phase (rad)'); ylim([-4*pi, 4*pi]); yticks((-4*pi: pi : 4*pi));
    yticklabels({'-4\pi', '-3\pi', '-2\pi', '-\pi', '0', '\pi', '2\pi', '3\pi', '4\pi'});
    box off
    
    % phase (>95% CI)
    significant_f = f;
    significant_phase = unwrap(phi);
    significant_phase_lower = unwrap(phi) - 2*phistd;
    significant_phase_upper = unwrap(phi) + 2*phistd;
    
    for f_idx = 1 : length(f)
        if min(cerr(f_idx, :)) <= conf
            significant_f(f_idx) = NaN;
        end
    end
    
    subplot(3,1,2); 
    plot(significant_f, significant_phase_lower, 'Color', C_COLOR, 'LineWidth', 0.5); hold on 
    plot(significant_f, significant_phase_upper, 'Color', C_COLOR, 'LineWidth', 0.5);
    plot(significant_f, significant_phase, 'Color', C_COLOR, 'LineWidth', 2); hold off
    axis square; xticks((0:5:25)); xlim([0, 25]);
    ylabel('Phase (rad)'); ylim([-4*pi, 4*pi]); yticks((-4*pi: pi : 4*pi));
    yticklabels({'-4\pi', '-3\pi', '-2\pi', '-\pi', '0', '\pi', '2\pi', '3\pi', '4\pi'});
    box off
    
    % |C|
    subplot(3,1,3); hold on;  
    plot(f, C, 'Color', C_COLOR, 'LineWidth', 2);
    plot(f, cerr(:, 1), 'Color', C_COLOR, 'LineWidth', 0.5);
    plot(f, cerr(:, 2), 'Color', C_COLOR, 'LineWidth', 0.5);
    plot([0, 25],[conf, conf], 'k-', 'LineWidth', 2); hold off;
    axis square; xlabel('f (Hz)'); xticks((0:5:25)); xlim([0, 25]);
    ylim([0, 1]); yticks((0:0.2:1)); ylabel({'|Coherence|', ''}); 
    text(16, 0.9, {['T = ', str(coh_T), ' s'], ['W = ', str(coh_W), ' Hz']}, 'FontSize', 12);
end
