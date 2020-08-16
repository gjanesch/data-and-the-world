array_to_LaTeX <- function(arr){
    rows <- apply(arr, MARGIN=1, paste, collapse = " & ")
    matrix_string <- paste(rows, collapse = " \\\\ ")
    return(paste("\\begin{bmatrix}", matrix_string, "\\end{bmatrix}"))
}

A <- matrix(c(3,4,5,6,7,9,4,5,122), ncol=3, byrow=TRUE)
cat(array_to_LaTeX(A))
