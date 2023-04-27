%%
% given indeces of target_peaks, indeces of cob_peaks, and lengths of cob
% cycles. For each target peak, return the simultaneous cob phase (0-360)




function [target_phase_in_cob] = SM_target_phaseInCob(target_peak_indeces, cob_peak_indeces, cob_lengths)
	
    N_target = length(target_peak_indeces);
    N_cob = length(cob_peak_indeces);
    N_cob_L = length(cob_lengths);
    
    % sanity check
    if N_cob ~= N_cob_L
        error('cob_peak_indeces and cob_lengths are not with the same size');
    elseif N_target == 0
        error('no target peaks');
    elseif N_cob == 0
        error('no cob peaks');
    end
    
    target_phase_in_cob = NaN(size(target_peak_indeces));
    
    search_start_cob_index = 1;
    
    for i = 1 : N_target
        target = target_peak_indeces(i);
        for j = search_start_cob_index : N_cob
            cob = cob_peak_indeces(j);
            cob_L = cob_lengths(j);
            if and( cob <= target , target < cob + cob_L)
                target_phase = 360*(target - cob)/cob_L;
                target_phase_in_cob(i) = target_phase;
                search_start_cob_index = j;
                break
            end
        end
    end
    
    