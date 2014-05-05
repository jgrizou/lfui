classdef EMGaussian_classifier < handle
    %EMGAUSSIAN_CLASSIFIER
    
    properties
        type = 'EMgaussian'
        nLabels = 0 % Track the number of classes
        
        X = [];
        pY = [];
        
        gm
        gmargs = {}
        
        %speed-up
        hard_empirical_confusion_matrix
        proba_empirical_confusion_matrix
        
    end
    
    methods
        
        function self = EMGaussian_classifier(varargin)
            self.gmargs = varargin;
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
            
            dim = size(X, 2);
            self.nLabels = size(pY, 2);
            
            S=struct;
            S.mu = zeros(self.nLabels, dim);
            S.Sigma = zeros(dim, dim, self.nLabels);
            for iLabel = 1:self.nLabels
                weights = pY(:, iLabel);
                weightedMean = weighted_mean(X, weights);
                weightedCov = weighted_cov(X, weights, weightedMean);
                
                S.mu(iLabel, :) = weightedMean;
                S.Sigma(:,:, iLabel) = weightedCov;
            end
            
            self.gm = gmdistribution.fit(X, self.nLabels, 'Start', S, self.gmargs{:});
        end
        
        function params = get_params(self, label)
            if label < 0 || label > self.nLabels
                error('EMGaussian_classifier:get_params:OutOfRange', 'Defined label is out of range.')
            end
            params = struct;
            params.mean = self.gm.mu(label, :);
            params.covariance = self.gm.Sigma(:, :, label);
        end
        
        function pY = predict(self, X, normalize)
            if nargin < 3
                normalize = true;
            end
            if normalize
                pY = self.gm.posterior(X);
            else
                pY = zeros(size(X, 1), self.nLabels);
                for iLabel = self.nLabels
                    params = get_params(self, iLabel);
                    pY(:, iLabel) = mvnpdf(X, params.mean, params.covariance);
                end
            end
        end
        
        function logpY = logpredict(self, X, normalize)
            % Warning: if normalize is true the ouput is not a logarithm!!
            if nargin < 3
                normalize = true;
            end
            if normalize
                logpY = self.gm.posterior(X);
            else
                logpY = zeros(size(X, 1), self.nLabels);
                for iLabel = self.nLabels
                    params = self.get_params(iLabel);
                    logpY(:, iLabel) = logmvnpdf(X, params.mean, params.covariance);
                end
            end
        end
        
        function confusionMatrix = compute_hard_empirical_confusion_matrix(self, nCrossValidation, force)
            if nargin < 3
                force = false;
            end
            if force || isempty(self.hard_empirical_confusion_matrix)
                blankClassifier = @() EMGaussian_classifier(self.gmargs{:});
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
                blankClassifier = @() EMGaussian_classifier(self.gmargs{:});
                [given, predicted] = cross_validation(blankClassifier, self.X, self.pY, nCrossValidation);
                self.proba_empirical_confusion_matrix = proba_confusion_matrix(vertcat(given{:}), vertcat(predicted{:}));
            end
            confusionMatrix = self.proba_empirical_confusion_matrix;
        end
        
        function [h,s] = plot_gaussian2D(self, label, color, lw, fill)
            % this function apply only for 2D data
            if nargin < 5
                fill = 0;
            end
            if nargin < 4
                lw = 2;
            end
            if nargin < 3
                color = 'b';
            end
            params = self.get_params(label);
            if fill
                [h, s] = plotcov2(params.mean, params.covariance, 'plot-axes', 0, 'plot-opts', {'Color', color, 'linewidth', lw}, 'fill-color', color);
            else
                [h, s] = plotcov2(params.mean, params.covariance, 'plot-axes', 0, 'plot-opts', {'Color', color, 'linewidth', lw});
            end
        end
        
        function plot_all_gaussian2D(self, colorList, lw, fill)
            % this function apply only for 2D data
            if nargin < 4
                fill = 0;
            end
            if nargin < 3
                lw = 2;
            end
            if nargin < 2
                colorList = jet(self.nLabels);
            end
            hold on
            for iLabel = 1:self.nLabels
                self.plot_gaussian2D(iLabel, colorList(iLabel, :), lw, fill);
            end
        end
        
        
        
    end
    
end

