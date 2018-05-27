classdef CM_DecisionTree
    %CM_DESITIONTREE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function model =  train(obj, dataSamples, dataLabels)
            model = fitctree(dataSamples,dataLabels);
        end
        function results =  test(obj, dataSamples, ~, model)
            results = predict(model,dataSamples);
        end
    end
    
end

