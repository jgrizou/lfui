function analysisLogs = folder_analysis(resultFolder, nCrossvalidation, usedDataOnly)
%FOLDER_ANALYSIS

if nargin < 2
    nCrossvalidation = 10;
end

if nargin < 3
    usedDataOnly = 0;
end

analysisLogs = Logger();

matfiles = getfilenames(resultFolder, 'refiles', '*.mat');
nFile = length(matfiles);

for iFile = 1:nFile
    
    fprintf('%4d/%4d', iFile, nFile);
    
    filename = fullfile(matfiles{iFile});
    load(filename)
    analysisLogs.logit(filename)    
    analysisLogs.log_from_logger(recorder_analysis(rec, nCrossvalidation, usedDataOnly))
    
    fprintf('\b\b\b\b\b\b\b\b\b')
end