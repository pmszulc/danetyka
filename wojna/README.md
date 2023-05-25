Jak długo trzeba grać w wojnę?
================

Będąc dzieckiem, nieraz grałem w karcianą wojnę, jak pewnie wielu z Was.
Nie przypominam sobie jednak, bym ukończył choć jedną rozgrywkę — gra
zdawała się ciągnąć w nieskończoność. Problem z wojną jest taki, że
jeśli przeciwnik zaczyna mieć mało kart, zwykle zostają mu mocne, przez
co zaczyna zabierać nasze — i tak w kółko. Tzn. problemów jest
oczywiście więcej, choćby taki, że nic w tej grze od nas nie zależy.
Jest z jednej strony całkowicie losowa (rozdanie kart), z drugiej
całkowicie deterministyczna (wynik jest funkcją rozdania). Tzn. tak mi
się wydawało…

## Motywacja

Grałem ostatnio w wojnę ze swoim dzieckiem i zastanawiałem się, czy to
się kiedyś skończy. Graliśmy w uproszczoną wersję: tylko pięć różnych
kart, ale więcej powtórzeń, żeby “wojna” była częściej. Obstawiałem, że
mimo tego uproszczenia, będzie trwało to wieki, także ustaliliśmy, że
skończymy, jak coś tam się wydarzy.

Później stwierdziłem, że ciekawe byłoby policzyć, czy to naprawdę trwa
wieki.

## Monte Carlo

Metoda Monte Carlo jest w pewnym sensie trochę uwłaczająca ludzkiemu
intelektowi. Okazuje się, że w niektórych sytuacjach, zamiast szukać
analitycznych rozwiązań problemów, rozsądniej jest zrobić coś miliard
razy i zobaczyć, jak często się udało. Dziecinada.

Natomiast uwielbiam tę metodę. Jak pomyślałem o tym, że ciekawe byłoby
się przekonać, ile średnio trwa wojna — i natychmiast uświadomiłem
sobie, że bardzo łatwo to oszacować, poczułem jakiś rodzaj wyższej
przyjemności, ciężkiej do opisania.

Dodam, że zawsze traktowałem tę metodę jako sposób na szacowanie
prawdopodobieństw w przypadku, gdy obliczenia analityczne byłyby zbyt
złożone (choć oczywiście zastosowania są szersze). Ale w pewnym sensie
to po prostu analiza danych, tyle że zamiast je zbierać, sami je
generujemy. Wrócę do tej myśli pod koniec.

A teraz wróćmy do wojny, bo muszę przyznać, że wyniki mnie zaskoczyły.

## Założenia

Przyjąłem, że gramy w dwie osoby talią 52 kart (bez jokerów). Musiałem
założyć jakieś czasy trwania pojedynków, tzn. wyłożenia kart, porównania
ich i zabrania. Do tego dochodzą “wojny”. Zagrałem parę rozdań i wyszło
mi, że zwykły pojedynek (bez wojny) trwa ok. 4 sekund, a jeśli zakończy
się wojną, w sumie 11 sekund (najwięcej zabiera odwrócenie kart na drugą
stronę). Wojna może być dłuższa, gdy znów jest remis, ale przyjąłem, że
taka sytuacja jest na tyle rzadka, że nie będę jej uwzględniał
(niestety, tak napisałem kod, że notowanie tej informacji wymagałoby
większych modyfikacji). Im gra jest dłuższa, tym te czasy mogą się
zmieniać, ale zignorowałem ten fakt (założyłem, że gramy jak roboty). Bo
z jednej strony z powodu zmęczenia gra może zwolnić, ale z drugiej z
racji znudzenia możemy chcieć szybko skończyć.

Gra trwa do czasu, gdy ktoś straci wszystkie karty. Założyłem, że jeśli
jest wojna i brakuje nam karty do wyłożenia, to też przegrywamy (choć
nie pamiętam, czy tak się grało ;)). Teoretycznie może wystąpić remis:
gracze mają tyle samo kart i cały czas jest wojna. W takiej sytuacji,
dla talii 52 kart, każdemu będzie brakować ostatniej, by tę wojnę
rozstrzygnąć — i zakładam, że mamy wtedy remis. Jest to BARDZO mało
prawdopodobne: gracze muszą mieć co drugą kartę taką samą. Ale to też
mnie interesowało, czy jest realne, by taka sytuacja zdarzyła się choć
raz, gdybym grał np. kilka razy dziennie przez całe życie.

## Sposób odkładania kart

