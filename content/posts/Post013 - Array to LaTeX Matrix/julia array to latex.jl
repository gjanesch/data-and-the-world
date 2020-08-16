using LinearAlgebra

function array_to_LaTeX(arr)
    matrix_string = "\begin{bmatrix}"
    for row in eachrow(arr)
        row_string = join([string(r) for r in row], " & ")
        matrix_string = string(matrix_string, " ", row_string, " \\")
    end
    matrix_string = string(matrix_string[begin:end-1], "\end{bmatrix}")
    return matrix_string
end

function array_to_LaTeX(arr)
    arr = string.(arr)
    nrow = size(arr)[1]
    rows = [join(arr[row,:], " & ") for row in range(1, 3, step=1)]
    return string("\begin{bmatrix} ", join(rows, " \\ "), " \end{bmatrix}")
end

A = [3 4 5; 6 7 9; 4 5 122]
array_to_LaTeX(A)