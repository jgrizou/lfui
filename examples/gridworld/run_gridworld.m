%% READ First

% This is an example, just to not let you with a code that doesn't do anything.
% However I am using a lot of highlevel that hide the core of the code by 
% plenty of highlevel configuration handling. 
% This will be improved when time permit, with an example as close as
% possible with the core functions, and with a better plot showing the
% insight of the algortihm

% There is quite a few tools I created for myself, and unfortunatly they
% are not all documented.


%%
%disabling some warning well handled
warning('off', 'ensure_positive_semidefinite:NegativeEigenvalues')
warning('off', 'ensure_symmetry:ComplexInfNaN')
warning('off', 'process_options:argUnused')
warning('off', 'cross_validation:NotEnoughData')

% We choose to use a Logger as a kind of workspace to store and retrieve usefull variable
% It also allow to easilly creates history of data and retrieve then as easilly
% You may get confuse at first but compare this file with the
% demo_no_recorder to see the benefit of it
% rec is the only short name variable that you should see and stand for
% recorder, a Logger instance.
rec = Logger();

%% shuffle random seed according to current time
seed = init_random_seed(); % init seed with current time
rec.log_field('randomSeed', seed);

%% Environement
% set-up world
gSize = 5;
environment = Discrete_mdp_gridworld(gSize);
environment.set_state(randi(environment.nS));
rec.logit(environment)

% generate task hypothesis
% hytothesis are represented as optimal policies
nStates = environment.nS;
nHypothesis = environment.nS;
hypothesisPolicies = cell(1, nHypothesis);
for iHyp = 1:nHypothesis
    tmpEnvironment = Discrete_mdp_gridworld(environment.gSize);
    tmpR = zeros(nStates, 1);
    tmpR(iHyp) = 1; % sparse reward function, zero everywhere but 1 on a randomly selected state
    tmpEnvironment.set_reward(tmpR);
    [~, hypothesisPolicies{iHyp}] = VI(tmpEnvironment);
end
rec.logit(nHypothesis)
rec.logit(hypothesisPolicies)

hypothesisRecordNames = cell(1, rec.nHypothesis);
for iHyp = 1:rec.nHypothesis
    hypothesisRecordNames{iHyp} = ['plabelHyp', num2str(iHyp)];
end
rec.logit(hypothesisRecordNames)

%% Teacher side
% choose which frames of interaction the teacher uses
% we use a feedback frame, meaning the user will provide signal of two
% classes, correct and incorrect
rec.log_field('teacherFrame' ,Discrete_mdp_feedback_frame(0)) % teacher makes no mistake, use 0.05 for 5% error

% Generate artificial teaching signals
nFeatures = 2; % the dimension of the feature vectors representing the user signal

% the center of the gaussian clusters
mus(1, :, 1) = ones(1, nFeatures) * 10;
mus(1, :, 2) = ones(1, nFeatures) * -10;
% they are quite well separated clusters here, just to have a nice example, you
% should play with this ti test the behavior of the system with more noisy
% data, we are usually testing with 34 dimensional EEG data.

% their covariance
sigmas(:, :, 1) = eye(nFeatures);
sigmas(:, :, 2) = eye(nFeatures);

% we need more points that the number of iteration we plan
nPointsPerClusters = 1000; 

% function that sample points from gaussian parameters
[X, Y] = gaussian_clusters(mus, sigmas, nPointsPerClusters);

% here we log some more info
% I declare those variables in the logger to be sure to not use them from the workspace
rec.log_field('nFeatures', nFeatures)
% The dispatcher is a tool that, given a label (Y) sends back a signal (X) and
% removes it from the list so as to use it only once
rec.log_field('teacherDispatcher', Dispatcher(X, Y, true));

%%%%%%%%%%%%%
% you may want to use less artificial dataset, you can find some on my
% github account: https://github.com/jgrizou/datasets
%%%%%%%%%%%%%

%% Learner side
% choose which frames of interaction the learner uses
rec.log_field('learnerFrame',Discrete_mdp_feedback_frame(0.1)) % learner believes teacher makes 10% of the times teaching errors

% choose classifier to use
rec.log_field('blankClassifier', @() GaussianUninformativePrior_classifier('shrink', 0.5));

%% Setup experiment
% I declare those variable in the logger to be sure to not use it from the workspace
% Otherwise an other method would be
% nSteps = 100; rec.logit(nSteps)

rec.log_field('nSteps', 200) % nb of step to simulate
rec.log_field('nInitSteps', 10) % minPointNeeded before computing anything
%the classifier need a minimum of data to work and this actually depend on the
%number of features, 10 is fine fo 2D datasets and the classifier selected.
rec.log_field('confidenceLevel', 0.9) % confidence level on the probability, when it goes over this value the
% system is confident

% a struct containing the info for action selection
% do not bother with this while you do not know everything else
actionSelectionInfo = struct;
actionSelectionInfo.method = 'uncertainty'; % main method used always but in the bellow cases
actionSelectionInfo.initMethod = 'random'; % method used when we do not have enough data
actionSelectionInfo.confidentMethod = 'greedy'; % method use once we reache confidence to reach the target state
actionSelectionInfo.epsilon = 0; % it is not used for the action selection method selected
actionSelectionInfo.nStepBetweenUpdate = 1; % some planning method compute uncertainty map, sometome we do not want to update them every step
rec.log_field('actionSelectionInfo', actionSelectionInfo)

% sometime we want to reset the position of the agent, do not play with
% do not bother with this while you do not know everything else
rec.log_field('nStepBetweenStateReset', 0) % 0 means never reset

% the method used to estimate the uncertainty map
% do not bother with this while you do not know everything else
rec.log_field('uncertaintyMethod', 'signal_sample')
rec.log_field('nSampleUncertaintyPlanning', 20)

