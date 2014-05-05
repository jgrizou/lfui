function uncertaintyMap = compute_uncertainty_map(methodName, hypothesisPolicies, probabilities, frame, hypothesisClassifiers, varargin)
%COMPUTE_UNCERTAINTY_MAP
%TODO: doc, error detection, example, tests

%For now, signal uncertainty are based on gaussian classifier only
%We do not adapt to classifier type yet

switch methodName
    
    case 'simple_signal_sample'
        %new implementation, not optimal either
        signalSamples = process_options(varargin, 'signalSamples', []);
        uncertaintyMap = simple_signal_uncertainty_discrete_policies_sample_based(hypothesisPolicies, probabilities, hypothesisClassifiers, frame, signalSamples);
        
    case 'signal_sample'
        %new implementation, not optimal either
        [signalSamples, nCrossValidation] = process_options(varargin, 'signalSamples', [], 'nCrossValidation', []);
        uncertaintyMap = signal_uncertainty_discrete_policies_sample_based(hypothesisPolicies, probabilities, hypothesisClassifiers, frame, signalSamples, nCrossValidation);
        
    case 'signal_trace'
        % uncertainty at the expected signal level
        % greedy global comparison based on gaussian mean dispersion  
        anonymousFunction = @(x,y) Gaussian_classifier.compute_simple_dispersion(x,y);
        uncertaintyMap = signal_uncertainty_discrete_policies_greedy_global(hypothesisPolicies, probabilities, hypothesisClassifiers, frame, anonymousFunction);

    case 'task'
        % new method, not optimal either
        % uncertainty at the expected meaning/label level
        uncertaintyMap = task_uncertainty_discrete_policies(hypothesisPolicies, probabilities, frame);       

    otherwise
        error('compute_uncertainty_map:UnknownMethodName', ['"', methodName, ' not handled']) 
end