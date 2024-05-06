clc;
warning off;
%% solution process
% % VF
clear all;
FileName = 'Results_testdata_33bus_VF.mat';
load(FileName);
LB = model.record.LB';
UB = model.record.UB';
Obj = model.record.obj';
max_error = model.record.error.max';
GAP1 = model.record.gap.gap1';
GAP2 = model.record.gap.gap2';
GAP3 = model.record.gap.gap3';
FileName = 'Results_testdata_33bus.xlsx';
xlswrite(FileName, [LB UB Obj max_error GAP1 GAP2 GAP3], 1, 'C4:I54');
% % CF
clear all;
FileName = 'Results_testdata_33bus_CF.mat';
load(FileName);
sum = model.record.penalty';
LB = model.record.LB';
UB = model.record.UB';
Obj = model.record.obj';
max_error = model.record.error.max';
GAP1 = model.record.gap.gap1';
GAP2 = model.record.gap.gap2';
GAP3 = model.record.gap.gap3';
FileName = 'Results_testdata_33bus.xlsx';
xlswrite(FileName, [LB UB Obj max_error GAP1 GAP2 GAP3], 1, 'M4:S54');

%% results 
%% socp
% % VF
clear all;
FileName = 'Results_testdata_33bus_VF.mat';
load(FileName);
temp = model;
num = 8;
% % power
power_pcc = temp.record.solution(num).solution.grid.pcc.p(:,1) - ...
     temp.record.solution(num).solution.grid.pcc.p(:,2);
power_gt = temp.record.solution(num).solution.grid.gt.p;
power_res = model.record.solution(num).solution.grid.res.p;
power_es = temp.record.solution(num).solution.grid.es.p_dis - ...
    temp.record.solution(num).solution.grid.es.p_dis;
power_eb = -temp.record.solution(num).solution.grid.eb.p;
power_pump = -temp.record.solution(num).solution.grid.pump.p;
% % heat power
heatpower_gt = temp.record.solution(num).solution.grid.gt.h;
heatpower_eb = temp.record.solution(num).solution.grid.eb.h;
heatpower_tst = temp.record.solution(num).solution.grid.tst.h_dis - ...
    temp.record.solution(num).solution.grid.tst.h_chr;
% % DHN and buildings
heatpower_s = temp.record.solution(num).solution.heatingnetwork.h_source(end-23:end,1);
massflow = temp.record.solution(num).solution.heatingnetwork.Massflow(end-23:end,1);
tau_s = temp.record.solution(num).solution.heatingnetwork.Tau_pipe_s_in(end-23:end,1);
tau_r = temp.record.solution(num).solution.heatingnetwork.Tau_pipe_r_out(end-23:end,1);
tau_in = temp.record.solution(num).solution.buildings.Tau_in;
data_temp = [power_pcc power_gt power_res power_es power_eb power_pump ...
    heatpower_gt heatpower_eb heatpower_tst ...
    heatpower_s massflow tau_s tau_r tau_in];
FileName = 'Results_testdata_33bus.xlsx';
xlswrite(FileName, data_temp, 2, 'C5:S29');
% % CF
clear all;
FileName = 'Results_testdata_33bus_CF.mat';
load(FileName);
temp = model;
num = 10;
% % power
power_pcc = temp.record.solution(num).solution.grid.pcc.p(:,1) - ...
     temp.record.solution(num).solution.grid.pcc.p(:,2);
power_gt = temp.record.solution(num).solution.grid.gt.p;
power_res = model.record.solution(num).solution.grid.res.p;
power_es = temp.record.solution(num).solution.grid.es.p_dis - ...
    temp.record.solution(num).solution.grid.es.p_dis;
power_eb = -temp.record.solution(num).solution.grid.eb.p;
power_pump = -temp.record.solution(num).solution.grid.pump.p;
% % heat power
heatpower_gt = temp.record.solution(num).solution.grid.gt.h;
heatpower_eb = temp.record.solution(num).solution.grid.eb.h;
heatpower_tst = temp.record.solution(num).solution.grid.tst.h_dis - ...
    temp.record.solution(num).solution.grid.tst.h_chr;
