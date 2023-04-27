%% 04/08/2020


function [etat_matrix] = SM_etat_routine(to_avg_data, event_locs, extended_frame, alwBool)


    % to_avg_data is better to be a column
    if size(to_avg_data,2) ~= 1
        error('to_avg_data is not a column');
    end
    
    % event_locs is better to be acolumn
    if isempty(event_locs)
        disp('event_locs is empty');
        etat_matrix = [];
        return
    end
    
    
    if size(event_locs,2) ~= 1
        disp('event_locs is not a column');
    end
    
    
    
    % estimate maximum space needed for etat_matrix
    % if all event_locs are accepted, the number of the columns of
    % etat_matrix will simply be the number of event_locs
    
    % the rows will be data from -extended_frame, ..., -1, 0, 1, ..., extended_frame
    % which is 2*extended_frame+1
    
    % initializing
    default_row_number = 2*extended_frame+1;
    default_column_number = length(event_locs);
    etat_matrix = NaN(default_row_number, default_column_number);
    cc = 0;

    % iterate over event_locs
    for i = 1: length(event_locs)
        % event onset locs
        eo = event_locs(i);
        % eo should be > extended_frame
        if eo <= extended_frame
            continue
        end
        % eo should be < length(to_avg_data)-extended_frame
        if eo >=  (length(to_avg_data)-extended_frame)
            continue
        end
        % (eo-extended_frame to eo+extended_frame)
        etat_frames = ((eo-extended_frame):(eo+extended_frame));
        % (eo-extended_frame to eo+extended_frame) should all have alwBool true
        if ~all(alwBool(etat_frames))
            continue
        end
        cc = cc +1;
        etat_matrix(:,cc) = to_avg_data(etat_frames);
    end
    
    % number check
    num_of_nan_columns = sum(isnan(etat_matrix(1,:)));
    if num_of_nan_columns ~= (default_column_number-cc)
        error('NaN number inconsistent');
    end
    
    % remove excess NaN columns
    etat_matrix = etat_matrix(:,1:cc);
    
    clear cc
	
