library("tidyverse")
library("descr")
library("broom")
library("knitr")
theme_set(ggpubr::theme_pubr(base_size = 13))

galton <- read_csv2("galton.csv") %>% mutate(
  plec = as.factor(plec),
  plec = fct_recode(plec, K = "0", M = "1")
)

head(galton, 8)

# Model podstawowy

m_galton <- glm(plec ~ wzrost_dziecka, galton, family = "binomial")

galton <- galton %>% mutate(
  M_prob1 = predict(m_galton, type = "response"),
  plec_est1 = ifelse(M_prob1 > 0.5, "M", "K")
)
descr::crosstab(galton$plec_est1, galton$plec, prop.t = TRUE)
mean(galton$plec_est1 == galton$plec)
summary(m_galton)

# Zaleznosc plci i wzrostu rodzicow?

galton %>% 
  pivot_longer(c(wzrost_ojca, wzrost_matki), 
    names_to = "Rodzic", values_to = "Wzrost") %>% 
  mutate(Rodzic = fct_recode(Rodzic, "Ojciec" = "wzrost_ojca", 
    "Matka" = "wzrost_matki")) %>% 
  ggplot(aes(Wzrost, fill = plec)) +
  geom_density(alpha = 0.6) +
  facet_wrap(vars(Rodzic)) +
  labs(fill = "Płeć", y = "")

glm(plec ~ wzrost_ojca + wzrost_matki, galton, family = "binomial") %>% 
  summary() 

# Model rozszerzony

m_galton2 <- glm(plec ~ wzrost_dziecka + wzrost_ojca + wzrost_matki, galton, 
  family = "binomial")
summary(m_galton2)

galton <- galton %>% mutate(
  M_prob2 = predict(m_galton2, type = "response"),
  plec_est2 = ifelse(M_prob2 > 0.5, "M", "K")
)
descr::crosstab(galton$plec_est2, galton$plec, prop.t = TRUE) # mniej błędów
mean(galton$plec_est2 == galton$plec)
