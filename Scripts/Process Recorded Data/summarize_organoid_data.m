function summarize_organoid_data(take_average)
% This function takes all the .mat files in it's current directory and
% creates 1440(for a full day or recording) X 2 cell. Each row will contain
% the time ("0000" format) and a 32x10x4 array containing data for each
% channel, feature, and port

% creates directory folders at processed_dir (parameter) for batch name
% then creates files based on the date which contain data for that day.
% Days which are full of data will be marked with a "*"

load("Parameters.mat", "PROCESSED_DATA_DIR") % PROCESSED_DATA_DIR = datapath to store the processed data

% Get outputdir -> based on whether we want to store the mean or median
if take_average 
    output_dir = fullfile(PROCESSED_DATA_DIR , "Processed Data (mean)");
else
    output_dir = fullfile(PROCESSED_DATA_DIR , "Processed Data (median)");
end

% Get File names in current directory
directory = dir();
file_names = {directory.name};
file_names = file_names(endsWith(file_names , ".mat"));

name_cell = split(file_names , "_");
% name_cell = 1*NUM_FILES*3 --> in the 3 direction: [batch_prefix, date,
% time]
batches = unique(name_cell(:,:,1));

for b = 1:numel(batches)
    batch = batches{b};

    if ~exist( fullfile(output_dir , batch) , "dir") % If no batch folder
        mkdir(fullfile(output_dir , batch)) % Create folder
        fprintf("No Batch Folder Found, Creating (%s) \n" , batch)
    end

    % Get files for specific batch
    batch_files = file_names(contains(name_cell(:,:,1) , batch)); 
    % Get the [batch, date, time] for all files of a specific batch
    batch_cell = split(batch_files , "_");
    dates = unique(batch_cell(:,:,2)); % get the specific dates within the batch files

    for d = 1:numel(dates)
        date = dates{d};

        date_files = batch_files(contains(batch_cell(:,:,2) , date)); % get files for a specific date
        date_cell = split(date_files , "_");
        times = date_cell(:,:,3); % get times of files of a specific batch and date
        
        % extract hour and minute data from each time value
        hourminute = cellfun(@(x) x(1:4), times, 'UniformOutput', false);
        % reformat from HHMMSS -> HHMM

        if exist( fullfile(output_dir, batch, strcat(date,'-.mat') ) , "file")
            fprintf("Full Data File (%s-.mat) Found\n" , date)
            continue % if marked date file is found skip loop iteration

        elseif exist( fullfile(output_dir, batch, strcat(date,'.mat') ) , "file")
            fprintf("Date File Found (%s.mat): Updating if Possible\n" , date)

            load(fullfile(output_dir, batch, strcat(date,'.mat')) , "data")
            % if there is a data file but it's not marked (full) we need to
            % determine if there's any new data we can add 

            % find times in current directory but not in data file
            no_data_times = data( strcmp(data(:,2),'NO DATA') , 1);
            new_times = hourminute(ismember( hourminute , no_data_times));
            
            % loop through new times and insert into data cell
            for t = 1:numel(new_times)
                new_time = new_times{t};
                fprintf("Adding Data for %s\n" , new_time)

                % find index 
                index = find( strcmp(data(:,1),new_time) );

                % convert time back to HHMMSS.mat
                new_time = char(times(startsWith(times , new_time)));

                % load file and insert into global cell array
                load_file = strjoin({batch,date,new_time},'_');
                load(load_file , 'features')

                data{index,2} = SummarizeData(features , take_average);

            end

        else % if there is no file for this day
            fprintf("No date File Found: Creating %s.mat\n" , date)

            data = cell(1440 , 2); % empty cell
            
            % Fill Data Times
            i = 1;
            for h = 0:23
                for m = 0:59
                    data{i,1} = sprintf('%02d%02d', h, m);  % Format 'HHMM'
                    i = i + 1;
                end
            end

            for t = 1:length(data) % loop through each minute iteration
                time = data{t,1};

                if ismember(time , hourminute)

                    % convert HHMM --> HHMMSS.mat
                    insert_time = char(times(startsWith(times , time)));

                    % load file and insert into global cell array
                    load_file = strjoin({batch,date,insert_time},'_');
                    load(load_file , 'features')
    
                    data{t,2} = SummarizeData(features , take_average);

                else
                    data{t,2} = 'NO DATA';
                    fprintf("No Data Found for %s_%s\n",date,time)

                end % if statement (time in time)
            end % time loop
        end % if statement (datefile in dir)

        % Save data for date
        if any(strcmp(data(:,2),'NO DATA'))
            save_file = strcat(date , '.mat');
            fprintf("Saving incomplete date file: %s.mat\n" , date)
        else
            save_file = strcat(date , '-.mat');
            fprintf("Saving complete date file: %s.mat\n" , date)
        end

        save( fullfile(output_dir, batch, save_file) , "data")

    end % date loop

end % batch loop

