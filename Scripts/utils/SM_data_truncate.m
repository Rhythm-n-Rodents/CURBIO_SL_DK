
function [data_truncated] = SM_data_truncate(data, time_shift, rate, head_tail)

    arguments
        data (:, :)
        time_shift (1, 1)
        rate (1, 1)
        head_tail = 'tail'
    end
    
    
    if strcmp(head_tail, 'head')
        data_truncated = data(round(time_shift*rate)+1:end, :);
    else
        data_truncated = data(1:end-round(time_shift*rate), :);
    end
    
    
end