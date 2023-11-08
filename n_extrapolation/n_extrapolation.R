library("tidyverse")
library("tidymodels")
library("doParallel")
theme_set(ggpubr::theme_pubr(base_size = 15))

all_cores <- parallel::detectCores(logical = FALSE)
cl <- makePSOCKcluster(all_cores)
registerDoParallel(cl)

pulsar <- read_csv("train.csv")

pulsar <- pulsar %>% 
  rename(
    Mean = "Mean_Integrated", Skewness = "EK", EK = "Skewness",
    Mean_curve = "Mean_DMSNR_Curve", SD_curve = "SD_DMSNR_Curve",
    Skewness_curve = "EK_DMSNR_Curve", EK_curve = "Skewness_DMSNR_Curve"
  ) %>% 
  mutate(Class = as.factor(Class)) %>% 
  select(-id)

set.seed(42)
train <- slice_sample(pulsar, n = 6e4)

rf_model <- rand_forest()  %>% 
  set_mode("classification") %>% 
  set_engine("ranger")
rf_recipe <- recipe(Class ~ ., train)
rf_wflow <- workflow() %>%
  add_model(rf_model) %>%
  add_recipe(rf_recipe)

slice_logloss <- function(n, seed) {
  set.seed(seed)
  train_sample <- slice_sample(train, n = n)
  # dla maksymalnego n to prawie tylko permutacja, ale ma to znaczenie 
  # -> dziala jak repeated CV
  train_folds <- vfold_cv(train_sample, v = 10, strata = Class)
  
  rf_cv <- rf_wflow %>% fit_resamples(
    resamples = train_folds,
    metrics = metric_set(mn_log_loss)
  )
  collect_metrics(rf_cv, summarize = FALSE) %>% 
    select(.estimate) %>% 
    mutate(n = n, seed = seed, .before = 1)
}

n <- seq(1e4, 6e4, length = 11) %>% round()
seeds <- 1:10
grid <- expand_grid(n, seeds)

results <- map2_df(grid$n, grid$seeds, slice_logloss, .progress = TRUE)

results %>% 
  summarise(logloss = mean(.estimate), se = sd(.estimate) / sqrt(n()), .by = n) %>% 
  mutate(n = n * 0.9) %>% 
  ggplot(aes(n, logloss)) +
  geom_point(size = 2) +
  geom_line() +
  geom_errorbar(aes(ymin = logloss - se, ymax = logloss + se), width = 2000)

df <- results %>% 
  summarise(logloss = mean(.estimate), se = sd(.estimate) / sqrt(n()), .by = n) %>% 
  mutate(n = n * 0.9)

model <- lm(logloss ~ I(1/n) + I(1/n^2), df, weights = 1/se)
summary(model)

df <- df %>% 
  mutate(logloss_pred = predict(model))
df_extrapolation <- tibble(n = c(6e4, 7e4, 8e4)*0.9)
df_extrapolation <- df_extrapolation %>% 
  mutate(logloss_pred = predict(model, df_extrapolation))

ggplot(df, aes(n, logloss)) +
  geom_point(size = 2) +
  geom_line() +
  geom_errorbar(aes(ymin = logloss - se, ymax = logloss + se), width = 2000) +
  geom_point(data = df_extrapolation, aes(y = logloss_pred), col = "blue", size = 2) +
  geom_line(data = df_extrapolation, aes(y = logloss_pred), col = "blue", linetype = "dashed") +
  geom_point(aes(y = logloss_pred), col = "red", size = 2) +
  geom_line(aes(y = logloss_pred), col = "red", linetype = "dashed")

predict(model, tibble(n = nrow(pulsar) * 0.9)) # 0.04194017

set.seed(123)
test_folds <- vfold_cv(pulsar, v = 10, repeats = 10, strata = Class)
rf_cv <- rf_wflow %>% fit_resamples(
  resamples = test_folds,
  metrics = metric_set(mn_log_loss)
)
collect_metrics(rf_cv) # 0.0419
