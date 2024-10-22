function model_heatingnetwork_NLP(varargin)
% ***************************************************
% Model of Heating Network
% ***************************************************
if find(strcmp(varargin, 'DisplayTime'))
    DisplayTime = varargin{find(strcmp(varargin, 'DisplayTime'))+1};
else
    DisplayTime = 1;
end
if DisplayTime
    fprintf('%-40s\t\t','- Model heating network');
    t0 = clock;
end
%%
global data model;
P1 = 0.5*[1 1; 1 1]; P2 = 0.5*[1 -1; -1 1];
[loc_fnode, loc_tnode, loc_length, loc_diameter, loc_rough, ...
    loc_conductivity, loc_flowrate_min, loc_flowrate_max, ...
    loc_tau_s_min, loc_tau_s_max, loc_tau_r_min, loc_tau_r_max, loc_flag_pump] = ...
    deal(1,2,3,4,5,6,7,8,9,10,11,12,16);
[loc_nodeno, loc_nodetype] = deal(1,2);
[loc_initial_Tau_s, loc_initial_Tau_r, loc_initial_Tau_amb] = ...
    deal(1,2,3);
%% Data
rho_w = data.BasicParam.Massflow.Density/1e3;     % t/m^3;
c_w = data.BasicParam.Massflow.HeatCapacity;     % kJ/(kg*��)
pi = data.BasicParam.pi;
big_M = data.BasicParam.big_M;
% %
num_initialtime = data.initialParam.heatingnetwork.num_initialtime;
num_heatperiod = data.period*data.interval.electricity/data.interval.heat;  % h
num_start = num_initialtime+1;
num_end = num_initialtime+num_heatperiod;
% %
data_pipe = data.heatingnetwork.pipe;
data_node = data.heatingnetwork.node;
data_initial = data.initialParam.heatingnetwork;
% %
num_pipe = size(data_pipe,1);
num_node = size(data_node,1);
num_source = sum(data_node(:,loc_nodetype) == 0);
num_load = sum(data_node(:,loc_nodetype) == 2);
data_Tau_sur = ones(num_initialtime+num_heatperiod,1)*data_initial.temperature(loc_initial_Tau_amb);

%% Calculate basic parameters
Area_pipe = data_pipe(:,loc_diameter).^2*pi/4;
Length_pipe = data_pipe(:,loc_length);
heatloss_ratio = 3600/1e3*data_pipe(:,loc_conductivity)*data.interval.heat./Area_pipe/c_w/rho_w;
data.heatingnetwork.Area = Area_pipe;
data.heatingnetwork.Length = Length_pipe;
data.heatingnetwork.heatloss_ratio = heatloss_ratio;
Massflow_max = model.record.bounds.heatingnetwork(end).Massflow_max;
Massflow_min = model.record.bounds.heatingnetwork(end).Massflow_min;
Tau_pipe_s_in_max = model.record.bounds.heatingnetwork(end).Tau_pipe_s_in_max;
Tau_pipe_s_in_min = model.record.bounds.heatingnetwork(end).Tau_pipe_s_in_min;
Tau_pipe_s_out_max = model.record.bounds.heatingnetwork(end).Tau_pipe_s_out_max;
Tau_pipe_s_out_min = model.record.bounds.heatingnetwork(end).Tau_pipe_s_out_min;
Tau_pipe_r_in_max = model.record.bounds.heatingnetwork(end).Tau_pipe_r_in_max;
Tau_pipe_r_in_min = model.record.bounds.heatingnetwork(end).Tau_pipe_r_in_min;
Tau_pipe_r_out_max = model.record.bounds.heatingnetwork(end).Tau_pipe_r_out_max;
Tau_pipe_r_out_min = model.record.bounds.heatingnetwork(end).Tau_pipe_r_out_min;
aux_alpha_max = model.record.bounds.heatingnetwork(end).aux_alpha_max;
aux_alpha_min = model.record.bounds.heatingnetwork(end).aux_alpha_min;
aux_beta_max = model.record.bounds.heatingnetwork(end).aux_beta_max;
aux_beta_min = model.record.bounds.heatingnetwork(end).aux_beta_min;
h_pipe_s_in_max = 1000/3600*c_w*Massflow_max.*Tau_pipe_s_in_max;  % kW
h_pipe_s_in_min = 1000/3600*c_w*Massflow_min.*Tau_pipe_s_in_min;
h_pipe_r_in_max = 1000/3600*c_w*Massflow_max.*Tau_pipe_r_in_max;
h_pipe_r_in_min = 1000/3600*c_w*Massflow_min.*Tau_pipe_r_in_min;
h_pipe_s_out_max = 1000/3600*c_w*Massflow_max.*Tau_pipe_s_out_max;
h_pipe_s_out_min = 1000/3600*c_w*Massflow_min.*Tau_pipe_s_out_min;
h_pipe_r_out_max = 1000/3600*c_w*Massflow_max.*Tau_pipe_r_out_max;
h_pipe_r_out_min = 1000/3600*c_w*Massflow_min.*Tau_pipe_r_out_min;
num_aux = size(model.record.bounds.heatingnetwork.aux_alpha_max,1);

