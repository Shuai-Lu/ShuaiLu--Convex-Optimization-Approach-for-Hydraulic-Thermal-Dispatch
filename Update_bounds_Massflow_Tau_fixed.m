function Update_bounds_Massflow_Tau_fixed(varargin)
if find(strcmp(varargin, 'DisplayTime'))
    DisplayTime = varargin{find(strcmp(varargin, 'DisplayTime'))+1};
else
    DisplayTime = 1;
end
if DisplayTime
    fprintf('%-40s\t\t','- Update bounds');
    t0 = clock;
end
%%
global data model_fixed;
num_initialtime = data.initialParam.heatingnetwork.num_initialtime;
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
num_node = size(data.heatingnetwork.node,1);
Massflow_initial = data.initialParam.heatingnetwork.massflow;
num_iter = length(model_fixed.record.solution);


if varargin{1} == 1
    Massflow_max = ones(num_heatperiod,1)*Massflow_initial;
    Massflow_min = ones(num_heatperiod,1)*Massflow_initial;
    num_iter = 1;
elseif num_iter == 0
    Massflow_max = ones(num_heatperiod,1)*3600*rho_w*(Area_pipe.*data.heatingnetwork.pipe(:,loc_flowrate_max))';
    Massflow_min = ones(num_heatperiod,1)*3600*rho_w*(Area_pipe.*data.heatingnetwork.pipe(:,loc_flowrate_min))';
    num_iter = 1;
elseif num_iter > 0
    t = num_initialtime+1:num_initialtime+num_heatperiod;
    Massflow_max = model_fixed.record.solution(num_iter). ...
        solution.heatingnetwork.Massflow(t,:);
    Massflow_min = Massflow_max;
end

%%
Tau_pipe_s_in_max = ones(num_heatperiod,1)*data.heatingnetwork.pipe(:,loc_tau_s_max)';
Tau_pipe_s_in_min = ones(num_heatperiod,1)*data.heatingnetwork.pipe(:,loc_tau_s_min)';
Tau_pipe_s_out_max = ones(num_heatperiod,1)*data.heatingnetwork.pipe(:,loc_tau_s_max)';
Tau_pipe_s_out_min = ones(num_heatperiod,1)*data.heatingnetwork.pipe(:,loc_tau_s_min)';
Tau_pipe_r_in_max = ones(num_heatperiod,1)*data.heatingnetwork.pipe(:,loc_tau_r_max)';
Tau_pipe_r_in_min = ones(num_heatperiod,1)*data.heatingnetwork.pipe(:,loc_tau_r_min)';
Tau_pipe_r_out_max = ones(num_heatperiod,1)*data.heatingnetwork.pipe(:,loc_tau_r_max)';
Tau_pipe_r_out_min = ones(num_heatperiod,1)*data.heatingnetwork.pipe(:,loc_tau_r_min)';

%%
model_fixed.record.bounds(num_iter).heatingnetwork.Massflow_max = Massflow_max;
model_fixed.record.bounds(num_iter).heatingnetwork.Massflow_min = Massflow_min;
model_fixed.record.bounds(num_iter).heatingnetwork.Tau_pipe_s_in_max = Tau_pipe_s_in_max;
model_fixed.record.bounds(num_iter).heatingnetwork.Tau_pipe_s_in_min = Tau_pipe_s_in_min;
model_fixed.record.bounds(num_iter).heatingnetwork.Tau_pipe_s_out_max = Tau_pipe_s_out_max;
model_fixed.record.bounds(num_iter).heatingnetwork.Tau_pipe_s_out_min = Tau_pipe_s_out_min;
model_fixed.record.bounds(num_iter).heatingnetwork.Tau_pipe_r_in_max = Tau_pipe_r_in_max;
model_fixed.record.bounds(num_iter).heatingnetwork.Tau_pipe_r_in_min = Tau_pipe_r_in_min;
model_fixed.record.bounds(num_iter).heatingnetwork.Tau_pipe_r_out_max = Tau_pipe_r_out_max;
model_fixed.record.bounds(num_iter).heatingnetwork.Tau_pipe_r_out_min = Tau_pipe_r_out_min;

%% Pressure of node
model_fixed.record.bounds(num_iter).heatingnetwork.Pressure_node_max(1:num_heatperiod,1:num_node) = ...
    data.initialParam.heatingnetwork.pressure_bounds(1);
model_fixed.record.bounds(num_iter).heatingnetwork.Pressure_node_min(1:num_heatperiod,1:num_node) = ...
    data.initialParam.heatingnetwork.pressure_bounds(2);

%%
if DisplayTime
    t1 = clock;
    fprintf('%10.2f%s\n', etime(t1,t0), 's');
end
end