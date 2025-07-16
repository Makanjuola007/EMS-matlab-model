function solis_data = import_solis_xlsx('C:\Users\dogba\Downloads\SolarData\Weekly\110F8018C040004-2022-08-29_2022-09-04-1676559547180.xlsx')
    % Import and process Solis data from XLSX file
    % Input: filename - path to your Solis XLSX file
    % Output: solis_data - processed table with standardized column names
    
    fprintf('Importing Solis data from: %s\n', filename);
    
    % Read the XLSX file
    try
        [~, sheets] = xlsfinfo(filename);
        fprintf('Found %d sheets: %s\n', length(sheets), strjoin(sheets, ', '));
        
        % Usually data is in the first sheet, but let's check
        if length(sheets) > 1
            fprintf('Using first sheet: %s\n', sheets{1});
        end
        
        % Read the data
        raw_data = readtable(filename, 'Sheet', 1);
        fprintf('Raw data size: %d rows x %d columns\n', height(raw_data), width(raw_data));
        
        % Display first few rows to understand structure
        fprintf('\nFirst 5 rows of raw data:\n');
        disp(raw_data(1:min(5, height(raw_data)), :));
        
        % Display column names
        fprintf('\nColumn names found:\n');
        for i = 1:width(raw_data)
            fprintf('%d: %s\n', i, raw_data.Properties.VariableNames{i});
        end
        
    catch ME
        fprintf('Error reading XLSX file: %s\n', ME.message);
        fprintf('Make sure the file path is correct and the file is not open in Excel\n');
        solis_data = table();
        return;
    end
    
    % Process and standardize the data
    solis_data = standardize_solis_data(raw_data);
    
    if ~isempty(solis_data)
        fprintf('\nProcessed data summary:\n');
        fprintf('Date range: %s to %s\n', ...
            datestr(min(solis_data.timestamp)), datestr(max(solis_data.timestamp)));
        fprintf('Total data points: %d\n', height(solis_data));
        fprintf('Time interval: %.1f minutes\n', ...
            minutes(solis_data.timestamp(2) - solis_data.timestamp(1)));
        
        % Display final structure
        fprintf('\nFinal data structure:\n');
        disp(solis_data(1:min(5, height(solis_data)), :));
    end
end

