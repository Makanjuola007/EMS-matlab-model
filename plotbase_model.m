% Load the Excel file

T = readtable('weekly/weekly.xlsx');  % Load the table

time = T.Time;              % Access "Time_hr" column
power = T.PowerConsumed_W;     % Access "PowerConsumed_W" column
cost = T.InstantCost__;         % Access "InstantCost_$" column
cumulative_energy_cost =T.CumulativeCost__;
% Extract 3 columns
%time = data{:,1};       % Column 1: Time
%power = data{:,2};      % Column 2: Power
%cost = data{:,3};       % Column 3: Cost

% Plotting
figure;
%subplot(3,1,1);
plot(time, cumulative_energy_cost, 'b');
title('cumulative vs Time');
xlabel('Time (s)');
ylabel('cumulative');

%subplot(3,1,2);
%plot(time, cost, 'r');
%title('Cost vs Time');
%xlabel('Time (s or hr)');
%ylabel('Instant Cost ($)');

%subplot(3,1,3);
%plot(power, cost, 'g');
%title('Cost vs Power');
%xlabel('Power (W)');
%ylabel('Instant Cost ($)');

%sgtitle('Energy Monitoring Visualization');
