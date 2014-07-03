classdef Discrete_mdp_Tworld < handle
    %DISCRETE_MDP_TWORLD
    
    % Available action are (N, S, E, W and NOOP (optional)).
    
    properties        
        %the following variable must keep the same name to be used with
        %Value Iteration Solver
        Gamma = 0.95 % Discount factor - for Value Iteration (VI) solver
        nS = 7 % Number of state
        nA = 4 % Number of action (4 is default, no NOOP action)
        P % Transisiton matrix
        R % Reward
        
        currentState % Current state of the agent
        
        drawer % a Square_plot class
        
%          ---- ---- ---- ---- ---- 
%         |    |    |    |    |    |
%         |  1 |  2 |  3 |  4 |  5 |
%          ---- ---- ---- ---- ----
%                   |    |
%                   |  6 |
%                    ----
%                   |    |
%                   |  7 |
%                    ----
                  
    end
    
    methods
        
        function self = Discrete_mdp_Tworld(nA)
            
            if nargin > 0
                if nnz(nA == [4 5])
                    self.nA = nA;
                else
                    error('discrete_mdp_Tworld:Discrete_mdp_gridworld:NActionNonValid','The number of action is either 4 or 5 (default)')
                end
            end
            
            % building transition matrix
            self.P = cell(1, self.nA);
            %action North
            self.P{1} = zeros(self.nS, self.nS); % could be directly zeros(self.nS) but it is to highlight the fact it is a 2D
            self.P{1}(1,1) = 1;
            self.P{1}(2,2) = 1;
            self.P{1}(3,3) = 1;
            self.P{1}(4,4) = 1;
            self.P{1}(5,5) = 1;
            self.P{1}(6,3) = 1;
            self.P{1}(7,6) = 1;
            %action South
            self.P{2} = zeros(self.nS, self.nS); % could be directly zeros(self.nS) but it is to highlight the fact it is a 2D
            self.P{2}(1,1) = 1;
            self.P{2}(2,2) = 1;
            self.P{2}(3,6) = 1;
            self.P{2}(4,4) = 1;
            self.P{2}(5,5) = 1;
            self.P{2}(6,7) = 1;
            self.P{2}(7,7) = 1;
            %action East
            self.P{3} = zeros(self.nS, self.nS); % could be directly zeros(self.nS) but it is to highlight the fact it is a 2D
            self.P{3}(1,2) = 1;
            self.P{3}(2,3) = 1;
            self.P{3}(3,4) = 1;
            self.P{3}(4,5) = 1;
            self.P{3}(5,5) = 1;
            self.P{3}(6,6) = 1;
            self.P{3}(7,7) = 1;
            %action West
            self.P{4} = zeros(self.nS, self.nS); % could be directly zeros(self.nS) but it is to highlight the fact it is a 2D
            self.P{4}(1,1) = 1;
            self.P{4}(2,1) = 1;
            self.P{4}(3,2) = 1;
            self.P{4}(4,3) = 1;
            self.P{4}(5,4) = 1;
            self.P{4}(6,6) = 1;
            self.P{4}(7,7) = 1;
            %action NOOP
            if self.nA == 5
                self.P{5} = eye(self.nS);
            end
            
            % empty reward
            self.R = zeros(self.nS, self.nA);
            
            positions = zeros(self.nS, 2);
            positions(1, :) = [-2,0];
            positions(2, :) = [-1,0];
            positions(3, :) = [0,0];
            positions(4, :) = [1,0];
            positions(5, :) = [2,0];
            positions(6, :) = [0,-1];
            positions(7, :) = [0,-2];
            self.drawer = Squares_plot(positions);
        end
        
        function set_reward(self, R)
            % should check R before
            self.R = R;
        end
        
        function set_state(self, state)
            if state > self.nS || state < 1
                error('discrete_mdp_Tworld:set_state:StateNonValid', 'This state is not valid.')
            end
            self.currentState = state;
        end
        
        function state = get_state(self)
            state = self.currentState;
        end
        
        function apply_action(self, action)
            if action > self.nA || action < 0
                error('discrete_mdp_Tworld:set_state:ActionNonValid', 'This action is not valid.')
            end
            self.currentState = randsample(1:self.nS, 1, true, full(self.P{action}(self.currentState,:)));
        end
        
        function draw_grid(self, state, action, goal)
            self.drawer.reset_colors()
            self.drawer.reset_chars()
            self.drawer.draw(false)
            if nargin > 3
                if self.drawer.is_id_valid(goal)
                    self.drawer.draw_dot(goal)
                end
            end
            if nargin > 1
                self.drawer.draw_dot(state, 'r')
            else
                self.drawer.draw_dot(self.currentState, 'r')
            end
            if nargin > 2
                %realign with the square plotter convention
                if action < 3
                    action = action + 2;
                elseif action == 3
                    action = 2;
                elseif action == 4
                    action = 1;
                end
                self.drawer.draw_arrow(action, state, 'b')
            end
        end
        
        function draw_grid_values(self, values, limMinMax,  cbar)
            self.drawer.reset_chars()
            if nargin < 3
                self.drawer.set_all_colors_by_values(values)
            else
                self.drawer.set_all_colors_by_values(values, limMinMax)
            end
            if nargin < 4
                self.drawer.draw()
            else
                self.drawer.draw(cbar, limMinMax)
            end
        end
        
        function draw_grid_state_number(self)
            self.drawer.reset_colors()
            self.drawer.set_all_char_as_square_number()
            self.drawer.draw()
        end
        
    end
    
end

