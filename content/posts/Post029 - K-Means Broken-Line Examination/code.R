library(MASS)
library(NbClust)
library(tidyverse)
library(magrittr)

##### PART 1: REPLICATING THE PAPER'S PLOT ########################################################

generate_data <- function(centers, n_points, variance){
    ## Samples multivariate normals around the specified centers using the specified variance.
    ## Returns a dataframe with the points and the corresponding cluster.
    generated_list <- lapply(split(centers, seq(nrow(centers))), mvrnorm,
                            n=n_points, Sigma=variance*diag(dim(centers)[2]))
    generated_data <- do.call(rbind, generated_list)
    return(generated_data)
}

## Centers for the red, cyan, green, magenta, yellow, and blue clusters in the paper, respectively
centers_from_paper <- matrix(c(-0.845, -0.048, -0.392, 0.548, 0.276, 0.360,
                               0.647, 0.899, 0.293, -0.728, 0.935, -0.140),
                             byrow=TRUE, ncol=2)
example_data <- generate_data(centers_from_paper, 150, 0.2^2)
example_data <- data.frame(Cluster=rep(1:6, each=150), example_data)
ggplot(data=example_data) + geom_point(aes(x=X1, y=X2, color=as.factor(Cluster)), size=2) +
    scale_colour_manual(values=c("red","cyan","green", "magenta", "yellow", "blue")) + 
    theme(legend.position = "none")

###################################################################################################

##### PART 2: REPLICATING THE PAPER'S ANALYSIS ####################################################
n_runs <- 100
std_devs <- c(0.2, 0.3, 0.4, 0.5)
indices <- c("kl", "ch", "silhouette", "ccc", "sdindex")
max_clusters <- 24

lnSk <- function(x, n_clusters){
    ## Calculates ln(S_k) of the k-means model with the specified data and number of clusters
    return(log(kmeans(x, n_clusters)$tot.withinss))
}

broken_line_method <- function(lnSk_df){
    ## Determines the best number of clusters using the broken-line method from the paper.  Returns
    ## the best number of clusters
    broken_line <- function(lnSk_df, k){
        first_line_data <- lnSk_df[1:k,]
        second_line_data <- lnSk_df[(k+1):nrow(lnSk_df),]
        first_line <- lm(data=first_line_data, lnSk ~ K)
        second_line <- lm(data=second_line_data, lnSk ~ K)
        total_rss <- sum(resid(first_line)^2) + sum(resid(second_line)^2)
        return(total_rss)
    }
    
    K <- 2:(nrow(lnSk_df)-2)
    broken_line_rss <- sapply(K, broken_line, lnSk_df=lnSk_df)
    best_K <- K[which.min(broken_line_rss)]
    return(best_K)
}

best_number_of_clusters <- function(generated_data, nbclust_methods, max_clusters){
    other_methods_best_K <- sapply(nbclust_methods,
                                   function(i){NbClust(data=generated_data, method="kmeans",
                                                       max.nc=max_clusters, index=i)$Best.nc}
                                   )[1,]
    lnSk_df <- data.frame(K=1:max_clusters, lnSk=sapply(1:max_clusters, lnSk, x=generated_data))
    broken_line_best_K <- broken_line_method(lnSk_df)
    return(c(other_methods_best_K, brokenline=broken_line_best_K))
}

n_runs <- 100
simulation_results <- sapply(std_devs, function(x){
    print(x)
    set.seed(NULL)
    rowMeans(
        replicate(n_runs, {
        print(Sys.time())
        best_number_of_clusters(generate_data(centers_from_paper, 150, x^2), indices, 24)
    }))
})

simulation_results <- as.data.frame(simulation_results)
names(simulation_results) <- c("sd=0.2", "sd=0.3", "sd=0.4", "sd=0.5")
paper_sorting <- c("brokenline", "ch", "silhouette", "kl", "sdindex", "ccc")
simulation_results <- simulation_results[paper_sorting,] %>%
    mutate(AvgAbsDiff = (abs(`sd=0.2`-6) + abs(`sd=0.3`-6) + abs(`sd=0.4`-6) + abs(`sd=0.5`-6))/4)
simulation_results

###################################################################################################
###################################################################################################
##### PART 2a: LOOK AT ln(S_k) PLOTS ##############################################################

lnSk_list <- lapply(1:20, function(x){
    data.frame(Run=x,
               K=1:24,
               lnSk=sapply(1:24, lnSk, x=generate_data(centers_from_paper, 150, 0.2^2)))
})
lnSk_multiple_runs <- do.call(rbind, lnSk_list)
ggplot(data=lnSk_multiple_runs) + geom_point(aes(x=K, y=lnSk)) + facet_wrap(~Run)

