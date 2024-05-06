figure;
num = 4;
subplot(num,1,1);
plot(model.record.solution(end).solution.grid.gt.h + ...
    model.record.solution(end).solution.grid.eb.h + ...
    model.record.solution(end).solution.grid.tst.h_dis - ...
    model.record.solution(end).solution.grid.tst.h_chr);
grid on;
subplot(num,1,2);
plot(model.record.solution(end).solution.heatingnetwork.h_source(11:end,1));
grid on;
subplot(num,1,3);
plot(model.record.solution(end).solution.buildings.h_load);
grid on;
subplot(num,1,4);
plot(model.record.solution(end).solution.buildings.Tau_in);
grid on;

figure;
num = 3;
subplot(num,1,1);
plot(model.record.solution(end).solution.grid.gt.h);
grid on; 
subplot(num,1,2);
plot(model.record.solution(end).solution.grid.eb.h);
grid on;
subplot(num,1,3);
plot(model.record.solution(end).solution.grid.tst.h_dis - ...
    model.record.solution(end).solution.grid.tst.h_chr);
grid on;








