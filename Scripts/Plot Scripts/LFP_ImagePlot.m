% x-axis: Time (Drug Treatments Included
% y-axis: Frequency Bands
% Color PSD

clear  % Clear all variables from the workspace
clc    % Clear the command window

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

% Get Data
data = FetchData(Session);  % Fetch data using the provided session structure

batches = fieldnames(Session);  % Get batch names

% total time ~ 24 hours
dt = 5; % minutes (minimum = 1 , whole number)

plot_data = struct();

for b = 1:numel(batches)
    batch = batches{b};
    drugs = fieldnames(Session.(batch));
    organoids = ORGANOIDS.(batch);
    
    for o = 1:numel(organoids)
        organoid = organoids{o};
            
        image_array = [];
        drug_indexs = zeros(1,numel(drugs));
        for d = 1:numel(drug_indexs)
            drug = drugs{d};

            drug_data = data.(batch).(drug);
            
            LFP_data = [];
            for f = 1:7
                feature_data = ExtractFeatures(drug_data , f);
                
                feature_array = [];
                for oo = 1:numel(organoids)
                    oorganoid = organoids{o};

                    electrodes_inside_organoid = el2row(1:ELECTRODES_INSIDE.(oorganoid));
                    organoid_feature_vector = mean(feature_data(electrodes_inside_organoid,:,oo) , 1);
                    
                    feature_array = cat(3 , feature_array , organoid_feature_vector);

                end

                LFP_data = cat(1 , LFP_data , feature_array);

            end

            
            if dt > 1
                % Adjust the array based on dt
                old_data = LFP_data;
                new_data = [];
                num_iterations = ceil(length(LFP_data) / dt);

                for i = 1:num_iterations
                    
                    if i == num_iterations
                        iteration_data = mean(old_data , 2);
                    else
                        iteration_data = mean(old_data(:,1:dt) , 2);
                        old_data(:,1:dt) = [];
                    end

                    new_data = cat(2 , new_data , iteration_data);

                end
            
            else
                new_data = LFP_data;

            end    

            image_array = cat(2 , image_array , new_data);
            drug_indexs(d) = length(image_array);

        end

        plot_data.(organoid).("image_array") = image_array;
        plot_data.(organoid).("drug_indexs") = [1 , drug_indexs(1:end-1)];

    end

end

% Plot Data

ytick_labels = ["Delta", "Theta", "Alpha", "Beta", "Gamma", "HG1", "HG2"];
ytick_values = 1:numel(ytick_labels);

for b = 1:numel(batches)
    batch = batches{b};
    drugs = strrep(fieldnames(Session.(batch)) , "_" , "-");
    organoids = ORGANOIDS.(batch);

    for o = 1:numel(organoids)
        organoid = organoids{o};

        image_array = plot_data.(organoid).("image_array");
        drug_indexs = plot_data.(organoid).("drug_indexs");
        
        % normalize array
        freq_band_mean = mean(image_array , 2);
        image_array = image_array ./ freq_band_mean;

        fig = figure;
        imagesc(image_array)
        caxis([min(image_array(:)), prctile(image_array(:), 95)]);
        colorbar;

        title(sprintf("Normalized PSD of Frequency Bands (%s)" , organoid))
        xlabel(sprintf("Time (%dmin iterations)" , dt))
        xticks(drug_indexs)
        xticklabels(drugs)
        ylabel("Frequency Bands")
        yticks(ytick_values)
        yticklabels(ytick_labels)
        
    end

end