%%
define_variables();                % % Define variables
Initilize_initialtime();           % % Initialize num_initialtime
Fix_known_variables();             % % Fix known variables();
%% Thermal Constraints
Cons_ThermalBalance_source_load();  % % Thermal balance at source & load nodes
Cons_ThermalBalance_node();         % % Thermal balance and temperature mixing at cross node (4g)

% % Temperature quasi-dynamic (4d)-(4e)
Cons_aux_alpha_beta();              % Complementary constraints between aux_alpha aux_beta
Cons_aux_M();

Cons_aux_h();                  % McMormick envelope: linearization of aux_h_in & aux_h_out
Cons_aux_h_out();                   % Cons of aux_h_out
% % heat loss
t = num_start:num_end;
model.cons = model.cons + (( ...
    model.var.heatingnetwork.h_pipe_s_out(t,:) == model.var.heatingnetwork.aux_h_pipe_s_out) : '');
model.cons = model.cons + (( ...
    model.var.heatingnetwork.h_pipe_r_out(t,:) == model.var.heatingnetwork.aux_h_pipe_r_out) : '');
% % Thermal power equation (4f)
Cons_h();                     % McCormick envelope of heat power(8a)

%% Temperature limits (4h)
t = 1:num_heatperiod;
model.cons = model.cons + ((Tau_pipe_s_in_min(t,:) <= ...
    model.var.heatingnetwork.Tau_pipe_s_in(t+num_initialtime,:) <= ...
    Tau_pipe_s_in_max(t,:)) : '');
model.cons = model.cons + ((Tau_pipe_s_out_min(t,:) <= ...
    model.var.heatingnetwork.Tau_pipe_s_out(t+num_initialtime,:) <= ...
    Tau_pipe_s_out_max(t,:)) : '');
model.cons = model.cons + ((Tau_pipe_r_in_min(t,:) <= ...
    model.var.heatingnetwork.Tau_pipe_r_in(t+num_initialtime,:) <= ...
    Tau_pipe_r_in_max(t,:)) : '');
model.cons = model.cons + ((Tau_pipe_r_out_min(t,:) <= ...
    model.var.heatingnetwork.Tau_pipe_r_out(t+num_initialtime,:) <= ...
    Tau_pipe_r_out_max(t,:)) : '');


%% Hydraulic Constraints
% % mass flow balance (4i)
t = num_start:num_end;
for k = 1:num_node
    % cross node
    if data_node(k,loc_nodetype) == 1
        set_pipe_head = find(data_pipe(:,loc_fnode) == k);
        set_pipe_tail = find(data_pipe(:,loc_tnode) == k);
        if isa((sum(model.var.heatingnetwork.Massflow(t,set_pipe_tail),2) == ...
                sum(model.var.heatingnetwork.Massflow(t,set_pipe_head),2)), 'constraint')
            model.cons = model.cons + (( ...
                sum(model.var.heatingnetwork.Massflow(t,set_pipe_tail),2) == ...
                sum(model.var.heatingnetwork.Massflow(t,set_pipe_head),2)) : '');
        end
    end
