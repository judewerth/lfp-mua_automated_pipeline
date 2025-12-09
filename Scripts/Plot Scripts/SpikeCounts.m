clear  % Clear all variables from the workspace
clc    % Clear the command window

% Define a structure 'Session' to hold recording sessions for different batches
Session = struct( ...
    "O21_24", struct( ...
        "Control", ["240702_0100","240702_0200"]), ...
    "O25_28", struct( ...
        "Control", ["241002_0100","241002_0200"]) ...
);

load("Parameters.mat")  % Load additional parameters from 'Parameters.m'

data = FetchData(Session);  % Fetch data using the provided session structure

spike_5i_B4 = ExtractFeatures(data.O21_24.Control, 10);
spike_35_B4 = ExtractFeatures(data.O21_24.Control, 8);

spike_5i_B5 = ExtractFeatures(data.O25_28.Control, 10);
spike_35_B5 = ExtractFeatures(data.O25_28.Control, 8);
%%

spike_cell = cell(4,2,2);

batches = fieldnames(Session);

for b = 1:numel(batches)
    batch = batches{b};

    organoids = ORGANOIDS.(batch);
    for o = 1:numel(organoids)
        organoid = organoids{o};
        electrodes_inside_organoid = el2row(1:ELECTRODES_INSIDE.(organoid));

        spike_35 = ExtractFeatures(data.(batch).Control, 8);
        spike_5i = ExtractFeatures(data.(batch).Control, 10);

        organoid_data = {spike_35(electrodes_inside_organoid,:,o), spike_5i(electrodes_inside_organoid,:,o)};

        spike_cell(o,:,b) = organoid_data;


    end

end
