function Cal_alpha_beta()

global data model;
loc_length = 3; loc_diameter = 4;
% %
rho_w = data.BasicParam.Massflow.Density/1e3;     % t/m^3;
% c_w = data.BasicParam.Massflow.HeatCapacity;     % kJ/(kg*¡æ)
pi = data.BasicParam.pi;
Area_pipe = data.heatingnetwork.pipe(:,loc_diameter).^2*pi/4;
Length_pipe = data.heatingnetwork.pipe(:,loc_length);
num_pipe = size(data.heatingnetwork.pipe,1);
num_heatperiod = data.period*data.interval.electricity/data.interval.heat;  % h
Num_aux = size(model.record.solution(end).solution.heatingnetwork.aux_alpha,1);
%%
Massflow_initial = data.initialParam.heatingnetwork.massflow;
Massflow = model.record.projection(end).Massflow;
%%
for t = 1:num_heatperiod
    for j = 1:num_pipe
        M_alpha = 0;  M_beta = 0;
        sum_alpha = 0; sum_beta = 0;
        % sum_alpha
        for i = 1:Num_aux
            if t+1-i <= 0
                sum_alpha = sum_alpha + Massflow_initial(j);
            else
                sum_alpha = sum_alpha + Massflow(t+1-i,j)*data.interval.heat;
            end
            if sum_alpha > rho_w*Area_pipe(j)*Length_pipe(j)
                M_alpha = i-1;
                if t+1-i <= 0
                    sum_alpha = sum_alpha - Massflow_initial(j);
                else
                    sum_alpha = sum_alpha - Massflow(t+1-i,j)*data.interval.heat;
                end
                break;
            end
        end
        
        % sum_beta
        for i = 1:Num_aux
            if t-i <= 0
                sum_beta = sum_beta + Massflow_initial(j);
            else
                sum_beta = sum_beta + Massflow(t-i,j)*data.interval.heat;
            end
            if sum_beta > rho_w*Area_pipe(j)*Length_pipe(j)
                M_beta = i-1;
                if t-i <= 0
                    sum_beta = sum_beta - Massflow_initial(j);
                else
                    sum_beta = sum_beta - Massflow(t-i,j)*data.interval.heat;
                end
                break;
            end
        end
        
        %%
        % alpha
        aux_alpha(1:M_alpha, j, t) = 1; %#ok<*AGROW>
        if t-M_alpha <= 0
            aux_alpha(M_alpha+1, j, t) = (rho_w*Area_pipe(j)*Length_pipe(j) - sum_alpha)/ ...
                (Massflow_initial(j)*data.interval.heat);
        else
            aux_alpha(M_alpha+1, j, t) = (rho_w*Area_pipe(j)*Length_pipe(j) - sum_alpha)/ ...
                (Massflow(t-M_alpha,j)*data.interval.heat);
        end
        aux_alpha(M_alpha+2:Num_aux, j, t) = 0;
        
        
        % % beta
        aux_beta(1:M_beta+1, j, t) = 1;
        if t-M_beta-1 <= 0
            aux_beta(M_beta+2, j, t) = (rho_w*Area_pipe(j)*Length_pipe(j) - sum_beta)/ ...
                (Massflow_initial(j)*data.interval.heat);
        else
            aux_beta(M_beta+2, j, t) = (rho_w*Area_pipe(j)*Length_pipe(j) - sum_beta)/ ...
                (Massflow(t-M_beta-1,j)*data.interval.heat);
        end
        aux_beta(M_beta+3:Num_aux, j, t) = 0;
    end
end

model.record.projection(end).aux_alpha = aux_alpha;
model.record.projection(end).aux_beta = aux_beta;

end



