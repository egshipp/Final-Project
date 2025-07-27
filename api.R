# Packages
library(plumber)
library(tidymodels)
library(readr)

# Data Prep
data <- read.csv("diabetes_binary_health_indicators_BRFSS2015.csv", fileEncoding = "latin1")

data$HighChol <- as.factor(data$HighChol)
data$Fruits <- as.factor(data$Fruits)
data$Diabetes_binary <- as.factor(data$Diabetes_binary)

data_model <- data |>
  select(Diabetes_binary, BMI, HighChol, Fruits)

set.seed(111)
data_split <- initial_split(data_model, prop = 0.7)
data_train <- training(data_split)
data_test <- testing(data_split)
data_cv_folds <- vfold_cv(data_train, 10)

# Best Model: Random Forest Model
tree_rec <- recipe(Diabetes_binary ~ ., data = data_train) |>
  step_normalize(BMI) |>
  step_dummy(HighChol) |>
  step_dummy(Fruits)

rf_spec <- rand_forest(mtry = 2) |>
  set_engine("ranger") |>
  set_mode("classification")
  
rf_wkf <- workflow() |>
    add_recipe(tree_rec) |>
    add_model(rf_spec)

final_fit <- fit(rf_wkf, data = data_train)

#* Predict Diabetes Risk
#* @param BMI:numeric = 28.7
#* @param HighChol:int = 0
#* @param Fruits:int = 1
#* @get /pred
function(BMI = 28.7, HighChol = 0, Fruits = 1) {
  input <- tibble(
    BMI = as.numeric(BMI),
    HighChol = as.factor(HighChol),
    Fruits = as.factor(Fruits)
  )
  
  prediction <- predict(final_fit, input, type = "prob")$.pred_1
  list(prob_diabetes = prediction)
}

#* Get author info
#* @get /info
function() {
  list(
    name = "Elena Shipp",
    github_pages = "https://egshipp.github.io/Final-Project"
  )
}

# Example test calls:
# http://localhost:8000/pred?BMI=28.7&HighChol=0&Fruits=1
# http://localhost:8000/pred?BMI=35.2&HighChol=1&Fruits=0
# http://localhost:8000/pred?BMI=24.5&HighChol=0&Fruits=1