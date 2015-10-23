# Define the function for news' website scraping 

# -----------------------------------------------------------------------------------------
# [GetRecommendation] : pass in a data frame and obtain its' recommendation 
# the section "More on this story" serves as the recommendation for this news
# a.k.a the interaction or so called the out-links for the node 

GetRecommendation <- function(df)
{
	recommend_info <- lapply( df$links, function(x)
	{
		# if there's "More on this story" section, the character length will be non zero
		# obtain the news title and link, if none, return a NA data frame 
		boolean	<- read_html(x) %>%
				   html_nodes( xpath = "//*[@class='group__title']" ) %>%
			       html_text()
     
		if( length(boolean) != 0 )
		{	
			recommend_title <- read_html(x) %>% 
						       html_nodes( xpath = "//*[@class='cta']" ) %>%
						       html_text()

			recommend_links <- read_html(x) %>% 
						       html_nodes( xpath = "//*[@class='unit__link-wrapper']" ) %>%
						       html_attr( name = "href" )
			recommend_links <- ifelse( str_detect( recommend_links, "http" ), 
				                       recommend_links, paste0( url, recommend_links ) )

			# it may happen that when linked to news outside of bbc, the links will not be found
			# solve this by checking if the length of the title and link are the same, and remove
			# the longer ones (valid ones), unique prevents if there're duplicated recommendations
			if( length(recommend_title) != length(recommend_links) )
			{
				valid <- min( length(recommend_title), length(recommend_links) )
				recommend <- unique( data.table( title = recommend_title[1:valid], links = recommend_links[1:valid] ) )
			}else	
				recommend <- unique( data.table( title = recommend_title, links = recommend_links ) )					
		}else
			recommend <- data.table( title = NA, links = NA )

		return(recommend)
	})

	return(recommend_info)
}

# -----------------------------------------------------------------------------------------
# [ConvertToGraph] : pass in the head data frame and tail list( recommendation of the head data frame ) 
# and convert it to graph data structure where each row represents the interaction(edges) of the graph
# also records the layer in which the edges were generated 

ConvertToGraph <- function( head_df, tail_list, layer )
{
	number_of_links <- length(head_df$links)
	graph_list <- vector( mode = "list", length = number_of_links )

	for( i in 1:number_of_links )
	{
		# there're no recommendation if the first element of the link column is NA 
		# for the recommendation list, or you can use links
		if( !is.na( tail_list[[i]]$links[1] ) )
		{
			dataset <- data.table( from  = head_df[ i, ]$title, 
				                   to    = tail_list[[i]]$title,
				                   layer = layer )
			graph_list[[i]] <- dataset
		}else
			next			
	}

	graph_data <- rbindlist(graph_list)
	return(graph_data)
}

# -----------------------------------------------------------------------------------------
# [RemoveEmptyEdges] : Pass in a recommendation_list and 
# remove those that do not have recommendations, and also remove those that links to 
# content outside of the website  
# don't do this before converting it to graph data frame, will cause out of border
# and will lose track of recording the nodes that do not have out-links 

RemoveEmptyEdges <- function(recommend_list)
{
	# remove empty edges if any 
	recommend_list <- lapply( recommend_list, function( list )
	{
		list[ complete.cases(list) & str_detect( links, url ), ]
	})

	# remove empty list if any
	recommend_list <- recommend_list[ sapply( recommend_list, nrow ) > 0 ]

	return(recommend_list)
}

#  -----------------------------------------------------------------------------------------
# [WebCrawl] : pass in the current layer of recommendation_list, 
# rerun this section to move in to deeper layers
# @layer = the count of the layer that we're heading towards

WebCrawl <- function( current_layer, layer )
{
	number_of_list <- length(current_layer)
	recommendation_list <- vector( mode = "list", length = number_of_list )

	# loop through each list 
	j <- length(edge_list)
	for( i in 1:number_of_list )
	{
		print( paste0( i, " of ", number_of_list ) )

		next_layer_list <- GetRecommendation( current_layer[[i]] )
		edge_list[[ j+i ]] <<- ConvertToGraph( current_layer[[i]], next_layer_list, layer )

		# rbind the next layer's recommendation info together into one data frame,
		# after converting it the edge list format.  
		# unique is a double check to prevent duplicates from the list( confirmed that there'll be )
		recommendation_list[[i]] <- unique( data.table( do.call( rbind, next_layer_list ) ) )

		# assign random sleeping time 
		if( i == number_of_list )
			break
		Sys.sleep( sample( 1:100, 1 ) )
	}

	# return next layer's recommendation list
	recommendation_list <- RemoveEmptyEdges(recommendation_list)
	return(recommendation_list)
}


