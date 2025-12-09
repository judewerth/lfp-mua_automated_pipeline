function data_struct = FetchData(Session , take_average)

    % This function is meant to fetch 32x10x4 arrays from Summary Data and turn
    % them into nested structs
    % data struct format:
    %   data_struct --> batch_id --> drug_id
    %       data_struct --> [O09-12, O13-16, 017-20,...] --> [Control, 4-AP, No Drug, Bicuculline, Tetrodotoxin]
    %           output values are stacked summary data arrays
    % Session format:
    %   Session --> batch_id --> drug_id (same as data_struct)
    %       batch_id --> 
    %           drug_id = [] -> all times , [start_time , end_time] --> those
    %           times 
    
    load("Parameters.mat", "DRUG_TIMES")
    
    % Default: Take the mean (false=median)
    if nargin < 2
        take_average = true;
    end
    
    % Construct data_struct 
    % Session format needs to mirror DRUG_TIMES (batch --> drugs)
    
    batches = fieldnames(Session);
    
    for b = 1:numel(batches)
        batch = batches{b};
    
        batch_session = Session.(batch);
        drugs = fieldnames(batch_session);
    
        for d = 1:numel(drugs)
            drug = drugs{d};
            
            % Get Session Date and Time information
            if isempty(Session.(batch).(drug))
                session_time = DRUG_TIMES.(batch).(drug);
            else
                session_time = Session.(batch).(drug);
            end
            
            time_cell = permute(split(session_time , "_") , [2,3,1]);
            start_date = time_cell(1,1);
            start_time = time_cell(1,2);
            end_date = time_cell(2,1);
            end_time = time_cell(2,2);
    
            date_list = generateDateList(start_date , end_date);
            
            % Get Session Data (data for batch and drug)
            session_data = [];
            for i = 1:numel(date_list)
                date = date_list{i};
                
                % Load Data File
                data = LoadData(strrep(batch,"_","-") , date , take_average);
    
                % Find Endpoints (with respect to the date)
                if i == 1
                    start_index = find(strcmp(data(:,1) , start_time));
                else
                    start_index = 1;
                end
    
                if i == numel(date_list)
                    end_index = find(strcmp(data(:,1) , end_time));
                else
                    end_index = length(data);
                end
                  
                % Fetch and Stack data arrays for session
                for ii = start_index:end_index
                    time_data_array = data{ii,2};
    
                    if ischar(time_data_array)
                        fprintf("Warning: No Data Found for %s/%s/%s\n" , batch , date , data{ii,1})
                    else
                        session_data = cat(1 , session_data , data{ii,2});
                    end
    
                end
    
    
            end
    
            data_struct.(batch).(drug) = session_data;
    
        end
    
    end

end


function dateList = generateDateList(startDate, endDate)
    % Generate a list of all dates between startDate and endDate (inclusive)
    startDateNum = datenum(startDate, 'yymmdd');
    endDateNum = datenum(endDate, 'yymmdd');
    dateList = arrayfun(@(d) datestr(d, 'yymmdd'), startDateNum:endDateNum, 'UniformOutput', false);
end