classdef Discrete_mdp_guidance_frame
%DISCRETE_MDP_GUIDANCE_FRAME Simlulate an interaction frame
%As all frame classes the function labels = compute_labels(state, action) should be implemented
%This frames output the action that should have been performed at state
%The outputed labels are associated to [action1, action2, ..., actionN]
    
    properties
        errorRate = 0
    end
    
    methods
        function self = Discrete_mdp_guidance_frame(errorRate)
            % The error rate model the error rate in feedback assesment (default is 0)
            if nargin > 0
            self.errorRate = errorRate;
            end
        end
        
        function labels = compute_labels(self, policy, state, ~)
            % policy - [matrix (nState x nAction)] (can be sparse)
            % state - state to whihc action was performed
            % action - action performed at state
            %
            % labels - probability of teacher meaning [action1, action2, ..., actionN]
            statePolicy = full(policy(state, :));
            labels = softmax(statePolicy, 0);
            labels = apply_noise(labels, self.errorRate);
        end
    end
end

