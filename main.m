% Test script for the energy management system
% This creates sample data and runs the baseline simulation

clc; clear; close all;

%% Generate Sample Data (24 hours, 5-minute intervals)
time_step = 5/60; % 5 minutes in hours
n_points = 24 * 60 / 5; % 288 points for 24 hours
time_hours = (0:n_points-1) * time_step;

% Generate realistic solar profile (6kW peak)
solar_data = 6 * max(0, sin(pi * (time_hours - 6) / 12)) .* (time_hours >= 6 & time_hours <= 18);
solar_data = solar_data + 0.1 * randn(size(solar_data)); % Add some noise
solar_data = max(0, solar_data); % Ensure non-negative

% Generate realistic load profile
base_load = 0.5 + 0.3 * sin(2*pi*time_hours/24); % Base consumption
morning_peak = 1.5 * exp(-((time_hours - 7).^2) / 2); % Morning peak
evening_peak = 2.0 * exp(-((time_hours - 19).^2) / 4); % Evening peak
load_data = base_load + morning_peak + evening_peak;
load_data = load_data + 0.1 * randn(size(load_data)); % Add noise
load_data = max(0.2, load_data); % Minimum load

% Generate sample agile pricing (pence/kWh)
% High prices during peak hours, negative during night
base_price = 15; % Base price
peak_multiplier = 2.5 * (sin(2*pi*(time_hours-18)/24) + 1); % Peak around 6pm
night_discount = -10 * (time_hours < 6 | time_hours > 23); % Negative prices at night
price_data = base_price + peak_multiplier + night_discount;
price_data = price_data + 2 * randn(size(price_data)); % Add noise

%% Set up system parameters
params = struct();
params.battery_capacity = 10;        % kWh
params.initial_soc = 0.5;           % 50%
params.max_charge_rate = 5.0;       % kW
params.max_discharge_rate = 5.0;    % kW
params.battery_efficiency = 0.95;
params.time_step = time_step;
params.min_soc = 0.1;               % 10%
params.max_soc = 0.95;              % 95%

% Price thresholds
params.high_price_threshold = 20;    % pence/kWh
params.low_price_threshold = 5;      % pence/kWh
params.export_threshold = 15;        % pence/kWh

%% Run the simulation
fprintf('Running baseline simulation...\n');
results = run_basic_simulation(solar_data, load_data, price_data, params);

%% Plot results
figure('Position', [100, 100, 1200, 800]);

% Plot 1: Power flows
subplot(2,2,1);
plot(time_hours, solar_data, 'g-', 'LineWidth', 2); hold on;
plot(time_hours, load_data, 'r-', 'LineWidth', 2);
plot(time_hours, results.time_series.grid_action, 'b-', 'LineWidth', 1.5);
plot(time_hours, results.time_series.battery_action, 'm-', 'LineWidth', 1.5);
xlabel('Time (hours)');
ylabel('Power (kW)');
title('Power Flows');
legend('Solar', 'Load', 'Grid (+ import)', 'Battery (+ charge)', 'Location', 'best');
grid on;

% Plot 2: Battery SOC
subplot(2,2,2);
plot(time_hours, results.time_series.battery_soc * 100, 'k-', 'LineWidth', 2);
xlabel('Time (hours)');
ylabel('Battery SOC (%)');
title('Battery State of Charge');
ylim([0 100]);
grid on;

% Plot 3: Electricity prices
subplot(2,2,3);
plot(time_hours, price_data, 'c-', 'LineWidth', 2);
xlabel('Time (hours)');
ylabel('Price (pence/kWh)');
title('Electricity Prices');
grid on;

% Plot 4: Cumulative cost
cumulative_cost = cumsum(max(0, results.time_series.grid_action) .* price_data * time_step);
cumulative_income = cumsum(max(0, -results.time_series.grid_action) .* price_data * time_step * 0.5);
net_cumulative = cumulative_cost - cumulative_income;

subplot(2,2,4);
plot(time_hours, cumulative_cost/100, 'r-', 'LineWidth', 2); hold on;
plot(time_hours, cumulative_income/100, 'g-', 'LineWidth', 2);
plot(time_hours, net_cumulative/100, 'b-', 'LineWidth', 2);
xlabel('Time (hours)');
ylabel('Cost (£)');
title('Cumulative Costs');
legend('Import Cost', 'Export Income', 'Net Cost', 'Location', 'best');
grid on;

%% Save results
save('baseline_simulation_results.mat', 'results', 'solar_data', 'load_data', 'price_data', 'params', 'time_hours');

fprintf('\nSimulation complete! Results saved to baseline_simulation_results.mat\n');
fprintf('Check the plots to verify the system behavior.\n');

%% Analysis of key decisions
fprintf('\n=== Decision Analysis ===\n');
decision_types = {};
for i = 1:length(results.time_series.decisions)
    decision_types{i} = results.time_series.decisions{i}.action;
end

unique_decisions = unique(decision_types);
for i = 1:length(unique_decisions)
    count = sum(strcmp(decision_types, unique_decisions{i}));
    fprintf('%s: %d times (%.1f%%)\n', unique_decisions{i}, count, count/length(decision_types)*100);
end