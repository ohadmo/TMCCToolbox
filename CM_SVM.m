classdef CM_SVM
    properties
        mapper
    end
    methods
        function obj = CM_SVM(dataMapper)
            obj.mapper = dataMapper;
        end
        function model =  train(obj, dataSamples, dataLabels, x, y)
            myMapper = obj.mapper;
            dataLabels = arrayfun(@myMapper.ChangeLabelToInteger, dataLabels); % must be used otherwise throw away double labels
            model = svmtrain(double(dataLabels), dataSamples, sprintf('-c %f -g %f -b 1 -q -t 0', x, y));
        end
        function [plabels,accuracy,prob_estimates] =  test(obj, testSamples, testLabels, model)
            myMapper = obj.mapper;
            testLabels = arrayfun(@myMapper.ChangeLabelToInteger, testLabels);
            [plabels,accuracy,prob_estimates] = svmpredict(double(testLabels), testSamples, model, '-b 1 -q');
            plabels = arrayfun(@myMapper.ChangeIntegerToLabel, plabels);
        end
    end
    
end

