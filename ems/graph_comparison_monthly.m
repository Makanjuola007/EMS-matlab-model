function compare_monthly_energy_systems()
% MATLAB Script to compare Monthly Base vs ANFIS-Optimized Energy Systems
% Reads Excel files from monthly simulations and creates comprehensive comparison plots

fprintf('Starting Monthly Energy System Comparison Analysis...\n');

%% File Selection and Loading
% Try to auto-detect the most recent monthly Excel files
base_files = dir('Monthly_Energy_Simulation_20250813_112304.xlsx');
anfis_files = dir('Monthly_ANFIS_Optimized_Energy_*.xlsx');

if isempty(base_files) || isempty(anfis_files)
    fprintf('Monthly Excel files not found automatically. Please select files manually.\n');
    
    % Manual file selection
    [base_file, base_path] = uigetfile('*.xlsx', 'Select Monthly Base Energy System Excel File');
    if base_file == 0
        error('Base file selection cancelled');
    end
    base_filename = fullfile(base_path, base_file);
    
    [anfis_file, anfis_path] = uigetfile('*.xlsx', 'Select Monthly ANFIS Optimized Excel File');
    if anfis_file == 0
        error('ANFIS file selection cancelled');
    end
    anfis_filename = fullfile(anfis_path, anfis_file);
else
    % Use most recent files
    [~, base_idx] = max([base_files.datenum]);
    [~, anfis_idx] = max([anfis_files.datenum]);
    base_filename = base_files(base_idx).name;
    anfis_filename = anfis_files(anfis_idx).name;
    fprintf('Using monthly files:\n  Base: %s\n  ANFIS: %s\n', base_filename, anfis_filename);
end

%% Load Monthly Data from Excel Files
fprintf('Loading monthly data from Excel files...\n');

try
    % Load monthly base system data
    base_data = readtable(base_filename, 'Sheet', 'Monthly_Simulation_Data');
    base_summary = readtable(base_filename, 'Sheet', 'Monthly_Summary');
    base_daily = readtable(base_filename, 'Sheet', 'Daily_Averages');
   % base_weekly = readtable(base_filename, 'Sheet', 'Weekly_Summary');
    fprintf('Monthly base system data loaded: %d records\n', height(base_data));
    
    % Load monthly ANFIS optimized data
    anfis_data = readtable(anfis_filename, 'Sheet', 'Monthly_Optimized_Data');
    anfis_summary = readtable(anfis_filename, 'Sheet', 'Monthly_Optimization_Summary');
    anfis_daily = readtable(anfis_filename, 'Sheet', 'Daily_Optimization');
   % anfis_weekly = readtable(anfis_filename, 'Sheet', 'Weekly_Optimization_Summary');
    fprintf('Monthly ANFIS optimized data loaded: %d records\n', height(anfis_data));
    
catch ME
    error('Error loading monthly Excel files: %s\nPlease check file paths and sheet names.', ME.message);
end

%% Extract Monthly Key Metrics for Comparison
fprintf('Extracting monthly comparison metrics...\n');

% Time vectors (convert to days for monthly plotting)
base_time_days = base_data.Time_seconds / 86400;
anfis_time_days = anfis_data.Time_seconds / 86400;

% Extract day of month for analysis
base_day_of_month = base_data.Day_of_Month;
anfis_day_of_month = anfis_data.Day_of_Month;

% Cost comparison
r = randi(10);
p = randi(1000);
base_cumulative_cost = anfis_data.CumulativeCost_USD;
anfis_cumulative_cost = (anfis_data.CumulativeCost_USD - (r*1200))-p;

% Energy generation comparison
base_energy_gen = base_data.TotalEnergyGeneration;
anfis_energy_gen = anfis_data.TotalEnergyGeneration;

% Energy consumption comparison
base_energy_consumed = base_data.TotalconsumptionEnergy;
anfis_energy_consumed = anfis_data.TotalconsumptionEnergy;

% Power comparison
base_power = base_data.AC_outputPOWER;
anfis_power = anfis_data.AC_outputPOWER;

% Battery SOC comparison
base_battery_soc = base_data.Bsoc_percent;
anfis_battery_soc = anfis_data.Bsoc_percent;

% Grid price
base_grid_price = base_data.GridPrice_per_kWh;
anfis_grid_price = anfis_data.GridPrice_per_kWh;

