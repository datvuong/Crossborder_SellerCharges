LoadLGS3PL <- function(venture) {
  require(XLConnect)
  
  LGS_3PL_WB <- loadWorkbook(paste0("../../1_Input/DeliveryCompanyList/",venture,".xlsx"))
  LGS_3PL_List <- readWorksheet(LGS_3PL_WB, sheet = 1)
  colnames(LGS_3PL_List) <- c("Company")
  list3PString <- paste(LGS_3PL_List$Company, collapse = "|")
  list3PString
}