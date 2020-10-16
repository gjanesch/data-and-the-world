using Distributions
using RDatasets
using Statistics

function TwoSampleT2Test(X,Y)
    nx, p = size(X)
    ny, _ = size(Y)
    δ = mean(X, dims=1) - mean(Y, dims=1)
    Sx = cov(X)
    Sy = cov(Y)
    S_pooled = ((nx-1)*Sx + (ny-1)*Sy)/(nx+ny-2)
    
    t_squared = (nx*ny)/(nx+ny) * δ * inv(S_pooled) * transpose(δ)
    statistic = t_squared[1,1] * (nx+ny-p-1)/(p*(nx+ny-2))

    F = FDist(p, nx+ny-p-1)
    p_value = 1 - cdf(F, statistic)
    println("Test statistic: $(statistic)\nDegrees of freedom: $(p) and $(nx+ny-p-1)\np-value: $(p_value)")
    return([statistic, p_value])
end

iris = dataset("datasets", "iris")
versicolor = convert(Matrix, iris[iris.Species .== "versicolor", 1:2])
virginica = convert(Matrix, iris[iris.Species .== "virginica", 1:2])
TwoSampleT2Test(versicolor, virginica)