loadOldSellerCharges <- function(oldSellerChargedFolder, omsData){
  require(dplyr, quietly = TRUE)
  require(tools, quietly = TRUE)
  
  
  setClass("myDateTime")
  setAs("character","myDateTime", function(from) as.POSIXct(from, format="%Y-%m-%d %H:%M:%S"))
  
  oldSellerChargedData <- NULL
  for (file in list.files(oldSellerChargedFolder)){
    if(file_ext(file)=="csv"){
      currentFileData <- 
        read.csv(file.path(oldSellerChargedFolder,file),
                 sep = ",", quote = '',
                 col.names = c("SC_SOI_ID","id_sales_order_item","id_transaction",
                               "fk_seller","fk_transaction_type","is_unique",
                               "transaction_source","fk_user","description",
                               "value","taxes_vat","taxes_wht",
                               "ref","ref_date","number",
                               "fk_transaction_statement","created_at","updated_at",
                               "fk_qc_user"),
                 colClasses = c("integer","integer","integer",
                                "integer","integer","character",
                                "factor","integer","character",
                                "numeric","numeric","numeric",
                                "integer","character","character",
                                "character","myDateTime","myDateTime",
                                "integer"))
      if (is.null(oldSellerChargedData))
        oldSellerChargedData <- currentFileData
      else
        oldSellerChargedData <- rbind_list(oldSellerChargedData,currentFileData)
    }
  }
  
  oldSellerChargedData <- filter(oldSellerChargedData, fk_transaction_type==7)
  
  oldSellerChargedData_OMS <- left_join(oldSellerChargedData,
                                        omsData,by="id_sales_order_item")
  
  oldSellerChargedData_OMS %<>% filter(!is.na(bob_id_sales_order_item))
  chargedTrackingNumber <- oldSellerChargedData_OMS$tracking_number
  chargedItem <- 
    filter(omsData, tracking_number %in% chargedTrackingNumber)$id_sales_order_item
  
  chargedItem <- c(chargedItem, oldSellerChargedData$id_sales_order_item)
  uniqueChargedItem <- chargedItem[!duplicated(chargedItem)]
  uniqueChargedItem
}