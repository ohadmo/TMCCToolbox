import os
import glob
import KohonenMap
import shutil
import multiprocessing as mp
import time
import sys
import itertools

pairPatientsDirPath = 'D:\\GitHub\ParkinsonKohonen\\DatasetLeaveOneOut_BalancedShuffledBigData_LeaveOut20precent\\'
featuresNum = 34
latticeLength = 6
latticeWidth = 6
epochs = 1000

def applyOnOnePatientDir(tupDir):
    sourceDir = tupDir[0]
    outDir = tupDir[1]

    # delete all legacy run results from source dir
    runDirectoriesRes = [os.path.join(sourceDir, name) for name in os.listdir(sourceDir) if os.path.isdir(os.path.join(sourceDir, name))]
    for d in runDirectoriesRes:
        print(d + "  be deleted !!!!!")
        #shutil.rmtree(d)

    # making sure there is only train and test dataset
    if len(os.listdir(sourceDir)) != 2:
        print("Folder " + sourceDir + " contains more than only mat file !!!:(:(:(:(:(:(:(", os.listdir(sourceDir))
        sys.exit(1)

    trainData = glob.glob(os.path.join(sourceDir, "*_Train.mat"))
    testData = glob.glob(os.path.join(sourceDir, "*_Test.mat"))
    if not testData or not trainData:
        print("empty train/test data in: ", sourceDir)

    os.system('python KohonenMap.py -d {} -t {} -n {} -l {} -w {} -e {} -o {}'.format(
                trainData[0], testData[0], featuresNum, latticeLength, latticeWidth, epochs, outDir))
    return tupDir


if __name__ == '__main__':
    outDirName = "LOORun_" + time.strftime("%Y-%m-%d-%H%M%S")
    outDirPath = os.path.join(pairPatientsDirPath, outDirName)
    if not os.path.exists(outDirPath):
        os.makedirs(outDirPath)
    allSourceDirs = [(os.path.join(pairPatientsDirPath, name), os.path.join(pairPatientsDirPath, outDirName, name))
                     for name in os.listdir(pairPatientsDirPath)
                     if os.path.isdir(os.path.join(pairPatientsDirPath, name)) and "ParkinsonSubDataset" in name]
    pool = mp.Pool(processes=26)
    results = pool.map(applyOnOnePatientDir, allSourceDirs)
    print(len(results))
    print(results)