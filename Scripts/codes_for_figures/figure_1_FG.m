%% Figure 1FG

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Edit Line #61. Edit the path to the "Data" folder.
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
         "SLR124", "h"];

HEAD_PITCH = [];
HEADTORSO_YAW = [];     

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
    if ~strcmp(animal_ID, recordingListMap('animal_ID'))
        error('[recordingListMap] animal_ID inconstent');
    end

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
        
        hyang = data(:,9);
        hpang = data(:,10);
        
        hyvel = data(:,27);
        hpvel = data(:,28);

        if strcmp(rec_type, 'd')
            htyang = data(:, 9) - data(:,18);
            htyang = htyang - mean(htyang(alwbool));
            htyvel = data(:, 33);
        end

        %% concatenate
        HEAD_PITCH = [HEAD_PITCH ; hpang(alwbool)];
        
        if strcmp(rec_type, 'd')
            HEADTORSO_YAW = [HEADTORSO_YAW ; htyang(alwbool)];
        end
    end
end


%% Figure 1F, 1G
figure(100)
set(gcf, 'Position', [50, 50, 400, 200], 'DefaultAxesFontSize', 15);
histogram(HEAD_PITCH, (-90:3:90), 'EdgeColor', 'none', 'FaceColor', rgb(0, 128, 0),'Normalization', 'pdf');
xlim([-90, 90]); xticks((-90:30:90));

figure(101)
set(gcf, 'Position', [50, 50, 400, 200], 'DefaultAxesFontSize', 15);
histogram(HEADTORSO_YAW, (-60:3:60), 'EdgeColor', 'none', 'FaceColor', rgb(255, 140, 0), 'Normalization', 'pdf');
xlim([-60, 60]); xticks((-60:30:60));

% Fitting Head Pitch
edges = (-90:3:90);
y = histcounts(HEAD_PITCH, edges, 'Normalization', 'pdf');
x = 0.5*(edges(1:end-1) + edges(2:end));

% Fitting with 3 Gaussians: y = Gaussian_A + Gaussian_B + Gaussian_C
% p(1): coefficient of Gaussian_A (foraging)
% p(2): coefficient of Gaussian_B (rearing)
% p(3): mean of Gaussian_A
% p(4): mean of Gaussian_B
% p(5): mean of Gaussian_C
% p(6): std of Gaussian_A
% p(7): std of Gaussian_B
% p(8): std of Gaussian_C
fit = @(p, x) p(1)./sqrt(2*pi*p(6)^2).*exp(-(x-p(3)).^2/(2*p(6)^2)) + ...
              p(2)./sqrt(2*pi*p(7)^2).*exp(-(x-p(4)).^2/(2*p(7)^2)) + ...
              (1-p(1)-p(2))./sqrt(2*pi*p(8)^2).*exp(-(x-p(5)).^2/(2*p(8)^2));
loss = @(p) -sum(y.*log(fit(p, x)));
fitparams = fminsearch(loss, [0.7; 0.2; -45; 0; 45; 20; 10; 20]);
disp('Head Pitch: 3 Gaussian fit');
disp(fitparams);
G1 = fitparams(1)./sqrt(2*pi*fitparams(6)^2).*exp(-(x-fitparams(3)).^2/(2*fitparams(6)^2));
G2 = fitparams(2)./sqrt(2*pi*fitparams(7)^2).*exp(-(x-fitparams(4)).^2/(2*fitparams(7)^2));
G3 = (1-fitparams(1)-fitparams(2))./sqrt(2*pi*fitparams(8)^2).*exp(-(x-fitparams(5)).^2/(2*fitparams(8)^2));
figure(100); hold on
plot(x, fit(fitparams, x), 'r', 'LineWidth', 1);
plot(x, G1, 'k--', 'LineWidth', 1);
plot(x, G2, 'k--', 'LineWidth', 1);
plot(x, G3, 'k--', 'LineWidth', 1);
hold off

% R-square of Gaussian fit
% Rsq = 1 - (RSS/TSS)
pitch_RSS = sum((y - fit(fitparams, x)).^2);
pitch_TSS = sum((y - mean(y)).^2);
pitch_Rsq = 1 - pitch_RSS/pitch_TSS;
disp('Pitch R-square:');
pitch_Rsq

% Fitting head-torso yaw angle
edges = (-60:3:60);
y = histcounts(HEADTORSO_YAW, edges, 'Normalization', 'pdf');
x = 0.5*(edges(1:end-1) + edges(2:end));

% fit Gaussian: y = Gaussian(x)
% p(1): mean of Gaussian
% p(2): std of Gaussian
fit = @(p, x) 1./sqrt(2*pi*p(2)^2).*exp(-(x-p(1)).^2/(2*p(2)^2));
loss = @(p) -sum(y.*log(fit(p, x)));
fitparams = fminsearch(loss, [0 ; 30]);
disp('Head-Torso Yaw: Gaussian fit');
disp(fitparams);
figure(101); hold on
plot(x, fit(fitparams, x), 'r', 'LineWidth', 1);
xline(0, '--');

% R-square of Gaussian fit
% Rsq = 1 - (RSS/TSS)
yaw_RSS = sum((y - fit(fitparams, x)).^2);
yaw_TSS = sum((y - mean(y)).^2);
yaw_Rsq = 1 - yaw_RSS/yaw_TSS;
disp('Yaw R-square:');
yaw_Rsq