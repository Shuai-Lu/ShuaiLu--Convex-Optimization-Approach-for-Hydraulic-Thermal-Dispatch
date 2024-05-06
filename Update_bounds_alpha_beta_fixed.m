function Update_bounds_alpha_beta_fixed()
global data model_fixed;
loc_length = 3; loc_diameter = 4; loc_flowrate_max = 8; loc_flowrate_min = 7;
loc_tau_s_max = 10; loc_tau_s_min = 9; loc_tau_r_max = 12; loc_tau_r_min = 11;
% %
rho_w = data.BasicParam.Massflow.Density/1e3;     % t/m^3;
c_w = data.BasicParam.Massflow.HeatCapacity;     % MJ/(t*¡æ)
pi = data.BasicParam.pi;
Area_pipe = data.heatingnetwork.pipe(:,loc_diameter).^2*pi/4;
Length_pipe = data.heatingnetwork.pipe(:,loc_length);
num_heatperiod = data.period*data.interval.electricity/data.interval.heat;
num_pipe = size(data.heatingnetwork.pipe,1);
Massflow_initial = data.initialParam.heatingnetwork.massflow;
num_iter = length(model_fixed.record.bounds);
%%
Massflow_max = model_fixed.record.bounds(end).heatingnetwork.Massflow_max;
Massflow_min = model_fixed.record.bounds(end).heatingnetwork.Massflow_min;
t = 1:num_heatperiod;
for j = 1:num_pipe
    Num_aux(t,j) = ceil(rho_w*Area_pipe(j)*Length_pipe(j)./(model_fixed.record.bounds(end).heatingnetwork(1).Massflow_min(t,j)*data.interval.heat)) + 1;
