clear
clc

% Define a structure 'Session' to hold recording sessions for different batches
Session = struct( ...
    "MB1_4", struct( ...
        "Control", []));

load("Parameters.mat")  % Load additional parameters from 'Parameters.m'
data = FetchData(Session);  % Fetch data using the provided session structure

%%
batches = fieldnames(Session);  % Get batch names

% Get Data
num_features = 7;
plot_data = struct();

num_elec = 12;
elec_inside = el2row(1:num_elec);

for b = 1:numel(batches)
    b_id = batches{b};
    mb_ids = ORGANOIDS.(b_id);

    b_data = data.(b_id).("Control");
    
    % LFP Data
    lfp_data = [];
    for f = 1:num_features

        feature_data = ExtractFeatures(b_data, f);
        psd_data = permute(mean(feature_data(elec_inside,:,:)), [2,1,3]);
        zscores = (psd_data - mean(psd_data, 1)) ./ std(psd_data, 0, 1);
        
        lfp_data = cat(2, lfp_data, zscores);
    end

    % Spike Data
    spike_data = ExtractFeatures(b_data, 10);
    firing_rate = permute(mean(spike_data(elec_inside,:,:)), [2,3,1]) ./ 60;

    plot_data.(b_id) = {lfp_data, firing_rate};

    
end

%%
% Plot Data
for b = 1:numel(batches)
    b_id = batches{b};

    p1 = plot_data.(b_id){1};
    p2 = plot_data.(b_id){2};
    [T, ~, I] = size(p1);
    t = 1:T;
    
    lfp_colors = ["#ad2bea", "#4d3ff8", "#39cabb", "#53e53a","#e3e12c", "#f7a740", "#ed3838"];
    for i = 1:I
        
        figure;
        subplot(2,1,1)
        hold on;
        for f = 1:num_features
            plot(t, p1(:,f,i), 'Color', lfp_colors(f))
        end

        title(sprintf("%s: port=%d", strrep(b_id,"_","-") , i))
        ylabel("PSD z-score")
        legend(["Delta", "Theta", "Alpha", "Beta", "Gamma", "HG1", "HG2"])
        ylim([prctile(p1(:,:,i), 1, "all"), prctile(p1(:,:,i), 99, "all")])

        subplot(2,1,2)
        plot(t, p2(:,i), 'Color', 'k')
        ylabel("Firing Rate (spikes/s)")
        xlabel("Time (minutes)")
        ylim([prctile(p2(:,i), 1), prctile(p2(:,i), 99)])

    end


end
