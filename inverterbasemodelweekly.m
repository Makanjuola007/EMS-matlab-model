% Energy System Simulation for 1 Week (7 days)
modelName = 'EnergyMonitoring_Weekly';
new_system(modelName);
open_system(modelName);

set_param(modelName, 'StopTime', '604800');  % 7 days in seconds

% Create time vector (7000 points over 7 days)
time = linspace(0, 604800, 7000);  % finer resolution for weekly sim

% Sample synthetic profiles for signals
dcv_pv = 500 * max(0, sin(pi * mod(time, 86400) / 86400));  % repeats daily
dci_pv = 10 * max(0, sin(pi * mod(time, 86400) / 86400));

ac_voltage = 230 + 10*sin(2*pi*mod(time, 86400)/86400);
ac_current = 5 + 2*sin(2*pi*mod(time, 43200)/43200);
ac_power = ac_voltage .* ac_current;
ac_freq = 50 + 0.1*sin(2*pi*mod(time, 86400)/86400);

total_energy_gen = cumtrapz(time, ac_power)/3600;
total_power_consumed = ac_power .* (0.6 + 0.4*sin(2*pi*mod(time, 43200)/43200));
total_energy_consumed = cumtrapz(time, total_power_consumed)/3600;

grid_voltage = 240 + 5*sin(2*pi*mod(time, 43200)/43200);
grid_current = 4 + 2*cos(2*pi*mod(time, 43200)/43200);
grid_reactive_power = 100 * sin(2*pi*mod(time, 43200)/43200);
grid_apparent_power = sqrt((grid_voltage.*grid_current).^2 + grid_reactive_power.^2);
grid_power_factor = ac_power ./ (grid_apparent_power + eps);

total_on_grid_gen = ac_power .* (0.5 + 0.5*sin(2*pi*mod(time, 86400)/86400));
meter_power = total_power_consumed - total_on_grid_gen;

% Battery signals (realistic charge/discharge pattern)
b_voltage = 48 + 0.5 * (mod(time, 21600) < 10800);  % step pattern daily
b_current = 10 * (mod(time, 43200) < 21600);        % 6hr charge/discharge daily
b_power = b_voltage .* b_current;
bsoc = 50 + 25 * sin(2*pi*time/604800);             % slow weekly SOC variation

total_energy_charge = cumtrapz(time, max(b_power, 0))/3600;
total_energy_discharge = cumtrapz(time, max(-b_power, 0))/3600;

inverter_temp = 35 + 10*sin(2*pi*mod(time, 86400)/86400);
bms_voltage = b_voltage + 0.5;
bms_current = b_current;

load_power = total_power_consumed;

%% 🔌 COST CALCULATION BASED ON TIME-OF-DAY PRICING
% ₦25.92 per kWh from 08:00 to 23:00
% ₦13.62 per kWh from 23:00 to 08:00

% Convert power to kW and time step to hours
power_kw = total_power_consumed / 1000;
dt = diff(time) / 3600; 
dt = [dt, dt(end)];  % Ensure dt matches length

% Determine hourly price per kWh
price_per_kwh = zeros(size(time));
for i = 1:length(time)
    hour_of_day = mod(time(i), 86400) / 3600;  % Time in hours within the day
    if hour_of_day >= 8 && hour_of_day < 23
        price_per_kwh(i) = 25.92;  % Day rate
    else
        price_per_kwh(i) = 13.62;  % Night rate
    end
end

% Compute energy consumed at each time step
energy_kwh = power_kw .* dt;

% Compute cost
instant_cost = energy_kwh .* price_per_kwh;
cumulative_cost = cumsum(instant_cost);

%% 📦 Define all signals (including cost-related ones)
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
    'PricePerKwh', price_per_kwh;
    'InstantCost', instant_cost;
    'CumulativeCost', cumulative_cost
};

%% ⏺ Push all timeseries to base workspace
for i = 1:size(signals, 1)
    ts = timeseries(signals{i,2}, time);
    assignin('base', [signals{i,1} '_ts'], ts);
end

%% 🧱 Create Simulink Blocks for All Signals
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

%% 💾 Save and open model
save_system(modelName);
open_system(modelName);
