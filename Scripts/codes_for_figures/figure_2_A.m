%% Figure 2A

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Edit Line #26. Edit the path to the "Data" folder.
% 2. Run the code.


clc;
clear;
close all;


%% General parameters
animal_ID = 'SLR087';
muscle_name = 'NONE';
rec_type = 'd';

disp([animal_ID, ' - ', rec_type, ' - ', muscle_name]);
disp(' ');

cur_folder_path = ['..\..\Data\', animal_ID];  % Edit here
cd(cur_folder_path)

% sampling rate
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

%% Load percentiles
load([animal_ID, '_D_percentiles_36data.mat']);
if ~strcmp(animal_ID, percentiles.animal_ID)
    error('[percentiles] animal_ID inconstent');
end
pcts = percentiles.pcts;


%% Iterate over recordings
for recordingIndex = 13
   
    %% Load data
    loaded_filename = [animal_ID, '_arena_', rec_type, num2str(recordingIndex), '_D_36data'];
    load(loaded_filename);
    disp([9, ' - ', loaded_filename]);
    SM_checkDataColumnNumber(data, 36);
    
    %% Shifting
    time_shift = 0.0095;
    data = SM_data_time_shift(data, (9:35), time_shift, rate);
        
    %% Allowed booleans
    bBools = bBoolsMap([rec_type, num2str(recordingIndex)]);
    
    usablebool = SM_data_truncate(bBools('usable'), time_shift, rate, 'tail');
    
    if strcmp(rec_type, 'd')
        b3bool = SM_data_truncate(bBools('b3'), time_shift, rate, 'tail');
    end
    
    %% Data Assignment
    time = data(:,1);
    breathing = data(:,36);
    htvel = data(:,33);
    
    
    %% Spectrogram params
    sg.fMax = 20; 
    sg.movingwin = [5, 0.1];
    sg.T = sg.movingwin(1);
    sg.dT = sg.movingwin(2);
    sg.W = 1;
    sg.TW = sg.T*sg.W;
    sg.K = floor(2*sg.T*sg.W)-1;
    disp([9, 'Spectrogram: TW = ',num2str(sg.TW), '   K = ',num2str(sg.K)]);
    sgparams.tapers = [sg.TW, sg.K];
    sgparams.pad = 1;
    sgparams.Fs = rate;
    sgparams.fpass = [0.1, sg.fMax];
    sgparams.err = [2, 0.05];
    sgparams.trialave = 0;
    
    
    %% Cohgram params
    cg.fMax = 20;
    cg.movingwin = [5, 0.1];
    cg.T = cg.movingwin(1);
    cg.dT = cg.movingwin(2);
    cg.W = 1;
    cg.TW = cg.T*cg.W;
    cg.K = floor(2*cg.T*cg.W)-1;
    disp([9, 'Cohgram: TW = ',num2str(cg.TW), '   K = ',num2str(cg.K)]);
    cgparams.tapers = [cg.TW, cg.K];
    cgparams.pad = 1;
    cgparams.Fs = rate;
    cgparams.fpass = [0.1, cg.fMax];
    cgparams.err = [2, 0.05];
    cgparams.trialave = 0;

    
    %% Figure 2A
    % normalize signal
    norm_breathing = (breathing - mean(breathing))./std(breathing, 0, 1);
    norm_htvel = (htvel - mean(htvel))./std(htvel, 0, 1);

    % calculate spectrogram
    [sg_S_breathing, sg_t, sg_f, ~] = mtspecgramc(norm_breathing, sg.movingwin, sgparams);
    [sg_S_htvel, ~, ~, ~] = mtspecgramc(norm_htvel, sg.movingwin, sgparams);

    sg_S_breathing = SM_processGramMatrix(sg_S_breathing);
    sg_S_htvel = SM_processGramMatrix(sg_S_htvel);
    sg_t = sg_t + time(1);

    % calculate cohgram
    [cg_C, cg_phi, ~, ~, ~, cg_t, cg_f, cg_confC, cg_phistd, cg_Cerr] = cohgramc(norm_htvel, norm_breathing, cg.movingwin, cgparams);
    cg_C = SM_processGramMatrix(cg_C);
    cg_t = cg_t + time(1);

    % plot
    time_lim_1h = [118, 132];

    food_in_videoFrames = [119, 344, 693, 1805, 2354, 2687, 3173];
    food_got_videoFrames = [259, 472, 1715, 2277, 2602, 3114];

    food_in_time = 1 + (food_in_videoFrames-1)./20;
    food_got_time = 1 + (food_got_videoFrames-1)./20;

    figure('Name', 'Figure 2A');
    set(gcf, 'Color', 'w',  'Position', [100, 100, 930, 470], 'DefaultAxesFontSize', 15);
    % head-torso yaw vel
    subplot(3,1,1); hold on
    imagesc(sg_t, sg_f, log10(sg_S_htvel)); set(gca, 'YDir', 'normal');
    xlim(time_lim_1h); %set(gca,'xticklabel',{[]})
    ylim([0, 20]); yticks((0:5:20));  caxis([-4, 0.2]);
    colorbar; colormap jet;
    
    % breathing
    subplot(3,1,2);
    imagesc(sg_t, sg_f, log10(sg_S_breathing)); set(gca, 'YDir', 'normal');
    xlim(time_lim_1h); %set(gca,'xticklabel',{[]})
    ylim([0, 20]); yticks((0:5:20)); caxis([-4, 0.2]);
    colorbar; colormap jet;
    
    % coherence
    subplot(3,1,3);
    imagesc(cg_t, cg_f, cg_C);
    xlim(time_lim_1h); %set(gca,'xticklabel',{[]})
    ylim([0, 20]); yticks((0:5:20)); 
    set(gca, 'YDir', 'normal'); colorbar; caxis([0,1]); colormap jet; 

    % food in/food found
    for i = 1:3
        subplot(3,1,i)
        hold on
        for tt = food_in_time
            if and(tt >= time_lim_1h(1), tt <= time_lim_1h(2))
                plot([tt, tt], [0, 20], 'w', 'LineWidth', 4);
            end
        end
        for tt = food_got_time
            if and(tt >= time_lim_1h(1), tt <= time_lim_1h(2))
                plot([tt, tt], [0, 20], 'k', 'LineWidth', 4);
            end
        end 
        hold off
    end
end
