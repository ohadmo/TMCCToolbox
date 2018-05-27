classdef CM_SVM_OvA < handle
    properties
        LabelsUsedTraining
        mapper
    end  
    methods
        function obj = CM_SVM_OvA(dataMapper)
            obj.mapper = dataMapper;
        end
        function models =  train(obj, dataSamples, dataLabels ,x, y)
            obj.LabelsUsedTraining = unique(dataLabels);
            myMapper = obj.mapper;
            models = cell(7,1);
            %fprintf('About to run svmtrain OvA with k: ')
            dataReLabels = arrayfun(@myMapper.ChangeLabelToInteger, dataLabels);
            parfor k=1:max(unique(dataReLabels'))
                if ismember(k,dataReLabels) %stupid workaround becuse of parfor
                    %fprintf('k= %d ',k);
                    models{k} = svmtrain(double(dataReLabels == k), dataSamples, sprintf('-c %f -g %f -b 1 -q -t 2', x, y));
                end
            end
            fprintf('\n');   
        end
        function [results] =  test(obj, dataSamples, dataLabels, trained_model)
            %[plabels,accuracy,prob_estimates] = svmpredict(double(dataLabels), dataSamples, model, '-b 1 -q');
            myMapper = obj.mapper;
            prob = zeros(size(dataSamples,1),7);
            ddd =unique([obj.LabelsUsedTraining']); % if not used as integers doule is needed around dataLabels
            for k=ddd
                try
                    [~,~,p] = svmpredict(double(dataLabels==k), dataSamples, trained_model{myMapper.ChangeLabelToInteger(k)}, '-b 1 -q');
                    prob(:,myMapper.ChangeLabelToInteger(k)) = p(:,trained_model{myMapper.ChangeLabelToInteger(k)}.Label==1);    %# probability of class==k
                catch err
                    fprintf('exception: %s\n',err.message);
                    fprintf('CAUGHT unique(trainLabel) < unique(testLabel)!!!!\n');
                    fprintf('the value of K is: %d\n', k);
                    fprintf('the unique trainLabel vec: %s \n', mat2str(unique(obj.LabelsUsedTraining)'));
                    fprintf('the unique testLabel vec: %s \n', mat2str(unique(dataLabels)'));
                    prob(:,myMapper.ChangeLabelToInteger(k)) = 0;
                end
            end
            %getting the index of the max value
            [~,results] = max(prob,[],2);
            
            %chancing from index to label
            for i=1:length(results)
                results(i) = myMapper.ChangeIntegerToLabel(results(i));
            end
        end
    end
    
end

