function hypothesisClassifiers = compute_classifiers(blankClassifierAnonymousFunction, teacherSignals, teacherHypothesisPLabels)
%COMPUTE CLASSIFIERS
%TODO: doc, error detection, example, tests

nHypothesis = length(teacherHypothesisPLabels);
hypothesisClassifiers = cell(1, nHypothesis);
for iHyp = 1:nHypothesis
    hypothesisClassifiers{iHyp} = blankClassifierAnonymousFunction();
    hypothesisClassifiers{iHyp}.fit(teacherSignals, teacherHypothesisPLabels{iHyp})
end

