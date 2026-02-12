clear
clc

% Define a structure 'Session' to hold recording sessions for different batches
Session = struct( ...
    "O9_12", struct( ...
        "Control", []), ... # empty brackets captures all recording times for the specific drug
    "O13_16", struct( ...
        "Control", []), ...
    "O17_20", struct( ...
        "Control", []), ...
    "O21_24", struct( ...
        "Control", []), ...
    "O25_28", struct( ...
        "Control", []) ...
);

load("Parameters.mat")  % Load additional parameters from 'Parameters.m'

data = FetchData(Session);  % Fetch data using the provided session structure

%% Process Data

%{
Analysis Plan:
    1) Get frequency band time series 
    2) Average within 15-minute bins
    3) Convert to relative power (estimated by summing frequency bands)
    4) Convert to z-score
    5) Average across electrodes
    6) Apply large gaussian filter (2 hours)
%}

batches = fieldnames(Session);  % Get batch names
FEATURE_NAMES = ["Delta", "Theta", "Alpha", "Beta", "Gamma", "HG1", "HG2", "Spike35", "Spike4i", "Spike5i"];

% Get Data to Plot
plot_data = struct();

% Processing Parameters
active_features = [1:7, 10]; % all frequency bands and 5i threshold
elec_mapping = el2row(1:32);
dt = 15; % minutes
gaus_len = 60; % minutes

% Loop through each batch and drug to plot data
for b = 1:numel(batches)
    batch = batches{b};
    Organoids = ORGANOIDS.(batch);

    for o = 1:numel(Organoids)
        organoid = Organoids{o};
        data_struct.(batch).(organoid) = struct();
        plot_data.(organoid) = struct();

        organoid_data = data.(batch).Control(:, :, o);
        num_elec = ELECTRODES_INSIDE.(organoid);
        
        % loop through features and extract data
        for f = active_features
            
            % 1) extract frequency band power time series
            feature_data = ExtractFeatures(organoid_data, f);
            feature_data = feature_data(1:num_elec, :);

            num_minutes = length(feature_data);
            
            % analysis for all features (LFP and spikes)
            % 2) average within 15 minute bins
            t = 0:1:num_minutes;
            t_bins = 0:dt:num_minutes;

            binned_data = zeros(num_elec, length(t_bins)-1);
            for bin_idx = 1:(length(t_bins)-1)
                bin_mask = (t_bins(bin_idx) <= t) & (t < t_bins(bin_idx+1));
                binned_data(:, bin_idx) = mean(feature_data(:, bin_mask), 2);  % Average the feature data within the bin
            end
            
            % store in struct
            data_struct.(batch).(organoid).(FEATURE_NAMES(f)) = binned_data;
    
        end

        t = (0:(length(t_bins)-2)) .* dt;
        active_feature_names = fieldnames(data_struct.(batch).(organoid));
        lfp_features = active_feature_names(~startsWith(active_feature_names, 'Spike')); 
    
        % loop through features and get lfp array
        lfp_array = zeros(length(lfp_features), num_elec, length(t));
        for f = 1:length(lfp_features)
            lfp_array(f, :, :) = data_struct.(batch).(organoid).(lfp_features{f});
        end
        
        % 3) Convert to relative power
        total_power = sum(lfp_array, 1);
        relative_power = (lfp_array ./ total_power) * 100; % as a percentage
    
        % 4) Convert to z-score (along time axis (3))
        zScore = (relative_power - mean(relative_power, 3)) ./ std(relative_power, 0, 3); % Z-score normalization
        
        % 5) Average across electrodes
        zScore = squeeze(mean(zScore, 2));
    
        % 6) Apply Gaussian Filter for smoothing
        sigma = gaus_len ./ dt;
        for f = 1:length(lfp_features)
            smoothedZScore = imgaussfilt(zScore(f,:), sigma);  % Apply Gaussian filter 
            plot_data.(organoid).(lfp_features{f}) = smoothedZScore;  % Store smoothed z-score in plot_data
        end

        % Store spike features
        spike_features = active_feature_names(startsWith(active_feature_names, 'Spike')); 
        for f = 1:length(spike_features)
            spike_data = data_struct.(batch).(organoid).(spike_features{f});
            population_firing_rate = sum(spike_data(1:num_elec,:), 1) / 60; % spikes/min -> spikes/s

            % convert to zscore
            % pfr_zscore = (population_firing_rate - mean(population_firing_rate)) ./ std(population_firing_rate);
            pfr_zscore = imgaussfilt(population_firing_rate, sigma);

            plot_data.(organoid).(spike_features{f}) = pfr_zscore;
        end

        % Store time vector
        plot_data.(organoid).time = t;

    end
end

%% Plot data

n = 250;
lfp_colors = ["#ad2bea", "#4d3ff8", "#39cabb", "#53e53a","#e3e12c", "#f7a740", "#ed3838"];
lfp_labels = ["Delta", "Theta", "Alpha", "Beta", "Gamma", "HG1", "HG2"];
Batches = fieldnames(data_struct);

for b = 1:numel(Batches)
    batch = Batches{b};
    Organoids = fieldnames(data_struct.(batch));

    for o = 1:numel(Organoids)
        organoid = Organoids{o};

        % Create figure
        fig = figure;
        fig.Units = 'normalized'; % Set units to normalized for relative sizing
        fig.Position = [0.2, 0.2, 0.6, 0.6]; % [left, bottom, width, height]
        
        % LFP Traces
        ax1 = subplot(2, 1, 1);
        hold on
        grid on

        time = plot_data.(organoid).time / 60 / 24; % minutes -> days

        for f = 1:length(lfp_features)
            lfp_trace = plot_data.(organoid).(lfp_features{f});
            plot(time, lfp_trace, '-', 'Color', lfp_colors(lfp_labels==lfp_features{f}), 'DisplayName', lfp_features{f})
        end

        ylim([-4, 4])
        ylabel("Relative Power Z-score", "FontSize",12,"FontWeight","bold")
        xticks(0:2:floor(time(end)))
        title("Relative Frequency Band Power", "FontSize", 15)    

        Lgnd = legend('show', 'Orientation', 'horizontal');
        Lgnd.Position(1) = 0.28;
        Lgnd.Position(2) = .84;

        % Population Firing Rate
        ax2 = subplot(2, 1, 2);
        hold on
        grid on

        for f = 1:length(spike_features)
            spike_trace = plot_data.(organoid).(spike_features{f});
            plot(time, spike_trace, '-', 'Color', 'black', 'DisplayName', sprintf("MUA Spikes (%s threshold)", erase(spike_features{f}, 'Spike')))
        end
        
        xticks(0:2:floor(time(end)))
        ylabel("Population Firing Rate (Hz)", "FontSize",12,"FontWeight","bold")
        title("Population Firing Rate", "FontSize", 15)   

        linkaxes([ax1, ax2], 'x')
        xlabel(ax2, 'Time (days)')

        Lgnd = legend('show', 'Orientation', 'horizontal', 'Location', 'northeast');
    
        sgtitle(sprintf("%s: Time-varying activity across longitudinal recording", organoid), "FontWeight", "bold", "FontSize", 20)
    end
end