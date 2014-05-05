function [confidences, confidents, isConfident] = compute_confidences_student(estimates, threshold)
%COMPUTE_CONFIDENCE_STUDENT - Compute the confidences that one hypothesis as a
%better estimate than all the other. To do so we compare it individually to
%all the others and report the lowest value.
%
%   Syntax:  [confidences, confidents, isConfident] = compute_confidences_student(estimates, threshold)
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

elements = arrayfun(@(iHypothesis) estimates(:,iHypothesis), 1:nHypothesis, 'UniformOutput', false);
pvalue_func = @(X, Y) 1-mvtcdf_gaussian_uninformative_prior(0, mean(X)-mean(Y), var(X)+var(Y), size(X, 1), 1);
pairwise_pvalue = pairwise_comparison(pvalue_func, elements);

%its a bit tricky here, we convert the pairwise conparison in square from
% Comparaison we do are not symmetric but their relation is known p(X>Y) = 1- p(X<Y)
confidences = squareform(pairwise_pvalue);
% only the lower left is correct
% the upper right of the matrice should be 1 - the lower left
confidences = tril(confidences) + triu(1-confidences);
%finally fill the diagonal
confidences(logical(eye(size(confidences)))) = 0.5; %P(X>X) = 0.5, always

%fix problem of Nan
%those problem append only when testing zero variance variable of same
%mean, i.e. the same data iof zeros variance
% e.g: X = [1,1,1] and Y=X
% ttest2(X, Y, threshold, 'left', 'unequal')
% in such case we assume a value of 0.5
confidences(isnan(confidences)) = 0.5;


confidents = confidences > threshold;

% here we do not compare against an hypothesis against itself, we wnat to
% knwon if we are confident agaisnt all the others only
tmpConfidences = confidences + diag(ones(1, nHypothesis));
isConfident = all(tmpConfidences > threshold);