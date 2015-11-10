LoadCurrencyExchange <- function(venture){
  require(XLConnect)
  
  currencyWB <- loadWorkbook("../../1_Input/Currency_Exchange.xlsx")
  currencyList <- readWorksheet(currencyWB, sheet = 1)
  row.names(currencyList) <- currencyList$Ventures
  ventureCurrency <- currencyList[venture, 2]
}