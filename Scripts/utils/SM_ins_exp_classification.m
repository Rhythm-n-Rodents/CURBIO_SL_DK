%% Inspiratory-Expiratory Classification

%% 09/13/2020


function [ins, exp] = SM_ins_exp_classification(data, breathing_onsets, breathing_lengths, ins_phi_range, exp_phi_range)

    arguments
        data (:, 1)
        breathing_onsets (:, 1)
        breathing_lengths (:, 1)
        ins_phi_range (1, 2)
        exp_phi_range (1, 2)
    end
    
    %% phase of breathing of each data
    data_phase_in_breathing = SM_target_phaseInCob(data, breathing_onsets, breathing_lengths);
    
    %% inspiratory data
    if ins_phi_range(1) < ins_phi_range(2) % ex: [45, 135]
        ins_bool = and(data_phase_in_breathing >= ins_phi_range(1) , data_phase_in_breathing <= ins_phi_range(2));
    else % ex: [330, 30]
        ins_bool = or(data_phase_in_breathing >= ins_phi_range(1) , data_phase_in_breathing <= ins_phi_range(2));
    end
        
    ins = data(ins_bool);
        
    %% expiratory data
    if exp_phi_range(1) < exp_phi_range(2) % ex: [200, 300]
        exp_bool = and(data_phase_in_breathing >= exp_phi_range(1) , data_phase_in_breathing <= exp_phi_range(2));
    else % ex: [330, 30]
        exp_bool = or(data_phase_in_breathing >= exp_phi_range(1) , data_phase_in_breathing <= exp_phi_range(2));
    end
        
    exp = data(exp_bool);

    
end