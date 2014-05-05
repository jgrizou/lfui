function analysisLogs = folder_analysis(resultFolder, nCrossvalidation)
%FOLDER_ANALYSIS

if nargin < 2
    nCrossvalidation = 10;
end

analysisLogs = Logger();

matfiles = getfilenames(resultFolder, 'refiles', '*.mat');
nFile = length(matfiles);

for iFile = 1:nFile
    
    fprintf('%4d/%4d', iFile, nFile);
    
    filename = fullfile(matfiles{iFile});
    load(filename)
    analysisLogs.logit(filename)    
    analysisLogs.log_from_logger(recorder_analysis(rec, nCrossvalidation))
    
    fprintf('\b\b\b\b\b\b\b\b\b')
end