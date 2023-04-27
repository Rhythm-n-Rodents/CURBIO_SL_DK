function [sortedMatrix] = SM_rasterSortingBaseLength(rasterMatrix, baseLengthColumnIndex, baseIndexColumnIndex, rasterEmptyColumnIndex)

	% baseLengthColumnIndex: the column index of base lengths
	% baseIndexColumnIndex: the column index of base index (different base cycle has differnt base index)
	% rasterEmptyColumnIndex: starting from the shorted base (0) to the longest base (N), will be the y-coordinate of the final raster plot

	sortedMatrix = sortrows(rasterMatrix, baseLengthColumnIndex, 'descend');
    for i = 2 : length(sortedMatrix(:,baseLengthColumnIndex))
        if sortedMatrix(i,baseIndexColumnIndex) == sortedMatrix(i-1,baseIndexColumnIndex)
            sortedMatrix(i,rasterEmptyColumnIndex) = sortedMatrix(i-1,rasterEmptyColumnIndex);
        else
            sortedMatrix(i,rasterEmptyColumnIndex) = sortedMatrix(i-1,rasterEmptyColumnIndex) + 1;
        end
    end