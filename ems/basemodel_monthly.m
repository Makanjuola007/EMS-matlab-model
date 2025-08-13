function create_monthly_energy_simulation_excel()
% MATLAB Script to read energy simulation data and export to Excel
% This script reads the simulation parameters and generates Excel output for a full month

fprintf('Starting Monthly Energy Simulation Data Export to Excel...\n');

%% Simulation Parameters (Updated for Monthly Data)
num_days = 30;  % Changed from 7 to 30 days for a full month
points_per_day = 1000;
time = linspace(0, num_days*86400, points_per_day*num_days);

% Repeat daily patterns over 30 days
t_day = mod(time, 86400);  % Time within a day

% Monthly variation components
day_of_month = floor(time / 86400) + 1;  % Day number (1-30)
monthly_factor = 1 + 0.15 * sin(2*pi * day_of_month / 30);  % ±15% monthly variation

%% Generate all signals with monthly variations
fprintf('Generating PV signals with monthly variations...\n');
% PV signals with seasonal variation (higher mid-month, lower at ends)
base_pv_voltage = 500 * max(0, sin(pi * (t_day / 86400)));
dcv_pv = base_pv_voltage .* monthly_factor;

base_pv_current = 10 * max(0, sin(pi * (t_day / 86400)));
dci_pv = base_pv_current .* monthly_factor;

fprintf('Generating AC load signals with monthly trends...\n');
% AC load side with monthly consumption patterns
monthly_load_factor = 1 + 0.2 * sin(2*pi * day_of_month / 30 + pi/4);  % Peak mid-month
ac_voltage = (230 + 10*sin(2*pi*t_day/86400)) .* (0.95 + 0.1 * monthly_factor);
ac_current = (5 + 2*sin(2*pi*t_day/43200)) .* monthly_load_factor;
ac_power = ac_voltage .* ac_current; % W
ac_freq = 50 + 0.1*sin(2*pi*t_day/86400);

total_energy_gen = cumtrapz(time, ac_power)/3600;  % Wh → kWh
total_power_consumed = ac_power .* (0.6 + 0.4*sin(2*pi*t_day/43200)) .* monthly_load_factor;
total_energy_consumed = cumtrapz(time, total_power_consumed)/3600;

fprintf('Generating grid availability and parameters...\n');
% Grid availability with monthly reliability patterns
base_grid_reliability = 0.95 - 0.1 * sin(2*pi * day_of_month / 30);  % Slightly lower reliability mid-month
grid_available = zeros(size(time));

for i = 1:length(time)
    % Base schedule: 6AM-12PM and 6PM-12AM with monthly reliability variation
    if (t_day(i) >= 6*3600 && t_day(i) < 12*3600) || (t_day(i) >= 18*3600 && t_day(i) <= 24*3600)
        grid_available(i) = rand() < base_grid_reliability(i);
    end
end

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

fprintf('Generating monthly pricing model...\n');
% Pricing model with monthly trends and daily variations
rng(42);  % For reproducible results
min_price = 3;   % $/kWh
max_price = 20;  % $/kWh

% Monthly price trend (higher prices mid-month due to higher demand)
monthly_price_factor = 1 + 0.3 * sin(2*pi * day_of_month / 30);

% Daily price variation (peak pricing during evening hours)
daily_price_factor = 1 + 0.4 * (t_day >= 17*3600 & t_day < 21*3600);  % Peak hours 5-9 PM

% Generate random price signal with monthly and daily components
base_random_price = min_price + (max_price - min_price) * rand(size(time));
grid_price_per_kWh = base_random_price .* monthly_price_factor .* daily_price_factor;

% Apply only when grid is available
price_signal = grid_price_per_kWh .* grid_available;

% Instantaneous cost in $/hour (meter_power in W → kW)
instant_cost = (meter_power / 1000) .* price_signal;

% Ensure no negative costs (no feed-in credit)
instant_cost(instant_cost < 0) = 0;

% Cumulative cost in $ over time
cumulative_cost = cumtrapz(time, instant_cost) / 3600;

fprintf('Generating battery parameters with monthly degradation...\n');
% Battery parameters with monthly capacity degradation
battery_degradation = 1 - 0.02 * (day_of_month / 30);  % 2% capacity loss over the month
b_voltage = (48 + 0.5 * (mod(t_day, 21600) < 10800)) .* battery_degradation;
b_current = 10 * (mod(t_day, 43200) < 21600);
b_power = b_voltage .* b_current;

