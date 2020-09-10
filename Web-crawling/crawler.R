## --------------------------- General info ----------------------
##
## Script name: Shiny Foody
##
## Purpose of script: Crawl data from the web and create a shiny app for location selection
##
## Author: Hieu Tran
##
## Date Created: 2020-09-10
##
## Email: minhhieutran2112@gmail.com
##
## ---------------------------
##
## Notes:
##   
## ---------------------------

## --------------------------- Preparation ------------------------
rm(list = ls())
options(java.parameters = "-Xmx4g")
## load up and install the packages we will need:

# create a vector of packages that you will be using
packages <- c('tidyverse', 'rvest', 'RSelenium', 'stringr', 'leaflet', 'ggmap', 'magrittr', 'sp')

# create a vector of installed packages
installed_packages <- as.vector(installed.packages()[,c(1)])

# install missing packages
missing_packages <- setdiff(packages, installed_packages)

if (length(missing_packages) > 0) {
  install.packages(setdiff(packages, installed_packages))
}

# load packages
invisible(lapply(packages, library, character.only = TRUE))

## --------------------------- Fueling up ---------------------  

rD <- rsDriver(browser = 'firefox')
remDr <- rD$client

## function
myswitch <- function (remDr, windowId) {
  qpath <- sprintf('%s/session/%s/window', remDr$serverURL,
                   remDr$sessionInfo[['id']])
  remDr$queryRD(qpath, 'POST', qdata = list(handle = windowId))
}

get_html_text <- function(page_source, xpath, index=1) {
  # get text by xpath
  text <- (page_source %>% 
             html_nodes(xpath = xpath) %>% 
             html_text())[index]
  
  # if no text is extracted, return empty string, otherwise return that text
  if (identical(text, character(0))) {
    return('')
  } else {
    return(text)
  }
}

get_general_info <- function(page_source) {
  info <- tibble(
    title = get_html_text(page_source, "//div[@class = 'main-info-title']//h1"),
    category = get_html_text(page_source, "//div[@class = 'category-items']//a[@title]"),
    cuisine_type = get_html_text(page_source, "//div[@class = 'cuisines-list']//a/text()"),
    customer_type = get_html_text(page_source, "//div[@class = 'audiences']/text()"),
    avg_score = get_html_text(page_source, "//div[@class = 'microsite-point-avg ']"),
    location = get_html_text(page_source, "//div[@class = 'microsite-top-points']//span", 1),
    price = get_html_text(page_source, "//div[@class = 'microsite-top-points']//span", 2),
    quality = get_html_text(page_source, "//div[@class = 'microsite-top-points']//span", 3),
    space = get_html_text(page_source, "//div[@class = 'microsite-top-points']//span", 4),
    service = get_html_text(page_source, "//div[@class = 'microsite-top-points']//span", 5),
    comment_count = get_html_text(page_source, "//div[@class = 'microsite-review-count']"),
    address = get_html_text(page_source, "//div[@class = 'res-common-add']//span//a//span[@itemprop = 'streetAddress']"),
    district = get_html_text(page_source, "//span[@itemprop = 'addressLocality']"),
    price_range = get_html_text(page_source, "//span[@itemprop = 'priceRange']/span"),
    time = get_html_text(page_source, "//div[@class = 'micro-timesopen']//span[3]"),
    area = get_html_text(page_source, "//a[@itemprop = 'item']//span[@itemprop = 'name']")
  )
  
  return(info)
}

## variable
page_source <- list()
multiple_branches <- list()
single_branches <- list()
shop_name <- list()
click_field <- list()
currWindow <- list()
general_info <- list()
windows <- list()
otherWindow <- list()
intermediate_handle <- list()
windows1 <- list()
otherWindow1 <- list()
windows2 <- list()
otherWindow2 <- list()
general_info_2 <- list()
a <- 1
e <- 1
click_field_branches <- list()

