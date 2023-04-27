%%  04/23/2020

function [validBreathOnsets, validBreathLengths] = SM_breathingBevConstraint(breathOnsets, breathLengths, allowedBoolean)
    % verify inputs
    if length(breathOnsets) ~= length(breathLengths)
        disp('Input lengths not the same');return
    end
    
    if ~iscolumn(breathOnsets)
        if isrow(breathOnsets)
            breathOnsets = breathOnsets';
        else
            disp('Input breath onsets has wrong dimension');return
        end
    end
    
    if ~iscolumn(breathLengths)
        if isrow(breathLengths)
            breathLengths = breathLengths';
        else
            disp('Input breath lengths has wrong dimension');return
        end
    end
    	
	validBreathBool = false(length(breathOnsets),1);
	
    for bo = 1: length(breathOnsets)
        if all(allowedBoolean(breathOnsets(bo):(breathOnsets(bo) + breathLengths(bo)))) % whole breath is allowed
			validBreathBool(bo) = true;
        end
    end
	
	validBreathOnsets = breathOnsets(validBreathBool);
	validBreathLengths = breathLengths(validBreathBool);
    
    if length(validBreathOnsets) ~= length(validBreathLengths)
        error('error');
    end
