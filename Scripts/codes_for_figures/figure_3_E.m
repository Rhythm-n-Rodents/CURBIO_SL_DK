%% Figure 3E

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Edit Line #121. Edit the path to the "Data" folder.
% 2. Uncomment one of the SUBJECT declarations (Lines #21 - #25).
% 3. Run the code.


clc;
clear;
close all;


%% Subject (Uncomment one of the five SUBJECT decalrations below)

%SUBJECT = ["SLR114", "h", "SM", 36, 4];  % uncomment for sternomastoid (SM)
%SUBJECT = ["SLR124", "h", "CM", 36, 3];  % uncomment for cleidomastoid (CM)
%SUBJECT = ["SLR123", "h", "CT", 36, 4];  % uncomment for clavotrapezius (CT)
%SUBJECT = ["SLR124", "h", "SP", 36, 4];  % uncomment for splenius (SP)
%SUBJECT = ["SLR124", "h", "BC", 36, 5];  % uncomment for biventer cervicis (BC)


switch SUBJECT(3)
    case "SM"
        rasterColor = rgb(61, 133, 198);
    case "CM"
        rasterColor = rgb(103, 78, 167);
    case "CT"
        rasterColor = rgb(166, 77, 121);
    case "SP"
        rasterColor = rgb(34, 139, 34);
    case "BC"
        rasterColor = rgb(107, 142, 35);
    otherwise
        error('Wrong muscle');
end


%% General parameters
animal_ID = char(SUBJECT(1));
rec_type = char(SUBJECT(2));

base_index = str2double(SUBJECT(4));
target_index = str2double(SUBJECT(5));

disp(['base = ' , str(base_index)]);
disp(['target = ' , str(target_index)]);
disp(' ');

disp([animal_ID, ' - ', rec_type]);
disp(' ');

rate = 2000;


%% Base Frequency (time rasterplot)
SET_BASE_FMIN = true;
BASE_FMIN = 1;
SET_BASE_FMAX = true;
BASE_FMAX = 14;
disp('=== Time Raster Plot ===');
if SET_BASE_FMIN
    disp(['BASE_FMIN = ', str(BASE_FMIN)]);
else
    disp('BASE_FMIN = NONE');
end
if SET_BASE_FMAX
    disp(['BASE_FMAX = ', str(BASE_FMAX)]);
else
    disp('BASE_FMAX = NONE');
end
disp(' ');


%% Base Frequency (phase rasterplot)
PHASE_RASTER_FMIN = 4;
PHASE_RASTER_FMAX = 14;
disp('=== Phase Raster Plot ===');
disp(['PHASE_RASTER_FMIN = ', str(PHASE_RASTER_FMIN)]);
disp(['PHASE_RASTER_FMAX = ', str(PHASE_RASTER_FMAX)]);
disp(' ');


%% Plot params
BREATHING_INDECES = [2 36];
EMG_INDECES = (3:6);
MPU_INDECES = [20 27:35];

%% BSTA params
BSTA_preWT = 0.1; % in seconds
BSTA_postWT = 0.2; % in seconds

BSTA_preWF = BSTA_preWT*rate;  % in frames
BSTA_postWF = BSTA_postWT*rate;  % in frames

BSTA_time = (-BSTA_preWT : 1/rate : BSTA_postWT);


%% Head pitch binning
headpitch_edges = (-60:10:60);
headpitch_bins = (headpitch_edges(1:end-1) + headpitch_edges(2:end))/2;


%% Count number of breaths
N_COUNTS_REAR = 0;
N_COUNTS_FORAGE = 0;
N_COUNTS_BETWEEN = 0;


%% Select different boolean types
for bin_idx = 1 : length(headpitch_bins)
    
    disp(['Head Pitch: ', str(headpitch_edges(bin_idx)), ' to ', str(headpitch_edges(bin_idx+1))]);
    
    %% Switch directory
    cd(['..\..\Data\', char(animal_ID)]);  % Edit here
    
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

    
    %% BSTA segments
    bsta_segs_muscle = [];
    bsta_segs_breathing = [];

    
    %% Loading recordings
    for recordingIndex = recordingListMap(rec_type)
        
        %% Load data
        loaded_filename = [animal_ID, '_arena_', rec_type, num2str(recordingIndex), '_D_36data'];
        load(loaded_filename);
        disp([' - ', loaded_filename]);
        SM_checkDataColumnNumber(data, 36);

        %% Time delay correction
        TIME_DELAY_CORRECTION = 0.0095;
        data = SM_data_time_shift(data, (9:35), TIME_DELAY_CORRECTION, rate);

        %% Allowed booleans
        bBools = bBoolsMap([rec_type, num2str(recordingIndex)]);
        % correct booleans to match time shift
        bBools('usable') = SM_data_truncate(bBools('usable'), TIME_DELAY_CORRECTION, rate, 'tail');

        if strcmp(rec_type, 'd')
            bBools('hbgood') = SM_data_truncate(bBools('hbgood'), TIME_DELAY_CORRECTION, rate, 'tail');
        end

        %% Denote time array
        breathing = data(:, 36);
        hpitch = data(:, 10);

        %% Allowed booleans
        hpitch_bool = and(hpitch >= headpitch_edges(bin_idx), hpitch < headpitch_edges(bin_idx+1));
        alwbool = and(hpitch_bool, bBools('usable'));

        %% Base signal processing
        % breathing
        if ismember(abs(base_index), BREATHING_INDECES)
            base_data = sign(base_index)*data(:,abs(base_index));
            [base_peaks, base_valleys] = sniffutil_getrespinflections_findpeaks(base_data);
            base = sniffutil_getxpct_risetimes(base_data, base_peaks, base_valleys, 10);

        % bno signals
        elseif ismember(abs(base_index), MPU_INDECES)
            base_pcts = pcts([rec_type, '_', str(base_index)]);
            % base signal (flip sign if needed)
            base_data = sign(base_index)*data(:,abs(base_index));
            [~, base] = matlab_findpeaks(base_data, 'MinPeakHeight', base_pcts('90'), 'MinPeakProminence', 0.5*base_pcts('std'));
        else
            error('[Base] new vars encountered.');
        end

        baseLengths = base(2:end) - base(1:end-1);
        base = base(1:end-1);

        if SET_BASE_FMAX
            base_fmax_boolean = (baseLengths >= rate/BASE_FMAX);
            base = base(base_fmax_boolean);
            baseLengths = baseLengths(base_fmax_boolean);
        end
        if SET_BASE_FMIN
            base_fmin_boolean = (baseLengths <= rate/BASE_FMIN);
            base = base(base_fmin_boolean);
            baseLengths = baseLengths(base_fmin_boolean);
        end 
        [base, baseLengths] = SM_breathingBevConstraint(base, baseLengths, alwbool);
        

        %% Target signal processing
        % breathing
        if ismember(target_index, BREATHING_INDECES)
            target_data = data(:, target_index);
            [target_peaks, target_valleys] = sniffutil_getrespinflections_findpeaks(target_data);
            target = sniffutil_getxpct_risetimes(target_data, target_peaks, target_valleys, 10);
            
        % EMGs
        elseif ismember(target_index, EMG_INDECES)
            target_pcts = pcts([rec_type, '_', str(target_index)]);
            target_data = data(:, target_index);
            [~, target] = matlab_findpeaks(target_data, 'MinPeakHeight', target_pcts('90'), 'MinPeakProminence', 0.5*target_pcts('std'));
            target = target(target_data(target) < target_pcts('99.99'));
            target = target(alwbool(target));

        % bno signals
        elseif ismember(abs(target_index), MPU_INDECES)
            target_pcts = pcts([rec_type, '_', str(target_index)]);
            target_data = sign(target_index)*data(:, abs(target_index));
            [~, target] = matlab_findpeaks(target_data, 'MinPeakHeight', target_pcts('90'), 'MinPeakProminence', 0.5*target_pcts('std'));
            target = target(alwbool(target));
        else
            error('[target] new vars encountered');
        end

        % skip if not peaks found in either base or target
        if or(isempty(base), isempty(target))
            continue
        end

        %% *************** Raster Program *********************** %%
        % iterate over base peaks
        for bb = 1 : length(base)

            % start of the base cycle
            b_start = base(bb);
            % length of the base cycle
            b_length = baseLengths(bb);
            % end of the base cycle
            b_end = b_start + b_length;

            assert(all(alwbool(b_start:b_end)));

            % at least 1 target peak must be found in the base cycle
            % skip if no targets peaks are found within the base cycle
            qualify_bool = and(target >= b_start, target < b_end);
            if ~any(qualify_bool)
                continue
            end
            
            %% BSTA
            if and(b_start-BSTA_preWF>0, b_start+BSTA_postWF<=length(breathing))
                bsta_segs_muscle = [bsta_segs_muscle, target_data(b_start-BSTA_preWF : b_start+BSTA_postWF)];
                bsta_segs_breathing = [bsta_segs_breathing, breathing(b_start-BSTA_preWF : b_start+BSTA_postWF)];
            end
            
            %% Count
            avg_hpitch_of_sniff = mean(hpitch(b_start:b_end));
            
            % rear
            if avg_hpitch_of_sniff > 43.5
                N_COUNTS_REAR = N_COUNTS_REAR + 1;
            % forage
            elseif avg_hpitch_of_sniff < -16.5
                N_COUNTS_FORAGE = N_COUNTS_FORAGE + 1;
            % between
            else
                N_COUNTS_BETWEEN = N_COUNTS_BETWEEN + 1;
            end
        end
    end
    
    disp(['Number of segs: ', str(size(bsta_segs_muscle, 2))]);
    disp(' ');
    
    
    %% BSTA
    figure(1)
    
    set(gcf, 'Color', 'w', 'Position', [100, 100, 550, 900], 'DefaultAxesFontSize', 15);

    subplot(12,2,26-2*bin_idx-1); hold on
    [sta_mean, sta_error, ~] = SM_sta(bsta_segs_muscle.*2500);  % uV
    plot(BSTA_time, sta_mean, 'LineWidth', 1, 'Color', rasterColor);
    plot(BSTA_time, sta_error, 'LineWidth', 0.5, 'Color', rasterColor);
    xline(0, 'k-', 'LineWidth', 1); xlim([-inf, inf]); hold off
    if bin_idx ~= 1
        set(gca,'xticklabel',{[]});
    end
    
    clear sta_mean sta_error sta_n
    
    subplot(12,2,26-2*bin_idx); hold on
    [sta_mean, sta_error, ~] = SM_sta(bsta_segs_breathing);
    plot(BSTA_time, sta_mean, 'LineWidth', 1, 'Color', rgb(128,0,0));
    plot(BSTA_time, sta_error, 'LineWidth', 0.5, 'Color', rgb(128,0,0));
    xline(0, 'k-', 'LineWidth', 1); xlim([-inf, inf]); hold off
    clear sta_mean sta_error sta_n
    
    if bin_idx ~= 1
        set(gca,'xticklabel',{[]});
    end

   
end

N_COUNTS_FORAGE

N_COUNTS_BETWEEN

N_COUNTS_REAR
