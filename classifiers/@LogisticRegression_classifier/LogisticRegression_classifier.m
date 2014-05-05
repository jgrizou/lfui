classdef LogisticRegression_classifier < handle
    %LOGISTICREGRESSION_CLASSIFIER
    %One versus all
    
    properties
        type = 'logisticRegression'
        nLabels = 0 % Track the number of classes
        logRegTheta = {}
        optioptions
        
        lambda = 0;
        
        X = [];
        pY = [];
        
        %speed-up
        hard_empirical_confusion_matrix
        proba_empirical_confusion_matrix
    end
    
    methods
        
        function self = LogisticRegression_classifier(lambda, optioptions)
            if nargin > 0
                self.lambda = lambda;
            end
            if nargin > 1
                self.optioptions = optioptions;
            else
                self.optioptions = optimset('GradObj', 'on', 'MaxIter', 100,'Diagnostics', 'off', 'Display','off');
            end
        end
        
        function erase(self)
            self.nLabels = 0;
            self.logRegTheta = {};
            self.X = [];
            self.pY = [];
        end
        
        function fit(self, X, pY)
            self.erase()
            self.X = X;
            self.pY = pY;
            self.nLabels = size(pY, 2);
            
            Y = plabel_to_label(pY);
            for iLabel = 1:self.nLabels
                oneVsAllLabel = Y;
                oneVsAllLabel(oneVsAllLabel ~= iLabel) = 0;
                oneVsAllLabel(oneVsAllLabel == iLabel) = 1;
                self.logRegTheta{iLabel} = train_logistic_regression(X, oneVsAllLabel, self.lambda, self.optioptions);
            end
        end
        
        function pY = predict(self, X, normalize)
            if nargin < 3
                normalize = true;
            end
            pY = zeros(size(X, 1), self.nLabels);
            for iLabel = 1:self.nLabels
                pY(:, iLabel) = predict_logistic_regression(X, self.logRegTheta{iLabel});
            end
            if normalize
                pY = proba_normalize_row(pY);
            end
        end
        
        function logpY = logpredict(self, X, normalize)
            if nargin < 3
                normalize = true;
            end
            py = self.predict(X, normalize);
            if normalize
                logpY = py;
            else
                logpY = log(py);
            end
        end
        
        function confusionMatrix = compute_hard_empirical_confusion_matrix(self, nCrossValidation, force)
            if nargin < 3
                force = false;
            end
            if force || isempty(self.hard_empirical_confusion_matrix)
                blankClassifier = @() LogisticRegression_classifier(self.lambda, self.optioptions);
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
                blankClassifier = @() LogisticRegression_classifier(self.lambda, self.optioptions);
                [given, predicted] = cross_validation(blankClassifier, self.X, self.pY, nCrossValidation);
                self.proba_empirical_confusion_matrix = proba_confusion_matrix(vertcat(given{:}), vertcat(predicted{:}));
            end
            confusionMatrix = self.proba_empirical_confusion_matrix;
        end
        
    end
    
end

