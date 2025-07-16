function results = run_basic_simulation(solar_data, load_data, price_data, params)
    % Run a basic energy system simulation
    % Inputs:
    %   solar_data: Array of solar generation values (kW)
    %   load_data: Array of load demand values (kW)
    %   price_data: Array of electricity prices (pence/kWh)
    %   params: System parameters structure
    %
    % Output:
    %   results: Structure with simulation results
    
    % Validate inputs
    n_points = length(solar_data);
    if length(load_data) ~= n_points || length(price_data) ~= n_points
        error('All input arrays must have the same length');
    end
    
    % Initialize system parameters
    if nargin < 4
        params = struct();
    end
    
    % Default system parameters
    params.battery_capacity = getfield_default(params, 'battery_capacity', 10); % kWh
    params.initial_soc = getfield_default(params, 'initial_soc', 0.5);         % 50%
    params.max_charge_rate = getfield_default(params, 'max_charge_rate', 5.0);
    params.max_discharge_rate = getfield_default(params, 'max_discharge_rate', 5.0);
    params.battery_efficiency = getfield_default(params, 'battery_efficiency', 0.95);
    params.time_step = getfield_default(params, 'time_step', 5/60); % 5 minutes in hours
    
    % Initialize result arrays
    battery_soc = zeros(n_points, 1);
    battery_action = zeros(n_points, 1);
    grid_action = zeros(n_points, 1);
    decisions = cell(n_points, 1);
    
    % Initialize battery state
    current_soc = params.initial_soc;
    
    % Main simulation loop
    for i = 1:n_points
        % Store current SOC
        battery_soc(i) = current_soc;
        
        % Run energy balance decision
        [batt_action, grid_action(i), decision] = energy_balance_solis(...
            solar_data(i), load_data(i), current_soc, price_data(i), params);
        
        battery_action(i) = batt_action;
        decisions{i} = decision;
        
        % Update battery SOC
        if batt_action > 0
            % Charging
            energy_stored = batt_action * params.time_step * params.battery_efficiency;
            current_soc = min(params.max_soc, current_soc + energy_stored / params.battery_capacity);
        elseif batt_action < 0
            % Discharging
            energy_used = -batt_action * params.time_step / params.battery_efficiency;
            current_soc = max(params.min_soc, current_soc - energy_used / params.battery_capacity);
        end
        
        % Ensure SOC stays within bounds
        current_soc = max(params.min_soc, min(params.max_soc, current_soc));
    end
    
    % Calculate financial metrics
    grid_import = max(0, grid_action);
    grid_export = max(0, -grid_action);
    
    import_cost = sum(grid_import .* price_data .* params.time_step);
    export_income = sum(grid_export .* price_data .* params.time_step * 0.5); % Assume 50% export rate
    
    net_cost = import_cost - export_income;
    
    % Calculate energy metrics
    total_solar = sum(solar_data .* params.time_step);
    total_load = sum(load_data .* params.time_step);
    total_grid_import = sum(grid_import .* params.time_step);
    total_grid_export = sum(grid_export .* params.time_step);
    
    self_consumption_rate = 1 - (total_grid_export / total_solar);
    grid_independence = 1 - (total_grid_import / total_load);
    
    % Package results
    results = struct();
    results.time_series = struct();
    results.time_series.battery_soc = battery_soc;
    results.time_series.battery_action = battery_action;
    results.time_series.grid_action = grid_action;
    results.time_series.grid_import = grid_import;
    results.time_series.grid_export = grid_export;
    results.time_series.decisions = decisions;
    
    results.financial = struct();
    results.financial.import_cost = import_cost;
    results.financial.export_income = export_income;
    results.financial.net_cost = net_cost;
    results.financial.daily_cost = net_cost / (n_points * params.time_step / 24);
    
    results.energy = struct();
    results.energy.total_solar = total_solar;
    results.energy.total_load = total_load;
    results.energy.total_grid_import = total_grid_import;
    results.energy.total_grid_export = total_grid_export;
    results.energy.self_consumption_rate = self_consumption_rate;
    results.energy.grid_independence = grid_independence;
    
    results.params = params;
    
    % Display summary
    fprintf('\n=== Simulation Results ===\n');
    fprintf('Simulation period: %.1f hours\n', n_points * params.time_step);
    fprintf('Total solar generation: %.2f kWh\n', total_solar);
    fprintf('Total load consumption: %.2f kWh\n', total_load);
    fprintf('Grid import: %.2f kWh\n', total_grid_import);
    fprintf('Grid export: %.2f kWh\n', total_grid_export);
    fprintf('Self-consumption rate: %.1f%%\n', self_consumption_rate * 100);
    fprintf('Grid independence: %.1f%%\n', grid_independence * 100);
    fprintf('Import cost: £%.2f\n', import_cost / 100);
    fprintf('Export income: £%.2f\n', export_income / 100);
    fprintf('Net cost: £%.2f\n', net_cost / 100);
    fprintf('Daily cost: £%.2f\n', results.financial.daily_cost / 100);
end

function value = getfield_default(struct_var, field_name, default_value)
    % Helper function to get field with default value
    if isfield(struct_var, field_name)
        value = struct_var.(field_name);
    else
        value = default_value;
    end
end