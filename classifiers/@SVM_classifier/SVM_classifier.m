classdef SVM_classifier < handle
    %SVM_CLASSIFIER
    %One versus all
    
    properties
        defaultLabel = -1; % the 'all' label will be -1; avoid to use it!
        
        type = 'svm'
        nLabels = 0 % Track the number of classes
        svmStructs = {}
        svmargs = {}
        
        plattParams = {}
        
        X = [];
        pY = [];
        
        %speed-up
        hard_empirical_confusion_matrix
        proba_empirical_confusion_matrix
    end
    
    methods
        
        function self = SVM_classifier(varargin)
            self.svmargs = varargin;
        end
        
        function erase(self)
            self.nLabels = 0;
            self.svmStructs = {};
            self.plattParams = {};
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
                oneVsAllLabel(oneVsAllLabel ~= iLabel) = self.defaultLabel;
                self.svmStructs{iLabel} = svmtrain(X, oneVsAllLabel, self.svmargs{:});
                
                %
                [outClass, values] = mysvmclassify(self.svmStructs{iLabel}, X);
                
                labplatt = ones(size(oneVsAllLabel));
                if all(values(outClass == iLabel) <= 0)
                    labplatt(oneVsAllLabel ~= self.defaultLabel) = 0;
                else
                    labplatt(oneVsAllLabel == self.defaultLabel) = 0;
                end
                [A, B] = SVM_classifier.tunePlattParam(values, labplatt);
                self.plattParams{iLabel} = struct;
                self.plattParams{iLabel}.A = A;
                self.plattParams{iLabel}.B = B;
            end
        end
        
        function pY = predict(self, X, normalize)
            if nargin < 3
                normalize = true;
            end
            pY = zeros(size(X, 1), self.nLabels);
            for iLabel = 1:self.nLabels
                [outClass, values] = mysvmclassify(self.svmStructs{iLabel}, X);
                
                inverted = 0;
                if all(values(outClass == iLabel) <= 0)
                    inverted = 1;
                end
                
                pY(:,iLabel) = 1 ./ ( 1 + exp(self.plattParams{iLabel}.A * values + self.plattParams{iLabel}.B));
                
                if inverted
                    pY(:,iLabel) = 1 - pY(:,iLabel);
                end
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
                blankClassifier = @() SVM_classifier(self.svmargs{:});
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
                blankClassifier = @() SVM_classifier(self.svmargs{:});
                [given, predicted] = cross_validation(blankClassifier, self.X, self.pY, nCrossValidation);
                self.proba_empirical_confusion_matrix = proba_confusion_matrix(vertcat(given{:}), vertcat(predicted{:}));
            end
            confusionMatrix = self.proba_empirical_confusion_matrix;
        end
        
    end
    
    methods(Static)
        function [A, B] = tunePlattParam(values, labels)
            % Input parameters:
            % values = array of SVM decision values
            % labels = array of booleans: is the example labeled +1?
            
            % prior1 = number of positive examples
            % prior0 = number of negative examples
            prior1 = sum(labels == 1);
            prior0 = sum(labels == 0);
            [A,B] = svm_platt_parameters(values, labels, prior1, prior0);
        end
    end
    
end




