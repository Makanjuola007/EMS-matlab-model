function create_energy_simulation_excel()
% MATLAB Script to read energy simulation data and export to Excel
% This script reads the simulation parameters and generates Excel output

fprintf('Starting Energy Simulation Data Export to Excel...\n');

%% Simulation Parameters (from your original script)
num_days = 7;
points_per_day = 1000;
time = linspace(0, num_days*86400, points_per_day*num_days);

% Repeat daily patterns over 7 days
t_day = mod(time, 86400);  % Time within a day

%% Generate all signals (same logic as your original script)
fprintf('Generating PV signals...\n');
% PV signals
dcv_pv = 500 * max(0, sin(pi * (t_day / 86400)));
dci_pv = 10 * max(0, sin(pi * (t_day / 86400)));

fprintf('Generating AC load signals...\n');
% AC load side
ac_voltage = 230 + 10*sin(2*pi*t_day/86400);
ac_current = 5 + 2*sin(2*pi*t_day/43200);
ac_power = ac_voltage .* ac_current; % W
ac_freq = 50 + 0.1*sin(2*pi*t_day/86400);

total_energy_gen = cumtrapz(time, ac_power)/3600;  % Wh → kWh
total_power_consumed = ac_power .* (0.6 + 0.4*sin(2*pi*t_day/43200));
total_energy_consumed = cumtrapz(time, total_power_consumed)/3600;

fprintf('Generating grid availability and parameters...\n');
% Grid availability
grid_available = zeros(size(time));
grid_available(t_day >= 6*3600 & t_day < 12*3600) = 1; % 6h ON
grid_available(t_day >= 18*3600 & t_day <= 24*3600) = 1; % 6h ON

% Grid parameters (masked by availability)
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

fprintf('Generating pricing model...\n');
% Pricing model with random hourly price
rng(42);  % For reproducible results
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

fprintf('Generating battery parameters...\n');
% Battery parameters
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

%% Create time stamps for Excel
fprintf('Creating timestamps...\n');
start_date = datetime('now') - days(num_days); % Start 7 days ago
timestamps = start_date + seconds(time);

%% Prepare data for Excel export
fprintf('Preparing data for Excel export...\n');

% Create data table
data_table = table(...
    timestamps', ...
    time', ...
    dcv_pv', ...
    dcv_pv', ...  % DCV_PV2 (same as PV1 in original)
    dci_pv', ...
    dci_pv', ...  % DC_current2 (same as current1 in original)
    ac_voltage', ...
    ac_current', ...
    ac_power', ...
    ac_freq', ...
    total_energy_gen', ...
    total_power_consumed', ...
    total_energy_consumed', ...
    grid_available', ...
    grid_voltage', ...
    grid_current', ...
    grid_reactive_power', ...
    grid_apparent_power', ...
    grid_power_factor', ...
    total_on_grid_gen', ...
    meter_power', ...
    price_signal', ...
    instant_cost', ...
    cumulative_cost', ...
    b_voltage', ...
    b_current', ...
    b_power', ...
    bsoc', ...
    total_energy_charge', ...
    total_energy_discharge', ...
    inverter_temp', ...
    bms_voltage', ...
    bms_current', ...
    load_power', ...
    'VariableNames', {...
        'Timestamp', 'Time_seconds', 'DCV_PV1', 'DCV_PV2', 'DC_current1', 'DC_current2', ...
        'AC_Voltage', 'AC_current', 'AC_outputPOWER', 'AC_freq', 'TotalEnergyGeneration', ...
        'TotalPOWERconsumed', 'TotalconsumptionEnergy', 'GridAvailable', 'GridVoltage', ...
        'Gridcurrent', 'PowergridReactivePower', 'PowergridApparentPower', 'GridPowerFactor', ...
        'TotalOn_gridGeneration', 'meterpower', 'GridPrice_per_kWh', 'InstantCost_per_hour', ...
        'CumulativeCost_USD', 'Bvoltage', 'Bcurrent', 'Bpower', 'Bsoc_percent', ...
        'totalEnergyCharge', 'totalEnergyDisCharge', 'inveterTemp', 'bmsVoltage', 'bmscurrent', 'loadpower'});

