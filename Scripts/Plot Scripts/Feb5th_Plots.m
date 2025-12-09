% Plot 1: Firing Map
%   Figure per Batch (4x2)
%   Firing Rate (Hz) 
%   Rows = Organoids
%   Columns = Control | Drug

% Plot 2: Frequency Spectra
%   Figure per Batch (4x2)
%   Frequency Band Relative z-score
%   Rows = Organoids
%   Columns = Control | Drug

% Plot 3: Line Plots
%   y-axis 1 (log-log): PSD Frequency Band
%   y-axis 2: Firing Rate
%   x-axis: Time
%   Rows = Organoids
%   Columns = Control | Drug

%% Get Data

load("Parameters.mat")  % Load additional parameters from 'Parameters.m'

% Session = struct( ...
%     "O9_12", struct( ...
%         "Control", [], ...
%         "x4_AP", [], ...
%         "No_Drug", [], ...
%         "Bicuculline", [], ...
%         "Tetrodotoxin", []), ...
%     "O13_16", struct( ...
%         "Control", [], ...
%         "x4_AP", [], ...
%         "No_Drug", [], ...
%         "Bicuculline", [], ...
%         "Tetrodotoxin", []), ...
%     "O17_20", struct( ...
%         "Control", [], ...
%         "x4_AP", [], ...
%         "No_Drug", [], ...
%         "Bicuculline", [], ...
%         "Tetrodotoxin", []), ...
%     "O21_24", struct( ...
%         "Control", [], ...
%         "x4_AP", [], ...
%         "No_Drug", [], ...
%         "Bicuculline", [], ...
%         "Tetrodotoxin", []), ...
%     "O25_28", struct( ...
%         "Control", [], ...
%         "x4_AP", [], ...
%         "No_Drug", [], ...
%         "Bicuculline", [], ...
%         "Tetrodotoxin", []) ...
% );
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


data = FetchData(Session);  % Fetch data using the provided session structure
%%
clear
clc

load("Parameters.mat")  % Load additional parameters from 'Parameters.m'
data = load("data.mat");

%% Reorganize Data for all Plots
% Set up struct in the structure:
%    Batch --> Organoid --> Control/Drug --> [Channels x Time x Feature]

Batches = fieldnames(data);
data_struct = struct();

for b = 1:numel(Batches)
    batch = Batches{b};
    Organoids = ORGANOIDS.(batch);
    Drugs = fieldnames(data.(batch));

    data_struct.(batch) = struct();

    for o = 1:numel(Organoids)
        organoid = Organoids{o};

        data_struct.(batch).(organoid) = struct();
        elec_mapping = el2row(1:32);

        for d = 1:numel(Drugs)
            drug = Drugs{d};
            
            drug_data = data.(batch).(drug);
            data_array = [];
            active_features = [1:7, 9]; % all frequency bands and 5i threshold

            for f = active_features
                
                % get data for each feature and organoid
                feature_array = ExtractFeatures(drug_data, f);
                feature_array = feature_array(elec_mapping, :, o);
                if f >= 8 % if it's a spike
                    feature_array = feature_array / 60; % convert spikes/min -> spikes/s
                end

                % concatenate feature array to global array
                data_array = cat(3, data_array, feature_array);
            end  

            % add into global data sctruct
            data_struct.(batch).(organoid).(drug) = data_array;
        end        
    end
end


%% Plot 1 (Firing Map): 

n = 100;
plot_f = 8;

