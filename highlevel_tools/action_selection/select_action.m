function action = select_action(methodName, environment, varargin)
%SELECT_ACTION 
%TODO: doc, error detection, example, tests

switch methodName   
    case 'random'
        action = randi(environment.nA);
    
    case 'greedy'
        policy = process_options(varargin, 'policy', []);
        if isempty(policy)
            error('select_action:PolicyNotDefined', 'Policy to follow is not defined')
        end
        action = greedy_action_discrete_policy(policy, environment.get_state());  
        
    case 'e_greedy'
        [policy, epsilon] = process_options(varargin, 'policy', [], 'epsilon', []);
        if isempty(policy)
            error('select_action:PolicyNotDefined', 'Policy to follow is not defined')
        end
        if isempty(epsilon)
            epsilon = 0;
            warning('select_action:EpsilonNotDefined', 'Epsilon is not defined, 0 is used by default')
        end       
        action = egreedy_action_discrete_policy(policy, environment.get_state(), epsilon); 
        
    otherwise
        error('select_action:UnknownMethodName', ['"', methodName, ' not handled'])     
end