
function [data_shifted] = SM_data_time_shift(data, shift_indeces, time_shift, rate)

    arguments
        data (:, :)
        shift_indeces (1, :)
        time_shift (1, 1)
        rate (1, 1)
    end
    
  
        
    if time_shift == 0
        data_shifted = data;
    
    else
        shifted_frames = round(rate * time_shift);
        data_shifted = data(1:end-shifted_frames, :);
        % shift data
        for i = shift_indeces
            data_shifted(:, i) = data(shifted_frames+1:end, i);
        end
    end
    
end