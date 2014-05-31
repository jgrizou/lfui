function analysisLog = recorder_analysis(rec, nCrossvalidation, usedDataOnly)
%RECORDER_ANALYSIS

if nargin < 2
    nCrossvalidation = 10;
end

if nargin < 3
    usedDataOnly = 0;
end

analysisLog = Logger();

if usedDataOnly
    analysisLog.log_field('accuracy', recorder_compute_accuracy_used_data_only(rec, nCrossvalidation))
else
    analysisLog.log_field('accuracy', recorder_compute_accuracy(rec, nCrossvalidation))
end

analysisLog.log_from_struct(recorder_compute_reachingStat(rec))

analysisLog.log_field('dispatcher_empty', rec.dispatcher_empty)
