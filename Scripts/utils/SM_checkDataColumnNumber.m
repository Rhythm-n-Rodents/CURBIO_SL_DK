%% SM_checkDataColumnNumber

function [] = SM_checkDataColumnNumber(data, numCol)
	if length(data(1,:)) ~= numCol
        error(['[Error] Data does not have ', num2str(numCol), ' columns!!']);
        return
    end
end