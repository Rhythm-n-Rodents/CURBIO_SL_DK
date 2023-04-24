%% Figure 1J

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Edit Line #58. Edit the path to the "Data" folder.
% 2. Run the code.


clc;
clear;
close all;


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
     

%% 
walldist_edges = (0:0.05:0.5);
walldist_bins = 0.5*(walldist_edges(1:end-1) + walldist_edges(2:end));

ANIMALS_REAR_TIMELENGTH = [];
ANIMALS_FORAGE_TIMELENGTH = [];
ANIMALS_TOTAL_TIMELENGTH = [];


for i = 1 : size(POOLS, 1)
    
    animal_ID = char(POOLS(i, 1));
    rec_type = char(POOLS(i, 2));
    rate = 2000;
    
    disp(' ');
    disp([char(animal_ID), ' - ', rec_type]);
    disp(' ');
    
    %% Change directory
    animal_ID = char(animal_ID);
    cur_folder_path = ['..\..\Data\', animal_ID];  % Edit here
    cd(cur_folder_path)

    %% Load recording list map
    load([animal_ID, '_D_recordingListMap.mat']);
    assert(strcmp(animal_ID, recordingListMap('animal_ID')), '[recordingListMap] animal_ID inconstent');
    
    %% load bBoolsMap
    load([animal_ID, '_D_bBoolsMap.mat']);
    assert(strcmp(animal_ID, bBoolsMap('animal_ID')), '[bBoolsMap] animal_ID inconstent');
    
    %% Load video boundary frames
    load([animal_ID, '_D_videoFrameBoundaries.mat']);
    assert(strcmp(animal_ID, dic_VFBs('animal_ID')), '[dic_VFBs] animal_ID inconstent');
    
    %% Animal-wise variables
    REAR_TIMELENGTH = zeros(length(walldist_bins), 1);
    FORAGE_TIMELENGTH = zeros(length(walldist_bins), 1);
    TOTAL_TIMELENGTH = zeros(length(walldist_bins), 1);
    

    %% Loading every recorded data
    for recordingIndex = recordingListMap(rec_type)
        %% Load data
        loaded_filename = [animal_ID, '_arena_', rec_type, num2str(recordingIndex), '_D_36data'];
        load(loaded_filename);
        SM_checkDataColumnNumber(data, 36);
        
        %% Time shift
        time_shift = 0.0095;
        data = SM_data_time_shift(data, (9:35), time_shift, rate);
        
        %% Denote variables
        time = data(:, 1);
        
        %% Denote booleans
        bBools = bBoolsMap([rec_type, num2str(recordingIndex)]);

        bBools('usable') = SM_data_truncate(bBools('usable'), time_shift, rate, 'tail');

        if strcmp(rec_type, 'd')
            bBools('hbgood') = SM_data_truncate(bBools('hbgood'), time_shift, rate, 'tail');
        end

        lowpitchbool = data(:,10) < -16.5; % -16.5;
        highpitchbool = data(:,10) > 43.5; % 43.5; 
        
        foragebool = and(lowpitchbool, bBools('usable'));
        rearbool = and(highpitchbool, bBools('usable'));
        
        %% to-wall distance
        % read DLC tracking data (torso tracking)
        dlc_excel = readmatrix([animal_ID, '_arena_', rec_type, num2str(recordingIndex), '_D_videoDLC_torso.csv']);
        % video boundaries
        vb = dic_VFBs([rec_type, num2str(recordingIndex)]);
        % only takes the tracking data in the video boundary
        dlc_excel = dlc_excel(vb(1):vb(2), :);
        assert(size(dlc_excel, 1) == vb(2)-vb(1)+1);
        
        % read ellipse params
        ellipse_params = load([animal_ID, '_arena_', rec_type, num2str(recordingIndex), '_D_arena_ellipse_params']);
        ellipse_params = ellipse_params.ellipse_params;
        
        % transforms DLC tracking
        [dlc_x, dlc_y] = SM_ellipse2circle(dlc_excel(:,2), -dlc_excel(:,3), ellipse_params);  % dlc_x.shape = (M, 1)
        
        % DLC is taking at 20 Hz -> lowpass at 4 Hz
        dlc_x = SM_filterAlongColumns(dlc_x, 20, 4, 3, 'low');
        dlc_y = SM_filterAlongColumns(dlc_y, 20, 4, 3, 'low');
        
        % upsampling
        dlc_x = SM_splineAlongColumns_specifiedLength(dlc_x, length(time));
        dlc_y = SM_splineAlongColumns_specifiedLength(dlc_y, length(time));
        
        % distance to the wall
        dlc_r = sqrt(dlc_x.^2 + dlc_y.^2);
        

        %% Probability of rearing
        for wi = 1: length(walldist_edges)-1
            walldist_min = walldist_edges(wi);
            walldist_max = walldist_edges(wi+1);
            wall_boolean = and(dlc_r >= walldist_min, dlc_r < walldist_max);
            
            % update cumulated timing
            REAR_TIMELENGTH(wi) = REAR_TIMELENGTH(wi) + sum(and(wall_boolean, rearbool))/rate;
            FORAGE_TIMELENGTH(wi) = FORAGE_TIMELENGTH(wi) + sum(and(wall_boolean, foragebool))/rate;
            TOTAL_TIMELENGTH(wi) = TOTAL_TIMELENGTH(wi) + sum(wall_boolean)/rate;
        end

        
    end  % end of recording iterations
    
    %% update
    ANIMALS_REAR_TIMELENGTH = [ANIMALS_REAR_TIMELENGTH, REAR_TIMELENGTH];
    ANIMALS_FORAGE_TIMELENGTH = [ANIMALS_FORAGE_TIMELENGTH, FORAGE_TIMELENGTH];
    ANIMALS_TOTAL_TIMELENGTH = [ANIMALS_TOTAL_TIMELENGTH, TOTAL_TIMELENGTH];
    
    
    %% Plot
    figure(1)
    set(gcf, 'Color', 'w', 'Position', [100, 100, 1000, 450], 'DefaultAxesFontSize', 12);
    
    subplot(1,2,1); hold on
    plot(walldist_bins, FORAGE_TIMELENGTH./TOTAL_TIMELENGTH, 'Color', rgb(0, 115, 189));
    ylim([0, 1]); hold off
    title('Foraging');
    xlabel('Radial distance in arena (m)');
    ylabel('Time proportion');
    
    subplot(1,2,2); hold on
    plot(walldist_bins, REAR_TIMELENGTH./TOTAL_TIMELENGTH, 'Color', rgb(217, 84, 26));
    ylim([0, 0.2]); hold off
    title('Rearing');
    xlabel('Radial distance in arena (m)');
    ylabel('Time proportion');
end


%% Linear regression
% size = (n_bins, n_animals)
Y_foraging = ANIMALS_FORAGE_TIMELENGTH./ANIMALS_TOTAL_TIMELENGTH;
Y_rearing = ANIMALS_REAR_TIMELENGTH./ANIMALS_TOTAL_TIMELENGTH;

Xf = [];
Yf = [];

Xr = [];
Yr = [];

% process data
for i = 1 : size(Y_foraging, 1)  % loop over n_bins
    for j = 1 : size(Y_foraging, 2)  % loop over n_animals
        if ~isnan(Y_foraging(i, j))
            Xf = [Xf , walldist_bins(i)];
            Yf = [Yf , Y_foraging(i, j)];
        end
        
        if ~isnan(Y_rearing(i, j))
            Xr = [Xr , walldist_bins(i)];
            Yr = [Yr , Y_rearing(i, j)];
        end
    end
end

% linear regression - foraging
f_fit = fitlm(Xf, Yf)
r_fit = fitlm(Xr, Yr)

% plot - sanity check
figure(10)
set(gcf, 'Color', 'w', 'Position', [100, 100, 1000, 800], 'DefaultAxesFontSize', 12);

subplot(2,2,1); hold on
plot(walldist_bins, Y_foraging, '.', 'Color', rgb(0, 115, 189));
ylim([0, 1]); hold off
title('Foraging');
xlabel('Radial distance in arena (m)');
ylabel('Time proportion');

subplot(2,2,2); hold on
plot(walldist_bins, Y_rearing, '.', 'Color', rgb(217, 84, 26));
ylim([0, 0.2]); hold off
title('Rearing');
xlabel('Radial distance in arena (m)');
ylabel('Time proportion');

subplot(2,2,3); hold on
plot(Xf, Yf, '.', 'Color', rgb(0, 0, 0));
ylim([0, 1]); hold off
title('Foraging');
xlabel('Radial distance in arena (m)');
ylabel('Time proportion');

subplot(2,2,4); hold on
plot(Xr, Yr, '.', 'Color', rgb(0, 0, 0));
ylim([0, 0.2]); hold off
title('Rearing');
xlabel('Radial distance in arena (m)');
ylabel('Time proportion');


%% calculate mean (direct average)
% calculate proportion
ANIMALS_REAR_PROB = ANIMALS_REAR_TIMELENGTH ./ ANIMALS_TOTAL_TIMELENGTH;
ANIMALS_FORAGE_PROB = ANIMALS_FORAGE_TIMELENGTH ./ ANIMALS_TOTAL_TIMELENGTH;

% mean accross all animals
MEAN_ANIMALS_REAR_PROB = mean(ANIMALS_REAR_PROB, 2, "omitnan");
MEAN_ANIMALS_FORAGE_PROB = mean(ANIMALS_FORAGE_PROB, 2, "omitnan");

figure(1)
set(gcf, 'Color', 'w', 'Position', [100, 100, 1000, 450], 'DefaultAxesFontSize', 12);

subplot(1,2,1); hold on
plot(walldist_bins, MEAN_ANIMALS_FORAGE_PROB, 'Color', rgb(0, 0, 0), 'LineWidth', 2);
ylim([0, 1]); hold off
title('Foraging');
xlabel('Radial distance in arena (m)');
ylabel('Time proportion');

subplot(1,2,2); hold on
plot(walldist_bins, MEAN_ANIMALS_REAR_PROB, 'Color', rgb(0, 0, 0), 'LineWidth', 2);
ylim([0, 0.2]); hold off
title('Rearing');
xlabel('Radial distance in arena (m)');
ylabel('Time proportion');
