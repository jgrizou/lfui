function accuracy = recorder_compute_accuracy_used_data_only(rec, nCrossvalidation)
%RECORDER_COMPUTE_ACCURACY_USED_DATA_ONLY

if nargin < 2
    nCrossvalidation = 10;
end

%get data together
X = rec.teacherDispatcher.X;
labels = rec.teacherDispatcher.get_available_labels();
Y = zeros(size(X, 1), 1);
for il = 1:length(labels)
    Y(rec.teacherDispatcher.labelsIndices(labels(il))) = labels(il);
end
pY = label_to_plabel(Y, 1, length(labels));    


%extract only the used one
usedX = rec.teacherSignal;
nUsed = size(usedX, 1);

usedpY = zeros(nUsed, size(pY, 2));
for iX = 1:nUsed
    repUsedX = repmat(usedX(iX, :), size(X,1) ,1);
    idx = find(all(X == repUsedX, 2));
    usedpY(iX, :) = pY(idx,:);
end

%compute
accuracy = compute_accuracy(rec.blankClassifier, usedX, usedpY, nCrossvalidation);




