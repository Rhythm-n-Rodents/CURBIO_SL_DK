function [whiskparamfilt] = util_lowpass(whiskparam,Fswhisk, high_cut,filter_order)

% filter whisking parameter signal (whiskparam, Fswhisk,
% high_cut,filter_order)


% order 3 lowpass digital Butterworth filter with normalized cutoff
% frequency high_cut/(Fswhisk/2).

[b, a] = butter(filter_order,high_cut/(Fswhisk/2));

whiskparamfilt = filtfilt(b,a,whiskparam);
