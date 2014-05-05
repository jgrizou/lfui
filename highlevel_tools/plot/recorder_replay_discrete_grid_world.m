function recorder_replay_discrete_grid_world(rec, methodInfo, pauseSec)
%RECORDER_REPLAY_DISCRETE_GRID_WORLD 

nSteps = length(rec.stepTime);

filestr = generate_method_filestr(methodInfo);
evolution = rec.(['probabilities_', filestr]);
taught = zeros(nSteps, 1);
for s = 1:nSteps
    taught(s) = evolution(s, rec.teacherHypothesis(s));
end
        
for iStep = 1:nSteps
    clf
    recorder_discrete_grid_world_frame(rec, iStep, methodInfo)
    if iStep > 1
        subplot(2, 2, 4)
        plot(evolution(1:iStep, :), 'b')
        hold on
        plot(taught(1:iStep, :), 'r')
        xlim([0, rec.iStep(end)])
        ylim([-0.05, 1.05])
        title('Targets Probabilities Evolution')
    end
    drawnow
    
    if nargin > 2
        pause(pauseSec) 
    else
        pause
    end
end

