clc, clear all;
warning off;
flag_update_data = 1;
flag_CF = 0;
flag_CF_predetermine_massflow = 0;
%%
if flag_update_data && exist([cd '\mydata.mat']) %#ok<EXIST>
    delete('mydata.mat');
end
global data model FileName model_fixed;
data = []; model = [];
FileName = 'testdata_9bus_mesh.xlsx';

%%
ReadData(flag_update_data); % 1: update data; 0: old date;

%% initilizae
myIntialize(10, 1);    % num_initialtime=10, interval_heat=1
data.grid.p_pcc = 1e4; data.grid.q_pcc = 1e4;

%% model initilization
model.record.sol = [];
model. record.solution = [];
model.record.relaxation_error = [];
model.record.projection = [];
model.record.penalty = [];
model.record.bounds = [];
model.cons = [];
model.cons_McCormick = [];
model.SOC.ratio_aux_massflow = 0.01;
model.SOC.ratio_aux_h = 0.1;
model.SOC.ratio_h = 0.1;
model_fixed.record.sol = [];
model_fixed.record.solution = [];
model_fixed.cons = [];
model_fixed.record.bounds = [];
model_fixed.cons_McCormick = [];

%% 
Update_bounds_Massflow_Tau(flag_CF_predetermine_massflow);  % 0: not fixing the mass flow£» 1£ºfixing the mass flow
Update_bounds_alpha_beta();

%% modeling
model_grid();
model_heatingnetwork_SOC(1,1,flag_CF,flag_CF_predetermine_massflow); % 1: McCormick; 2: SOC; 3: 1-CF, 0-VF
model_buildings();
model_couplingrelationship();

%%
Update_bounds_Massflow_Tau_fixed(0);
Update_bounds_alpha_beta_fixed();
model_grid_fixed();
model_heatingnetwork_SOC_fixed(1,0);
model_buildings_fixed();
model_couplingrelationship_fixed();

%%
Max_iter = 200;
num_iter = 1;
flag_convergent = 0;
coefficient = [];
while num_iter <= Max_iter && ~flag_convergent
    fprintf('%s%2d%s\n', '------------------------ Iter:  ', num_iter, ' ------------------------');
    %% Calculate residual
    coefficient(num_iter) = min([1e4 1e4]); %#ok<*SAGROW>  % *(num_iter-1)^0.5
    model_cons_residual(coefficient(end),0);  % 1: Normalizaton; 0: No normalization
   
    %% solving
    fprintf('%-40s\n', '- Solving model');
    model.ops = sdpsettings('solver','mosek','showprogress',0, 'verbose',0, 'relax', 2);      
    model.record.sol(end+1).sol = optimize(model.cons + model.cons_McCormick + model.cons_CCP, ...
        model.cost.grid.sum + ...
        model.var.penalty, model.ops);
    fprintf('%-40s\t\t', '  -- Solving time:');
    fprintf('%10.2f%s\n',model.record.sol(end).sol.solvertime, 's');
    if model.record.sol(end).sol.problem
        fprintf('\n%s\n',model.record.sol(end).sol.info);
        load gong;
        sound(y,Fs);
