%% Figure 6B

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Edit Line #19. Use integer 33 for CW or -33 for CCW.
% 2. Edit Line #35. Edit the path to the "Data" folder.
% 3. Run the code.


clc;
clear;
close all;

base_index = 36;
target_index = 33;  % Edit here. 33: CW | -33: CCW

rasterColor = rgb(130, 130, 130);  % rgb(109, 145, 203);

disp(['base = ' , str(base_index)]);
disp(['target = ' , str(target_index)]);
disp(' ');


%% General parameters
animal_ID = 'SLR087';
rec_type = 'd';

disp([animal_ID, ' - ', rec_type]);
disp(' ');

cd(['..\..\Data\', char(animal_ID)]);  % Edit here

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
PHASE_RASTER_FMIN = 8;  % was 8,  or 4
PHASE_RASTER_FMAX = 14;  % was 14,  or 8
disp('=== Phase Raster Plot ===');
disp(['PHASE_RASTER_FMIN = ', str(PHASE_RASTER_FMIN)]);
disp(['PHASE_RASTER_FMAX = ', str(PHASE_RASTER_FMAX)]);
disp(' ');

%% Time Raster Boundaries
RT = [0.25, 0.2];
preCycles = 3;

%% Plot params
SET_Y_SCALING_FACTOR = true;
y_scale_factor = 1000;

BREATHING_INDECES = [2 36];
EMG_INDECES = (3:6);
MPU_INDECES = [20 27:35];

rate = 2000;

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

%% Load percentiles_36data
load([animal_ID, '_D_percentiles_36data.mat']);
if ~strcmp(animal_ID, percentiles.animal_ID)
    error('[percentiles] animal_ID inconstent');
end
pcts = percentiles.pcts;
    
%% Raster matrices
timeRasterMultiple = [];
timeBaseCounter = 0;
phaseRasterMultiple = [];
phaseBaseCounter = 0;
    
%% Loading recordings
for recordingIndex = recordingListMap(rec_type)
    %% Recording-wise raster matrices
    timeRasterMatrix = [];
    phaseRasterMatrix = [];

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
        bBools('b3') = SM_data_truncate(bBools('b3'), TIME_DELAY_CORRECTION, rate, 'tail');
    end
       
    lowpitchbool = data(:,10) < -16.5;
    highpitchbool = data(:,10) > 43.5;
	
    %% Denote time array
    time = data(:,1);

    %% Allowed booleans
    alwbool = and(lowpitchbool, bBools('b3'));

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
        
        % skip the base cycle that occurs too early in the recording
        % twice the base cycle length prior to start is required
        if b_start < 2*b_length
            continue
        end
        
        % skip the base cycle if it occurs too close to the end of the
        % recording
        if b_end > (length(time) - b_length)
            continue
        end
        
        % time window prior to the start of the base cycle
        if preCycles*b_length < RT(1)*rate
            before_width = preCycles*b_length;
        else
            before_width = RT(1)*rate;
        end
        
        % time window after the end of the base cycle
        if b_length + RT(2) > rate
            after_width = rate - b_length;
        else
            after_width = RT(2)*rate;
        end
        
        % at least 1 target peak must be found in the base cycle
        % skip if no targets peaks are found within the base cycle
        qualify_bool = and(target >= b_start, target < b_end);
        if ~any(qualify_bool)
            continue
        end

        %% *** Time raster matrix ***
        % target peaks that occur during the extended window
        targets_in_raster_bool = and((target >= (b_start - before_width)), (target <= (b_end + after_width)));
        targets_in_raster = target(targets_in_raster_bool);
        
        % update time raster base counts
        timeBaseCounter = timeBaseCounter + 1;
        
        % iterate over target peaks
        for tt = 1 : length(targets_in_raster)
            % timeRasterMatrix(1) = length of the base cycle
            % timeRasterMatrix(2) = base cycle id
            % timeRasterMatrix(3) = time of target peak w.r.s b_start
            % timeRasterMatrix(4) = blank column for later use
            timeRasterMatrix(end+1, :) = [b_length/rate, timeBaseCounter, (targets_in_raster(tt)-b_start)/rate, 0];
        end

        %% *** Phase raster matrix ***
        % criterion of phase rasterplot by the length of base cycle
        if or(b_length < rate/PHASE_RASTER_FMAX, b_length > rate/PHASE_RASTER_FMIN)
            continue
        end
        
        % use targets that occur within the base cycle
        targets_in_raster = target(qualify_bool);
        
        % update phase raster base counts
        phaseBaseCounter = phaseBaseCounter + 1;
        
        % iterate over target peaks
        for tt = 1 : length(targets_in_raster)
            % phaseRasterMatrix(1) = length of the base cycle
            % phaseRasterMatrix(2) = base cycle id
            % phaseRasterMatrix(3) = phase of target peak w.r.s base cycle
            % phaseRasterMatrix(4) = blank column for later use
            phaseRasterMatrix(end+1, :) = [b_length/rate, phaseBaseCounter, (targets_in_raster(tt)-b_start)*360/b_length, 0];
        end

    end
    
    % concatenate raster matrices from multiple recordings
    timeRasterMultiple = [timeRasterMultiple ; timeRasterMatrix];
    phaseRasterMultiple = [phaseRasterMultiple ; phaseRasterMatrix];
end

%% Plot the raster plot from all recordings
timeRaster3 = SM_rasterSortingBaseLength(timeRasterMultiple, 1, 2, 4);
phaseRaster3 = SM_rasterSortingBaseLength(phaseRasterMultiple, 1, 2, 4);

%% Scaling by y_scale_factor
if SET_Y_SCALING_FACTOR
    timeRaster3(:,4) = timeRaster3(:,4)./y_scale_factor;
    phaseRaster3(:,4) = phaseRaster3(:,4)./y_scale_factor;
end

%%
disp(['Counts in time raster plot: ' , str(timeBaseCounter)]);
disp(['Counts in phase raster plot: ' , str(phaseBaseCounter)]);


%% Plot narrower figure
% Time Raster Plot
figure()
set(gcf, 'color', 'w', 'Position',[50, 50, 600, 430]);
scatter(timeRaster3(:,3), timeRaster3(:,4), 3, 'filled', 'MarkerFaceColor', rasterColor, 'MarkerEdgeColor', 'none'); hold on
plot([0, 0], [0, timeRaster3(end,4)], 'r--', timeRaster3(:,1), timeRaster3(:,4), 'k--', 'LineWidth', 2); hold off
xlim([-0.2, 0.6]); xticks((-0.2:0.2:0.6));
ylim([0, max(timeRaster3(:,4))]);
set(gca, 'FontSize', 15); 

% Sniffing Raster Plot
figure()
set(gcf, 'color', 'w', 'Position',[800, 80, 300, 560]);

subplot(2,1,1)
plot(phaseRaster3(:,3), phaseRaster3(:,4), '.', 'MarkerSize', 1, 'Color', rasterColor);
xlim([0, 360]); xticks((0:90:360)); xticklabels({[]});
ylim([0, max(phaseRaster3(:,4))]);
title([num2str(PHASE_RASTER_FMIN), ' - ', num2str(PHASE_RASTER_FMAX), ' Hz']);
axis square; set(gca, 'FontSize', 12);

subplot(2,1,2)
histogram(phaseRaster3(:,3), (0:10:360), 'Normalization', 'Probability', 'FaceColor', rasterColor, 'EdgeColor', 'None');
xlim([0, 360]); xticks((0:90:360)); xticklabels({'0','\pi/2','\pi','3\pi/2','2\pi'});
ylabel({'',''});
axis square; set(gca, 'FontSize', 12); 
