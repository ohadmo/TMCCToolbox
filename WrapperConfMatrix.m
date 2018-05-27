function res = WrapperConfMatrix(cmatrix, labelsKeys)
outOneClusterConf = cell(24,12);
% wrapper for the counting matrix
outOneClusterConf(1,5) = {'predicted'};
outOneClusterConf(5,1) = {'actual'};
outOneClusterConf(2,3:9)= labelsKeys;
outOneClusterConf(3:9,2)= labelsKeys;
outOneClusterConf(3:9,3:9) = num2cell(cmatrix);
%wrapper for the presentage matrix
outOneClusterConf(10,5) = {'predicted(%)'};
outOneClusterConf(15,1) = {'actual(%)'};
outOneClusterConf(11,3:9)= labelsKeys;
outOneClusterConf(12:18,2)= labelsKeys;
outOneClusterConf(12:18,3:9) = num2cell(cmatrix./repmat(sum(cmatrix,2),1,length(cmatrix)));
%overall success rate
outOneClusterConf(1,11) = {'total sucess rate'};
outOneClusterConf(1,12) = num2cell(FromConfMatToSuccessRate(cmatrix));
outOneClusterConf(2,11) = {'number of samples classified correctly'};
outOneClusterConf(2,12) = num2cell(trace(cmatrix));
outOneClusterConf(3,11) = {'total number of samples'};
outOneClusterConf(3,12) = num2cell(sum(sum(cmatrix)));

res = outOneClusterConf; % return the wrapped matrix to outputing
end
function SucessRateAllFolds = FromConfMatToSuccessRate(confMat)
if size(confMat,1) ~= size(confMat,2)
    error('The conf matrix rows # must be equal to coulmn')
end
SucessRateAllFolds = trace(confMat)/sum(sum(confMat));
end