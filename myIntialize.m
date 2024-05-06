function myIntialize(varargin)
if find(strcmp(varargin, 'DisplayTime'))
    DisplayTime = varargin{find(strcmp(varargin, 'DisplayTime'))+1};
else
    DisplayTime = 1;
end
if DisplayTime
    fprintf('%-40s\t\t','- Initilize parameters');
    t0 = clock;
end
%%
global data;
num_initialtime = varargin{1};
interval_heat = varargin{2};
data.initialParam.heatingnetwork.temperature = [data.heatingnetwork.pipe(1,14:15) -5];
data.initialParam.heatingnetwork.massflow = data.heatingnetwork.pipe(:,13)';
data.initialParam.heatingnetwork.num_initialtime = num_initialtime;
data.initialParam.heatingnetwork.pressure_bounds = [100 20];
data.initialParam.buildings.temperature = [18 24 21]; %[18 24 21];
data.interval.heat = interval_heat;
data.BasicParam.Massflow.Density = 1e3;       % kg/m^3
data.BasicParam.Massflow.HeatCapacity = 4.2;  % kJ/(kg¡¤¡æ)
data.BasicParam.pi = 3.1416;
data.BasicParam.gravity = 9.8;                % m/s^2
data.BasicParam.big_M = 2e4;


if DisplayTime
    t1 = clock;
    fprintf('%10.2f%s\n', etime(t1,t0), 's');
end
end