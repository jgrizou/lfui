function recorder_compute_proba(rec, methodInfo)
%RECORDER_COMPUTE_PROBA

filestr = generate_method_filestr(methodInfo);

%% train classifiers
hypothesisClassifiers = cell(1, rec.nHypothesis);
if length(rec.iStep) > rec.nInitSteps
    switch methodInfo.classifierMethod
        
        case 'online'
            switch methodInfo.cumulMethod
                case 'batch'
                    for iHyp = 1:rec.nHypothesis
                        hypothesisClassifiers{iHyp} = rec.blankClassifier();
                        hypothesisClassifiers{iHyp}.fit(rec.teacherSignal, rec.(rec.hypothesisRecordNames{iHyp}))
                    end
                case 'filter'
                    for iHyp = 1:rec.nHypothesis
                        hypothesisClassifiers{iHyp} = rec.blankClassifier();
                        hypothesisClassifiers{iHyp}.fit(rec.teacherSignal(1:end-1, :), rec.(rec.hypothesisRecordNames{iHyp})(1:end-1, :))
                    end
            end
            rec.replace_field(['classifiers_', filestr], hypothesisClassifiers)
            
        case 'calibration'
            %if no classifier yet, train it
            if rec.is_prop(['classifiers_', filestr]) && ...
                    isempty(rec.(['classifiers_', filestr]){1})
                %create dataset
                rec.teacherDispatcher.reset
                for icr = 1:length(rec.calibrationRatio)
                    nPoint = round(rec.nInitSteps * rec.calibrationRatio(icr));
                    pLabel = zeros(1, length(rec.calibrationRatio));
                    pLabel(icr) = 1;
                    for pp = 1:nPoint
                        rec.log_field('calibrationX', rec.teacherDispatcher.get_sample(icr))
                        rec.log_field('calibrationpY', pLabel)
                    end
                end
                % train classifier
                classifier = rec.blankClassifier();
                classifier.fit(rec.calibrationX, rec.calibrationpY)
                % same for all
                for iHyp = 1:rec.nHypothesis
                    hypothesisClassifiers{iHyp} = classifier;
                end
                rec.replace_field(['classifiers_', filestr], hypothesisClassifiers)
            end
            
        otherwise
            error('recorder_compute_proba:notimplemented', [methodInfo.classifierMethod, ' is not implemented'])
            
    end
else
    rec.replace_field(['classifiers_', filestr], hypothesisClassifiers)
end


%% compute estimates
switch methodInfo.samplingMethod
    case 'sampling'
        nSampling = rec.nSampling;
        
    case 'one_shot'
        nSampling = 1;
        
    otherwise
        error('recorder_compute_proba:notimplemented', [methodInfo.samplingMethod, ' is not implemented'])
end

hypothesisLogLikelihoods = zeros(nSampling, rec.nHypothesis);

switch methodInfo.estimateMethod
    case 'power_matching'
        powerLogLikelihoods = zeros(nSampling, rec.nHypothesis);
end

if length(rec.iStep) > rec.nInitSteps
    for iSampling = 1:nSampling
        switch methodInfo.samplingMethod
            case 'sampling'
                samplingClassifiers = rec.(['classifiers_', filestr]);
                classifiers = cell(1, rec.nHypothesis);
                for iHyp = 1:rec.nHypothesis
                    classifiers{iHyp} = samplingClassifiers{iHyp}.sample_classifier();
                end
                
            otherwise
                classifiers = rec.(['classifiers_', filestr]);
        end
        
        switch methodInfo.estimateMethod
            
            case 'power_matching'
                tmpMethodInfo = methodInfo;
                
                tmpMethodInfo.estimateMethod = 'matching';
                hypothesisLogLikelihoods(iSampling, :) = ...
                    compute_estimates(tmpMethodInfo, ...
                    classifiers, ...
                    rec.teacherSignal, ...
                    rec.get_cell_of_fields(rec.hypothesisRecordNames), ...
                    'nCrossValidation', rec.nCrossValidation);
                
                tmpMethodInfo.estimateMethod = 'power';
                powerLogLikelihoods = ...
                    compute_estimates(tmpMethodInfo, ...
                    classifiers, ...
                    rec.teacherSignal, ...
                    rec.get_cell_of_fields(rec.hypothesisRecordNames), ...
                    'nCrossValidation', rec.nCrossValidation);
                
                
            otherwise
                hypothesisLogLikelihoods(iSampling, :) = ...
                    compute_estimates(methodInfo, ...
                    classifiers, ...
                    rec.teacherSignal, ...
                    rec.get_cell_of_fields(rec.hypothesisRecordNames), ...
                    'nCrossValidation', rec.nCrossValidation);
                
        end
    end
end

%% compute proba

switch methodInfo.samplingMethod
    case 'sampling'
        
        % this is quite ugly (not stable), think hard if possible to do
        % something else
        hypothesisEstimates = exp(hypothesisLogLikelihoods);
        rec.log_field(['estimates_', filestr], hypothesisEstimates)
        
        hypothesisConfidences = zeros(rec.nHypothesis, rec.nHypothesis);
        if length(rec.iStep) > rec.nInitSteps
            switch methodInfo.probaMethod
                case 'student'
                    [hypothesisConfidences, ~, ~] = compute_confidences_student(hypothesisEstimates, 0.5); % whatever the threshold we won't use it
                    
                case 'normal'
                    [hypothesisConfidences, ~, ~] = compute_confidences_normal(hypothesisEstimates, 0.5); % whatever the threshold we won't use it
                    
                case 'ttest2'
                    [hypothesisConfidences, ~, ~] = compute_confidences_ttest2(hypothesisEstimates, 0.5); % whatever the threshold we won't use it
            end
        end
        rec.log_field(['confidences_', filestr], hypothesisConfidences)
        
        hypothesisProbabilities = compute_min_confidences(hypothesisConfidences);
        
        
    otherwise
        switch methodInfo.cumulMethod
            case 'filter'
                rec.log_field(['logupdate_', filestr], hypothesisLogLikelihoods)
                %update the filter
                if rec.is_prop(['logLikelihoods_', filestr])
                    hypothesisLogLikelihoods = hypothesisLogLikelihoods + rec.(['logLikelihoods_', filestr])(end, :);
                end
        end
        
        switch methodInfo.estimateMethod
            case 'power_matching'
                rec.log_field(['logpower_', filestr], powerLogLikelihoods)
                hypothesisLogLikelihoods = hypothesisLogLikelihoods + powerLogLikelihoods;
        end
        
        rec.log_field(['logLikelihoods_', filestr], hypothesisLogLikelihoods)
        
        switch methodInfo.probaMethod
            
            case 'normalize'
                hypothesisProbabilities = normalize_log_array(hypothesisLogLikelihoods);
                
            case 'pairwise'
                %pairwise comparison
                nla = @(x,y) normalize_log_array([x,y]);
                gvai = @(x,y) get_value_at_index(nla(x, y), 1);
                elements = num2cell(hypothesisLogLikelihoods);
                pw = pairwise_comparison(gvai, elements);
                pw = squareform(pw);
                conf = tril(pw) + triu(1-pw);
                hypothesisProbabilities = compute_min_confidences(conf);
                
            otherwise
                error('recorder_compute_proba:notimplemented', [methodInfo.probaMethod, ' is not implemented'])
                
        end
end

rec.log_field(['probabilities_', filestr], hypothesisProbabilities)





