function recorder_compute_uncertainty_map(rec, uncertaintyMethodName, methodInfo)
%RECORDER_COMPUTE_UNCERTAINTY_MAP
%Same as compute_uncertainty_map but using the recorder facility
%TODO: doc, error detection, example, tests

if strcmp(rec.actionSelectionInfo.method, 'uncertainty') || strcmp(rec.actionSelectionInfo.method, 'myopic_uncertainty')
    
    uncertaintyMap = zeros(rec.environment.nS, rec.environment.nA);
    uncertaintyPolicy = zeros(rec.environment.nS, rec.environment.nA);
    
    if length(rec.iStep) > rec.nInitSteps
        
        filestr = generate_method_filestr(methodInfo);
        methodPlanningProba = proba_normalize_row(rec.(['probabilities_', filestr])(end, :));
        
        nAvailableSample = size(rec.teacherSignal, 1);
        if nAvailableSample > rec.nSampleUncertaintyPlanning
            idx = randperm(nAvailableSample);
            signalSamples = rec.teacherSignal(idx(1:rec.nSampleUncertaintyPlanning), :);
        else
            signalSamples = rec.teacherSignal;
        end
                
        uncertaintyMap = compute_uncertainty_map(uncertaintyMethodName, ...
            rec.hypothesisPolicies, ...
            methodPlanningProba, ...
            rec.learnerFrame, ...
            rec.(['classifiers_', filestr]), ...
            'signalSamples', signalSamples, ...
            'nCrossValidation', rec.nCrossValidation);
        % we provide the signal and blankClassifier each time
        % but we only use it if uncertaintyMethodName = 'signal_sample'
        % this is an optional parameter, it can be remove to move this
        % into a switch case on uncertaintyMethodName
        
        rec.environment.set_reward(uncertaintyMap)
        [~, uncertaintyPolicy] = VI(rec.environment);
        uncertaintyPolicy = full(uncertaintyPolicy);
    end
    
    rec.logit(uncertaintyMap)
    rec.logit(uncertaintyPolicy)
end