% parameter for the estimation of 
rec.log_field('nCrossValidation', 10)


% a struct containing the info about the method used for updating
% probabilities of tasks
% do not bother with this while you do not know everything else
methodInfo = struct;
methodInfo.classifierMethod = 'online'; 
methodInfo.samplingMethod = 'one_shot';
methodInfo.estimateMethod = 'matching';
methodInfo.cumulMethod = 'filter';
methodInfo.probaMethod = 'normalize';
rec.log_field('methodInfo', methodInfo)

% this is only used is the samplingMethod field is set to 'sampling', this
% is quite experimental
% do not bother with this while you do not know everything else
rec.log_field('nSampling', 50)

% this is only used if the classifierMethod field above is 'calibration'
% do not bother with this while you do not know everything else
rec.log_field('calibrationRatio', [0.5, 0.5])

% I guess for a first start you should not try to change any parameter, and
% then try to change them one by one while looking into the code what is
% happening

%% Main loop

% choose which hypothesis is the one taught by the teacher
teacherHypothesis = randi(rec.nHypothesis); % this will be recorded at each iteration so not now
teacherPolicy = rec.hypothesisPolicies{teacherHypothesis}; % the teacher objective is set up at random among the set of possibles
targetReached = false; % is the target reached?
isConfident = false; % is the confidence level reached?
%note that the confidence level can be reached at a different state than
%the target state, the agent must then reach the state, that is why we use
%two variables here.

for iStep = 1:rec.nSteps % main loop starts
    %% start loop
    stepTime = tic;
    fprintf('%4d/%4d',iStep, rec.nSteps);
    rec.logit(iStep) 
    % you see the above command, that is what make the power of the logger class
    % I just repeat the same command but iStep gets actually accumulated in
    % an array inside the logger
    
    %% choose and apply action
    if mod(iStep, rec.nStepBetweenStateReset) == 0
        environment.set_state(randi(environment.nS));
    end
    state = rec.environment.get_state(); rec.logit(state) 
    action = recorder_select_action(rec, rec.methodInfo); rec.logit(action)
    rec.environment.apply_action(action);
    
    %% simulate teacher response
    teacherPLabel = rec.teacherFrame.compute_labels(teacherPolicy, state, action);
    teacherLabel = sample_action_discrete_policy(teacherPLabel);
    rec.log_field('teacherSignal', rec.teacherDispatcher.get_sample(teacherLabel));
    
    %% compute hypothetic plabels
    hypothesisPLabel = cellfun(@(hyp) rec.learnerFrame.compute_labels(hyp, state, action), rec.hypothesisPolicies, 'UniformOutput', false);
    rec.log_multiple_fields(rec.hypothesisRecordNames, hypothesisPLabel)
    
    %% plot evolution
    recorder_discrete_grid_world_frame(rec, iStep, rec.methodInfo)
    drawnow
    
    % here is a quick overview of the plot:
    %   - top-left is the gridworld with the agent (red) moving
    %       for each move it receive on feedback from the user (not shown)
    %       the black dot shows the target intended byt he user
    %   - top-right is the probability of each target
    %       the scale is changin always so as to make small differences
    %       easier to see.
    %   - bottom-left is the uncertainty map used by the agent to select next action
    %       here again be carefull when analaysing, the map displayed is
    %       a projection. The uncertainty map is computed on the
    %       state-action space, which is not nice to plot. So I used a
    %       custom projection that gives a more or less intuitive vision of
    %       what is happening.
    %   - bottom-right is the evolution of probabilities for each target
    %       the one we want to go up is the one in red, if it does not happen, they my algorithm failed!
    
    %% compute hypothesis probabilities
    recorder_compute_proba(rec, rec.methodInfo)

    %% detect confidence
    [isConfident, bestHypothesis] = recorder_check_confidence(rec, rec.methodInfo);
    rec.logit(isConfident)
    rec.logit(bestHypothesis)
    rec.logit(teacherHypothesis)
    
    targetReached = bestHypothesis == rec.environment.currentState;
    rec.logit(targetReached)
    
    if targetReached
        % reset the learning process
        recorder_reset_proba(rec, bestHypothesis, rec.methodInfo)
        % change which hypothesis is the one taught by the teacher
        teacherHypothesis = randi(rec.nHypothesis); % this will be recorded at each iteration so not now
        teacherPolicy = rec.hypothesisPolicies{teacherHypothesis};
    end
    
    %% compute uncertainty
    recorder_compute_uncertainty_map(rec, rec.uncertaintyMethod, rec.methodInfo)
    
    %% end loop
    % Here I am just logging is the dispatcher is empty, because if is then
    % it means we start reusing data, and this may affect the performances, it is like cheating!
    rec.log_field('dispatcher_empty', rec.teacherDispatcher.who_is_empty())
    
    rec.log_field('stepTime', toc(stepTime))
    fprintf('\b\b\b\b\b\b\b\b\b')
end

%% Save
% we save the logger with a timestamped filename
[pathstr, ~, ~] = fileparts(mfilename('fullpath'));
folder = fullfile(pathstr, 'results');
if ~exist(folder, 'dir')
    mkdir(folder)
end
recFilename = generate_timestamped_filename(folder, 'mat');

% this save the logger it self and can be recovored as a logger instance
% latter
rec.save(recFilename)
% however if you do not want to reuse my logger or are afraid to loose or alter the
% logger class file at some point, use the following line instead.
% rec.save_all_fields(recFilename)

%% Replay
% if you used the standard logger.save function then you can replay the experiment
% just load the file that was save in the examples/gridworld/results folder 
% and run the following line

%recorder_replay_discrete_grid_world(rec, rec.methodInfo, 0)