###################################################################################################
###################################################################################################
##### PART 2b: A VARIATION ########################################################################
broken_line_method_mod <- function(lnSk_df){
    ## Determines the best number of clusters using the broken-line method from the paper.  Returns
    ## the best number of clusters
    ## note: sometimes gives warning "did not converge in 10 iterations"
    broken_line <- function(lnSk_df, k){
        first_line_data <- lnSk_df[1:k,]
        second_line_data <- lnSk_df[(k+1):nrow(lnSk_df),]
        first_line <- lm(data=first_line_data, lnSk ~ K)
        second_line <- lm(data=second_line_data, lnSk ~ K)
        total_rss <- sum(resid(first_line)^2) + sum(resid(second_line)^2)
        return(total_rss)
    }
    
    broken_line2 <- function(lnSk_df, k){
        first_line_data <- lnSk_df[1:k,]
        second_line_data <- lnSk_df[k:nrow(lnSk_df),]
        first_line <- lm(data=first_line_data, lnSk ~ K)
        second_line <- lm(data=second_line_data, lnSk ~ K)
        total_rss <- sum(resid(first_line)^2) + sum(resid(second_line)^2)
        return(total_rss)
    }
    
    K <- 2:(nrow(lnSk_df)-2)
    broken_line_rss <- sapply(K, broken_line, lnSk_df=lnSk_df)
    best_K <- K[which.min(broken_line_rss)]
    broken_line_mod_rss <- sapply(K, broken_line2, lnSk_df=lnSk_df)
    best_K_mod <- K[which.min(broken_line_mod_rss)]
    return(c(brokenline=best_K, brokenline_mod=best_K_mod))
}

best_number_of_clusters <- function(generated_data, nbclust_methods, max_clusters){
    other_methods_best_K <- sapply(nbclust_methods,
                                   function(i){NbClust(data=generated_data, method="kmeans",
                                                       max.nc=max_clusters, index=i)$Best.nc}
    )[1,]
    lnSk_df <- data.frame(K=1:max_clusters, lnSk=sapply(1:max_clusters, lnSk, x=generated_data))
    broken_line_best_K <- broken_line_method_mod(lnSk_df)
    return(c(other_methods_best_K, broken_line_best_K))
}

n_runs <- 100
simulation_results <- sapply(std_devs, function(x){
    set.seed(NULL)
    rowMeans(
        replicate(n_runs, {
        best_number_of_clusters(generate_data(centers_from_paper, 150, x^2), indices, 24)
    }))
})

simulation_results <- as.data.frame(simulation_results)
names(simulation_results) <- c("sd=0.2", "sd=0.3", "sd=0.4", "sd=0.5")
simulation_results %>%
    mutate(AvgAbsDiff = (abs(`sd=0.2`-6) + abs(`sd=0.3`-6) + abs(`sd=0.4`-6) + abs(`sd=0.5`-6))/4)

###################################################################################################
###################################################################################################
##### PART 3: EXAPANDING THE TESTS ################################################################


###################################################################################################
###################################################################################################
##### PART 3a: NUMBER OF CLUSTERS #################################################################

pairwise_euclidean_distances <- function(point_matrix){
    ## returns vector of all possible Euclidean distances between a matrix of points
    combn(nrow(point_matrix), 2, function(x){sqrt(sum((point_matrix[x[1],]-point_matrix[x[2],])^2))})
}

n_runs <- 50
num_cluster_simulation <- sapply(2:10, function(x){
    print(x)
    set.seed(NULL)
    rowMeans(
        replicate(n_runs, {
            print(Sys.time())
            min_dist <- 0
            while(min_dist<0.45){
                cluster_centers <- sapply(1:2, function(y){runif(x, min=-1, max=1)})
                min_dist <- min(pairwise_euclidean_distances(cluster_centers))
            }
            best_number_of_clusters(generate_data(cluster_centers, 150, 0.2^2), indices, 24)
        }))
})

num_cluster_simulation %>%
    as.data.frame %>%
    set_colnames(paste0("K=",as.character(2:10)))

cluster_sim_long <- num_cluster_simulation %>%
    as.data.frame %>%
    set_colnames(paste0("K=",as.character(2:10))) %>%
    cbind(method=rownames(.), .) %>%
    pivot_longer(cols=starts_with("K="), names_to="K", names_prefix="K=") %>%
    mutate(K=as.numeric(K), Error=value-K)

#value of 0.2883117 calculated as the (0 - min(Error))/(max(Error)/min(Error))
ggplot(cluster_sim_long) +
    geom_tile(aes(x=method, y=K, fill=Error)) +
    scale_fill_gradientn(colors=c("red", "green", "blue"), values=c(0,0.2883117,1))

###################################################################################################
###################################################################################################
##### PART 3b: NUMBER OF POINTS #################################################################

n_runs <- 50
n_points <- c(20, 50, 150, 400)
num_points_simulation <- sapply(n_points, function(x){
    print(x)
    set.seed(NULL)
    rowMeans(
        replicate(n_runs, {
            print(Sys.time())
            best_number_of_clusters(generate_data(centers_from_paper, x, 0.2^2), indices, 24)
        }))
})

num_points_simulation %>%
    as.data.frame %>%
    set_colnames(paste0("n=", n_points))

###################################################################################################


###################################################################################################
###################################################################################################
##### PART 3c: MAXIMUM NUMBER OF CLUSTERS #########################################################

max_clusters <- c(10,12,14,16,18,20,22,24)
n_runs <- 50
max_clusters_simulation <- sapply(max_clusters, function(x){
    print(x)
    set.seed(NULL)
    rowMeans(
        replicate(n_runs, {
            print(Sys.time())
            best_number_of_clusters(generate_data(centers_from_paper, 150, 0.2^2), indices, x)
        }))
})

max_clusters_simulation %>%
    as.data.frame %>%
    set_colnames(paste0("n=", max_clusters))