##
for (page_num in 1:84) {
  
  ## navigate to each pages
  remDr$navigate(paste0("https://www.foody.vn/ha-noi/cafe?ds=Restaurant&vt=row&st=1&c=2&page=", page_num, "&provinceId=218&categoryId=2&append=true"))
  
  ## get page's source_code (including all html code)
  page_source[[page_num]] <- remDr$getPageSource()
  
  ## get name of the restaurants
  read_html(page_source[[page_num]][[1]]) %>% 
    html_nodes(css = "h2") %>% 
    html_text() %>% 
    str_remove('^([[:space:]]+)') %>% # trim spaces at the beginning
    str_remove('([[:space:]]+)$') %>% # trim spaces at the end
    str_replace_all('[\n\r]','') -> shop_name[[page_num]] 
  
  ## get index of multiple branches restaurants
  which(str_detect(shop_name[[page_num]], 'Hệ thống')) -> multiple_branches[[page_num]]
  
  ## get index of single branches restaurants
  which(str_detect(shop_name[[page_num]], 'Hệ thống', negate = TRUE)) -> single_branches[[page_num]]
  
  ## pick the element to click to get to the page of that specific restaurant
  remDr$findElements(using = "xpath", "//h2/a") -> click_field[[page_num]] 
  
  ## get handle of the 'mother' page (which include many restaurants), use to get back to the mother page later
  currWindow[[page_num]] <- remDr$getCurrentWindowHandle()[[1]] 
  
  ## ---------------- for restaurant with multiple branches ------------------
  for(i in multiple_branches[[page_num]]) { 
    
    ## click link
    click_field[[page_num]][[i]]$clickElement()

    ## get handle
    windows[[i]] <- remDr$getWindowHandles() # get all windows handle
    otherWindow[[i]] <- windows[[i]][!windows[[i]] %in% currWindow[[page_num]]][[1]] # other handle apart from current 'mother' one
    
    ## switch to other window
    myswitch(remDr, otherWindow[[i]][[1]])  
    
    ## ------ click to a branch then get information about that branch -----
    
    ## get into a branch
    remDr$findElements(using = "xpath", "//h2/a") -> click_field_branches[[i]] 
    
    ## get the handle of the intermediate page (to get back later)
    intermediate_handle[[i]] <- remDr$getCurrentWindowHandle()[[1]] 
    
    ## loop to get information about each branch
    for(j in 1:length(click_field_branches[[i]])) {
      
      ## click link
      click_field_branches[[i]][[j]]$clickElement()

      ## get handle
      windows1[[j]] <- remDr$getWindowHandles() # get all windows handle
      otherWindow1[[j]] <- windows1[[j]][!windows1[[j]] %in% c(windows1[[j]][[1]], windows1[[j]][[2]])] # other handle apart from current 'mother' and 'intermediate' one
      
      ## switch to other window
      myswitch(remDr, otherWindow1[[j]][[1]])
      
      ## extract info of that branch
      page_source1 <- read_html((remDr$getPageSource())[[1]])
      
      general_info[[a]] <- get_general_info(page_source1)

      ## close the tab for that branch and switch to the intermediate tab
      remDr$closeWindow()
      remDr$switchToWindow(intermediate_handle[[i]][[1]])

      a <- a + 1
      
    }
    
    ## close intermediate tab and switch to mother page
    remDr$closeWindow()
    remDr$switchToWindow(currWindow[[page_num]])
  }
  
  ## ---------------- for restaurant with single branches ------------------
  
  for(g in single_branches[[page_num]]) {
    
    ## click link
    click_field[[page_num]][[g]]$clickElement()

    ## get handle
    windows2[[g]] <- remDr$getWindowHandles() # get all windows handle
    otherWindow2[[g]] <- windows2[[g]][!windows2[[g]] %in% currWindow[[page_num]]][[1]] # other handle apart from current 'mother' one
    
    ## switch to other window
    myswitch(remDr, otherWindow2[[g]][[1]])
    
    ## extract info of that branch
    page_source2 <- read_html((remDr$getPageSource())[[1]])

    general_info_2[[e]] <- get_general_info(page_source2)
    
    e <- e + 1
    
    ## close tab for that restaurant and switch to mother page
    remDr$closeWindow()
    remDr$switchToWindow(currWindow[[page_num]])
  }
}

##################################

do.call(rbind.data.frame, general_info) -> final_multiple_branches
do.call(rbind.data.frame, general_info_2) -> final_single_branch

################################### process location
loca_process <- function(location_x) {
  location_x %>%
    mutate_all(function(x) str_replace_all(x, '^((\\s+)(\"*)|(\"*))(.+)((\\s+)(\"*)|(\\s+))$', '\\5')) %>%
    mutate_all(function(x) str_replace_all(x, '^-\\s+', '')) %>%
    mutate_all(function(x) str_replace_all(x, '\\s+$|^\\s+', '')) %>%
    unite('address', address, district, sep = ', ') %>%
    separate(price_range, c('lower_price', 'upper_price'), sep = ' - ') %>%
    separate(time, c('time1', 'time2'), sep = ' \\| ') %>%
    separate(time1, c('open_1', 'close_1'), sep = ' - ') %>%
    separate(time2, c('open_2', 'close_2'), sep = ' _ ') %>%
    mutate_at(vars('lower_price', 'upper_price'), function(x) str_replace_all(x, '\\.|Ä|click_field_branches', '')) %>%
    mutate_at(vars('lower_price', 'upper_price'), function(x) str_sub(x, end = -2)) %>%
    mutate_at(vars('avg_score', 'location', 'quality', 'space', 'service', 'comment_count', 'lower_price', 'upper_price'), as.double)
}

