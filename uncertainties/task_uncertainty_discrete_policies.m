function uncertaintyMap = new_task_uncertainty_discrete_policies(policies, probabilities, frame)
%TASK_UNCERTAINTY_DISCRETE_POLICIES - Compute an uncertainty value for each state-action pair based on expected disagreement of different policies
%The more optimal labels differ between policies, the more uncertainty.
%
%   Syntax:  uncertaintyMap = task_uncertainty_discrete_policies(policies, probabilities, normalize_output)
%
%   Inputs:
%       policies - A cell vector of policy [cell vector (nHypothesis) of matrix (nStates, nActions)] - policies may be sparse
%       probabilities - Associated probabilities/weight of the policies [array vector (nHypothesis)]
%       frame - the frame of the interaction, outputs expected label from a state-action pair
    
%   Outputs:
%       uncertaintyMap - Uncertainty value for each state-action pair [matrix (nStates, nActions) of scalar \in (0, 1) if normalized otherwised \in (0, -log(0.5))]
%                        The uncertainty is computed using entropy (information theory) 
%
%   Examples:

%
%   TODO:
%       Add tests

%   Author: Jonathan Grizou
%   Equipe Flowers
%   200 Avenue de la vieille tour
%   33405 Talence
%   France
%   email: jonathan.grizou@inria.fr
%   Website: https://flowers.inria.fr/jgrizou/

if ~isvector(probabilities)
    error('task_uncertainty_discrete_policies:InputDim', 'probabilities must be 1-D.'); 
end
if ~is_proba_normalized_row(probabilities)
    error('task_uncertainty_discrete_policies:InputNotNormalized', 'probabilities must sum to 1.'); 
end
if ~iscell(policies)
    error('task_uncertainty_discrete_policies:InputType', 'policies must be a vector of cell.'); 
end
if ~isvector(policies)
    error('task_uncertainty_discrete_policies:InputDim', 'policies must be a 1-D cell vector.'); 
end
if ~all(cellfun(@(x) is_proba_normalized_row(x), policies))
    error('task_uncertainty_discrete_policies:InputNotNormalized', 'policies rows must sum to 1.'); 
end

[nStates, nActions] = size(policies{1});
nHypothesis = length(probabilities);
nLabels = size(frame.compute_labels(policies{1}, 1, 1), 2);

uncertaintyMap = zeros(nStates, nActions);
for iState = 1:nStates
    for iAction = 1:nActions

        expectedPLabel = zeros(nLabels, nHypothesis);
        for iHypothesis = 1:nHypothesis
            expectedPLabel(:, iHypothesis) = frame.compute_labels(policies{iHypothesis}, iState, iAction)'; % probability of the teacher intended meaning
        end
        
        uncertaintyMap(iState, iAction) = sum(var(expectedPLabel, probabilities, 2));
    end   
end