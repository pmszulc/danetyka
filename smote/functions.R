plot_results <- function(results, metrics, calibr = "No") {
  results %>% 
    filter(.metric %in% metrics) %>% 
    filter(calibration == calibr) %>% 
    mutate(Model = fct_recode(Model, "Weak model" = "Weak", "Strong model" = "Strong")) %>% 
    ggplot(aes(.metric, mean, col = SMOTE)) +
    geom_point(position = position_dodge(width = 0.3), size = 2) +
    geom_errorbar(aes(ymin = mean - std_err, ymax = mean + std_err),
      position = position_dodge(width = 0.3), width = 0.3, linewidth = 1) +
    facet_wrap(vars(Model), ncol = 2) +
    scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, by = 0.2)) +
    geom_hline(yintercept = seq(0, 1, by = 0.2), linetype = 2, alpha = 0.2) +
    see::scale_color_oi()
}


calc_perf <- function(threshold, pred, metric) {
  pred %>% 
    mutate(.pred_class = make_two_class_pred(.pred_1, levels(Y), 
      threshold = threshold)) %>% 
    group_by(id, id2) %>% 
    metric(Y, .pred_class) %>% 
    summarise(mean = mean(.estimate), std_err = sd(.estimate)/sqrt(n()))
}

find_threshold <- function(pred, target, metric) {
  thresholds <- seq(0, 1, by = 0.001)
  recall_thresholds <- future_map_dfr(thresholds, calc_perf, pred = pred, metric = metric,
      .progress = TRUE) %>% 
    mutate(threshold = thresholds, .before = 1)
  new_threshold <- recall_thresholds %>% 
    filter(mean >= target) %>% 
    slice_min(mean, with_ties = FALSE) %>% 
    pull(threshold)
  new_threshold
}

modify_threshold <- function(results, fit, model, metric_name) {
  # fit = np. rf_fit1_roc
  # model = c("Strong", "Weak")
  # metric_name = c("sens", "recall")
  metrics <- if (metric_name == "sens") c(sens, spec) else c(recall, precision)
  names <- if (metric_name == "sens") c("sens", "spec") else c("recall", "precision")
  target <- results %>% 
    filter(Model == model, SMOTE == "Yes", .metric == metric_name) %>% 
    pull(mean)
  pred <- collect_predictions(fit)
  new_thresh <- find_threshold(pred, target = target, metric = metrics[[1]])
  new_results <- map_dfr(metrics, calc_perf, threshold = new_thresh, pred = pred) %>% 
    mutate(.metric = names, SMOTE = "No", Model = model, calibration = "Yes")
  new_results %>% 
    mutate(new_threshold = new_thresh)
}

proportion_perf <- function(seed = 1, k_rm, data, wflow, param_info) {
  suppressMessages(require(themis))
  
  set.seed(seed)
  ind <- which(data$Y == "1")
  my_metrics <- metric_set(roc_auc, pr_auc)
  
  # jesli w ind_rm nic nie ma, wez cale dane
  if (k_rm > 0) {
    ind_rm <- sample(ind, k_rm)
    data <- dplyr::slice(data, -ind_rm)
  } 
  tune_folds <- vfold_cv(data, v = 3, repeats = 2, strata = Y)
  cv_folds <- vfold_cv(data, v = 10, repeats = 1, strata = Y)
  
  tune <- wflow %>% tune_bayes(
    resamples = tune_folds,
    param_info = param_info,
    initial = 5,
    iter = 5,
    metrics = metric_set(roc_auc)
  )
  fit <- wflow %>% 
    finalize_workflow(select_best(tune)) %>% 
    fit_resamples(
      resamples = cv_folds,
      metrics = my_metrics,
      control = control_resamples(save_pred = TRUE)
    )
  
  results <- fit %>% 
    collect_predictions() %>% 
    my_metrics(Y, .pred_1) %>% 
    select(-.estimator)
  results
}

proportion_perf_repeats <- function(k_rm, data, wflow, param_info, smote, repeats = 1) {
  seeds <- 1:repeats
  results <- future_map_dfr(seeds, proportion_perf, k_rm = k_rm, data = data, wflow = wflow, 
    param_info = param_info, .options = furrr_options(seed = TRUE))
  
  n <- nrow(data)
  ind <- which(data$Y == "1")
  k <- length(ind)
  prop <- (k - k_rm) / (n - k_rm)
  
  results <- results %>% 
    group_by(.metric) %>% 
    summarise(mean = mean(.estimate), std_err = sd(.estimate) / sqrt(n())) %>% 
    mutate(Proportion = prop, SMOTE = smote, .before = 1)
  results
}
