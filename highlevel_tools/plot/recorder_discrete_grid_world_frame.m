function recorder_discrete_grid_world_frame(rec, iStep, methodInfo)
%RECORDER_DISCRETE_GRID_WORLD_FRAME

if iStep > 1    
    
    if rec.is_prop('uncertaintyMap')
        uMap = rec.uncertaintyMap(:, :, iStep-1);
    else
        uMap = zeros(rec.environment.nS, rec.environment.nA);
    end
    
    filestr = generate_method_filestr(methodInfo);
    discrete_grid_world_frame(rec.environment, ...
        rec.state(iStep), rec.action(iStep), rec.teacherHypothesis(iStep-1), ...
        rec.(['probabilities_', filestr])(iStep-1, :), ...
        uMap)
    
    subplot(2, 2, 4)
    evolution = rec.(['probabilities_', filestr]);
    plot(evolution)
    title('Targets Probabilities Evolution')
else
    discrete_grid_world_frame(rec.environment, ...
        rec.state(iStep), rec.action(iStep), 0, zeros(1, rec.nHypothesis), ...
        zeros(rec.environment.nS, rec.environment.nA))
end