end
% % pressure head balance of pipeline (4j)
t = num_start:num_end;
for j = 1:num_pipe
    fnode = data_pipe(j,loc_fnode);
    tnode = data_pipe(j,loc_tnode);
    if data_pipe(j,loc_flag_pump)
        model.cons = model.cons + (( ...
            model.var.heatingnetwork.Pressure_node(t,fnode) - model.var.heatingnetwork.Pressure_node(t,tnode) == ...
            model.var.heatingnetwork.Pressure_loss(t,j) + ...
            model.var.heatingnetwork.Pressure_pump(t,sum(data_pipe(1:j,loc_flag_pump)))) : '');
    else
        model.cons = model.cons + (( ...
            model.var.heatingnetwork.Pressure_node(t,fnode) - model.var.heatingnetwork.Pressure_node(t,tnode) == ...
            model.var.heatingnetwork.Pressure_loss(t,j)) : '');
    end
end
% % pressure loss of pipeline (4k): (10b)
t = 1:num_heatperiod;
for j = 1:num_pipe
    %     model.cons = model.cons + (( ...
    %         model.var.heatingnetwork.Pressure_loss(t+num_initialtime,j) >= data_pipe(j,loc_rough)* ...
    %         model.var.heatingnetwork.Massflow(t+num_initialtime,j).^2) : '');
    model.cons = model.cons + (( ...
        model.var.heatingnetwork.Pressure_loss(t+num_initialtime,j) <= data_pipe(j,loc_rough)* ...
        ((Massflow_max(t,j)+Massflow_min(t,j)).*model.var.heatingnetwork.Massflow(t+num_initialtime,j) - ...
        Massflow_max(t,j).*Massflow_min(t,j))) : '');
end
%% --------------------------------------------
%% head gain of pump (4l): (11a)
% t = num_start:num_end;
% for j = 1:sum(data_pipe(:,loc_flag_pump))
%     model.cons = model.cons + (( 0 <=  ...
%         model.var.heatingnetwork.Pressure_pump(t,j) <= ...
%         -0.05*model.var.heatingnetwork.Massflow(t,j).^2 + ...
%         5*model.var.heatingnetwork.Massflow(t,j)*10 + ...
%         5*10^2) : '');
% end
% % bounds of mass flow and pressure head (4m)-4(n)
t = 1:num_heatperiod;
if isa((Massflow_min(t,:) <= model.var.heatingnetwork.Massflow(t+num_initialtime,:) <= ...
        Massflow_max(t,:)), 'constraint')
    model.cons = model.cons + ((Massflow_min(t,:) ...
        <= model.var.heatingnetwork.Massflow(t+num_initialtime,:) <= ...
        Massflow_max(t,:)) : '');
end
% model.cons = model.cons + (( ...
%     ones(num_heatperiod,1)*2*ones(1,num_node) <= ...
%     model.var.heatingnetwork.Pressure_node(t,:) <= ...
%     ones(num_heatperiod,1)*50*ones(1,num_node)) : '');


%% Final temperature constraints
model.cons = model.cons + (( ...
    model.var.heatingnetwork.Tau_pipe_s_in(end-data.interval.electricity/data.interval.heat + 1 : end,1) >= ...
    data_initial.temperature(loc_initial_Tau_s)) : '');
model.cons = model.cons + (( ...
    model.var.heatingnetwork.Tau_pipe_r_out(end-data.interval.electricity/data.interval.heat + 1 : end,:) == ...
    data_initial.temperature(loc_initial_Tau_r)) : '');

%% Consistency in each control period
interval = data.interval.electricity/data.interval.heat;
if interval >= 2
    for t = num_start:interval:num_end
        model.cons = model.cons + (( ...
            ones(interval-1,1)*model.var.heatingnetwork.Massflow(t,:) == ...
            model.var.heatingnetwork.Massflow(t+1:t+interval-1,:)) : '');
        model.cons = model.cons + (( ...
            ones(interval-1,1)*model.var.heatingnetwork.Tau_pipe_s_in(t,:) == ...
            model.var.heatingnetwork.Tau_pipe_s_in(t+1:t+interval-1,:)) : '');
    end
end

%%
if DisplayTime
    t1 = clock;
    fprintf('%10.2f%s\n', etime(t1,t0), 's');
end

%% ****************************************************
%% Sub Function
%% ****************************************************

