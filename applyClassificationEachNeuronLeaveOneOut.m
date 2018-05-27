% applyClassificationEachNeuronLeaveOneOut('parkinson','D:\GitHub\ParkinsonKohonen\DatasetLeaveOneOut_BalancedShuffledBigData_LeaveOut20precent\LOORun_2018-01-08-160359\ParkinsonSubDataset_1\2018-01-08-160400\', 'svm_OvA', 'nClass', 'nLabel', 'nPatient')
function applyClassificationEachNeuronLeaveOneOut(dataType, dir_name, method, dataName, labelName, patientName)
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
xlsSavingFile = strcat(dir_name , 'EachClusterClassificationResults', timeString, '_', method,'.xlsx'); % the xlsx ending is needed, otherwise xlwrite saves only the last sheet

isResultValid = false;

labelsMapper = ParkinsonsLabelsMapping(dataType);
files = dir(strcat(dir_name , 'neuron_TESTDATA*.mat'));

distArray = [];

confMatrixAllClusters = zeros(7,7);

ParamSearchCost = -5:10;
ParamSearchGamma =-10:2;
ParamSearchCost = 2.^ParamSearchCost;
ParamSearchGamma = 2.^ParamSearchGamma;
%ParamSearchCost = 1;
%ParamSearchGamma =0.03;

for file=files' % for each neron in the lattice
    testDataStruct = load(strcat(dir_name, file.name), dataName, labelName, patientName);
    %load train data struct
    tmp = strsplit(file.name,'TESTDATA');
    tmp = strcat(tmp(1),tmp(2));
    trainDataStruct = load(strcat(dir_name,tmp{:}), dataName, labelName, patientName); % retrive train neuron(file) from test neuron(file) name
    
    trainData = trainDataStruct.nClass;
    testData = testDataStruct.nClass;
    trainLabel = trainDataStruct.nLabel;
    testLabel = double(testDataStruct.nLabel);   % make sure its not uint8 otherwise will cause a probelm when concatating arrays
    
    MaxSuccessRateForFile = 0;
    MaxOneClusterConfMat = NaN;
    MaxOneClusterConfMatCellWrapped = NaN;
    
    for parCost=ParamSearchCost
        for parGamma=ParamSearchGamma
            tempCurrentClusterResConfMatrix = NaN;
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
                trained =  desirfedClassifier.chosenClassifier.train(trainData, trainLabel',parCost, parGamma);
                results = desirfedClassifier.chosenClassifier.test(testData, testLabel', trained);
                
                confMatrixOneCluster = zeros(7,7);
                count=0;
                for i=1:length(results)
                    if eq(results(i),testLabel(i))
                        count=count+1;
                    end
                    confMatrixOneCluster(labelsMapper.ChangeLabelToInteger(testLabel(i)),labelsMapper.ChangeLabelToInteger(results(i))) = ...
                        confMatrixOneCluster(labelsMapper.ChangeLabelToInteger(testLabel(i)),labelsMapper.ChangeLabelToInteger(results(i))) + 1;
                end
                if (count ~= trace(confMatrixOneCluster))
                    error('big mistake !!!!')
                end
                                
                % conf matrix each cluster
                outClusterConfMat = WrapperConfMatrix(confMatrixOneCluster,labelsMapper.labelToInteger.keys());
                outClusterConfMat(5,11) = {strcat('cost:',num2str(log(parCost)/log(2)))} ;
                outClusterConfMat(6,11) = {strcat('gamma:',num2str(log(parGamma)/log(2)))} ;
                outClusterConfMat = addToWrappingConfMatrixTrainDataInfo(outClusterConfMat, trainLabel, labelsMapper.labelToInteger.keys());                
                
                %fprintf('%s_correct:%d,  total:%d,  SucessRate:%f \n',file.name,count,length(results),count/length(results));
            end
            OneClusterAccuracyRate = FromConfMatToSuccessRate(confMatrixOneCluster);
            fprintf('%s Cluster Accuracy = %g%%  rbf with C=%f gama=%f\n', file.name, OneClusterAccuracyRate, log(parCost)/log(2), log(parGamma)/log(2));
            if OneClusterAccuracyRate > MaxSuccessRateForFile
                MaxSuccessRateForFile = OneClusterAccuracyRate;  % saving max value to be used later
                MaxOneClusterConfMat = confMatrixOneCluster;
                MaxOneClusterConfMatCellWrapped = outClusterConfMat;
            end
        end % gamma search
    end %cost search
    fprintf('%s Maximal Cluster Accuracy = %g%%  rbf with %s %s\n', file.name, MaxSuccessRateForFile, MaxOneClusterConfMatCellWrapped{5,11}, MaxOneClusterConfMatCellWrapped{6,11});
    % for sucess rate for each cluster- list
    outxls{lineIndex,1} = file.name;
    outxls{lineIndex,2} = trace(MaxOneClusterConfMat);
    outxls{lineIndex,3} = sum(sum(MaxOneClusterConfMat));
    outxls{lineIndex,4} = FromConfMatToSuccessRate(MaxOneClusterConfMat);
    lineIndex = lineIndex+1;
    
    % for sucess rate for each cluster- lattice
    tmp1 = strsplit(file.name,'neuron_TESTDATA');
    tmp2 = strsplit(tmp1{2},'.mat');
    tmp3 = strsplit(tmp2{1},'X');
    distArray(str2num(cell2mat(tmp3(1)))+1,str2num(cell2mat(tmp3(2)))+1) = FromConfMatToSuccessRate(MaxOneClusterConfMat);
    
    % for conf matrix one cluster
    xlwrite(xlsSavingFile, MaxOneClusterConfMatCellWrapped, strcat('ConfMatOneCluster_',tmp2{1}));
    
    % for conf matrix of all clusters
    confMatrixAllClusters = confMatrixAllClusters + MaxOneClusterConfMat;
    
end % end file(neuron) loop

if isResultValid
    xlwrite(xlsSavingFile, outxls, 'sucRateEachCluster');
    xlwrite(xlsSavingFile, distArray, 'distMat');
    outConfMat = WrapperConfMatrix(confMatrixAllClusters, labelsMapper.labelToInteger.keys());
    xlwrite(xlsSavingFile, outConfMat, 'ConfussionMatrixAllClusters');
end
end % end applyClassificationEachNeuronLeaveOneOut function

%%%%%%% Functions %%%%%%%
function SucessRateAllFolds = FromConfMatToSuccessRate(confMat)
if size(confMat,1) ~= size(confMat,2)
    error('The conf matrix rows # must be equal to coulmn')
end
SucessRateAllFolds = trace(confMat)/sum(sum(confMat));
end
