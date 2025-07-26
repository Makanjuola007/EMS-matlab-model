% Load your weekly Excel file
filename = 'weekly/weekly.xlsx';
data = readtable(filename);

% Assume time is in hours (0 to 168 for a week)
time_hr = data.Time;  % Adjust if your column name is different
power = data.PowerConsumed_W;

% Initialize price vector
price_per_kwh = zeros(size(time_hr));

% Assign prices based on time-of-day
for i = 1:length(time_hr)
    hour_of_day = mod(time_hr(i), 24);  % Get time within 24h cycle
    if hour_of_day >= 8 && hour_of_day < 23
        price_per_kwh(i) = 25.92;  % Daytime price
    else
        price_per_kwh(i) = 13.62;  % Nighttime price
    end
end

% Convert power from W to kW
power_kw = power / 1000;

% Calculate energy consumed in kWh over the time steps
dt = diff(time_hr); 
dt = [dt; dt(end)];  % Ensure equal length
energy_kwh = power_kw .* dt;

% Instantaneous cost and cumulative cost
instant_cost = energy_kwh .* price_per_kwh;
cumulative_cost = cumsum(instant_cost);

% Add to table
data.InstantCost_ = instant_cost;
data.CumulativeCost_ = cumulative_cost;
data.PricePerKwh_ = price_per_kwh;

% Save updated table to Excel
writetable(data, 'weekly_with_cost.xlsx');
disp('Updated file saved as "weekly_with_cost.xlsx"');