%         break;
    end
    model.record.obj(num_iter) = value(model.cost.grid.sum + model.var.penalty);
    model.record.cost(num_iter) = value(model.cost.grid.sum);
    model.record.penalty(num_iter) = value(model.var.penalty);
    model.record.LB(num_iter) = value(model.cost.grid.sum);
    fprintf('%-40s\t\t', '  -- Cost: ');
    fprintf('%10.2f%s\n', model.record.cost(end), '$')
    fprintf('%-40s\t\t', '  -- Object: ');
    fprintf('%10.2f%s\n', model.record.obj(end), '$');
    
    %% record solution
    model.record.solution(end+1).solution = myFun_GetValue(model.var);
    
    %% Calculate relaxation error
    Cal_relaxation_error();
    fprintf('%-40s\t\t', '  -- alpha & beta:');
    fprintf('%10.2f%s\n',100*model.record.relaxation_error(end).aux_product_max, '%');   
    fprintf('%-40s\t\t', '  -- aux_M:');
    fprintf('%10.2f%s\n',100*model.record.relaxation_error(end).aux_M_max, '%');
    fprintf('%-40s\t\t', '  -- aux_h:');
    fprintf('%10.2f%s\n',100*model.record.relaxation_error(end).aux_h_pipe_max, '%');
    fprintf('%-40s\t\t', '  -- h:');
    fprintf('%10.2f%s\n',100*model.record.relaxation_error(end).h_pipe_max, '%');
    fprintf('%-40s\t\t', '  -- Pressure_loss:');
    fprintf('%10.2f%s\n',100*model.record.relaxation_error(end).Pressure_loss_max, '%');
    fprintf('%-40s\t\t', '  -- Power_pump:');
    fprintf('%10.2f%s\n',100*model.record.relaxation_error(end).Power_pump_max, '%');
    fprintf('%-40s\t\t', '  -- max:');
    fprintf('%10.2f%s\n',100*model.record.relaxation_error(end).max, '%');
    

    %% Solve CF-VT model
    fprintf('%-40s\n', '- Solving CF-VT model');
    model_fixed.record.solution(num_iter).solution.heatingnetwork.Massflow = ...
        model.record.solution(end).solution.heatingnetwork.Massflow;
    model_fixed.cons_McCormick = [];
    Update_bounds_Massflow_Tau_fixed(0,'DisplayTime',0);
    Update_bounds_alpha_beta_fixed();
    model_cons_McCormick_fixed('DisplayTime',0);
    
    model_fixed.ops = sdpsettings('solver','cplex', 'verbose',0, 'relax', 0);    
    model_fixed.record.sol(end+1).sol = optimize(model_fixed.cons + model_fixed.cons_McCormick, ...
        model_fixed.cost.grid.sum + 1e3*model_fixed.var.slacks.sum, ...
        model_fixed.ops);
    
    fprintf('%-40s\t\t', '  -- Solving time:');
    fprintf('%10.2f%s\n',model_fixed.record.sol(end).sol.solvertime, 's');
    if model_fixed.record.sol(end).sol.problem
        model_fixed.record.solution(num_iter).solution = myFun_GetValue(model_fixed.var);
        model_fixed.record.cost(num_iter) = inf;
        model_fixed.record.obj(num_iter) = inf;
    else
        model_fixed.record.solution(num_iter).solution = myFun_GetValue(model_fixed.var);
        model_fixed.record.cost(num_iter) = value(model_fixed.cost.grid.sum);
        model_fixed.record.obj(num_iter) = value(model_fixed.cost.grid.sum) + ...
            1e3*value(model_fixed.var.slacks.sum);
    end
    model.record.UB(num_iter) = min(model_fixed.record.obj(1:num_iter));
    fprintf('%-40s\t\t', '  -- Cost: ');
    fprintf('%10.2f%s\n', model_fixed.record.cost(end), '$');
    fprintf('%-40s\t\t', '  -- slacks: ');
    fprintf('%10.2f%s\n', value(model_fixed.var.slacks.sum), '');
    
    %% Calculate Gap
    if num_iter == 1
        model.record.gap.gap1(num_iter) = inf;
        model.record.gap.gap2(num_iter) = inf;
        model.record.gap.gap3(num_iter) = (min(model_fixed.record.cost) - ...
        model.record.cost(num_iter))/min(model_fixed.record.cost);
        model.record.gap.gap3(isnan(model.record.gap.gap3)) = inf; 
    elseif num_iter >= 2
        model.record.gap.gap1(num_iter) = ...
            ((model.record.cost(num_iter-1)+model.record.penalty(num_iter-1)) - ...
            (model.record.cost(num_iter)+ ...
            coefficient(num_iter-1)*model.record.penalty(num_iter)/coefficient(num_iter))) / ...
            (model.record.cost(num_iter-1)+model.record.penalty(num_iter-1));
        
        model.record.gap.gap2(num_iter) = model.record.penalty(num_iter)/coefficient(num_iter);
        
        model.record.gap.gap3(num_iter) = (min(model_fixed.record.obj) - ...
            model.record.cost(num_iter))/min(model_fixed.record.obj);
    end      
        
    fprintf('%-40s\n', '- Get the gap ');
    fprintf('%-40s\t\t', '  -- Gap1: ');
    fprintf('%10.2f%s\n', 100*model.record.gap.gap1(end), '%');
    fprintf('%-40s\t\t', '  -- Gap2: ');
    fprintf('%10.2f%s\n', model.record.gap.gap2(end), '');
        fprintf('%-40s\t\t', '  -- Gap3: ');
    fprintf('%10.2f%s\n', 100*model.record.gap.gap3(end), '%');
    %% Record penalty
    myplot_1(coefficient);
    myplot_2(num_iter);
    myplot_3();
    %%    
    if model.record.gap.gap1(end) <= 1e-4 && ...
            model.record.gap.gap2(end) <= 1e-2 && ...
            model.record.gap.gap3(end) <= 1e-4
        fprintf('%-40s\n', '- Convergent!');
        flag_convergent = 1;
        if flag_CF == 1
            temp = ['Results_' FileName(1:end-5) '_CF.mat'];
            save(temp);
        elseif flag_CF == 0
            temp = ['Results_' FileName(1:end-5) '_VF.mat'];
            save(temp);
        end
    end
    %%
    num_iter = num_iter + 1;
    fprintf('\n');
