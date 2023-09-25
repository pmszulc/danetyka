library("tidyverse")
library("yardstick")
theme_set(ggpubr::theme_pubr(base_size = 13))
MSE <- function(y, y_est) mean((y - y_est)^2)

n <- 100
set.seed(1)
y <- rnorm(n)
err <- rnorm(n, sd = 0.1)
y_est1 <- y + err
y_est2 <- y + 1 + err
y_est3 <- -y + err
y_est4 <- -y + 4 + err
df <- tibble(
  y = rep(y, 4),
  y_est = c(y_est1, y_est2, y_est3, y_est4),
  model = rep(c("Model A", "Model B", "Model C", "Model D"), each = n)
)

ggplot(df, aes(y, y_est)) + 
  geom_point(size = 2, alpha = 0.6) + 
  geom_abline(slope = 1, col = "red", linewidth = 1) +
  facet_wrap(vars(model), ncol = 2) +
  labs(x = "Y", y = "Prognoza Y")

df %>% 
  group_by(model) %>% 
  summarise(
    R2 = cor(y, y_est)^2,
    R2_yardstick = yardstick::rsq_vec(y, y_est),
    R2mse = 1 - MSE(y, y_est)/MSE(y, mean(y)),
    R2mse_yardstick = yardstick::rsq_trad_vec(y, y_est),
    MAE = mean(abs(y - y_est))
  )
