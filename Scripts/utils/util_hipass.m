function [whiskparamfilt] = util_hipass(whiskparam,Fswhisk, high_cut,filter_order)

% filter whisking parameter signal (whiskparam, Fswhisk,
% high_cut,filter_order)


% order 3 lowpass digital Butterworth filter with normalized cutoff
% frequency high_cut/(Fswhisk/2).

[b, a] = butter(filter_order,high_cut/(Fswhisk/2),'high');
whiskparamfilt = filtfilt(b,a,whiskparam);
