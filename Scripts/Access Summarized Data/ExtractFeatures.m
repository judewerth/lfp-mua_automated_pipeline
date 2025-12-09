function feature_data = ExtractFeatures(data , feature_index)
% The goal of this function is to take the time*channel x orgranoid x feature
% data from GetDataBox and convert it to time x channel x organoid for a
% single feature
%   Input: 
%       data = time*channel x orgranoid x feature array
%       feature = scaler of desired feature
%   Ouput:
%       feature_data = time x channel x organoid array for a single feature
% feature index: [Delta Theta Alpha Beta Gamma HG1 HG2 35 4i 5i]

load("Parameters.mat", "NUM_CHANNELS")

% check that feature is only 1 number
if numel(feature_index) > 1

    disp("Can only use one feature at a time (feature needs to be a scaler)")
    return

end

% cut data based on desired feature
data = data(:,feature_index,:);

% detetermine number of minutes captured in data array
[N , ~ , NUM_PORTS] = size(data);

% reshape to get desired data array
feature_data = reshape(data , [NUM_CHANNELS , N/NUM_CHANNELS , NUM_PORTS]); 
% creates a channel x time x organoid array

