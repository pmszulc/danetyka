library("tidyverse")
library("tidymodels")
library("doParallel")
library("knitr")
theme_set(ggpubr::theme_pubr(base_size = 13))

all_cores <- parallel::detectCores(logical = FALSE)
cl <- makePSOCKcluster(all_cores)
registerDoParallel(cl)

set.seed(10)
n <- 10000
p <- 5
X <- replicate(p, rnorm(n)) %>% 
  as.data.frame() %>% 
  set_names(paste0("X", 1:p))
y <- rep(c(0, 1), n/2) %>% as.factor()
df <- bind_cols(X, y = y)

split <- initial_split(df, prop = 1/10, strata = y)
train <- training(split)
test <- testing(split)

folds <- vfold_cv(train, v = 5, repeats = 3, strata = y)

model <- logistic_reg() 
glm_wflow <- workflow() %>%
  add_model(model) %>%
  add_formula(y ~ .)

glm_wflow %>% 
  fit_resamples(resamples = folds, metrics = metric_set(accuracy)) %>% 
  show_best()

model <- nearest_neighbor(neighbors = tune()) %>%
  set_mode("classification")
knn_wflow <- workflow() %>%
  add_model(model) %>%
  add_formula(y ~ .)

knn_tune <- knn_wflow %>% tune_grid(
  resamples = folds,
  grid = tibble(neighbors = 1:500),
  metrics = metric_set(accuracy)
)

show_best(knn_tune)

autoplot(knn_tune) +
  labs(x = "k", y = "dokładność")

knn_wflow %>% 
  finalize_workflow(select_best(knn_tune)) %>% 
  fit(train) %>% 
  predict(test) %>% 
  add_column(test, .) %>% 
  accuracy(y, .pred_class)

glm_wflow %>% 
  fit(train) %>% 
  predict(test) %>% 
  add_column(test, .) %>% 
  accuracy(y, .pred_class)

simulate_data <- function(seed, n = 200, p = 5) {
  set.seed(seed)
  X <- replicate(p, rnorm(n)) %>% 
    as_data_frame() %>% 
    set_names(paste0("X", 1:p))
  y <- rep(c(0, 1), n/2) %>% as.factor()
  df <- bind_cols(X, y = y)
  folds <- vfold_cv(df, v = 5, repeats = 1, strata = y)
  folds
}
folds_list <- map(1:1000, simulate_data)

model <- logistic_reg() 
glm_wflow <- workflow() %>%
  add_model(model) %>%
  add_formula(y ~ .)

model <- nearest_neighbor(neighbors = tune()) %>%
  set_mode("classification")
knn_wflow <- workflow() %>%
  add_model(model) %>%
  add_formula(y ~ .)

fit_glm <- function(folds) {
  fit <- glm_wflow %>% 
    fit_resamples(resamples = folds, metrics = metric_set(accuracy))
  show_best(fit) 
}

fit_knn <- function(folds) {
  fit <- knn_wflow %>% tune_grid(
    resamples = folds,
    grid = tibble(neighbors = 1:100),
    metrics = metric_set(accuracy)
  ) 
  show_best(fit, n = 1)
}

acc_glm <- map_dfr(folds_list, fit_glm, .progress = TRUE)
acc_knn <- map_dfr(folds_list, fit_knn, .progress = TRUE)

results <- bind_rows(list(glm = acc_glm, knn = acc_knn), .id = "model")
summarise(results, mean(mean), .by = model)

ggplot(results, aes(mean, fill = model)) +
  geom_density(alpha = 0.6) +
  labs(x = "dokładność", y = "") +
  scale_y_continuous(labels = NULL, breaks = NULL)

simulate_data_nested <- function(seed, n = 200, p = 5) {
  set.seed(seed)
  X <- replicate(p, rnorm(n)) %>% 
    as_data_frame() %>% 
    set_names(paste0("X", 1:p))
  y <- rep(c(0, 1), n/2) %>% as.factor()
  df <- bind_cols(X, y = y)
  folds <- nested_cv(df, 
    outside = vfold_cv(df, v = 5, repeats = 1, strata = y),
    inside = vfold_cv(df, v = 3, repeats = 1, strata = y)
  )
  folds
}
folds_nested_list <- map(1:1000, simulate_data_nested)

tune_knn <- function(inner_data) {
  knn_tune <- knn_wflow %>% tune_grid(
    resamples = inner_data,
    grid = tibble(neighbors = 1:100),
    metrics = metric_set(accuracy)
  )
  select_best(knn_tune)
}
calc_accuracy <- function(outer_data, params) {
  fit <- knn_wflow %>% 
    finalize_workflow(params) %>% 
    fit(analysis(outer_data))
  results <- assessment(outer_data) %>% 
    add_column(predict(fit, assessment(outer_data)))
  accuracy(results, y, .pred_class) %>%
    pull(.estimate)
}

fit_knn_nested <- function(folds) {
  params_list <- map(folds$inner_resamples, tune_knn)
  accuracy <- map2_dbl(folds$splits, params_list, calc_accuracy)
  mean(accuracy)
}

acc_knn_nested <- map_dbl(folds_nested_list, fit_knn_nested, .progress = TRUE)

results_nested <- tibble(model = "knn_nested", mean = acc_knn_nested)
results_nested <- results %>% 
  select(model, mean) %>% 
  bind_rows(results_nested)

ggplot(results_nested, aes(mean, fill = model)) +
  geom_density(alpha = 0.6) +
  labs(x = "dokładność", y = "") +
  scale_y_continuous(labels = NULL, breaks = NULL)
