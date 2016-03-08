# news-networks

Testing out web scraping functionality for R, python and visualizing news network with R. Then use the dataset to create news networks, where the news’ title serves as the network’s nodes and its recommendation news are the network’s edges (out-links), as for which section of the news in a webpage counts as recommendation news’ for a given news are described in each news’ folder. For practice purpose only. Workflow for the folder is described in the following : 

1. Getting the data : Folder “NYtimes” and “bbc” contains functions for web scraping news from each website. All the datasets are also stored in the folder, so if you’re not interested in web scraping and you’re fine with working with datasets that are a bit out-dated, then you may skip this section.
2. Cleaning and visualizing the data : Folder “network”, currently in progress. 

**NYtimes** Stores the web scraping functions and datasets that stores the news’ title and links. 2015.10.23

- `NYtimes.py` Web scraping functions and process. Starts from the world news section. News from “Related Coverage” on the right side of the webpage serves as the news’ recommendation.
- `header.csv` List of user-agent headers that goes along with the web scraping functions.
- `NYtimes_data_new` Stores the data in python objects (.pkl). Including starting news (“news_info_1.csv”), edge_list and recommendation_list. The last number behind the data denotes in which layer was the data scraped. Edge lists are also stored in .csv file to be used with R for creating the network visualizations. To avoid confusions, edge list data are appended on top of one another. e,g, “edge_list_4” will contain news’ edge list from layer 1 to 4, “edge_list_3” will contain news’ edge list from layer 1 to 3 and so on. On the other hand, news’ recommendation data are stored separately. e.g. ““recommendation_list_4” will only store the news’ title and corresponding links if it is generated in the fourth layer.

**bbc** Stores the commensurate things as the NYtimes folder. 2015.10.23
  
- `bbc.R` Web scraping process. bbc’s starting node are chosen manually. To be explicit, after scraping NYtimes’s starting news from the world section, we would try to find news from bbc that are reporting similar contents. For example, if one of the news from NYtimes is talking about president elections in Taiwan, then we will find a similar news that is also referring to the same topic, note that title for the two news will most likely be different! For bbc, news from “More on this story” from the bottom of the webpage counts as that news’ recommendation, bbc might give different names for this part, but the html class is the same.     
- `bbc_functions.R` Define functions used for scraping.
- `bbc_data_new` Data are stored in r objects (.rds). Same as NYtimes, the number behind the names denotes the layer in which the data was created.

**network** (in progress)

- `network.R` Functions for creating the network visualization. Loads in the edge list dataset from the bbc and NYtimes folder respectively, preprocess and visualize it.
- `network.*` Different file-type of the report. Or simply view the report from the following [link](http://ethen8181.github.io/news-networks/network/network.html).

