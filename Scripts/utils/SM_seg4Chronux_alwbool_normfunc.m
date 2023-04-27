%% Inputs
% signal: signal to be segmented
% segmentLength: length of segmentation (unit: frames)
% allowableBoolean: a boolean list with 1 for allowed data and 0 for forbidden data

%% Outputs
% segmentedSignal: segmented signals [signal x trial]

function [segmentedSignal] = SM_seg4Chronux_alwbool_normfunc(signal, segmentLength, alwbool, normTime, devideStd)

    %% Input sanity check
    % normTime must be 'before', 'after', or 'none'
    if and(and(~strcmp(normTime, 'before'), ~strcmp(normTime, 'after')), ~strcmp(normTime, 'none'))
        error('Unspecified normTime occured');
    end
    
    % make sure signal is a column array [n x 1]
	if ~iscolumn(signal)
		if isrow(signal)
			signal = signal';
		else
			error('Input signal is not a column or vector');
		end
	end
	%% make sure allowableBoolean is a column array [n x 1]
	if ~iscolumn(alwbool)
		if isrow(alwbool)
			alwbool = alwbool';
		else
			error('Input allowableBoolean is not a column or vector');
		end
    end
    
    %% normalization
    if strcmp(normTime, 'before')
        if devideStd
        	signal = (signal - mean(signal(alwbool)))./std(signal(alwbool));
        else
            signal = signal - mean(signal(alwbool));
        end
    end
	
    %% start segmenting
    maximum_possible_columns = floor(length(signal)/segmentLength);
    number_column_used = 0;
    
	%% pre-allocation
    segmentedSignal = zeros(segmentLength, maximum_possible_columns);
    
    %% new method (03/22/2022)
    % try to avoid losing usable data
    cur = 1;
    while cur <= length(alwbool)-segmentLength+1
        % not allowed -> move on
        if ~alwbool(cur)
            cur = cur + 1;
            continue
        else
            % check if the whole segment is allowed
            % the indeces of the semgent is (cur:cur+segmentLength-1)
            if all(alwbool(cur : cur+segmentLength-1))
                number_column_used = number_column_used + 1;
                single_segment = signal(cur : (cur+segmentLength-1));
                if strcmp(normTime, 'after')
                    if devideStd
                        single_segment = (single_segment - mean(single_segment))./std(single_segment);
                    else
                        single_segment = single_segment - mean(single_segment);
                    end
                end
                segmentedSignal(:,number_column_used) = single_segment;
                % advance by segmentLength
                cur = cur+segmentLength;
            else
                for j = 0 : (segmentLength-1)
                    if ~alwbool(cur+segmentLength-1-j)
                        cur = cur+segmentLength-j;
                        break
                    end
                end
            end
        end
    end

    
    %% old method (will waste to much data)
%     for i = 1: maximum_possible_columns
%         segmentationIndex = (segmentLength*(i-1)+1:segmentLength*i);
%         segmentationBoolean = alwbool(segmentationIndex);
%         if all(segmentationBoolean) % all true
%             number_column_used = number_column_used + 1;
%             single_segment = signal(segmentationIndex);
%             if strcmp(normTime, 'after')
%                 if devideStd
%                     single_segment = (single_segment - mean(single_segment))./std(single_segment);
%                 else
%                     single_segment = single_segment - mean(single_segment);
%                 end
%             end
%             segmentedSignal(:,number_column_used) = single_segment;
%         end
%     end
    
    %% remove tail of zeros columns
    segmentedSignal = segmentedSignal(:,1:number_column_used);
    