classdef GaussianMixture_classifier < handle
    %GAUSSIANMIXTURE_CLASSIFIER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        type = 'gaussianMixture'
        nGaussiansPerClass = 0 % Track the number of classes
        nLabels = 0
                
        X = [];
        pY = [];
        
        gm = {}
        gmargs = {}
        
        %speed-up
        hard_empirical_confusion_matrix
        proba_empirical_confusion_matrix

    end
    
    methods
        
        function self = GaussianMixture_classifier(nGaussiansPerClass, varargin)
            self.nGaussiansPerClass = nGaussiansPerClass;
            if nargin > 1
                self.gmargs = varargin;
            end
        end
        
        function erase(self)
            self.nLabels = 0;
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
                self.gm{iLabel} = gmdistribution.fit(X(Y == iLabel, :), self.nGaussiansPerClass, self.gmargs{:});
            end
        end
        
        function pY = predict(self, X, normalize)
            if nargin < 3
                normalize = true;
            end
            pY = zeros(size(X, 1), self.nLabels);
            for iLabel = 1:self.nLabels
                pY(:,iLabel) = self.gm{iLabel}.pdf(X);
            end
            if normalize
                pY = proba_normalize_row(pY);
            end
        end
        
        function logpY = logpredict(self, X, normalize)
            % Warning: if normalize is true the ouput is not a logarithm!!
            if nargin < 3
                normalize = true;
            end
            logpY = zeros(size(X, 1), self.nLabels);
            for iLabel = 1:self.nLabels
                logpY(:,iLabel) = log(self.gm{iLabel}.pdf(X) + realmin);
            end
            if normalize
                logpY = log_normalize_row(logpY); %here logpY is not a log any more
            end
        end
        
        function params = get_params(self, label)
            if label < 0 || label > self.nLabels
                error('GaussianMixture_classifier:get_params:OutOfRange', 'Defined label is out of range.')
            end
            params = struct;
            params.means = self.gm{label}.mu;
            params.covariances = self.gm{label}.Sigma;
        end
                
        function confusionMatrix = compute_hard_empirical_confusion_matrix(self, nCrossValidation, force)
            if nargin < 3
                force = false;
            end
            if force || isempty(self.hard_empirical_confusion_matrix)
                blankClassifier = @() GaussianMixture_classifier(self.nGaussiansPerClass, self.gmargs{:});
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
                blankClassifier = @() GaussianMixture_classifier(self.nGaussiansPerClass, self.gmargs{:});
                [given, predicted] = cross_validation(blankClassifier, self.X, self.pY, nCrossValidation);
                self.proba_empirical_confusion_matrix = proba_confusion_matrix(vertcat(given{:}), vertcat(predicted{:}));
            end
            confusionMatrix = self.proba_empirical_confusion_matrix;
        end
               
    end
end

