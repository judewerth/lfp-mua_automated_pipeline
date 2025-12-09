% x-axis: Drug Treatments
% y-axis: Firing Rate
% Bars: Control Organoid, GBM-Organoid Chimera (Batch Average)
% Errorbar: 2 stds (one in each direction)
% Dots: Organoid Average

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

data = FetchData(Session);  % Fetch data using the provided session structure
batches = fieldnames(Session);  % Get batch names
%%
% Bar plot configurations
bar_width = 0.75;   % Width of individual bars
bar_space = 0.25;   % Space between bars in the same group
group_space = 1;    % Space between groups of bars

num_groups = 0;     % Initialize number of groups
has_organoid = 0;   % Track if there are organoids
has_chimera = 0;    % Track if there are chimeras

% Determine the number of groups and if they contain chimera or organoid data
for b = 1:numel(batches)
    batch = batches{b};
    
    % Update the number of groups based on the current batch
    if numel(fieldnames(Session.(batch))) > num_groups
        groups = fieldnames(Session.(batch));
        num_groups = numel(groups);

        % Store the index of each group for x-axis positioning
        for i = 1:numel(groups)
            group = groups{i};
            group_index.(group) = i;
        end
    end

    % Check if the batch contains chimera data
    if IS_CHIMERA.(batch)
        has_chimera = 1;
    else
        has_organoid = 1;
    end
end

% Calculate the number of bars per group (organoid + chimera)
bars_per_group = sum([has_organoid, has_chimera]);

% Calculate x-axis values for bars and groups
group_vector = repelem(0:num_groups-1, bars_per_group) * (bar_width * bars_per_group);
group_vector = group_vector + repelem(0:num_groups-1, bars_per_group) * group_space;
bar_vector = mod(0:(num_groups * bars_per_group - 1), bars_per_group) * bar_width;

x_values = group_vector + bar_vector;  % Final x-axis values for bars
x_label_values = unique(group_vector) + (bar_width + bar_space) * ((bars_per_group - 1) / 2);

% Get Data to Plot
organoid_average = struct();
organoid_std = struct();
% Loop through each batch and drug to plot data
for b = 1:numel(batches)
    batch = batches{b};
    drugs = fieldnames(data.(batch));
    organoids = ORGANOIDS.(batch);

    if IS_CHIMERA.(batch)
        is_chimera = "chimera";
    else
        is_chimera = "organoid";
    end

    if ~isfield(organoid_average , is_chimera)
        organoid_average.(is_chimera) = struct();
        organoid_std.(is_chimera) = struct();
    end

    % Loop through each drug in the current batch
    for d = 1:numel(drugs)
        drug = drugs{d};
        drug_data = data.(batch).(drug);  % Get data for the drug
        
        % Extract frequency band data from the drug data
        spike_data = ExtractFeatures(drug_data, 10);
        
        % Get the size of the frequency band data
        [~, NUM_MINUTES, NUM_ORGANOIDS] = size(spike_data);
        
        if ~isfield(organoid_average.(is_chimera) , drug)
            organoid_average.(is_chimera).(drug) = [];
            organoid_std.(is_chimera).(drug) = [];
        end
        
        % Loop through each organoid in the batch
        for o = 1:NUM_ORGANOIDS
            organoid = organoids{o};  % Get the current organoid
            
            % Extract data for electrodes inside the organoid
            electrodes_inside_organoid = el2row(1:ELECTRODES_INSIDE.(organoid));
            organoid_data = spike_data(electrodes_inside_organoid, :, o);
            organoid_data = organoid_data / 60;  % Convert to spikes/s

            % Take out all values over 90th percentile
            organoid_data(organoid_data > prctile(organoid_data,90,"all")) = prctile(organoid_data,90,"all");
            
            % Find and extract most active channel
%             most_active_channel = mean(organoid_data , 2) == max(mean(organoid_data , 2));
%             organoid_data = organoid_data(most_active_channel,:);

            o_mean = mean(organoid_data, "all");
            o_std = mean(std(organoid_data , 0 , 2), "all");
            
            % Store organoid data and calculate the mean for dots
            organoid_average.(is_chimera).(drug) = cat(1, organoid_average.(is_chimera).(drug), o_mean);
            organoid_std.(is_chimera).(drug) = cat(1 , organoid_std.(is_chimera).(drug) , o_std);
        end
        
    end
end

% Plot Data
% Create the figure and set axis properties
fig = figure;
hold on
title("Firing Rate Across Different Drug Treatments (5i threshold)")
xlabel("Drug Treatments")
ylabel("Firing Rate")
xticks(x_label_values)
xticklabels(strrep(strrep(groups, "x4_AP", "4-AP"), "_", " "))

plot_groups = fieldnames(organoid_average);
for pg = 1:numel(plot_groups)
    plot_group = plot_groups{pg};

    if plot_group == "chimera"
        is_chimera = 1;
    elseif plot_group == "organoid"
        is_chimera = 0;
    else
        error()
    end

    drugs = fieldnames(organoid_average.(plot_group));

    % Loop through each drug in the current batch
    for d = 1:numel(drugs)
        drug = drugs{d};
        % Calculate error bars (standard deviation)
        bar_data = mean(organoid_average.(plot_group).(drug) , "all");  % Calculate bar height (mean of dots)
        errorbar_data = mean(organoid_std.(plot_group).(drug), "all");
        dot_data = organoid_average.(plot_group).(drug);
        
        % Calculate the x position for the bar
        x_data = x_values(bars_per_group * (group_index.(drug) - 1) + is_chimera + (bars_per_group-1));
        
        % Set color based on whether the batch is a chimera or organoid
        if is_chimera
            color = 'r';  % Red for chimera
        else
            color = 'b';  % Blue for organoid
        end
        
        % Plot the bar, error bar, and scatter dots
        bar(x_data, bar_data, bar_width, color)
        errorbar(x_data, bar_data, errorbar_data, 'k')
        scatter(-(bar_width / 4) + (bar_width / 2) * rand(1, numel(dot_data)) + x_data, ...
                dot_data, 'k', 'filled')
    end
end


% Create invisible bars for legend
bar_organoid = bar(nan, nan, 'b');  % Blue bar for organoid
bar_chimera = bar(nan, nan, 'r');   % Red bar for chimera

% Add legend to the plot
legend([bar_organoid, bar_chimera], {'Organoid', 'GBM Chimera'}, 'Location', 'Best');

%% Statistical Analysis One way ANOVA
stat_data = [];
org_type = {};
drug_type = {};

plot_groups = fieldnames(organoid_average);

for pg = 1:numel(plot_groups)
    plot_group = plot_groups{pg};
    group_data = organoid_average.(plot_group);

    drugs = fieldnames(group_data);
    for d = 1:numel(drugs)
        drug = drugs{d};
        drug_data = group_data.(drug);

        stat_data = cat(1, stat_data, drug_data);
        org_type = [org_type; repmat(string(plot_group), length(drug_data), 1)];
        drug_type = [drug_type; repmat(string(drug), length(drug_data), 1)];
    
    end

end
group_cell = {};
for i = 1:numel(org_type)
    group_cell = [group_cell ; {org_type(i) , drug_type(i)}];
end

p = anovan(stat_data, {org_type, drug_type});
