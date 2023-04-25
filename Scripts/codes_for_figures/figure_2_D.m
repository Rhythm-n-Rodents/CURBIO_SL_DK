%% Figure 2D

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Edit Line #19. Use 'low' for foraging or 'high' for rearing.
% 2. Edit Line #111. Edit the path to the "Data" folder.
% 3. Run the code.


clc;
clear;
close all;

%% Behavioral state
behavioral_state = 'low';  % Edit here. 'low': foraging | 'high': rearing

if strcmp(behavioral_state, 'low')
    disp('===== Foraging =====');
elseif strcmp(behavioral_state, 'high')
    disp('===== Rearing =====');
end

%% Animals
POOLS = ["SLR087", "d"; ...
         "SLR089", "d"; ...
         "SLR090", "d"; ...
         "SLR092", "d"; ...
         "SLR093", "d"; ...
         "SLR094", "h"; ...
         "SLR095", "d"; ...
         "SLR096", "h"; ...
         "SLR097", "h"; ...
         "SLR099", "h"; ...
         "SLR100", "h"; ...
         "SLR102", "d"; ...
         "SLR103", "d"; ...
         "SLR105", "d"; ...
         "SLR106", "d"; ...
         "SLR107", "h"; ...
         "SLR108", "d"; ...
         "SLR110", "d"; ...
         "SLR111", "d"; ...
         "SLR112", "d"; ...
         "SLR113", "d"; ...
         "SLR114", "h"; ...
         "SLR115", "d"; ...
         "SLR116", "h"; ...
         "SLR117", "h"; ...
         "SLR119", "d"; ...
         "SLR120", "h"; ...
         "SLR121", "h"; ...
         "SLR122", "h"; ...
         "SLR123", "h"; ...
         "SLR124", "h"; ...
         "SLR125", "h"; ...
         "SLR126", "h"];

rate = 2000;
     
% Restriction on the breathing frequency
BASE_FMIN = 4;
BASE_FMAX = 14;
disp('=== Breathing Frequency ===');
disp(['BASE_FMIN = ', str(BASE_FMIN)]);
disp(['BASE_FMAX = ', str(BASE_FMAX)]);
disp('');

%% BSTA params
BSTA_TIME = 0.2;
BSTA_FRAME = rate * BSTA_TIME;
BSTA_X = (-BSTA_TIME : 1/rate : BSTA_TIME);


%% Pre-allocate BSTA segments for each animal
all_bsta_breathing = [];            % shape = (bsta_window_size, num_animals)

all_bsta_headyawvel = [];           % shape = (bsta_window_size, num_animals)
all_bsta_headyawvel_cw = [];        % shape = (bsta_window_size, num_animals)
all_bsta_headyawvel_ccw = [];       % shape = (bsta_window_size, num_animals)

all_bsta_headtorsoyawvel = [];      % shape = (bsta_window_size, num_animals)
all_bsta_headtorsoyawvel_cw = [];   % shape = (bsta_window_size, num_animals)
all_bsta_headtorsoyawvel_ccw = [];  % shape = (bsta_window_size, num_animals)

all_bsta_headtorsoyawang = [];      % shape = (bsta_window_size, num_animals)
all_bsta_headtorsoyawang_cw = [];   % shape = (bsta_window_size, num_animals)
all_bsta_headtorsoyawang_ccw = [];  % shape = (bsta_window_size, num_animals)

all_bsta_headpitchvel = [];         % shape = (bsta_window_size, num_animals)
all_bsta_headpitchang = [];         % shape = (bsta_window_size, num_animals)

all_bsta_headrollvel = [];          % shape = (bsta_window_size, num_animals)
all_bsta_headrollang = [];          % shape = (bsta_window_size, num_animals)


