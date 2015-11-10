SaveBatchUploadedFile <- function(outputData, outputFolder){
  batchArray <- seq(1, nrow(outputData), 2000)
  for (i in batchArray) {
    start <- i
    end <- i + 1999
    batch <- outputData[start:end, ]
    write.csv(batch, file.path(outputFolder, 
                                   paste0("Final_Data_UploadtoSC_",start,"_",end,".csv")),
              row.names = FALSE)
  }
}