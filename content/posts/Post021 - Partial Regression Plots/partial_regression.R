library(faraway)
library(ggplot2)

data(sat)

# partial regression plot
ggplot(data=sat, aes(x=expend, y=total)) + geom_point()

cor(sat$expend, sat$salary)

expend_resid = resid(lm(data=sat, expend ~ ratio + salary + takers))
total_resid = resid(lm(data=sat, total ~ ratio + salary + takers))

cor(expend_resid, total_resid)

ggplot(data=NULL) + geom_point(aes(x=expend_resid, y=total_resid))


# Partial residual plot
model = lm(data=sat, total ~ expend + ratio + salary + takers)
