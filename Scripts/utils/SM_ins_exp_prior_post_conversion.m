%% Inspiratory-Expiratory Conversion

%% 09/13/2020

%{ 
  Given a feature x, calculate


%}


function [ins_p, exp_p] = SM_ins_exp_prior_post_conversion(ins_data, exp_data, feature_edges)

    arguments
        ins_data (:, 1)
        exp_data (:, 1)
        feature_edges (1, :)
    end
    
    %% Histocounts
    [ins_n, ~] = histcounts(ins_data, feature_edges);
    [exp_n, ~] = histcounts(exp_data, feature_edges);
    
    total_n = ins_n + exp_n;
    
    ins_p = ins_n ./ total_n;
    
    exp_p = exp_n ./ total_n;
    
    if size(ins_p, 2) ~= 1
        ins_p = ins_p';
    end
    
    if size(exp_p, 2) ~= 1
        exp_p = exp_p';
    end
end