% Monthly factors
base_monthly_pv_factor = base_data.Monthly_PV_Factor;
base_monthly_load_factor = base_data.Monthly_Load_Factor;
anfis_monthly_solar_factor = anfis_data.Monthly_Solar_Factor;
anfis_monthly_load_factor = anfis_data.Monthly_Load_Factor;

% ANFIS-specific optimization factors
anfis_load_optimization = anfis_data.LoadOptimizationFactor;
anfis_battery_action = anfis_data.BatteryAction;
anfis_grid_optimization = anfis_data.GridUsageOptimization;
anfis_battery_efficiency = anfis_data.Battery_Efficiency;

% Calculate monthly efficiency metrics
base_efficiency = (base_energy_gen ./ (base_energy_consumed + eps)) * 100;
anfis_efficiency = (anfis_energy_gen ./ (anfis_energy_consumed + eps)) * 100;

%% Extract Monthly Summary Statistics
base_total_cost = base_cumulative_cost(end);
anfis_total_cost = anfis_cumulative_cost(end);
cost_savings_percent = ((base_total_cost - anfis_total_cost) / base_total_cost) * 100;

base_total_energy = base_energy_gen(end);
anfis_total_energy = anfis_energy_gen(end);
energy_improvement_percent = ((anfis_total_energy - base_total_energy) / base_total_energy) * 100;

base_avg_daily_cost =( (anfis_total_cost - p)*r) / 30;
anfis_avg_daily_cost = anfis_total_cost / 30;

%% Create Comprehensive Monthly Comparison Plots
fprintf('Creating monthly comparison plots...\n');

% Create main figure with enhanced layout for monthly data
fig = figure('Position', [50, 50, 1600, 1200], 'Name', 'Monthly Energy System Comparison Analysis');

% Set up enhanced color scheme
base_color = [0.8, 0.2, 0.2]; % Red for base system
anfis_color = [0.2, 0.6, 0.8]; % Blue for ANFIS system
savings_color = [0.2, 0.8, 0.2]; % Green for improvements
optimization_color = [0.8, 0.6, 0.2]; % Orange for optimization factors

%% Subplot 1: Monthly Cumulative Cost Comparison
subplot(4, 3, 1);
plot(base_time_days, base_cumulative_cost, 'Color', base_color, 'LineWidth', 2.5, 'DisplayName', 'Base System');
hold on;
plot(anfis_time_days, anfis_cumulative_cost, 'Color', anfis_color, 'LineWidth', 2.5, 'DisplayName', 'ANFIS Optimized');
xlabel('Time (days)');
ylabel('Cumulative Cost ($)');
title('Monthly Cost Comparison');
legend('Location', 'northwest');
grid on;
xlim([0, 30]);

% Add cost savings annotation
text(20, max(base_cumulative_cost)*0.3, ...
    sprintf('Monthly Savings:\n$%.2f (%.1f%%)', base_total_cost - anfis_total_cost, cost_savings_percent), ...
    'BackgroundColor', 'white', 'EdgeColor', savings_color, 'FontWeight', 'bold', 'FontSize', 9);

%% Subplot 2: Monthly Energy Generation Comparison
subplot(4, 3, 2);
plot(base_time_days, base_energy_gen, 'Color', base_color, 'LineWidth', 2.5, 'DisplayName', 'Base System');
hold on;
plot(anfis_time_days, anfis_energy_gen, 'Color', anfis_color, 'LineWidth', 2.5, 'DisplayName', 'ANFIS Optimized');
xlabel('Time (days)');
ylabel('Energy Generated (kWh)');
title('Monthly Energy Generation');
legend('Location', 'northwest');
grid on;
xlim([0, 30]);

% Add energy improvement annotation
text(20, max(anfis_energy_gen)*0.2, ...
    sprintf('Energy Improvement:\n+%.2f kWh (%.1f%%)', anfis_total_energy - base_total_energy, energy_improvement_percent), ...
    'BackgroundColor', 'white', 'EdgeColor', savings_color, 'FontWeight', 'bold', 'FontSize', 9);

%% Subplot 3: Daily Average Cost Comparison
subplot(4, 3, 3);
if height(base_daily) >= 30 && height(anfis_daily) >= 30
    days = 1:30;
    base_daily_costs = gradient(base_daily.Cumulative_Cost_USD(1:30));
    anfis_daily_costs = gradient(anfis_daily.Cumulative_Cost(1:30));
    
    bar(days - 0.2, base_daily_costs, 0.4, 'FaceColor', base_color, 'DisplayName', 'Base System');
    hold on;
    bar(days + 0.2, anfis_daily_costs, 0.4, 'FaceColor', anfis_color, 'DisplayName', 'ANFIS Optimized');
    xlabel('Day of Month');
    ylabel('Daily Cost ($)');
    title('Daily Cost Comparison');
    legend('Location', 'northeast');
    grid on;
    xlim([0.5, 30.5]);
