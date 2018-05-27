import numpy as np
import time
import matplotlib.pyplot as plt
import xlrd
import matplotlib.patches as mpatches



def extract(col_start,row_start,row_finish):
    mtx=[]
    class0 = []
    class1 = []
    class15 = []
    class2 = []
    class25 = []
    class3 = []
    class4 = []
    for i in range(row_start, row_finish):
        class0.append(int(worksheet.cell(i,col_start).value))
        class1.append(int(worksheet.cell(i,col_start+1).value))
        class15.append(int(worksheet.cell(i,col_start+2).value))
        class2.append(int(worksheet.cell(i,col_start+3).value))
        class25.append(int(worksheet.cell(i,col_start+4).value))
        class3.append(int(worksheet.cell(i,col_start+5).value))
        class4.append(int(worksheet.cell(i,col_start+6).value))
    mtx.append(class4)
    mtx.append(class3)
    mtx.append(class25)
    mtx.append(class2)
    mtx.append(class15)
    mtx.append(class1)
    mtx.append(class0)
    return mtx


workbook = xlrd.open_workbook("D:\\GitHub\\ParkinsonKohonen\\runResultOfKohonen_BalancedShuffledBigData.mat_7labels__500epochs_linetopology_ big radius, fixed updating\\2017-03-29-233713\\RUN__BalancedShuffledBigData.mat__1X30_epoch-500_2017-03-29-233713.xlsx")
worksheet = workbook.sheet_by_index(0)

num_of_epochs = 500

def animate():
    N = 30
    delta = 0.14

    X_idx = 3
    Y_idx = 5
    matrix_val = extract(Y_idx,X_idx,X_idx+N)
    submatriX8 = matrix_val.copy()

    rects1 = ax1.bar(np.arange(N), matrix_val.pop(),delta*4, align='center', color='b', alpha=0.8)
    rects2 = ax2.bar(np.arange(N), matrix_val.pop(),delta*4, align='center', color='g', alpha=0.8)
    rects3 = ax3.bar(np.arange(N), matrix_val.pop(),delta*4, align='center', color='r', alpha=0.8)
    rects4 = ax4.bar(np.arange(N), matrix_val.pop(),delta*4, align='center', color='c', alpha=0.8)
    rects5 = ax5.bar(np.arange(N), matrix_val.pop(),delta*4, align='center', color='m', alpha=0.8)
    rects6 = ax6.bar(np.arange(N), matrix_val.pop(),delta*4, align='center', color='y', alpha=0.8)
    rects7 = ax7.bar(np.arange(N), matrix_val.pop(),delta*4, align='center', color='k', alpha=0.8)

    rects81 = ax8.bar(np.arange(N), submatriX8.pop(), delta, align='center', color='b', alpha=0.8)
    rects82 = ax8.bar(np.arange(N) + delta, submatriX8.pop(), delta, align='center', color='g', alpha=0.8)
    rects83 = ax8.bar(np.arange(N) + 2 * delta, submatriX8.pop(), delta, align='center', color='r', alpha=0.8)
    rects84 = ax8.bar(np.arange(N) + 3 * delta, submatriX8.pop(), delta, align='center', color='c', alpha=0.8)
    rects85 = ax8.bar(np.arange(N) + 4 * delta, submatriX8.pop(), delta, align='center', color='m', alpha=0.8)
    rects86 = ax8.bar(np.arange(N) + 5 * delta, submatriX8.pop(), delta, align='center', color='y', alpha=0.8)
    rects87 = ax8.bar(np.arange(N) + 6 * delta, submatriX8.pop(), delta, align='center', color='k', alpha=0.8)

    fig.canvas.draw()
    time.sleep(1)

    for i in range(num_of_epochs+1):
        X_idx += N+3  # TODO

        #print(worksheet.cell(X_idx,5).value)
        matrix_val = extract(Y_idx,X_idx,X_idx+N)
        submatriX8 = matrix_val.copy()
        for rect, h in zip(rects1, matrix_val.pop()):
            rect.set_height(h)
        for rect, h in zip(rects2, matrix_val.pop()):
            rect.set_height(h)
        for rect, h in zip(rects3, matrix_val.pop()):
            rect.set_height(h)
        for rect, h in zip(rects4, matrix_val.pop()):
            rect.set_height(h)
        for rect, h in zip(rects5, matrix_val.pop()):
            rect.set_height(h)
        for rect, h in zip(rects6, matrix_val.pop()):
            rect.set_height(h)
        for rect, h in zip(rects7, matrix_val.pop()):
            rect.set_height(h)
        #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        for rect, h in zip(rects81, submatriX8.pop()):
            rect.set_height(h)
        for rect, h in zip(rects82, submatriX8.pop()):
            rect.set_height(h)
        for rect, h in zip(rects83, submatriX8.pop()):
            rect.set_height(h)
        for rect, h in zip(rects84, submatriX8.pop()):
            rect.set_height(h)
        for rect, h in zip(rects85, submatriX8.pop()):
            rect.set_height(h)
        for rect, h in zip(rects86, submatriX8.pop()):
            rect.set_height(h)
        for rect, h in zip(rects87, submatriX8.pop()):
            rect.set_height(h)

        fig.canvas.draw()
        time.sleep(0.2)

fig, ((ax1, ax2),(ax3, ax4),(ax5, ax6),(ax7,ax8)) = plt.subplots(4,2,sharex=True, sharey=True)
plt.subplots_adjust(wspace=0.05)
#plt.xlabel('Neuron no.')
#plt.ylabel('Samples clustered toward specific neuron')

plt.xticks( np.arange(30))

ax1.set_xlabel("Neuron No.")
ax2.set_xlabel("Neuron No.")
ax3.set_xlabel("Neuron No.")
ax4.set_xlabel("Neuron No.")
ax5.set_xlabel("Neuron No.")
ax6.set_xlabel("Neuron No.")
ax7.set_xlabel("Neuron No.")
ax8.set_xlabel("Neuron No.")
ax5.set_ylabel("Number of Samples Clustered Toward a Neuron")
ax6.set_ylabel("Number of Samples Clustered Toward a Neuron")

win = fig.canvas.manager.window
win.after(500, animate)
mng = plt.get_current_fig_manager()
mng.full_screen_toggle()

# Drawing the legend
labels = ['0', '1', '1.5', '2', '2.5', '3', '4']
patches = [mpatches.Patch(color='b', label='0.0'),
           mpatches.Patch(color='g', label='1.0'),
           mpatches.Patch(color='r', label='1.5'),
           mpatches.Patch(color='c', label='2.0'),
           mpatches.Patch(color='m', label='2.5'),
           mpatches.Patch(color='y', label='3.0'),
           mpatches.Patch(color='k', label='4.0')]
fig.legend(patches, labels, loc="best", ncol=7)

axes = plt.gca()
axes.set_ylim([0,2200])
plt.show()
print("DONE!")