%% Create summary statistics
fprintf('Creating summary statistics...\n');
summary_stats = table(...
    {'Total Energy Generated (kWh)'; 'Total Energy Consumed (kWh)'; 'Total Cost ($)'; ...
     'Peak AC Power (W)'; 'Average Grid Price ($/kWh)'; 'Grid Availability (%)'; ...
     'Max Battery SOC (%)'; 'Min Battery SOC (%)'; 'Average Inverter Temp (°C)'}, ...
    {total_energy_gen(end); total_energy_consumed(end); cumulative_cost(end); ...
     max(ac_power); mean(price_signal(price_signal > 0)); mean(grid_available)*100; ...
     max(bsoc); min(bsoc); mean(inverter_temp)}, ...
    'VariableNames', {'Parameter', 'Value'});

%% Export to Excel
excel_filename = sprintf('Energy_Simulation_Data_%s.xlsx', datestr(now, 'yyyymmdd_HHMMSS'));

fprintf('Exporting to Excel file: %s\n', excel_filename);

try
    % Write main data to first sheet
    writetable(data_table, excel_filename, 'Sheet', 'Simulation_Data');
    
    % Write summary to second sheet
    writetable(summary_stats, excel_filename, 'Sheet', 'Summary_Statistics');
    
    % Create hourly averages for easier analysis
    fprintf('Creating hourly averages...\n');
    
    % Resample to hourly data (every 1000/24 ≈ 42 points)
    hourly_indices = 1:42:length(time);  % Approximate hourly sampling
    
    hourly_data = table(...
        timestamps(hourly_indices)', ...
        ac_power(hourly_indices)', ...
        total_power_consumed(hourly_indices)', ...
        grid_available(hourly_indices)', ...
        price_signal(hourly_indices)', ...
        bsoc(hourly_indices)', ...
        meter_power(hourly_indices)', ...
        'VariableNames', {...
            'Timestamp', 'AC_Power_W', 'Power_Consumed_W', 'Grid_Available', ...
            'Grid_Price_per_kWh', 'Battery_SOC_percent', 'Meter_Power_W'});
    
    writetable(hourly_data, excel_filename, 'Sheet', 'Hourly_Data');
    
    fprintf('Successfully exported data to: %s\n', excel_filename);
    fprintf('Excel file contains 3 sheets:\n');
    fprintf('  1. Simulation_Data - All %d data points\n', length(time));
    fprintf('  2. Summary_Statistics - Key metrics\n');
    fprintf('  3. Hourly_Data - Hourly averaged data for analysis\n');
    
    % Display key results
    fprintf('\n=== SIMULATION SUMMARY ===\n');
    fprintf('Total Energy Generated: %.2f kWh\n', total_energy_gen(end));
    fprintf('Total Energy Consumed: %.2f kWh\n', total_energy_consumed(end));
    fprintf('Total Grid Cost: $%.2f\n', cumulative_cost(end));
    fprintf('Average Grid Price: $%.2f/kWh\n', mean(price_signal(price_signal > 0)));
    fprintf('Grid Availability: %.1f%%\n', mean(grid_available)*100);
    fprintf('Peak AC Power: %.0f W\n', max(ac_power));
    fprintf('========================\n\n');
    
catch ME
    fprintf('Error creating Excel file: %s\n', ME.message);
    fprintf('Trying alternative export method...\n');
    
    % Alternative: Save as CSV files if Excel export fails
    csv_filename_data = sprintf('Energy_Simulation_Data_%s.csv', datestr(now, 'yyyymmdd_HHMMSS'));
    csv_filename_summary = sprintf('Energy_Simulation_Summary_%s.csv', datestr(now, 'yyyymmdd_HHMMSS'));
    
    writetable(data_table, csv_filename_data);
    writetable(summary_stats, csv_filename_summary);
    
    fprintf('Data exported to CSV files:\n');
    fprintf('  - %s\n', csv_filename_data);
    fprintf('  - %s\n', csv_filename_summary);
end

fprintf('Energy simulation data export completed!\n');

end

%% Run the function
create_energy_simulation_excel(); 