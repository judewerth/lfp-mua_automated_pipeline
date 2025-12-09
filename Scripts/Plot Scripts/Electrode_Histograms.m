clear
clc

Session = struct( ...
    "O9_12", struct( ...
        "Control1", ["230504_0300" , "230504_0400"], ...
        "Control2", ["230518_1110" , "230518_1210"], ...
        "x4_AP", ["230518_1225" , "230518_1325"], ...
        "No_Drug", ["230518_1830" , "230518_1930"], ...
        "Bicuculline", ["230519_0930" , "230519_1030"], ...
        "Tetrodotoxin", ["230519_1540" , "230519_1640"]), ...
    "O13_16", struct( ...
        "Control1", ["230526_0300" , "230526_0400"], ...
        "Control2", ["230608_1750","230608_1850"], ...
        "x4_AP", ["230608_1905" , "230608_2005"], ...
        "No_Drug", ["230608_2350" , "230609_0050"], ...
        "Bicuculline", ["230609_1020" , "230609_1120"], ...
        "Tetrodotoxin", ["230609_1540" , "230609_1640"]), ...
    "O17_20", struct( ...
        "Control1", ["230623_0300" , "230623_0400"], ...
        "Control2", ["230712_1155","230712_1255"], ...
        "x4_AP", ["230712_1310" , "230712_1410"], ...
        "No_Drug", ["230712_1825" , "230712_1925"], ...
        "Bicuculline", ["230713_1235" , "230713_1335"], ...
        "Tetrodotoxin", ["230713_1815" , "230713_1915"]), ...
    "O21_24", struct( ...
        "Control1", ["240702_0300" , "240702_0400"], ...
        "Control2", ["240709_1225" , "240709_1325"], ...
        "x4_AP", ["240709_1345" , "240709_1445"], ...
        "No_Drug", ["240709_1800" , "240709_1900"], ...
        "Bicuculline", ["240710_1050" , "240710_1150"], ...
        "Tetrodotoxin", ["240710_1605" , "240710_1705"]), ...
    "O25_28", struct( ...
        "Control1", ["241002_0300" , "241002_0400"], ...
        "Control2", ["241014_1150","241014_1250"], ...
        "x4_AP", ["241014_1305" , "241014_1405"], ...
        "No_Drug", ["241014_1825" , "241014_1925"], ...
        "Bicuculline", ["241015_1330" , "241015_1430"], ...
        "Tetrodotoxin", ["241015_1835" , "241015_1935"]) ...
);

load("Parameters.mat")  % Load additional parameters from 'Parameters.m'

data = FetchData(Session);  % Fetch data using the provided session structure
%% Get Data

control_data = struct();
drug_data = struct();

batches = fieldnames(Session);  % Get batch names
B = numel(batches);
for b = 1:B
    batch = batches{b};
    batch_data = data.(batch);
    
    organoids = ORGANOIDS.(batch);
    O = numel(organoids);

    drugs = fieldnames(batch_data);
    D = numel(drugs);
    for d = 1:D
        drug = drugs{d};

        spike_data = ExtractFeatures(batch_data.(drug), 10);
        spike_data = spike_data(el2row(1:32), :, :); % reorder electrodes according to mapping

        firing_rates = permute(median(spike_data, 2), [1,3,2]) / 60;
        spike_std = permute(std(spike_data, 0, 2), [1,3,2]);        

        for o = 1:O
            organoid = organoids{o};
       
            elec_inside = ELECTRODES_INSIDE.(organoid);
            inside_data = firing_rates(1:elec_inside, o);
            outside_data = firing_rates(elec_inside+1:end, o);
            
            % Get Data for Control Organoids
            if startsWith(drug, "Control")

                data_cell = {inside_data, outside_data; ...
                    spike_std(1:elec_inside, o), spike_std(elec_inside+1:end, o)};

                cntrl_idx =  str2double(drug(end));
                control_data.(organoid)(:,:,cntrl_idx) = data_cell;
               
            else
                drug_idx = d-2; % [4-AP, Overnight, Bicuculline, TTX]
                drug_data.(organoid)(drug_idx,:) = {inside_data./control_data.(organoid){1,1,2}, ...
                                                    outside_data./control_data.(organoid){1,2,2}};
        
            end
        end
        
    end

end

%% Plot #1: Drug Line Plots --> Find Electrodes of Interest

% Electrodes of Interest (Average):
% 009:
% O10:
% O11:
% O12:
% O13:
% O14:
% O15: 8
% O16: 7, 8, 10
% O17: 19, 21, 22
% O18: 5, 6, 7, 10, 12, 18
% O19:
% O20:
% O21:
% O22: 
% O23: 17, 19
% O24: 
% O25:
% O26: 16
% O27: 10
% O28: 10, 20

% Electrodes of Interest (Median):
% 009:
% O10:
% O11:
% O12: 2
% O13: 20, 21
% O14:
% O15: 
% O16: 4
% O17: 19, 22
% O18: 5, 6, 7, 10, 12, 18
% O19:
% O20: 13
% O21: 17
% O22: 14
% O23: 
% O24: 
% O25:
% O26: 
% O27: 10
% O28: 20
elec_of_interest = struct('O12', 2, 'O13', [20, 21], 'O16', 4, 'O17', [19, 22],...
    'O18', [5, 6, 7, 10, 12, 18], 'O20', 13, 'O21', 17, 'O22', 14, 'O27', 10, 'O28', 20);

