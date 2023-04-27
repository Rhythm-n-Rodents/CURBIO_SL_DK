function [new_vector] = SM_replaceVectorWithNaNatBoolean0(old_vector, alwboolean)
	
	% given a vector (old_vector) and a boolean (alwboolean), for every false index in alwboolean, replace the data to NaN in old_vector
	
	% dimension check
	if ~iscolumn(old_vector)
		if isrow(old_vector)
			old_vector = old_vector';
		else
			error('[Error] input vector is not a column');
		end
	end
	
	% length(old_vector) should equal length(alwboolean)
	if length(alwboolean) ~= length(old_vector)
		error('[Error] input boolean has a different length as the input vector');
	end
	
	% replacement
	new_vector = old_vector;
	new_vector(~alwboolean) = NaN;
