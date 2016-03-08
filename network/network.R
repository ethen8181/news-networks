# network
library(sna)
library(grid)
library(ggnet)
library(dplyr)
library(scales) 
library(igraph)
library(ggplot2)
library(network)
library(data.table)
library(intergraph)
library(RColorBrewer)


# ------------------------------------------------------------------------------------------------
# [TopNews] : Extract the top 10 news' node name and scores, using pagerank or degree of the node
# @graph_dataframe : pass in a igraph type graph
# @grouping        : specify pagerank or degree as the grouping 
TopNews <- function( graph_dataframe, grouping = "pagerank" )
{
	if( grouping == "pagerank" )
	{
		attribute_data <- data.table( nodes = names( V(graph_dataframe) ), 
			                          score = page.rank( graph_dataframe )$vector ) %>%
			              arrange( desc(score) )           	
	}

	if( grouping == "degree" )
	{
		# uses degree to represent the top 10 news 
		attribute_data <- data.table( nodes = names( V(graph_dataframe) ), 
	                       		  	  score = igraph::degree(graph_dataframe) ) %>%
			      	  	  arrange( desc(score) )
	}

	# extract the news with the top 10 score, via pagerank or degree
	top_10_news <- top_n( attribute_data, 10, score )
	return(top_10_news)
}

# -----------------------------------------------------------------------------------------------
# [NetworkPlot] : Cleaning up edge list and creating visualization
# @news     : NYtimes or BBC 
# @layer    : visualize how many layers of the network, currently 4
# @grouping : pagerank, degree or start

NetworkPlot <- function( news, layer = 4, grouping = "start" )
{
	# 1. reading in the edgelist dataset
	# change the column order for new york times, combine the list for bbc 
	# also set the palette colors are the network plot 
	if( news == "NYtimes" )
	{
		filepath <- paste0( "/Users/ethen/news-networks/NYtimes/NYtimes_data_new/edge_list_", layer, ".csv" )
		edgelist <- data.table( read.csv(filepath) )
		setcolorder( edgelist, c( "from", "to", "layer" ) )

		palette <- "Set1"

	}else # "BBC"
	{
		filepath <- paste0( "/Users/ethen/news-networks/bbc/bbc_data_new/edge_list_", layer, ".rds" )
		edgelist <- readRDS(filepath)
		edgelist <- rbindlist(edgelist)

		palette <- "Set2"
	}		

	# 2. preprocessing 
	# exclude the layer column to remove duplicated edges or else ggnet won't work 
	unique_rows <- !duplicated( edgelist[ , -3, with = FALSE ] )
	edgelist    <- edgelist[ unique_rows & complete.cases(edgelist), ]
	
	# remove the layer column and convert to igraph and network type	
	graph_df <- graph.data.frame( edgelist[ , -3, with = FALSE ] )
	network  <- asNetwork(graph_df)

	# 3. grouping the nodes 
	# divide the nodes into two groups, top 10 news and others
	# or by the starting nodes and others
	if( grouping %in% c( "pagerank", "degree" ) )
	{
		top_10_news <- TopNews( graph_df, grouping )
		boolean <- names( V(graph_df) ) %in% top_10_news$nodes  
		network %v% "group" <- ifelse( boolean, "Top 10 News", "Others" )

	}else # "start"
	{
		if( news == "NYtimes" )
		{
			starting_nodes <- read.csv("/Users/ethen/news-networks/NYtimes/NYtimes_data_new/edge_list_1.csv")
			boolean <- names( V(graph_df) ) %in% unique( starting_nodes$from )

		}else # "BBC"
		{
			starting_nodes <- readRDS("/Users/ethen/news-networks/bbc/bbc_data_new/edge_list_1.rds")
			boolean <- names( V(graph_df) ) %in% unique( starting_nodes[[1]]$from )
		}	
		
		network %v% "group" <- ifelse( boolean, "Starting Nodes", "Others" )
	}

	# 4. visualization, plot uses randomized positioning as default, 
	# fix the positioning of the plot
	# number of nodes and edges, goes with the title of the plot
	edges <- length( E(graph_df) )
	nodes <- length( V(graph_df) )
	title <- paste0( "# of nodes:", nodes, "; ", "# of edges:", edges )

	set.seed(1234)
	network_plot <- ggnet2( network, 
		node.size  = 6, 
		alpha      = .6,
		node.color = "group",
		palette    = palette,
		edge.alpha = .9,
		arrow.type = "open",
		arrow.size = 5,
		#arrow.gap = .18,
		edge.label = edgelist$layer,
		edge.label.size = 3,		
		edge.color = c("color", "grey") 
	) + ggtitle( paste0( "Structure of ", news, "\n", title ) )

	return(network_plot)
}

# -------------------------------------------------------------
# store the plot 

# network_plot <- NetworkPlot("NYtimes")
# network_plot <- NetworkPlot("BBC")
    
# setwd("/Users/ethen/news-networks")

# png( "ny_network_plot.png", width = 1080, height = 780 )
# png( "bbc_network_plot_new.png", width = 1080, height = 780 )

# network_plot

# dev.off()


