function uncertaintyMap = signal_uncertainty_discrete_policies_greedy_pairwise(policies, probabilities, classifiers, frame, anonymousFunction)
%SIGNAL_UNCERTAINTY_DISCRETE_POLICIES_GREEDY_PAIRWISE

%This function may be very costly as it must evaluate for each state-action
%pair the uncertainty based on pairwise model comparision of each
%hypothesis model

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
        
        upperRight = pairwise_comparison(anonymousFunction, params);
        % Those are only the upper right elements, the pairwise comparison of uncertainty element is supposed to be symmetric and of diagonal equals to 0.
        % To compute total weighted uncertainty we now need to compute the associated weights which is also a matrices
        % Such probabilistic weights matrices should sum to one.
        % However we known that the pairwise comparison are symmetric and
        % of diagonal zero, therefore we only needs the upper right weights too.
        weights = pairwise_comparison(@(x,y) x*y, num2cell(probabilities));
        uncertaintyMap(iState, iAction) = 2 * upperRight * weights'; % 2 * because the matrices are symmetrics. Remember diagonal elements are zeros.
    end
end