%% -----------------------------------------------------------------
% % Define variables
    function define_variables()
        model.var.heatingnetwork = [];
        model.var.heatingnetwork.Massflow = sdpvar(num_initialtime+num_heatperiod, num_pipe);   % t/h
        model.var.heatingnetwork.Pressure_loss = sdpvar(num_initialtime+num_heatperiod, num_pipe);
        model.var.heatingnetwork.Pressure_node = sdpvar(num_initialtime+num_heatperiod, num_node);
        model.var.heatingnetwork.Pressure_pump = sdpvar(num_initialtime+num_heatperiod, 1);
        %
        model.var.heatingnetwork.Tau_pipe_s_in = sdpvar(num_initialtime+num_heatperiod, num_pipe);
        model.var.heatingnetwork.Tau_pipe_s_out = sdpvar(num_initialtime+num_heatperiod, num_pipe);
        model.var.heatingnetwork.Tau_pipe_r_in = sdpvar(num_initialtime+num_heatperiod, num_pipe);
        model.var.heatingnetwork.Tau_pipe_r_out = sdpvar(num_initialtime+num_heatperiod, num_pipe);
        %
        model.var.heatingnetwork.h_pipe_s_in = sdpvar(num_initialtime+num_heatperiod, num_pipe);  % kW
        model.var.heatingnetwork.h_pipe_s_out = sdpvar(num_initialtime+num_heatperiod, num_pipe);
        model.var.heatingnetwork.h_pipe_r_in = sdpvar(num_initialtime+num_heatperiod, num_pipe);
        model.var.heatingnetwork.h_pipe_r_out = sdpvar(num_initialtime+num_heatperiod, num_pipe);
        %
        model.var.heatingnetwork.h_source = sdpvar(num_initialtime+num_heatperiod, num_source);
        model.var.heatingnetwork.h_load = sdpvar(num_initialtime+num_heatperiod, num_load);
        
        % aux
        model.var.heatingnetwork.aux_alpha = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_beta = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_M_alpha = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_M_beta = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_h_pipe_s_in_alpha = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_h_pipe_s_in_beta = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_h_pipe_r_in_alpha = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_h_pipe_r_in_beta = sdpvar(num_aux,num_pipe,num_heatperiod);
        model.var.heatingnetwork.aux_h_pipe_s_out = sdpvar(num_heatperiod, num_pipe);
        model.var.heatingnetwork.aux_h_pipe_r_out = sdpvar(num_heatperiod, num_pipe);
        
    end

%% -----------------------------------------------------------------
% % Initialize num_initialtime
    function Initilize_initialtime()
        model.var.heatingnetwork.Tau_pipe_s_in(1:num_initialtime,:) = data_initial.temperature(loc_initial_Tau_s);
        model.var.heatingnetwork.Tau_pipe_r_in(1:num_initialtime,:) = data_initial.temperature(loc_initial_Tau_r);
        model.var.heatingnetwork.Tau_pipe_s_out(1:num_initialtime,:) = data_initial.temperature(loc_initial_Tau_s);
        model.var.heatingnetwork.Tau_pipe_r_out(1:num_initialtime,:) = data_initial.temperature(loc_initial_Tau_r);
        model.var.heatingnetwork.Massflow(1:num_initialtime,:) = ones(num_initialtime,1)*data_initial.massflow;
        model.var.heatingnetwork.h_pipe_s_in(1:num_initialtime,:) = 1000/3600*c_w* ...
            model.var.heatingnetwork.Massflow(1:num_initialtime,:).*model.var.heatingnetwork.Tau_pipe_s_in(1:num_initialtime,:);
        model.var.heatingnetwork.h_pipe_s_out(1:num_initialtime,:) = 1000/3600*c_w* ...
            model.var.heatingnetwork.Massflow(1:num_initialtime,:).*model.var.heatingnetwork.Tau_pipe_s_out(1:num_initialtime,:);
        model.var.heatingnetwork.h_pipe_r_in(1:num_initialtime,:) = 1000/3600*c_w* ...
            model.var.heatingnetwork.Massflow(1:num_initialtime,:).*model.var.heatingnetwork.Tau_pipe_r_in(1:num_initialtime,:);
        model.var.heatingnetwork.h_pipe_r_out(1:num_initialtime,:) = 1000/3600*c_w* ...
            model.var.heatingnetwork.Massflow(1:num_initialtime,:).*model.var.heatingnetwork.Tau_pipe_r_out(1:num_initialtime,:);
    end

