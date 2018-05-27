% applyClassificationEachNeuron('parkinson', 'not_duplicate_train', 'D:\GitHub\ParkinsonKohonen\ParkinsonsTrials\2017-12-10-015759\', 'svm_OvA', 'nClass', 'nLabel', 'nPatient', 5)
function applyClassificationEachNeuron(dataType, duplicationFlag, dir_name, method, dataName, labelName, patientName, num_folds)  %  input: DatasetLeaveOneOut\ParkinsonSubDataset_8\2016-09-23-090832\
% Initialisation of POI Libs
javaaddpath('poi_library/poi-3.8-20120326.jar');
javaaddpath('poi_library/poi-ooxml-3.8-20120326.jar');
javaaddpath('poi_library/poi-ooxml-schemas-3.8-20120326.jar');
javaaddpath('poi_library/xmlbeans-2.3.0.jar');
javaaddpath('poi_library/dom4j-1.6.1.jar');
javaaddpath('poi_library/stax-api-1.0.1.jar');

warning('off','MATLAB:xlswrite:AddSheet');
warning('off','MATLAB:warn_truncate_for_loop_index');

outxls = cell(0);
outxls{1,1} = 'clusterName';
outxls{1,2} = 'correct';
outxls{1,3} = 'size';
outxls{1,4} = 'success rate';
lineIndex = 2;

timeString = datestr(datetime('now'));
timeString = regexprep(timeString, ' ', '_');
timeString = regexprep(timeString, ':', '-');
xlsSavingFile = strcat(dir_name , 'EachClusterClassificationResults', timeString, '_', duplicationFlag, '_' , num2str(num_folds),'folds_', method,'.xlsx'); % the xlsx ending is needed, otherwise xlwrite saves only the last sheet

isResultValid = false;

labelsMapper = ParkinsonsLabelsMapping(dataType);
files = dir(strcat(dir_name , 'neuron*.mat'));

%%%%%
numberOfRowsInLattice = 0;
for file=files'
   cur_line = strsplit(file.name,'neuron_');
   cur_line = strsplit(cur_line{2},'X');
   cur_line = str2num(cur_line{1});
   if cur_line > numberOfRowsInLattice
       numberOfRowsInLattice = cur_line;
   end
end
numberOfRowsInLattice = numberOfRowsInLattice +1;
%%%%%

distArray = {};
confMatrixAllClusters = zeros(7,7);

ParamSearchCost = -5:10;
ParamSearchGamma =-10:2;
ParamSearchCost = 2.^ParamSearchCost;
ParamSearchGamma = 2.^ParamSearchGamma;
%ParamSearchCost = 1;
%ParamSearchGamma =0.03;

for file=files' % for each neuron in lattice
    dataStruct = load(strcat(dir_name, file.name), dataName, labelName, patientName);
    input_len = length(dataStruct.nLabel);
    rp =  randperm(input_len);
    tmp1 = strsplit(file.name,'neuron_');
    tmp2 = strsplit(tmp1{2},'.mat');
    tmp3 = strsplit(tmp2{1},'X');
    MaxSuccessRateForFile = 0;
    MaxSuccessRateOfFiveFoldsForFile = NaN;
    MaxFiveFoldsMatrices = NaN;
    MaxAllFoldsCellConfArray = NaN;
    MaxSumAllFoldsNumConfArray = NaN;
    for parCost=ParamSearchCost
        for parGamma=ParamSearchGamma
            confMatrixAllFolds = zeros(7,7);
            AllFoldsConfArray = [];
            tempDistArray = [];
            tempAllFoldsCellArray = [];
            for i_fold = 1:num_folds
                [trainData,trainLabel,testData,testLabel] = prepareTrainTestDataForFold(input_len, num_folds, i_fold, dataStruct.(dataName), dataStruct.(labelName), dataType, duplicationFlag, rp);
                if isempty(trainLabel)
                    fprinf('!!!! In filename %s, trainLabel is empty\n', file.name);
                elseif isempty(testLabel)
                    fprintf('!!!! In filename %s, testLabel is empty\n', file.name);
                elseif length(unique(trainLabel)) <= 1
                    fprintf('!!!! In filename %s , CANT RUN SVM ONLY ON ONE CLASS \n', file.name);
                    %elseif (isempty(find(ismember(unique(testLabel),unique(trainLabel))==0)) == false)
                    %    fprintf('!!!! In filename %s, labels in testLabel that dont appear in trainLabel\n', file.name)
                else
                    isResultValid = true;
                    desirfedClassifier =  ClassificationMethods(method, labelsMapper);
                    trained =  desirfedClassifier.chosenClassifier.train(trainData, trainLabel', parCost, parGamma);
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
                    if (count ~= trace(confMatrixOneFold))
                        error('big mistake !!!!')
                    end
                    confMatrixAllFolds = confMatrixAllFolds + confMatrixOneFold;
                    
                    % used for sucess rate list of each fold in one cluster
                    tempAllFoldsCellArray = [tempAllFoldsCellArray, {confMatrixOneFold}];
                    
                    % sucess rate distribution presented as a lattice for each fold
                    tempDistArray = [tempDistArray, FromConfMatToSuccessRate(confMatrixOneFold)];
                                   
                    % conf matrix each cluster
                    outOneFoldConfMat = WrapperConfMatrix(confMatrixOneFold,labelsMapper.labelToInteger.keys()); % returns a cell array
                    outOneFoldConfMat(5,11) = {strcat('cost:',num2str(log(parCost)/log(2)))} ;
                    outOneFoldConfMat(6,11) = {strcat('gamma:',num2str(log(parGamma)/log(2)))} ;
                    outOneFoldConfMat = addToWrappingConfMatrixTrainDataInfo(outOneFoldConfMat, trainLabel, labelsMapper.labelToInteger.keys());
                    outOneFoldConfMat(1,1) = {strcat(num2str(i_fold), 'out', num2str(num_folds))};
                    AllFoldsConfArray = cat(1,AllFoldsConfArray,outOneFoldConfMat);
                    
                    %fprintf('%s_correct:%d,  total:%d,  SucessRate:%f  , cost:%d  gamma:%d \n',file.name, count, length(results), count/length(results), log(parCost)/log(2), log(parGamma)/log(2));

                end % ending not empty if
            end % ending folds loop
            fprintf('%s CV Accuracy = %g%%  rbf with C=%f gama=%f\n', file.name, FromConfMatToSuccessRate(confMatrixAllFolds), log(parCost)/log(2), log(parGamma)/log(2));
            if FromConfMatToSuccessRate(confMatrixAllFolds) > MaxSuccessRateForFile
                MaxSuccessRateForFile = FromConfMatToSuccessRate(confMatrixAllFolds);  % saving max value to be used later
                MaxFiveFoldsMatrices = tempAllFoldsCellArray;
                MaxSuccessRateOfFiveFoldsForFile = tempDistArray;
                MaxSumAllFoldsNumConfArray = confMatrixAllFolds;
                MaxAllFoldsCellConfArray = AllFoldsConfArray;
            end
        end % end gamma search
    end % end cost search
    fprintf('%s Maximal Cross-validation Accuracy = %g%%  rbf with %s %s\n', file.name, MaxSuccessRateForFile, MaxAllFoldsCellConfArray{5,11}, MaxAllFoldsCellConfArray{6,11});
    % perform success rate output to a variable to be written to excel
    for i =1:length(MaxFiveFoldsMatrices)
        outxls{lineIndex,1} = file.name;
        outxls{lineIndex,2} = trace(MaxFiveFoldsMatrices{i});
        outxls{lineIndex,3} = sum(sum(MaxFiveFoldsMatrices{i}));
        outxls{lineIndex,4} = FromConfMatToSuccessRate(MaxFiveFoldsMatrices{i});
        outxls{lineIndex,5} = strcat('Fold',num2str(i),'OutOf',num2str(num_folds));
        lineIndex = lineIndex+1;
    end  
    % perform dist write to variable to be written to excel
    for i=1:length(MaxSuccessRateOfFiveFoldsForFile)
        i_idx = (str2num(cell2mat(tmp3(1)))+1) + (numberOfRowsInLattice + 2) * (i -1);
        distArray(i_idx, str2num(cell2mat(tmp3(2)))+1) = {MaxSuccessRateOfFiveFoldsForFile(i)};
    end
    % added to confMatrixAllClusters
    confMatrixAllClusters = confMatrixAllClusters + MaxSumAllFoldsNumConfArray;
    % A concatinating n-folds sum matrix and outputing to a sheet
    outAllFoldsConfMat = WrapperConfMatrix(MaxSumAllFoldsNumConfArray,labelsMapper.labelToInteger.keys());
    outAllFoldsConfMat(1,1) = {strcat('SUM', 'out', num2str(num_folds))};
    outAllFoldsConfMat(19:22,1:8) = {'='};
    MaxAllFoldsCellConfArray = cat(1,outAllFoldsConfMat,MaxAllFoldsCellConfArray);
    xlwrite(xlsSavingFile, MaxAllFoldsCellConfArray, strcat('ConfMatOneCluster-',tmp2{1}));
    
end % end file(neuron) loop

if isResultValid
    xlwrite(xlsSavingFile, outxls, 'sucRateEachCluster');
    xlwrite(xlsSavingFile, distArray, 'distMat');
    outConfMat = WrapperConfMatrix(confMatrixAllClusters, labelsMapper.labelToInteger.keys());
    xlwrite(xlsSavingFile, outConfMat, 'ConfussionMatrixAllClusters');
end
end % end applyClassificationEachNeuron main function

%%%%%%% Functions %%%%%%%

function SucessRateAllFolds = FromConfMatToSuccessRate(confMat)
if size(confMat,1) ~= size(confMat,2)
    error('The conf matrix rows # must be equal to coulmn')
end
SucessRateAllFolds = trace(confMat)/sum(sum(confMat));
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
else
    if strcmp(dataset_type,'whiteWine')
        error('Should balance by replicating train data with whiteWine dataset')
    end
end
testD = all_samples(test_ind,:);
testL = all_labels(test_ind)';
end