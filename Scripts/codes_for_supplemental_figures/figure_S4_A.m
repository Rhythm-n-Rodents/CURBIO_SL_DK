%% Figure S4A

% Liao & Kleinfeld (2023) A change in behavioral state switches the
% pattern of motor output that underlies rhythmic head and orofacial
% movements


%% To run the code
% 1. Run the code.


clear
clc
close all


% intrinsic freq of neck
wn = 9.5;  

% Range of k (0.5 * coupling strength)
K = (1.5 : 0.005 : 1.65);

ALPHA = [];
who_leads = 'rearing';  % foraging or rearing


for k = K
    % solve for tau (x)
    syms x
    if strcmp(who_leads, 'foraging')
        % time delay
        sol = double(vpasolve(asin((wn - 11)/k) - 11*x*2*pi - asin((wn - 8)/k) + 8*x*2*pi == pi, x, [0.001, 0.1]));
        
    elseif strcmp(who_leads, 'rearing')
        % time delay
        sol = double(vpasolve(asin((wn - 11)/k) - 11*x*2*pi - asin((wn - 8)/k) + 8*x*2*pi == -pi, x, [0.001, 0.1]));
    end

    % time delay
    if isempty(sol)
        ALPHA = [ALPHA, NaN];
    else
        ALPHA = [ALPHA, sol];
    end
end

figure(100)
set(gcf, 'Position', [100, 100, 560, 250], 'Color', 'w')
plot(K, ALPHA); xlabel('0.5 x Coupling strength (Hz)'); ylabel('Time delay (s)');
xlim([K(1), K(end)]); ylim([0, 0.05]); title('Neck model');
