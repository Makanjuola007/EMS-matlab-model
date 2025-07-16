function [battery_action, grid_action, decisions] = energy_balance_solis(solar_gen, load_demand, battery_soc, electricity_price, params)
    % Energy balance function replicating Solis optimal income mode
    % Inputs:
    %   solar_gen: Solar generation in kW
    %   load_demand: Household demand in kW  
    %   battery_soc: Battery state of charge (0-1)
    %   electricity_price: Current electricity price in pence/kWh
    %   params: Structure with system parameters
    %
    % Outputs:
    %   battery_action: Positive = charge, Negative = discharge (kW)
    %   grid_action: Positive = import, Negative = export (kW)
    %   decisions: Structure with decision reasoning
    
    % Default parameters if not provided
    if nargin < 5
        params = struct();
    end
    
    % System parameters (adjust based on your system)
    max_charge_rate = getfield_default(params, 'max_charge_rate', 5.0);     % kW
    max_discharge_rate = getfield_default(params, 'max_discharge_rate', 5.0); % kW
    min_soc = getfield_default(params, 'min_soc', 0.1);                     % 10%
    max_soc = getfield_default(params, 'max_soc', 0.95);                    % 95%
    
    % Price thresholds (tune these based on your data)
    high_price_threshold = getfield_default(params, 'high_price_threshold', 20); % pence/kWh
    low_price_threshold = getfield_default(params, 'low_price_threshold', 5);    % pence/kWh
    export_threshold = getfield_default(params, 'export_threshold', 15);         % pence/kWh
    
    % Calculate net demand
    net_demand = load_demand - solar_gen;
    
    % Initialize outputs
    battery_action = 0;
    grid_action = 0;
    decisions = struct();
    
    % Decision logic
    if net_demand > 0
        % Need more energy than solar provides
        decisions.situation = 'deficit';
        decisions.net_demand = net_demand;
        
        if electricity_price > high_price_threshold && battery_soc > min_soc
            % High price and battery available - use battery
            max_battery_supply = min(net_demand, max_discharge_rate);
            available_battery = (battery_soc - min_soc) * params.battery_capacity;
            
            battery_action = -min(max_battery_supply, available_battery);
            grid_action = net_demand + battery_action; % Remaining from grid
            
            decisions.action = 'discharge_battery';
            decisions.reason = sprintf('High price (%.1fp/kWh) - using battery', electricity_price);
            
        else
            % Use grid (either low price or insufficient battery)
            battery_action = 0;
            grid_action = net_demand;
            
            if electricity_price <= high_price_threshold
                decisions.action = 'import_grid';
                decisions.reason = sprintf('Acceptable price (%.1fp/kWh) - using grid', electricity_price);
            else
                decisions.action = 'import_grid_forced';
                decisions.reason = sprintf('High price but insufficient battery (SOC: %.1f%%)', battery_soc*100);
            end
        end
        
    else
        % Excess energy available
        excess_energy = -net_demand;
        decisions.situation = 'surplus';
        decisions.excess_energy = excess_energy;
        
        if electricity_price < low_price_threshold && battery_soc < max_soc
            % Low price - charge battery first
            available_charge_capacity = (max_soc - battery_soc) * params.battery_capacity;
            max_charge_power = min(excess_energy, max_charge_rate);
            
            battery_action = min(max_charge_power, available_charge_capacity);
            remaining_excess = excess_energy - battery_action;
            
            if remaining_excess > 0
                grid_action = -remaining_excess; % Export remainder
                decisions.action = 'charge_and_export';
                decisions.reason = sprintf('Low price (%.1fp/kWh) - charge battery then export', electricity_price);
            else
                grid_action = 0;
                decisions.action = 'charge_battery';
                decisions.reason = sprintf('Low price (%.1fp/kWh) - charge battery', electricity_price);
            end
            
        else
            % Export to grid (either good price or battery full)
            battery_action = 0;
            grid_action = -excess_energy;
            
            if electricity_price >= export_threshold
                decisions.action = 'export_grid';
                decisions.reason = sprintf('Good export price (%.1fp/kWh)', electricity_price);
            else
                decisions.action = 'export_grid_forced';
                decisions.reason = sprintf('Battery full (SOC: %.1f%%) - forced export', battery_soc*100);
            end
        end
    end
    
    % Store final values in decisions
    decisions.battery_action = battery_action;
    decisions.grid_action = grid_action;
    decisions.final_soc = battery_soc;
    decisions.price = electricity_price;
end

function value = getfield_default(struct_var, field_name, default_value)
    % Helper function to get field with default value
    if isfield(struct_var, field_name)
        value = struct_var.(field_name);
    else
        value = default_value;
    end
end