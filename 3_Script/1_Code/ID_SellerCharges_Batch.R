
source("../1_Code/fn_loadInvoiceData.R")
source("../1_Code/fn_loadRateCard.R")
source("../1_Code/fn_loadOMSData.R")
source("../1_Code/fn_loadOldSellerCharges.R")

runningFodlerName <- "20151009"
runningFodler <- file.path("../../1_Input",runningFodlerName)
invoiceFolder <- file.path(runningFodler,"Invoices")

venture <- "Indonesia"
ventureShort <- switch (venture,
                        "Indonesia" = "ID"
)

currencyExchange <- switch (venture,
                        "Indonesia" = 1738.82
)

outputFolder <- file.path("../../2_Output/",runningFodlerName)
if(!dir.exists(outputFolder))
    dir.create(outputFolder)

InvoiceData <- loadInvoiceData(invoiceFolder, runningFodlerName)
RateCard <- loadRateCard(file.path("../../1_Input/Ratecards",paste0(ventureShort,"_Ratecard.csv")))
oldSellerCharge <- loadOldSellerCharges("../../1_Input/SellerCharged")
omsData <- loadOMSData("../../1_Input/OMS_Data")

omsDataUnique <- omsData %>% filter(!duplicated(id_sales_order_item) & !is.na(Shipped_Date) &
                                    tracking_number!="")

mappedData <- left_join(omsDataUnique,InvoiceData,
                        by = c("Tracking_number"))

mappedData %<>%
    group_by(Tracking_number) %>%
    mutate(Weight_kg=Weight_kg/n()) %>%
    ungroup()

skuAverageWeight <- mappedData %>% 
    group_by(Tracking_number) %>%
    mutate(ItemCount=n_distinct(id_sales_order_item)) %>%
    ungroup() %>%
    filter(ItemCount==1, !is.na(Weight_kg)) %>%
    group_by(sku) %>%
    summarize(sku_average_weight=mean(Weight_kg),
              sku_goods_Type=as.character(last(Goods_Type)))

sellerAverageWeight <- mappedData %>%
    group_by(Seller_Code) %>%
    filter(!is.na(Weight_kg)) %>%
    summarize(seller_average_weight=mean(Weight_kg))

country_average_weight <- mean(mappedData$Weight_kg, na.rm = TRUE)

mappedDataWeight <- left_join(mappedData,skuAverageWeight,
                              by="sku")

mappedDataWeight <- left_join(mappedDataWeight, sellerAverageWeight,
                              by="Seller_Code")

mappedDataWeight %<>%
    mutate(Final_Item_Weight=ifelse(!is.na(Weight_kg) & Weight_kg>0,Weight_kg,
                               ifelse(!is.na(sku_average_weight),sku_average_weight,
                                      ifelse(!is.na(seller_average_weight),seller_average_weight,
                                             country_average_weight)))) %>%
    group_by(Tracking_number) %>%
    mutate(Final_Package_Weight=sum(Final_Item_Weight)) %>% ungroup() %>%
    mutate(Final_Package_Weight_Rounded=ifelse(Final_Package_Weight<=2, ceiling(Final_Package_Weight*100)/100,
                                       round((Final_Package_Weight+0.25)/.5)*.5)) %>%
    mutate(Final_Good_Type=ifelse(!is.na(Goods_Type),as.character(Goods_Type),
                                  ifelse(!is.na(sku_goods_Type),as.character(sku_goods_Type),
                                         "GENERAL")))

mappedDataWeightRate <- left_join(mappedDataWeight, RateCard,
                                  by=c("Final_Package_Weight_Rounded"="Weight"))

mappedDataWeightRate %<>%
    group_by(Tracking_number) %>%
    mutate(ItemCount=n(),
           packageValue=sum(unit_price)) %>%
    ungroup() %>%
    mutate(Shipping_Charges=ifelse(Final_Good_Type=="GENERAL",General_Goods,
                                Sensitive_Goods)/ItemCount,
           HighValueCharge=ifelse(packageValue>4400000,0.15*unit_price,0)/currencyExchange) %>%
    mutate(SellerCharges_HKD=Shipping_Charges+HighValueCharge,
           SellerCharges_IDR=SellerCharges_HKD*currencyExchange) %>%
    mutate(Chargeable_Effective_Date=ifelse(is.na(Cancelled_Date),format(Delivered_Date,"%Y-%m-%d"),
                                            format(Cancelled_Date,"%Y-%m-%d")))

newCharged <- mappedDataWeightRate$SC_SOI_ID
sc_Charged <- oldSellerCharge$SC_SOI_ID
chargedTrackingNumber <- filter(mappedDataWeightRate, newCharged %in% sc_Charged)$Tracking_number
tobeCharged <- filter(mappedDataWeightRate, !(Tracking_number %in% chargedTrackingNumber))

FinalData <- tobeCharged %>%
    select(Seller
           ,Seller_Code
           ,SellerCharges_HKD
           ,Tracking_number
           ,package_number
           ,id_sales_order_item
           ,SC_SOI_ID
           ,Chargeable_Weight=Final_Package_Weight_Rounded
           ,Chargeable_Effective_Date) %>%
    mutate(Date=format(Sys.Date(),"%Y-%m-%d"))

write.csv(tobeCharged, file.path(outputFolder, "Tobecharded_Raw.csv"),
          row.names = FALSE)
write.csv(FinalData, file.path(outputFolder, "Final_Data_UploadtoSC.csv"),
          row.names = FALSE)

Deliver_Company_List <- tobeCharged %>% 
    group_by(shipment_provider_name) %>% 
    summarize(ItemCount=n())
write.csv(Deliver_Company_List, file.path(outputFolder, "Deliver_Company_List.csv"),
              row.names=FALSE)