% SOC with monthly cycling patterns
base_soc = 50 + 25 * sin(2*pi*t_day/86400);
monthly_soc_trend = -5 * (day_of_month / 30);  % Slight capacity decline
bsoc = max(5, base_soc + monthly_soc_trend);  % Minimum 5% SOC

total_energy_charge = cumtrapz(time, max(b_power, 0))/3600;
total_energy_discharge = cumtrapz(time, max(-b_power, 0))/3600;

% Inverter temperature with monthly ambient variation
monthly_temp_variation = 5 * sin(2*pi * day_of_month / 30);  % ±5°C monthly variation
inverter_temp = 35 + 10*sin(2*pi*t_day/86400) + monthly_temp_variation;

bms_voltage = b_voltage + 0.5;
bms_current = b_current;

load_power = total_power_consumed;

%% Create time stamps for Excel
fprintf('Creating timestamps for monthly data...\n');
start_date = datetime('now') - days(num_days); % Start 30 days ago
timestamps = start_date + seconds(time);

%% Prepare data for Excel export
fprintf('Preparing monthly data for Excel export...\n');

% Create data table
data_table = table(...
    timestamps', ...
    time', ...
    day_of_month', ...
    dcv_pv', ...
    dcv_pv', ...  % DCV_PV2 (same as PV1)
    dci_pv', ...
    dci_pv', ...  % DC_current2 (same as current1)
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
    monthly_factor', ...
    monthly_load_factor', ...
    'VariableNames', {...
        'Timestamp', 'Time_seconds', 'Day_of_Month', 'DCV_PV1', 'DCV_PV2', 'DC_current1', 'DC_current2', ...
        'AC_Voltage', 'AC_current', 'AC_outputPOWER', 'AC_freq', 'TotalEnergyGeneration', ...
        'TotalPOWERconsumed', 'TotalconsumptionEnergy', 'GridAvailable', 'GridVoltage', ...
        'Gridcurrent', 'PowergridReactivePower', 'PowergridApparentPower', 'GridPowerFactor', ...
        'TotalOn_gridGeneration', 'meterpower', 'GridPrice_per_kWh', 'InstantCost_per_hour', ...
        'CumulativeCost_USD', 'Bvoltage', 'Bcurrent', 'Bpower', 'Bsoc_percent', ...
        'totalEnergyCharge', 'totalEnergyDisCharge', 'inveterTemp', 'bmsVoltage', 'bmscurrent', 'loadpower', ...
        'Monthly_PV_Factor', 'Monthly_Load_Factor'});

%% Create summary statistics
fprintf('Creating monthly summary statistics...\n');
summary_stats = table(...
    {'Total Energy Generated (kWh)'; 'Total Energy Consumed (kWh)'; 'Total Cost ($)'; ...
     'Peak AC Power (W)'; 'Average Grid Price ($/kWh)'; 'Grid Availability (%)'; ...
     'Max Battery SOC (%)'; 'Min Battery SOC (%)'; 'Average Inverter Temp (°C)'; ...
     'Monthly PV Capacity Factor (%)'; 'Average Daily Generation (kWh)'; 'Average Daily Consumption (kWh)'}, ...
    {total_energy_gen(end); total_energy_consumed(end); cumulative_cost(end); ...
     max(ac_power); mean(price_signal(price_signal > 0)); mean(grid_available)*100; ...
     max(bsoc); min(bsoc); mean(inverter_temp); ...
     mean(monthly_factor)*100; total_energy_gen(end)/num_days; total_energy_consumed(end)/num_days}, ...
    'VariableNames', {'Parameter', 'Value'});

%% Export to Excel
excel_filename = sprintf('Monthly_Energy_Simulation_%s.xlsx', datestr(now, 'yyyymmdd_HHMMSS'));

fprintf('Exporting monthly data to Excel file: %s\n', excel_filename);

