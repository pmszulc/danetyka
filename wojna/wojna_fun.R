pojedynek <- function(gracz1, gracz2, sposob) {
  n1 <- length(gracz1)
  n2 <- length(gracz2)
  czy_wojna <- 0
  
  # najpierw wygrany
  karty_do_zabrania1 <- c(gracz1[1], gracz2[1])
  karty_do_zabrania2 <- c(gracz2[1], gracz1[1])
  
  if (sposob == "najpierw_przegrany") {
    temp <- karty_do_zabrania1
    karty_do_zabrania1 <- karty_do_zabrania2
    karty_do_zabrania2 <- temp
  } else if (sposob == "losowo") {
    karty_do_zabrania1 <- sample(karty_do_zabrania1)
    karty_do_zabrania2 <- sample(karty_do_zabrania2)
  } else if (sposob == "zawsze_gracz1") {
    karty_do_zabrania2 <- karty_do_zabrania1
  }
  
  if (gracz1[1] > gracz2[1]) {
    gracz1 <- c(gracz1, karty_do_zabrania1)[-1]
    gracz2 <- gracz2[-1]
    
  } else if (gracz1[1] < gracz2[1]) {
    gracz2 <- c(gracz2, karty_do_zabrania2)[-1]
    gracz1 <- gracz1[-1]
    
  } else {
    wynik <- wojna(gracz1, gracz2, n1, n2, sposob)
    gracz1 <- wynik$gracz1
    gracz2 <- wynik$gracz2
    czy_wojna <- 1
  }
  return(list(gracz1 = gracz1, gracz2 = gracz2, czy_wojna = czy_wojna))
}

wojna <- function(gracz1, gracz2, n1, n2, sposob) {
  
  # jesli kogos "nie stac" na wojne (n1 < 3), przegrywa
  if (n1 < 3) {
    gracz1 <- integer(0)
    return(list(gracz1 = gracz1, gracz2 = gracz2))
  } else if (n2 < 3) {
    gracz2 <- integer(0)
    return(list(gracz1 = gracz1, gracz2 = gracz2))
  } 
  # patrzymy na 3. karte, ewentualnie 5., 7. itd.
  ind_all <- seq(3, min(n1, n2), by = 2)
  
  # szukamy pierwszego indeksu, dla ktorego nie ma rownosci
  ind <- which(gracz1[ind_all] != gracz2[ind_all])
  if (length(ind) == 0) {
    # nie znalezlismy takiego -> wojna do konca
    if (n1 == n2) {
      # remis
      gracz1 <- integer(0)
      gracz2 <- integer(0)
    } else if (n1 > n2) {
      # gracz2 nie ma kart, przegrywa
      gracz2 <- integer(0)
    } else {
      gracz1 <- integer(0)
    }
    
  } else {
    ind <- ind_all[ind[1]]
    karty_do_zabrania1 <- c(gracz1[1:ind], gracz2[1:ind])
    karty_do_zabrania2 <- c(gracz2[1:ind], gracz1[1:ind])
    
    if (sposob == "najpierw_przegrany") {
      temp <- karty_do_zabrania1
      karty_do_zabrania1 <- karty_do_zabrania2
      karty_do_zabrania2 <- temp
    } else if (sposob == "losowo") {
      karty_do_zabrania1 <- sample(karty_do_zabrania1)
      karty_do_zabrania2 <- sample(karty_do_zabrania2)
    } else if (sposob == "zawsze_gracz1") {
      karty_do_zabrania2 <- karty_do_zabrania1
    }
    
    if (gracz1[ind] > gracz2[ind]) {
      gracz1 <- c(gracz1, karty_do_zabrania1)[-(1:ind)]
      gracz2 <- gracz2[-(1:ind)]
    } else {
      gracz2 <- c(gracz2, karty_do_zabrania2)[-(1:ind)]
      gracz1 <- gracz1[-(1:ind)]
    }
  }
  return(list(gracz1 = gracz1, gracz2 = gracz2))
}

rozgrywka <- function(id, n, sposob) {
  # sposob = w jaki sposob odkladamy karty pod spod:
  # c("losowo", "najpierw_wygrany", "najpierw_przegrany", "zawsze_gracz1")
  set.seed(id)
  karty <- sample(rep(1:(n/4), each = 4))
  gracz1 <- karty[1:(n/2)]
  gracz2 <- karty[(n/2 + 1):n]
  ile_wojen <- 0
  
  for (i in 1:max) {
    wynik <- pojedynek(gracz1, gracz2, sposob)
    gracz1 <- wynik$gracz1
    gracz2 <- wynik$gracz2
    ile_wojen <- ile_wojen + wynik$czy_wojna
    if (length(gracz1) == 0 & length(gracz2) == 0) {
      return(c(id, NA, i, ile_wojen)) # remis po "i" krokach
    } else if (length(gracz1) == 0) {
      return(c(id, 2, i, ile_wojen)) # wygral gracz 2 po "i" krokach
    } else if (length(gracz2) == 0) {
      return(c(id, 1, i, ile_wojen))
    }
  }
  return(c(id, NA, i, ile_wojen)) # petla = remis
}

rozgrywka_permut <- function(id, karty) {
  
  gracz1 <- karty[id, 1:(n/2)]
  gracz2 <- karty[id, (n/2 + 1):n]
  ile_wojen <- 0
  
  for (i in 1:max) {
    wynik <- pojedynek(gracz1, gracz2)
    gracz1 <- wynik$gracz1
    gracz2 <- wynik$gracz2
    ile_wojen <- ile_wojen + wynik$czy_wojna
    if (length(gracz1) == 0 & length(gracz2) == 0) {
      return(c(id, NA, i, ile_wojen)) # remis po "i" krokach
    } else if (length(gracz1) == 0) {
      return(c(id, 2, i, ile_wojen)) # wygral gracz 2 po "i" krokach
    } else if (length(gracz2) == 0) {
      return(c(id, 1, i, ile_wojen))
    }
  }
  return(c(id, NA, i, ile_wojen)) # petla = remis
}