Jest jeszcze jedno założenie, przez które zacząłem żałować, że w ogóle
zająłem się tym tematem… Jak wygramy zwykły pojedynek lub wojnę, w jaki
sposób zbieramy karty i kładziemy pod spód? Tzn. to, że pod spód, to
jasne, ale w jakiej kolejności?

Okazało się, że ma to ogromne znaczenie. Póki co przedstawiam wyniki w
sytuacji, gdy najpierw odkładamy swoje karty. Tzn. tak naprawdę nie ma
znaczenia, czy swoje, czy przeciwnika: ważne, że zawsze albo wygranego,
albo przegranego. Można jednak podejść do tego inaczej. Później pokażę
wyniki dla dwóch innych sytuacji: najpierw odkładamy karty ustalonego
gracza (nieważne, czy wygrał pojedynek) lub karty odkładamy losowo
(czasem zdarzy się nam odłożyć jako pierwszą kartę przeciwnika, czasem
naszą).

## Wyniki

Wykonałem milion symulacji, poniżej rozkład czasów trwania całej
rozgrywki (w minutach, skala logarytmiczna).

<img src="unnamed-chunk-4-1.png" style="width:70.0%"
data-fig-align="center" />

Przeciętnie cała gra trwa od 10 do 28 minut (rozstęp kwartylowy),
średnia arytmetyczna 22 minuty, 96% rozgrywek kończy się przed upływem
godziny. Najdłuższa trwała 4 godziny.

Szczerze mówiąc, spodziewałem się znacznie dłuższych czasów. Cóż, gdy
jest się dzieckiem, czas biegnie inaczej — może tu należy szukać
wyjaśnienia. Poza tym, te założone przeze mnie czasy pojedynków są
pewnie dłuższe u dzieci. Natomiast jak się okaże, być może to nie jest
tylko kwestia poczucia czasu.

## Remisy

A jaka jest szansa na remis? W moim milionie symulacji taka sytuacja nie
zdarzyła się ani razu, w takim razie na pewno jest rzadka. Chciałem
jednak lepiej to oszacować. Problem w tym, że zwiększanie liczby
symulacji niewiele dało — tzn. przekonałem się jedynie, że jest to
jeszcze rzadsze. W końcu jednak symulacje zaczęły trwać tak długo, że
musiałem zrezygnować z tego podejścia (i całe szczęście).

Być może da się to policzyć analitycznie, ale jak zacząłem o tym myśleć,
rozbolała mnie głowa. Wiadomo, że remisy wystąpią, jeśli co druga karta
jest taka sama. Łatwo policzyć, jakie jest prawdopodobieństwo, że tak
się rozłożą karty od razu po rozdaniu. Ale trzeba jeszcze uwzględnić
wszystkie przypadki, które zbiegają do tego rozkładu…

Podszedłem do tego w następujący sposób. Im mniejsza talia kart, tym
remisy są bardziej prawdopodobne. Wykonam obliczenia dla 12 kart, 16,
20, itd. (chcę mieć cztery kolory, stąd wielkość talii dzieli się przez
cztery). Najpewniej będzie dało się zauważyć pewną zależność i
przedłużając ją, oszacuję wynik dla 52 kart.

Dodam, że dla niewielkich wielkości talii można rozpatrywać wszystkie
możliwe permutacje (zamiast je losować), ale wyszło mi, że już dla 16
jest ich ponad 30 milionów (mimo że wziąłem pod uwagę tylko unikalne
permutacje pod względem starszeństwa kart i nie odróżniałem pierwszego
gracza od drugiego).

Poniżej szacowane prawdopodobieństwa remisu dla różnych wielkości talii
(oś Y w skali logarytmicznej). Zwiększyłem liczbę symulacji do minimum
10 milionów, dla większej liczby kart nawet do 100 milionów (bo
prawdopodobieństwa stają się bardzo małe).

<img src="unnamed-chunk-6-1.png" style="width:70.0%"
data-fig-align="center" />

Widać, że nie jest to przypadkowa relacja, rządzi nią jakiś wzór.
Dopasowałem do danych model regresji. Podszedłem do tego dość prosto:
ponieważ dla zlogarytmowanego prawdopodobieństwa widać lekki łuk,
przyjąłem model postaci `log(p) ~ n + n^2`. Jak widać niżej, taka
funkcja niemal idealnie przechodzi przez wszystkie punkty (zaznaczyłem
ją na czerwono).

<img src="unnamed-chunk-8-1.png" style="width:70.0%"
data-fig-align="center" />

