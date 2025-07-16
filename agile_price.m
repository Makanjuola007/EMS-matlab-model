function agile_prices = fetch_octopus_agile_prices(start_date, end_date, region)
    % Fetch Octopus Energy Agile pricing data
    % Inputs:
    %   start_date: datetime object for start
    %   end_date: datetime object for end  
    %   region: string like 'A' for Eastern England (check your region)
    
    % Convert dates to ISO format
    start_str = datestr(start_date, 'yyyy-mm-ddTHH:MM:SS');
    end_str = datestr(end_date, 'yyyy-mm-ddTHH:MM:SS');
    
    % Construct API URL
    base_url = 'https://api.octopus.energy/v1/products/AGILE-FLEX-22-11-25/electricity-tariffs/E-1R-AGILE-FLEX-22-11-25-';
    tariff_code = [region '/standard-unit-rates/'];
    
    url = [base_url tariff_code '?period_from=' start_str '&period_to=' end_str];
    
    try
        % Fetch data
        options = weboptions('ContentType', 'json');
        response = webread(url, options);
        
        % Parse response
        results = response.results;
        n_results = length(results);
        
        % Initialize output table
        timestamps = datetime.empty(n_results, 0);
        prices = zeros(n_results, 1);
        
        % Extract data
        for i = 1:n_results
            timestamps(i) = datetime(results(i).valid_from, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''');
            prices(i) = results(i).value_inc_vat; % Price in pence/kWh
        end
        
        % Create table
        agile_prices = table(timestamps, prices, 'VariableNames', {'timestamp', 'price_pence_per_kWh'});
        
        % Sort by timestamp
        agile_prices = sortrows(agile_prices, 'timestamp');
        
        fprintf('Successfully fetched %d price points\n', height(agile_prices));
        
    catch ME
        fprintf('Error fetching agile prices: %s\n', ME.message);
        fprintf('Check your internet connection and region code\n');
        agile_prices = table();
    end
end

% Example usage:
% start_date = datetime('2024-01-01');
% end_date = datetime('2024-01-02');
% region = 'A'; % Eastern England - check your region
% prices = fetch_octopus_agile_prices(start_date, end_date, region);