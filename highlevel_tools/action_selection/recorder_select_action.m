function action = recorder_select_action(rec, methodInfo)
%RECORDER_SELECT_ACTION 
%Same as select_action but using the recorder facility
%TODO: doc, error detection, example, tests

if rec.is_prop('isConfident') && rec.isConfident(end)
    actionSelectionMethod = rec.actionSelectionInfo.confidentMethod;
else
    if length(rec.iStep) > rec.nInitSteps + 1
        actionSelectionMethod = rec.actionSelectionInfo.method;
    else
        actionSelectionMethod = rec.actionSelectionInfo.initMethod;
    end
end

nStep = length(rec.iStep);
if nStep > 0
    stepToUse = nStep - 1 - mod(nStep-1, rec.actionSelectionInfo.nStepBetweenUpdate);
else
    stepToUse = 1; 
end

switch actionSelectionMethod
    
    case 'random'
        action = select_action('random', rec.environment);
        
    case 'greedy'
        filestr = generate_method_filestr(methodInfo);
        hypothesisProbabilities = rec.(['probabilities_', filestr])(stepToUse, :);
        [~, bestHypothesis] = max(hypothesisProbabilities);
        action = select_action('greedy', rec.environment, 'policy', full(rec.hypothesisPolicies{bestHypothesis}));

    case 'e_greedy'
        filestr = generate_method_filestr(methodInfo);
        hypothesisProbabilities = rec.(['probabilities_', filestr])(stepToUse, :);
        [~, bestHypothesis] = max(hypothesisProbabilities);
        action = select_action('e_greedy', rec.environment, 'policy', full(rec.hypothesisPolicies{bestHypothesis}), 'epsilon', rec.actionSelectionInfo.epsilon);
        
    case 'uncertainty'
        action = select_action('greedy', rec.environment, 'policy', full(rec.uncertaintyPolicy(:, :, stepToUse)));

    case 'e_uncertainty'
        action = select_action('e_greedy', rec.environment, 'policy', full(rec.uncertaintyPolicy(:, :, stepToUse)), 'epsilon', rec.actionSelectionInfo.epsilon);
        
    case 'myopic_uncertainty'
        state = rec.environment.get_state();
        action = greedy_action_discrete_policy(full(rec.uncertaintyMap(state, :, stepToUse)), 1);  
                
    otherwise
        error('recorder_select_action:UnknownMethodName', [actionSelectionMethod, ' not handled'])
        
end