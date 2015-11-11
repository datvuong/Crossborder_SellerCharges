LoadLGS3PL <- function(venture) {
  require(XLConnect)
  
  LGS_3PL_WB <- loadWorkbook(paste0("../../1_Input/DeliveryCompanyList/",venture,".xlsx"))
  LGS_3PL_List <- readWorksheet(sellerWB, sheet = 1)
  
  LGS_3PL_List
}