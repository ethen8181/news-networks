# Webscraping new york times' news 

from urllib.request import urlopen
from urllib.error import HTTPError
from bs4 import BeautifulSoup
import pandas as pd
import requests
import random
import pickle 
import time
import os

# starting url 
url = "http://www.nytimes.com/pages/world/index.html?action=click&pgtype=Homepage&region=TopBar&module=HPMiniNav&contentCollection=World&WT.nav=page"

# Functions 

"""
-- [getWorldNews] -----------------------------------------------------------------
1. Start from the world section of new york times obtain its links and title 
   (strip to remove whitespaces), this serves as the first layer of nodes 
2. Returns the data frame with the links and its corresponding title 
"""

def getWorldNews(url) :

	webpage = BeautifulSoup( urlopen(url), "html.parser" )
	news = webpage.findAll( "div", { "class":"columnGroup singleRule " } )

	news_title = []
	news_links = []

	for information in news :
		infos = information.findAll("h3")
		
		for info in infos :
			info = info.findAll("a")[0]
			news_links.append( info.attrs["href"] )
			news_title.append( info.get_text().strip() )

	news_dict = { "title" : news_title, "links" : news_links }
	return pd.DataFrame(news_dict)

# obtain the first layer 
# news_info_1 = getWorldNews(url)
# news_info_1.to_csv( "NYtimes_data_new/news_info_1.csv", sep = ",", index = False )
# print(news_info_1)


"""
-- [getRecommendation] -----------------------------------------------------------------
1. Given a link from the new's data frame, choose a random header and obtain 
   the recommendation info ( title and links ), news from the "Related Cover" section
   in the right is considered to be the recommendation news 
2. Returns data frame of the recommendation info 
"""		

def getRecommendation(link) :

	# create the random user agent's headers
	header = headers[ "header" ][ random.randint( 0, len(headers) - 1 ) ]
	random_header = { "User-Agent" : header } 
	
	# create the session and assign headers 
	session = requests.Session()
	request = session.get( link, headers = random_header )
	webpage = BeautifulSoup(request.text)

	# if there's a related news section start scraping titles and links 
	boolean = webpage.find( "h2", { "class":"module-heading" } )

	if boolean != None :	
		recommends = webpage.findAll( "aside", { "class":"related-coverage-marginalia" } )[0]
		
		# obtain the news' links
		news_links = []	
		recommends_links = recommends.findAll( "a", { "class":"story-link" } )
		for recommend in recommends_links :
			news_links.append( recommend.attrs["href"] )

		# obtain the news' title
		news_title = []
		recommends_title = recommends.findAll( "span", { "class":"story-heading-text" } )			
		for recommend in recommends_title :
			news_title.append( recommend.get_text().strip() )

		news_dict = { "title" : news_title, "links" : news_links }

	else :
		# scalar index problem have to use list 
		news_dict = { "title" : [None], "links" : [None] }

	# return data after removing duplicates 
	data = pd.DataFrame(news_dict)
	data.drop_duplicates( inplace = True )
	return data


"""
-- [getRecommendationInfo] -----------------------------------------------------------
1. Pass in a data frame containing the news' title and link to obtain the recommendation news,
   which is done by looping the links through the getRecommendation function 
2. Returns list containing the recommendation info data frame ( link and title )
"""

def getRecommendationInfo(dataframe) :

	recommend_info =[]

	for link in dataframe["links"] :
		try :
			recommend = getRecommendation(link)
			recommend_info.append(recommend)

		except HTTPError as e :
			continue
				
	return recommend_info


# store a python object 
def saveObject( data, filename ):

	files = open( filename, "wb" )
	pickle.dump( data, files )
	files.close()

# read in a python object 
def readObject(filename) :

	files = open( filename, "rb" )
	data = pickle.load(files)
	files.close()
	return data

# concat the edge list to a data frame and store as a csv file
def saveEdgeList( edgelist, filename ) :

	concat_edge_list = pd.concat( edgelist, ignore_index = True )
	concat_edge_list.to_csv( filename, sep = ",", index = False )