for b = 1:numel(Batches)
    batch = Batches{b};
    Organoids = ORGANOIDS.(batch);
    
    % Create figure
    fig = figure;
    fig.Units = 'normalized'; % Set units to normalized for relative sizing
    fig.Position = [0.2, 0.2, 0.6, 0.8]; % [left, bottom, width, height]

    for o = 1:numel(Organoids)
        organoid = Organoids{o};
        Drugs = fieldnames(data_struct.(batch).(organoid));
        
        num_elec = ELECTRODES_INSIDE.(organoid);
        drug_array = [];
        drug_idxs = [];

        for d = 1:numel(Drugs)
            drug = Drugs{d};
            
            d_array = data_struct.(batch).(organoid).(drug);

            % Create array to plot
            if drug == "Control"
                % Plot Array for Control Session
                control_array = d_array(:,:,plot_f);
                plot_array1 = condense_array(control_array, n);
                control_idxs = [0, length(plot_array1)];
            else
                drug_idxs = [drug_idxs, length(drug_array)+1];
                drug_array = cat(2, drug_array, d_array(:,:,plot_f));
            end      
        end
        drug_idxs = n*(drug_idxs/length(drug_array)); % normalize ticks
        plot_array2 = condense_array(drug_array, n);
        
        % Find limits
        llim = prctile([plot_array1; plot_array2], 5, "all");
        hlim = prctile([plot_array1; plot_array2], 95, "all");
        clims = [llim, hlim];
        
        % Plot
        % Control
        a1 = subplot(numel(Organoids), 2, 2*o-1);
        a1.Position = [0.05, 0.15, 0.455, 0.7];
        hold on
        axis tight

        imagesc(plot_array1, clims)
        colormap(gca, jet); % Blue-to-red color scale
        yline(num_elec, 'k', 'LineWidth', 3)
        
        if num_elec == 32
            yticks([0, 32])
        else
            yticks([0, num_elec, 32])
        end
        ylabel("Channels")
        if d == numel(Drugs)
            xticks([.5, n-.5])
            xticklabels(["0", num2str(round(length(control_array)/60))])
            xlabel("Time (hours)")
        end
        title(sprintf("%s / Control", organoid))

        % Drug
        subplot(numel(Organoids), 2, 2*o) 
        hold on
        axis tight

        imagesc(plot_array2, clims)
        colormap(gca, jet)
        yline(num_elec, 'k', 'LineWidth', 3)

        colorbar;
        yticks([])
        if d == numel(Drugs)
            xticks(ceil(drug_idxs))
            xticklabels(["4-AP", "NM", "Bicu", "TTX"])
            xlabel(sprintf("Time (%d hours)", round(length(drug_array)/60)))
        end
        title(sprintf("%s / Drugs", organoid))
    end
    sgtitle(sprintf("%s / Firing Map (Hz)", strrep(batch, "_", "-")))
end

%% Plot 2: Log Line Plots
n = 300;
lfp_colors = ["#ad2bea", "#4d3ff8", "#39cabb", "#53e53a","#e3e12c", "#f7a740", "#ed3838"];
lfp_labels = ["Delta", "Theta", "Alpha", "Beta", "Gamma", "HG1", "HG2"];
for b = 1:numel(Batches)
    batch = Batches{b};
    Organoids = ORGANOIDS.(batch);
    
    % Create figure
    fig = figure;
    fig.Units = 'normalized'; % Set units to normalized for relative sizing
    fig.Position = [0.2, 0.2, 0.6, 0.8]; % [left, bottom, width, height]

    for o = 1:numel(Organoids)
        organoid = Organoids{o};
        Drugs = fieldnames(data_struct.(batch).(organoid));
        
        num_elec = ELECTRODES_INSIDE.(organoid);

        drug_array = [];
        drug_idxs = [];

        for d = 1:numel(Drugs)
            drug = Drugs{d};
            
            d_array = data_struct.(batch).(organoid).(drug);

            % Create array to plot
            if drug == "Control"
                % Plot Array for Control Session
                plot_array1 = condense_array(d_array, n);

                control_idxs = [0, length(plot_array1)];
            else
                drug_idxs = [drug_idxs, length(drug_array)+1];
                drug_array = cat(2, drug_array, d_array);
            end      
        end
        drug_idxs = n*(drug_idxs/length(drug_array)); % normalize ticks
        plot_array2 = condense_array(drug_array, n);
        
        % Find Most Active Electrode
        combined_array = cat(2, plot_array1, plot_array2);
        elec_average = mean(mean(combined_array, 2)./ mean(combined_array, [2,1]), 3);
        active_elec = find(elec_average == max(elec_average(1:num_elec)));
         
        % Plot Vector
        plot_vector1 = permute(plot_array1(active_elec,:,:), [2,3,1]);
        plot_vector2 = permute(plot_array2(active_elec,:,:), [2,3,1]);
        
        % Ylims
        combined_vector = [plot_vector1; plot_vector2];
        lfp_min = min(combined_vector(:,1:7), [], "all");
        lfp_max = max(combined_vector(:,1:7), [], "all");
        fr_min = min(combined_vector(:,8), [], "all");
        fr_max = max(combined_vector(:,8), [], "all");

        % Plot
        % Control
        subplot(numel(Organoids), 2, 2*o-1)
        hold on

        yyaxis left
        for f = 1:7
            plot(1:n, plot_vector1(:,f), '-', 'Color', lfp_colors(f))
        end
        ylim([lfp_min, lfp_max])
        set(gca, 'YScale', 'log');
        ylabel("Frequency Band PSD")
        yyaxis right
        plot(1:n, plot_vector1(:,8), 'k', 'LineWidth', 2)
        ylim([fr_min, fr_max])
        if d == numel(Drugs)
            xticks([.5, n-.5])
            xticklabels(["0", num2str(round(length(control_array)/60))])
            xlabel("Time (hours)")
        end
        title(sprintf("%s / Control / Electrode %d", organoid, active_elec))        

        % Drug
        subplot(numel(Organoids), 2, 2*o) 
        hold on

        yyaxis left
        for f = 1:7
            plot(1:n, plot_vector2(:,f), '-', 'Color', lfp_colors(f), 'DisplayName', lfp_labels(f))
        end
        ylim([lfp_min, lfp_max])
        set(gca, 'YScale', 'log');
        yyaxis right
        plot(1:n, plot_vector2(:,8), 'k', 'LineWidth', 2, 'DisplayName', 'Firing Rate')
        ylim([fr_min, fr_max])
        ylabel("Firing Rate (spikes/s)")   
        if d == numel(Drugs)
            xticks(ceil(drug_idxs))
            xticklabels(["4-AP", "NM", "Bicu", "TTX"])
            xlabel(sprintf("Time (%d hours)", round(length(drug_array)/60)))
        end
        title(sprintf("%s / Drugs / Electrode %d", organoid, active_elec))  

    end

    Lgnd = legend('show', 'Orientation', 'horizontal');
    Lgnd.Position(1) = 0.2;
    Lgnd.Position(2) = .96;
    
