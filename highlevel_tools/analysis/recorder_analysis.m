function analysisLog = recorder_analysis(rec, nCrossvalidation)
%RECORDER_ANALYSIS

if nargin < 2
    nCrossvalidation = 10;
end

analysisLog = Logger();

analysisLog.log_field('accuracy', recorder_compute_accuracy(rec, nCrossvalidation))

analysisLog.log_from_struct(recorder_compute_reachingStat(rec))

analysisLog.log_field('dispatcher_empty', rec.dispatcher_empty)
