function reachingStat = recorder_compute_reachingStat(rec)
%RECORDER_COMPUTE_REACHINGSTAT

%%
totalReach = rec.targetReached';
correctReach = zeros(1, length(totalReach));
correctReach(totalReach) = rec.teacherHypothesis(totalReach) == rec.bestHypothesis(totalReach);
wrongReach = totalReach - correctReach;
%
maxLength = rec.nSteps;
tt = find(totalReach);
timeTarget = ones(1, maxLength) * -1;
timeTarget(1:length(tt)) = tt;
%
tpt = tt;
if ~isempty(tpt)
    tpt = [tpt(1), diff(tpt)];
end
timePerTarget = ones(1, maxLength) * -1;
timePerTarget(1:length(tpt)) = tpt;

tc = correctReach(totalReach);
targetCorrect = ones(1, maxLength) * -1;
targetCorrect(1:length(tc)) = tc';

ratioReach = mean(targetCorrect(1:sum(totalReach)));
ratioReach(isnan(ratioReach)) = 0;


confidence = rec.isConfident';
confidenceSum = totalReach + confidence;

%find time between conf and reach
reachID = find(confidenceSum == 2);

confReachTimePerTarget = ones(1, maxLength) * -1;
for iReach = 1:length(reachID)
    cnt = 0;
    for i = reachID(iReach)-1:-1:1
        if confidenceSum(i) > 0
            cnt = cnt + 1;
        else
            break
        end
    end
    confReachTimePerTarget(iReach) = cnt;
end



%%
reachingStat = struct;

reachingStat.totalReach = totalReach;
reachingStat.correctReach = correctReach;
reachingStat.wrongReach = wrongReach;

reachingStat.timeTarget = timeTarget;

reachingStat.timePerTarget = timePerTarget;
reachingStat.targetCorrect = targetCorrect;
reachingStat.ratioReach = ratioReach;

reachingStat.confidence = confidence;
reachingStat.confidenceSum = confidenceSum;
reachingStat.confReachTimePerTarget = confReachTimePerTarget;

