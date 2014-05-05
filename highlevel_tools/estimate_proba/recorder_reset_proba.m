function recorder_reset_proba(rec, bestHypothesis, methodInfo)
%RECORDER_RESET_PROBA

bestPLabel = rec.(rec.hypothesisRecordNames{bestHypothesis});
for iHyp = 1:rec.nHypothesis
    % be carefull with this kind of operation on the logger
    % you should know what you are doing
    rec.(rec.hypothesisRecordNames{iHyp}) = bestPLabel;
end

filestr = generate_method_filestr(methodInfo);
if strcmp(methodInfo.cumulMethod, 'filter')
    rec.(['logLikelihoods_', filestr])(end, :) = zeros(1, rec.nHypothesis);
end

rec.(['probabilities_', filestr])(end, :) = proba_normalize_row(zeros(1, rec.nHypothesis));
