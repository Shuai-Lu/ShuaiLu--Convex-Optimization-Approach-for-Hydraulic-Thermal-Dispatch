function Cal_penalty_improve(varargin)
if find(strcmp(varargin, 'DisplayTime'))
    DisplayTime = varargin{find(strcmp(varargin, 'DisplayTime'))+1};
else
    DisplayTime = 1;
end
if DisplayTime
    fprintf('%-40s\t\t','- Calculate penalty cost');
    t0 = clock;
end
global data model;
%%
num_initialtime = data.initialParam.heatingnetwork.num_initialtime;
num_heatperiod = data.period*data.interval.electricity/data.interval.heat;  % h
num_start = num_initialtime+1;
num_end = num_initialtime+num_heatperiod;
t = num_start:num_end;
length_penalty = length(model.penalty);
k = varargin{1};
if length_penalty == 0
    model.penalty(length_penalty+1).sum = 0;
    model.penalty(length_penalty+1).Massflow = 0;
    model.penalty(length_penalty+1).Tau_pipe = 0;
    model.penalty(length_penalty+1).h_pipe = 0;
    model.penalty(length_penalty+1).aux_alpha = 0;
    model.penalty(length_penalty+1).aux_beta = 0;
    model.penalty(length_penalty+1).aux_M_alpha = 0;
    model.penalty(length_penalty+1).aux_M_beta = 0;
    model.penalty(length_penalty+1).aux_h_alpha = 0;
    model.penalty(length_penalty+1).aux_h_beta = 0;
elseif length_penalty >= 1
    % % Massflow: 6
    model.penalty(length_penalty+1).Massflow = ...
        4*sum(sum((model.var.heatingnetwork.Massflow(t,:) - model.record.projection(end).Massflow).^2));
        
    % % Tau_pipe: 4
    model.penalty(length_penalty+1).Tau_pipe = ...
        sum(sum((model.var.heatingnetwork.Tau_pipe_s_in(t,:) - model.record.projection(end).Tau_pipe_s_in).^2)) + ...
        sum(sum((model.var.heatingnetwork.Tau_pipe_s_out(t,:) - model.record.projection(end).Tau_pipe_s_out).^2)) + ...
        sum(sum((model.var.heatingnetwork.Tau_pipe_r_in(t,:) - model.record.projection(end).Tau_pipe_r_in).^2)) + ...
        sum(sum((model.var.heatingnetwork.Tau_pipe_r_out(t,:) - model.record.projection(end).Tau_pipe_r_out).^2));
    % % h_pipe_s/r_in: 4
    model.penalty(length_penalty+1).h_pipe = ...
        sum(sum((model.var.heatingnetwork.h_pipe_s_in(t,:) - model.record.projection(end).h_pipe_s_in).^2)) + ...
        sum(sum((model.var.heatingnetwork.h_pipe_s_out(t,:) - model.record.projection(end).h_pipe_s_out).^2)) + ...
        sum(sum((model.var.heatingnetwork.h_pipe_r_in(t,:) - model.record.projection(end).h_pipe_r_in).^2)) + ...
        sum(sum((model.var.heatingnetwork.h_pipe_r_out(t,:) - model.record.projection(end).h_pipe_r_out).^2));
               
    
    % % alpha: 3
    model.penalty(length_penalty+1).aux_alpha = ...
        sum((model.var.heatingnetwork.aux_alpha(:) - model.record.projection(end).aux_alpha(:)).^2);
    % % aux_M_alpha: 1
    model.penalty(length_penalty+1).aux_M_alpha = ...
        sum((model.var.heatingnetwork.aux_M_alpha(:) - model.record.projection(end).aux_M_alpha(:)).^2);
    % % aux_h_alpha: 2
    model.penalty(length_penalty+1).aux_h_alpha = ...
        sum((model.var.heatingnetwork.aux_h_pipe_s_in_alpha(:) - model.record.projection(end).aux_h_pipe_s_in_alpha(:)).^2) + ...
        sum((model.var.heatingnetwork.aux_h_pipe_r_in_alpha(:) - model.record.projection(end).aux_h_pipe_r_in_alpha(:)).^2);
    
    % % beta: 3
    model.penalty(length_penalty+1).aux_beta = ...
        sum((model.var.heatingnetwork.aux_beta(:) - model.record.projection(end).aux_beta(:)).^2);
    % % aux_M_beta: 1
    model.penalty(length_penalty+1).aux_M_beta = ...
        sum((model.var.heatingnetwork.aux_M_beta(:) - model.record.projection(end).aux_M_beta(:)).^2);
    % % aux_h_beta: 2
    model.penalty(length_penalty+1).aux_h_beta = ...
        sum((model.var.heatingnetwork.aux_h_pipe_s_in_beta(:) - model.record.projection(end).aux_h_pipe_s_in_beta(:)).^2) + ...
        sum((model.var.heatingnetwork.aux_h_pipe_r_in_beta(:) - model.record.projection(end).aux_h_pipe_r_in_beta(:)).^2);
    
end

%% sum
model.penalty(length_penalty+1).sum = k * ...
    (model.penalty(length_penalty+1).Massflow + ...
    model.penalty(length_penalty+1).Tau_pipe + model.penalty(length_penalty+1).h_pipe + ...
    model.penalty(length_penalty+1).aux_alpha + model.penalty(length_penalty+1).aux_beta + ...
    model.penalty(length_penalty+1).aux_M_alpha + model.penalty(length_penalty+1).aux_M_beta + ...
    model.penalty(length_penalty+1).aux_h_alpha + model.penalty(length_penalty+1).aux_h_beta);


%%
if DisplayTime
    t1 = clock;
    fprintf('%10.2f%s\n', etime(t1,t0), 's');
end

end