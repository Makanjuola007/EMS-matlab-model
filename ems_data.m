% === Step 1: Read Excel File ===
T = readtable("weekly/weekly.xlsx");

% === Step 2: Generate Time Vector ===
time = (0:300:(height(T)-1)*300)';  % 5-minute intervals over the week

% === Step 3: Extract Signals from Table ===
DCV_PV1 = T.DCVoltagePV1_V_;
DCV_PV2 = T.DCVoltagePV2_V_;
DC_current1 = T.DCCurrent1_A_;
DC_current2 = T.DCCurrent2_A_;
AC_Voltage = T.ACVoltageR_U_A_V_;
AC_current = T.ACCurrentR_U_A_A_;
AC_ouputPOWER = T.ACOutputTotalPower_Active__W_;
AC_freq = T.ACOutputFrequencyR_Hz_;

TotalEnergyGeneration = T.TotalGeneration_Active__kWh_;
TotalPOWERconsumed = T.TotalConsumptionPower_W_;
TotalconsumptionEnergy = T.TotalConsumptionEnergy_kWh_;
GridVoltage = T.PowerGridVoltageR_U_A_V_;
Gridcurrent = T.PowerGridCurrentR_U_A_A_;
PowergridReactivePower = T.PowerGridTotalReactivePower_Var_;
PowergridApparentPower = T.PowerGridTotalApparentPower_VA_;
GridPowerFactor = T.GridPowerFactor;
TotalOn_gridGeneration = T.TotalOn_gridGeneration_kWh_;

meterpower = T.MeterPower_W_;

Bvoltage = T.BatteryVoltage_V_;
Bcurrent = T.BatteryCurrent_A_;
Bpower = T.BatteryPower_W_;
Bsoc = T.RemainingBatteryCapacity_SoC____;
totalEnergyCharge = T.TotalEnergyCharged_kWh_;
totalEnergyDisCharge = T.TotalEnergyDischarged_kWh_;

inveterTemp = T.InverterTemperature___;
bmsVoltage = T.BMSVoltage_V_;
bmscurrent = T.BatteryCurrent_A_;

loadpower = T.Back_upLoadPower_W_;

% === Step 4: Pack signals into list for processing ===
signals = {
    'DCV_PV1', DCV_PV1;
    'DCV_PV2', DCV_PV2;
    'DC_current1', DC_current1;
    'DC_current2', DC_current2;
    'AC_Voltage', AC_Voltage;
    'AC_current', AC_current;
    'AC_ouputPOWER', AC_ouputPOWER;
    'AC_freq', AC_freq;
    'TotalEnergyGeneration', TotalEnergyGeneration;
    'TotalPOWERconsumed', TotalPOWERconsumed;
    'TotalconsumptionEnergy', TotalconsumptionEnergy;
    'GridVoltage', GridVoltage;
    'Gridcurrent', Gridcurrent;
    'PowergridReactivePower', PowergridReactivePower;
    'PowergridApparentPower', PowergridApparentPower;
    'GridPowerFactor', GridPowerFactor;
    'TotalOn_gridGeneration', TotalOn_gridGeneration;
    'meterpower', meterpower;
    'Bvoltage', Bvoltage;
    'Bcurrent', Bcurrent;
    'Bpower', Bpower;
    'Bsoc', Bsoc;
    'totalEnergyCharge', totalEnergyCharge;
    'totalEnergyDisCharge', totalEnergyDisCharge;
    'inveterTemp', inveterTemp;
    'bmsVoltage', bmsVoltage;
    'bmscurrent', bmscurrent;
    'loadpower', loadpower;
};

% === Step 5: Helper to convert cell → number (default 0 if invalid) ===
safe2num = @(x) double(str2double(string(x)));  % invalid text → NaN → 0 later

% === Step 6: Clean and format for Simulink ===
for i = 1:size(signals, 1)
    name = signals{i,1};
    raw = signals{i,2};

    % Convert cells to numeric if needed
    if iscell(raw)
        raw = cellfun(safe2num, raw);  % convert each cell to number
    end

    % Combine with time
    ts = [time, raw];

    % Remove rows with NaN or Inf
    valid_rows = ~any(isnan(ts) | isinf(ts), 2);
    ts_clean = ts(valid_rows, :);

    % Assign to base workspace
    assignin('base', [name '_input'], ts_clean);
end

% === Step 7: Save all *_input variables to .mat file ===
vars_to_save = who('*_input');
save('ems_inputdata_cleaned.mat', vars_to_save{:});

disp("✅ All signals cleaned, saved, and ready for Simulink!");