end

%% Plot 3
% Freq vs PSD

organoid_data = [];
chimera_data = [];
for b = 1:numel(Batches)
    batch = Batches{b};
    Organoids = ORGANOIDS.(batch);
    
    batch_data = [];
    for o = 1:numel(Organoids)
        organoid = Organoids{o};

        elec_inside = ELECTRODES_INSIDE.(organoid);

        org_data = data_struct.(batch).(organoid).("Control");

        org_lfp_data = permute(mean(mean(org_data(1:elec_inside,:,1:7), 2), 1), [3,1,2]);
        batch_data = [batch_data, org_lfp_data];
    end

    if IS_CHIMERA.(batch)
        chimera_data = cat(3, chimera_data, batch_data);
    else
        organoid_data = cat(3, organoid_data, batch_data);
    end

end

[num_lfp, ~, num_chimera] = size(chimera_data);
[~, ~, num_organoids] = size(organoid_data);

org_avg = permute(mean(organoid_data, 2), [1, 3, 2]);
chimera_avg = permute(mean(chimera_data, 2), [1, 3, 2]);

org_std = permute(std(organoid_data, 0, 2), [1, 3, 2]);
chimera_std = permute(std(chimera_data, 0, 2), [1, 3, 2]);
%%
figure;
hold on;

plot(1:num_lfp, mean(org_avg, 2), 'b', 'LineWidth', 1)
plot(1:num_lfp, mean(chimera_avg, 2), 'r', 'LineWidth', 1)

