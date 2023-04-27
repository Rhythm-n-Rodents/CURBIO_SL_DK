%% 04/08/2020

function [sta_mean, sta_error, sta_n] = SM_sta(data)

	% calculate mean
	sta_mean = mean(data, 2);
	
	% calculate std
	sta_std = std(data, 0, 2);
	
	% calculate N
	sta_n = size(data, 2);
	
	% calculate lower error
	sta_low_error = sta_mean - 2*sta_std/sqrt(sta_n);
	
	% calculate upper error
	sta_up_error = sta_mean + 2*sta_std/sqrt(sta_n);
	
	sta_error = [sta_low_error sta_up_error];