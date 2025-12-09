clear  % Clear all variables from the workspace
clc    % Clear the command window

% Define a structure 'Session' to hold recording sessions for different batches
Session = struct( ...
    "O9_12", struct( ...
        "Control", ["230518_1110" , "230518_1210"], ...
        "x4_AP", ["230518_1225" , "230518_1325"], ...
        "No_Drug", ["230518_1830" , "230518_1930"], ...
        "Bicuculline", ["230519_0930" , "230519_1030"], ...
        "Tetrodotoxin", ["230519_1540" , "230519_1640"]), ...
    "O13_16", struct( ...
        "Control", ["230608_1750","230608_1850"], ...
        "x4_AP", ["230608_1905" , "230608_2005"], ...
        "No_Drug", ["230608_2350" , "230609_0050"], ...
        "Bicuculline", ["230609_1020" , "230609_1120"], ...
        "Tetrodotoxin", ["230609_1540" , "230609_1640"]), ...
    "O17_20", struct( ...
        "Control", ["230712_1155","230712_1255"], ...
        "x4_AP", ["230712_1310" , "230712_1410"], ...
        "No_Drug", ["230712_1825" , "230712_1925"], ...
        "Bicuculline", ["230713_1235" , "230713_1335"], ...
        "Tetrodotoxin", ["230713_1815" , "230713_1915"]), ...
    "O21_24", struct( ...
        "Control", ["240709_1225" , "240709_1325"], ...
        "x4_AP", ["240709_1345" , "240709_1445"], ...
        "No_Drug", ["240709_1800" , "240709_1900"], ...
        "Bicuculline", ["240710_1050" , "240710_1150"], ...
        "Tetrodotoxin", ["240710_1605" , "240710_1705"]), ...
    "O25_28", struct( ...
        "Control", ["241014_1150","241014_1250"], ...
        "x4_AP", ["241014_1305" , "241014_1405"], ...
        "No_Drug", ["241014_1825" , "241014_1925"], ...
        "Bicuculline", ["241015_1330" , "241015_1430"], ...
        "Tetrodotoxin", ["241015_1835" , "241015_1935"]) ...
);

%%
load("Parameters.mat")  % Load additional parameters from 'Parameters.m'

data = FetchData(Session);  % Fetch data using the provided session structure
batches = fieldnames(Session);  % Get batch names
data_struct = struct();

% Thresholds
% Published effect of 4-AP and TTX - 2 stds (closer to 1)
% 4-AP: 327% +- 51% --> 245%
% TTX: 16% +- 16% --> 48%
thresh_4AP = 1.43;
thresh_TTX = .80;

for b = 1:numel(batches)

    batch = batches{b};
    batch_data = data.(batch);
    drugs = fieldnames(batch_data);
    org_ids = ORGANOIDS.(batch);
    data_struct.(batch) = struct();
    
    plot_data = [];
    for d = 1:numel(drugs)

        drug = drugs{d};
        drug_data = batch_data.(drug);

        spike_data = ExtractFeatures(drug_data, 10);
        electrode_data = mean(spike_data, 2);
        plot_data = cat(2, plot_data, electrode_data);

    end
    
    
    for o = 1:4

        organoid_data = plot_data(:,:,o);
        electrodes = el2row(1:NUM_CHANNELS);
        normalized_organoid_data = [organoid_data(electrodes,1)./mean(organoid_data(electrodes,1)), organoid_data(electrodes,2:end)./organoid_data(electrodes,1)];


        % filter electrodes based on thresholds
        E = length(normalized_organoid_data);
        active_electrode_data = [];
        for e = 1:E
            single_electrode_data = normalized_organoid_data(e,:);

            if single_electrode_data(1,2) > thresh_4AP && single_electrode_data(1,5) < thresh_TTX

                active_electrode_data = cat(1,active_electrode_data,[single_electrode_data,e]);
            end

        end
        data_struct.(batch).(org_ids{o}) = normalized_organoid_data;
    end

end

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

%%
% Plot Data with filtered electrodes
figure;
tiledlayout(2, 1); 
hold on;

plot_data = struct();
plot_data.("organoid") = struct();
plot_data.("chimera") = struct();

org_data = [];
chimera_data = [];
org_sum = 0;
for b = 1:numel(batches)
    batch = batches{b};

    is_chimera = IS_CHIMERA.(batch);

    batch_data = data_struct.(batch);
    organoids = fieldnames(batch_data);
    
    for o = 1:numel(organoids)
        organoid = organoids{o};
        organoid_data = batch_data.(organoid);

        if ~isempty(organoid_data)
            electrodes_inside = ELECTRODES_INSIDE.(organoid);
            inside = ismember(organoid_data(:,6), 1:electrodes_inside);
            org_avg = mean(organoid_data(inside,1:5), 1);
            org_std = std(organoid_data(inside,1:5), 0, 1);
            [org_sz,~] = size(organoid_data(inside,1:5));
            org_sum = org_sum + org_sz;
          
            if is_chimera
                x = x_values(2*(1:5));

                plot_data.("chimera").(organoid) = organoid_data;

                scatter(x, org_avg , 10*org_sz ,'k' ,'filled')
                errorbar(x, org_avg, org_std, 'k', 'LineStyle', 'none')

                chimera_data = cat(1, chimera_data, org_avg);
            else
                x = x_values(2*(1:5)-1);

                plot_data.("organoid").(organoid) = organoid_data;

                scatter(x, org_avg, 10*org_sz, 'k', 'filled')
                errorbar(x, org_avg, org_std , 'k', 'LineStyle', 'none')
                
                org_data = cat(1, org_data, org_avg);
            end
        end
        
    end
