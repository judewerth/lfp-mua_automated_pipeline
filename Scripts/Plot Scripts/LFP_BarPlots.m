% x-axis: Frequency Bands
% y-axis: Power Spectral Density
% Bars: Control Organoid, GBM-Organoid Chimera (Batch Average)
% Errorbar: 2 stds (one in each direction)
% Dots: Organoid Average

clear  % Clear all variables from the workspace
clc    % Clear the command window

% Define a structure 'Session' to hold recording sessions for different batches
Session = struct( ...
    "O9_12", struct( ...
        "Control", ["230518_0610" , "230518_1210"]), ...
    "O13_16", struct( ...
        "Control", ["230608_1250","230608_1850"]), ...
    "O17_20", struct( ...
        "Control", ["230712_0655","230712_1255"]), ...
    "O21_24", struct( ...
        "Control", ["240709_0725","240709_1325"]), ...
    "O25_28", struct( ...
        "Control", ["241014_0650","241014_1250"]) ...
);

load("Parameters.mat")  % Load additional parameters from 'Parameters.m'

data = FetchData(Session);  % Fetch data using the provided session structure

batches = fieldnames(Session);  % Get batch names
features = ["Delta" , "Theta" , "Alpha" , "Beta" , "Gamma" , "High_Gamma_1" , "High_Gamma_2"];

% Bar plot configurations
bar_width = 0.75;   % Width of individual bars
bar_space = 0.25;   % Space between bars in the same group
group_space = 1;    % Space between groups of bars

num_groups = 7;     % 7 frequency bands
has_organoid = 0;   % Track if there are organoids
has_chimera = 0;    % Track if there are chimeras

% Determine the number of groups and if they contain chimera or organoid data
for b = 1:numel(batches)
    batch = batches{b};

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
    for f = 1:numel(features)
        feature = features{f};

        control_data = data.(batch).Control;  % Get data for the drug
        
        % Extract frequency band data from the drug data
        frequency_band_data = ExtractFeatures(control_data, f);
        
        % Get the size of the frequency band data
        [~, NUM_MINUTES, NUM_ORGANOIDS] = size(frequency_band_data);
        
        if ~isfield(organoid_average.(is_chimera) , feature)
            organoid_average.(is_chimera).(feature) = [];
            organoid_std.(is_chimera).(feature) = [];
        end
        
        % Loop through each organoid in the batch
        for o = 1:NUM_ORGANOIDS
            organoid = organoids{o};  % Get the current organoid
            
            % Extract data for electrodes inside the organoid
            electrodes_inside_organoid = el2row(1:ELECTRODES_INSIDE.(organoid));
            organoid_data = frequency_band_data(electrodes_inside_organoid, :, o);
            organoid_data = organoid_data / (NUM_MINUTES * 60);  % Convert to spikes/s

            o_mean = mean(organoid_data , "all");
            o_std = mean(std(organoid_data , 0 , 2), "all");
            
            % Store organoid data and calculate the mean for dots
            organoid_average.(is_chimera).(feature) = cat(1, organoid_average.(is_chimera).(feature), o_mean);
            organoid_std.(is_chimera).(feature) = cat(1 , organoid_std.(is_chimera).(feature) , o_std);
        end
        
    end
end

% Normalize Data (Divide by the control for each frequency band)
plot_groups = fieldnames(organoid_average);
frequency_bands = fieldnames(organoid_average.("organoid"));

% for fb = 1:numel(frequency_bands)
%     freq_band = frequency_bands{fb};
% 
%     for pg = 1:numel(plot_groups)
%         plot_group = plot_groups{pg};
% 
% 
%         fq_data = organoid_average.(plot_group).(freq_band);
%         fq_std = organoid_std.(plot_group).(freq_band);
% 
%         if plot_group == "organoid"
%             fq_mean = mean(fq_data);
%         end
% 
%         organoid_average.(plot_group).(freq_band) = fq_data;
%         organoid_std.(plot_group).(freq_band) = fq_std;
% 
%     end
% end

% Plot Data
% Create the figure and set axis properties
fig = figure;
hold on
title("PSD of LFP Frequency Bands (Control Only)")
xlabel("Frequency Bands")
ylabel("Power Spectral Density (PSD)")
xticks(x_label_values)
xticklabels(strrep(features, "_", " "))


for pg = 1:numel(plot_groups)
    plot_group = plot_groups{pg};

    if plot_group == "chimera"
        is_chimera = 1;
    elseif plot_group == "organoid"
        is_chimera = 0;
    else
        error()
    end

    % Loop through each drug in the current batch
    for f = 1:numel(features)
        feature = features{f};

        % Calculate error bars (standard deviation)
        bar_data = mean(organoid_average.(plot_group).(feature) , "all");  % Calculate bar height (mean of dots)
        errorbar_data = mean(organoid_std.(plot_group).(feature), "all");
        dot_data = organoid_average.(plot_group).(feature);
        
        % Calculate the x position for the bar
        x_data = x_values(bars_per_group * (f - 1) + is_chimera + 1);
        
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

ax = gca;
ax.YScale = 'log';

% Create invisible bars for legend
bar_organoid = bar(nan, nan, 'b');  % Blue bar for organoid
bar_chimera = bar(nan, nan, 'r');   % Red bar for chimera

% Add legend to the plot
legend([bar_organoid, bar_chimera], {'Organoid', 'GBM Chimera'}, 'Location', 'Best');

%% Statistical Test
stat_cell = {};

for fq = 1:numel(frequency_bands)
    frequency_band = frequency_bands{fq};

    organoid_data = organoid_average.("organoid").(frequency_band);
    chimera_data = organoid_average.("chimera").(frequency_band);
    
    [h, c] = ttest2(organoid_data, chimera_data);
    
    stat_cell = [stat_cell; {frequency_band, c, h}];

end




