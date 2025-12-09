function MoveIncompleteData()

RHD_FILE_SIZE = 319209034; % file size of a complete RHD File
BAD_DATA_DIR = "D:/bad_data";

% Get Directory (without directory values)
directory = dir();
directory = directory(~[directory.isdir]);

% Get Incomplete File Names
incomplete_files_logical = [directory.bytes] ~= RHD_FILE_SIZE;

file_names = {directory.name};
incomplete_file_names = file_names(incomplete_files_logical);
incomplete_file_names = incomplete_file_names(endsWith(incomplete_file_names , '.rhd'));

for i = 1:numel(incomplete_file_names)
    incomplete_file = incomplete_file_names{i};

    fprintf("Moving Incomplete file (%s) to bad_data\n" , incomplete_file)
    movefile(incomplete_file , BAD_DATA_DIR)

end