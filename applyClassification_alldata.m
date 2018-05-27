% applySVM_alldata('parkinson', 'not_duplicate_train', 'ParkinsonDataSets/BalancedShuffledBigData.mat', 'svm', 'clean_data', 'clean_label', 'clean_patient', 5, [], 'ConfMatrices')
function applySVM_alldata(datasetType, duplicationFlag, DatasetPath, method, dataName, labelName, patientName, n_folds, filename, sheetname)
% Initialisation of POI Libs
javaaddpath('poi_library/poi-3.8-20120326.jar');
javaaddpath('poi_library/poi-ooxml-3.8-20120326.jar');
javaaddpath('poi_library/poi-ooxml-schemas-3.8-20120326.jar');
javaaddpath('poi_library/xmlbeans-2.3.0.jar');
javaaddpath('poi_library/dom4j-1.6.1.jar');
javaaddpath('poi_library/stax-api-1.0.1.jar');
% Set warnings off
warning('off','MATLAB:xlswrite:AddSheet');
warning('off','MATLAB:warn_truncate_for_loop_index');

% Naming output file
xlsSavingFile = outputfileNaming(filename, DatasetPath, method, n_folds);

% Load data from path
allFields = load(DatasetPath, dataName, labelName, patientName);
samples = allFields.(dataName);
labels = allFields.(labelName);
input_len = length(labels);

% Mapping the labels
labelsMapper = ParkinsonsLabelsMapping(datasetType);

% Normalizing the Data
%samples = (samples - min(samples))./(max(samples)-min(samples));
% Standardize the Data
meansArray = ones(size(samples)) * diag(mean(samples));
stdarray = ones(size(samples)) * diag(std(samples));
samples = (samples - meansArray)./stdarray;
% ^ to support older matlab version in NoName
%samples = (samples - mean(samples))./std(samples);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
All_conf_folds = [];
isResultValid = false;
ParamSearchCost = 2; %-5:10;
ParamSearchGamma = 0.03; %-10:2;
%ParamSearchCost = 2.^ParamSearchCost;
%ParamSearchGamma = 2.^ParamSearchGamma;

rand_ind = randperm(input_len);
ac = [];
for parCost = ParamSearchCost
    for parGamma = ParamSearchGamma
        confMatrixAllFold = zeros(7,7); % set to zero before each fold
        for i_fold = 1:n_folds
            %fprintf('Starting Cross Validation %d out of %d   : ',i_fold,n_folds);
            [trainData,trainLabel,testData,testLabel] = prepareTrainTestDataForFold (input_len, n_folds, i_fold, samples, labels, datasetType, duplicationFlag, rand_ind);

            if isempty(trainLabel)
                fprinf('!!!!! trainLabelis empty\n');
            elseif isempty(testLabel)
                fprintf('!!!! testLabel is empty\n');
            elseif length(unique(trainLabel)) <= 1
                fprintf('!!!! CANT TRAIN SVM ONLY ON ONE CLASS \n');
            %elseif (isempty(find(ismember(unique(testLabel),unique(trainLabel))==0)) == false)
            %    fprintf('!!!! labels in testLabel that dont appear in trainLabel\n')
            else
                isResultValid = true;
                desirfedClassifier =  ClassificationMethods(method,labelsMapper);
                trained =  desirfedClassifier.chosenClassifier.train(trainData, trainLabel, parCost, parGamma);
                results = desirfedClassifier.chosenClassifier.test(testData, testLabel, trained);

                
                confMatrixOneFold = zeros(7,7);
                count=0;
                for i=1:length(results)
                    if eq(results(i),testLabel(i))
                        count=count+1;
                    end
                    confMatrixOneFold(labelsMapper.ChangeLabelToInteger(testLabel(i)),labelsMapper.ChangeLabelToInteger(results(i))) = ...
                        confMatrixOneFold(labelsMapper.ChangeLabelToInteger(testLabel(i)),labelsMapper.ChangeLabelToInteger(results(i))) + 1;
                end
                ac = [ac, count];
                confMatrixAllFold = confMatrixAllFold + confMatrixOneFold;
                
                % conf matrix each cluster
                outClusterConfMat = WrapperConfMatrix(confMatrixOneFold, labelsMapper.labelToInteger.keys());
                outClusterConfMat = addToWrappingConfMatrixTrainDataInfo(outClusterConfMat,trainLabel,labelsMapper.labelToInteger.keys());
                outClusterConfMat(1,1) = {strcat(num2str(i_fold), 'out', num2str(n_folds))};
                All_conf_folds = cat(1,All_conf_folds,outClusterConfMat);
                fprintf('correct:%d,  total:%d, SucessRate:%f\n', count,length(results),count/length(results));
            end
        end %Finished all folds
        if isResultValid
            % Adding an average confusion matrix between all the N folds of the cross validation
            outAvgConfMat = WrapperConfMatrix(confMatrixAllFold, labelsMapper.labelToInteger.keys());
            outAvgConfMat(19:22,1:8) = {'='};
            outAvgConfMat(1,1) = {strcat('SUM','out',num2str(n_folds))};
            All_conf_folds = cat(1,outAvgConfMat,All_conf_folds);
            
            acOut = sum(ac) / input_len * 100;
            acAvg = ac/floor(input_len/n_folds)*100;
            fprintf('Cross-validation Accuracy = %g%%  STD=%g rbf with C=%f gama=%f\n', acOut, std(acAvg), parCost, parGamma);
            lastline = cell(1,12);
            lastline(1,5)= {'CV Accuracy(%)='};
            lastline(1,6)= {acOut};
            lastline(1,8)= {'STD='};
            lastline(1,9)= {std(acAvg)};
            xlwrite(strcat(xlsSavingFile,'.xlsx'), [All_conf_folds; lastline], strcat(sheetname,'_',num2str(parCost),'_',num2str(parGamma))); % xlsx ending is needed for the xlwrite, otherwise saves only last sheet
        end
        ac = [];
        All_conf_folds=[];
        isResultValid = false;
    end
end
end

function  xlsout = outputfileNaming(fname, DataPath, classification_method, number_of_folds)
if isempty(fname)
    timeString = datestr(datetime('now'));
    timeString = regexprep(timeString, ' ', '_');
    timeString = regexprep(timeString, ':', '-');
    [~,datasetname,~] = fileparts(DataPath);
    xlsout = strcat('AllDataClassification_', classification_method, '_', datasetname, '_', timeString, '_folds-', num2str(number_of_folds));
else
    xlsout = fname;
end
end
function [trainD, trainL, testD, testL] = prepareTrainTestDataForFold(input_length, total_folds, cur_fold, all_samples, all_labels, dataset_type, duplication_flag, shuffledIndices)
test_ind = shuffledIndices(floor((cur_fold-1)*input_length/total_folds)+1:floor(cur_fold*input_length/total_folds));
train_ind = (1:input_length)';
train_ind(test_ind) = [];
trainD = all_samples(train_ind,:);
trainL = all_labels(train_ind);
% replicating traning samples
if strcmp(duplication_flag, 'duplicate_train')
    if strcmp(dataset_type,'parkinson')
        error('Should not balance by replicating train data with parkinsons dataset')
    end
    [trainD,trainL] = replicateTrainData(trainD,trainL);
end

testD = all_samples(test_ind,:);
testL = all_labels(test_ind);
end
