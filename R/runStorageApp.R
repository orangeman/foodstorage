#' function for loading the storage-app 
#' 
#' @return This function is the only exported function of the foodstorage package. The package was built for analyzing a Food Co-ops' consumption. The results are represented in the shiny 'storage-app' which you can run by this function!
#' 
#'
#' @export
runStorageApp <- function() {
  appDir <- system.file(package = "foodstorage")
  if (appDir == "") {
    stop("Could not find example directory. Try re-installing `foodstorage`.", call. = FALSE)
  }
  
  shiny::runApp(appDir, display.mode = "normal")
}