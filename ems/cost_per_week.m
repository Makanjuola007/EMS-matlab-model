%% --- Step 1: Run Simulink Model ---
modelName = 'EnergyMonitoring7days';
simOut = sim(modelName);

% Extract timeseries from base workspace (already created by your script)
InstantCost_ts = evalin('base', 'InstantCost_ts'); % $/hour
LoadPower_ts   = evalin('base', 'loadpower_ts');   % W
GridPrice_ts   = evalin('base', 'GridPrice_ts');   % $/kWh

time_hours = InstantCost_ts.Time / 3600; % convert s → hours
instant_cost = InstantCost_ts.Data;      % actual $/hour
load_power = LoadPower_ts.Data;          % W
grid_price = GridPrice_ts.Data;          % $/kWh

%% --- Step 2: Compute Reference Cost (Grid only, no PV) ---
ref_cost = (load_power / 1000) .* grid_price;  % kW × $/kWh

%% --- Step 3: Monthly grouping ---
hours_in_day = 24;
days_in_week = 7;
days_in_month = [31 28 31 30 31 30 31 31 30 31 30 31]; % adjust for leap if needed

report_data = {};
start_hour = 0;

for m = 1:12
    % Hours in this month
    month_hours = days_in_month(m) * hours_in_day;
    idx = time_hours >= start_hour & time_hours < start_hour + month_hours;

    month_actual_cost = trapz(time_hours(idx), instant_cost(idx));
    month_ref_cost    = trapz(time_hours(idx), ref_cost(idx));

    % Total savings for the month
    month_savings = month_ref_cost - month_actual_cost;

    % Savings per week in this month
    weeks_in_month = days_in_month(m) / days_in_week;
    weekly_saving = month_savings / weeks_in_month;

    report_data{m,1} = datestr(datenum(2025,m,1), 'mmmm'); % Month name
    report_data{m,2} = month_actual_cost;
    report_data{m,3} = weekly_saving;

    start_hour = start_hour + month_hours;
end

%% --- Step 4: Save to Excel ---
T = cell2table(report_data, 'VariableNames', ...
    {'Month', 'Total_Cost_$', 'Weekly_Savings_$'});
writetable(T, 'MonthlyReport.xlsx');

fprintf('Monthly report saved as "MonthlyReport.xlsx"\n');
