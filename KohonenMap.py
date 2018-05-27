import numpy as np
import math
import os
from Neuron import Neuron
import random
import scipy.io
import time
import xlsxwriter
import argparse

class KohonenMap:
    def __init__(self, dimensions, length, width, filename, testData, outFile, numEpochs):
        self.dimensions = dimensions   #data dim
        self.length = length
        self.width = width
        self.nMap = []
        self.numOfEpochs = numEpochs

        self.data_filename = filename
        self.data_test_file = testData

        # Train
        self.labels = {}
        self.dict_data = {}
        self.patients_data = {}
        self.patients_data_unique = None
        # Test
        self.test_labels = {}
        self.test_data = {}
        self.test_patients = {}

        self.labels_train_test_unique = None

        # Decreases
        self.m_iNumIterations = None

        # Creating output Excel workbook + formats
        self.workbook = xlsxwriter.Workbook(str(outFile) + ".xlsx")
        self.excel_headers_format = self.workbook.add_format({'bold': True, 'font_color': 'red', 'align': 'center'})
        self.excel_numbers_format = self.workbook.add_format({'bold': True, 'align': 'center'})
        # Adding Class Distribution Worksheet
        self.outputFile = self.workbook.add_worksheet("Classes")
        self.outputFile.set_column('A:A', 13)
        self.outputFile.set_column('B:B', 17)
        self.outputFile.set_column('C:C', 13)
        self.outputFile.set_column('E:E', 23)
        self.excel_row = 0
        # Adding Patient Distribution Worksheet
        self.outputPatientSheet = self.workbook.add_worksheet("Patients")
        self.excel_patient_row = 0
        # StartTime for class Distribution Worksheet
        self.outputFile.write(self.excel_row, 0, "START_TIME")
        self.outputFile.write(self.excel_row, 1, time.strftime("%Y-%m-%d-%H%M%S"))
        self.excel_row += 1

        self.m_iIterationCount = 0
        #self.labels_distributions = {"0.0": 0, "1.0": 0, "1.5": 0, "2.0": 0, "2.5": 0, "3.0": 0, "4.0": 0}

        #temporary shit
        self.CurrentRadius = None
        self.rememberUpdates = 0

    def initialise(self):
        # Setting the Values
        Neuron.dimensions = self.dimensions
        Neuron.length = self.length
        Neuron.width = self.width
        # Initialising Neuron Weights
        for i in range(self.length):
            innerlist = []
            for j in range(self.width):
                temp = Neuron(i, j)
                temp.weights = np.asarray([random.uniform(0,1) for i in range(self.dimensions)], dtype=np.float64)
                innerlist.append(temp)
            self.nMap.append(innerlist)

    def read_data(self):
        # Reading Test Data
        if self.data_test_file is not None:
            matTest = scipy.io.loadmat(self.data_test_file)
            for idx, sample in enumerate(matTest['testDataPair']):
                self.test_data.update({idx:sample})
            for idx, sample in enumerate(matTest['testLabelsPair']):
                self.test_labels.update({idx:sample[0]})
            for idx, sample in enumerate(matTest['testPatientPair']):
                self.test_patients.update({idx:sample[0]})
            trainDataName = 'trainDataPair'
            trainLabelsName = 'trainLabelsPair'
            trainPatientName = 'trainPatientPair'
        else:
            trainDataName = 'clean_data'
            trainLabelsName = 'clean_label'
            trainPatientName = 'clean_patient'

        # Reading Train Data
        mat = scipy.io.loadmat(self.data_filename)
        for idx, sample in enumerate(mat[trainDataName]):
            self.dict_data.update({idx: sample})
        for idx, sample in enumerate(mat[trainLabelsName]):
            self.labels.update({idx: sample[0]})
        for idx, sample in enumerate(mat[trainPatientName]):
            self.patients_data.update({idx: sample[0]})

        # Setting  Iterations Variables
        self.m_iNumIterations = len(self.labels) * self.numOfEpochs
        Neuron.iterations_constant = self.m_iNumIterations
        self.patients_data_unique = np.unique([v for v in self.patients_data.values()])

        temp = np.unique([v for v in (list(self.labels.values()) + list(self.test_labels.values()))])
        self.labels_train_test_unique= [str(float(x))for x in temp]
        print(self.labels_train_test_unique)
        pass
        #self.labels_distributions[str(sample[0])] += 1
        #self.labels_distributions.update((x, y/len(self.labels)) for x, y in self.labels_distributions.items())

    def normaliseValues(self):
        for j in range(self.dimensions):
            sumc = 0
            for k in self.dict_data.keys():
                sumc += float(self.dict_data[k][j])
            for k in self.test_data.keys():
                sumc += float(self.test_data[k][j])
            avg = float(sumc)/(len(self.dict_data)+ len(self.test_data))
            std = 0
            for k in self.dict_data.keys():
                std += math.pow(self.dict_data[k][j] - avg, 2)
            for k in self.test_data.keys():
                std += math.pow(self.test_data[k][j] - avg,2)
            std = math.sqrt(std/(len(self.dict_data) + len(self.test_data)))

            for k in self.dict_data.keys():
                self.dict_data[k][j] = (self.dict_data[k][j] - avg)/std
            for k in self.test_data.keys():
                self.test_data[k][j] = (self.test_data[k][j] - avg)/std #!!!

    def printLatticeClassDistributionToExcel(self):
        # Output class Header to file
        for k,v in zip(list(range(4,4+len(self.labels_train_test_unique)+1)), ["Class Labels"] + self.labels_train_test_unique):
            self.outputFile.write(self.excel_row, k, v, self.excel_headers_format)
        self.excel_row += 1
        for i in range(self.length):
            for j in range(self.width):
                # Output Values to Console
                #print("X:", self.nMap[i][j].X, "Y:", self.nMap[i][j].Y, "classes(1-4)", self.nMap[i][j].countLabels)
                # Output Values to File
                self.outputFile.write(self.excel_row, 0, "x coordinate:")
                self.outputFile.write(self.excel_row, 1, self.nMap[i][j].X, self.excel_numbers_format)
                self.outputFile.write(self.excel_row, 2, "y coordinate:")
                self.outputFile.write(self.excel_row, 3, self.nMap[i][j].Y, self.excel_numbers_format)
                self.outputFile.write(self.excel_row, 4, "classification distribution")
                for k,v in zip(list(range(5,5+len(self.labels_train_test_unique))), self.labels_train_test_unique):
                    self.outputFile.write(self.excel_row, k, self.nMap[i][j].countLabels[v])
                self.excel_row += 1
        self.excel_row += 1

    def printLatticePatientDistributionToExcel(self):
        for i in range(self.length):
            for j in range(self.width):
                for k,v in {0:"X:", 1:self.nMap[i][j].X, 2:"Y:", 3:self.nMap[i][j].Y}.items():
                    self.outputPatientSheet.write(self.excel_patient_row, k, v, self.excel_headers_format)
                for p in range(len(self.patients_data_unique)):
                    self.outputPatientSheet.write(self.excel_patient_row + 1, p,
                                                  "Ptnt_" + str(self.patients_data_unique[p]))
                    self.outputPatientSheet.write(self.excel_patient_row + 2, p,
                                                  self.nMap[i][j].countPatient[self.patients_data_unique[p]])
                self.excel_patient_row += 3

    def printFirstDist(self):
        for i in range(self.length):
            for j in range(self.width):
                self.nMap[i][j].resetCountLabels(self.labels_train_test_unique)
                self.nMap[i][j].resetCountPatient(self.patients_data_unique)
        for k in self.dict_data.keys():
            n = self.getBestMatchingUnit(self.dict_data[k])
            #n = self.findBmu(self.dict_data[k])
            real_class = float(self.labels[k])
            n.countLabels[str(real_class)] += 1
            n.countPatient[self.patients_data[k]] += 1
        #Output fist line for Class dist excl file
        self.outputFile.write(self.excel_row, 0, "First(init)Dist")
        self.excel_row += 1
        self.printLatticeClassDistributionToExcel()
        # Output patients Header worksheet
        self.outputPatientSheet.write(self.excel_patient_row, 0, "First dist", self.excel_headers_format)
        self.excel_patient_row += 1
        self.printLatticePatientDistributionToExcel()


    def trainMap(self, maxError):
        currentError = float("inf")
        #while currentError  > maxError:
        print ("number of iterations that will be performed: ", self.m_iNumIterations)
        while self.m_iNumIterations > 0:
            #labels_dist = {"0.0": 0, "1.0": 0, "1.5": 0, "2.0": 0, "2.5": 0, "3.0": 0, "4.0": 0}
            currentError = 0
            trainingSet = []
            trainingLabels = []
            trainingPatients = []
            self.rememberUpdates = 0 ## to delete !
            self.flag1 = False
            for i in range(self.length):            ##for findBMU
                for j in range(self.width):
                    self.nMap[i][j].samples_counter = 0
                    self.nMap[i][j].resetCountLabels(self.labels_train_test_unique)
                    self.nMap[i][j].resetCountPatient(self.patients_data_unique) #for patient distribution
            for k in self.dict_data.keys():
                trainingSet.append((self.dict_data[k]))
                trainingLabels.append(self.labels[k])
                trainingPatients.append(self.patients_data[k])
            for i in range(len(self.dict_data)):
                #print("trinig idx:" ,i)
                rnd_idx = random.randint(0, len(self.dict_data)-i-1)
                p1 = trainingSet[rnd_idx]
                p1_label = trainingLabels[rnd_idx]
                p1_patient = trainingPatients[rnd_idx]
                #labels_dist[str(p1_label)] += 1
                currentError = currentError + self.trainOne(p1, p1_label, p1_patient)    # Calling trainOne
                del trainingSet[rnd_idx]
                #trainingSet.pop(rnd_idx)
                del trainingPatients[rnd_idx]
                del trainingLabels[rnd_idx]
            print("number of updates performed is", self.rememberUpdates , "")

            # Output Header to Console
            print("average delta:::" + str(currentError) + " epoch:::" + str(self.m_iIterationCount/(len(self.labels) * self.numOfEpochs)) +
                  " time" + time.strftime("%Y-%m-%d-%H%M%S") + " NeighbourRadius:" + str(self.CurrentRadius)+ "\n")
            # Output Epoch Header to file
            for k, v in {0:"Avg Delta", 1:currentError,
                         2:"Iteration", 3:self.m_iIterationCount,
                         4:"percentage", 5:self.m_iIterationCount/(len(self.labels) * self.numOfEpochs),
                         6:"Time", 7:time.strftime("%Y-%m-%d-%H%M%S"),
                         8:"Neighbour Radius:", 9:self.CurrentRadius}.items():
                self.outputFile.write(self.excel_row, k, v)
                self.outputPatientSheet.write(self.excel_patient_row, k, v, self.excel_headers_format)
            self.excel_patient_row += 1
            self.excel_row += 1
            self.printLatticeClassDistributionToExcel()
            self.printLatticePatientDistributionToExcel()

    def trainOne(self, pattern, pattern_label, pattern_patient):
        err = 0
        # BMU
        #bmu = self.findBmu(pattern)
        bmu = self.getBestMatchingUnit(pattern)
        # Incrementing the total  # of samples in this neuron (used in findBmu)
        bmu.samples_counter += 1
        # Incrementing the Specific Disease Severity
        bmu.countLabels[str(float(pattern_label))] += 1
        # Incrementing the Spesific Patient Counter
        bmu.countPatient[pattern_patient] += 1
        # Updating Lattice Process
        for i in range(self.length):
            for j in range(self.width):
                err += self.nMap[i][j].UpdateNeuronWeight_newSecond(pattern, bmu, self.m_iNumIterations, self.m_iIterationCount, self)
        self.m_iNumIterations -= 1
        self.m_iIterationCount += 1
        return abs(err/(self.length * self.width))

    def findBmu(self, v):
        tmp_list = []
        for i in range(self.length):
            for j in range(self.width):
                tmp_list.append(self.nMap[i][j])
        while len(tmp_list) != 0:
            minDistance = float("inf")
            for neuron in tmp_list:
                diff = np.subtract(v, neuron.weights)
                diff_squared = np.sum(np.power(diff, 2))
                dist = np.sqrt(diff_squared)
                if dist <= minDistance:
                    minDistance = dist
                    chosen = neuron
            potential_bmu = tmp_list.pop(tmp_list.index(chosen))
            if ((potential_bmu.samples_counter / (self.m_iIterationCount % len(self.dict_data) +1)) <=
                        1/(self.width*self.length)):
                return potential_bmu
        raise Exception("No BMU was found")

          
    def getBestMatchingUnit(self, vector):
        minDistance = float("inf")
        for i in range(self.length):
            for j in range(self.width):
                diff = np.subtract(vector, self.nMap[i][j].weights)
                diff_squared = np.sum(np.power(diff, 2))
                dist = np.sqrt(diff_squared)
                if (dist < minDistance):
                    minDistance = dist
                    chosen = self.nMap[i][j]
        return chosen

    def Results(self):
        for i in range(self.length):        #for findBMU
                for j in range(self.width):
                    self.nMap[i][j].samples_counter = 0
                    self.nMap[i][j].resetCountLabels(self.labels_train_test_unique)
                    self.nMap[i][j].resetCountPatient(self.patients_data_unique)  # for patient distribution
        for k in self.dict_data.keys():
            n = self.getBestMatchingUnit(self.dict_data[k])
            #n = self.findBmu(self.dict_data[k])
            n.samples_counter += 1           #for findBMU
            self.m_iIterationCount += 1     #for findBMU
            real_class = self.labels[k]
            n.countLabels[str(float(real_class))] += 1
            n.countPatient[self.patients_data[k]] += 1
            n.resClass.append(self.dict_data[k])
            n.resLabel.append(real_class)
            n.resPatient.append(self.patients_data[k])
        # Output Class dist Header worksheet
        self.outputFile.write(self.excel_row, 0, "Results Dist")
        self.excel_row += 1
        self.printLatticeClassDistributionToExcel()
        # Output patients Header worksheet
        self.outputPatientSheet.write(self.excel_patient_row, 0, "Results:", self.excel_headers_format)
        self.excel_patient_row += 1
        self.printLatticePatientDistributionToExcel()

    def resusltsTestData(self):
        for k in self.test_data.keys():
            bmu = self.getBestMatchingUnit(self.test_data[k])
            bmu.resTestClass.append(self.test_data[k])
            bmu.resTestLabel.append(self.test_labels[k])
            bmu.resTestPatient.append(self.test_patients[k])

    def closeExcel(self,dPath):
        self.outputFile.write(self.excel_row, 0, "END_TIME")
        self.outputFile.write(self.excel_row, 1, time.strftime("%Y-%m-%d-%H%M%S"))
        self.workbook.close()

        for i in range(self.length):
            for j in range(self.width):
                c = np.asarray(self.nMap[i][j].resClass)
                l = np.asarray(self.nMap[i][j].resLabel)
                p = np.asarray(self.nMap[i][j].resPatient)
                scipy.io.savemat(os.path.join(dPath, 'neuron_' + str(i) + 'X' + str(j) + '.mat'), dict(nClass=c, nLabel=l, nPatient=p))
                if self.data_test_file is not None:
                    ct = np.asarray(self.nMap[i][j].resTestClass)
                    lt = np.asarray(self.nMap[i][j].resTestLabel)
                    pt = np.asarray(self.nMap[i][j].resTestPatient)
                    scipy.io.savemat(os.path.join(dPath, 'neuron_TESTDATA' + str(i) + 'X' + str(j) + '.mat'), dict(nClass=ct, nLabel=lt, nPatient=pt))