end

%% -----------------------------------------------------------------
%%                           Functions
%% -----------------------------------------------------------------
%% plot
function myplot_1(coefficient)
global model model_fixed;
for k = 1:length(model.record.relaxation_error)
    model.record.error.aux_product_max(k) = model.record.relaxation_error(k).aux_product_max;
    model.record.error.h_pipe_max(k) = model.record.relaxation_error(k).h_pipe_max;
    model.record.error.aux_M_max(k) = model.record.relaxation_error(k).aux_M_max;
    model.record.error.aux_h_pipe_max(k) = model.record.relaxation_error(k).aux_h_pipe_max;
    model.record.error.max(k) = model.record.relaxation_error(k).max;
end

%%
num_figure = 8;
figure(1);
clf;
subplot(num_figure,1,1);
title('Max of error');
semilogy(model.record.error.max, '.-', 'MarkerSize', 5, 'LineWidth', 3); hold on;
grid on;
legend({'\alpha \beta', 'h', 'M_{aux}', 'h_{aux}', 'max'}, 'Location', 'NorthWest', 'Orientation', 'Horizontal');

subplot(num_figure,1,2);
title('Penalty cost')
semilogy(model.record.penalty,'.-', 'MarkerSize', 5); hold on;
legend({'Cost of residual'});
grid on;

subplot(num_figure,1,3);
title('Sum of error');
semilogy(model.record.penalty./coefficient,'.-', 'MarkerSize', 5);
legend({'Residual'})
grid on;

subplot(num_figure,1,4);
title('Cost');
plot(model.record.LB,'.-', 'MarkerSize', 5); hold on;
plot(model.record.UB);
legend({'LB', 'UB'});
grid on;

subplot(num_figure,1,5);
title('Obj');
plot(model.record.obj,'.-', 'MarkerSize', 5); 
legend({'Obj'});
grid on;

subplot(num_figure,1,6);
title('gap');
semilogy(model.record.gap.gap1,'.-', 'MarkerSize', 5);
legend({'gap'});
grid on;

subplot(num_figure,1,7);
title('gap');
semilogy(model.record.gap.gap2,'.-', 'MarkerSize', 5);
legend({'gap'});
grid on;

