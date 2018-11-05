### CPEE_JobRecommendationEngine
The purpose of this project is to build a hybrid job recommendation engine for Quickhire using Collaborative filtering, which makes the use of numerical ratings given by applicants for particular jobs to find similarity between the applicants, as well as of similar job items to predict recommendations of unseen job items to applicants.

Objective: To reduce the burden on the user to search through the catalogue to find relevant stuff. Thereby enhancing user experience and generating more business value.

Benefit: You can vouch for high quality candidates. Discover candidates best suited for specialized positions. And in case of other ecommerce businesses you can even convert shoppers into customers.

Following are the steps to be followed for building job recommendation engine:
	Cast the ratings matrix using library Reshape
	Perform SVD on the above matrix to create User Similarity Matrix & Job Similarity Matrix
	From the user similarity matrix, find 20 similar users to the applicant ID
	Take the job ID’s to which these users have applied
	Find 20 jobs that are similar to each one of them
	We now have a superset of jobs
Sort these Jobs in ascending order of distance between the applicant’s location & job’s location and recommend top 10 jobs from that list.
