clear
clc

file_prefix = "O**-**"; % replace with organoid prefixes
% IMPORTANT: the file prefix neds to be the same as the rhd prefix
% files being saved should look like "(file_prefix)_YYMMDD_HHMMSS.rhd"

for i = 1:100000 % Relatively Infinite Loop (Cntrl C to cancel)
    
    MoveIncompleteData()
    % This function moves and .rhd which aren't the specified size to
    % D:\bad_data. process_organoid_data generates errors on incomplete
    % rhd files (recordings which don't last for the full 60 seconds)
    % This only happens at the end of recording sessions

    process_organoid_data({sprintf('%s*' , file_prefix)})
    % This functions takes rhd files and creates a 479x1280 matlab
    % array of summary features (more details in function). Each array
    % is summary data for 1 minute

    summarize_organoid_data(true) % summarizes via mean
    summarize_organoid_data(false) % summarizes via median
    % This function takes the minute arrays from process_organoid_data
    % and creates 32x10x4 arrays (channelsxfeaturesxorganoids) for each
    % minute. Data is stored in a cell array with a labeled time. Cell
    % arrays are stored in .mat files for each day (in Box Sync). 
end