subplot(num_figure,1,8);
title('gap');
plot(model.record.gap.gap3,'.-', 'MarkerSize', 5);
legend({'gap'});
grid on;
end

%% plot
function myplot_2(num_iter)
global model;
model.temp.residual.aux_product(num_iter) = ...
    sum(model.record.solution(end).solution.heatingnetwork.aux_alpha_product_1_residual(:)) + ...
    sum(model.record.solution(end).solution.heatingnetwork.aux_alpha_product_2_residual(:)) + ...
    sum(model.record.solution(end).solution.heatingnetwork.aux_beta_product_1_residual(:)) + ...
    sum(model.record.solution(end).solution.heatingnetwork.aux_beta_product_2_residual(:));
model.temp.residual.aux_M(num_iter) = ...
    sum(model.record.solution(end).solution.heatingnetwork.aux_M_alpha_1_residual(:)) +...
    sum(model.record.solution(end).solution.heatingnetwork.aux_M_alpha_2_residual(:)) + ...
    sum(model.record.solution(end).solution.heatingnetwork.aux_M_beta_1_residual(:)) + ...
    sum(model.record.solution(end).solution.heatingnetwork.aux_M_beta_2_residual(:));
model.temp.residual.aux_h(num_iter) = ...
    sum(model.record.solution(end).solution.heatingnetwork.aux_h_pipe_s_in_alpha_1_residual(:)) + ...
    sum(model.record.solution(end).solution.heatingnetwork.aux_h_pipe_s_in_alpha_2_residual(:)) + ...
    sum(model.record.solution(end).solution.heatingnetwork.aux_h_pipe_r_in_alpha_1_residual(:)) + ...
    sum(model.record.solution(end).solution.heatingnetwork.aux_h_pipe_r_in_alpha_2_residual(:)) + ...
    sum(model.record.solution(end).solution.heatingnetwork.aux_h_pipe_s_in_beta_1_residual(:)) + ...
    sum(model.record.solution(end).solution.heatingnetwork.aux_h_pipe_s_in_beta_2_residual(:)) + ...
    sum(model.record.solution(end).solution.heatingnetwork.aux_h_pipe_r_in_beta_1_residual(:)) + ...
    sum(model.record.solution(end).solution.heatingnetwork.aux_h_pipe_r_in_beta_2_residual(:));
model.temp.residual.h(num_iter) = ...
    sum(model.record.solution(end).solution.heatingnetwork.h_pipe_s_in_1_residual(:)) + ... ...
    sum(model.record.solution(end).solution.heatingnetwork.h_pipe_s_in_2_residual(:)) + ... ...
    sum(model.record.solution(end).solution.heatingnetwork.h_pipe_r_in_1_residual(:)) + ... ...
    sum(model.record.solution(end).solution.heatingnetwork.h_pipe_r_in_2_residual(:)) + ... ...
    sum(model.record.solution(end).solution.heatingnetwork.h_pipe_s_out_1_residual(:)) + ... ...
    sum(model.record.solution(end).solution.heatingnetwork.h_pipe_s_out_2_residual(:)) + ... ...
    sum(model.record.solution(end).solution.heatingnetwork.h_pipe_r_out_1_residual(:)) + ... ...
    sum(model.record.solution(end).solution.heatingnetwork.h_pipe_r_out_2_residual(:));
model.temp.residual.Pressure_loss(num_iter) = ...
    sum(model.record.solution(end).solution.heatingnetwork.Pressure_loss_residual(:));
model.temp.residual.Power_pump(num_iter) = ...
    sum(model.record.solution(end).solution.heatingnetwork.Power_pump_1_residual(:)) + ...
    sum(model.record.solution(end).solution.heatingnetwork.Power_pump_2_residual(:));

