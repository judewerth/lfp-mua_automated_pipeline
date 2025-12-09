clear
clc

load("Parameters.mat")  % Load additional parameters from 'Parameters.m'
data = load("data.mat");

%% Reorganize Data for all Plots
% Set up struct in the structure:
%    Batch --> Organoid --> Control/Drug --> [Channels x Time x Feature]

Batches = fieldnames(data);
data_struct = struct();
B = 2;
O = 1;
for b = B:B
    batch = Batches{b};
    Organoids = ORGANOIDS.(batch);
    Drugs = fieldnames(data.(batch));

    data_struct.(batch) = struct();

    for o = O:O
        organoid = Organoids{o};

        data_struct.(batch).(organoid) = struct();
        elec_mapping = el2row(1:32);

        for d = 1:numel(Drugs)
            drug = Drugs{d};
            
            drug_data = data.(batch).(drug);
            data_array = [];
            active_features = [1:7, 10]; % all frequency bands and 5i threshold

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


%% Firing Map
n = 100;
plot_f = 8;
Batches = fieldnames(data_struct);
for b = 1:numel(Batches)
    batch = Batches{b};
    Organoids = fieldnames(data_struct.(batch));
    
    % Create figure
    fig = figure;
    fig.Units = 'normalized'; % Set units to normalized for relative sizing
    fig.Position = [0.2, 0.2, 0.6, 0.4]; % [left, bottom, width, height]
    
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
        yline(num_elec, 'Color', [.9, .9, .9], 'LineWidth', 10, 'Label', 'Channels Outside the Organoid', 'LabelHorizontalAlignment','left')
        
        if num_elec == 32
            yticks([0, 32])
        else
            yticks([1, num_elec, 32])
        end
        ylabel("Channels", "FontSize", 12, "FontWeight","bold")

        xticks([.5, n-.5])
        xticklabels(["0", num2str(round(length(control_array)/60))])
        xlabel("Time (hours)", "Position",[105, -2], "FontSize", 12, "FontWeight","bold")

        title("Control Recording", "FontSize", 15)

        % Drug
        a2 = subplot(numel(Organoids), 2, 2*o);
        a2.Position = [0.53, 0.15, 0.455, 0.7];
        hold on
        axis tight

        imagesc(plot_array2, clims)
        colormap(gca, jet)
        yline(num_elec, 'Color', [.9, .9, .9], 'LineWidth', 10)
        for idx = drug_idxs
            xline(idx+.5, 'w', 'LineWidth', 3)
        end
        cbar = colorbar;
        xlabel(cbar, "Hz", "Position", [.5,4.65], "Rotation",360,"FontWeight","bold")
        yticks([])

        xticks([ceil(drug_idxs), n-.5])
        xticklabels(["4-AP", "NM", "Bicu", "TTX", num2str(round(length([control_array, drug_array])/60))])


        title("Drug Recording", "FontSize", 15)
    end
    sgtitle("Single Organoid Firing Map", "FontWeight", "bold", "FontSize", 20)
end

%% LFP Plots

n = 250;
lfp_colors = ["#ad2bea", "#4d3ff8", "#39cabb", "#53e53a","#e3e12c", "#f7a740", "#ed3838"];
lfp_labels = ["Delta", "Theta", "Alpha", "Beta", "Gamma", "HG1", "HG2"];
Batches = fieldnames(data_struct);

for b = 1:numel(Batches)
    batch = Batches{b};
    Organoids = fieldnames(data_struct.(batch));
    
    % Create figure
    fig = figure;
    fig.Units = 'normalized'; % Set units to normalized for relative sizing
    fig.Position = [0.2, 0.2, 0.6, 0.4]; % [left, bottom, width, height]

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
                control_array = d_array;
                plot_array1 = condense_array(control_array, n);

            else
                drug_idxs = [drug_idxs, length(drug_array)+1];
                drug_array = cat(2, drug_array, d_array);
            end      
        end
        drug_idxs = n*(drug_idxs/length(drug_array)); % normalize ticks
        plot_array2 = condense_array(drug_array, n);
        
        % Find Most Active Electrode
        combined_array = cat(2, plot_array1, plot_array2);
        elec_average = mean(combined_array(:,:,8), 2);
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
        a1 = subplot(numel(Organoids), 2, 2*o-1);
        a1.Position = [0.05, 0.15, 0.425, 0.7];
        hold on

        yyaxis left
        for f = 1:7
            plot(1:n, plot_vector1(:,f), '-', 'Color', lfp_colors(f))
        end
        ylim([lfp_min, lfp_max])
        set(gca, 'YScale', 'log');
        ylabel("Frequency Band PSD", "FontSize",12,"FontWeight","bold")
        yyaxis right
        yticks([])
        plot(1:n, plot_vector1(:,8), 'k', 'LineWidth', 2)
        ylim([fr_min, fr_max])
        if d == numel(Drugs)
            xticks([.5, n-.5])
            xticklabels(["0", num2str(round(length(control_array)/60))])
            xlabel("Time (hours)", "Position",[265, .0001], "FontSize", 12, "FontWeight","bold")
        end
        title("Control Recording", "FontSize", 15)        

        % Drug
        a2 = subplot(numel(Organoids), 2, 2*o);
        a2.Position = [0.525, 0.15, 0.425, 0.7];
        hold on

        yyaxis left
        for f = 1:7
            plot(1:n, plot_vector2(:,f), '-', 'Color', lfp_colors(f), 'DisplayName', lfp_labels(f))
        end
        ylim([lfp_min, lfp_max])
        yticks([])
        set(gca, 'YScale', 'log');
        yyaxis right
        plot(1:n, plot_vector2(:,8), 'k', 'LineWidth', 2, 'DisplayName', 'Firing Rate')
        ylim([fr_min, fr_max])
        ylabel("Firing Rate (Hz)", "FontSize",12,"FontWeight","bold")   
        if d == numel(Drugs)
            xticks([ceil(drug_idxs), n-.5])
            xticklabels(["4-AP", "NM", "Bicu", "TTX", num2str(round(length([control_array, drug_array])/60))])
        end
        title("Drug Recording", "FontSize", 15)  

    end

    Lgnd = legend('show', 'Orientation', 'horizontal');
    Lgnd.Position(1) = 0.19;
    Lgnd.Position(2) = .81;
    
    sgtitle("Active Electrode LFP Power and Firing Rate", "FontWeight", "bold", "FontSize", 20)
end
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