"""
-- [convertToGraph] ------------------------------------------------------------------------
1. Pass the layer's data frame and it's corresponding recommendation list and 
   convert it to graph data structure where each row represents the interaction (edges) of the graph
   also pass the @layer to denote in which layers were the edges generated 
2. Returns the data frame of the edge list 
"""

def convertToGraph( dataframe, lists, layer ) :

	graph_list = []

	for i in range( len(dataframe) ) :		

		# multiple checks for na values		
		if pd.isnull( lists[i]["links"][0] ) :
			continue

		else :
			tail = lists[i]["title"]
			graph_dict = { "from"  : list( dataframe.iloc[[i]]["title"] ) * len(tail), 
			               "to"    : tail, 
			               "layer" : list( str(layer) ) * len(tail) }
			dataset = pd.DataFrame(graph_dict)
			dataset.dropna( inplace = True )
			graph_list.append(dataset)

	return pd.concat( graph_list, ignore_index = True )


"""
-- [webCrawl] ------------------------------------------------------------------------
1. Pass in the current layer of the recommendation_list to move deeper into the next layer,
   and the layer number that the we're heading towards
2. Returns the next layer's recommendation_list also appends new edge list to global edge_list
"""

def webCrawl( current_layer, layer ) :

	global edge_list
	number_of_list = len(current_layer)
	recommendation_list = []

	# loop through each data frame in the recommendation list to obtain its recommendation
	for i in range(number_of_list) :
		print( str(i+1) + "of" + str(number_of_list) )

		# drop na values, skip the list if it is empty 
		current_layer[i].dropna( inplace = True )

		if len(current_layer[i]) != 0 :			 
			next_layer_list = getRecommendationInfo( current_layer[i] )

			# append edge list to the global edge_list
			# check if the next_layer_list are all consists of empty data frame  
			if len( pd.concat( next_layer_list, ignore_index = True ).dropna() ) != 0 : 
				edge_list.append( convertToGraph( current_layer[i], next_layer_list, layer ) )

				# store the next layer's recommendation info into a list 
				data = pd.concat( next_layer_list, ignore_index = True )
				data.drop_duplicates( inplace = True )
				recommendation_list.append(data)

			# assign random sleeping time before crawling the next list 
			if i == (number_of_list - 1) :
				break
			time.sleep( random.randint( 10, 100 ) )

		else :
			continue
	# return the whole next layer's recommendation list		
	return recommendation_list

# --------------------------------------------------------------------------------------

# 1. environment setting : read in list of random headers, set working directory 
headers = pd.read_csv("headers.csv")
os.chdir("NYtimes_data_new")

# 2. start from the first layer
# news_info_1 = pd.read_csv("news_info_1.csv")

# 3. get the first layer's recommendation and store it 
# recommendation_list_1 = getRecommendationInfo(news_info_1)
# saveObject( recommendation_list_1, "recommendation_list_1.pkl" )

# 4.
# @edge_list : stores the edge list of all layers
# edge_list = []
# edge_list.append( convertToGraph( news_info_1, recommendation_list_1, 1 ) )

# saveObject( edge_list, "edge_list_1.pkl" )
# saveEdgeList( edge_list, "edge_list_1.csv" )


# --------------------------------------------------------------------------	
# manually change the # behind variable recommendation_list_ to move deeper into next layer,
# placesincludes the readObject, webCrawl, saveObject, and also the # behind layer
# the edge_list variable keeps on appending the new edge list to the original list,
# so no # changing required 

# finished layer 3 going to 4 
layer = 3

recommendation_list_3 = readObject( "recommendation_list_" + str(layer) + ".pkl" )
edge_list = readObject( "edge_list_" + str(layer) + ".pkl" )

recommendation_list_4 = webCrawl( recommendation_list_3, layer+1 )

saveObject( recommendation_list_4, "recommendation_list_" + str( layer+1 ) + ".pkl" )
saveObject( edge_list, "edge_list_" + str( layer+1 ) + ".pkl" )
saveEdgeList( edge_list, "edge_list_" + str( layer+1 ) + ".csv" )


