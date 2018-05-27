clear;
diary off
delete('logging.out')
diary logging.out
diary on

%%%%%%%%%%%%%%%%%%
EachTwoPatientsPath = 'D:\GitHub\ParkinsonKohonen\DatasetLeaveOneOut_whiteWine\';
method = 'svm_OvA';
datasetType = 'whiteWine';
isLeaveOneOut = false;
%%%%%%%%%%

d = dir(EachTwoPatientsPath);
isub = [d(:).isdir]; %returns logical vector
nameFolds = {d(isub).name}';
nameFolds(ismember(nameFolds,{'.','..'})) = [];
for k=1:length(nameFolds) % for each patient
    nameFolds(k) = strcat(EachTwoPatientsPath, nameFolds(k));
end

for k=1:length(nameFolds) 
    fprintf('********%s********\n',nameFolds{k})    
    resultsDir = dir(nameFolds{k});
    isdirectory = [resultsDir(:).isdir]; % returns logical vector
    onlyFolders = {resultsDir(isdirectory).name}';
    onlyFolders(ismember(onlyFolders,{'.','..'})) = []; 
    if isempty(strcat(onlyFolders))
        error('No folder to run ');
    end
    for j=1:length(onlyFolders) %for each kohonen run (just one)
         onlyFolders(j) = (strcat(nameFolds(k),'/',onlyFolders(j),'/'));
         fprintf('####%s\n',onlyFolders{j})
         
         % Support old relabeling output
         delete(strcat(onlyFolders{j} , 'RELABELED*.mat'));
         
         % Run svm
         delete(strcat(onlyFolders{j} , 'EachClusterClassification*'));
         
         % Execute for multiple folders as folds or as leave one patinet out
         if isLeaveOneOut
            applyClassificationEachNeuronLeaveOneOut(datasetType, onlyFolders{j}, method, 'nClass', 'nLabel', 'nPatient');
         else
            applyClassificationEachNeuron(datasetType, 'duplicate_train', onlyFolders{j}, method, 'nClass','nLabel', 'nPatient', 5);
         end
    end
end
diary off

