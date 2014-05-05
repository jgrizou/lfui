classdef GaussianUninformativePrior_classifier < handle
    %GaussianUninformativePrior_classifier Simple gaussian classifier, one gaussian per class.
    %This is build on top of a gaussian classifier
    %
    %   TODO:
    %       -Add tests, and check dimension
    
    properties
        type = 'gaussianUninformativePrior'
        gaussianClassifier
        regOption % shrink or diag
        regParam
        
        %speed-up
        hard_empirical_confusion_matrix
        proba_empirical_confusion_matrix
        
        nPoints
        dim
    end
    
    
    methods
        function self = GaussianUninformativePrior_classifier(varargin)
            % Initialize Gaussian_classifier variable
            % To set a regularization option, set a regularization option name and its param
            % Example tmp = GaussianUninformativePrior_classifier('shrink', 0.5)
            if ~isempty(varargin)
                self.regOption = varargin{1};
                self.regParam = varargin{2};
            end
        end
        
        function params = get_params(self, label)
            params = self.gaussianClassifier.get_params(label);
        end
        
        function fit(self, X, pY)
            self.hard_empirical_confusion_matrix = [];
            self.proba_empirical_confusion_matrix = [];
            
            self.gaussianClassifier = Gaussian_classifier(self.regOption, self.regParam);
            self.gaussianClassifier.fit(X, pY)
            [self.nPoints, self.dim] = size(X);
        end
        
        function pY = predict(self, X, normalize)
            if nargin < 3
                normalize = true;
            end
            pY = zeros(size(X, 1), self.gaussianClassifier.nGaussians);
            if (self.nPoints - self.dim) > 0
                for iLabel = 1:self.gaussianClassifier.nGaussians
                    pY(:,iLabel) = mvtpdf_gaussian_uninformative_prior(X, ...
                        self.gaussianClassifier.parameters{iLabel}.mean, ...
                        self.gaussianClassifier.parameters{iLabel}.covariance, ...
                        self.nPoints, ...
                        self.dim);
                end
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
            logpY = zeros(size(X, 1), self.gaussianClassifier.nGaussians);
            if (self.nPoints - self.dim) > 0
                for iLabel = 1:self.gaussianClassifier.nGaussians
                    logpY(:,iLabel) = logmvtpdf_gaussian_uninformative_prior(X, ...
                        self.gaussianClassifier.parameters{iLabel}.mean, ...
                        self.gaussianClassifier.parameters{iLabel}.covariance, ...
                        self.nPoints, ...
                        self.dim);
                end
            end
            if normalize
                logpY = log_normalize_row(logpY); %here logpY is not a log any more
            end
        end
        
        function classifier = sample_classifier(self)
            if (self.nPoints - self.dim) > 0
                classifier = Gaussian_classifier(self.regOption, self.regParam);
                classifier.nGaussians = self.gaussianClassifier.nGaussians;
                classifier.parameters = {};
                for iLabel = 1:self.gaussianClassifier.nGaussians
                    %sample
                    [mu, sigma] = sample_gaussian_uninformative_prior(...
                        self.gaussianClassifier.parameters{iLabel}.mean, ...
                        self.gaussianClassifier.parameters{iLabel}.covariance, ...
                        self.nPoints, ...
                        self.dim);
                    %assign
                    classifier.parameters{iLabel} = struct;
                    classifier.parameters{iLabel}.mean = mu;
                    classifier.parameters{iLabel}.covariance = sigma;
                end
            else
                classifier = [];
            end
        end
        
        function confusionMatrix = compute_hard_empirical_confusion_matrix(self, nCrossValidation, force)
            if nargin < 3
                force = false;
            end    
            if force || isempty(self.hard_empirical_confusion_matrix)
                blankClassifier = @() GaussianUninformativePrior_classifier(self.regOption, self.regParam);
                [given, predicted] = cross_validation(blankClassifier, self.gaussianClassifier.X, self.gaussianClassifier.pY, nCrossValidation);
                self.hard_empirical_confusion_matrix = hard_confusion_matrix(vertcat(given{:}), vertcat(predicted{:}));
            end
            confusionMatrix = self.hard_empirical_confusion_matrix;
        end
        
        function confusionMatrix = compute_proba_empirical_confusion_matrix(self, nCrossValidation, force)
            if nargin < 3
                force = false;
            end            
            if force || isempty(self.proba_empirical_confusion_matrix)
                blankClassifier = @() GaussianUninformativePrior_classifier(self.regOption, self.regParam);
                [given, predicted] = cross_validation(blankClassifier, self.gaussianClassifier.X, self.gaussianClassifier.pY, nCrossValidation);
                self.proba_empirical_confusion_matrix = proba_confusion_matrix(vertcat(given{:}), vertcat(predicted{:}));
            end
            confusionMatrix = self.proba_empirical_confusion_matrix;
        end
        
    end
    
end
