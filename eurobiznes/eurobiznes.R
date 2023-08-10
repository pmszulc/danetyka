# Uwagi do kodu:

# - Poniewaz chodzimy w kolko, po polu 40 nastepuje 1, nie 41 (dlatego dziele
# modulo 40). Trzeba jeszcze uwazac, bo 40 %% 40 = 0, wiec pozycje 0 nalezy
# zmienic na 40.

# - Tworze 40-elementowy wektor wypelniony zerami i jesli stane np. na polu 10,
# zwiekszam dziesiaty element tego wektora o 1.

# - Kod nie jest napisany optymalnie, nacisk zostal polozony na czytelnosc.

library("tidyverse")
theme_set(ggpubr::theme_pubr(base_size = 13))

## Czesc I, bez uwzglednienia pol zmieniajacych pozycje

N <- 1e7 # liczba symulacji
pola <- numeric(40) # tu zapiszemy, jak czesto stanelismy na danym polu
pozycja <- 1 # poczatkowa pozycja (start)
pola[1] <- 1
for (i in 1:N) {
  rzut1 <- sample(1:6, 2, replace = TRUE)
  if (rzut1[1] != rzut1[2]) {
    pozycja <- pozycja + sum(rzut1)
  } else { 
    rzut2 <- sample(1:6, 2, replace = TRUE)
    if (rzut2[1] != rzut2[2]) {
      pozycja <- pozycja + sum(rzut1) + sum(rzut2)
    } else {
      pozycja <- 11 # idziesz do wiezienia
    }
  }
  pozycja <- pozycja %% 40
  if (pozycja == 0) pozycja <- 40 # uwaga na 40 %% 40
  pola[pozycja] <- pola[pozycja] + 1
}

df <- tibble(Pole = 1:40, Prawdopodobieństwo = pola/N)
kolor <- rep("zwykły", 40)
kolor[11] <- "idziesz do więzienia"
df$kolor <- kolor

ggplot(df, aes(Pole, Prawdopodobieństwo, fill = kolor)) +
  geom_col() +
  scale_fill_manual(values = c("grey40", "grey70")) +
  scale_x_continuous(breaks = seq(1, 40, by = 3)) +
  theme(legend.position = "none")


## Czesc II

# Funkcja zmieniajaca pozycje
zmien_pozycje <- function(p) {
  p <- p %% 40
  if (p == 0) {
    p <- 40
  } else if (p == 31) { # idziesz do wiezienia
    p <- 11
  } else if (p %in% c(3, 18, 34)) { # niebieska karta
    # z pewnym prawdop. zostan na polu albo zmien pozycje:
    p <- sample(c(p, 1, 11, 40), 1, prob = c(13/16, 1/16, 1/16, 1/16))
  } else if (p %in% c(8, 23, 37)) { # czerwona karta
    p <- sample(c(p, 1, 7, 11, 15, 24, 36, p-3), 1, prob = c(9/16, rep(1/16, 7)))
  }
  return(p)
}

N <- 1e7
pola <- numeric(40)
pozycja <- 1
pola[1] <- 1
for (i in 1:N) {
  rzut1 <- sample(1:6, 2, replace = TRUE)
  if (rzut1[1] != rzut1[2]) {
    pozycja <- pozycja + sum(rzut1)
  } else { 
    rzut2 <- sample(1:6, 2, replace = TRUE)
    if (rzut2[1] != rzut2[2]) {
      pozycja <- pozycja + sum(rzut1) + sum(rzut2)
    } else {
      pozycja <- 11
    }
  }
  pozycja <- zmien_pozycje(pozycja)
  pola[pozycja] <- pola[pozycja] + 1
}

df2 <- tibble(Pole = 1:40, Prawdopodobieństwo = pola/N)
kolor <- rep("zwykły", 40)
kolor[c(3, 18, 34)] <- "niebieski"
kolor[c(8, 23, 37)] <- "czerwony"
kolor[11] <- "idziesz do więzienia"
df2$kolor <- kolor

panstwo <- rep("inne", 40)
panstwo[c(2, 4)] <- "grecja"
panstwo[c(7, 9, 10)] <- "wlochy"
panstwo[c(12, 14, 15)] <- "hiszpania"
panstwo[c(17, 19, 20)] <- "anglia"
panstwo[c(22, 24, 25)] <- "benelux"
panstwo[c(27, 28, 30)] <- "szwecja"
panstwo[c(32, 33, 35)] <- "rfn"
panstwo[c(38, 40)] <- "austria"
df2$panstwo <- panstwo

ggplot(df2, aes(Pole, Prawdopodobieństwo, fill = kolor)) +
  geom_col() +
  scale_x_continuous(breaks = seq(1, 40, by = 3)) +
  scale_fill_manual(values = c( "firebrick2", "grey40", "dodgerblue", "grey70")) +
  theme(legend.position = "none")

arrange(df2, desc(Prawdopodobieństwo))
summarise(df2, prawdop = sum(Prawdopodobieństwo), .by = panstwo) %>% 
  arrange(desc(prawdop)) %>% 
  mutate(prawdop = round(100*prawdop, 1))