function processed_data = standardize_solis_data(raw_data)
    % Standardize column names and data format
    % This function tries to automatically detect common Solis column names
    
    processed_data = table();
    
    % Get column names (convert to lower case for easier matching)
    col_names = lower(raw_data.Properties.VariableNames);
    
    % Try to find timestamp column
    timestamp_col = find_column(col_names, {'time', 'date', 'timestamp', 'datetime'});
    if isempty(timestamp_col)
        fprintf('ERROR: Could not find timestamp column\n');
        fprintf('Available columns: %s\n', strjoin(raw_data.Properties.VariableNames, ', '));
        return;
    end
    
    % Extract and convert timestamp
    timestamp_data = raw_data{:, timestamp_col};
    if isnumeric(timestamp_data)
        % Excel serial date numbers
        timestamps = datetime(timestamp_data, 'ConvertFrom', 'excel');
    elseif isdatetime(timestamp_data)
        timestamps = timestamp_data;
    elseif ischar(timestamp_data) || isstring(timestamp_data)
        % Try to parse as datetime
        try
            timestamps = datetime(timestamp_data);
        catch
            fprintf('ERROR: Could not parse timestamp format\n');
            return;
        end
    else
        fprintf('ERROR: Unknown timestamp format\n');
        return;
    end
    
    % Find solar generation column
    solar_col = find_column(col_names, {'pv', 'solar', 'generation', 'dc'});
    if ~isempty(solar_col)
        solar_generation_kW = raw_data{:, solar_col};
    else
        fprintf('WARNING: Solar generation column not found\n');
        solar_generation_kW = zeros(height(raw_data), 1);
    end
    
    % Find battery column
    battery_col = find_column(col_names, {'battery', 'ess', 'storage', 'batt'});
    if ~isempty(battery_col)
        battery_power_kW = raw_data{:, battery_col};
    else
        fprintf('WARNING: Battery column not found\n');
        battery_power_kW = zeros(height(raw_data), 1);
    end
    
    % Find grid column
    grid_col = find_column(col_names, {'grid', 'meter', 'ac', 'mains'});
    if ~isempty(grid_col)
        grid_power_kW = raw_data{:, grid_col};
    else
        fprintf('WARNING: Grid column not found\n');
        grid_power_kW = zeros(height(raw_data), 1);
    end
    
    % Find load/consumption column
    load_col = find_column(col_names, {'load', 'consumption', 'demand', 'house'});
    if ~isempty(load_col)
        load_consumption_kW = raw_data{:, load_col};
    else
        fprintf('WARNING: Load column not found - calculating from energy balance\n');
        % Calculate load from energy balance: Load = Solar + Grid + Battery
        load_consumption_kW = solar_generation_kW + grid_power_kW + battery_power_kW;
    end
    
    % Create standardized table
    processed_data = table(timestamps, solar_generation_kW, battery_power_kW, ...
                          grid_power_kW, load_consumption_kW, ...
                          'VariableNames', {'timestamp', 'solar_generation_kW', ...
                          'battery_power_kW', 'grid_power_kW', 'load_consumption_kW'});
    
    % Remove any rows with invalid timestamps
    valid_rows = ~isnat(processed_data.timestamp);
    processed_data = processed_data(valid_rows, :);
    
    % Sort by timestamp
    processed_data = sortrows(processed_data, 'timestamp');
    
    % Basic data validation
    fprintf('\nData validation:\n');
    fprintf('Solar range: %.2f to %.2f kW\n', min(solar_generation_kW), max(solar_generation_kW));
    fprintf('Battery range: %.2f to %.2f kW\n', min(battery_power_kW), max(battery_power_kW));
    fprintf('Grid range: %.2f to %.2f kW\n', min(grid_power_kW), max(grid_power_kW));
    fprintf('Load range: %.2f to %.2f kW\n', min(load_consumption_kW), max(load_consumption_kW));
    
    % Check for missing data
    missing_data = sum(isnan(processed_data{:, 2:end}));
    if any(missing_data > 0)
        fprintf('WARNING: Missing data found:\n');
        var_names = processed_data.Properties.VariableNames(2:end);
        for i = 1:length(missing_data)
            if missing_data(i) > 0
                fprintf('  %s: %d missing values\n', var_names{i}, missing_data(i));
            end
        end
    end
end

function col_idx = find_column(col_names, search_terms)
    % Find column index that contains any of the search terms
    col_idx = [];
    
    for i = 1:length(col_names)
        col_name = col_names{i};
        for j = 1:length(search_terms)
            if contains(col_name, search_terms{j})
                col_idx = i;
                return;
            end
        end
    end
end

% Usage example:
% Place your XLSX file in the same directory as this script
% solis_data = import_solis_xlsx('your_solis_file.xlsx');

% Quick test with sample filename
fprintf('=== SOLIS XLSX IMPORTER ===\n');
fprintf('Usage: solis_data = import_solis_xlsx(''your_file.xlsx'')\n');
fprintf('Make sure your XLSX file is in the MATLAB current directory\n');
fprintf('Or provide the full path to the file\n\n');

fprintf('Common Solis column names to look for:\n');
fprintf('- Timestamp: Time, Date, DateTime\n');
fprintf('- Solar: PV Power, Solar Generation, DC Power\n');
fprintf('- Battery: Battery Power, ESS Power, Storage Power\n');
fprintf('- Grid: Grid Power, Meter Power, AC Power\n');
fprintf('- Load: Load Power, Consumption, House Load\n');