%% -----------------------------------------------------------------
% % fixed known variables
    function Fix_known_variables()
        for t = 1:num_heatperiod
            for j = 1:num_pipe
                % Massflow
                if Massflow_max(t,j) == Massflow_min(t,j)
                    model.var.heatingnetwork.Massflow(t+num_initialtime,j) = ...
                        Massflow_min(t,j);
                end
                % Tau_pipe
                if Tau_pipe_s_in_max(t,j) == Tau_pipe_s_in_min(t,j)
                    model.var.heatingnetwork.Tau_pipe_s_in(t+num_initialtime,j) = ...
                        Tau_pipe_s_in_min(t,j);
                end
                if Tau_pipe_s_out_max(t,j) == Tau_pipe_s_out_min(t,j)
                    model.var.heatingnetwork.Tau_pipe_s_out(t+num_initialtime,j) = ...
                        Tau_pipe_s_out_min(t,j);
                end
                if Tau_pipe_r_in_max(t,j) == Tau_pipe_r_in_min(t,j)
                    model.var.heatingnetwork.Tau_pipe_r_in(t+num_initialtime,j) = ...
                        Tau_pipe_r_in_min(t,j);
                end
                if Tau_pipe_r_out_max(t,j) == Tau_pipe_r_out_min(t,j)
                    model.var.heatingnetwork.Tau_pipe_r_out(t+num_initialtime,j) = ...
                        Tau_pipe_r_out_min(t,j);
                end
            end
        end
        % % fixed known aux variables
        temp = (aux_alpha_max == aux_alpha_min);
        model.var.heatingnetwork.aux_alpha(temp) = ...
            aux_alpha_min(temp);
        temp = (aux_beta_max == aux_beta_min);
        model.var.heatingnetwork.aux_beta(temp) = ...
            aux_beta_min(temp);
    end

%% -------------------------------------------------------------
% % Thermal balance at source & load nodes
    function Cons_ThermalBalance_source_load()
        t = num_start:num_end;
        for k = 1:num_node
            % heat power balance at source node (4a)
            if data_node(k,loc_nodetype) == 0
                j = find(data_pipe(:,loc_fnode) == k);
                model.cons = model.cons + ((model.var.heatingnetwork.h_source(t,:) == ...
                    model.var.heatingnetwork.h_pipe_s_in(t,j) - ...
                    model.var.heatingnetwork.h_pipe_r_out(t,j)) : 'h_source'); %#ok<*BDSCA>
                % heat power balance at crossing node
            elseif data_node(k,loc_nodetype) == 1
                % heat power balance at load node (4b)
            elseif data_node(k,loc_nodetype) == 2
                j = find(data_pipe(:,loc_tnode) == k);
                model.cons = model.cons + (( ...
                    model.var.heatingnetwork.h_load(t, ...
                    sum(data_node(1:k,loc_nodetype) == 2)) == ...
                    model.var.heatingnetwork.h_pipe_s_out(t,j) - ...
                    model.var.heatingnetwork.h_pipe_r_in(t,j)) : 'h_load');
            end
        end
    end

%% -----------------------------------------------------------------
%% Constraints of aux_alpha aux_beta
%% -----------------------------------------------------------------
    function Cons_aux_alpha_beta()
        % % alpha
        % 0 <= alpha <= 1
        if isa((0 <= model.var.heatingnetwork.aux_alpha(:,:,:) <= 1), 'constraint')
            model.cons = model.cons + ((0 <= ...
                model.var.heatingnetwork.aux_alpha(:,:,:) <= 1) : '');
        end
        % (1 - alpha(i)) * alpha(i+1) = 0
        if isa(((1 - model.var.heatingnetwork.aux_alpha(1:end-1,:,:)) .* ...
                model.var.heatingnetwork.aux_alpha(2:end,:,:) == 0), 'constraint')
            model.cons = model.cons + (( ...
                (1 - model.var.heatingnetwork.aux_alpha(1:end-1,:,:)) .* ...
                model.var.heatingnetwork.aux_alpha(2:end,:,:) == 0 ) : '');
        end
        % % beta
        % 0 <= beta <= 1
        if isa((0 <= model.var.heatingnetwork.aux_beta(:,:,:) <= 1), 'constraint')
            model.cons = model.cons + ((0 <= ...
                model.var.heatingnetwork.aux_beta(:,:,:) <= 1) : '');
        end
        % beta(1) = 1
        if isa((model.var.heatingnetwork.aux_beta(1,:,:) == 1), 'constraint')
            model.cons = model.cons + (( ...
                model.var.heatingnetwork.aux_beta(1,:,:) == 1) : '');
        end
        % (1 - beta(i)) * beta(i+1) = 0
        if isa(((1 - model.var.heatingnetwork.aux_beta(1:end-1,:,:)) .* ...
                model.var.heatingnetwork.aux_beta(2:end,:,:) == 0), 'constraint')
            model.cons = model.cons + (( ...
                (1 - model.var.heatingnetwork.aux_beta(1:end-1,:,:)) .* ...
                model.var.heatingnetwork.aux_beta(2:end,:,:) == 0 ) : '');
        end
        
        % % Bounds of alpha & beta  (4d)-(4e)
        if isa((aux_alpha_min <= model.var.heatingnetwork.aux_alpha <= ...
                aux_alpha_max), 'constraint')
            model.cons = model.cons + (( ...
                aux_alpha_min <= ...
                model.var.heatingnetwork.aux_alpha <= ...
                aux_alpha_max) : '');
        end
        if isa((aux_beta_min <= ...
                model.var.heatingnetwork.aux_beta <= ...
                aux_beta_max), 'constraint')
            model.cons = model.cons + (( ...
                aux_beta_min <= ...
                model.var.heatingnetwork.aux_beta <= ...
                aux_beta_max): '');
        end
    end

