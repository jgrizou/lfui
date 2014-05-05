function discrete_grid_world_frame(environment, state, action, goalState, stateProbabilities, uncertaintyMap)
%DISCRETE_GRID_WORLD_FRAME

subplot(2, 2, 1)
environment.draw_grid(state, action, goalState)

subplot(2, 2, 2)
environment.draw_grid_values(stateProbabilities)
title('Targets probabilities')

if nargin > 5
    subplot(2, 2, 3)
    environment.draw_grid_values(state_action_to_state_for_uncertainty_display(uncertaintyMap, environment.P))
    title('Uncertainty')
end

