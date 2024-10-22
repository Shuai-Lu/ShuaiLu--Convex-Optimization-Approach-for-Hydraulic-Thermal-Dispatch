function model_couplingrelationship(varargin)
if find(strcmp(varargin, 'DisplayTime'))
    DisplayTime = varargin{find(strcmp(varargin, 'DisplayTime'))+1};
else
    DisplayTime = 1;
end
if DisplayTime
    fprintf('%-40s\t\t','- Model coupling relationship');
    t0 = clock;
end
%%
global data model;
model.cons = model.cons + (( ...
    model.var.grid.pump.p == ...
    model.var.heatingnetwork.Power_pump(1 + ...
    data.initialParam.heatingnetwork.num_initialtime:end, :)) : '');

model.cons = model.cons + (( ...
    sum(model.var.grid.gt.h, 2) + ...
    sum(model.var.grid.eb.h, 2) + ...
    sum(model.var.grid.tst.h_dis, 2) - ...
    sum(model.var.grid.tst.h_chr, 2) == ...
    1e3*model.var.heatingnetwork.h_source(1 + ...
    data.initialParam.heatingnetwork.num_initialtime:end, :)) : '');

model.cons = model.cons + (( ...
    1e3*model.var.heatingnetwork.h_load(1 + ...
    data.initialParam.heatingnetwork.num_initialtime:end, :) == ...
    model.var.buildings.h_load) : '');

%%
if DisplayTime
    t1 = clock;
    fprintf('%10.2f%s\n', etime(t1,t0), 's');
end
end