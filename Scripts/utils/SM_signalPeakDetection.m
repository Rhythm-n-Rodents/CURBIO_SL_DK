%% Signal peak detection

% 09/13/2020

%{ 
Given a signal, this function finds the peaks by the matlab built-in
function "matlab_findpeaks", which needs 2 params 'MinPeakHeight' and 'MinPeakProminence'

%}


function [peaks, lengths] = SM_signalPeakDetection(signal, rate, alwbool, min_peak_height, min_peak_prominence, set_fmax, set_fmin, fmax, fmin)

    arguments
        signal (:, 1)
        rate (1, 1)
        alwbool (:, 1)
        min_peak_height (1, 1)
        min_peak_prominence (1, 1)
        set_fmax logical = false
        set_fmin logical = false
        fmax (1,1) = NaN
        fmin (1,1) = NaN
        
    end
    
    [~, peaks] = matlab_findpeaks(signal, 'MinPeakHeight', min_peak_height, 'MinPeakProminence', min_peak_prominence);
    
    lengths = peaks(2:end) - peaks(1:end-1);
    
    peaks = peaks(1:end-1);
    
    if set_fmax
        fmax_boolean = (lengths >= rate/fmax);
        peaks = peaks(fmax_boolean);
        lengths = lengths(fmax_boolean);
        clear fmax_boolean
    end
    
    if set_fmin
        fmin_boolean = (lengths <= rate/fmin);
        peaks = peaks(fmin_boolean);
        lengths = lengths(fmin_boolean);
        clear fmin_boolean
    end
    
    [peaks, lengths] = SM_breathingBevConstraint(peaks, lengths, alwbool);
    
end