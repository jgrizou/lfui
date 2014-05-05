classdef Discrete_mdp_feedback_frame
%DISCRETE_MDP_FEEDBACK_FRAME Simlulate an interaction frame
%As all frame classes the function labels = compute_labels(state, action) should be implemented
%This frames assess the action performed at state
%The outputed labels are associated to [correct, incorrect]

    properties
        errorRate = 0
        labelsNames = {'correct', 'incorrect'}
    end
    
    methods
        function self = Discrete_mdp_feedback_frame(errorRate)
            % The error rate model the error rate in feedback assesment (default is 0)
            if nargin > 0
                self.errorRate = errorRate;
            end
        end
        
        function labels = compute_labels(self, policy, state, action)
            % policy - [matrix (nState x nAction)] (can be sparse)
            % state - state from which action was performed
            % action - action performed at state
            %
            % labels - probability of teacher meaning [correct, incorrect]
            statePolicy = full(policy(state, :));
            labels = zeros(1, 2);
            if statePolicy(action) == max(statePolicy)
                labels(1) = 1; % correct
            else
                labels(2) = 1; % incorrect
            end
            labels = apply_noise(labels, self.errorRate);
        end
    end
end