% % DHN and buildings
heatpower_s = temp.record.solution(num).solution.heatingnetwork.h_source(end-23:end,1);
massflow = temp.record.solution(num).solution.heatingnetwork.Massflow(end-23:end,1);
tau_s = temp.record.solution(num).solution.heatingnetwork.Tau_pipe_s_in(end-23:end,1);
tau_r = temp.record.solution(num).solution.heatingnetwork.Tau_pipe_r_out(end-23:end,1);
tau_in = temp.record.solution(num).solution.buildings.Tau_in;
data_temp = [power_pcc power_gt power_res power_es power_eb power_pump ...
    heatpower_gt heatpower_eb heatpower_tst ...
    heatpower_s massflow tau_s tau_r tau_in];
FileName = 'Results_testdata_33bus.xlsx';
xlswrite(FileName, data_temp, 2, 'C36:S60');

%% MILP
% % VF
clear all;
FileName = 'Results_testdata_33bus_VF.mat';
load(FileName);
temp = model_fixed;
num = 8;
% % power
power_pcc = temp.record.solution(num).solution.grid.pcc.p(:,1) - ...
     temp.record.solution(num).solution.grid.pcc.p(:,2);
power_gt = temp.record.solution(num).solution.grid.gt.p;
power_res = model.record.solution(num).solution.grid.res.p;
power_es = temp.record.solution(num).solution.grid.es.p_dis - ...
    temp.record.solution(num).solution.grid.es.p_dis;
power_eb = -temp.record.solution(num).solution.grid.eb.p;
power_pump = -temp.record.solution(num).solution.grid.pump.p;
% % heat power
heatpower_gt = temp.record.solution(num).solution.grid.gt.h;
heatpower_eb = temp.record.solution(num).solution.grid.eb.h;
heatpower_tst = temp.record.solution(num).solution.grid.tst.h_dis - ...
    temp.record.solution(num).solution.grid.tst.h_chr;
% % DHN and buildings
heatpower_s = temp.record.solution(num).solution.heatingnetwork.h_source(end-23:end,1);
massflow = temp.record.solution(num).solution.heatingnetwork.Massflow(end-23:end,1);
tau_s = temp.record.solution(num).solution.heatingnetwork.Tau_pipe_s_in(end-23:end,1);
tau_r = temp.record.solution(num).solution.heatingnetwork.Tau_pipe_r_out(end-23:end,1);
tau_in = temp.record.solution(num).solution.buildings.Tau_in;
data_temp = [power_pcc power_gt power_res power_es power_eb power_pump ...
    heatpower_gt heatpower_eb heatpower_tst ...
    heatpower_s massflow tau_s tau_r tau_in];
FileName = 'Results_testdata_33bus.xlsx';
xlswrite(FileName, data_temp, 3, 'C5:S29');
% % CF
clear all;
FileName = 'Results_testdata_33bus_CF.mat';
load(FileName);
temp = model_fixed;
num = 10;
% % power
power_pcc = temp.record.solution(num).solution.grid.pcc.p(:,1) - ...
     temp.record.solution(num).solution.grid.pcc.p(:,2);
power_gt = temp.record.solution(num).solution.grid.gt.p;
power_res = model.record.solution(num).solution.grid.res.p;
power_es = temp.record.solution(num).solution.grid.es.p_dis - ...
    temp.record.solution(num).solution.grid.es.p_dis;
power_eb = -temp.record.solution(num).solution.grid.eb.p;
power_pump = -temp.record.solution(num).solution.grid.pump.p;
% % heat power
heatpower_gt = temp.record.solution(num).solution.grid.gt.h;
heatpower_eb = temp.record.solution(num).solution.grid.eb.h;
heatpower_tst = temp.record.solution(num).solution.grid.tst.h_dis - ...
    temp.record.solution(num).solution.grid.tst.h_chr;
% % DHN and buildings
heatpower_s = temp.record.solution(num).solution.heatingnetwork.h_source(end-23:end,1);
massflow = temp.record.solution(num).solution.heatingnetwork.Massflow(end-23:end,1);
tau_s = temp.record.solution(num).solution.heatingnetwork.Tau_pipe_s_in(end-23:end,1);
tau_r = temp.record.solution(num).solution.heatingnetwork.Tau_pipe_r_out(end-23:end,1);
tau_in = temp.record.solution(num).solution.buildings.Tau_in;
data_temp = [power_pcc power_gt power_res power_es power_eb power_pump ...
    heatpower_gt heatpower_eb heatpower_tst ...
    heatpower_s massflow tau_s tau_r tau_in];
FileName = 'Results_testdata_33bus.xlsx';
xlswrite(FileName, data_temp, 3, 'C36:S60');
