function data = LoadData(batch , date, take_average)
% This function is used to load date created from summarize_organoid_data
% Make sure PROCESSED_DATA_DIR leads to the correct folder and the format
% is as the function created.

% Inputs: 
%   batch (parent folder)
%   date (YYMMDD)

% Output:
%   Data Cell (1440x2)

load("Parameters.mat",  "PROCESSED_DATA_DIR")

% Get outputdir
if take_average
    output_dir = fullfile(PROCESSED_DATA_DIR , "Processed Data (mean)");
else
    output_dir = fullfile(PROCESSED_DATA_DIR , "Processed Data (median)");
end

% load file will either be date.mat or date-.mat
if exist(fullfile(output_dir, batch, date+"-.mat") , "file")
    load(fullfile(output_dir, batch, date+"-.mat") , "data")

elseif exist(fullfile(output_dir, batch, date+".mat") , "file")
    load(fullfile(output_dir, batch, date+".mat") , "data")

else
    error(sprintf("Couldn't Find Data File (%s)\n" , fullfile(output_dir, batch, date+"(-).mat")))

end
