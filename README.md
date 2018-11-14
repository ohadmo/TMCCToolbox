# TMCCToolbox

**Topological Multi-Class Classifier Toolbox**

### Classification
applyClassification_alldata.m

### Dedekind Cuts Classifier
LinearScaleClassifier.m

### Topological Classification (excluding test data after clustring)
1. KohonenMap.py - perform clustering
2. applyClassificationEachNeuron.m (for k folds)

### Topological Classification (excluding test data before clustring)
1. createDataSet_LeaveOnePatientOut.m  - create from dataset (need to retag 'clean_patient' field randomly, range [1-<number_of_folds>])
2. RunKohonenMap_LeaveOnePatientOut.py - performs clustering
3. applyClassificationEachNeuron_MultipleFolders.m (applyClassificationEachNeuronLeaveOneOut.m)  - perform classification

### Leave One Patient Out Topological Classification
1. createDataSet_LeaveOnePatientOut.m  - create from dataset
2. RunKohonenMap_LeaveOnePatientOut.py - perform clustering
3. applyClassificationEachNeuron_MultipleFolders.m (applyClassificationEachNeuronLeaveOneOut.m) - perform classification
