function recorder_save_replay(rec, methodInfo, folder)
%RECORDER_SAVE_REPLAY

if ~exist(folder, 'dir')
    mkdir(folder)
end

nSteps = length(rec.stepTime);

filestr = generate_method_filestr(methodInfo);
evolution = rec.(['probabilities_', filestr]);
taught = zeros(nSteps, 1);
for s = 1:nSteps
    taught(s) = evolution(s, rec.teacherHypothesis(s));
end
        
cnt = 0;
for iStep = 1:nSteps
    cnt = cnt + 1;
    
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
    
    save_all_images(folder, 'jpeg', sprintf('%04d', cnt))
    
end
