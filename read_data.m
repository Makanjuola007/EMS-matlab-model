% Create a table for export
T = table(time');  % Initialize with time column
T.Properties.VariableNames{1} = 'Time_sec';

% Append all signal data
for i = 1:size(signals, 1)
    T.(signals{i,1}) = signals{i,2}';
end

% Write to Excel
writetable(T, 'EnergyMonitoring_Weekly_Output.xlsx');
