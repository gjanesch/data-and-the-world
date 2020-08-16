import numpy as np

def array_to_LaTeX(arr):
    arr = arr.astype("str")
    nrow = arr.shape[0]
    rows = [" & ".join(arr[i,:].tolist()) for i in range(nrow)]
    return "\\begin{bmatrix} " + " \\\\ ".join(rows) + " \\end{bmatrix}"

A = np.array([[3,4,5],[6,7,9],[4,5,122]])
print(array_to_LaTeX(A))
