function accuracy = recorder_compute_accuracy(rec, nCrossvalidation)
%RECORDER_COMPUTE_ACCURACY

if nargin < 2
    nCrossvalidation = 10;
end

if rec.is_prop('accuracy')
    accuracy = rec.accuracy;
else
    X = rec.teacherDispatcher.X;
    labels = rec.teacherDispatcher.get_available_labels();
    Y = zeros(size(X, 1), 1);
    for il = 1:length(labels)
        Y(rec.teacherDispatcher.labelsIndices(labels(il))) = labels(il);
    end
    pY = label_to_plabel(Y, 1, length(labels));    
    accuracy = compute_accuracy(rec.blankClassifier, X, pY, nCrossvalidation);
end

