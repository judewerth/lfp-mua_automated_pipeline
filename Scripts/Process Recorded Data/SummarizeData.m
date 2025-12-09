function summary_data = SummarizeData(raw_data , take_average)

% This function takes raw feature data and processes it to summary data
% so it can be stored on a laptop.
% summary_data = average(or median) frequency ampltide and total spike count (32x10x4)
% raw_data = 1280x479 features

% features = num_organoids*num_features*num_channels X time iterations
% (1minute with fs = 20000)
%       port -> feature -> channel

% Change Summary Method (take_average)
% true = mean() , false = median()

% Parameters:
load("Parameters.mat", "NUM_CHANNELS", "NUM_FEATURES")
[n , ~] = size(raw_data); 
% based on the way the raw_data is formatted (479x1280) this will extract
% NUM_CHANNELS*NUM_FEATURES*NUM_PORTS

% Indexes:
port_index = 0 : NUM_CHANNELS*NUM_FEATURES : n; 
% featuers is broken seperated (rows) by port data.
% this breaks up the data based on the port recorded from
% 0 , 320 , 640 , 960 , 1280
NUM_PORTS = length(port_index) - 1; 

% Organize Data:
summary_data = zeros(NUM_CHANNELS , NUM_FEATURES , NUM_PORTS); % initialize data

for port = 1:NUM_PORTS
    
    % raw data --> data from single port
     port_data = raw_data( port_index(port)+1:port_index(port+1) , :);

    % Summarize data file:
    if take_average
        summary_port_data = mean(port_data , 2); % mean
    else
        summary_port_data = median(port_data , 2); % median
    end
    
    % this is the data for the LFP sessions (mean or median)
    summary_port_data = reshape(summary_port_data , [NUM_FEATURES,NUM_CHANNELS])'; % reshape into channelsxfeatures
    
    % Store summary data in global array
    % LFP data will be stored in mean/median format (per iteration)
    % Spike Data will be in total for the entire minute
    
    % this is the data for spike detection
    sum_port_data = sum(port_data , 2);
    sum_port_data = reshape(sum_port_data , [NUM_FEATURES,NUM_CHANNELS])';
    
    % out of the 10 features, the first 7 quantify the LFP signal and the
    % final 3 are the spike counts at different thresholds
    lfp_data = summary_port_data(: , 1:7);
    spike_data = sum_port_data(: , 8:10);

    % put into global array
    summary_data(:,:,port) = [lfp_data , spike_data];

end
