LoadSellerList <- function(venture){
  require(XLConnect)
  
  sellerWB <- loadWorkbook(paste0("../../1_Input/SellerList/",venture,".xlsx"))
  sellerList <- readWorksheet(sellerWB, sheet = 1)
  
  sellerList
}