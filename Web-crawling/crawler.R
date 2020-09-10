library(tidyverse)
library(rvest)
library(RSelenium)
library(stringr)
library(leaflet)
library(ggmap)
library(magrittr)
library(sp)
rD <- rsDriver(browser = 'firefox')
remDr <- rD$client

## function
myswitch <- function (remDr, windowId) {
  qpath <- sprintf('%s/session/%s/window', remDr$serverURL,
                   remDr$sessionInfo[['id']])
  remDr$queryRD(qpath, 'POST', qdata = list(handle = windowId))
}

page_source <- list()
true_cond <- list()
false_cond <- list()
ten_shop <- list()
b <- list()
currWindow <- list()
general_info <- list()
menu <- list()
windows <- list()
otherWindow <- list()
currWindow1 <- list()
windows1 <- list()
otherWindow1 <- list()
windows2 <- list()
otherWindow2 <- list()
general_info_2 <- list()
menu_2 <- list()
b2 <- list()
a <- 1
e <- 1
d <- list()
##

for (k in 1:84) {
  remDr$navigate(paste0("https://www.foody.vn/ha-noi/cafe?ds=Restaurant&vt=row&st=1&c=2&page=", k, "&provinceId=218&categoryId=2&append=true"))
  page_source[[k]] <- remDr$getPageSource() # 1 -> k
  
  ## get name  ---------------------------------
  ### get name of há» thá»ng ---------------------
  (read_html(page_source[[k]][[1]]) %>% html_nodes(css = "h2") %>% html_text() %>% str_remove('^([[:space:]]+)') %>% str_remove('([[:space:]]+)$') %>% str_replace_all('[\n\r]','') -> ten_shop[[k]]) # 1 -> k
  
  which(str_detect(ten_shop[[k]], 'Há» thá»ng')) -> true_cond[[k]] # 1 -> k
  which(str_detect(ten_shop[[k]], 'Há» thá»ng', negate = TRUE)) -> false_cond[[k]] # 1 -> k
  
  remDr$findElements(using = "xpath", "//h2/a") -> b[[k]] # 1 -> k
  
  currWindow[[k]] <- remDr$getCurrentWindowHandle()[[1]] # 1 -> k
  
  for(i in true_cond[[k]]) { # 1 -> k
## click link

    remDr$executeScript("arguments[0].setAttribute('target', arguments[1]);", list(b[[k]][[i]], '_blank')) # 1 -> k, # 1 -> i
    remDr$executeScript("arguments[0].setAttribute('rel', arguments[1]);", list(b[[k]][[i]], "noopener noreferrer")) # 1 -> k, # 1 -> i
    remDr$executeScript("arguments[0].scrollIntoView(false);", list(b[[k]][[i]])) # 1 -> k, # 1 -> i
    b[[k]][[i]]$clickElement() # 1 -> k, # 1 -> i
    
    ## get handle
    Sys.sleep(sample(seq(1,5), 1))
    
    windows[[i]] <- remDr$getWindowHandles() # 1 -> i
    otherWindow[[i]] <- windows[[i]][!windows[[i]] %in% currWindow[[k]]][[1]]
    
    ## switch window
    myswitch(remDr, otherWindow[[i]][[1]])  # 1 -> i
    
    ## process
    
    remDr$findElements(using = "xpath", "//h2/a") -> d[[i]] # 1 -> i
    
    currWindow1[[i]] <- remDr$getCurrentWindowHandle()[[1]] # 1 -> i
  ## loop inside
  for(j in 1:length(d[[i]])) {
    remDr$executeScript("arguments[0].setAttribute('target', arguments[1]);", list(d[[i]][[j]], '_blank'))
    remDr$executeScript("arguments[0].setAttribute('rel', arguments[1]);", list(d[[i]][[j]], "noopener noreferrer"))
    remDr$executeScript("arguments[0].scrollIntoView(false);", list(d[[i]][[j]]))
    d[[i]][[j]]$clickElement()
    Sys.sleep(sample(seq(5,10), 1))
    
    windows1[[j]] <- remDr$getWindowHandles()
    otherWindow1[[j]] <- windows1[[j]][!windows1[[j]] %in% c(windows1[[j]][[1]], windows1[[j]][[2]])]
    myswitch(remDr, otherWindow1[[j]][[1]])
    page_source1 <- read_html((remDr$getPageSource())[[1]])
    Sys.sleep(sample(seq(5,10), 1))
    
    general_info[[a]] <- tibble(title = ifelse(identical(page_source1 %>% html_nodes(xpath = "//div[@class = 'main-info-title']//h1") %>% html_text(), character(0)), '', page_source1 %>% html_nodes(xpath = "//div[@class = 'main-info-title']//h1") %>% html_text()),
                                category = ifelse(identical(page_source1 %>% html_nodes(xpath = "//div[@class = 'category-items']//a[@title]") %>% html_text(), character(0)), '', page_source1 %>% html_nodes(xpath = "//div[@class = 'category-items']//a[@title]") %>% html_text()),
                                loai_mon = ifelse(identical(page_source1 %>% html_nodes(xpath = "//div[@class = 'cuisines-list']//a/text()") %>% html_text(), character(0)), '', page_source1 %>% html_nodes(xpath = "//div[@class = 'cuisines-list']//a/text()") %>% html_text()),
                                loai_khach = ifelse(identical(page_source1 %>% html_nodes(xpath = "//div[@class = 'audiences']/text()") %>% html_text(), character(0)), '', page_source1 %>% html_nodes(xpath = "//div[@class = 'audiences']/text()") %>% html_text()),
                                avg_score = ifelse(identical(page_source1 %>% html_nodes(xpath = "//div[@class = 'microsite-point-avg ']") %>% html_text(), character(0)), page_source1 %>% html_nodes(xpath = "//div[@class = 'microsite-point-avg avg-bg-low']") %>% html_text(), page_source1 %>% html_nodes(xpath = "//div[@class = 'microsite-point-avg ']") %>% html_text()),
                                location = ifelse(identical((page_source1 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[1], character(0)), '', (page_source1 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[1]),
                                price = ifelse(identical((page_source1 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[2], character(0)), '', (page_source1 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[2]),
                                quality = ifelse(identical((page_source1 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[3], character(0)), '', (page_source1 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[3]),
                                space = ifelse(identical((page_source1 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[4], character(0)), '', (page_source1 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[4]),
                                service = ifelse(identical((page_source1 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[5], character(0)), '', (page_source1 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[5]),
                                comment_count = ifelse(identical(page_source1 %>% html_nodes(xpath = "//div[@class = 'microsite-review-count']") %>% html_text(), character(0)), '', page_source1 %>% html_nodes(xpath = "//div[@class = 'microsite-review-count']") %>% html_text()),
                                address = ifelse(identical(page_source1 %>% html_nodes(xpath = "//div[@class = 'res-common-add']//span//a//span[@itemprop = 'streetAddress']") %>% html_text(), character(0)), '', page_source1 %>% html_nodes(xpath = "//div[@class = 'res-common-add']//span//a//span[@itemprop = 'streetAddress']") %>% html_text()),
                                district = ifelse(identical(page_source1 %>% html_nodes(xpath = "//span[@itemprop = 'addressLocality']") %>% html_text(), character(0)), '', page_source1 %>% html_nodes(xpath = "//span[@itemprop = 'addressLocality']") %>% html_text()),
                                price_range = ifelse(identical(page_source1 %>% html_nodes(xpath = "//span[@itemprop = 'priceRange']/span") %>% html_text(), character(0)), '', page_source1 %>% html_nodes(xpath = "//span[@itemprop = 'priceRange']/span") %>% html_text()),
                                time = ifelse(identical(page_source1 %>% html_nodes(xpath = "//div[@class = 'micro-timesopen']//span[3]") %>% html_text(), character(0)), '', page_source1 %>% html_nodes(xpath = "//div[@class = 'micro-timesopen']//span[3]") %>% html_text()),
                                khu_vuc = ifelse(identical((page_source1 %>% html_nodes(xpath = "//a[@itemprop = 'item']//span[@itemprop = 'name']") %>% html_text())[3], character(0)), '', (page_source1 %>% html_nodes(xpath = "//a[@itemprop = 'item']//span[@itemprop = 'name']") %>% html_text())[3]))
    
    menu[[a]] <- tibble(product = ifelse(identical(page_source1 %>% html_nodes(xpath = "//a[@class = 'title-name-food']//div[@class = 'title-name ng-binding ng-isolate-scope']") %>% html_text(), character(0)), '', page_source1 %>% html_nodes(xpath = "//a[@class = 'title-name-food']//div[@class = 'title-name ng-binding ng-isolate-scope']") %>% html_text()),
                        price = ifelse(identical(page_source1 %>% html_nodes(xpath = "//span[@class = 'price ng-binding']") %>% html_text(), character(0)), '', page_source1 %>% html_nodes(xpath = "//span[@class = 'price ng-binding']") %>% html_text())) # giÃ¡
    
    remDr$closeWindow()
    remDr$switchToWindow(currWindow1[[i]][[1]])
    Sys.sleep(sample(seq(4,6), 1))
    
    a <- a + 1
  }
    
  remDr$closeWindow()
  remDr$switchToWindow(currWindow[[k]])
  Sys.sleep(sample(seq(4,6), 1))
  }
  
  for(g in false_cond[[k]]) {
    remDr$executeScript("arguments[0].setAttribute('target', arguments[1]);", list(b[[k]][[g]], '_blank'))
    remDr$executeScript("arguments[0].setAttribute('rel', arguments[1]);", list(b[[k]][[g]], "noopener noreferrer"))
    remDr$executeScript("arguments[0].scrollIntoView(false);", list(b[[k]][[g]]))
    b[[k]][[g]]$clickElement()
    Sys.sleep(sample(seq(5,10), 1))
    
    windows2[[g]] <- remDr$getWindowHandles() # 1 -> i
    otherWindow2[[g]] <- windows2[[g]][!windows2[[g]] %in% currWindow[[k]]][[1]]
    
    myswitch(remDr, otherWindow2[[g]][[1]])
    page_source2 <- read_html((remDr$getPageSource())[[1]])
    Sys.sleep(sample(seq(5,10), 1))
    
    general_info_2[[e]] <- tibble(title = ifelse(identical(page_source2 %>% html_nodes(xpath = "//div[@class = 'main-info-title']//h1") %>% html_text(), character(0)), '', page_source2 %>% html_nodes(xpath = "//div[@class = 'main-info-title']//h1") %>% html_text()),
                                  category = ifelse(identical(page_source2 %>% html_nodes(xpath = "//div[@class = 'category-items']//a[@title]") %>% html_text(), character(0)), '', page_source2 %>% html_nodes(xpath = "//div[@class = 'category-items']//a[@title]") %>% html_text()),
                                  loai_mon = ifelse(identical(page_source2 %>% html_nodes(xpath = "//div[@class = 'cuisines-list']//a/text()") %>% html_text(), character(0)), '', page_source2 %>% html_nodes(xpath = "//div[@class = 'cuisines-list']//a/text()") %>% html_text()),
                                  loai_khach = ifelse(identical(page_source2 %>% html_nodes(xpath = "//div[@class = 'audiences']/text()") %>% html_text(), character(0)), '', page_source2 %>% html_nodes(xpath = "//div[@class = 'audiences']/text()") %>% html_text()),
                                  avg_score = ifelse(identical(page_source2 %>% html_nodes(xpath = "//div[@class = 'microsite-point-avg ']") %>% html_text(), character(0)), page_source2 %>% html_nodes(xpath = "//div[@class = 'microsite-point-avg avg-bg-low']") %>% html_text(), page_source2 %>% html_nodes(xpath = "//div[@class = 'microsite-point-avg ']") %>% html_text()),
                                  location = ifelse(identical((page_source2 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[1], character(0)), '', (page_source2 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[1]),
                                  price = ifelse(identical((page_source2 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[2], character(0)), '', (page_source2 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[2]),
                                  quality = ifelse(identical((page_source2 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[3], character(0)), '', (page_source2 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[3]),
                                  space = ifelse(identical((page_source2 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[4], character(0)), '', (page_source2 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[4]),
                                  service = ifelse(identical((page_source2 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[5], character(0)), '', (page_source2 %>% html_nodes(xpath = "//div[@class = 'microsite-top-points']//span") %>% html_text())[5]),
                                  comment_count = ifelse(identical(page_source2 %>% html_nodes(xpath = "//div[@class = 'microsite-review-count']") %>% html_text(), character(0)), '', page_source2 %>% html_nodes(xpath = "//div[@class = 'microsite-review-count']") %>% html_text()),
                                  address = ifelse(identical(page_source2 %>% html_nodes(xpath = "//div[@class = 'res-common-add']//span//a//span[@itemprop = 'streetAddress']") %>% html_text(), character(0)), '', page_source2 %>% html_nodes(xpath = "//div[@class = 'res-common-add']//span//a//span[@itemprop = 'streetAddress']") %>% html_text()),
                                  district = ifelse(identical(page_source2 %>% html_nodes(xpath = "//span[@itemprop = 'addressLocality']") %>% html_text(), character(0)), '', page_source2 %>% html_nodes(xpath = "//span[@itemprop = 'addressLocality']") %>% html_text()),
                                  price_range = ifelse(identical(page_source2 %>% html_nodes(xpath = "//span[@itemprop = 'priceRange']/span") %>% html_text(), character(0)), '', page_source2 %>% html_nodes(xpath = "//span[@itemprop = 'priceRange']/span") %>% html_text()),
                                  time = ifelse(identical(page_source2 %>% html_nodes(xpath = "//div[@class = 'micro-timesopen']//span[3]") %>% html_text(), character(0)), '', page_source2 %>% html_nodes(xpath = "//div[@class = 'micro-timesopen']//span[3]") %>% html_text()),
                                  khu_vuc = ifelse(identical((page_source2 %>% html_nodes(xpath = "//a[@itemprop = 'item']//span[@itemprop = 'name']") %>% html_text())[3], character(0)), '', (page_source2 %>% html_nodes(xpath = "//a[@itemprop = 'item']//span[@itemprop = 'name']") %>% html_text())[3]))
    
    menu_2[[e]] <- tibble(product = page_source2 %>% html_nodes(xpath = "//a[@class = 'title-name-food']//div[@class = 'title-name ng-binding ng-isolate-scope']") %>% html_text(),
                          price = page_source2 %>% html_nodes(xpath = "//span[@class = 'price ng-binding']") %>% html_text()) # giÃ¡
    
    e <- e + 1
    
    remDr$closeWindow()
    remDr$switchToWindow(currWindow[[k]])
    Sys.sleep(sample(seq(4,6), 1))
  }
}

##################################

do.call(rbind.data.frame, general_info) -> location_he_thong
do.call(rbind.data.frame, general_info_2) -> location_1
do.call(rbind.data.frame, menu) -> final_menu_he_thong
do.call(rbind.data.frame, menu_2) -> final_menu

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
                    mutate_at(vars('lower_price', 'upper_price'), function(x) str_replace_all(x, '\\.|Ä|d', '')) %>%
                    mutate_at(vars('lower_price', 'upper_price'), function(x) str_sub(x, end = -2)) %>%
                    mutate_at(vars('avg_score', 'location', 'quality', 'space', 'service', 'comment_count', 'lower_price', 'upper_price'), as.double)
}

loca_process(location_1) -> location_1
loca_process(location_he_thong) -> location_he_thong

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

paste0(location_1$address, ', HÃ  Ná»i, Viá»t Nam') -> address_1

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

paste0(location_he_thong$address, ', HÃ  Ná»i, Viá»t Nam') -> address_he_thong

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
location_1 %>%
  rowid_to_column() %>%
  left_join(geocoded_1, by = c('rowid' = 'index')) %>%
  select(-row_id, -original_address, -status, -address_type) -> location_1

location_he_thong %>%
  rowid_to_column() %>%
  left_join(geocoded_he_thong, by = c('rowid' = 'index')) %>%
  select(-row_id, -original_address, -status, -address_type) -> location_he_thong

## post process
location_1 %<>% 
  mutate_all(function(x) str_replace_all(x, ',$', ''))

location_he_thong %<>% 
  mutate_all(function(x) str_replace_all(x, ',$', ''))
