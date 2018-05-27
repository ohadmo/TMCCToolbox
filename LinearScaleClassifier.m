% LinearScaleClassifier('whiteWine', 'ParkinsonDataSets/WineQualityWhite.mat', 'svm', 'clean_data', 'clean_label', 'clean_patient', 5)
% DONT USE WITH svm_OvA (classifier use 2 classes)
function LinearScaleClassifier(datasetType, filepath, method, dataName, labelName, patientName, n_folds)

    function [CountLabelsMat,trainedModels] = PerformLSC(classificationMethod, uniqueLabelsOrdered, train_samples, train_labels, test_samples, test_labels, mapper)
        desiredClassifier = ClassificationMethods(classificationMethod, mapper);
        trainedModels = cell(length(uniqueLabelsOrdered)-1, 1);
        LSCpart = cell(length(uniqueLabelsOrdered)-1,2);
        CountLabelsMat = zeros(length(test_labels),7);  % change back he 7 into length(uniqueLabelsOrdered)
        
        for idx=1:length(uniqueLabelsOrdered)-1 % to optimize parfor
            LSCpart{idx,1} = uniqueLabelsOrdered(1:idx);
            LSCpart{idx,2} = uniqueLabelsOrdered(idx+1:end);
        end
        x = LSCpart(:,1); % to optimize parfor
        y = LSCpart(:,2); % to optimize parfor
        parfor idx=1:length(uniqueLabelsOrdered)-1        
            fprintf('****starting LSC part no. i=%d, part1=%s, part2=%s **** \n', idx, mat2str(x{idx}), mat2str(y{idx}))
            trainedModels{idx} = desiredClassifier.chosenClassifier.train(train_samples, ismember(train_labels,y{idx}));
        end
        for idx=1:length(uniqueLabelsOrdered)-1
            %[plabels, ~, ~ ] = desirfedClassifier.chosenClassifier.test(test_samples, test_labels, trainedModels{idx});
            plabels = desiredClassifier.chosenClassifier.test(test_samples, test_labels, trainedModels{idx});

            for j=1:length(plabels)
                LabelstoIncrease = LSCpart{idx,plabels(j)+1}; % Note, the 1
                for k=1:length(LabelstoIncrease)
                    desiredCol = mapper.ChangeLabelToInteger(LabelstoIncrease(k));
                    try
                        CountLabelsMat(j,desiredCol) = CountLabelsMat(j,desiredCol) + 1;
                    catch
                        disp(j)
                        disp(desiredCol)
                        error('!!!!')
                    end
                end
            end
        end
    end
    function mat = CalculateMaxIndexEachRow(sumLSC, mapper)
        mat = NaN(length(sumLSC),1);
        for idx=1:length(sumLSC)
            vec = sumLSC(idx,:);
            m  = max(vec);
            maxIndex = find(vec == m);
            if length(maxIndex) == 1
                mat(idx) = mapper.ChangeIntegerToLabel(maxIndex);
            end
        end
    end
    function confMat = CalculateConfMatrix(p_labels, mapper, TestingLabels)
        confMat = zeros(7,7);
        count=0;
        for idx=1:length(p_labels)
            if ~isnan(p_labels(idx))
                pl = mapper.ChangeLabelToInteger(p_labels(idx));
                tl = mapper.ChangeLabelToInteger(TestingLabels(idx));
                if eq(pl,tl)
                    count = count + 1;
                end
                confMat(tl,pl) = confMat(tl,pl) + 1;
            end
        end       
    end

warning('off','MATLAB:xlswrite:AddSheet');

allFields = load(filepath, dataName, labelName, patientName);
samples = allFields.(dataName);
labels = allFields.(labelName);
input_len = length(labels);
OrderedLabelsLSC = unique(labels);
labelsMapper = ParkinsonsLabelsMapping(datasetType);

timeString = datestr(datetime('now'));
timeString = regexprep(timeString, ' ', '_');
timeString = regexprep(timeString, ':', '-');
[~,datasetname,~] = fileparts(filepath);
xlsOutputFile = strcat('LinearScaleClassifier_', method, '_', datasetname, '_', timeString, '_folds-',num2str(n_folds),'.xlsx');

rand_ind = randperm(input_len);
ac = [];
for i_fold=1:n_folds
    fprintf('Starting Cross Validation %d out of %d \n',i_fold,n_folds);
    test_ind = rand_ind(floor((i_fold-1)*input_len/n_folds)+1:floor(i_fold*input_len/n_folds));
    train_ind = (1:input_len)';
    train_ind(test_ind) = [];    
    
    samplesTrain = samples(train_ind,:);
    labelsTrain = labels(train_ind);
    samplesTest = samples(test_ind,:);
    labelsTest = labels(test_ind);
    
    % training & testing
    sumPredictedLabels = PerformLSC(method, OrderedLabelsLSC, samplesTrain, labelsTrain, samplesTest, labelsTest, labelsMapper);
    % finiding the max index, marking samples with more than one max
    predictedLabels = CalculateMaxIndexEachRow(sumPredictedLabels, labelsMapper);
    ac = [ac,  sum(labelsTest == predictedLabels)];
    
    %create conf matrix
    LscConfMat = CalculateConfMatrix(predictedLabels, labelsMapper, labelsTest);
    
    %output to file
    outMat = WrapperConfMatrix(LscConfMat, labelsMapper.labelToInteger.keys());
    outMat = addToWrappingConfMatrixTrainDataInfo(outMat, labelsTrain, labelsMapper.labelToInteger.keys());
    outMat(5,11) = {'filtered out due to nan values(tie in decistion)'};
    outMat(5,12) = {sum(isnan(predictedLabels))};
    outMat(6,11) = {'filtered out in %'};
    outMat(6,12) = {sum(isnan(predictedLabels))/length(predictedLabels)*100};
    xlswrite(xlsOutputFile, outMat, strcat('ConfMatLSC_',num2str(i_fold),'-',num2str(n_folds)));
end
acOut = sum(ac) / input_len * 100;
acAvg = ac/floor(input_len/n_folds)*100;
fprintf('Cross-validation Accuracy = %g%%  STD=%g\n', acOut, std(acAvg));
overAllOut = cell(2,2);
overAllOut{1,1} = 'accuracy';
overAllOut{2,1} = 'std';
overAllOut{1,2} = acOut;
overAllOut{2,2} = std(acAvg);

xlswrite(xlsOutputFile, overAllOut, 'overall_accuracy');
end