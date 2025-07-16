% Helper script to create sample Solis data structure
% Use this if you need to manually enter your data or understand the format

% Create sample data structure that matches what we expect from Solis Cloud
% You can modify this with your actual values

%% Sample Solis Data Structure
% This shows exactly what format we need

% Time range: 24 hours with 5-minute intervals
start_time = datetime('2024-01-15 00:00:00');
time_interval = minutes(5);
n_points = 24 * 12; % 288 points for 24 hours

% Create timestamps
timestamps = start_time + (0:n_points-1) * time_interval;

% Sample data (replace with your actual values)
% These are example values - you'll need to replace with your Solis data
solar_generation_kW = zeros(n_points, 1);
battery_charge_kW = zeros(n_points, 1);    % Positive = charging
battery_discharge_kW = zeros(n_points, 1); % Positive = discharging  
grid_import_kW = zeros(n_points, 1);       % Positive = importing from grid
grid_export_kW = zeros(n_points, 1);       % Positive = exporting to grid
load_consumption_kW = zeros(n_points, 1);  % Total house consumption

% Create the data table
solis_data = table(timestamps, solar_generation_kW, battery_charge_kW, ...
                   battery_discharge_kW, grid_import_kW, grid_export_kW, ...
                   load_consumption_kW);

% Display sample
fprintf('Sample Solis data structure:\n');
disp(solis_data(1:10, :)); % Show first 10 rows

%% Alternative: Manual data entry helper
% If you have a few key data points, you can enter them manually

fprintf('\n=== Manual Data Entry Helper ===\n');
fprintf('If you can see data in Solis Cloud but cant export:\n');
fprintf('1. Note down values for a few hours (every 30 minutes)\n');
fprintf('2. Look for these values in your Solis dashboard:\n');
fprintf('   - PV Power (kW) = solar generation\n');
fprintf('   - Battery Power (kW) = battery charge/discharge\n');
fprintf('   - Grid Power (kW) = grid import/export\n');
fprintf('   - Load Power (kW) = house consumption\n');
fprintf('3. Enter them in the arrays above\n');

%% What to look for in Solis Cloud
fprintf('\n=== What to Look for in Solis Cloud ===\n');
fprintf('Common field names in Solis Cloud:\n');
fprintf('- Solar: "PV Power", "Solar Generation", "DC Power"\n');
fprintf('- Battery: "Battery Power", "ESS Power", "Storage Power"\n');
fprintf('- Grid: "Grid Power", "AC Power", "Meter Power"\n');
fprintf('- Load: "Load Power", "Consumption", "House Load"\n');
fprintf('- Signs: Watch for +/- signs or different colors\n');
fprintf('  * Green usually = generation/export\n');
fprintf('  * Red usually = consumption/import\n');
fprintf('  * Blue usually = battery\n');

%% Save template
fprintf('\n=== Saving Template ===\n');
filename = 'solis_data_template.csv';
writetable(solis_data, filename);
fprintf('Template saved as: %s\n', filename);
fprintf('You can open this in Excel and fill in your actual data\n');

%% Expected data ranges (for validation)
fprintf('\n=== Expected Data Ranges ===\n');
fprintf('For a 6kW solar + 10kWh battery system:\n');
fprintf('- Solar: 0-6 kW (peak around midday)\n');
fprintf('- Battery: -5 to +5 kW (charge/discharge rate)\n');
fprintf('- Grid: -6 to +6 kW (import/export)\n');
fprintf('- Load: 0.5-5 kW (typical house consumption)\n');
fprintf('- Values should balance: Solar + Grid + Battery = Load\n');