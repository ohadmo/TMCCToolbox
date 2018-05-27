function res = addToWrappingConfMatrixTrainDataInfo(mtx, trainLabel, cellOfLabels)
%cacluate and store the train data distribution
mtx(19,5) = {'Train Data Info for current Cluster'};
%C = categorical(trainLabel,[3 4 5 6 7 8 9],{'3', '4', '5', '6', '7', '8', '9'});
C = categorical(trainLabel, cell2mat(cellOfLabels), cellfun(@num2str,cellOfLabels, 'UniformOutput', false));
[counter,indexCounter] = histcounts(C);
mtx(20,1) = {'class label'};
mtx(20,2:1+size(indexCounter,2))= indexCounter;
mtx(21,1) = {'class count'};
mtx(21,2:1+size(indexCounter,2))= num2cell(counter);
mtx(22,1) = {'train class dist'};
distCounter = counter;
for q=1:size(distCounter,2)
    distCounter(q) = distCounter(q)/sum(counter);
end
mtx(22,2:1+size(indexCounter,2))= num2cell(distCounter);
res = mtx; % return the wrapped matrix to outputing
end