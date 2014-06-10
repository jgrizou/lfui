function [confidences, confidents, isConfident] = compute_confidences_normal(estimates, threshold)
%COMPUTE_CONFIDENCE_NORMAL - Compute the confidences that one hypothesis as a
%better estimate than all the other. To do so we compare it individually to
%all the others and report the lowest value.
%
%   Syntax:  [confidences, confidents, isConfident] = compute_confidences_normal(estimates, threshold)
%
%   Inputs:
%       estimates - Matrix of estimated performances [matrix (nEstimations, nHypothesis)]
%       threshold - Confidence level
%
%   Outputs:
%       confidences - confidence of each hypothesis being better than each other [matrix (nHypothesis, nHypothesis)] of scalar \in (0,1)
%
%       organisation of this matrice goes that way:
%
%           estimates = X1 Y1 Z1
%                       X2 Y2 Z2
%                       ...
%
%           confidences = p(X>X) p(Y>X) p(Z>X)
%                         p(X>Y) p(Y>Y) p(Z>Y)
%                         p(X>Z) p(Y>Z) p(Z>Z)
%
%       confidents - if confidences are above threshold
%       isConfident - hypothesis that are confident above threshold wrt. all other ones [vector (1, Hypothesis)] of boolean
%                       if threshold is not defined, isConfident will always be zero.
%                     A threshold of 1 can never be reached


%   Author: Jonathan Grizou
%   Equipe Flowers
%   200 Avenue de la vieille tour
%   33405 Talence
%   France
%   email: jonathan.grizou@inria.fr
%   Website: https://flowers.inria.fr/jgrizou/

if ~ismatrix(estimates)
    error('compute_confidence:InputDim', 'estimates must be 2-D.');
end
if threshold <= 0 || threshold >= 1
    error('compute_confidence:Input', 'threshold should be \in (0,1).');
end
[~, nHypothesis] = size(estimates);

confidences = zeros(nHypothesis, nHypothesis);

means = mean(estimates, 1);
vars = var(estimates, 0, 1);

for iHypothesis = 1:nHypothesis
    
    meansDiff = repmat(means(iHypothesis), 1, nHypothesis) - means;
    varsSum = repmat(vars(iHypothesis), 1, nHypothesis) + vars;
    
    alphas = meansDiff ./ sqrt(varsSum);
    confidences(:,iHypothesis) = 0.5 + erf(alphas/sqrt(2))/2;
    
    %fix problem of Nan when var are zero
    if any(isnan(confidences(:,iHypothesis)))
        tmpDiff = (sign(meansDiff) + 1) / 2;
        confidences(varsSum == 0, iHypothesis) = tmpDiff(varsSum == 0);
    end
end

confidents = confidences > threshold;

% here we do not compare against an hypothesis against itself, we wnat to
% knwon if we are confident agaisnt all the others only
tmpConfidences = confidences + diag(ones(1, nHypothesis));
isConfident = all(tmpConfidences > threshold);
