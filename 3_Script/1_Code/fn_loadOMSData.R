loadOMSData <- function(omsDataFolder){
    
    require(dplyr, quietly = TRUE)
    require(tools, quietly = TRUE)
    require(magrittr, quietly = TRUE)
    
    setClass("myDateTime")
    setAs("character","myDateTime", function(from) as.POSIXct(gsub('"','',from), format="%Y-%m-%d %H:%M:%S"))
    setClass("myInteger")
    setAs("character","myInteger", function(from) as.integer(gsub(',','',from)))
    
    omsDataAll <- NULL
    for (file in list.files(omsDataFolder)){
        if(file_ext(file)=="csv"){
            currentFileData <- read.csv(file.path(omsDataFolder,file),
                                        sep = ",", quote = '"',
                                        col.names = c("order_nr","id_sales_order_item","SC_SOI_ID",
                                                      "business_unit","payment_method","sku",
                                                      "description","unit_price","Item_Status",
                                                      "RTS_Date","Shipped_Date","Cancelled_Date",
                                                      "Delivered_Date","tracking_number","package_number",
                                                      "shipment_provider_name","Seller_Code","Seller",
                                                      "tax_class"),
                                        colClasses = c("integer","integer","integer",
                                                       "factor","factor","character",
                                                       "character","numeric","factor",
                                                       "myDateTime","myDateTime","myDateTime",
                                                       "myDateTime","character","character",
                                                       "character","character","character",
                                                       "factor"))
            if (is.null(omsDataAll))
                omsDataAll <- currentFileData
            else
                omsDataAll <- rbind_list(omsDataAll,currentFileData)
        }
    }
    
    omsDataAll %<>%
        mutate(Tracking_number=gsub("^0","",tracking_number)) #remove leading ZERO of tracking number to mapped with Invoice Data
    
    omsDataAll
}