import os
import xlrd
import xlsxwriter
import glob
import numpy

keys = [0, 1, 2, 3, 4, 5, 6]
values = [0, 1, 1.5, 2, 2.5, 3, 4]
dictionary = dict(zip(keys, values))

sumEachOne = numpy.empty([7, 7, 7])
for i in range(7):
    sumEachOne[i] = numpy.zeros((7, 7))


pairPatientsDirPath = '/home/ohadmosafi/ParkinsonKohonen/DatasetLeaveOneOut_31patients_SVMOvA/'
allDirs = [os.path.join(pairPatientsDirPath, name) for name in os.listdir(pairPatientsDirPath) if os.path.isdir(os.path.join(pairPatientsDirPath, name))]

workbookWrite = xlsxwriter.Workbook(pairPatientsDirPath + "confEachFolder.xlsx")
excel_headers_format = workbookWrite.add_format({'bold': True, 'font_color': 'red', 'align': 'center'})
yellow_format = workbookWrite.add_format({'bold': True, 'bg_color': 'yellow'})

outputSheetByPatient = workbookWrite.add_worksheet("successRateByPatient")
outputSheetByPatient.set_column("A:A", 23)
outputSheetByPatient.set_column("B:B", 12)
outputSheetByPatient.set_column("C:C", 16)
sheetRow = 0

outputSheetByPatient.write(sheetRow, 0, "Folder Name", excel_headers_format)
outputSheetByPatient.write(sheetRow, 1, "PD Severity", excel_headers_format)
outputSheetByPatient.write(sheetRow, 2, "Success Rate", excel_headers_format)
sheetRow += 1


SheetConfMatAll = workbookWrite.add_worksheet("ConfMatrixDisplayAll")
SheetConfMatAll.set_column("K:K",23)
Row2 = 0

for dir in allDirs:
    runDirectoriesRes = [os.path.join(dir, name) for name in os.listdir(dir) if os.path.isdir(os.path.join(dir, name))]

    #only dataset and result
    if len(os.listdir(dir)) != 3:
        print("Folder " + dir + " contains more than only mat file and result !!!***************", os.listdir(dir))

    for d in runDirectoriesRes:
        print(d)
        #path = 'D:\GitHub\ParkinsonKohonen\DatasetEachTwoPatients\PairParkinsonDataset_10_25\\2016-07-30-171319'
        file = glob.glob(os.path.join(d, "EachClusterClassification*"))
        if len(file) != 1:
            print("more than one run of EachClusterCLassifiaction in " + d)

        Only_dir_name = d.split(os.sep)
        outputSheetByPatient.write(sheetRow, 0, Only_dir_name[-2])  # Patient Name
        if not file:
            print("No file to parse!!!!!!!!!!!!!!!!!!! ", d)
        else:

            workbook = xlrd.open_workbook(file.pop())
            worksheet = workbook.sheet_by_name('ConfussionMatrixAllClusters')

            outputSheetByPatient.write(sheetRow, 2, worksheet.cell(0, 11).value)  # Patient success rate
            SheetConfMatAll.write(Row2, 10, Only_dir_name[-2], yellow_format)

            confMat = numpy.zeros((7, 7))
            i_append = 2
            j_append = 2
            for i in range(7):
                for j in range(7):
                    confMat[i, j] = int(worksheet.cell(i+i_append, j+j_append).value)
            #print(confMat)
            idx = numpy.matrix(confMat).sum(axis=1)
            #print(idx)
            idx = numpy.nonzero(idx)
            #print(idx)
            if len(idx[0]) != 1:
                print("error finding 1 class")
            print("severity of the patient: ", idx[0][0])
            outputSheetByPatient.write(sheetRow, 1, dictionary.get(idx[0][0]))  # Patient PD Severity
            sumEachOne[idx[0][0]] += confMat

            SheetConfMatAll.write(Row2, 5, "Predicted")
            SheetConfMatAll.write(Row2+5, 0, "Actual")
            Row2 += 1
            for i in range(7):
                SheetConfMatAll.write(Row2+i+1, 1, str(dictionary.get(i)), excel_headers_format)    # actual labels
                SheetConfMatAll.write(Row2, i+2, str(dictionary.get(i)), excel_headers_format)      # predicted labels
            Row2 += 1

            for i in range(7):
                for j in range(7):
                    SheetConfMatAll.write(Row2, j+2, confMat[i][j])
                Row2 += 1
            Row2 += 2

        sheetRow += 1

outputFileWrite = workbookWrite.add_worksheet("ConfMatrixBySeverity")
outputFileWrite.set_column("A:A", 15)
outputFileWrite.set_column("L:M", 15)
excel_row = 0


for i in range(7):
    outputFileWrite.write(excel_row, 0, "Severity_" + str(dictionary.get(i)), yellow_format); excel_row += 1
    outputFileWrite.write(excel_row, 3, "Predicted"); excel_row += 1
    outputFileWrite.write(excel_row+3, 0, "Actual")

    outputFileWrite.write(excel_row, 11, "Success Rate")
    #print('11', sumEachOne[i])
    #print('22', numpy.sum(sumEachOne[i]))
    try:
        outputFileWrite.write(excel_row, 12, numpy.trace(sumEachOne[i])/numpy.sum(sumEachOne[i]))  # success rate
    except Exception as e:
        outputFileWrite.write(excel_row, 12, 0)  # success rate

    outputFileWrite.write(excel_row+1, 11, "Matrix Sum")
    outputFileWrite.write(excel_row+1, 12, numpy.sum(sumEachOne[i]))

    for p in range(7):
        outputFileWrite.write(excel_row + 1 + p, 1, str(dictionary.get(p)), excel_headers_format)  #  actual labels
        outputFileWrite.write(excel_row, p+2, str(dictionary.get(p)), excel_headers_format)       #  predicted labels
    excel_row += 1

    for k in range(7):
        for w in range(7):
            outputFileWrite.write(excel_row, w+2, sumEachOne[i][k][w])
        excel_row += 1
    excel_row += 2

workbookWrite.close()

