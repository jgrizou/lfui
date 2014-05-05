function hypothesisLogLikelihoods = compute_estimates(methodInfo, hypothesisClassifiers, teacherSignals, teacherHypothesisPLabels, varargin)
%COMPUTE_FILTER_PROBA

nHypothesis = length(teacherHypothesisPLabels);
nObservation = size(teacherSignals,1);
hypothesisLogLikelihoods = zeros(1, nHypothesis);

switch methodInfo.estimateMethod
    
    case 'matching'
        for iHyp = 1:nHypothesis
            
            [nCrossValidation] = process_options(varargin, 'nCrossValidation', []);
            
            confusionMatrix = hypothesisClassifiers{iHyp}.compute_proba_empirical_confusion_matrix(nCrossValidation);
            % normalize it per column!  may be optimized
            confusionMatrix = proba_normalize_row(confusionMatrix')';
            
            %the following could be done more accurately in the log domain
            switch methodInfo.cumulMethod
                case 'batch'
                    predictedPLabel = hypothesisClassifiers{iHyp}.logpredict(teacherSignals);
                    for iObservation = 1:nObservation
                        correctedPredictedPLabel = confusionMatrix * predictedPLabel(iObservation, :)';
                        matchingProba = teacherHypothesisPLabels{iHyp}(iObservation,:) * correctedPredictedPLabel;
                        hypothesisLogLikelihoods(iHyp) = hypothesisLogLikelihoods(iHyp) + log(matchingProba + realmin);
                    end
                    
                case 'filter'
                    predictedPLabel = hypothesisClassifiers{iHyp}.logpredict(teacherSignals(end, :));
                    %the following could be done more accurately in the log domain
                    correctedPredictedPLabel = confusionMatrix * predictedPLabel';
                    matchingProba = teacherHypothesisPLabels{iHyp}(end,:) * correctedPredictedPLabel;
                    hypothesisLogLikelihoods(iHyp) = log(matchingProba + realmin);
            end
        end
        
    case 'simple_matching'
        %no confusion matrix
        for iHyp = 1:nHypothesis
            %the following could be done more accurately in the log domain
            switch methodInfo.cumulMethod
                case 'batch'
                    predictedPLabel = hypothesisClassifiers{iHyp}.logpredict(teacherSignals);
                    for iObservation = 1:nObservation
                        matchingProba = teacherHypothesisPLabels{iHyp}(iObservation,:) * predictedPLabel';
                        hypothesisLogLikelihoods(iHyp) = hypothesisLogLikelihoods(iHyp) + log(matchingProba + realmin);
                    end
                    
                case 'filter'
                    predictedPLabel = hypothesisClassifiers{iHyp}.logpredict(teacherSignals(end, :));
                    %the following could be done more accurately in the log domain
                    matchingProba = teacherHypothesisPLabels{iHyp}(end,:) * predictedPLabel';
                    hypothesisLogLikelihoods(iHyp) = log(matchingProba + realmin);
            end
        end
        
    case 'model'
        for iHyp = 1:nHypothesis
            %the following could be done more accurately in the log domain
            switch methodInfo.cumulMethod
                case 'batch'
                    loglikelihood = hypothesisClassifiers{iHyp}.logpredict(teacherSignals, false);
                    labelLoglikelihood = loglikelihood + log(teacherHypothesisPLabels{iHyp} + realmin);
                    
                    for iObservation = 1:nObservation
                        hypothesisLogLikelihoods(iHyp) = hypothesisLogLikelihoods(iHyp) + add_log_array(labelLoglikelihood(iObservation, :));
                    end
                    
                case 'filter'
                    loglikelihood = hypothesisClassifiers{iHyp}.logpredict(teacherSignals(end, :), false);
                    labelLoglikelihood = loglikelihood + log(teacherHypothesisPLabels{iHyp}(end, :) + realmin);
                    hypothesisLogLikelihoods(iHyp) = add_log_array(labelLoglikelihood);
            end
        end
        
    case 'bhattacharyya'
        for iHyp = 1:nHypothesis
            bhattacharyyaCoef_pairwise = hypothesisClassifiers{iHyp}.pairwise_bhattacharyya_similarity();
            if length(bhattacharyyaCoef_pairwise) > 1
                error('compute_sampling_proba:notimplemented', 'not implemented')
                %if two label it works, otherwise multiple value outputed
                %investigate later, maybe a product would do
            end
            hypothesisLogLikelihoods(iHyp) = log(1 - bhattacharyyaCoef_pairwise + realmin);
        end
        
    case 'power'
        [nCrossValidation] = process_options(varargin, 'nCrossValidation', []);
        
        for iHyp = 1:nHypothesis
            confusionMatrix = hypothesisClassifiers{iHyp}.compute_proba_empirical_confusion_matrix(nCrossValidation);
            % normalize it per column!  may be optimized
            confusionMatrix = proba_normalize_row(confusionMatrix')';
            
            %compute powers
            powers = sum(teacherSignals.^2, 2);
            
            %
            predictedPLabel = hypothesisClassifiers{iHyp}.logpredict(teacherSignals);
            correctedPredictedPLabel = zeros(size(predictedPLabel));
            for iObservation = 1:nObservation
                correctedPredictedPLabel(iObservation, :) = confusionMatrix * predictedPLabel(iObservation, :)';
            end
            
            %compute loglikelihood
            powerCorrect = weighted_mean(powers, correctedPredictedPLabel(:,1));
            powerWrong = weighted_mean(powers, correctedPredictedPLabel(:,2));
            hypothesisLogLikelihoods(iHyp) = log(powerWrong/powerCorrect + realmin);
        end
         
    otherwise
        error('compute_filter_proba:notimplemented', [methodInfo.estimateMethod, ' is not implemented'])
        
        
end