end

bar(x_values(2*(1:5)-1) , mean(org_data, 1), bar_width/2, 'blue')
bar(x_values(2*(1:5)) , mean(chimera_data, 1), bar_width/2,  'red')
%%
% Define plot parameters
xlabels = ["Control", "4-AP", "Normal Media", "Bicuculline", "TTX"]; % Drug treatments
colors = {'r', 'b'};                   % Colors for inside (red) and outside (blue)

% Prepare figure
figure;
tiledlayout(2, 2); % Create 2x2 subplot layout

% Loop through organoids
for o = 1:length(org_ids)
    % Create a subplot for the current organoid
    nexttile;
    hold on;

    % Get electrodes inside the organoid
    electrodes_inside = ELECTRODES_INSIDE.(org_ids{o});
    electrodes_inside_data = plot_data(1:electrodes_inside, :, o); % Inside electrodes data
    electrodes_outside_data = plot_data(electrodes_inside+1:end, :, o); % Outside electrodes data

    % Plot each inside electrode (no legend duplication)
    for e = 1:electrodes_inside
        plot(1:5, electrodes_inside_data(e, :), 'Color', colors{1}, ...
             'LineWidth', 1, 'MarkerFaceColor', colors{1}, 'HandleVisibility', 'off');
    end
    % Add a single representative line for "Inside" to the legend
    plot(NaN, NaN, 'Color', colors{1}, 'LineWidth', 1, 'DisplayName', 'Inside');

    % Plot each outside electrode (no legend duplication)
    for e = 1:size(electrodes_outside_data, 1)
        plot(1:5, electrodes_outside_data(e, :), 'Color', colors{2}, ...
             'LineWidth', 1, 'MarkerFaceColor', colors{2}, 'HandleVisibility', 'off');
    end
    % Add a single representative line for "Outside" to the legend
    plot(NaN, NaN, 'Color', colors{2}, 'LineWidth', 1, 'DisplayName', 'Outside');

    % Formatting for the subplot
    xticks(1:5);
    xticklabels(xlabels);
    xlabel('Drug Treatments');
    ylabel('Plot Data Values');
    title(['Organoid ', org_ids{o}]);
    grid on;
    legend('Location', 'best'); % Add a legend for each subplot
    hold off;
end

% Add overall title
sgtitle('Electrode Response for Drug Treatments by Organoid');

%%
organoid_data = [];
chimera_data = [];

for b = 1:numel(batches)
    batch = batches{b};

    batch_data = data_struct.(batch);
    is_chimera = IS_CHIMERA.(batch);
    organoids = ORGANOIDS.(batch);

    for o = 1:numel(organoids)
        organoid = organoids{o};

        org_data = batch_data.(organoid);
        electrodes_inside_organoid = el2row(1:ELECTRODES_INSIDE.(organoid));

        if is_chimera
            chimera_data = cat(1, chimera_data, org_data(electrodes_inside_organoid,:));
        else
            organoid_data = cat(1, organoid_data, org_data(electrodes_inside_organoid,:));
        end

    end

end

%%
figure_titles = ["Electrode Firing Rates / Organoid Mean Firing Rate", ...
                 "4-AP Firing Rates / Control Firing Rates", ...
                 "Normal Media Firing Rates / Control Firing Rates", ...
                 "Bicuculline Firing Rates / Control Firing Rates", ...
                 "TTX Firing Rates / Control Firing Rates"];

xaxislabel = "Number of Electrodes";
yaxislabel = "Normalized Firing Rate";
legendlabel = ["Organoids", "Chimeras"];

for i = 1:5
    
    figure;
    hold on;

    h1 = histogram(organoid_data(:,i));
    h2 = histogram(chimera_data(:,i));

    h1.BinWidth = 0.25;
    h2.BinWidth = 0.25;

    title(figure_titles(i))
    xlabel(xaxislabel)
    ylabel(yaxislabel)
    legend(legendlabel)

    if i == 5
        xlim([0,15])
        xticks(0:2:15)
    else
        if max(organoid_data(:,i)) > max(chimera_data(:,1))
            plot_max = max(organoid_data(:,i));
        else
            plot_max = max(chimera_data(:,i));
        end
        xticks(0:2:ceil(plot_max))
    end


end
