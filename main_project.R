###############################################################################
#~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ Ingesting the Datasets ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~~#
###############################################################################
rm(list=ls(all=TRUE))
#Current working directory
getwd()
#Set working directory to where your data files are stored
setwd("C:/Users/Desktop/Job recommendation engine")

combined_jobs_final <- read.csv(file = "Combined_Jobs_Final.csv", header=TRUE)
credentials <- read.csv(file = "Credentials.csv", header=TRUE)
education <- read.csv(file = "Education.csv", header = TRUE)
experience <- read.csv(file = "Experience.csv", header = TRUE)
interests <- read.csv(file = "Interests.csv", header = TRUE)
job_views <- read.csv(file = "Job_Views.csv", header = TRUE)
languages <- read.csv(file = "Languages.csv", header = TRUE)
leadership <- read.csv(file = "Leadership.csv", header = TRUE)
main_info <- read.csv(file = "Main_Info.csv", header = TRUE)
main_job_views <- read.csv(file = "MainJobViews.csv", header = TRUE)
position_of_interest <- read.csv(file = "Positions_Of_Interest.csv", header = TRUE)
traindata <- read.csv(file="TrainData.csv", header=TRUE)
class(traindata)
str(traindata)
summary(traindata)

#Initially we determine of Ratings on provided by Applicants for Jobs
library(ggplot2)
table(traindata$Rating)
qplot(x=traindata$Rating, data=traindata)
qplot(x=traindata$Rating, y=traindata$ApplicantID, data = traindata)

#Example to understand the Applicant Behaviour
X <- which((traindata$ApplicantID==96))
traindata[X,]

###############################################################################
#~ ~ ~ ~ ~ ~ ~ ~ ~ Data Exploration, Preprocessing & Casting ~ ~ ~ ~ ~ ~ ~ ~ ~#
###############################################################################
# Cast the ratings matrix
#This function reshapes a data frame between 'wide' format with repeated
#measurements in separate columns of the same record and 'long' format 
#with the repeated measurements in separate records
library(reshape2)
newdata <- dcast(traindata,ApplicantID ~ JobID)
str(newdata)
sum(is.na(newdata))
dim(newdata)

#newdata[is.na(newdata)] <- 0
#OR

library(DMwR)
newdata <- centralImputation(newdata)
str(newdata)

#Main_Job_Views
sum(is.na(main_job_views))
main_job_views <- knnImputation(main_job_views)
str(main_job_views)

#Main_Info
sum(is.na(main_info))
main_info <- centralImputation(main_info)
str(main_info)
names(main_info)

#Combined_Jobs_Final
sum(is.na(combined_jobs_final))
names(combined_jobs_final)
str(combined_jobs_final)
combined_jobs_final <- subset(combined_jobs_final, select = -c(2,3,4,5,11,14,15,16,18,19,20))
combined_jobs_final <- centralImputation(combined_jobs_final)

#New Insights of Applicant ID 96 as described above
newdata[2,]

###############################################################################
#~ ~ ~ ~ ~ ~ ~ ~ ~ Compute the Singular-value Decomposition  ~ ~ ~ ~ ~ ~ ~ ~ ~#
###############################################################################
#SVD is a method of decomposing a matrix into other matrices 
#That has lots of wonderful properties(like Applicants, Jobs, Distance)
svd<-svd(newdata[,-1])
S <- diag(svd$d)
u <- svd$u
v <- svd$v
vt = t(v)
N_hat = u %*% S %*% vt
eigenval = svd$d
e_sqare_energy = (eigenval/sum(eigenval))*100
cumsum(e_sqare_energy)

# with first 615 values itself, 100% is covered hence, 615 dimensions are enough
svd <- svd(N_hat,nu=615,nv=615)
S <- diag(svd$d[1:615])
 
###############################################################################
#~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ Compute Cosine Similarity ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~#
###############################################################################
library(lsa)
user_similarity <- cosine(u)
job_similarity <- cosine(vt)
#Mapping ApplicantID with their Index
app_id <- cbind(newdata[,1], seq(1:nrow(newdata)))
app_id <- as.data.frame(app_id)
names(app_id) <- c("applicant_id", "index")

