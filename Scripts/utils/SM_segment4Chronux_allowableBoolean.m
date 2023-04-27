%% Inputs
% signal: signal to be segmented
% segmentLength: length of segmentation (unit: frames)
% allowableBoolean: a boolean list with 1 for allowed data and 0 for forbidden data

%% Outputs
% segmentedSignal: segmented signals [signal x trial]

function [segmentedSignal] = SM_segment4Chronux_allowableBoolean(signal, segmentLength, allowableBoolean)

    %% make sure signal is a column array [n x 1]
	if ~iscolumn(signal)
		if isrow(signal)
			signal = signal';
		else
			error('[Error] input signal is not a column or vector');
		end
	end
	
	%% make sure allowableBoolean is a column array [n x 1]
	if ~iscolumn(allowableBoolean)
		if isrow(allowableBoolean)
			allowableBoolean = allowableBoolean';
		else
			error('[Error] input allowableBoolean is not a column or vector');
		end
	end
	
    %% start segmenting
    maximum_possible_columns = floor(length(signal)/segmentLength);
    number_column_used = 0;
    
	%% pre-allocation
    segmentedSignal = zeros(segmentLength, maximum_possible_columns);
    
    for i = 1: maximum_possible_columns
        segmentationIndex = (segmentLength*(i-1)+1:segmentLength*i);
        segmentationBoolean = allowableBoolean(segmentationIndex);
        if all(segmentationBoolean) % all true
            number_column_used = number_column_used + 1;
            segmentedSignal(:,number_column_used) = signal(segmentationIndex);
        end
    end
    
    %% remove tail of zeros columns
    segmentedSignal = segmentedSignal(:,1:number_column_used);