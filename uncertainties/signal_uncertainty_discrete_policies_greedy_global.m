function uncertaintyMap = signal_uncertainty_discrete_policies_greedy_global(policies, probabilities, classifiers, frame, anonymousFunction)
%SIGNAL_UNCERTAINTY_DISCRETE_POLICIES_GREEDY_GLOBAL

%This function may be very costly as it must evaluate for each state-action
%pair the uncertainty based on model comparision of each hypothesis model

if ~isvector(probabilities)
    error('signal_uncertainty_discrete_policies_global:InputDim', 'probabilities must be 1-D.'); 
end
if ~is_proba_normalized_row(probabilities)
    error('signal_uncertainty_discrete_policies_global:InputNotNormalized', 'probabilities must sum to 1.'); 
end
if ~iscell(policies)
    error('signal_uncertainty_discrete_policies_global:InputType', 'policies must be a vector of cell.'); 
end
if ~isvector(policies)
    error('signal_uncertainty_discrete_policies_global:InputDim', 'policies must be a 1-D cell vector.'); 
end
if ~all(cellfun(@(x) is_proba_normalized_row(x), policies))
    error('signal_uncertainty_discrete_policies_global:InputNotNormalized', 'policies rows must sum to 1.'); 
end
if length(policies) ~= length(probabilities) || length(probabilities) ~= length(classifiers)
    error('signal_uncertainty_discrete_policies_global:InputDim', 'policies, probabilities, and classifiers must have the same number of element'); 
end

[nStates, nActions] = size(policies{1});
nHypothesis = length(probabilities);

uncertaintyMap = zeros(nStates, nActions);
for iState = 1:nStates
    for iAction = 1:nActions

        params = cell(1, nHypothesis);
        for iHypothesis = 1:nHypothesis
            pLabel = frame.compute_labels(policies{iHypothesis}, iState, iAction); % probability of the teacher intended meaning
            % If we stick with the probabilistic expected label, it becomes very difficult (or at least very very very costly) to compare each model
            % In order to make the problem tracktable we ask each hypothesis to vote for only one expected label (greedy)
            % In practice this does not affect much the planning.
            % For the feedback frames this have minor effects and should never change the uncertainty ranking, which is what matters for our planner
            expectedLabel = greedy_action_discrete_policy(pLabel, 1); % this function selects the most probable label expected from the teacher
            params{iHypothesis} = classifiers{iHypothesis}.get_params(expectedLabel);
        end
        
        uncertaintyMap(iState, iAction) = anonymousFunction(params, probabilities);
    end
end