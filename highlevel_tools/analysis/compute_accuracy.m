function accuracy = compute_accuracy(blankClassifier, X, pY, nCrossvalidation)
%COMPUTE_THEORITICAL_ACCURACY

%CV
[predicted, given] = cross_validation(blankClassifier, X, pY, nCrossvalidation);
predicted = vertcat(predicted{:});
given = vertcat(given{:});
%
accuracy = accuracy_label(plabel_to_label(predicted), plabel_to_label(given));