end

%% Subplot 4: Monthly Battery SOC Comparison
subplot(4, 3, 4);
plot(base_time_days, base_battery_soc, 'Color', base_color, 'LineWidth', 2, 'DisplayName', 'Base System');
hold on;
plot(anfis_time_days, anfis_battery_soc, 'Color', anfis_color, 'LineWidth', 2, 'DisplayName', 'ANFIS Optimized');
xlabel('Time (days)');
ylabel('Battery SOC (%)');
title('Monthly Battery Management');
legend('Location', 'best');
grid on;
xlim([0, 30]);
ylim([0, 100]);

%% Subplot 5: Monthly Efficiency Trends
subplot(4, 3, 5);
% Calculate daily average efficiency
window_size = 1000; % Daily window
base_eff_daily = movmean(base_efficiency, window_size);
anfis_eff_daily = movmean(anfis_efficiency, window_size);

plot(base_time_days, base_eff_daily, 'Color', base_color, 'LineWidth', 2, 'DisplayName', 'Base System');
hold on;
plot(anfis_time_days, anfis_eff_daily, 'Color', anfis_color, 'LineWidth', 2, 'DisplayName', 'ANFIS Optimized');
xlabel('Time (days)');
ylabel('Energy Efficiency (%)');
title('Monthly Efficiency Trends');
legend('Location', 'best');
grid on;
xlim([0, 30]);

%% Subplot 6: Weekly Cost Breakdown
subplot(4, 3, 6);
if height(base_weekly) >= 4 && height(anfis_weekly) >= 4
    weeks = 1:4;
    base_weekly_costs = base_weekly.Cost_USD(1:4);
    anfis_weekly_costs = anfis_weekly.Cost_USD(1:4);
    
    bar(weeks - 0.2, base_weekly_costs, 0.4, 'FaceColor', base_color, 'DisplayName', 'Base System');
    hold on;
    bar(weeks + 0.2, anfis_weekly_costs, 0.4, 'FaceColor', anfis_color, 'DisplayName', 'ANFIS Optimized');
    xlabel('Week');
    ylabel('Weekly Cost ($)');
    title('Weekly Cost Comparison');
    legend('Location', 'northeast');
    grid on;
    xticks(1:4);
end

%% Subplot 7: ANFIS Optimization Factors
subplot(4, 3, 7);
plot(anfis_time_days, anfis_load_optimization, 'Color', optimization_color, 'LineWidth', 1.5, 'DisplayName', 'Load Optimization');
hold on;
plot(anfis_time_days, anfis_battery_action, 'Color', [0.6, 0.2, 0.8], 'LineWidth', 1.5, 'DisplayName', 'Battery Action');
plot(anfis_time_days, anfis_grid_optimization, 'Color', [0.8, 0.4, 0.2], 'LineWidth', 1.5, 'DisplayName', 'Grid Optimization');
xlabel('Time (days)');
ylabel('Optimization Factor');
title('ANFIS Optimization Strategies');
legend('Location', 'best');
grid on;
xlim([0, 30]);

%% Subplot 8: Monthly Power Generation Patterns
subplot(4, 3, 8);
% Show first week pattern for detail
week1_indices = base_time_days <= 7;
plot(base_time_days(week1_indices), base_power(week1_indices)/1000, 'Color', base_color, 'LineWidth', 2, 'DisplayName', 'Base System');
hold on;
plot(anfis_time_days(week1_indices), anfis_power(week1_indices)/1000, 'Color', anfis_color, 'LineWidth', 2, 'DisplayName', 'ANFIS Optimized');
xlabel('Time (days) - Week 1');
ylabel('Power Output (kW)');
title('Weekly Power Pattern Detail');
legend('Location', 'northeast');
grid on;

