#### Create the adjacency matrix for the example network
net.matrix <- matrix(c(0,1,0,0,0, 0,0,4,0,0, 0,2,0,1,1,
                       0,1,0,0,0, 0,0,0,0,0), 
                     nrow = 5, ncol = 5, byrow = TRUE,
                     dimnames = list(c("1", "2", "3", "4", "5"),
                                     c("1", "2", "3", "4", "5")))

#### Network Visualization
library(igraph)
net=graph.adjacency(net.matrix,mode="directed",weighted=TRUE,
                    diag=FALSE) 
l <- layout.fruchterman.reingold(net)
plot.igraph(net,layout=l, vertex.label.cex=1,
            vertex.label.color="black",
            edge.color="gray60",vertex.color="light blue",
            edge.width=E(net)$weight, 
            edge.arrow.size=0.4,edge.curved=.3)

#### Network Analysis
library(sna)

## Create the network object
net <- network(net.matrix,matrix.type="adjacency",directed=TRUE)

## Network Size
network.size(net)

## Outdegrees and Indegrees for Nodes
degree(net,cmode="outdegree")
degree(net,cmode="indegree")

## Weighted Outdegrees and Indegrees for Nodes
degree(net.matrix,cmode="outdegree")
degree(net.matrix,cmode="indegree")

## Network Density
gden(net)

## Weighted Density
gden(net.matrix)

## Network Reciprocity
grecip(net,measure="dyadic.nonnull")

## Network Centralization
centralization(net,degree,cmode="outdegree")
centralization(net,degree,cmode="indegree")

## Triad Census
triad.census(net, mode = "digraph")

