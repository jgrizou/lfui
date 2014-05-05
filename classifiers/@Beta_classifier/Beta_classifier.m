classdef Beta_classifier < handle
    %BETA_CLASSIFIER
    %Features are treated independantly, it is not a multivariate beta
    
    properties
        
        type = 'beta'
        nLabels = 0 % Track the number of classes
        nDims = 0
        parameters = {} % Store the alphas and betas
        
        X = [];
        pY = [];
        
        nPointPerSample = 10 %we fake here the probailistic labelling
        %for each sample we put nPointPerSample if probability is 1, 0
        %point if probability is 0 and well you understood the point
        % it is an approxaimtion but for now let's use it
        
    end
    
    methods
        
        function self = Beta_classifier(nPointPerSample)
            if nargin > 0
                self.nPointPerSample = nPointPerSample;
            end
        end
        
        function erase(self)
            self.nLabels = 0;
            self.nDims = 0;
            self.parameters = {};
            self.X = [];
            self.pY = [];
        end
        
        function fit(self, X, pY)
            % X [matrix (nObservations, nFeatures)]
            % pY is the probability of each label [matrix (nObservations, nLabels)]
            self.erase()
            self.X = X;
            self.pY = pY;
            self.nLabels = size(pY,2);
            self.nDims = size(X,2);
            nResamples = round(pY * self.nPointPerSample);
                            
            for iLabel = 1:self.nLabels
                self.parameters{iLabel} = struct;
                self.parameters{iLabel}.alpha = zeros(1, self.nDims);
                self.parameters{iLabel}.beta = zeros(1, self.nDims);
                
                resampledX = [];
                for iSample = 1:size(X,1)
                    resampledX = [resampledX; repmat(X(iSample, :), nResamples(iSample, iLabel), 1)];
                end
                for iDim = 1:self.nDims
                    phat = betafit(resampledX(:, iDim));
                    self.parameters{iLabel}.alpha(iDim) = phat(1);
                    self.parameters{iLabel}.beta(iDim) = phat(2);
                end
            end
        end
        
        function pY = predict(self, X, normalize)
            % Predict the probability of X for each label
            % X [matrix (nObservations, nFeatures)]
            % if normalize is true: (classification) pY is the probability of X for each label [matrix (nObservations, nLabels)]
            % if normalize is false: (estimate pdf) pY is the pdf value of X for each label [matrix (nObservations, nLabels)]
            if nargin < 3
                normalize = true;
            end
            pY = ones(size(X, 1), self.nLabels);
            for iLabel = 1:self.nLabels
                for iDim = 1:self.nDims
                    pY(:, iLabel) = pY(:, iLabel) .* betapdf(X(:, iDim), ...
                        self.parameters{iLabel}.alpha(iDim), ...
                        self.parameters{iLabel}.beta(iDim));
                end
            end
            if normalize
                pY = proba_normalize_row(pY);
            end
        end
        
        function logpY = logpredict(self, X, normalize)
            % Predict the log probability of X for each label
            % X [matrix (nObservations, nFeatures)]
            % X [matrix (nObservations, nFeatures)]
            % if normalize is true: (classification) logpY is the probability of X for each label [matrix (nObservations, nLabels)]
            % if normalize is false: (estimate pdf) pY is the log of the pdf value of X for each label [matrix (nObservations, nLabels)]
            % Warning: if normalize is true the ouput is not a logarithm!!
            if nargin < 3
                normalize = true;
            end
            logpY = zeros(size(X, 1), self.nLabels);
            for iLabel = 1:self.nLabels
                for iDim = 1:self.nDims
                    logpY(:, iLabel) = logpY(:, iLabel) + log(betapdf(X(:, iDim), ...
                        self.parameters{iLabel}.alpha(iDim), ...
                        self.parameters{iLabel}.beta(iDim)) + realmin);
                end
            end
            if normalize
                logpY = log_normalize_row(logpY); %here logpY is not a log any more
            end
        end
        
        function confusionMatrix = compute_hard_empirical_confusion_matrix(self, nCrossValidation, force)
            if nargin < 3
                force = false;
            end
            if force || isempty(self.hard_empirical_confusion_matrix)
                blankClassifier = @() Beta_classifier(self.nPointPerSample);
                [given, predicted] = cross_validation(blankClassifier, self.X, self.pY, nCrossValidation);
                self.hard_empirical_confusion_matrix = hard_confusion_matrix(vertcat(given{:}), vertcat(predicted{:}));
            end
            confusionMatrix = self.hard_empirical_confusion_matrix;
        end
        
        function confusionMatrix = compute_proba_empirical_confusion_matrix(self, nCrossValidation, force)
            if nargin < 3
                force = false;
            end
            if force || isempty(self.proba_empirical_confusion_matrix)
                blankClassifier = @() Beta_classifier(self.nPointPerSample);
                [given, predicted] = cross_validation(blankClassifier, self.X, self.pY, nCrossValidation);
                self.proba_empirical_confusion_matrix = proba_confusion_matrix(vertcat(given{:}), vertcat(predicted{:}));
            end
            confusionMatrix = self.proba_empirical_confusion_matrix;
        end
        
        
        
    end
    
end