%% Iterate over all animals
for ai = 1 : size(POOLS, 1)
    
    %% Animal information
    animal_ID = char(POOLS(ai, 1));
    rec_type = char(POOLS(ai, 2));

    disp([animal_ID, ' - ', rec_type]);
    disp(' ');

    % switch directory
    cd(['..\..\Data\', char(animal_ID)]);

    % load recording list map
    load([animal_ID, '_D_recordingListMap.mat']);
    assert(strcmp(animal_ID, recordingListMap('animal_ID')), '[recordingListMap] animal_ID inconstent');

    % load bBoolsMap
    load([animal_ID, '_D_bBoolsMap.mat']);
    assert(strcmp(animal_ID, bBoolsMap('animal_ID')), '[bBoolsMap] animal_ID inconstent');

    % load percentiles
    load([animal_ID, '_D_percentiles_36data.mat']);
    assert(strcmp(animal_ID, percentiles.animal_ID), '[percentiles] animal_ID inconstent');
    pcts = percentiles.pcts;

    % animal-wise variables
    animal_bsta_breathing = [];  % breathing
    
    animal_bsta_htyawvel = [];   % head-torso yaw velocity
    animal_bsta_hyawvel = [];    % head yaw velocity
    animal_bsta_hpitchvel = [];  % head pitch velocity
    animal_bsta_hrollvel = [];   % head roll velocity
    
    animal_bsta_htyawang = [];   % head-torso yaw angle
    animal_bsta_hpitchang = [];  % head pitch angle
    animal_bsta_hrollang = [];   % head roll angle

    %% Loading recordings
    for recordingIndex = recordingListMap(rec_type)

        %% Load data
        %cd(['C:\Songmao\KleinfeldLab\', char(animal_ID)]);
        loaded_filename = [animal_ID, '_arena_', rec_type, num2str(recordingIndex), '_D_36data'];
        load(loaded_filename);
        disp([' - ', loaded_filename]);
        SM_checkDataColumnNumber(data, 36);

        %% Time delay correction
        TIME_DELAY_CORRECTION = 0.0095;
        data = SM_data_time_shift(data, (9:35), TIME_DELAY_CORRECTION, rate);

        %% Allowed booleans
        bBools = bBoolsMap([rec_type, num2str(recordingIndex)]);
        
        if strcmp(rec_type, 'h')
            alwbool = SM_data_truncate(bBools('usable'), TIME_DELAY_CORRECTION, rate, 'tail');
        else
            bBools('b3') = SM_data_truncate(bBools('b3'), TIME_DELAY_CORRECTION, rate, 'tail');
            alwbool = bBools('b3');
        end
        
        if strcmp(behavioral_state, 'low')
            alwbool = and(alwbool, data(:,10) < -16.5);
        else
            alwbool = and(alwbool, data(:,10) > 43.5);
        end
        

        %% Denote data
        breathing = data(:, 36);
        
        hyawvel = data(:, 27);
        hpitchvel = data(:, 28);
        hrollvel = data(:, 29);
        
        hyawang = data(:, 9);
        hpitchang = data(:, 10);
        hrollang = data(:, 11);
        
        torsoyawang = data(:, 18);
        
        %% Process head-torso yaw data
        if strcmp(rec_type, 'd')
            htyawang = hyawang - torsoyawang;
            htyawang_mean = mean(htyawang(bBools('b3')));
            htyawang = htyawang - htyawang_mean;
            
            htyawvel = data(:, 33);            
        end
       
        %% Breathing data processing
        [breathing_peaks, breathing_valleys] = sniffutil_getrespinflections_findpeaks(breathing);
        breathing_onsets = sniffutil_getxpct_risetimes(breathing, breathing_peaks, breathing_valleys, 10);
        
        breathing_lengths = breathing_onsets(2:end) - breathing_onsets(1:end-1);
        breathing_onsets = breathing_onsets(1:end-1);
        
        % sift breathing frequency 
        breathing_fmax_boolean = (breathing_lengths >= rate/BASE_FMAX);
        breathing_onsets = breathing_onsets(breathing_fmax_boolean);
        breathing_lengths = breathing_lengths(breathing_fmax_boolean);
            
        breathing_fmin_boolean = (breathing_lengths <= rate/BASE_FMIN);
        breathing_onsets = breathing_onsets(breathing_fmin_boolean);
        breathing_lengths = breathing_lengths(breathing_fmin_boolean);
        
        % sift alwbool
        [breathing_onsets, breathing_lengths] = SM_breathingBevConstraint(breathing_onsets, breathing_lengths, alwbool);
        
        
        
        if isempty(breathing_onsets)
            continue
        end
        
        
        %% BSTA
        % breathing
        animal_bsta_breathing = [animal_bsta_breathing, SM_etat_routine(breathing, breathing_onsets, BSTA_FRAME, alwbool)];
        % angles
        animal_bsta_hpitchang = [animal_bsta_hpitchang, SM_etat_routine(hpitchang, breathing_onsets, BSTA_FRAME, alwbool)];
        animal_bsta_hrollang = [animal_bsta_hrollang, SM_etat_routine(hrollang, breathing_onsets, BSTA_FRAME, alwbool)];
        % velocities
        animal_bsta_hyawvel = [animal_bsta_hyawvel, SM_etat_routine(hyawvel, breathing_onsets, BSTA_FRAME, alwbool)];
        animal_bsta_hpitchvel = [animal_bsta_hpitchvel, SM_etat_routine(hpitchvel, breathing_onsets, BSTA_FRAME, alwbool)];
        animal_bsta_hrollvel = [animal_bsta_hrollvel, SM_etat_routine(hrollvel, breathing_onsets, BSTA_FRAME, alwbool)];
        % head-torso
        if strcmp(rec_type, 'd')
            animal_bsta_htyawang = [animal_bsta_htyawang, SM_etat_routine(htyawang, breathing_onsets, BSTA_FRAME, alwbool)];
            animal_bsta_htyawvel = [animal_bsta_htyawvel, SM_etat_routine(htyawvel, breathing_onsets, BSTA_FRAME, alwbool)];
        end
        
    end  % end of recordings
    
    if isempty(animal_bsta_breathing)
        continue
    end
    
    
    %% Split CW and CCW yaws
    disp(['Number of segs: ', str(size(animal_bsta_hyawvel, 2))]);
    mid_index = (length(BSTA_X)+1)/2;
    
    
    animal_bsta_hyawvel_cw = animal_bsta_hyawvel(:, animal_bsta_hyawvel(mid_index, :) > 0);
    animal_bsta_hyawvel_ccw = animal_bsta_hyawvel(:, animal_bsta_hyawvel(mid_index, :) < 0);
    
    
    if strcmp(rec_type, 'd')
        animal_bsta_htyawvel_cw = animal_bsta_htyawvel(:, animal_bsta_htyawvel(mid_index, :) > 0);
        animal_bsta_htyawvel_ccw = animal_bsta_htyawvel(:, animal_bsta_htyawvel(mid_index, :) < 0);
        
        animal_bsta_htyawang_cw = animal_bsta_htyawang(:, animal_bsta_htyawvel(mid_index, :) > 0);
        animal_bsta_htyawang_ccw = animal_bsta_htyawang(:, animal_bsta_htyawvel(mid_index, :) < 0);
    end
    
    
    %% Calculate animal-wise average
    [ani_bsta_breathing_mean, ani_bsta_breathing_error, ani_bsta_n] = SM_sta(animal_bsta_breathing);
    
    % head-torso yaw angle (CW) 
    if ~isempty(animal_bsta_htyawang_cw)  
        [ani_bsta_htyawang_cw_mean, ani_bsta_htyawang_cw_error, ani_bsta_htyawang_cw_n] = SM_sta(animal_bsta_htyawang_cw);
    end
    % head-torso yaw angle (CCW) 
    if ~isempty(animal_bsta_htyawang_ccw)  
        [ani_bsta_htyawang_ccw_mean, ani_bsta_htyawang_ccw_error, ani_bsta_htyawang_ccw_n] = SM_sta(animal_bsta_htyawang_ccw);
    end
    % head-torso yaw angle (CW+CCW) 
    [ani_bsta_htyawang_mean, ani_bsta_htyawang_error, ani_bsta_htyawang_n] = SM_sta(animal_bsta_htyawang);
    % head pitch angle
    [ani_bsta_hpitchang_mean, ani_bsta_hpitchang_error, ani_bsta_hpitchang_n] = SM_sta(animal_bsta_hpitchang);
    % head roll angle
    [ani_bsta_hrollang_mean, ani_bsta_hrollang_error, ani_bsta_hrollang_n] = SM_sta(animal_bsta_hrollang);
    
    
    % head-torso yaw velocity (CW) 
    if ~isempty(animal_bsta_htyawvel_cw)  
        [ani_bsta_htyawvel_cw_mean, ani_bsta_htyawvel_cw_error, ~] = SM_sta(animal_bsta_htyawvel_cw);
    end
    % head-torso yaw velocity (CCW) 
    if ~isempty(animal_bsta_htyawvel_ccw)  
        [ani_bsta_htyawvel_ccw_mean, ani_bsta_htyawvel_ccw_error, ~] = SM_sta(animal_bsta_htyawvel_ccw);
    end
    % head-torso yaw velocity (CW+CCW) 
    [ani_bsta_htyawvel_mean, ani_bsta_htyawvel_error, ~] = SM_sta(animal_bsta_htyawvel);
    
    
    % head yaw velocity (CW) 
    if ~isempty(animal_bsta_hyawvel_cw)
        [ani_bsta_hyawvel_cw_mean, ani_bsta_hyawvel_cw_error, ani_bsta_hyawvel_cw_n] = SM_sta(animal_bsta_hyawvel_cw);
    end
    % head yaw velocity (CCW) 
    if ~isempty(animal_bsta_hyawvel_ccw)
        [ani_bsta_hyawvel_ccw_mean, ani_bsta_hyawvel_ccw_error, ani_bsta_hyawvel_ccw_n] = SM_sta(animal_bsta_hyawvel_ccw);
    end
    % head yaw velocity (CW+CCW) 
    [ani_bsta_hyawvel_mean, ani_bsta_hyawvel_error, ani_bsta_hyawvel_n] = SM_sta(animal_bsta_hyawvel);
    % head pitch velocity
    [ani_bsta_hpitchvel_mean, ani_bsta_hpitchvel_error, ~] = SM_sta(animal_bsta_hpitchvel);
    % head roll velocity
    [ani_bsta_hrollvel_mean, ani_bsta_hrollvel_error, ~] = SM_sta(animal_bsta_hrollvel);
    
    
    %% Plot individual animal result (angle)
%     figure('Name', [animal_ID, ': ang- n = ', str(ani_bsta_n)])
%     set(gcf, 'Position', [50, 50, 560, 830])
%     % head-torso yaw angle
%     if strcmp(rec_type, 'd')
%         subplot(4, 1, 1); hold on  
%         plot(BSTA_X, ani_bsta_htyawang_cw_mean, 'Color', rgb(0, 115, 189), 'LineWidth', 1);
%         plot(BSTA_X, ani_bsta_htyawang_cw_error, 'Color', rgb(0, 115, 189), 'LineWidth', 0.5);
%         plot(BSTA_X, ani_bsta_htyawang_ccw_mean, 'Color', rgb(217, 84, 26), 'LineWidth', 1);
%         plot(BSTA_X, ani_bsta_htyawang_ccw_error, 'Color', rgb(217, 84, 26), 'LineWidth', 0.5);
%         plot(BSTA_X, ani_bsta_htyawang_mean, 'Color', rgb(128, 128, 128), 'LineWidth', 1);
%         plot(BSTA_X, ani_bsta_htyawang_error, 'Color', rgb(128, 128, 128), 'LineWidth', 0.5);
%         xlim([-inf, inf]); hold off
%     end
%     % head pitch angle
%     subplot(4, 1, 2); hold on
%     plot(BSTA_X, ani_bsta_hpitchang_mean, 'Color', rgb(128, 128, 128), 'LineWidth', 1);
%     plot(BSTA_X, ani_bsta_hpitchang_error, 'Color', rgb(128, 128, 128), 'LineWidth', 0.5);
%     xlim([-inf, inf]); hold off
%     % head roll angle
%     subplot(4, 1, 3); hold on
%     plot(BSTA_X, ani_bsta_hrollang_mean, 'Color', rgb(128, 128, 128), 'LineWidth', 1);
%     plot(BSTA_X, ani_bsta_hrollang_error, 'Color', rgb(128, 128, 128), 'LineWidth', 0.5);
%     xlim([-inf, inf]); hold off
%     % breathing
%     subplot(4, 1, 4); hold on
%     plot(BSTA_X, ani_bsta_breathing_mean, 'Color', rgb(128, 0, 0), 'LineWidth', 1);
%     plot(BSTA_X, ani_bsta_breathing_error, 'Color', rgb(128, 0, 0), 'LineWidth', 0.5);
%     xlim([-inf, inf]); hold off
    
    
    %% Plot individual animal result (velocity)
%     figure('Name', [animal_ID, ': vel- n = ', str(ani_bsta_n)])
%     set(gcf, 'Position', [50, 50, 560, 830])
%     % head-torso yaw velocity
%     if strcmp(rec_type, 'd')
%         subplot(4, 1, 1); hold on  
%         plot(BSTA_X, ani_bsta_htyawvel_cw_mean, 'Color', rgb(0, 115, 189), 'LineWidth', 1);
%         plot(BSTA_X, ani_bsta_htyawvel_cw_error, 'Color', rgb(0, 115, 189), 'LineWidth', 0.5);
%         plot(BSTA_X, ani_bsta_htyawvel_ccw_mean, 'Color', rgb(217, 84, 26), 'LineWidth', 1);
%         plot(BSTA_X, ani_bsta_htyawvel_ccw_error, 'Color', rgb(217, 84, 26), 'LineWidth', 0.5);
%         plot(BSTA_X, ani_bsta_htyawvel_mean, 'Color', rgb(128, 128, 128), 'LineWidth', 1);
%         plot(BSTA_X, ani_bsta_htyawvel_error, 'Color', rgb(128, 128, 128), 'LineWidth', 0.5);
%         xlim([-inf, inf]); hold off
%     end
%     % head yaw velocity
%     subplot(4, 1, 2); hold on
%     plot(BSTA_X, ani_bsta_hyawvel_cw_mean, 'Color', rgb(0, 115, 189), 'LineWidth', 1);
%     plot(BSTA_X, ani_bsta_hyawvel_cw_error, 'Color', rgb(0, 115, 189), 'LineWidth', 0.5);
%     plot(BSTA_X, ani_bsta_hyawvel_ccw_mean, 'Color', rgb(217, 84, 26), 'LineWidth', 1);
%     plot(BSTA_X, ani_bsta_hyawvel_ccw_error, 'Color', rgb(217, 84, 26), 'LineWidth', 0.5);
%     plot(BSTA_X, ani_bsta_hyawvel_mean, 'Color', rgb(128, 128, 128), 'LineWidth', 1);
%     plot(BSTA_X, ani_bsta_hyawvel_error, 'Color', rgb(128, 128, 128), 'LineWidth', 0.5);
%     xlim([-inf, inf]); hold off
%     % head pitch velocity
%     subplot(4, 1, 3); hold on
%     plot(BSTA_X, ani_bsta_hpitchvel_mean, 'Color', rgb(128, 128, 128), 'LineWidth', 1);
%     plot(BSTA_X, ani_bsta_hpitchvel_error, 'Color', rgb(128, 128, 128), 'LineWidth', 0.5);
%     xlim([-inf, inf]); hold off
%     % head roll velocity
%     subplot(4, 1, 4); hold on
%     plot(BSTA_X, ani_bsta_hrollvel_mean, 'Color', rgb(128, 128, 128), 'LineWidth', 1);
%     plot(BSTA_X, ani_bsta_hrollvel_error, 'Color', rgb(128, 128, 128), 'LineWidth', 0.5);
%     xlim([-inf, inf]); hold off
    
    
    %% Combine animal data, shape = (bsta_window_size, num_animals)
    % breathing
    all_bsta_breathing = [all_bsta_breathing, ani_bsta_breathing_mean];
    % head-torso yaw angles
    if strcmp(rec_type, 'd')
        if ~isempty(ani_bsta_htyawang_cw_mean)
            all_bsta_headtorsoyawang_cw = [all_bsta_headtorsoyawang_cw, ani_bsta_htyawang_cw_mean];
        end
        if ~isempty(ani_bsta_htyawang_ccw_mean)
            all_bsta_headtorsoyawang_ccw = [all_bsta_headtorsoyawang_ccw, ani_bsta_htyawang_ccw_mean];
        end
        all_bsta_headtorsoyawang = [all_bsta_headtorsoyawang, ani_bsta_htyawang_mean];
    end
    % head pitch angle
    all_bsta_headpitchang = [all_bsta_headpitchang, ani_bsta_hpitchang_mean];
    % head roll angle
    all_bsta_headrollang = [all_bsta_headrollang, ani_bsta_hrollang_mean];
    
    % head-torso yaw velocity
    if strcmp(rec_type, 'd')
        if ~isempty(ani_bsta_htyawvel_cw_mean)
            all_bsta_headtorsoyawvel_cw = [all_bsta_headtorsoyawvel_cw, ani_bsta_htyawvel_cw_mean];
        end
        if ~isempty(ani_bsta_htyawvel_ccw_mean)
            all_bsta_headtorsoyawvel_ccw = [all_bsta_headtorsoyawvel_ccw, ani_bsta_htyawvel_ccw_mean];
        end
        all_bsta_headtorsoyawvel = [all_bsta_headtorsoyawvel, ani_bsta_htyawvel_mean];
    end
    % head yaw velocity
    if ~isempty(ani_bsta_hyawvel_cw_mean)
        all_bsta_headyawvel_cw = [all_bsta_headyawvel_cw, ani_bsta_hyawvel_cw_mean];
    end
    if ~isempty(ani_bsta_hyawvel_ccw_mean)
        all_bsta_headyawvel_ccw = [all_bsta_headyawvel_ccw, ani_bsta_hyawvel_ccw_mean];
    end
    all_bsta_headyawvel = [all_bsta_headyawvel, ani_bsta_hyawvel_mean];
    % head pitch velocity
    all_bsta_headpitchvel = [all_bsta_headpitchvel, ani_bsta_hpitchvel_mean];
    % head roll velocity
    all_bsta_headrollvel = [all_bsta_headrollvel, ani_bsta_hrollvel_mean];

end

%% Calculate average across all animals
% breathing
[all_bsta_breathing_mean, all_bsta_breathing_error, ~] = SM_sta(all_bsta_breathing);

% head-torso yaw angle
[all_bsta_htyawang_cw_mean, all_bsta_htyawang_cw_error, ~] = SM_sta(all_bsta_headtorsoyawang_cw);
[all_bsta_htyawang_ccw_mean, all_bsta_htyawang_ccw_error, ~] = SM_sta(all_bsta_headtorsoyawang_ccw);
[all_bsta_htyawang_mean, all_bsta_htyawang_error, ~] = SM_sta(all_bsta_headtorsoyawang);
% head pitch angle
[all_bsta_hpitchang_mean, all_bsta_hpitchang_error, ~] = SM_sta(all_bsta_headpitchang);
% head roll angle
[all_bsta_hrollang_mean, all_bsta_hrollang_error, ~] = SM_sta(all_bsta_headrollang);

% head-torso yaw velocity
[all_bsta_htyawvel_cw_mean, all_bsta_htyawvel_cw_error, ~] = SM_sta(all_bsta_headtorsoyawvel_cw);
[all_bsta_htyawvel_ccw_mean, all_bsta_htyawvel_ccw_error, ~] = SM_sta(all_bsta_headtorsoyawvel_ccw);
[all_bsta_htyawvel_mean, all_bsta_htyawvel_error, ~] = SM_sta(all_bsta_headtorsoyawvel);
% head yaw velocity
[all_bsta_hyawvel_cw_mean, all_bsta_hyawvel_cw_error, ~] = SM_sta(all_bsta_headyawvel_cw);
[all_bsta_hyawvel_ccw_mean, all_bsta_hyawvel_ccw_error, ~] = SM_sta(all_bsta_headyawvel_ccw);
[all_bsta_hyawvel_mean, all_bsta_hyawvel_error, ~] = SM_sta(all_bsta_headyawvel);
% head pitch velocity
[all_bsta_hpitchvel_mean, all_bsta_hpitchvel_error, ~] = SM_sta(all_bsta_headpitchvel);
% head roll velocity
[all_bsta_hrollvel_mean, all_bsta_hrollvel_error, ~] = SM_sta(all_bsta_headrollvel);

%% Display
disp(['Number of animals with head recording: ', str(size(all_bsta_headpitchvel, 2))]);
disp(['Number of animals with head-torso recording: ', str(size(all_bsta_headtorsoyawvel, 2))]);

%% Plot from all animal (Angles)
figure('Name', 'All animals: angles')
set(gcf, 'Position', [50, 50, 560, 830])
% head-torso yaw angle
subplot(4, 1, 1); hold on  
plot(BSTA_X, all_bsta_htyawang_cw_mean, 'Color', rgb(0, 115, 189), 'LineWidth', 1);
plot(BSTA_X, all_bsta_htyawang_cw_error, 'Color', rgb(0, 115, 189), 'LineWidth', 0.5);
plot(BSTA_X, all_bsta_htyawang_ccw_mean, 'Color', rgb(217, 84, 26), 'LineWidth', 1);
plot(BSTA_X, all_bsta_htyawang_ccw_error, 'Color', rgb(217, 84, 26), 'LineWidth', 0.5);
plot(BSTA_X, all_bsta_htyawang_mean, 'Color', rgb(128, 128, 128), 'LineWidth', 1);
plot(BSTA_X, all_bsta_htyawang_error, 'Color', rgb(128, 128, 128), 'LineWidth', 0.5);
yline(0, 'k'); xline(0, 'k--'); title('Head-torso yaw angle');
xlim([-inf, inf]); ylim([-60, 60]); hold off
% head pitch angle
subplot(4, 1, 2); hold on
plot(BSTA_X, all_bsta_hpitchang_mean, 'Color', rgb(0, 128, 0), 'LineWidth', 1);
plot(BSTA_X, all_bsta_hpitchang_error, 'Color', rgb(0, 128, 0), 'LineWidth', 0.5);
xline(0, 'k--'); title('Head pitch angle');
xlim([-inf, inf]); ylim([-90, 90]); hold off
% head roll angl
subplot(4, 1, 3); hold on
plot(BSTA_X, all_bsta_hrollang_mean, 'Color', rgb(128, 128, 128), 'LineWidth', 1);
plot(BSTA_X, all_bsta_hrollang_error, 'Color', rgb(128, 128, 128), 'LineWidth', 0.5);
xline(0, 'k--'); title('Head roll angle');
xlim([-inf, inf]); ylim([-90, 90]); hold off
% breathing
subplot(4, 1, 4); hold on
plot(BSTA_X, all_bsta_breathing_mean, 'Color', rgb(128, 0, 0), 'LineWidth', 1);
plot(BSTA_X, all_bsta_breathing_error, 'Color', rgb(128, 0, 0), 'LineWidth', 0.5);
xline(0, 'k--'); title('Breathing');
xlim([-inf, inf]); hold off


%% Plot from all animal (Velocities)
figure('Name', 'All animals: velocities')
set(gcf, 'Position', [50, 50, 560, 830])
% head-torso yaw velocity
subplot(4, 1, 1); hold on  
plot(BSTA_X, all_bsta_htyawvel_cw_mean, 'Color', rgb(0, 115, 189), 'LineWidth', 1);
plot(BSTA_X, all_bsta_htyawvel_cw_error, 'Color', rgb(0, 115, 189), 'LineWidth', 0.5);
plot(BSTA_X, all_bsta_htyawvel_ccw_mean, 'Color', rgb(217, 84, 26), 'LineWidth', 1);
plot(BSTA_X, all_bsta_htyawvel_ccw_error, 'Color', rgb(217, 84, 26), 'LineWidth', 0.5);
plot(BSTA_X, all_bsta_htyawvel_mean, 'Color', rgb(128, 128, 128), 'LineWidth', 1);
plot(BSTA_X, all_bsta_htyawvel_error, 'Color', rgb(128, 128, 128), 'LineWidth', 0.5);
yline(0, 'k'); xline(0, 'k--'); title('Head-torso yaw velocity');
xlim([-inf, inf]); ylim([-125, 125]); hold off
% head yaw velocity
subplot(4, 1, 2); hold on  
plot(BSTA_X, all_bsta_hyawvel_cw_mean, 'Color', rgb(0, 115, 189), 'LineWidth', 1);
plot(BSTA_X, all_bsta_hyawvel_cw_error, 'Color', rgb(0, 115, 189), 'LineWidth', 0.5);
plot(BSTA_X, all_bsta_hyawvel_ccw_mean, 'Color', rgb(217, 84, 26), 'LineWidth', 1);
plot(BSTA_X, all_bsta_hyawvel_ccw_error, 'Color', rgb(217, 84, 26), 'LineWidth', 0.5);
plot(BSTA_X, all_bsta_hyawvel_mean, 'Color', rgb(128, 128, 128), 'LineWidth', 1);
plot(BSTA_X, all_bsta_hyawvel_error, 'Color', rgb(128, 128, 128), 'LineWidth', 0.5);
yline(0, 'k'); xline(0, 'k--'); title('Head yaw velocity');
xlim([-inf, inf]); ylim([-125, 125]); hold off
% head pitch velocity
subplot(4, 1, 3); hold on
plot(BSTA_X, all_bsta_hpitchvel_mean, 'Color', rgb(0, 128, 0), 'LineWidth', 1);
plot(BSTA_X, all_bsta_hpitchvel_error, 'Color', rgb(0, 128, 0), 'LineWidth', 0.5);
xline(0, 'k--'); title('Head pitch velocity');
xlim([-inf, inf]); ylim([-60, 60]); hold off
% head roll velocity
subplot(4, 1, 4); hold on
plot(BSTA_X, all_bsta_hrollvel_mean, 'Color', rgb(128, 128, 128), 'LineWidth', 1);
plot(BSTA_X, all_bsta_hrollvel_error, 'Color', rgb(128, 128, 128), 'LineWidth', 0.5);
xline(0, 'k--'); title('Head roll velocity');
xlim([-inf, inf]); ylim([-30, 30]); hold off