scatter(repmat(1:num_lfp, [1,num_organoids])', org_avg(:), 'blue', 'filled', 'SizeData', 20)
scatter(repmat(1:num_lfp, [1,num_chimera])', chimera_avg(:), 'red', 'filled', 'SizeData', 20)

set(gca, 'Yscale', 'log')
title("PSD of Organoids and Chimeras (Control)")
ylabel("Power Spectral Density")
xlabel("Frequency Bands")
xticklabels(["Delta", "Theta", "Alpha", "Beta", "Gamma", "HG1", "HG2"])
legend(["Organoids", "Chimeras"])

%% Plot 4 PSD of LFP bands in relation to drug treatements
for b = 1:numel(Batches)
    batch = Batches{b};
    Organoids = ORGANOIDS.(batch);
    
    batch_data = [];
    for o = 1:numel(Organoids)
        organoid = Organoids{o};
        elec_inside = ELECTRODES_INSIDE.(organoid);
        Drugs = fieldnames(data_struct.(batch).(organoid));
        
        organoid_data = [];
        for d = 1:numel(Drugs)
            drug = Drugs{d};

            drug_data = data_struct.(batch).(organoid).(drug);
            drug_data = permute(mean(mean(drug_data(1:elec_inside,:,1:7), 2), 1), [3,1,2]);

            organoid_data = [organoid_data, drug_data];
        end
        
        batch_data = cat(3, batch_data, organoid_data);
    end

    colors = ['k', 'r', 'c', 'm', 'g']; % drugs
    figure;
    hold on;
    
    for d = 1:numel(Drugs)
        plot(1:7, mean(batch_data(:,d,:), 3), 'Color', colors(d), 'LineWidth', 1)
    end
    for d = 1:numel(Drugs)
        scatter(repmat(1:7, [1,4])', reshape(batch_data(:,d,:), 28, 1), colors(d), 'filled', "SizeData", 20)
    end
    set(gca, 'Yscale', 'log')
    title("PSD of Reaction to Drug Treatments")
    ylabel("Power Spectral Density")
    xlabel("Frequency Bands")
    xticklabels(["Delta", "Theta", "Alpha", "Beta", "Gamma", "HG1", "HG2"])
    legend(["Control", "4-AP", "No Drug", "Bicuculline", "Tetrodotoxin"])
end

%% Investigate PSD Slope
LFP_bands = ["Delta", "Theta", "Alpha", "Beta", "Gamma", "HG1", "HG2"];
chimera_mask = [];
array = [];
spike_vector = [];
for b = 1:numel(Batches)
    batch = Batches{b};
    Organoids = ORGANOIDS.(batch);

    for o = 1:numel(Organoids)
        organoid = Organoids{o};
        elec_inside = ELECTRODES_INSIDE.(organoid);

        org_data = data_struct.(batch).(organoid).("Control");
        channel_data = permute(median(org_data(1:elec_inside, :, 1:7), 2), [1,3,2]);
        spike_data = median(org_data(1:elec_inside, :, 8), 2) / 60;

        if IS_CHIMERA.(batch)
            chimera_mask = [chimera_mask; ones(elec_inside, 1)];
        else
            chimera_mask = [chimera_mask; zeros(elec_inside, 1)];
        end
        array = [array; channel_data];
        spike_vector = [spike_vector; spike_data];
    end
end
chimera_mask = logical(chimera_mask);

% figure;
% hold on;
% 
% plot(1:7, array(~chimera_mask, :)', 'b')
% plot(1:7, array(chimera_mask, :)', 'r')
% set(gca, 'Yscale', 'log')

%% Find slope and intercept of each line
coef_array = [];
for i = 1:length(array)
    x = log([2.5, 5.5, 10, 21.5, 40, 90, 165]);
    y = log(array(i,:));

    coef = polyfit(x, y, 1);
    coef_array = [coef_array; coef];
end

org_coef = mean(coef_array(~chimera_mask,:), 1);
chimera_coef = mean(coef_array(chimera_mask,:), 1);
bar_array = [org_coef; chimera_coef]';

figure(4); 
hold on;

bw = .15;
bar(bar_array)

scatter(1-bw*ones(sum(~chimera_mask),1), coef_array(~chimera_mask,1), 3, 'k', 'filled')
scatter(1+bw*ones(sum(chimera_mask),1), coef_array(chimera_mask,1), 3, 'k', 'filled')
scatter(2-bw*ones(sum(~chimera_mask),1), coef_array(~chimera_mask,2), 3, 'k', 'filled')
scatter(2+bw*ones(sum(chimera_mask),1), coef_array(chimera_mask,2), 3, 'k', 'filled')

%%
figure;
hold on;

scatter(spike_vector(~chimera_mask), array(~chimera_mask, 1), 5, 'b')
scatter(spike_vector(chimera_mask), array(chimera_mask, 1), 5, 'r')

set(gca, 'Yscale', 'log')
set(gca, 'Xscale', 'log')

%% Functions

function new_array = condense_array(old_array, n)
    % n = number of discrete time points
    [~, num_min, ~] = size(old_array);
    l = floor(num_min / n);
    
    new_array = [];
    interval = 1:l;

    for i = 1:n
        
        % get average across interval for each channel
        interval_average = mean(old_array(:,interval, :), 2);
        % add onto new array
        new_array = cat(2, new_array, interval_average);
        % advance interval
        if i == n
            interval = interval(end)+1:num_min;
        else
            interval = interval + l;
        end
    end
end