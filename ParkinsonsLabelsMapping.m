classdef ParkinsonsLabelsMapping
    properties
        labelToInteger
        integerToLabel
    end
    methods
        function obj = ParkinsonsLabelsMapping(dataType)
            actualLabels = NaN;
            if strcmp(dataType,'parkinson')
                actualLabels = {0,1,1.5,2,2.5,3,4};
            elseif strcmp(dataType,'whiteWine')
                actualLabels = {3,4,5,6,7,8,9};
            else
                error('invalid datatype: %s in LabelsMapping ctor', dataType);
            end
            obj.labelToInteger = containers.Map(actualLabels, {1,2,3,4,5,6,7});
            obj.integerToLabel = containers.Map({1,2,3,4,5,6,7}, actualLabels);
        end
        function intLabel = ChangeLabelToInteger(obj,label)
            %display(label)
            %display(obj.labelToInteger.keys())
            %display(obj.labelToInteger.values())
            intLabel = obj.labelToInteger(label);
        end
        function Label = ChangeIntegerToLabel(obj, intLabel)
            Label = obj.integerToLabel(intLabel);
        end
    end
    
end