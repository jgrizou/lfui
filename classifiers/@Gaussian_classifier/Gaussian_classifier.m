classdef Gaussian_classifier < handle
    %Gaussian_classifier Simple gaussian classifier, one gaussian per class.
    %
    %   TODO:
    %       -Add tests, and check dimension
    
    properties
        type = 'gaussian'
        nGaussians = 0 % Track the number of classes
        parameters = {} % Store the mean and covariance matrice for each class
        
        X = [];
        pY = [];
        
        regOption % shrink or diag
        regParam
        
        %speed-up
        hard_empirical_confusion_matrix
        proba_empirical_confusion_matrix
    end
    
    
    methods
        function self = Gaussian_classifier(varargin)
            % Initialize Gaussian_classifier instance
            % To set a regularization option, set a regularization option name and its param
            % Example tmp =Gaussian_classifier('shrink', 0.5)
            if ~isempty(varargin)
                self.regOption = varargin{1};
                self.regParam = varargin{2};
            end
        end
        
        function erase(self)
            self.nGaussians = 0;
            self.parameters = {};
            self.X = [];
            self.pY = [];
        end
        
        function fit(self, X, pY)
            % Fit n Gaussian on the data, one per label
            % X [matrix (nObservations, nFeatures)]
            % pY is the probability of each label [matrix (nObservations, nLabels)]
            self.erase()
            self.X = X;
            self.pY = pY;
            nLabels = size(pY,2);
            for iLabel = 1:nLabels
                weights = pY(:, iLabel);
                weightedMean = weighted_mean(X, weights);
                weightedCov = weighted_cov(X, weights, weightedMean);
                if ~isempty(self.regOption)
                    weightedCov = self.regularize_cov(weightedCov, self.regOption, self.regParam);
                end
                weightedCov = ensure_positive_semidefinite(weightedCov);
                self.add_gaussian(weightedMean, weightedCov);
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
            pY = zeros(size(X, 1), self.nGaussians);
            for iLabel = 1:self.nGaussians
                pY(:, iLabel) = mvnpdf(X, ...
                    self.parameters{iLabel}.mean, ...
                    self.parameters{iLabel}.covariance);
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
            logpY = zeros(size(X, 1), self.nGaussians);
            for iLabel = 1:self.nGaussians
                logpY(:, iLabel) = logmvnpdf(X, ...
                    self.parameters{iLabel}.mean, ...
                    self.parameters{iLabel}.covariance);
            end
            if normalize
                logpY = log_normalize_row(logpY); %here logpY is not a log any more
            end
        end
        
        function confusionMatrix = compute_bhattacharyya_confusion_matrix(self)
            %very ugly for now
            %only for 2 label data
            
            %should be done by sampling many model and averaging the results
            if self.nGaussians ~= 2
                error('GaussianUninformativePrior_classifier:compute_confusion_matrix', 'Not implemented')
            end
            bhattacharyyaCoef_pairwise = self.pairwise_bhattacharyya_similarity();
            bhattacharyyaDist_pairwise = -log(bhattacharyyaCoef_pairwise);
            classificationRate = 1 - bhattacharyya_gaussian_error_empirical(bhattacharyyaDist_pairwise);
            confusionMatrix = ones(2, 2) * classificationRate;
            confusionMatrix(1, 2) = 1 - classificationRate;
            confusionMatrix(2, 1) = 1 - classificationRate;
            confusionMatrix = confusionMatrix ./ sum(sum(confusionMatrix));
        end
        
         function confusionMatrix = compute_hard_empirical_confusion_matrix(self, nCrossValidation, force)
            if nargin < 3
                force = false;
            end    
            if force || isempty(self.hard_empirical_confusion_matrix)
                blankClassifier = @() Gaussian_classifier(self.regOption, self.regParam);
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
                blankClassifier = @() Gaussian_classifier(self.regOption, self.regParam);
                [given, predicted] = cross_validation(blankClassifier, self.X, self.pY, nCrossValidation);
                self.proba_empirical_confusion_matrix = proba_confusion_matrix(vertcat(given{:}), vertcat(predicted{:}));
            end
            confusionMatrix = self.proba_empirical_confusion_matrix;
        end
        
        function add_gaussian(self, mean, covariance)
            % Add one gaussian for one new label
            self.nGaussians = self.nGaussians + 1;
            self.parameters{self.nGaussians} = struct;
            self.parameters{self.nGaussians}.mean = mean;
            self.parameters{self.nGaussians}.covariance = covariance;
        end
        
        function [mean, covariance] = get_gaussian(self, label)
            % Return the mean and covariance of gaussian associated to specified label
            if label < 0 || label > self.nGaussians
                error('Gaussian_classifier:get_gaussian:OutOfRange', 'Defined label is out of range.')
            end
            params = self.get_params(label);
            mean = params.mean;
            covariance = params.covariance;
        end
        
        function params = get_params(self, label)
            % Similar to get_gaussian but return the results in a struct
            % params struct is meant to be used as element for the static method compute_bhattacharyya_similarity
            if label < 0 || label > self.nGaussians
                error('Gaussian_classifier:get_params:OutOfRange', 'Defined label is out of range.')
            end
            params = self.parameters{label};
        end
        
        function pairwiseSimilarities = pairwise_bhattacharyya_similarity(self)
            elements = arrayfun(@(x) self.get_params(x), 1:self.nGaussians, 'UniformOutput', false);
            similarityFunction = @(x, y) self.compute_bhattacharyya_similarity(x, y);
            pairwiseSimilarities = pairwise_comparison(similarityFunction, elements);
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
            [mean, covariance] = self.get_gaussian(label);
            if fill
                [h, s] = plotcov2(mean, covariance, 'plot-axes', 0, 'plot-opts', {'Color', color, 'linewidth', lw}, 'fill-color', color);
            else
                [h, s] = plotcov2(mean, covariance, 'plot-axes', 0, 'plot-opts', {'Color', color, 'linewidth', lw});
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
                colorList = jet(self.nGaussians);
            end
            hold on
            for iGaussian = 1:self.nGaussians
                self.plot_gaussian2D(iGaussian, colorList(iGaussian, :), lw, fill);
            end
        end
    end
    
    methods(Static)
        function regCov = regularize_cov(cov, varargin)
            if nargin>3
                error('Gaussian_classifier:regularize_cov:TooManyInputs', 'Too many input arguments.');
            end
            if isempty(varargin)
                warning('Gaussian_classifier:regularize_cov:NoOption', 'No option defined, the covariance was not changed.')
                regCov = cov;
            else
                switch varargin{1}
                    case 'diag'
                        regCov = diag_regularize_cov(cov, varargin{end});
                    case 'shrink'
                        regCov = shrink_cov(cov, varargin{end});
                    otherwise
                        error('Gaussian_classifier:regularize_cov:OptionNotValid', 'Option not handled.');
                end
            end
        end
        
        function similarity_score = compute_bhattacharyya_similarity(params1, params2)
            % Computes similarity between two label model of two Gaussian_classifier (GC) class based on the bhattacharyya coefficient.
            % This function is meant to be use with the pairwise_comparison(anonymousFunction, elements) function
            % Therefore it can only have two inputs, one for each elements.
            % Elements are meant to come from the function get_params(label) of an instance of Gaussianclassifier.
            [~, similarity_score] = bhattacharyya_gaussian(params1.mean, params1.covariance, params2.mean, params2.covariance);
        end
        
        function similarity_score = compute_simple_similarity(params1, params2)
            % Computes similarity between two label model of two Gaussian_classifier (GC) class based on the means distance.
            % This function is meant to be use with the pairwise_comparison(anonymousFunction, elements) function
            % Therefore it can only have two inputs, one for each elements.
            % Elements are meant to come from the function get_params(label) of an instance of Gaussianclassifier.
            similarity_score = -norm(params1.mean - params2.mean);
        end
        
        function dispersion_score = compute_simple_dispersion(params, weights, varargin)
            % Compute a simple dispersion between different gaussians only based on the mean dispersion
            % This is computed by estimating the weighted covariance of the mean of each distribution, the diperstion would then be the trave of the weighted covariance.
            % params - cell vector of parameters [cell vector (1 x nElements)]
            % Parameters elements are meant to come from the function get_params(label) of an instance of Gaussianclassifier.
            % weights - weights of each elements [vector (1 x nElements)]
            means = cellfun(@(x) x.mean, params, 'UniformOutput', false);
            means = cell2mat(means');
            classifier = Gaussian_classifier(varargin{:});
            classifier.fit(means, weights')
            dispersion_score = trace(classifier.parameters{1}.covariance);
        end
        
        function disagreement_score = classifier_disagreement(struct1, struct2)
            nLabels = length(struct1.parameters);
            disagreement_score = zeros(nLabels);
            for iLabel = 1:nLabels
                for jLabel = 1:nLabels
                    disagreement_score(iLabel, jLabel) = (1 - Gaussian_classifier.compute_bhattacharyya_similarity(struct1.parameters{iLabel}, struct2.parameters{jLabel})) * struct1.pLabel(iLabel) * struct2.pLabel(jLabel);
                end
            end
            disagreement_score = sum(sum(disagreement_score));
        end
        
    end
end

