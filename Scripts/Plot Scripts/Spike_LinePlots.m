clear
clc

% Define a structure 'Session' to hold recording sessions for different batches
Session = struct( ...
    "O9_12", struct( ...
        "Control", ["230518_0610" , "230518_1210"], ...
        "x4_AP", [], ...
        "No_Drug", [], ...
        "Bicuculline", [], ...
        "Tetrodotoxin", []), ...
    "O13_16", struct( ...
        "Control", ["230608_1250","230608_1850"], ...
        "x4_AP", [], ...
        "No_Drug", [], ...
        "Bicuculline", [], ...
        "Tetrodotoxin", []), ...
    "O17_20", struct( ...
        "Control", ["230712_0655","230712_1255"], ...
        "x4_AP", [], ...
        "No_Drug", [], ...
        "Bicuculline", [], ...
        "Tetrodotoxin", []), ...
    "O21_24", struct( ...
        "Control", ["240709_0725","240709_1325"], ...
        "x4_AP", [], ...
        "No_Drug", [], ...
        "Bicuculline", [], ...
        "Tetrodotoxin", []), ...
    "O25_28", struct( ...
        "Control", ["241014_0650","241014_1250"], ...
        "x4_AP", [], ...
        "No_Drug", [], ...
        "Bicuculline", [], ...
        "Tetrodotoxin", []) ...
);

load("Parameters.mat")  % Load additional parameters from 'Parameters.m'

data = FetchData(Session);  % Fetch data using the provided session structure

%%
batches = fieldnames(Session);  % Get batch names

% Get Data to Plot
plot_data = struct();

% Loop through each batch and drug to plot data
for b = 1:numel(batches)
    batch = batches{b};
    drugs = fieldnames(data.(batch));
    organoids = ORGANOIDS.(batch);

    
    data_array = [];
    drug_indexs = zeros(1 , numel(drugs));
    % Loop through each drug in the current batch
    for d = 1:numel(drugs)
        drug = drugs{d};
        drug_data = data.(batch).(drug);  % Get data for the drug
        
        % Extract frequency band data from the drug data
        spike_data = ExtractFeatures(drug_data, 10);

        % Average across channels and remove channels outside of the
        % organoid
        drug_array = [];
        for o = 1:numel(organoids)
            organoid = organoids{o};

            electrodes_inside_organoid = el2row(1:ELECTRODES_INSIDE.(organoid));
            organoid_array = spike_data(electrodes_inside_organoid,:,o);
            
            % Most Active Channel
             most_active_channel = mean(organoid_array , 2) == max(mean(organoid_array , 2));
             organoid_data = organoid_array(most_active_channel,:) ./ 60;
            
            % Channel Average
            % organoid_data = mean(organoid_array , 1) ./ 60;

            drug_array = cat(1 , drug_array , organoid_data);

        end
        
        data_array = cat(2 , data_array , drug_array);
        drug_indexs(d) = length(data_array);
        
    end

    plot_data.(batch).("data_array") = data_array;
    plot_data.(batch).("drug_indexs") = [1 , drug_indexs(1:end-1)];

end

% Plot Data
for b = 1:numel(batches)
    batch = batches{b};
    drugs = strrep(fieldnames(Session.(batch)) , "_" , "-");

    data_array = plot_data.(batch).("data_array");
    drug_indexs = plot_data.(batch).("drug_indexs");

    fig = figure;
    hold on

    plot(mean(data_array , 1) , 'LineWidth' , 2 , 'Color' , 'k')
    scatter(1:length(data_array) , data_array , 15 , 'filled')
    
    title(strrep(sprintf("Firing Rate Across Drug Treatments (%s)" , batch),"_","-"))
    ylabel("Firing Rate (spikes/s)")
    xlabel(sprintf("Time (%d hours)" , floor(length(data_array)/60)))
    xticks(drug_indexs)
    xticklabels(drugs)

    legend(["Batch Average" , ORGANOIDS.(batch)])

end