plot_organoids = fieldnames(drug_data);
for f = 1:numel(plot_organoids)
    plot_organoid = plot_organoids{f};

    plot_cell = drug_data.(plot_organoid)(:,1);
    plot_data = [ones(size(plot_cell{1})), plot_cell{1}, plot_cell{2}, plot_cell{3}, plot_cell{4}]';

    figure;
    hold on
    if ismember(plot_organoid, fieldnames(elec_of_interest))
        is_elec_interest = ismember(1:length(plot_data), elec_of_interest.(plot_organoid));

        plot(plot_data(:,is_elec_interest), 'k', 'LineWidth', 1)
        plot(plot_data(:,~is_elec_interest), 'r')

    else

        plot(plot_data, 'r')
    end
    
    xticks(1:5)
    xticklabels(["Control", "4-AP", "Overnight", "Bicuculline", "TTX"])
    ylabel("Drug Firing Rate / Control Firing Rate (spikes/s)")
    title(sprintf("Normalized Firing Rate for Individual Electrodes Inside Organoid \n %s", plot_organoid))
    
end

%% Plot #2 & #3 Control Histograms (Z-score)

plot_organoids = fieldnames(control_data);

for f = 1:numel(plot_organoids)
    plot_organoid = plot_organoids{f};

    plot_cell = control_data.(plot_organoid);

    ub = mean([plot_cell{1,1,1}; plot_cell{1,2,1}]);
    sb = std([plot_cell{1,1,1}; plot_cell{1,2,1}]);
    ua = mean([plot_cell{1,1,2}; plot_cell{1,2,2}]);
    sa = std([plot_cell{1,1,2}; plot_cell{1,2,2}]);

    % Figure 1: Before
    plot_inside = (plot_cell{1,1,1} - ub) / sb;
    plot_outside = (plot_cell{1,2,1} - ub) / sb;

    figure;
    hold on;
    h1 = histogram(plot_inside);
    h2 = histogram(plot_outside);
    h1.BinWidth = 0.25;
    h2.BinWidth = 0.25;

    if ismember(plot_organoid, fieldnames(elec_of_interest))
        xline(plot_inside(elec_of_interest.(plot_organoid)), 'LineWidth' , 2)
    end

    title(sprintf("Firing Rate z-scores for Organoid Electrodes \n t=Implantation, %s", plot_organoid))
    xlabel("z-scores (x-u)/s")
    ylabel("Number of Electrodes")
    legend(["Inside", "Outside"])

    % Figure 1: After
    plot_inside = (plot_cell{1,1,2} - ua) / sa;
    plot_outside = (plot_cell{1,2,2} - ua) / sa;

    figure;
    hold on;
    h1 = histogram(plot_inside);
    h2 = histogram(plot_outside);
    h1.BinWidth = 0.25;
    h2.BinWidth = 0.25;

    if ismember(plot_organoid, fieldnames(elec_of_interest))
        xline(plot_inside(elec_of_interest.(plot_organoid)), "LineWidth", 2)
    end

    title(sprintf("Firing Rate z-scores for Organoid Electrodes \n t=drug introduction, %s", plot_organoid))
    xlabel("z-scores (x-u)/s")
    ylabel("Number of Electrodes")
    legend(["Inside", "Outside"])

end

%% Plot #4 Average Firing Rate Bar Plots

plot_organoids = fieldnames(control_data);
inside_data = [];
outside_data = [];
interest_data = [];
for f = 1:numel(plot_organoids)
    plot_organoid = plot_organoids{f};

    plot_cell = control_data.(plot_organoid);

    inside_data = cat(1, inside_data, cat(3, [plot_cell{1,1,1}, plot_cell{2,1,1}], [plot_cell{1,1,2}, plot_cell{2,1,2}]));
    outside_data = cat(1, outside_data, cat(3, [plot_cell{1,2,1}, plot_cell{2,2,1}], [plot_cell{1,2,2}, plot_cell{2,2,2}]));

    if ismember(plot_organoid, fieldnames(elec_of_interest))
        interest_org = cat(3, [plot_cell{1,1,1}, plot_cell{2,1,1}], [plot_cell{1,1,2}, plot_cell{2,1,2}]);
        interest_org = interest_org(elec_of_interest.(plot_organoid),:,:);
        interest_data = cat(1, interest_data, interest_org);
    end


end

inside_avg = mean(inside_data, 1);
outside_avg = mean(outside_data, 1);
interest_avg = mean(interest_data, 1);

bar_array = permute(cat(1, outside_avg, inside_avg, interest_avg), [1,3,2]);


subplot(2,1,1)
bar(bar_array(:,:,1))
xticklabels(["Outside Electrodes", "Inside Electrodes", "Electrodes of Interest"])
ylabel("Average Firing Rate (spikes/s)")
title("Average Firing Rate, Control Session, All Organoids and Chimeras")
legend(["After Organoid Implantation", "Before Drug Introduction"])

subplot(2,1,2)
bar(bar_array(:,:,2))
xticklabels(["Outside Electrodes", "Inside Electrodes", "Electrodes of Interest"])
ylabel("Variation (std) of Firing Rate (spikes/s)")
title("Firing Rate std across one hour")