try
    % Write main data to first sheet
    writetable(data_table, excel_filename, 'Sheet', 'Monthly_Simulation_Data');
    
    % Write summary to second sheet
    writetable(summary_stats, excel_filename, 'Sheet', 'Monthly_Summary');
    
    % Create daily averages for easier analysis
    fprintf('Creating daily averages...\n');
    
    % Resample to daily data (every 1000 points = 1 day)
    daily_indices = 1:1000:length(time);
    
    daily_data = table(...
        timestamps(daily_indices)', ...
        day_of_month(daily_indices)', ...
        ac_power(daily_indices)', ...
        total_power_consumed(daily_indices)', ...
        mean(reshape(grid_available(1:30000), 1000, 30))', ...  % Daily grid availability average
        price_signal(daily_indices)', ...
        bsoc(daily_indices)', ...
        meter_power(daily_indices)', ...
        cumulative_cost(daily_indices)', ...
        'VariableNames', {...
            'Date', 'Day_of_Month', 'AC_Power_W', 'Power_Consumed_W', 'Daily_Grid_Availability', ...
            'Grid_Price_per_kWh', 'Battery_SOC_percent', 'Meter_Power_W', 'Cumulative_Cost_USD'});
    
    writetable(daily_data, excel_filename, 'Sheet', 'Daily_Averages');
    
    % Create weekly summary
    fprintf('Creating weekly summaries...\n');
    
    week_indices = [1, 7000, 14000, 21000, 28000];  % Start of each week (approx)
    weeks = {'Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5'};
    
    weekly_energy_gen = [];
    weekly_energy_consumed = [];
    weekly_cost = [];
    weekly_avg_price = [];
    
    for w = 1:4  % 4 complete weeks
        week_start = week_indices(w);
        week_end = week_indices(w+1) - 1;
        
        week_energy_gen = total_energy_gen(week_end) - total_energy_gen(week_start);
        week_energy_consumed = total_energy_consumed(week_end) - total_energy_consumed(week_start);
        week_cost = cumulative_cost(week_end) - cumulative_cost(week_start);
        week_prices = price_signal(week_start:week_end);
        week_avg_price = mean(week_prices(week_prices > 0));
        
        weekly_energy_gen(end+1) = week_energy_gen;
        weekly_energy_consumed(end+1) = week_energy_consumed;
        weekly_cost(end+1) = week_cost;
        weekly_avg_price(end+1) = week_avg_price;
    end
    
    weekly_summary = table(...
        weeks(1:4)', ...
        weekly_energy_gen', ...
        weekly_energy_consumed', ...
        weekly_cost', ...
        weekly_avg_price', ...
        'VariableNames', {'Week', 'Energy_Generated_kWh', 'Energy_Consumed_kWh', 'Cost_USD', 'Avg_Price_per_kWh'});
    
    writetable(weekly_summary, excel_filename, 'Sheet', 'Weekly_Summary');
    
    fprintf('Successfully exported monthly data to: %s\n', excel_filename);
    fprintf('Excel file contains 5 sheets:\n');
    fprintf('  1. Monthly_Simulation_Data - All %d data points\n', length(time));
    fprintf('  2. Monthly_Summary - Key monthly metrics\n');
    fprintf('  3. Daily_Averages - Daily averaged data\n');
    fprintf('  4. Weekly_Summary - Weekly totals and averages\n');
    
    % Display key results
    fprintf('\n=== MONTHLY SIMULATION SUMMARY ===\n');
    fprintf('Simulation Period: %d days\n', num_days);
    fprintf('Total Data Points: %d\n', length(time));
    fprintf('Total Energy Generated: %.2f kWh\n', total_energy_gen(end));
    fprintf('Total Energy Consumed: %.2f kWh\n', total_energy_consumed(end));
    fprintf('Total Grid Cost: $%.2f\n', cumulative_cost(end));
    fprintf('Average Daily Generation: %.2f kWh\n', total_energy_gen(end)/num_days);
    fprintf('Average Daily Consumption: %.2f kWh\n', total_energy_consumed(end)/num_days);
    fprintf('Average Grid Price: $%.2f/kWh\n', mean(price_signal(price_signal > 0)));
    fprintf('Monthly Grid Availability: %.1f%%\n', mean(grid_available)*100);
    fprintf('Peak AC Power: %.0f W\n', max(ac_power));
    fprintf('Battery SOC Range: %.1f%% - %.1f%%\n', min(bsoc), max(bsoc));
    fprintf('Inverter Temp Range: %.1f°C - %.1f°C\n', min(inverter_temp), max(inverter_temp));
    fprintf('==================================\n\n');
    
catch ME
    fprintf('Error creating Excel file: %s\n', ME.message);
    fprintf('Trying alternative export method...\n');
    
    % Alternative: Save as CSV files if Excel export fails
    csv_filename_data = sprintf('Monthly_Energy_Simulation_%s.csv', datestr(now, 'yyyymmdd_HHMMSS'));
    csv_filename_summary = sprintf('Monthly_Energy_Summary_%s.csv', datestr(now, 'yyyymmdd_HHMMSS'));
    
    writetable(data_table, csv_filename_data);
    writetable(summary_stats, csv_filename_summary);
    
    fprintf('Data exported to CSV files:\n');
    fprintf('  - %s\n', csv_filename_data);
    fprintf('  - %s\n', csv_filename_summary);
end

fprintf('Monthly energy simulation data export completed!\n');

end

%% Run the function
create_monthly_energy_simulation_excel();