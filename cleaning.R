library(data.table)
setwd("/Users/ethen/news-networks")

# bbc 
edgelist <- readRDS("bbc/bbc_data_new/edge_list_4.rds")
edgelist <- rbindlist(edgelist)

# all the unique new's title, give ids to each news 
news <- unique( c( unique(edgelist$from), unique(edgelist$to) ) )
id <- paste0( "bbc000", 1:length(news) )

bbc_data <- data.table( id = id, news = news )

# store the edge list in id format
edgelist$from <- bbc_data$id[ match( edgelist$from, bbc_data$news ) ] 
edgelist$to   <- bbc_data$id[ match( edgelist$to  , bbc_data$news ) ]

bbc_edgelist <- edgelist[ , -3, with = FALSE ]
write.table( bbc_edgelist, "bbc_edgelist.txt", row.names = FALSE, sep = "\t", quote = FALSE )

# nytimes

edgelist <- read.csv("NYtimes/NYtimes_data_new/edge_list_4.csv", stringsAsFactors = FALSE )

news <- unique( c( unique(edgelist$from), unique(edgelist$to) ) )
id <- paste0( "ny000", 1:length(news) )

ny_data <- data.table( id = id, news = news )

# store the edge list in id format
edgelist$from <- ny_data$id[ match( edgelist$from, ny_data$news ) ] 
edgelist$to   <- ny_data$id[ match( edgelist$to  , ny_data$news ) ]
setcolorder( edgelist, c( "from", "to", "layer" ) )

ny_edgelist <- edgelist[ , -3 ]
write.table( ny_edgelist, "ny_edgelist.txt", row.names = FALSE, sep = "\t", quote = FALSE )

		
# ----------------------------------------------------------------------
# preprocessing adjacency list data 
library(plyr)
library(xlsx)

news_data <- rbind( bbc_data, ny_data )

# read in the adjacency list line by line 
conn <- file( "match_IsorankN_cluster_alpha_0.8.txt", "r" )
conn <- file( "match_IsorankN_cluster_alpha_0.8_reverse.txt", "r" )
adjlist <- list()

step <- 1
while( length( line <- readLines( conn, 1 ) ) > 0 )
{
	nodes <- unlist( strsplit( line, " " ) )
	adjlist[[step]] <- data.frame( t(nodes) )
	step <- step + 1
}
close(conn)

# combine the adjacency list 
adj_dataframe <- do.call( rbind.fill, adjlist )

Match <- function(x) news_data$news[ match( x, news_data$id ) ]

result <- apply( adj_dataframe, 2, Match )
result[ is.na(result) ] <- ""

write.xlsx( result, "result.xlsx", row.names = FALSE )



# -------------------------------------------------------------------------
# combine recommendation list 

library(dplyr)

setwd( "/Users/ethen/news-networks/bbc/bbc_data_new" ) 

file  <- grep( "recommend", list.files(), value = TRUE )
files <- lapply( file, readRDS )

data <- lapply( 1:length(files), function(f)
{
	return( bind_rows( files[[f]] ) )
}) %>% bind_rows() %>% unique()

setwd( "/Users/ethen/Desktop")
write.table( data, "news.csv", row.names = FALSE, sep = "," )


