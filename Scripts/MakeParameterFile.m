function MakeParameterFile()
    % Make New Parameter File (Paramater.mat) from xlsx sheet.
    
    warning('off' , 'all')
    
    NUM_CHANNELS = 32;
    NUM_FEATURES = 10;
    
    PROCESSED_DATA_DIR = strrep(pwd, "\Scripts" , "");
    
    ORGANOIDS = struct();
    ELECTRODES_INSIDE = struct();
    IS_CHIMERA = struct();
    DRUG_TIMES = struct();
    
    filename = fullfile(PROCESSED_DATA_DIR, "RecordingLog.xlsx");
    
    batch_names = sheetnames(filename);
    
    for b = 1:numel(batch_names)
        batch = batch_names(b);
    
        ORGANOIDS.(batch) = [...
            readSingleCell(filename , batch , 'B2'), ...
            readSingleCell(filename , batch , 'B3'), ...
            readSingleCell(filename , batch , 'B4'), ...
            readSingleCell(filename , batch , 'B5') ...
        ];
    
    
        for o = 1:numel(ORGANOIDS.(batch))
            organoid = ORGANOIDS.(batch){o};
    
            ELECTRODES_INSIDE.(organoid) = readSingleCell(filename , batch , 'C'+string(o+1));
        end
    
    
        if readSingleCell(filename , batch , 'E2') == 1
            IS_CHIMERA.(batch) = true;
        else
            IS_CHIMERA.(batch) = false;
        end
    
        
        DRUG_TIMES.(batch) = struct( ...
            "Control" , [string(readSingleCell(filename , batch , 'I1')) , string(readSingleCell(filename , batch , 'J1'))], ...
            "x4_AP" , [string(readSingleCell(filename , batch , 'I2')) , string(readSingleCell(filename , batch , 'J2'))], ...
            "No_Drug" , [string(readSingleCell(filename , batch , 'I3')) , string(readSingleCell(filename , batch , 'J3'))], ...
            "Bicuculline" , [string(readSingleCell(filename , batch , 'I4')) , string(readSingleCell(filename , batch , 'J4'))], ...
            "Tetrodotoxin" , [string(readSingleCell(filename , batch , 'I5')) , string(readSingleCell(filename , batch , 'J5'))]...
        );
    
    end
    
    save(fullfile(PROCESSED_DATA_DIR, "Parameters.mat"), "NUM_CHANNELS", "NUM_FEATURES", "PROCESSED_DATA_DIR" , "ORGANOIDS", "ELECTRODES_INSIDE", "IS_CHIMERA", "DRUG_TIMES")

end

function data = readSingleCell(filename, sheetName, cellRef)
    % Extracts a single cell from a specified sheet in an Excel file using readtable
    % Inputs:
    %   filename - Name of the Excel file (string)
    %   sheetName - Name of the sheet to read from (string)
    %   cellRef - Cell reference in Excel notation (e.g., 'B2')
    % Output:
    %   data - The data from the specified cell

    % Use readtable with the 'Sheet' and 'Range' options to read the specified cell
    tableData = readtable(filename, 'Sheet', sheetName, 'Range', cellRef);
    
    % Extract the content from the single cell table
    data = tableData{1, 1};  % Assuming there's only one cell in the range
end