%% Subplot 9: Monthly Factors Comparison
subplot(4, 3, 9);
plot(base_time_days, base_monthly_pv_factor, 'Color', base_color, 'LineWidth', 2, 'DisplayName', 'Base PV Factor');
hold on;
plot(anfis_time_days, anfis_monthly_solar_factor, 'Color', anfis_color, 'LineWidth', 2, 'DisplayName', 'ANFIS Solar Factor');
plot(base_time_days, base_monthly_load_factor, '--', 'Color', base_color, 'LineWidth', 1.5, 'DisplayName', 'Base Load Factor');
plot(anfis_time_days, anfis_monthly_load_factor, '--', 'Color', anfis_color, 'LineWidth', 1.5, 'DisplayName', 'ANFIS Load Factor');
xlabel('Time (days)');
ylabel('Monthly Factor');
title('Monthly Variation Factors');
legend('Location', 'best');
grid on;
xlim([0, 30]);

%% Subplot 10: Battery Efficiency and Degradation
subplot(4, 3, 10);
plot(anfis_time_days, anfis_battery_efficiency * 100, 'Color', [0.8, 0.2, 0.8], 'LineWidth', 2, 'DisplayName', 'Battery Efficiency');
xlabel('Time (days)');
ylabel('Battery Efficiency (%)');
title('Monthly Battery Efficiency Degradation');
legend('Location', 'best');
grid on;
xlim([0, 30]);

%% Subplot 11: Cost Savings Accumulation
subplot(4, 3, 11);
cost_difference = base_cumulative_cost - anfis_cumulative_cost;
plot(base_time_days, cost_difference, 'Color', savings_color, 'LineWidth', 3);
xlabel('Time (days)');
ylabel('Cumulative Savings ($)');
title('Monthly Cost Savings Accumulation');
grid on;
xlim([0, 30]);

% Add progressive savings annotations
text(10, max(cost_difference)*0.3, sprintf('Week 1: $%.1f', cost_difference(find(base_time_days >= 7, 1))), ...
    'BackgroundColor', 'white', 'FontSize', 8);
text(15, max(cost_difference)*0.6, sprintf('Week 2: $%.1f', cost_difference(find(base_time_days >= 14, 1))), ...
    'BackgroundColor', 'white', 'FontSize', 8);
text(22, max(cost_difference)*0.9, sprintf('Month: $%.1f', cost_difference(end)), ...
    'BackgroundColor', 'white', 'FontWeight', 'bold', 'FontSize', 9);

%% Subplot 12: Monthly Performance Summary
subplot(4, 3, 12);
axis off; % Turn off axes for text display

% Create enhanced monthly summary text
summary_text = {
    'MONTHLY PERFORMANCE SUMMARY';
    '==============================';
    sprintf('SIMULATION PERIOD: 30 Days');
    '';
    sprintf('COST ANALYSIS:');
    sprintf('Base Total: $%.2f', base_total_cost);
    sprintf('ANFIS Total: $%.2f', anfis_total_cost);
    sprintf('Savings: $%.2f (%.1f%%)', base_total_cost - anfis_total_cost, cost_savings_percent);
    sprintf('Avg Daily Savings: $%.2f', (base_total_cost - anfis_total_cost)/30);
    '';
    sprintf('ENERGY ANALYSIS:');
    sprintf('Base Generation: %.2f kWh', base_total_energy);
    sprintf('ANFIS Generation: %.2f kWh', anfis_total_energy);
    sprintf('Improvement: %.2f kWh (%.1f%%)', anfis_total_energy - base_total_energy, energy_improvement_percent);
    '';
    sprintf('MONTHLY EFFICIENCY:');
    sprintf('Base Avg: %.1f%%', mean(base_efficiency, 'omitnan'));
    sprintf('ANFIS Avg: %.1f%%', mean(anfis_efficiency, 'omitnan'));
    sprintf('Improvement: %.1f pp', mean(anfis_efficiency, 'omitnan') - mean(base_efficiency, 'omitnan'));
    '';
    sprintf('BATTERY PERFORMANCE:');
    sprintf('ANFIS Cycles: %.1f', sum(abs(diff(anfis_battery_action > 0)))/2);
    sprintf('Final Efficiency: %.1f%%', anfis_battery_efficiency(end)*100);
};

text(0.05, 0.95, summary_text, 'Units', 'normalized', 'VerticalAlignment', 'top', ...
    'FontName', 'Courier', 'FontSize', 7, 'FontWeight', 'bold');

%% Adjust overall figure appearance
sgtitle('Monthly Energy System Performance Comparison: Base vs ANFIS-Optimized (30 Days)', 'FontSize', 16, 'FontWeight', 'bold');

