classdef ClassificationMethods
    %Contains Classification Methods to be used
    properties
        chosenClassifier
    end
    methods
        function obj = ClassificationMethods(methodName, datasetMapper)
            switch methodName
                case 'svm'
                    %disp('svm_OvO was chosen from ClassificationMethods');
                    obj.chosenClassifier = CM_SVM(datasetMapper);
                case 'dt'
                    %disp('decision tree was chosen from ClassificationMethods');
                    obj.chosenClassifier = CM_DecisionTree();
                case 'svm_OvA'
                    %disp('svm_OvA(adapted) was chosen from ClassificationMethods');
                    obj.chosenClassifier = CM_SVM_OvA(datasetMapper);
                otherwise
                    error('NO VALID METHOD WAS CHOSEN');
            end
        end
    end
    
end

