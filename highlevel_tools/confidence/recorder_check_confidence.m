function [isConfident, bestHypothesis] = recorder_check_confidence(rec, methodInfo)
%RECORDER_CHECK_CONFIDENCE 

isConfident = false;
bestHypothesis = 0;

filestr = generate_method_filestr(methodInfo);
hypothesisProbabilities = rec.(['probabilities_', filestr]);

if max(hypothesisProbabilities(end, :)) > rec.confidenceLevel
    isConfident = true;
    [~, bestHypothesis] = max(hypothesisProbabilities(end, :));
end