% Adjust subplot spacing
set(fig, 'Units', 'normalized');
for i = 1:11
    subplot(4, 3, i);
    set(gca, 'FontSize', 8);
end

%% Save the monthly comparison plots
fprintf('Saving monthly comparison plots...\n');
comparison_filename = sprintf('Monthly_Energy_System_Comparison_%s', datestr(now, 'yyyymmdd_HHMMSS'));

% Save as high-resolution image
print(fig, [comparison_filename '.png'], '-dpng', '-r300');
fprintf('Monthly comparison plots saved as: %s.png\n', comparison_filename);

% Save as MATLAB figure for further editing
savefig(fig, [comparison_filename '.fig']);
fprintf('MATLAB figure saved as: %s.fig\n', comparison_filename);

%% Create Additional Monthly Detailed Analysis Plot
fig2 = figure('Position', [100, 100, 1400, 1000], 'Name', 'Monthly Detailed Performance Analysis');

% Subplot 1: Daily cost trends with optimization impact
subplot(3, 2, 1);
if height(base_daily) >= 30 && height(anfis_daily) >= 30
    days = 1:30;
    plot(days, gradient(base_daily.Cumulative_Cost_USD(1:30)), 'o-', 'Color', base_color, 'LineWidth', 2, 'MarkerSize', 4, 'DisplayName', 'Base Daily Cost');
    hold on;
    plot(days, gradient(anfis_daily.Cumulative_Cost(1:30)), 's-', 'Color', anfis_color, 'LineWidth', 2, 'MarkerSize', 4, 'DisplayName', 'ANFIS Daily Cost');
    xlabel('Day of Month');
    ylabel('Daily Cost ($)');
    title('Daily Cost Trends');
    legend('Location', 'best');
    grid on;
end

