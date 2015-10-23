# Webscraping news from the BBC website

# environment setting section
library(rvest)
library(stringr)
library(data.table)
source("/Users/ethen/news-networks/bbc/bbc_functions.R")

setwd("/Users/ethen/news-networks/bbc/bbc_data_new")
url <- "http://www.bbc.com"
website <- "http://www.bbc.com/news/world"

# start from the world section for BBC
# use five news from the second section in the main page as the starting node,
# this excludes the first header news 
        
# obtain the news' title        
title <- read_html(website) %>%
		 html_nodes( xpath = "//*[@class='pigeon']//*[@class='title-link__title-text']" ) %>%
		 html_text()
		 
# obtain the news' links(urls), append the url in front if it does not contain the front url 		
# e.g. there're website links that looks like http://www.bbc.co.uk/guides/zgymxnb 
links <- read_html(website) %>%
		 html_nodes( xpath = "//*[@class='pigeon']//*[@class='title-link']") %>% 
         html_attr( name = "href" )
links <- ifelse( str_detect( links, "http" ), links, paste0( url, links ) )

# the number behind the undescore of news_info denotes the layer
news_info_1 <- data.table( title = title, links = links )

# saveRDS( news_info_1, "news_info_1.rds" )

# -----------------------------------------------------------------------------------------
# first layer
# number behind recommendation_list denotes the layer
# news_info_1 <- read.csv("news_info_1.csv", stringsAsFactors = FALSE )
# recommendation_list_1 <- GetRecommendation(news_info_1)

# create the edge_list to store the edge list for the graph 
# edge_list <- list()

# edge_list[[1]] <- ConvertToGraph( news_info_1, recommendation_list_1, 1 )
# recommendation_list_1 <- RemoveEmptyEdges(recommendation_list_1) 

# saveRDS( edge_list, "edge_list_1.rds" )
# saveRDS( recommendation_list_1, "recommendation_list_1.rds" )


# -----------------------------------------------------------------------------------------
# start from this section after getting edge_list_1 and recommendation_list_1, 
# if you're running a new session, remember to run the environment setting section on top

# denote the layer_number to start with
# for clarity, manually change the number behind the variable recommendation_list_ 
# currently, finished going from layer 3 to 4 
layer_number <- 3

edge_list <- readRDS( paste0( "edge_list_", layer_number, ".rds" ) )
recommendation_list_3 <- readRDS( paste0( "recommendation_list_", layer_number, ".rds" ) )

# change the number behind the recommendation_list to move deeper into the next layer
recommendation_list_4 <- WebCrawl( recommendation_list_3, layer_number + 1 )


# saving file section, remember to change the layer number of the recommendation_list_  
saveRDS( edge_list, paste0( "edge_list_", layer_number + 1, ".rds" ) )
saveRDS( recommendation_list_4, paste0( "recommendation_list_", layer_number + 1, ".rds" ) )


