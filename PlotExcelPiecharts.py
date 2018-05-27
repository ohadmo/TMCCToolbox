import numpy as np
import time
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import xlrd
import matplotlib as mpl

# chnaging the style to the old 1.X matplotlib
#mpl.style.use('classic')
mpl.rcParams['figure.facecolor'] = '0.75'
mpl.rcParams['legend.facecolor'] = '0.90'
#mpl.rcParams['patch.force_edgecolor'] = True
#mpl.rcParams['patch.facecolor'] = 'b'

mpl.rcParams.update({'font.size': 12})

# Severities Samples sizes :
#sevDict = {0: 32338, 1: 15997, 2: 14807, 3:63076, 4:35120, 5:26469, 6:5619}

def extract(col_start,row_start,row_finish):
    mtx = []
    class0 = []
    class1 = []
    class15 = []
    class2 = []
    class25 = []
    class3 = []
    class4 = []
    for idx in range(row_start, row_finish):
        class0.append(int(worksheet.cell(idx, col_start).value))
        class1.append(int(worksheet.cell(idx, col_start+1).value))
        class15.append(int(worksheet.cell(idx, col_start+2).value))
        class2.append(int(worksheet.cell(idx, col_start+3).value))
        class25.append(int(worksheet.cell(idx, col_start+4).value))
        class3.append(int(worksheet.cell(idx, col_start+5).value))
        class4.append(int(worksheet.cell(idx, col_start+6).value))
    mtx.append(class0)
    mtx.append(class1)
    mtx.append(class15)
    mtx.append(class2)
    mtx.append(class25)
    mtx.append(class3)
    mtx.append(class4)
    return mtx

def make_autopct(values):
    def my_autopct(pct):
        total = sum(values)
        val = int(round(pct*total/100.0))
        return '{p:.2f}% \n ({v:d})'.format(p=pct,v=val)
    return my_autopct

def animate():
    X_idx = 3   #first data coordinate
    Y_idx = 5   #first data coordinate
    matrix_val = extract(Y_idx, X_idx, X_idx + N)
    print("first_Value_Epoch", matrix_val[0][0])
    for i in range(ROWS):
        for j in range(COLS):
            values = [x.pop() for x in matrix_val]
            axarr[i, j].pie(values,  colors=colors,
                            autopct=make_autopct(values), pctdistance=2, shadow=False,
                            explode=[0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08],
                            radius=0.20, center=(0, 0), frame=True)
    fig.canvas.draw()
    #time.sleep(60)
    for k in range(num_of_epochs+1): # +1 for last results run
        X_idx += X_idx_add_to_val
        matrix_val = extract(Y_idx, X_idx, X_idx+N)
        print("first_Value_Epoch", matrix_val[0][0])
        for i in range(ROWS):
            for j in range(COLS):
                values = [x.pop() for x in matrix_val]
                axarr[i, j].clear()
                axarr[i, j].axis('off')
                axarr[i, j].pie(values, colors=colors,
                                autopct=make_autopct(values), pctdistance=2.2, shadow=False,
                                explode=[0.05,0.05,0.05,0.05,0.05,0.05,0.05],
                                radius=0.27, center=(0, 0), frame=True)
        fig.canvas.draw()
        print("EPOCH:" + str(k))

#*******************
xlsPath = "D:\\GitHub\\ParkinsonKohonen\\ParkinsonsTrials\\2017-12-10-015759\\RUN__BalancedShuffledBigData.mat__6X6_epoch-1000_2017-12-10-015759.xlsx"
num_of_epochs = 1000
ROWS = 6
COLS = 6
#*******************
workbook = xlrd.open_workbook(xlsPath)
worksheet = workbook.sheet_by_index(0)
N = ROWS*COLS
X_idx_add_to_val = N + 3

fig, axarr = plt.subplots(ROWS,COLS)
fig.tight_layout()
for i in range(ROWS):
    for j in range(COLS):
        axarr[i,j].axis('off')
fig.subplots_adjust(left=0.13,bottom=0.08)
colors = ['green', 'blue', 'yellow', 'red', 'aqua', 'purple', 'orange' ]

win = fig.canvas.manager.window
win.after(200, animate)
mng = plt.get_current_fig_manager()
mng.full_screen_toggle()

# Drawing the legend
labels = ['0', '1', '1.5', '2', '2.5', '3', '4']
patches = [mpatches.Patch(color=colors[0], label='0.0'),
           mpatches.Patch(color=colors[1], label='1.0'),
           mpatches.Patch(color=colors[2], label='1.5'),
           mpatches.Patch(color=colors[3], label='2.0'),
           mpatches.Patch(color=colors[4], label='2.5'),
           mpatches.Patch(color=colors[5], label='3.0'),
           mpatches.Patch(color=colors[6], label='4.0')]
fig.legend(patches, labels, loc = "best", ncol=7)
#fig.tight_layout()
#axes = plt.gca()
#axes.set_ylim([0,3000])
plt.show()



