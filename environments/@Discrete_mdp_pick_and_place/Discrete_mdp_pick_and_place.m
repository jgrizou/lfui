classdef Discrete_mdp_pick_and_place < handle
    %DISCRETE_MDP_PICK_AND_PLACE
    
    properties
        %the following variable must keep the same name to be used with
        %Value Iteration Solver
        Gamma = 0.95 % Discount factor - for Value Iteration (VI) solver
        nS % Number of state
        nA % Number of action
        P % Transisiton matrix
        R % Reward
        
        currentState % Current state of the agent
        
        featureSize
        %state spam from 1 to ns but it is easier to represent it in this vector form
        % [grasp/nograps robot_position object_position_1 object_position_2 object_position_3]
        % 1 for non grasping , 2 for grasping
        % robot positon 1 to 4
        % object postion 1 to 4 if lower level and 5 to 8 for second level and 9 if
        % grasped
       
        bridge
        % bridge when removing dead states
        
        % actions
        % 1 for right
        % 2 for left
        % 3 for grasping
        % 4 for ungrapsing

    end
    
    methods
        function self = Discrete_mdp_pick_and_place()
            % this environement is strange, first create the instance
            % and then use the init function
        end
        
        function init(self)
            info = self.mdp_pick_and_place();
            
            self.featureSize = info.sub2indDim;
            [mdp, self.bridge] = self.reduce_pick_and_place(info, info.deadStates);
            
            self.nS = mdp.nS;
            self.nA = mdp.nA;
            self.P = mdp.P;
            self.R = zeros(self.nS, self.nA);
            
            self.currentState = 1;
        end
        
        function state = feature_to_state(self, graspState, robotPos, obj1Pos, obj2Pos, obj3Pos)
            state = find(self.bridge == sub2ind(self.featureSize, graspState, robotPos, obj1Pos, obj2Pos, obj3Pos));
        end
        
        function [graspState, robotPos, obj1Pos, obj2Pos, obj3Pos] = state_to_feature(self, state)
            [graspState, robotPos, obj1Pos, obj2Pos, obj3Pos] = ind2sub(self.featureSize, self.bridge(state));
        end
        
        function set_reward(self, R)
            % should check R before
            self.R = R;
        end
        
        function set_state(self, state)
            if state > self.nS || state < 1
                error('discrete_mdp_gridworld:set_state:StateNonValid', 'This state is not valid.')
            end
            self.currentState = state;
        end
        
        function state = get_state(self)
            state = self.currentState;
        end
        
        function apply_action(self, action)
            if action > self.nA || action < 0
                error('discrete_mdp_gridworld:set_state:ActionNonValid', 'This action is not valid.')
            end
            self.currentState = randsample(1:self.nS, 1, true, full(self.P{action}(self.currentState,:)));
        end
        
        function draw(self)
            
            objPosX = [0.5, 2.5, 4.5, 6.5];
            objPosY = [0.5, 1.5];
            objRadius = 0.5;
            
            gripperY = 4.5;
            gripperRadius = 0.2;
            
            niceGreen = [0.4, 0.8, 0.2];
            niceBlue = [0.2, 0.4, 0.8]; 
            niceOrange = [0.9, 0.5, 0];
            
            [~, robotPos, obj1Pos, obj2Pos, obj3Pos] = self.state_to_feature(self.currentState);
            
            %obj1
            if obj1Pos < 9
                idX = mod(obj1Pos-1, 4) + 1;
                idY = floor((obj1Pos-1)/4) + 1;
                scatterpie(objPosX(idX), objPosY(idY), 1, niceGreen, objRadius, 'EdgeColor', 'none');
            else
                scatterpie(objPosX(robotPos), gripperY, 1, niceGreen, objRadius, 'EdgeColor', 'none');
            end
            
            %obj1
            if obj2Pos < 9
                idX = mod(obj2Pos-1, 4) + 1;
                idY = floor((obj2Pos-1)/4) + 1;
                scatterpie(objPosX(idX), objPosY(idY), 1, niceBlue, objRadius, 'EdgeColor', 'none');
            else
                scatterpie(objPosX(robotPos), gripperY, 1, niceBlue, objRadius, 'EdgeColor', 'none');
            end
            
            %obj1
            if obj3Pos < 9
                idX = mod(obj3Pos-1, 4) + 1;
                idY = floor((obj3Pos-1)/4) + 1;
                scatterpie(objPosX(idX), objPosY(idY), 1, niceOrange, objRadius, 'EdgeColor', 'none');
            else
                scatterpie(objPosX(robotPos), gripperY, 1, niceOrange, objRadius, 'EdgeColor', 'none');
            end
            
            %gripper
            scatterpie(objPosX(robotPos), gripperY, 1, [0,0,0], gripperRadius, 'EdgeColor', 'none');
            
            axis off
            axis equal
            
            xlim([0, 7])
            ylim([0, 5])
        end
        
    end
    
    methods(Static)
        mdpStruct = mdp_pick_and_place()
        [newMDP, bridge] = reduce_pick_and_place(MDP, deadStates)
    end
    
end

% R = zeros(ns,1);
% R(sub2ind(dim,1,4,8,1,4)) = 1;
