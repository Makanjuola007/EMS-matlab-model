% Energy System Simulation for 24 Hours
modelName = 'EnergyMonitoring24h';
new_system(modelName);
open_system(modelName);

set_param(modelName, 'StopTime', '86400');  % 24 hours in seconds

% Create time vector (1000 points over 24 hours)
time = linspace(0, 86400, 1000);

% Sample synthetic profiles for signals
dcv_pv = 500 * max(0, sin(pi * (time / 86400)));
dci_pv = 10 * max(0, sin(pi * (time / 86400)));

ac_voltage = 230 + 10*sin(2*pi*time/86400);
ac_current = 5 + 2*sin(2*pi*time/43200);
ac_power = ac_voltage .* ac_current;
ac_freq = 50 + 0.1*sin(2*pi*time/86400);

total_energy_gen = cumtrapz(time, ac_power)/3600;
total_power_consumed = ac_power .* (0.6 + 0.4*sin(2*pi*time/43200));
total_energy_consumed = cumtrapz(time, total_power_consumed)/3600;

grid_voltage = 240 + 5*sin(2*pi*time/43200);
grid_current = 4 + 2*cos(2*pi*time/43200);
grid_reactive_power = 100 * sin(2*pi*time/43200);
grid_apparent_power = sqrt((grid_voltage.*grid_current).^2 + grid_reactive_power.^2);
grid_power_factor = ac_power ./ (grid_apparent_power + eps);

total_on_grid_gen = ac_power .* (0.5 + 0.5*sin(2*pi*time/86400));
meter_power = total_power_consumed - total_on_grid_gen;

% Battery signals (realistic charge/discharge pattern)
b_voltage = 48 + 0.5 * (mod(time, 21600) < 10800);  % steps up during charge period (6hrs)
b_current = 10 * (mod(time, 43200) < 21600);        % charges 6hrs, discharges 6hrs alternating
b_power = b_voltage .* b_current;
bsoc = 50 + 25 * sin(2*pi*time/86400);              % SOC varies slowly with time

total_energy_charge = cumtrapz(time, max(b_power, 0))/3600;
total_energy_discharge = cumtrapz(time, max(-b_power, 0))/3600;

inverter_temp = 35 + 10*sin(2*pi*time/86400);
bms_voltage = b_voltage + 0.5;
bms_current = b_current;

load_power = total_power_consumed;

% Calculate time of day in seconds
timeofday = mod(time, 86400);

% Energy pricing logic (per second)
rate = zeros(size(time));
rate((timeofday >= 28800) & (timeofday < 82800)) = 25.92;   % 8:00 to 23:00
rate((timeofday < 28800) | (timeofday >= 82800)) = 13.62;   % 23:00 to 8:00

% Energy cost calculation in $/kWh converted to $/Wh, then compute instantaneous cost
cost_per_wh = rate / 1000;
energy_cost = total_power_consumed .* cost_per_wh;
cumulative_energy_cost = cumtrapz(time, energy_cost);

% Define signals
signals = {
    'DCV_PV1', dcv_pv;
    'DCV_PV2', dcv_pv;
    'DC_current1', dci_pv;
    'DC_current2', dci_pv;
    'AC_Voltage', ac_voltage;
    'AC_current', ac_current;
    'AC_ouputPOWER', ac_power;
    'AC_freq', ac_freq;
    'TotalEnergyGeneration', total_energy_gen;
    'TotalPOWERconsumed', total_power_consumed;
    'TotalconsumptionEnergy', total_energy_consumed;
    'GridVoltage', grid_voltage;
    'Gridcurrent', grid_current;
    'PowergridReactivePower', grid_reactive_power;
    'PowergridApparentPower', grid_apparent_power;
    'GridPowerFactor', grid_power_factor;
    'TotalOn_gridGeneration', total_on_grid_gen;
    'meterpower', meter_power;
    'Bvoltage', b_voltage;
    'Bcurrent', b_current;
    'Bpower', b_power;
    'Bsoc', bsoc;
    'totalEnergyCharge', total_energy_charge;
    'totalEnergyDisCharge', total_energy_discharge;
    'inveterTemp', inverter_temp;
    'bmsVoltage', bms_voltage;
    'bmscurrent', bms_current;
    'loadpower', load_power;
    'energyCost', energy_cost;
    'cumulativeEnergyCost', cumulative_energy_cost
};

% Assign each timeseries to base workspace
for i = 1:size(signals, 1)
    ts = timeseries(signals{i,2}, time);
    assignin('base', [signals{i,1} '_ts'], ts);
end

% Create blocks in model
x = 30; y = 30; xOffset = 300; yOffset = 70;
for i = 1:size(signals,1)
    sigName = signals{i,1};
    fromBlock = [modelName '/' sigName '_From'];
    scopeBlock = [modelName '/' sigName '_Scope'];

    add_block('simulink/Sources/From Workspace', fromBlock, ...
        'VariableName', [sigName '_ts'], 'Position', [x, y, x+80, y+30]);

    add_block('simulink/Sinks/Scope', scopeBlock, 'Position', [x+120, y, x+180, y+30]);

    add_line(modelName, [sigName '_From/1'], [sigName '_Scope/1']);

    y = y + yOffset;
    if y > 900
        y = 30;
        x = x + xOffset;
    end
end

save_system(modelName);
open_system(modelName);
