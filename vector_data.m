time = (0:300:86400)';  % 5-min intervals over 24h

% Old PV:
% PV = max(0, 2 + 1.5 * sin(2*pi*time/86400));

% New PV with cloud drop:
PV = max(0, 2 + 1.5 * sin(2*pi*time/86400) - 0.8 * sin(4*pi*time/86400));
       % Solar output (daylight)
Load = 2 + 0.5 * sin(2*pi*time/43200);             % Household load
% Old: SOC = 0.5 + ...
SOC = 0.95 * ones(size(time));  % Start full, force grid export
            % Battery State of Charge
Price = 0.20 + 0.15 * sin(2*pi*time/43200);        % Agile price variation

PV_ts = timeseries(PV, time);
Load_ts = timeseries(Load, time);
SOC_ts = timeseries(SOC, time);
Price_ts = timeseries(Price, time);

save('ems_input_data.mat', 'PV_ts', 'Load_ts', 'SOC_ts', 'Price_ts');
load('ems_input_data.mat')
