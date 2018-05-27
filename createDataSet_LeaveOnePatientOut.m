function createDataBy2Patients(oneOrTwoOut)
    load ParkinsonDataSets/BalancedShuffledBigData_forLeaveOneOut20per.mat clean_data clean_label clean_patient;

    timeString = datestr(datetime('now'));
    timeString = regexprep(timeString, ' ', '_');
    timeString = regexprep(timeString, ':', '-');

    % creating a dataset for each 2 patients
    uniquePatients = unique(clean_patient);
    if strcmp(oneOrTwoOut,'two')
        %use two random numbers
        for i=1:size(uniquePatients,1)
           for j=i+1:size(uniquePatients,1)
               % disp([num2str(uniquePatients(i)), '   ',num2str(uniquePatients(j))])
               % generate train data
               indexToTrain = find(clean_patient ~= uniquePatients(i) & clean_patient ~= uniquePatients(j));
               trainDataPair = clean_data(indexToTrain,:);
               trainLabelsPair = clean_label(indexToTrain,:);
               trainPatientPair = clean_patient(indexToTrain,:);
               % generate test data
               indexToTest = find(clean_patient == uniquePatients(i) | clean_patient == uniquePatients(j));
               testDataPair = clean_data(indexToTest,:);
               testLabelsPair = clean_label(indexToTest,:);
               testPatientPair = clean_patient(indexToTest,:);

               fileName = strcat('ParkinsonSubDataset_' ,num2str(uniquePatients(i)),'_', num2str(uniquePatients(j)));
               mkdir('DatasetLeaveTwoOut',fileName)
               save(strcat('DatasetLeaveTwoOut/' ,fileName, '/',fileName,'_Train.mat'),'trainDataPair','trainLabelsPair','trainPatientPair');
               save(strcat('DatasetLeaveTwoOut/' ,fileName, '/',fileName,'_Test.mat'),'testDataPair','testLabelsPair','testPatientPair');
               fprintf('finshed patient number: %d_%d\n', i, j);
           end
        end
    elseif strcmp(oneOrTwoOut,'one')
       %using leave one out
       for i=1:size(uniquePatients,1)
           % genrate the train data
           indexToTrain = find(clean_patient ~= uniquePatients(i));
           trainDataPair = clean_data(indexToTrain,:);
           trainLabelsPair = clean_label(indexToTrain,:);
           trainPatientPair = clean_patient(indexToTrain,:);
           %genrate the test data
           indexToTest = find(clean_patient == uniquePatients(i));
           testDataPair = clean_data(indexToTest,:);
           testLabelsPair = clean_label(indexToTest,:);
           testPatientPair = clean_patient(indexToTest,:);
           %save to dir
           parent_dir = strcat('DatasetLeaveOneOut_',timeString);
           fileName = strcat('ParkinsonSubDataset_' ,num2str(uniquePatients(i)));
           mkdir(parent_dir,fileName)
           save(strcat(parent_dir, '/' ,fileName, '/',fileName,'_Train.mat'),'trainDataPair','trainLabelsPair','trainPatientPair');
           save(strcat(parent_dir, '/' ,fileName, '/',fileName,'_Test.mat'),'testDataPair','testLabelsPair','testPatientPair');
           fprintf('finshed patient idx: %d value: %d\n', i,uniquePatients(i));
       end
    else
        error('invalid oneOrTwoOut argument parameter !!! :( ')
    end
end
