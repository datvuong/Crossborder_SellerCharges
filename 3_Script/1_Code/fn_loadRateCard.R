loadRateCard <- function(rateCardFile){
    rateCard <- read.csv(rateCardFile,
                         col.names = c("Weight","General_Goods","Sensitive_Goods"),
                         colClasses = c("numeric","numeric","numeric"))
}