Dokonując ekstrapolacji, prawdopodobieństwo remisu dla 52 kart to mniej
więcej jeden na 20 biliardów. Żeby wartość oczekiwana liczby remisów
wyniosła 1, pięć milionów par ludzi musiałoby grać codziennie po 100
razy przez 100 lat.

## Pętle

Przy okazji zorientowałem się, że jest jeszcze jeden rodzaj remisu —
pętla. Karty tak mogą się ułożyć, że ich rozkład powtarza się co ileś
pojedynków. Z jakiegoś powodu taka sytuacja zdarzała mi się tylko dla 20
kart (ok. 2500 razy na 10 milionów symulacji).

Na wykresie i do budowy modelu nie uwzględniałem tych przypadków, bo
zawyżały liczbę remisów (widać było, że punkt dla 20 kart jest trochę za
wysoko).

## Wpływ sposobu odkładania kart

Większym odkryciem dla mnie było jednak to, jak bardzo na wyniki wpływa
sposób, w jaki odkładamy karty pod spód talii. Jak pisałem,
dotychczasowe wyniki zakładają, że stosujemy strategię “najpierw
wygrany” (tzn. jeśli wygraliśmy pojedynek, pierwsze pod spód wędrują
nasze karty) albo “najpierw przegrany” (wyniki są takie same). Problem w
tym, że możemy podejść do tego inaczej i to naprawdę zmienia ogólny
obraz gry.

Po pierwsze, jeśli będziemy robić to losowo, gra wcale nie jest funkcją
rozdania (przestaje być deterministyczna, jak określiłem ją wcześniej).
Nie są też możliwe pętle. Co jednak ciekawsze, wydłuża to średni czas
gry z 22 do 32 minut!

To jeszcze nic. Możemy stosować strategię, że zawsze jako pierwsze
zbieramy karty jednego z graczy. Nieważne którego, tylko że niezależnie
od tego, kto wygrał pojedynek, pod spód kładziemy jako pierwsze karty
np. gracza nr 1. Wtedy średnia długość gry rośnie aż do 112 minut (IQR
62-156 min). O ile w ogóle się skończy, bo w ponad 80% przypadków
wystąpiła pętla!

Dodam, że pętlę identyfikuję w taki sposób, że ustalam maksymalną liczbę
iteracji gry na 10 tysięcy. Jeśli dochodzę do tego wyniku, uznaję, że
wystąpiła pętla. Sprawdziłem, że to jest w porządku (maksymalna liczba
iteracji dla skończonych gier to 6033; poza tym podniesienie limitu do
100 tysięcy nic nie zmienia).

Poniżej rozkłady dla wszystkich trzech strategii (bez pętli).

<img src="unnamed-chunk-11-1.png" style="width:70.0%"
data-fig-align="center" />

Czyli być może to moje wspomnienie, że gra w wojnę ciągnie się
nieskończoność, ma jakieś solidniejsze podstawy?

Pytanie tylko, jaką strategię odkładania kart zwykle się stosuje?
Przypuszczam, że żadną z nich. Raczej coś pomiędzy losowością a opcją
“najpierw wygrany/przegrany”. Z pewnością też każdy z graczy robi to
inaczej.

Widać jednak, że jesteśmy w stanie wpłynąć na długość gry. Nie
wspominając o tym, że jeśli ktoś ma bardzo dobrą pamięć do kart, to
odkładając je w odpowiedni sposób (tzn. raz tak, raz inaczej), można
zwiększyć prawdopodobieństwo wygranej.

## Analiza danych

Jak pisałem, na cały opisany tutaj proces można spojrzeć jak na analizę
danych, tyle że sami je generujemy. Odczułem to szczególnie, gdy
zastanawiałem się, w jaki sposób podsumować wyniki: czy np. lepsza
będzie mediana, czy średnia arytmetyczna. Ostatecznie zacząłem od
podania rozstępu kwartylowego. Jest to moja ulubiona miara
PRZECIĘTNOŚCI. Podkreślam to słowo dlatego, że zwykle IQR traktuje się
jako miarę rozrzutu. W publikacjach naukowych często zastępuje
odchylenie standardowe, gdy dane są skośne. Natomiast ja lubię myśleć o
przeciętności szerzej. Dobry przykład to wzrost. Jeśli podzielimy ludzi
na niskich, przeciętnych i wysokich, to przecież do tej drugiej
kategorii nie wrzucimy tylko osób o jednym, konkretnym wzroście (np.
równym medianie). Rozsądniej jako niskie traktować osoby z pierwszego
kwartyla, a wysokie z czwartego.

