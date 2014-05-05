function proba = compute_min_confidences(confidences)
% COMPUTE_MIN_CONFIDENCES - Output the probability that one hypothesis
% is above all others, therefore we consider only the probability of behing above
% the best hypothesis (or second best for the best hypothesis)

proba = confidences + eye(size(confidences))*0.5;
proba = min(proba, [], 1);

% do not normalize
% proba = proba_normalize_row(proba);
% such proba should not be normalize here
% we consider hypothesis individually