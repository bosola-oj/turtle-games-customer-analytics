getwd()

# Change current directory.
# setwd('your/path/to/data')

# Import the cleaned CSV file.
reviews <- read.csv(file.choose(), header=T)

# Import the tidyverse library
library(tidyverse)

# View the head of the data.
head(reviews)

# Create a summary of the data frame.
summary(reviews)

# check structure and dimensions as a sense-check.
str(reviews)
dim(reviews)

# Exploratory data analysis
# Groupings - understanding loyalty points by category

# Average loyalty points by gender.
reviews %>%
  group_by(gender) %>%
  summarise(mean_loyalty = mean(loyalty_points),
            median_loyalty = median(loyalty_points),
            count = n())

# Observations:
# Female customers show a slightly higher mean (1,601) and median (1,281) loyalty 
# points than male customers (mean 1,549, median 1,248), but the gap is small, 
#roughly 3% difference in mean and under 3% in median.
# Female customers (1,120) outnumber male customers (880) in this dataset,
# though not severe enough to distort the comparison above.
# Given how close these figures are, gender does not appear to be a meaningful 
# driver of loyalty point accumulation.
# marketing should not expect gender-based segmentation alone to explain or predict loyalty behaviour.

# Average loyalty points by education level.
reviews %>%
  group_by(education) %>%
  summarise(mean_loyalty = mean(loyalty_points),
            median_loyalty = median(loyalty_points),
            count = n())

# Observations
  
# "Basic" education shows a notably higher mean (2,265) than every other group,
# but this group has only 50 customers, the smallest sample by a wide margin 
# This is probably due to one or two high-loyalty outliers.
# "Graduate" customers form the largest group (900, 45% of the dataset) with the 
# second-highest mean (1,666). This is statistically a trustworthy result among
# the higher-loyalty groups, given its much larger sample size.
# "Diploma" holders show the lowest mean (1,336) among reliably-sized groups.
# Across every education group, the mean sits noticeably above the median.

# Scatterplot - loyalty vs spending score
ggplot(reviews, aes(x=spending_score, y=loyalty_points)) +
  geom_point(alpha=0.5, color='steelblue') +
  labs(title='Loyalty Points vs Spending Score',
       x='Spending Score',
       y='Loyalty Points')

# Observations
  
# Up to a spending score of roughly 60, loyalty points rise in a fairly tight
# band, mostly staying under 2,000. Beyond a spending score of roughly 60, the 
# data splits into two visually distinct groups: one that continues the same gentle,
# lower-value trend, and a second, separate band that jumps sharply higher, 
# This suggests at least two underlying customer behaviours or segments exist within 
# the high-spending population.


# Histogram - distribution of loyalty points
ggplot(reviews, aes(x=loyalty_points)) +
  geom_histogram(bins=30, fill='steelblue', color='black') +
  labs(title='Distribution of Loyalty Points',
       x='Loyalty Points',
       y='Frequency')

# Observations
  
# The distribution is strongly right-skewed: the large majority of customers 
# sit in the 0–2,000 loyalty point range, with a sharp peak around 1,200–1,500.


# Boxplot - loyalty points by gender
ggplot(reviews, aes(x=gender, y=loyalty_points)) +
  geom_boxplot(fill='lightblue') +
  labs(title='Loyalty Points by Gender',
       x='Gender',
       y='Loyalty Points')

# Observations

# The boxplots for male and female customers are almost identical in shape
# almost the same median (~1,250–1,300), the same interquartile range, and the 
# same long tail of outliers extending up to roughly 6,800 points for both genders. 
# This visually confirms the grouped table result that gender has no meaningful effect 
# on loyalty point accumulation or its spread. 

# Assignment Activity 6
# Check correlations between numeric variables.
cor(reviews[, c('age', 'remuneration', 'spending_score', 'loyalty_points')])

# Feature selection, justification, and concerns
# Based on both the Python regression results from Activity 1 and this 
#correlation check, `spending_score` and `remuneration` are justified 
#inclusions as each independently shows a meaningful relationship with 
#loyalty points. `age` is excluded: its near-zero R² and correlation in 
# every prior analysis consistently show it carries no explanatory power 
#for this target.


# Create the multiple linear regression model.
model_mlr <- lm(loyalty_points ~ remuneration + spending_score, data=reviews)

# View the model summary.
summary(model_mlr)

# The model's R² of 0.827 is strong and both predictors are highly significant

# Install and load the car package for VIF.
# install.packages('car')
library(car)

# Check Variance Inflation Factor.
vif(model_mlr)

# Add predicted values to the data frame.
reviews$predicted_loyalty <- predict(model_mlr)

# Plot actual vs predicted loyalty points.
ggplot(reviews, aes(x=predicted_loyalty, y=loyalty_points)) +
  geom_point(alpha=0.4, color='steelblue') +
  geom_abline(intercept=0, slope=1, color='red', linetype='dashed') +
  labs(title='Actual vs Predicted Loyalty Points (MLR Model)',
       x='Predicted Loyalty Points',
       y='Actual Loyalty Points')

# Check residual diagnostics
par(mfrow=c(2,2))
plot(model_mlr)

# Demonstrating the model with specific scenarios
# Create example customer scenarios.
new_customers <- data.frame(
  remuneration = c(25, 50, 90),
  spending_score = c(20, 50, 85)
)

# Predict loyalty points for these scenarios.
predict(model_mlr, newdata=new_customers)

# Scenario interpretation

# Customer 1 (remuneration £25k, spending score 20) — predicted loyalty points: -192.96.
#The model predicts a negative number of loyalty points, which is impossible in reality. 
# This is proof that the model's linear assumption breaks down specifically at the low end 
# of the customer base, and any real-world deployment of this model would need a rule bolted on 
# to avoid producing irrelevant output.

# Customer 2 (remuneration £50k, spending score 50) — predicted loyalty points: 1,643.30. 
#This sits close to the dataset's actual median (1,276) and mean (1,578), and is well within 
#the reliable middle portion of the actual-vs-predicted plot.

# Customer 3 (remuneration £90k, spending score 85) — predicted loyalty points: 4,153.73. 
# This falls in the exact region the diagnostic plots flagged as least reliable, 
# high fitted values, where residual spread widens and the actual-vs-predicted plot fans out 
# furthest from the reference line. This prediction should be treated as a rough estimate.