########## Function To Extract Top 20 Similar Applicants ##########
similar_users <- function(A){
  x <- subset(app_id, applicant_id==A)
  y <- x[1,2]
  users_sim <- user_similarity[y,]
  users_sim <- as.data.frame(cbind(users_sim, app_id$index))
  names(users_sim) <- c("similarity", "index")
  users_sim <- users_sim[with(users_sim, order(-similarity)), ]
  top <- users_sim[1:21, ]
  top_similar_users <- top[-1,2]
  top_similar_ids <- subset(app_id, index%in%top_similar_users)
  top_similar_ids <- top_similar_ids[,1]
  return(top_similar_ids)
}

########## Function to Extract Top 20 Similar Jobs ##########
similar_jobs <- function(A){
  ids <- similar_users(A)
  int_jobs <- subset(main_job_views, Applicant.ID%in%ids & Job.Applied=="yes")
  relevant_jobs <- unique(int_jobs[,3])
  jobs <- as.data.frame(cbind(names(newdata[,-1]), seq(1:length(names(newdata[,-1])))))
  names(jobs) <- c("job_id", "ind")
  temp <- subset(jobs, job_id%in%as.character(relevant_jobs))
  temp2 <- temp[,2]
  temp2 <- as.numeric(temp2)
  fin <- data.frame(similarity=numeric(),
                    ind = numeric())
  for(i in temp2){
    m <- job_similarity[i,]
    n <- as.data.frame(cbind(m, seq(1:ncol(job_similarity))))
    names(n) <- c("similarity", "ind")
    n <- n[with(n, order(-similarity)), ]
    tj <- n[2:21, ]
    fin <- rbind(fin, tj)
  }
  final <- fin[!duplicated(fin),]
  final_job_list <- subset(jobs, ind%in%final$ind)
  final_jobs <- final_job_list$job_id
  return(as.character(final_jobs))
}

########## Function to Recommend 10 Jobs ##########
reccos <- function(A, t){
  rec <- similar_jobs(A)
  rec <- as.numeric(rec)
  rec
  app_info <- subset(main_info, Applicant.ID%in%app_id[,1])
  app_info <- app_info[with(app_info, order(Applicant.ID)), ]
  job_info <- subset(combined_jobs_final, Job.ID%in%rec)
  job_info_place <- subset(job_info,
                           State.Code==as.character(main_info[which(main_info$Applicant.ID==A), 5]))
  t1 <- app_info[app_info$Applicant.ID==A,]
  x1 <- t1[1,6] #Latitude of Applicant from main_info
  y1 <- t1[1,7] #Longitude of Applicant from main_info
  
  #[,7] and [,8]: Latitude and Longitude of Job from combined_jobs_final
  dist <- c() #Empty vector for distance
  for (i in 1:nrow(job_info_place)){
    dist <- c(dist, sqrt((x1-job_info_place[i,7])**2 + (y1-job_info_place[i,8])**2))
  }#Calculate distance between 2 points
  
  job_info_place$dist <- dist
  job_info_place <- job_info_place[with(job_info_place, order(dist)), ]
  return(job_info_place[1:t,c(1:5)])
}

###############################################################################
#~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~  Initiate Job Recommendations ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~#
###############################################################################
#library(geosphere)
A = 96 #Applicant ID 96
reccomend <- reccos(A,10)
reccomend

########## Past Experience of Applicant ##########
prev <- subset(experience, Applicant.ID==A)
names(experience)
prev <- prev[, c("Position.Name","Employer.Name","City","State.Name","Salary")]
as.character(prev)
prev <- as.data.frame(prev)
names(prev) <- c("Experience","Company","City","State","Salary")
prev

########## Applicant's Position of Interest ##########
pos_interest <- subset(position_of_interest, Applicant.ID==A)
pos_interest <- pos_interest[, 2] #Position of Interest attribute
as.character(pos_interest)
pos_interest <- as.data.frame(pos_interest)
names(pos_interest) <- "Position of Interest"
pos_interest