num_figure = 6;
figure(2); clf;
subplot(num_figure,1,1);         %%
semilogy(model.temp.residual.aux_product,'.-', 'MarkerSize', 5); grid on;
legend({'Sum of aux\_product'});
subplot(num_figure,1,2);        %%
semilogy(model.temp.residual.aux_M,'.-', 'MarkerSize', 5); grid on;
legend({'Sum of aux\_M'});
subplot(num_figure,1,3);        %%
semilogy(model.temp.residual.aux_h,'.-', 'MarkerSize', 5); grid on;
legend({'Sum of aux\_h'});
subplot(num_figure,1,4);        %%
semilogy(model.temp.residual.h,'.-', 'MarkerSize', 5); grid on;
legend({'Sum of h'});
subplot(num_figure,1,5);        %%
semilogy(model.temp.residual.Pressure_loss, '.-', 'MarkerSize', 5); grid on;
legend({'Sum of Pressure\_loss'});
subplot(num_figure,1,6);        %%
semilogy(model.temp.residual.Power_pump, '.-', 'MarkerSize', 5); grid on;
legend({'Sum of Power\_pump'});
end

%% plot
function myplot_3()
global data model model_fixed;
%%
num_figure = 6;
figure(3); clf;
subplot(num_figure,1,1);         %%
plot(model.record.solution(end).solution.heatingnetwork.Massflow( ...
    data.initialParam.heatingnetwork.num_initialtime+1:end,1)); grid on;
legend({'Massflow'});

subplot(num_figure,1,2);        %%
plot(model.record.solution(end).solution.heatingnetwork.Tau_pipe_s_in(11:end,1)); grid on;
legend({'Tau\_pipe\_s\_in'});

subplot(num_figure,1,3);        %%
plot(model.record.solution(end).solution.heatingnetwork.Tau_pipe_r_out(11:end,1)); grid on;
legend({'Tau\_pipe\_r\_out'});

subplot(num_figure,1,4);        %%
plot(model.record.solution(end).solution.heatingnetwork.h_source( ...
    data.initialParam.heatingnetwork.num_initialtime+1:end,:)); grid on;
legend({'h\_source'});

subplot(num_figure,1,5);        %%
plot(model.record.solution(end).solution.heatingnetwork.h_load(11:end,:)); grid on;
legend({'h\_load'});

subplot(num_figure,1,6);
plot(model.record.solution(end).solution.buildings.Tau_in); grid on;
legend({'Tau\_in'});

%%
num_figure = 6;
figure(4); clf;
subplot(num_figure,1,1);         %%
plot(model_fixed.record.solution(end).solution.heatingnetwork.Massflow( ...
    data.initialParam.heatingnetwork.num_initialtime+1:end,1)); grid on;
legend({'Massflow'});

subplot(num_figure,1,2);        %%
plot(model_fixed.record.solution(end).solution.heatingnetwork.Tau_pipe_s_in(11:end,1)); grid on;
legend({'Tau\_pipe\_s\_in'});

subplot(num_figure,1,3);        %%
plot(model_fixed.record.solution(end).solution.heatingnetwork.Tau_pipe_r_out(11:end,1)); grid on;
legend({'Tau\_pipe\_r\_out'});

subplot(num_figure,1,4);        %%
plot(model_fixed.record.solution(end).solution.heatingnetwork.h_source( ...
    data.initialParam.heatingnetwork.num_initialtime+1:end,:)); grid on;
legend({'h\_source'});

subplot(num_figure,1,5);        %%
plot(model_fixed.record.solution(end).solution.heatingnetwork.h_load(11:end,:), '-', 'LineWidth',2); hold on;
plot(model_fixed.record.solution(end).solution.buildings.h_load/1e3,'-.'); grid on;
legend({'h\_load(DHN)' 'h\_load(buildings)'});

subplot(num_figure,1,6);
plot(model_fixed.record.solution(end).solution.buildings.Tau_in); grid on;
legend({'Tau\_in'});
end



