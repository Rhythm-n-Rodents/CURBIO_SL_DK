%% 04/20/2020

%% Note: vq = interp1(x,v,xq,method)

function [matrix_spc] = SM_splineAlongColumns_specifiedLength(matrix, newLength)

    oldLength = size(matrix, 1);

    x = [0 : 1/(oldLength-1): 1];
    xq = [0 : 1/(newLength-1): 1];
    
    matrix_spc = [];
    for i = 1:length(matrix(1,:))
        vi = matrix(:,i)';
        matrix_spc = [matrix_spc interp1(x, vi, xq, 'spline')'];
    end
    
end
