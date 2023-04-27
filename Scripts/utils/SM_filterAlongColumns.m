%% 04/29/2020

function [filtMatrix] = SM_filterAlongColumns(matrix, fsample, fcut, filter_order, HIGH_LOW_BAND)
    
    filtMatrix = zeros(size(matrix));
    
    %% Compare strings (case insensitive)
    % high-pass
    if strcmpi(HIGH_LOW_BAND, 'high')
        
        if length(fcut) ~= 1
            error('fcut dimension incorrect');
        elseif length(filter_order) ~= 1
            error('filter_order dimension incorrect');
        end
            
        for row_i = 1: size(matrix, 2)
            filtMatrix(:,row_i) = util_hipass(matrix(:,row_i), fsample, fcut, filter_order);
        end
        
    % low-pass
    elseif strcmpi(HIGH_LOW_BAND, 'low')
        
        if length(fcut) ~= 1
            error('fcut dimension incorrect');
        elseif length(filter_order) ~= 1
            error('filter_order dimension incorrect');
        end
        
        for row_i = 1: size(matrix, 2)
            filtMatrix(:,row_i) = util_lowpass(matrix(:,row_i), fsample, fcut, filter_order);
        end
    
    % band-pass
    elseif strcmpi(HIGH_LOW_BAND, 'band')
        
        if length(fcut) ~= 2
            error('fcut dimension incorrect');
        elseif length(filter_order) ~= 2
            error('filter_order dimension incorrect');
        end
        
        for row_i = 1: size(matrix, 2)
            temp = util_hipass(matrix(:,row_i), fsample, fcut(1), filter_order(1));
            filtMatrix(:,row_i) = util_lowpass(temp, fsample, fcut(2), filter_order(2));
        end
        
    else
        error('HIGH_LOW_BAND');
    end
    