loca_process(final_single_branch) -> final_single_branch
loca_process(final_multiple_branches) -> final_multiple_branches

#################### maps
# function
getGeoDetails <- function(address){   
  #use the gecode function to query google servers
  geo_reply = geocode(address, output='all', messaging=TRUE, override_limit=TRUE)
  #now extract the bits that we need from the returned list
  answer <- data.frame(lat=NA, long=NA, accuracy=NA, formatted_address=NA, address_type=NA, status=NA, original_address = NA)
  answer$status <- geo_reply$status
  #if we are over the query limit - want to pause for an hour
  while(ifelse(is_null(geo_reply$status), '', geo_reply$status) == "OVER_QUERY_LIMIT"){
    print("OVER QUERY LIMIT - Pausing for 1 hour at:") 
    time <- Sys.time()
    print(as.character(time))
    Sys.sleep(60*60)
    geo_reply = geocode(address, output='all', messaging=TRUE, override_limit=TRUE)
    answer$status <- geo_reply$status
  }
  #return Na's if we didn't get a match:
  if (ifelse(is_null(geo_reply$status), '', geo_reply$status) != "OK"){
    return(answer)
  }   
  #else, extract what we need from the Google server reply into a dataframe:
  answer$lat <- geo_reply$results[[1]]$geometry$location$lat
  answer$long <- geo_reply$results[[1]]$geometry$location$lng   
  if (length(geo_reply$results[[1]]$types) > 0){
    answer$accuracy <- geo_reply$results[[1]]$types[[1]]
  }
  answer$address_type <- paste(geo_reply$results[[1]]$types, collapse=',')
  answer$formatted_address <- geo_reply$results[[1]]$formatted_address
  answer$original_address <- address
  return(answer)
}

geocoded_1 <- data.frame()
geocoded_he_thong <- data.frame()


# Geocode loca 1
infile <- "input"
startindex <- 1
tempfilename <- paste0(infile, '_temp_geocoded_1.rds')
if (file.exists(tempfilename)){
  print("Found temp file - resuming from index:")
  geocoded <- readRDS(tempfilename)
  startindex <- nrow(geocoded_1)
  print(startindex)
}

paste0(final_single_branch$address, ', HÃ  Ná»i, Viá»t Nam') -> address_1

for (ii in seq(startindex, length(address_1))){
  tryCatch({print(paste("Working on index", ii, "of", length(address_1)))
    #query the google geocoder - this will pause here if we are over the limit.
    result = getGeoDetails(address_1[ii]) 
    print(result$status)     
    result$index <- ii
    #append the answer to the results file.
    geocoded_1 <- rbind(geocoded_1, result)
    #save temporary results as we are going along
    saveRDS(geocoded_1, tempfilename)
  }, error=function(e){cat("ERROR :",conditionMessage(e), "\n")})
}

# Geocode loca há» thá»ng
infile1 <- "input"
startindex1 <- 1
tempfilename1 <- paste0(infile1, '_temp_geocoded.rds')

if (file.exists(tempfilename1)){
  print("Found temp file - resuming from index:")
  geocoded_he_thong <- readRDS(tempfilename1)
  startindex1 <- nrow(geocoded_he_thong)
  print(startindex1)
}

paste0(final_multiple_branches$address, ', HÃ  Ná»i, Viá»t Nam') -> address_he_thong

for (iq in seq(startindex1, length(address_he_thong))){
  tryCatch({print(paste("Working on index", iq, "of", length(address_he_thong)))
    #query the google geocoder - this will pause here if we are over the limit.
    result1 = getGeoDetails(address_he_thong[iq]) 
    print(result1$status)     
    result1$index <- iq
    #append the answer to the results file.
    geocoded_he_thong <- rbind(geocoded_he_thong, result1)
    #save temporary results as we are going along
    saveRDS(geocoded_he_thong, tempfilename1)
  }, error=function(e){cat("ERROR :",conditionMessage(e), "\n")})
}

## left join
final_single_branch %>%
  rowid_to_column() %>%
  left_join(geocoded_1, by = c('rowid' = 'index')) %>%
  select(-row_id, -original_address, -status, -address_type) -> final_single_branch

final_multiple_branches %>%
  rowid_to_column() %>%
  left_join(geocoded_he_thong, by = c('rowid' = 'index')) %>%
  select(-row_id, -original_address, -status, -address_type) -> final_multiple_branches

## post process
final_single_branch %<>% 
  mutate_all(function(x) str_replace_all(x, ',$', ''))

final_multiple_branches %<>% 
  mutate_all(function(x) str_replace_all(x, ',$', ''))