%% ------------------------------------
% % Constraints of aux_M1 & aux_M2
    function Cons_aux_M()
        % %
        for t = 1:num_heatperiod
            i = 1:num_aux;
            model.cons = model.cons + (( ...
                model.var.heatingnetwork.aux_M_alpha(i,:,t) == ...
                model.var.heatingnetwork.aux_alpha(i,:,t) .* ...
                model.var.heatingnetwork.Massflow(t+num_initialtime+1-i,:)) : '');
            model.cons = model.cons + (( ...
                model.var.heatingnetwork.aux_M_beta(i,:,t) == ...
                model.var.heatingnetwork.aux_beta(i,:,t) .* ...
                model.var.heatingnetwork.Massflow(t+num_initialtime+1-i,:)) : '');
        end
        
        % % sum(aux_M_alpha*delta_t) = rho*S*L  (4d)-(4e)
        model.cons = model.cons + (( ...
            sum(model.var.heatingnetwork.aux_M_alpha(:,:,:), 1)*data.interval.heat == ...
            reshape(rho_w*Area_pipe.*Length_pipe*ones(1,num_heatperiod),[1,num_pipe,num_heatperiod])));
        model.cons = model.cons + (( ...
            sum(model.var.heatingnetwork.aux_M_beta(2:end,:,:), 1)*data.interval.heat == ...
            reshape(rho_w*Area_pipe.*Length_pipe*ones(1,num_heatperiod), [1,num_pipe,num_heatperiod])));
    end

%% ----------------------------------------------------------
% % Constraints of aux_h_in
    function Cons_aux_h()
        for t = 1:num_heatperiod
            i = 1:num_aux;
            % aux_h_pipe_s_in_alpha
            model.cons = model.cons + (( ...
                model.var.heatingnetwork.aux_h_pipe_s_in_alpha(i,:,t) == ...
                model.var.heatingnetwork.aux_alpha(i,:,t) .* ...
                model.var.heatingnetwork.h_pipe_s_in(t+num_initialtime+1-i,:) ...
                ) : '');
            % aux_h_pipe_r_in_alpha
            model.cons = model.cons + (( ...
                model.var.heatingnetwork.aux_h_pipe_r_in_alpha(i,:,t) == ...
                model.var.heatingnetwork.aux_alpha(i,:,t) .* ...
                model.var.heatingnetwork.h_pipe_r_in(t+num_initialtime+1-i,:) ...
                ) : '');
            % aux_h_pipe_s_in_beta
            model.cons = model.cons + (( ...
                model.var.heatingnetwork.aux_h_pipe_s_in_beta(i,:,t) == ...
                model.var.heatingnetwork.aux_beta(i,:,t) .* ...
                model.var.heatingnetwork.h_pipe_s_in(t+num_initialtime+1-i,:) ...
                ) : '');
            % aux_h_pipe_r_in_beta
            model.cons = model.cons + (( ...
                model.var.heatingnetwork.aux_h_pipe_r_in_beta(i,:,t) == ...
                model.var.heatingnetwork.aux_beta(i,:,t) .* ...
                model.var.heatingnetwork.h_pipe_r_in(t+num_initialtime+1-i,:) ...
                ) : '');
        end
    end