end
temp = max(ceil(rho_w*Area_pipe(:).*Length_pipe(:)./(Massflow_initial'*data.interval.heat)) + 1);
if isempty(model_fixed.record.solution)
    Num_aux = max(max(max(Num_aux)), temp);
else
    Num_aux = size(model_fixed.var.heatingnetwork.aux_alpha,1);
end
%%
for t = 1:num_heatperiod
    for j = 1:num_pipe
        M_alpha_max = 0; M_alpha_min = 0; M_beta_max = 0; M_beta_min = 0;
        sum1 = 0; sum2 = 0; sum3 = 0; sum4 = 0;
        % sum1
        for i = 1:Num_aux
            if t+1-i <= 0
                sum1 = sum1 + Massflow_initial(j)*data.interval.heat;
            else
                sum1 = sum1 + Massflow_min(t+1-i,j)*data.interval.heat;
            end
            if sum1 > rho_w*Area_pipe(j)*Length_pipe(j)
                M_alpha_max = i-1;
                if t+1-i <= 0
                    sum1 = sum1 - Massflow_initial(j)*data.interval.heat;
                else
                    sum1 = sum1 - Massflow_min(t+1-i,j)*data.interval.heat;
                end
                break;
            end
        end
        % sum2
        for i = 1:Num_aux
            if t+1-i <= 0
                sum2 = sum2 + Massflow_initial(j)*data.interval.heat;
            else
                sum2 = sum2 + Massflow_max(t+1-i,j)*data.interval.heat;
            end
            if sum2 > rho_w*Area_pipe(j)*Length_pipe(j)
                M_alpha_min = i-1;
                if t+1-i <= 0
                    sum2 = sum2 - Massflow_initial(j)*data.interval.heat;
                else
                    sum2 = sum2 - Massflow_max(t+1-i,j)*data.interval.heat;
                end
                break;
            end
        end
        % sum3
        for i = 1:Num_aux
            if t-i <= 0
                sum3 = sum3 + Massflow_initial(j)*data.interval.heat;
            else
                sum3 = sum3 + Massflow_min(t-i,j)*data.interval.heat;
            end
            if sum3 > rho_w*Area_pipe(j)*Length_pipe(j)
                M_beta_max = i-1;
                if t-i <= 0
                    sum3 = sum3 - Massflow_initial(j)*data.interval.heat;
                else
                    sum3 = sum3 - Massflow_min(t-i,j)*data.interval.heat;
                end
                break;
            end
        end
        % sum4
        for i = 1:Num_aux
            if t-i <= 0
                sum4 = sum4 + Massflow_initial(j)*data.interval.heat;
            else
                sum4 = sum4 + Massflow_max(t-i,j)*data.interval.heat;
            end
            if sum4 > rho_w*Area_pipe(j)*Length_pipe(j)
                M_beta_min = i-1;
                if t-i <= 0
                    sum4 = sum4 - Massflow_initial(j)*data.interval.heat;
                else
                    sum4 = sum4 - Massflow_max(t-i,j)*data.interval.heat;
                end
                break;
            end
        end
        
       %% **************************************************************        
        % alpha_max
        aux_alpha_max(1:M_alpha_max, j, t) = 1; %#ok<*AGROW>
        if t-M_alpha_max <= 0
            aux_alpha_max(M_alpha_max+1, j, t) = (rho_w*Area_pipe(j)*Length_pipe(j) - sum1)/ ...
                (Massflow_initial(j)*data.interval.heat);
        else
            aux_alpha_max(M_alpha_max+1, j, t) = (rho_w*Area_pipe(j)*Length_pipe(j) - sum1)/ ...
                (Massflow_min(t-M_alpha_max,j)*data.interval.heat);
        end
        aux_alpha_max(M_alpha_max+2:Num_aux, j, t) = 0;
        % % alpha_min
        aux_alpha_min(1:M_alpha_min, j, t) = 1;
        if t-M_alpha_min <= 0
            aux_alpha_min(M_alpha_min+1, j, t) = (rho_w*Area_pipe(j)*Length_pipe(j) - sum2)/ ...
                (Massflow_initial(j)*data.interval.heat);
        else
            aux_alpha_min(M_alpha_min+1, j, t) = (rho_w*Area_pipe(j)*Length_pipe(j) - sum2)/ ...
                (Massflow_max(t-M_alpha_min,j)*data.interval.heat);
        end
        aux_alpha_min(M_alpha_min+2:Num_aux, j, t) = 0;
        
        % % beta_max
        aux_beta_max(1:M_beta_max+1, j, t) = 1;
        if t-M_beta_max-1 <= 0
            aux_beta_max(M_beta_max+2, j, t) = (rho_w*Area_pipe(j)*Length_pipe(j) - sum3)/ ...
                (Massflow_initial(j)*data.interval.heat);
        else
            aux_beta_max(M_beta_max+2, j, t) = (rho_w*Area_pipe(j)*Length_pipe(j) - sum3)/ ...
                (Massflow_min(t-M_beta_max-1,j)*data.interval.heat);
        end
        aux_beta_max(M_beta_max+3:Num_aux, j, t) = 0;
        % % beta_min
        aux_beta_min(1:M_beta_min+1, j, t) = 1;
        if t-M_beta_min-1 <= 0
            aux_beta_min(M_beta_min+2, j, t) = (rho_w*Area_pipe(j)*Length_pipe(j) - sum4)/ ...
                (Massflow_initial(j)*data.interval.heat);
        else
            aux_beta_min(M_beta_min+2, j, t) = (rho_w*Area_pipe(j)*Length_pipe(j) - sum4)/ ...
                (Massflow_max(t-M_beta_min-1,j)*data.interval.heat);
        end
        aux_beta_min(M_beta_min+3:Num_aux, j, t) = 0;
        
    end
end

model_fixed.record.bounds(end).heatingnetwork.aux_alpha_max = aux_alpha_max;
model_fixed.record.bounds(end).heatingnetwork.aux_alpha_min = aux_alpha_min;
model_fixed.record.bounds(end).heatingnetwork.aux_beta_max = aux_beta_max;
model_fixed.record.bounds(end).heatingnetwork.aux_beta_min = aux_beta_min;

% if num_iter >= 2
%     min(model_fixed.record.solution(end).solution.heatingnetwork.aux_alpha(:)-aux_alpha_min(:))
%     min(-model_fixed.record.solution(end).solution.heatingnetwork.aux_alpha(:)+aux_alpha_max(:))
%     min(model_fixed.record.solution(end).solution.heatingnetwork.aux_beta(:)-aux_beta_min(:))
%     min(-model_fixed.record.solution(end).solution.heatingnetwork.aux_beta(:)+aux_beta_max(:))
%     min(min(model_fixed.record.solution(end).solution.heatingnetwork.Massflow(11:end,:)- ...
%         model_fixed.record.bounds(end).heatingnetwork.Massflow_min(:,:)))
%     min(min(-model_fixed.record.solution(end).solution.heatingnetwork.Massflow(11:end,:)+ ...
%         model_fixed.record.bounds(end).heatingnetwork.Massflow_max(:,:)))
% end
end