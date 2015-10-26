loadInvoiceData <- function(invoiceFolder, runningFolder){
    require(dplyr, quietly = TRUE)
    require(tools, quietly = TRUE)
    require(magrittr, quietly = TRUE)
    
    setClass("myDate")
    setAs("character","myDate", function(from) as.POSIXct(substr(from,1,10), format="%Y-%m-%d"))
    
    invoiceData <- NULL
    for (file in list.files(invoiceFolder)){
        if(file_ext(file)=="csv"){
            currentInvoice <- read.csv(file.path(invoiceFolder,file),
                                       sep = ",", quote = '',
                                       col.names = c("MAWB","Invoice_Date","Tracking_number",
                                                     "Shipper_Name","Org","Dest",
                                                     "Weight_kg","Vol_Wgt_kg","TOS",
                                                     "PCS","Amt","Charge_Per_PC",
                                                     "Handling_Surcharges","Net_Amt_HKD","Goods_Type",
                                                     "Postcode","Goods_Currency","Goods_Value"),
                                       colClasses = c("character","myDate","character",
                                                      "character","character","character",
                                                      "numeric","numeric","factor",
                                                      "integer","numeric","numeric",
                                                      "numeric","numeric","factor",
                                                      "character","factor","numeric"))
            currentInvoice %<>%
                mutate(Invoice_File=file)
            if (is.null(invoiceData))
                invoiceData <- currentInvoice
            else
                invoiceData <- rbind_list(invoiceData,currentInvoice)
        }
    }
    
    duplicatedTrackingNumber <- filter(invoiceData, duplicated(Tracking_number))$Tracking_number
    duplicatedInvoiceData <- invoiceData %>%
        filter(Tracking_number %in% duplicatedTrackingNumber) %>%
        arrange(Tracking_number)
    noDuplicated <- filter(invoiceData, !(Tracking_number %in% duplicatedTrackingNumber))
    
    write.csv(duplicatedInvoiceData, file.path("../../2_Output",runningFolder,"duplicatedInvoiceData.csv"),
              row.names = FALSE)
    noDuplicated
}