Druga sprawa, to czy lepsza w podsumowaniu jest tu mediana, czy średnia?
Dane są skośne, więc automatycznie kierujemy się w stronę mediany. I
ogólnie takie podejście jest zwykle dobre, natomiast tutaj można podać
argumenty za średnią. Nie w sensie, że powinna zastąpić medianę —
przecież możemy liczyć tyle miar, ile nam się podoba. Ale średnia
przekazuje tu naprawdę interesującą informację. Jeśli chcemy zagrać pięć
razy, ile czasu to może zająć? Ile czasu zmarnuję, grając w wojnę
codziennie? W odpowiedzi na te pytania nie pomoże mediana, ale właśnie
średnia. Skoro jedna gra trwa średnio 22 minuty, to pięć powinno zająć
mniej niż 2 godziny.

Średnia uwzględnia, że niektóre gry mogą być znacznie dłuższe. I jeśli
interesuje nas suma, jest to pożądana cecha średniej. Tym bardziej, im
więcej składników ma suma (bo zwiększa się szansa, że wystąpią te
większe wartości, w tym ekstremalne).

## To tyle

Zabierając się za ten temat, myślałem, że to będzie krótki wpis na
bloga, ale nie wyszło. Gdyby ktoś chciał poeksperymentować, cały kod
dostępny tutaj.

<!-- ## Backup -->
<!-- ### Sprawdzenie -->
<!-- ```{r} -->
<!-- # najkrotszy pojedynek -->
<!-- wyniki_df %>% -->
<!--   arrange(kroki) -->
<!-- # spr. -->
<!-- n <- 52 -->
<!-- id <- 1 -->
<!-- rozgrywka(id, n) -->
<!-- set.seed(id) -->
<!-- karty <- sample(rep(1:(n/4), each = 4)) -->
<!-- gracz1 <- karty[1:(n/2)] -->
<!-- gracz2 <- karty[(n/2 + 1):n] -->
<!-- i <- 0 -->
<!-- wynik <- pojedynek(gracz1, gracz2) -->
<!-- gracz1 <- wynik$gracz1 -->
<!-- gracz2 <- wynik$gracz2 -->
<!-- if (length(gracz1) == 0 & length(gracz2) == 0) { -->
<!--   return(c(seed, NA, i)) # remis po "i" krokach -->
<!-- } else if (length(gracz1) == 0) { -->
<!--   return(c(seed, 2, i)) # wygral gracz 2 po "i" krokach -->
<!-- } else if (length(gracz2) == 0) { -->
<!--   return(c(seed, 1, i)) -->
<!-- } -->
<!-- gracz1; gracz2 -->
<!-- i <- i + 1 -->
<!-- ``` -->
<!-- ### Permutacje -->
<!-- Dla malej liczby kart można rozważyć wszystkie unikalne permutacje. Niestety już dla n=16 jest ich pond 30 mln. -->
<!-- ```{r} -->
<!-- library("RcppAlgos") -->
<!-- k <- 4 -->
<!-- n <- k * 4 # talia -->
<!-- max <- 1e5 # maksymalna dlugosc pojedynku -->
<!-- karty <- permuteGeneral(v = 1:k, freq = rep(4, k)) -->
<!-- karty <- karty[1:(nrow(karty)/2), ] # wystarczy polowa -->
<!-- N <- nrow(karty) -->
<!-- id <- 1:N -->
<!-- wyniki <- future_map(id, ~ rozgrywka_permut(., karty), .progress = TRUE,  -->
<!--   .options = furrr_options(seed = TRUE)) -->
<!-- wyniki_df <- tibble( -->
<!--   zwyciezca = map_vec(wyniki, ~ .[2]), -->
<!--   kroki = map_vec(wyniki, ~ .[3]) -->
<!-- ) -->
<!-- # remisy? -->
<!-- k <- wyniki_df %>% -->
<!--   filter(is.na(zwyciezca)) %>%  -->
<!--   nrow() -->
<!-- k -->
<!-- k/N -->
<!-- # 0.07370851 -->
<!-- ``` -->
<!-- ### Pętle -->
<!-- ```{r} -->
<!-- # petla dla 20 kart: -->
<!-- # rozdanie: -->
<!-- # 5 1 2 1 3 4 1 3 4 4 -->
<!-- # 4 2 2 5 5 2 5 3 3 1 -->
<!-- # petla: -->
<!-- # 4 2 4 2 4 1 -->
<!-- # 3 5 1 5 2 5 3 3 3 1 5 2 4 1 -->
<!-- # po 16 krokach to samo -->
<!-- ``` -->