def main():
    parser = argparse.ArgumentParser(description='This is KohonenMap script')
    parser.add_argument('-d', '--datafile', help='Data File', required=True)
    parser.add_argument('-t', '--testfile', help='test data', required=False)
    parser.add_argument('-n', '--nfeature', nargs=1, type=int, help='Number of Features', required=True)
    parser.add_argument('-l', '--length', nargs=1, type=int, help='SOM Length', required=True)
    parser.add_argument('-w', '--width', nargs=1, type=int,  help='SOM Width', required=True)
    parser.add_argument('-e', '--epochs', nargs=1, type=int, help='Number of Epochs', required=True)
    parser.add_argument('-o', '--outfolder', help='Number of Epochs', required=True)
    args = parser.parse_args()
    print(args)

    data_filename = args.datafile  # "shuffled_parkinson_data.mat"
    test_data = args.testfile
    number_of_features = args.nfeature.pop()    # 34
    length = args.length.pop()                  # 2 # change trainOne and getBMU !
    width = args.width.pop()                    # 2 # change trainOne and getBMU !
    epochs = args.epochs.pop()                  # 150
    #iterations_number = epochs * 193426

    onlyFileName = data_filename.split(os.sep)[-1]  #split by os separator
    print("the file name is:", onlyFileName)
    fileTime = time.strftime("%Y-%m-%d-%H%M%S")

    dirPath = os.path.join(args.outfolder, fileTime)
    if not os.path.exists(dirPath):
        print("creating folder:", dirPath)
        os.makedirs(dirPath)
    outputFile = os.path.join(dirPath,"RUN__" + onlyFileName + "__" + str(length) + "X" + str(width) + "_epoch-" + str(epochs) + "_" + fileTime)
    n1 = KohonenMap(number_of_features, length, width, data_filename, test_data, outputFile, epochs)

    print("*****start initialise*****" + time.strftime("%Y-%m-%d-%H%M%S"))
    n1.initialise()
    print("*****initialise is done. loading the data*****" + time.strftime("%Y-%m-%d-%H%M%S"))
    n1.read_data()
    print("*****read data is done. normalising values*****" + time.strftime("%Y-%m-%d-%H%M%S"))
    n1.normaliseValues()

    print("*****normalisation is done, training*****" + time.strftime("%Y-%m-%d-%H%M%S"))
    n1.printFirstDist()
    n1.trainMap(1)
    print("*****results*****" + time.strftime("%Y-%m-%d-%H%M%S"))
    n1.Results()
    if test_data is not None:
        n1.resusltsTestData()
    n1.closeExcel(dirPath)

if __name__ == '__main__':
    main()