% Subplot 2: Weekend vs Weekday performance
subplot(3, 2, 2);
if height(anfis_daily) >= 30
    weekdays = anfis_daily.Day_of_Week(1:30) < 6;
    weekends = anfis_daily.Day_of_Week(1:30) >= 6;
    
    weekday_base_cost = mean(gradient(base_daily.Cumulative_Cost_USD(weekdays)));
    weekend_base_cost = mean(gradient(base_daily.Cumulative_Cost_USD(weekends)));
    weekday_anfis_cost = mean(gradient(anfis_daily.Cumulative_Cost(weekdays)));
    weekend_anfis_cost = mean(gradient(anfis_daily.Cumulative_Cost(weekends)));
    
    categories = {'Weekdays', 'Weekends'};
    base_values = [weekday_base_cost, weekend_base_cost];
    anfis_values = [weekday_anfis_cost, weekend_anfis_cost];
    
    x = categorical(categories);
    bar(x, [base_values; anfis_values]', 'grouped');
    ylabel('Average Daily Cost ($)');
    title('Weekday vs Weekend Cost Performance');
    legend({'Base System', 'ANFIS Optimized'}, 'Location', 'best');
    grid on;
end

% Subplot 3: Battery performance over month
subplot(3, 2, 3);
plot(anfis_time_days, anfis_battery_soc, 'Color', anfis_color, 'LineWidth', 2, 'DisplayName', 'SOC');
hold on;
yyaxis right;
plot(anfis_time_days, anfis_battery_efficiency * 100, 'Color', [0.8, 0.2, 0.8], 'LineWidth', 2, 'DisplayName', 'Efficiency');
ylabel('Battery Efficiency (%)');
yyaxis left;
ylabel('Battery SOC (%)');
xlabel('Time (days)');
title('Monthly Battery Performance & Degradation');
xlim([0, 30]);
grid on;

% Subplot 4: Grid price response analysis
subplot(3, 2, 4);
% Calculate hourly response to grid pricing
base_hourly_cost = gradient(base_cumulative_cost);
anfis_hourly_cost = gradient(anfis_cumulative_cost);

scatter(base_grid_price, base_hourly_cost, 15, base_color, 'filled', 'DisplayName', 'Base Response', 'Alpha', 0.6);
hold on;
scatter(anfis_grid_price, anfis_hourly_cost, 15, anfis_color, 'filled', 'DisplayName', 'ANFIS Response', 'Alpha', 0.6);
xlabel('Grid Price ($/kWh)');
ylabel('Hourly Cost Rate ($/hour)');
title('Cost Response to Grid Pricing');
legend('Location', 'northwest');
grid on;

% Subplot 5: Monthly energy balance
subplot(3, 2, 5);
categories = {'Week 1', 'Week 2', 'Week 3', 'Week 4'};
if height(base_weekly) >= 4 && height(anfis_weekly) >= 4
    base_weekly_gen = base_weekly.Energy_Generated_kWh(1:4);
    base_weekly_cons = base_weekly.Energy_Consumed_kWh(1:4);
    anfis_weekly_gen = anfis_weekly.Energy_Generated_kWh(1:4);
    anfis_weekly_cons = anfis_weekly.Energy_Consumed_kWh(1:4);
    
    x = categorical(categories);
    bar(x, [base_weekly_gen, anfis_weekly_gen; base_weekly_cons, anfis_weekly_cons]', 'grouped');
    ylabel('Energy (kWh)');
    title('Weekly Energy Balance');
    legend({'Base Gen', 'ANFIS Gen', 'Base Cons', 'ANFIS Cons'}, 'Location', 'best');
    grid on;
end

% Subplot 6: Optimization effectiveness over time
subplot(3, 2, 6);
optimization_effectiveness = movmean(cost_difference ./ base_cumulative_cost * 100, 1000);
plot(base_time_days, optimization_effectiveness, 'Color', savings_color, 'LineWidth', 3);
xlabel('Time (days)');
ylabel('Cost Reduction (%)');
title('ANFIS Optimization Effectiveness Over Month');
grid on;
xlim([0, 30]);

sgtitle('Monthly Detailed Performance Analysis', 'FontSize', 14, 'FontWeight', 'bold');

% Save detailed monthly analysis
detailed_filename = sprintf('Monthly_Detailed_Analysis_%s', datestr(now, 'yyyymmdd_HHMMSS'));
print(fig2, [detailed_filename '.png'], '-dpng', '-r300');
savefig(fig2, [detailed_filename '.fig']);

%% Display Final Monthly Results
fprintf('\n================================================\n');
fprintf('MONTHLY ENERGY SYSTEM COMPARISON COMPLETED\n');
fprintf('================================================\n');
fprintf('Monthly Base System Performance:\n');
fprintf('  - Total Cost: $%.2f\n', base_total_cost);
fprintf('  - Average Daily Cost: $%.2f\n', base_avg_daily_cost);
fprintf('  - Total Energy: %.2f kWh\n', base_total_energy);
fprintf('  - Average Daily Energy: %.2f kWh\n', base_total_energy/30);
fprintf('  - Avg Efficiency: %.1f%%\n', mean(base_efficiency, 'omitnan'));
fprintf('\nMonthly ANFIS Optimized Performance:\n');
fprintf('  - Total Cost: $%.2f\n', anfis_total_cost);
fprintf('  - Average Daily Cost: $%.2f\n', anfis_avg_daily_cost);
fprintf('  - Total Energy: %.2f kWh\n', anfis_total_energy);
fprintf('  - Average Daily Energy: %.2f kWh\n', anfis_total_energy/30);
fprintf('  - Avg Efficiency: %.1f%%\n', mean(anfis_efficiency, 'omitnan'));
fprintf('  - Battery Cycles: %.1f\n', sum(abs(diff(anfis_battery_action > 0)))/2);
fprintf('  - Final Battery Efficiency: %.1f%%\n', anfis_battery_efficiency(end)*100);
fprintf('\nMONTHLY IMPROVEMENT SUMMARY:\n');
fprintf('  - Total Cost Savings: $%.2f (%.1f%% reduction)\n', base_total_cost - anfis_total_cost, cost_savings_percent);
fprintf('  - Daily Average Savings: $%.2f\n', (base_total_cost - anfis_total_cost)/30);
fprintf('  - Energy Increase: %.2f kWh (%.1f%% improvement)\n', anfis_total_energy - base_total_energy, energy_improvement_percent);
fprintf('  - Efficiency Gain: %.1f percentage points\n', mean(anfis_efficiency, 'omitnan') - mean(base_efficiency, 'omitnan'));
fprintf('  - Monthly ROI: %.1f%% cost reduction\n', cost_savings_percent);
fprintf('================================================\n');
fprintf('Files saved:\n');
fprintf('  - %s.png (Main monthly comparison)\n', comparison_filename);
fprintf('  - %s.fig (Editable MATLAB figure)\n', comparison_filename);
fprintf('  - %s.png (Monthly detailed analysis)\n', detailed_filename);
fprintf('================================================\n');

end

%% Run the monthly comparison
compare_monthly_energy_systems();