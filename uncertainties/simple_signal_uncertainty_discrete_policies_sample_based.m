function uncertaintyMap = simple_signal_uncertainty_discrete_policies_sample_based(policies, probabilities, classifiers, frame, signalSamples)
%SIGNAL_UNCERTAINTY_DISCRETE_POLICIES_SAMPLE_BASED

if ~isvector(probabilities)
    error('signal_uncertainty_discrete_policies_pairwise:InputDim', 'probabilities must be 1-D.'); 
end
if ~is_proba_normalized_row(probabilities)
    error('signal_uncertainty_discrete_policies_pairwise:InputNotNormalized', 'probabilities must sum to 1.'); 
end
if ~iscell(policies)
    error('signal_uncertainty_discrete_policies_pairwise:InputType', 'policies must be a vector of cell.'); 
end
if ~isvector(policies)
    error('signal_uncertainty_discrete_policies_pairwise:InputDim', 'policies must be a 1-D cell vector.'); 
end
if ~all(cellfun(@(x) is_proba_normalized_row(x), policies))
    error('signal_uncertainty_discrete_policies_pairwise:InputNotNormalized', 'policies rows must sum to 1.'); 
end
if length(policies) ~= length(probabilities) || length(probabilities) ~= length(classifiers)
    error('signal_uncertainty_discrete_policies_pairwise:InputDim', 'policies, probabilities, and classifiers must have the same number of element'); 
end

[nStates, nActions] = size(policies{1});
nHypothesis = length(probabilities);
nSamples = size(signalSamples, 1);
nLabels = size(frame.compute_labels(policies{1}, 1, 1), 2);

predictedPLabel = zeros(nSamples, nLabels, nHypothesis);
for iHypothesis = 1:nHypothesis
    %the correction from confusion matrix is not needed here, only matters
    %the ordering not the absolute value
    predictedPLabel(:,:, iHypothesis) = classifiers{iHypothesis}.logpredict(signalSamples);  
end

uncertaintyMap = zeros(nStates, nActions);
for iState = 1:nStates
    for iAction = 1:nActions

        expectationMatching = zeros(nSamples, nHypothesis);
        for iHypothesis = 1:nHypothesis
            expectedPLabel = frame.compute_labels(policies{iHypothesis}, iState, iAction);
            expectedPLabel = repmat(expectedPLabel, nSamples, 1);
            expectationMatching(:, iHypothesis) = sum(expectedPLabel .* predictedPLabel(:, :, iHypothesis), 2);
        end
        
        uncertaintyMap(iState, iAction) = sum(var(expectationMatching, probabilities, 2));
        
    end
end