%% ---------------------------------------------------------------
% % Cons of aux_h_out
    function Cons_aux_h_out()
        model.cons = model.cons + (( ...
            reshape(model.var.heatingnetwork.aux_h_pipe_s_out',  [1, num_pipe, num_heatperiod]) == ...
            sum(model.var.heatingnetwork.aux_h_pipe_s_in_beta, 1) - ...
            sum(model.var.heatingnetwork.aux_h_pipe_s_in_alpha, 1)) : '');
        model.cons = model.cons + (( ...
            reshape(model.var.heatingnetwork.aux_h_pipe_r_out', [1, num_pipe, num_heatperiod]) == ...
            sum(model.var.heatingnetwork.aux_h_pipe_r_in_beta, 1) -  ...
            sum(model.var.heatingnetwork.aux_h_pipe_r_in_alpha, 1)) : '');
    end

%% ---------------------------------------
% % Cons of h_pipe
    function Cons_h()
        t = 1:num_heatperiod;
        model.cons = model.cons + (( ...
            model.var.heatingnetwork.h_pipe_s_in(t+num_initialtime,:) == 1000/3600*c_w* ...
            model.var.heatingnetwork.Tau_pipe_s_in(t+num_initialtime,:) .* ...
            model.var.heatingnetwork.Massflow(t+num_initialtime,:) ...
            ) : '');
        
        model.cons = model.cons + (( ...
            model.var.heatingnetwork.h_pipe_s_out(t+num_initialtime,:) == 1000/3600*c_w* ...
            model.var.heatingnetwork.Tau_pipe_s_out(t+num_initialtime,:) .* ...
            model.var.heatingnetwork.Massflow(t+num_initialtime,:) ...
            ) : '');
        model.cons = model.cons + (( ...
            model.var.heatingnetwork.h_pipe_r_in(t+num_initialtime,:) == 1000/3600*c_w* ...
            model.var.heatingnetwork.Tau_pipe_r_in(t+num_initialtime,:) .* ...
            model.var.heatingnetwork.Massflow(t+num_initialtime,:) ...
            ) : '');
        
        model.cons = model.cons + (( ...
            model.var.heatingnetwork.h_pipe_r_out(t+num_initialtime,:) == 1000/3600*c_w* ...
            model.var.heatingnetwork.Tau_pipe_r_out(t+num_initialtime,:) .* ...
            model.var.heatingnetwork.Massflow(t+num_initialtime,:) ...
            ) : '');
    end
%% ------------------------------------
% % Thermal balance at intersection node
    function Cons_ThermalBalance_node()
        for k = 1:num_node
            % cross node
            if data_node(k,loc_nodetype) == 1
                set_pipe_head = find(data_pipe(:,loc_fnode) == k);
                set_pipe_tail = find(data_pipe(:,loc_tnode) == k);
                model.cons = model.cons + (( ...
                    sum(model.var.heatingnetwork.h_pipe_s_out(num_start:num_end,set_pipe_tail),2) == ...
                    sum(model.var.heatingnetwork.h_pipe_s_in(num_start:num_end,set_pipe_head),2)) : '');
                model.cons = model.cons + (( ...
                    sum(model.var.heatingnetwork.h_pipe_r_out(num_start:num_end,set_pipe_head),2) == ...
                    sum(model.var.heatingnetwork.h_pipe_r_in(num_start:num_end,set_pipe_tail),2)) : '');
                if length(set_pipe_head) >= 2
                    model.cons = model.cons + (( ...
                        model.var.heatingnetwork.Tau_pipe_s_in(num_start:num_end,set_pipe_head(1)) == ...
                        model.var.heatingnetwork.Tau_pipe_s_in(num_start:num_end,set_pipe_head(2:end))) : '');
                end
                if length(set_pipe_tail) >= 2
                    model.cons = model.cons + (( ...
                        model.var.heatingnetwork.Tau_pipe_r_in(:,set_pipe_tail(1)) == ...
                        model.var.heatingnetwork.Tau_pipe_r_in(:,set_pipe_tail(2:end))) : '');
                end
            end
        end
    end
end
