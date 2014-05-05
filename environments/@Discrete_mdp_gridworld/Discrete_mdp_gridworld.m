classdef Discrete_mdp_gridworld < handle
    %DISCRETE_MDP_GRIDWORLD
    %
    % Available action are (N, S, E, W and NOOP).
    
    properties
        gSize
        
        %the following variable must keep the same name to be used with
        %Value Iteration Solver
        Gamma = 0.95 % Discount factor - for Value Iteration (VI) solver
        nS % Number of state
        nA = 5 % Number of action
        P % Transisiton matrix
        R % Reward
        
        currentState % Current state of the agent
        
        drawer % a Square_plot class
        
    end
    
    methods
        function self = Discrete_mdp_gridworld(gSize, nA)
            self.gSize = gSize;
            
            if nargin > 1
                if nnz(nA == [4 5])
                    self.nA = nA;
                else
                    error('discrete_mdp_gridworld:Discrete_mdp_gridworld:NActionNonValid','The number of action is either 4 or 5 (default)')
                end
            end
            
            MDP = MDPgrid(gSize, 1, 1, self.nA);
            self.nS = MDP.nS;
            self.P = MDP.P;
            self.R = zeros(self.nS, self.nA);
            
            
            tmpGridState = self.reshape_to_grid(1:self.nS);
            positions = zeros(self.nS, 2);
            for i = 1:self.gSize
                for j = 1:self.gSize
                    positions(tmpGridState(i, j), :) = [j, self.gSize - i];
                end
            end
            self.drawer = Squares_plot(positions);
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
    
    methods(Static)
        reshaped = reshape_to_grid(vector)
    end
end
