% Energy System Simulation for 1 Week with Grid Availability & Pricing
modelName = 'EnergyMonitoring7days';
new_system(modelName);
open_system(modelName);

set_param(modelName, 'StopTime', num2str(7*86400));  % 7 days in seconds

% Create time vector (1000 points per day × 7 days)
points_per_day = 1000;
time = linspace(0, 7*86400, points_per_day*7);

%% Repeat daily patterns over 7 days
t_day = mod(time, 86400);  % Time within a day

%% PV signals
dcv_pv = 500 * max(0, sin(pi * (t_day / 86400)));
dci_pv = 10 * max(0, sin(pi * (t_day / 86400)));

%% AC load side
ac_voltage = 230 + 10*sin(2*pi*t_day/86400);
ac_current = 5 + 2*sin(2*pi*t_day/43200);
ac_power = ac_voltage .* ac_current; % W
ac_freq = 50 + 0.1*sin(2*pi*t_day/86400);

total_energy_gen = cumtrapz(time, ac_power)/3600;  % Wh → kWh
total_power_consumed = ac_power .* (0.6 + 0.4*sin(2*pi*t_day/43200));
total_energy_consumed = cumtrapz(time, total_power_consumed)/3600;

%% Grid availability
grid_available = zeros(size(time));
grid_available(t_day >= 6*3600 & t_day < 12*3600) = 1; % 6h ON
grid_available(t_day >= 18*3600 & t_day <= 24*3600) = 1; % 6h ON

%% Grid parameters (masked by availability)
grid_voltage_base = 240 + 5*sin(2*pi*t_day/43200);
grid_current_base = 4 + 2*cos(2*pi*t_day/43200);
grid_reactive_power_base = 100 * sin(2*pi*t_day/43200);

grid_voltage = grid_voltage_base .* grid_available;
grid_current = grid_current_base .* grid_available;
grid_reactive_power = grid_reactive_power_base .* grid_available;

grid_apparent_power = sqrt((grid_voltage .* grid_current).^2 + grid_reactive_power.^2);
grid_power_factor = (grid_apparent_power > 0) .* (ac_power ./ (grid_apparent_power + eps));

total_on_grid_gen = ac_power .* (0.5 + 0.5*sin(2*pi*t_day/86400)) .* grid_available;
meter_power = total_power_consumed - total_on_grid_gen; % W

%% --- Pricing model with random hourly price ---
rng('shuffle');  % Different random prices each run; replace with rng(N) for repeatable
min_price = 3;   % $/kWh
max_price = 20;  % $/kWh

% Generate random price signal
grid_price_per_kWh = min_price + (max_price - min_price) * rand(size(time));

% Apply only when grid is available
price_signal = grid_price_per_kWh .* grid_available;

% Instantaneous cost in $/hour (meter_power in W → kW)
instant_cost = (meter_power / 1000) .* price_signal;

% Ensure no negative costs (no feed-in credit)
instant_cost(instant_cost < 0) = 0;

% Cumulative cost in $ over time
cumulative_cost = cumtrapz(time, instant_cost) / 3600;

fprintf('Min price this week: $%.2f, Max price: $%.2f\n', min(price_signal), max(price_signal));
fprintf('Total cost over 1 week: $%.2f\n', cumulative_cost(end));

%% Battery parameters
b_voltage = 48 + 0.5 * (mod(t_day, 21600) < 10800);
b_current = 10 * (mod(t_day, 43200) < 21600);
b_power = b_voltage .* b_current;
bsoc = 50 + 25 * sin(2*pi*t_day/86400);

total_energy_charge = cumtrapz(time, max(b_power, 0))/3600;
total_energy_discharge = cumtrapz(time, max(-b_power, 0))/3600;

inverter_temp = 35 + 10*sin(2*pi*t_day/86400);
bms_voltage = b_voltage + 0.5;
bms_current = b_current;

load_power = total_power_consumed;

%% Define signals
signals = {
    'DCV_PV1', dcv_pv;
    'DCV_PV2', dcv_pv;
    'DC_current1', dci_pv;
    'DC_current2', dci_pv;
    'AC_Voltage', ac_voltage;
    'AC_current', ac_current;
    'AC_outputPOWER', ac_power;
    'AC_freq', ac_freq;
    'TotalEnergyGeneration', total_energy_gen;
    'TotalPOWERconsumed', total_power_consumed;
    'TotalconsumptionEnergy', total_energy_consumed;
    'GridAvailable', grid_available;
    'GridVoltage', grid_voltage;
    'Gridcurrent', grid_current;
    'PowergridReactivePower', grid_reactive_power;
    'PowergridApparentPower', grid_apparent_power;
    'GridPowerFactor', grid_power_factor;
    'TotalOn_gridGeneration', total_on_grid_gen;
    'meterpower', meter_power;
    'GridPrice', price_signal;          % $/kWh
    'InstantCost', instant_cost;        % $/hour
    'CumulativeCost', cumulative_cost;  % $
    'Bvoltage', b_voltage;
    'Bcurrent', b_current;
    'Bpower', b_power;
    'Bsoc', bsoc;
    'totalEnergyCharge', total_energy_charge;
    'totalEnergyDisCharge', total_energy_discharge;
    'inveterTemp', inverter_temp;
    'bmsVoltage', bms_voltage;
    'bmscurrent', bms_current;
    'loadpower', load_power
};

%% Assign timeseries to workspace
for i = 1:size(signals, 1)
    ts = timeseries(signals{i,2}, time);
    assignin('base', [signals{i,1} '_ts'], ts);
end

%% Auto-create blocks in Simulink
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
