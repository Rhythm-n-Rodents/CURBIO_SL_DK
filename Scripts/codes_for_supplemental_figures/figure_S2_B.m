%% Figure S2B

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Edit Line #22. Use 'low' for foraging, or 'high' for rearing.
% 2. Edit Line #76. Edit the path to the "Data" folder.
% 2. Run the code.


clc;
clear;
close all;


%% Parameters

% Edit here. Use 'low' for foraging, or 'high' for rearing.
behavioral_mode = 'low';

C_COLOR = rgb(50, 50, 50);
AnimalID_ChNum = ["SLR100", 5, 'h', 4; ... % RDN, LDN
                  "SLR116", 6, 'h', 5; ...
                  "SLR117", 6, 'h', 5];

num_animals = size(AnimalID_ChNum, 1);
num_animals


for ai = 1:num_animals
    disp([char(AnimalID_ChNum(ai, 1)), ' - #', str(AnimalID_ChNum(ai, 2)), ' - #', str(AnimalID_ChNum(ai, 4))]);
end
disp(' ');


NORM_TIME = 'after'; % was after
DEVIDED_STD = true; % was true
rate = 2000;
T_SEG = 4;
F_SEG = rate*T_SEG;
f_max = 20;


%% Chronux hyperparameters
coh_T = T_SEG;
coh_W = 2;
coh_TW = coh_T*coh_W;
coh_K = floor(2*coh_T*coh_W)-1;
disp([9, str(T_SEG), ' s segments']);
disp(['Coherence: TW = ',str(coh_TW)]);
disp(['Coherence: K = ',str(coh_K)]);
disp(' ');

coh_params.tapers = [coh_TW, coh_K];
coh_params.pad = 1;
coh_params.Fs = rate;
coh_params.fpass = [0.1, f_max];
coh_params.err = [2, 0.05];
coh_params.trialave = 1;


%% Animal-independent variables
ALL_SEGS_A = [];
ALL_SEGS_B = [];


for ai = 1 : num_animals
	animal_ID = char(AnimalID_ChNum(ai, 1));
    rec_type = char(AnimalID_ChNum(ai, 3));
	disp(animal_ID)

	% move dir
	cur_folder_path = ['..\..\Data\', animal_ID];
	cd(cur_folder_path)
	
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

	% Signal pairs for coherence
	a_idx = str2double(AnimalID_ChNum(ai, 2));
	b_idx = str2double(AnimalID_ChNum(ai, 4));

	% COH_SEGS to store all the segments
	coh_segs_a = [];
	coh_segs_b = [];


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
		if or(strcmp(rec_type, 'h'), strcmp(rec_type, 'd'))
            bBools('usable') = SM_data_truncate(bBools('usable'), time_shift, rate, 'tail');

            if strcmp(behavioral_mode, 'low')
                alwbool = and(bBools('usable'), data(:,10) < -16.5);
            elseif strcmp(behavioral_mode, 'high')
                alwbool = and(bBools('usable'), data(:,10) > 43.5);
            end

        elseif strcmp(rec_type, 'x')
            bBools('usable') = SM_data_truncate(bBools('usable'), time_shift, rate, 'tail');
            alwbool = bBools('usable');
        end
		
		% signal segmentation for chronux
		a_segments = SM_seg4Chronux_alwbool_normfunc(data(:, a_idx), F_SEG, alwbool, NORM_TIME, DEVIDED_STD);
		b_segments = SM_seg4Chronux_alwbool_normfunc(data(:, b_idx), F_SEG, alwbool, NORM_TIME, DEVIDED_STD);
		
		% append
		coh_segs_a = [coh_segs_a, a_segments];
		coh_segs_b = [coh_segs_b, b_segments];
					
		clear alwbool data a_segments b_segments
	end 

	disp(' ');
    N = size(coh_segs_a, 2);
    disp(' ');
	disp(['Number of segments = ', str(N)]);
	disp('=================================');
	
    ALL_SEGS_A = [ALL_SEGS_A, coh_segs_a];
    ALL_SEGS_B = [ALL_SEGS_B, coh_segs_b];
    
end

disp(' ');
disp(['Number of segments = ', str(size(ALL_SEGS_A, 2))]);
disp('=================================');


%% animal-independent coherence
[ALL_C, ALL_PHI, ~, ~, ~, ALL_F, ALL_CONFC, ALL_PHISTD, ALL_CERR] = coherencyc(ALL_SEGS_A, ...
                                                                               ALL_SEGS_B, ...
                                                                               coh_params);
figure(5)
set(gcf, 'Color', 'w', 'Position', [100, 100, 400, 800], 'DefaultAxesFontSize', 15);
% phase of coherence
subplot(2,1,1); hold on;  
plot(ALL_F', unwrap(ALL_PHI), 'Color', C_COLOR, 'LineWidth', 2);
plot(ALL_F', unwrap(ALL_PHI) + 2*ALL_PHISTD, 'Color', C_COLOR, 'LineWidth', 0.5);
plot(ALL_F', unwrap(ALL_PHI) - 2*ALL_PHISTD, 'Color', C_COLOR, 'LineWidth', 0.5); hold off;
axis square; xticks((0:5:20));
ylabel({'Phase (rad)', ''}); ylim([-2*pi 2*pi]); yticks((-2*pi: pi : 2*pi)); yticklabels({'-2\pi', '-\pi', '0', '\pi', '2\pi'});
% |C|
subplot(2,1,2); hold on;
plot(ALL_F, ALL_C, 'Color', C_COLOR, 'LineWidth', 2);
plot(ALL_F, ALL_CERR(1,:), 'Color', C_COLOR, 'LineWidth', 0.5);
plot(ALL_F, ALL_CERR(2,:), 'Color', C_COLOR, 'LineWidth', 0.5);
plot([0, f_max],[ALL_CONFC, ALL_CONFC], 'k-', 'LineWidth', 2); hold off;
axis square; xlabel('f (Hz)'); xticks((0:5:20));
ylim([0, 1]); yticks((0:0.2:1)); ylabel({'|Coherence|', ''}); 
text(16, 0.9, {['T = ', str(coh_T), ' s'], ['W = ', str(coh_W), ' Hz']}, 'FontSize', 12);
