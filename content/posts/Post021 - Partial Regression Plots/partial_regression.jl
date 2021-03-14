using Cairo
using CSV
using DataFrames
using Fontconfig
using Gadfly
using GLM

sat = CSV.File("sat.csv") |> DataFrame
expend_regression = lm(@formula(expend ~ ratio + salary + takers), sat)
total_regression = lm(@formula(total ~ ratio + salary + takers), sat)

expend_residuals = sat["expend"] - predict(expend_regression, sat)
total_residuals = sat["total"] - predict(total_regression, sat)

residual_df = DataFrame(ExpendResiduals=expend_residuals, TotalResiduals=total_residuals)

p = plot(residual_df, x="ExpendResiduals", y="TotalResiduals", Geom.point, Theme(background_color="white"));
img = PNG("julia.png", 8inch, 5inch)
draw(img, p)