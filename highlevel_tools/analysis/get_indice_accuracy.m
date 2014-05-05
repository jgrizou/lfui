function idx = get_indice_accuracy(analysisLogs, minAcc, maxAcc)
%GET_INDICE_ACCURACY 

idx = [];
for i = 1:length(analysisLogs.accuracy)
    if analysisLogs.accuracy(i) > minAcc && analysisLogs.accuracy(i) <= maxAcc
        idx(end+1) = i;
    end    
end