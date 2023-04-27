%% Breathing signal processing


function [final_onsets, final_lengths, final_postinsp] = SM_breathing_processing(data, rate, alwbool, set_fmax, set_fmin, fmax, fmin)

    arguments
        data (:, 1)
        rate (1, 1)
        alwbool (:, 1)
        set_fmax logical = false
        set_fmin logical = false
        fmax (1,1) = NaN
        fmin (1,1) = NaN
    end
    
    
    [peaks, valleys] = sniffutil_getrespinflections_findpeaks(data);
    
    onsets = sniffutil_getxpct_risetimes(data, peaks, valleys, 10);
    
    lengths = onsets(2:end) - onsets(1:end-1);
    
    onsets = onsets(1:end-1);
    postinsp = peaks(1:end-1);
    clear breathing_peaks breathing_valleys
    
    if length(onsets) ~= length(postinsp)
        error('checkpoint #1 is not passed');
    end
    
    if set_fmax
        fmax_boolean = (lengths >= rate/fmax);
        onsets = onsets(fmax_boolean);
        lengths = lengths(fmax_boolean);
        postinsp = postinsp(fmax_boolean);
        clear fmax_boolean
    end
    
    if set_fmin
        fmin_boolean = (lengths <= rate/fmin);
        onsets = onsets(fmin_boolean);
        lengths = lengths(fmin_boolean);
        postinsp = postinsp(fmin_boolean);
        clear fmin_boolean
    end
    
    % apply allowed boolean (alwbool)
    [final_onsets, final_lengths] = SM_breathingBevConstraint(onsets, lengths, alwbool);
    
    % 
    final_postinsp = 0;
end