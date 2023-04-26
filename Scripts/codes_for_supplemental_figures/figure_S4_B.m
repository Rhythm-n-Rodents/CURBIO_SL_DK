%% Figure S4B

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Run the code.


clear
clc
close all


% intrinsic freq of nose
wn = 9.5;  

% Range of k (coupling strength)
K = (0.01 : 0.01 : 2.80);

ALPHA = [];
who_leads = 'rearing';  % foraging or rearing


for k = K
    % solve for tau (x)
    syms x
    if strcmp(who_leads, 'foraging')
        sol = double(vpasolve(-asin((wn - 8)/k) + 8*x*2*pi + asin((wn - 11)/k) - 11*x*2*pi == 0.648*pi, x, [0.001, 0.1]));
    elseif strcmp(who_leads, 'rearing')
        sol = double(vpasolve(asin((wn - 8)/k) - 8*x*2*pi - asin((wn - 11)/k) + 11*x*2*pi == 0.648*pi, x, [0.001, 0.1]));
    end
    
    if isempty(sol)
        ALPHA = [ALPHA, NaN];
    else
        ALPHA = [ALPHA, sol];
    end
end

figure(100)
set(gcf, 'Position', [100, 100, 560, 250])
plot(K, ALPHA); xlabel('Coupling strength (Hz)'); ylabel('Time delay (s)');
xlim([1.6, 2.8]); ylim([0, 0.05]); title('Nose model');
