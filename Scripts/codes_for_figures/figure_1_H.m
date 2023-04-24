%% Figure 1H

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Edit Line #67. Edit the path to the "Data" folder.
% 2. Run the code.


clc;
clear;
close all;


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
         "SLR115", "h"; ...
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
     
BREATHING_F_Forage = [];
BREATHING_F_Rear = [];

for i = 1 : size(POOLS, 1)
    
    animal_ID = char(POOLS(i, 1));
    rec_type = char(POOLS(i, 2));
    rate = 2000;
    
    disp(' ');
    disp([char(animal_ID), ' - ', rec_type]);
    disp(' ');
    
    %% Change directory
    animal_ID = char(animal_ID);
    cur_folder_path = ['../../Data/', animal_ID];  % Edit here
    cd(cur_folder_path)

    %% Load recording list map
    load([animal_ID, '_D_recordingListMap.mat']);
    assert(strcmp(animal_ID, recordingListMap('animal_ID')), '[recordingListMap] animal_ID inconstent');

    %% Load bBoolsMap
    load([animal_ID, '_D_bBoolsMap.mat']);
    if ~strcmp(animal_ID, bBoolsMap('animal_ID'))
        error('[bBoolsMap] animal_ID inconstent');
    end

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
        if strcmp(rec_type, 'd')
            bBools('b3') = SM_data_truncate(bBools('b3'), time_shift, rate, 'tail');
            alwbool = bBools('b3');
        elseif strcmp(rec_type, 'h')
            bBools('usable') = SM_data_truncate(bBools('usable'), time_shift, rate, 'tail');
            alwbool = bBools('usable');
        end

        %% Denote data
        time = data(:,1);
        breathing = data(:,36);
        hpang = data(:,10);
        
        %% breathing
        [breathing_peaks, breathing_valleys] = sniffutil_getrespinflections_findpeaks(breathing);
        breathing_onsets = sniffutil_getxpct_risetimes(breathing, breathing_peaks, breathing_valleys, 10);
        breathing_lengths = diff(breathing_onsets);
        breathing_onsets = breathing_onsets(1:end-1);
        
        [~, baseLengths_forage] = SM_breathingBevConstraint(breathing_onsets, breathing_lengths, and(alwbool, hpang<-16.5));
        [~, baseLengths_rear] = SM_breathingBevConstraint(breathing_onsets, breathing_lengths, and(alwbool, hpang>43.5));
        
        BREATHING_F_Forage = [BREATHING_F_Forage ; rate./baseLengths_forage];
        BREATHING_F_Rear = [BREATHING_F_Rear ; rate./baseLengths_rear];
    end
end

%% Plot breathing frequency histogram
BR_EDGES = (0:0.25:20);
BR_BINS = 0.5*(BR_EDGES(1:end-1)+BR_EDGES(2:end));
figure(1)
set(gcf, 'Color', 'w', 'Position', [50, 50, 400, 550], 'DefaultAxesFontSize', 15);
histogram(BREATHING_F_Forage, BR_EDGES, 'EdgeColor', 'none', 'FaceColor', rgb(0, 115, 189),'Normalization', 'pdf'); hold on
histogram(BREATHING_F_Rear, BR_EDGES, 'EdgeColor', 'none', 'FaceColor', rgb(217, 84, 26),'Normalization', 'pdf'); hold off
axis square
xlim([0, 20])

[h, p] = kstest2(BREATHING_F_Forage, BREATHING_F_Rear)


%% Fitting rearing
x = BR_BINS;

y_rearing = histcounts(BREATHING_F_Rear, BR_EDGES, 'Normalization', 'pdf');

% Fit one Gaussian: y = Gaussian(x)
% p(1): mean of Gaussian
% p(2): std of Gaussian
fit = @(p, x) 1./sqrt(2*pi*p(2)^2).*exp(-(x-p(1)).^2/(2*p(2)^2));
loss = @(p) -sum(y_rearing.*log(fit(p, x)));
fitparams = fminsearch(loss, [8 ; 1]);
disp('Forage: Gaussian fit');
disp(fitparams);

hold on
plot(x, fit(fitparams, x), 'r', 'LineWidth', 1);
hold off


%% Fitting foraging with 2 Gaussians
x = BR_BINS;

y_foraging = histcounts(BREATHING_F_Forage, BR_EDGES, 'Normalization', 'pdf');

% Fit one Gaussian: y = Gaussian_1(x) +  Gaussian_2(x)
% p(1): mean of Gaussian 1 
% p(2): std of Gaussian 1
% p(3): mean of Gaussian 2 
% p(4): std of Gaussian 2
% p(5): proportion of Gaissian 1

fit = @(p, x) p(5)./sqrt(2*pi*p(2)^2).*exp(-(x-p(1)).^2/(2*p(2)^2)) + (1-p(5))./sqrt(2*pi*p(4)^2).*exp(-(x-p(3)).^2/(2*p(4)^2));
loss = @(p) -sum(y_foraging.*log(fit(p, x)));
fitparams = fminsearch(loss, [11 ; 1; 4; 1; 0.95]);
disp('Forage: Gaussian fit');
disp(fitparams);

hold on
plot(x, fit(fitparams, x), 'b', 'LineWidth', 1);
hold off