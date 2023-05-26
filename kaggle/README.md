
## Kaggle

Krótkie wyjaśnienie dla tych, którzy nie znają strony
[kaggle.com](https://www.kaggle.com/). Co jakiś czas są tam organizowane
turnieje, kto zbuduje najlepszy model ML prognozujący jakąś cechę.
Nagrodą może być satysfakcja, uznanie, ale też [milion
dolarów](https://www.kaggle.com/competitions/passenger-screening-algorithm-challenge/overview).
Także jest się o co bić. Najważniejsze jednak, z dydaktycznego punktu
widzenia, że na takich turniejach, w stosunkowo krótkim czasie, można
się mocno podszkolić w metodach uczenia maszynowego. Wynika to z różnych
czynników, między innymi z dużej motywacji, która utrzymuje się zwykle
przez cały czas trwania turnieju.

Poniżej prezentuję mój model, który okazał się
[najlepszy](https://www.kaggle.com/competitions/playground-series-s3e10/leaderboard)
w przewidywaniu, czy dany obiekt astronomiczny to pulsar (w skrócie:
pulsar go gwiazda, która bardzo szybko rotuje i wysyła mnóstwo
promieniowania).

## Dane i dodatkowe cechy

``` r
library("tidyverse")
library("tidymodels")
library("mgcv")
library("doParallel")
#theme_set(ggpubr::theme_pubr(base_size = 13))
library("ggdark") # install_github("nsgrantham/ggdark")

all_cores <- parallel::detectCores(logical = FALSE)
cl <- makePSOCKcluster(all_cores)
registerDoParallel(cl)

pulsar <- read_csv("data/train.csv") %>% 
  mutate(Class = as.factor(Class))
glimpse(pulsar)
```

    Rows: 117,564
    Columns: 10
    $ id                   <dbl> 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,…
    $ Mean_Integrated      <dbl> 133.17188, 87.09375, 112.64062, 120.67969, 134.07…
    $ SD                   <dbl> 59.71608, 36.25797, 39.81839, 45.91845, 57.72011,…
    $ EK                   <dbl> 0.04313292, 0.43546892, 0.37963873, -0.09849016, …
    $ Skewness             <dbl> -0.7033835, 2.2660570, 0.9223061, 0.0117754, -0.5…
    $ Mean_DMSNR_Curve     <dbl> 54.917224, 3.417224, 2.730769, 2.696488, 1.107860…
    $ SD_DMSNR_Curve       <dbl> 70.08444, 21.86507, 15.68969, 20.95466, 11.25505,…
    $ EK_DMSNR_Curve       <dbl> 0.7497980, 7.0393303, 8.1934710, 8.1838740, 16.10…
    $ Skewness_DMSNR_Curve <dbl> -0.6495121, 52.6862514, 85.6497849, 70.3328988, 3…
    $ Class                <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0…

Jak widać wyżej, obserwacji jest sporo (ponad 100 tysięcy), natomiast
mamy tylko 8 zmiennych, przy pomocy których musimy przewidzieć, czy dana
gwiazda to pulsar (zmienna `Class`). Zwykle jednak w takich problemach
cechy, które są dostępne, to tylko punkt wyjścia, i na ich podstawie
tworzy się nowe, czasem kilkadziesiąt i więcej. I nierzadko jest to
najważniejsza część budowy modelu, tzn. jeśli chcemy, żeby był
najlepszy, musimy stworzyć lepsze cechy, niż inni.

W przypadku tych danych było inaczej. Stworzyłem jedynie dwie dodatkowe
cechy, na dodatek mam wątpliwości, czy były one potrzebne. Czemu nie
więcej? Bo te dostępne są po pierwsze bardzo silne, po drugie nie są to
pierwotne informacje z obserwacji gwiazd, ale już w pewien sposób
zagregowane.
[Tutaj](https://www.kaggle.com/competitions/playground-series-s3e10/discussion/393007)
jest więcej na ten temat. W skrócie, gwiazdę obserwuje się przez jakiś
czas, tworząc jej profil (ja zmienia się natężenie promieniowania),
który wyglądem przypomina rozkład (funkcję gęstości). Następnie
podsumowuje się go, licząc średnią, odchylenie standardowe, skośność i
kurtozę. I okazuje się, że to, czy gwiazda jest pulsarem, zależy
praktycznie tylko od tych parametrów. Także trzeba jedynie zaproponować
odpowiednią postać tej relacji.

Te dwie cechy, które stworzyłem, miały naśladować [test
Jarque-Bera](https://en.wikipedia.org/wiki/Jarque%E2%80%93Bera_test) na
normalność. Bazuje on tylko na skośności i kurtozie. Jaki jest sens
dodawania czegoś takiego? Myślałem następująco. Skoro konkretnie taka
kombinacja tych zmiennych, z taką transformacją (w teście podnosi się do
kwadratu) ma zastosowanie statystyczne, to jest to jakaś przesłanka, że
informacja, którą test niesie, może przydać się w innym miejscu (np. w
naszym modelu). Oczywiście jest to dość słaba przesłanka, ale ponieważ
dorzucenie takich zmiennych nic nie kosztuje (przy tylu obserwacjach),
warto spróbować. W praktyce często dodaje się mnóstwo zmiennych, które
są prostymi kombinacjami wyjściowych (średnia, iloraz itp.), bez żadnego
zastanowienia, czy ma to jakiekolwiek teoretyczne uzasadnienie. Najwyżej
później się z nich zrezygnuje, jeśli sprawdzimy, że nie wnoszą nic do
modelu.

Te dodane przeze mnie zmienne okazały się istotne w jednym z modeli,
których użyłem, ale to może też być kwestia tego, że po prostu warto
było uwzględnić kwadrat skośności i kurtozy, a nie akurat test
Jarque-Bera (dlatego pisałem wyżej, że nie jestem przekonany, czy warto
było to robić).

Poniżej wszystkie operacje, jakie wykonałem na danych, zanim zacząłem
budować model. Choć zaznaczę, że na część z nich zdecydowałem się
później, jak już miałem zbudowane wstępne modele.

``` r
make_data <- function(data) {
  data <- data %>% 
    rename(Mean = "Mean_Integrated", Skewness = "EK", EK = "Skewness",
      Mean_curve = "Mean_DMSNR_Curve", SD_curve = "SD_DMSNR_Curve",
      Skewness_curve = "EK_DMSNR_Curve", EK_curve = "Skewness_DMSNR_Curve") %>% 
    mutate(
      Skewness = log(Skewness + 3),
      EK = log(EK + 2),
      Mean_curve = log(log(Mean_curve + 2)),
      Skewness_curve = log(Skewness_curve + 4),
      EK_curve = log(EK_curve + 8)
    ) %>%
    mutate(
      JB_test = log(Skewness^2 + 1/4*EK^2),
      JB_test_curve = log(Skewness_curve^2 + 1/4*EK_curve^2)
    )
  return(data)
}
pulsar <- make_data(pulsar)
```

Zmiana nazw zmiennych może wydawać się śmieszna, natomiast ten krok może
zaoszczędzić dużo czasu, jeśli nowe nazwy są krótsze i bardziej
intuicyjne. W końcu będę je podawał setki razy! Na dodatek okazało się,
że w tych danych pomylono kurtozę ze skośnością (ma to znacznie w teście
Jarque-Bera).

Większość zmiennych logarytmuję, bo są silnie prawostronnie skośne.

## Dodatkowe modele

Poniżej dwa modele, które teoretyczne mogłyby być ostatecznymi, ale jak
zobaczymy później, użyłem ich tylko jako dodatkowe cechy w ogólniejszym
modelu.

### LASSO

Pierwszy model to regresja logistyczna. Dorzucam kwadrat każdej zmiennej
oraz interakcje. Część z nich pewnie niepotrzebnie — dlatego korzystam z
[LASSO](https://en.wikipedia.org/wiki/Lasso_(statistics)), które powinno
zredukować współczynniki przy nieważnych zmiennych do zera. Dodatkowo
jest to zabezpieczenie przez bardzo dużą współliniowością, której się tu
spodziewam.

Za karę w LASSO przyjąłem 0.0000418. Tę wartość otrzymywałem z
kroswalidacji, minimalizuje ona metrykę [log
loss](https://towardsdatascience.com/intuition-behind-log-loss-score-4e0c9979680a).
Bo to właśnie ta metryka rozstrzygała, który model w tym turnieju jest
najlepszy.

Być może jest to zaskakujące, że dość luźno podchodzę do budowy tego
modelu. Tzn. bez głębszego zastanowienia dorzucam kwadraty i interakcje,
a potem nie analizuję wyników, czy aby na pewno wszystkie człony są
potrzebne, ewentualnie czy nie warto dodać jakiejś interakcji trzeciego
rzędu albo sześcianu jakiejś zmiennej. Po pierwsze, kod, który
prezentuję, to oczywiście tylko podsumowanie mojej pracy. W
rzeczywistości napisałem go ZNACZNIE więcej (próbowałem różnych podejść,
modeli itd.). Ale jest jeszcze inne wyjaśnienie. Akurat na tym modelu
(regresja logistyczna) aż tak mi nie zależy, bo jak później zobaczymy,
pełni on jedynie pomocniczą rolę. I może nawet być nadmiernie dopasowany
do danych, nie jest to problemem.

Mimo wszystko jednak stosuję LASSO, a nie zwykłą regresję, także jakąś
kontrolę nad tym mam. Robię to dlatego (tzn. stosuję LASSO), że niewiele
mnie to kosztuje czasu: wystarczy w funkcji `set_engine()` zmienić
parametr na `glmnet` oraz przy pomocy kroswalidacji wybrać odpowiednią
karę (to już zajmuje trochę więcej czasu, ale wciąż relatywnie
niewiele). Ten koszt jest ważny, bo na budowę modelu mamy ograniczony
czas (w przypadku tego typu turniejów na kaggle tylko dwa tygodnie),
więc trzeba robić to, co może przynieść największą korzyść. Gdyby nie
odpowiednie oprogramowanie (`tidymodels` i `glmnet`), może nawet
zrezygnowałbym z LASSO i został przy klasycznej regresji logistycznej.

Swoją drogą, w biznesie jest podobnie. Zawsze mamy jakieś ograniczenie
czasowe i jest to zmienna, którą koniecznie trzeba uwzględnić w procesie
budowy modelu.

``` r
set.seed(42)
folds_stack <- vfold_cv(pulsar, v = 10, strata = Class)

formula_glm <- as.formula(Class ~ Mean + SD + Skewness + EK +
    Mean_curve + SD_curve + Skewness_curve + EK_curve + JB_test + JB_test_curve)
glm_model <- logistic_reg(mixture = 1, penalty = 0.0000418) %>%
  set_mode("classification") %>% 
  set_engine("glmnet")
glm_recipe <- recipe(formula_glm, pulsar) %>% 
  step_poly(all_numeric_predictors(), degree = 2) %>% 
  step_interact(~ all_numeric_predictors()^2)
glm_wflow <- workflow() %>%
  add_recipe(glm_recipe) %>% 
  add_model(glm_model)

glm_fit <- glm_wflow %>%
  fit(pulsar)
glm_resamples <- glm_wflow %>% fit_resamples(
  resamples = folds_stack,
  metrics = metric_set(mn_log_loss),
  control = control_resamples(save_pred = TRUE)
)
```

Model dopasowałem na całych danych `pulsar`, ale oprócz tego osobno na
10 podzbiorach (`folds_stack`). Wytłumaczę to później.

### XGB

Kolejny model to Extreme Gradient Boosting. Jego głównym zadaniem ma być
wykrycie interakcji wysokiego poziomu między zmiennymi. Parametry
ustalone przy pomocy kroswalidacji.

``` r
xgb_model <- boost_tree(min_n = 14, mtry = 4, trees = 1570, sample_size = 0.697,
    tree_depth = 6, loss_reduction = 0.1740, learn_rate = 0.0141) %>%
  set_mode("classification") %>%
  set_engine("xgboost")
xgb_recipe <- recipe(Class ~ Mean + SD + Skewness + EK + Mean_curve + SD_curve +
  Skewness_curve + EK_curve, pulsar)
xgb_wflow <- workflow() %>%
  add_model(xgb_model) %>%
  add_recipe(xgb_recipe)

xgb_fit <- xgb_wflow %>%
  fit(pulsar)
xgb_resamples <- xgb_wflow %>% fit_resamples(
  resamples = folds_stack,
  metrics = metric_set(mn_log_loss),
  control = control_resamples(save_pred = TRUE)
)
```

## GAM

Czas na główny model, GAM (Generalized Additive Model, uogólniony model
addytywny). Jeśli spotykacie się z nim po raz pierwszy, najprościej
spojrzeć na niego jak na uogólnienie regresji (w tym przypadku
logistycznej), tylko że zamiast ręcznie transformować pewne zmienne (np.
dorzucać kwadraty, logarytmy itp.), GAM robi to za nas. W taki sposób,
by jak najlepiej oddać relację między zmienną zależną i niezależną.

Zacznę od pokazania formuły, jakiej używałem, następnie ją wytłumaczę.

``` r
formula_gam <- as.formula(Class ~ s(Mean) + s(SD) + s(EK) + s(Skewness) +
  s(Mean_curve) + s(SD_curve) + s(EK_curve) + s(Skewness_curve) +
  ti(SD, EK) + ti(Skewness, EK) + ti(Skewness, Mean_curve) +
  ti(Mean_curve, SD_curve) + ti(SD_curve, Skewness_curve) +
  s(prob_xgb) + s(prob_glm))
```

Żeby umożliwić GAM takie elastyczne modelowanie, należy w formule
opakować daną zmienną w `s()` (skrót od *smooth*). Zastosowałem tę
operację do wszystkich zmiennych, bo pakiet, z którego korzystam
(`mgcv`) jest tak dobrze napisany, że jeśli dana relacja może być
modelowana w prostszy sposób (tzn. `s()` niepotrzebne), to tak właśnie
się stanie (funkcja sama wykonuje kroswalidację, by dobrać parametr
odpowiedzialny za skomplikowanie relacji). Choć gdyby zależało mi na
interpretacji modelu, to jednak niektóre zmienne zostawiłbym bez `s()`
(czyli modelowałbym liniowo), bo jednak to nie jest do końca to samo.
Tutaj, gdy mamy tak dużo danych i interesuje nas tylko dokładność
prognoz (na dodatek na danych, co do których mamy pewność, że są bardzo
podobne do treningowych), modelowanie liniowe po prostu się nie opłaca.

Oprócz tego dorzucam interakcje, służy do tego funkcja `ti()`.
Wszystkich możliwych interakcji jest dużo, zdecydowałem się na kilka.
Proces ich wyboru zajął mi dość dużo czasu. Patrzyłem na różne czynniki,
ale głównie na błąd *log loss* w kroswalidacji. Starałem się jednak, by
tych interakcji było jak najmniej, tzn. jeśli któraś tylko minimalnie
redukowała błąd, raczej ją usuwałem. Obawiałem się nadmiernego
dopasowania do danych i mniejszej generalizacji na nowe dane (tak, przy
pomocy kroswalidacji też może zrobić *overfitting*).

Wiem, że w `tidymodel` można przeprowadzić proces wyboru zmiennych (w
tym przypadku interakcji), ale ponieważ chciałem mieć nad tym większą
kontrolę, odpowiedni kod, który wykonuje kroswalidację, napisałem sam.

Na koniec do modelu dorzucam dwie cechy, które powstały przy pomocy
LASSO i XGB (`s(prob_xgb)` i `s(prob_glm)`). O co w tym chodzi?
Popularną techniką poprawiającą zdolność predykcyjną modelu jest tzw.
[stacking](https://www.gormanalysis.com/blog/guide-to-model-stacking-i-e-meta-ensembling/).
Prognozy z modeli traktuje się nie jako ostateczne, ale jako zmienne dla
ogólniejszego modelu (“meta-modelu”). Tak naprawdę jest to jeden z
rodzajów tzw. *ensemble*, którego najpopularniejszym przedstawicielem
jest las losowy. Główna różnica jest taka, że w lesie używamy bazowych
modeli tego samego rodzaju, a w *stackingu* różnych (i zwykle im
bardziej różne, tym lepiej).

Możemy też na to spojrzeć w taki sposób. Model regresji logistycznej
mówi nam coś o tym, czy dana gwiazda to pulsar, czy nie (nawet całkiem
sporo, bo dla tych danych to dobry model). Ta informacja jest
przedstawiona ilościowo, w formie prawdopodobieństwa. W pewnym sensie
nie różni się to od którejkolwiek z pierwotnych zmiennych: one też
przekazują informację o tym, czy gwiazda jest pulsarem (choć nie w
formie prawdopodobieństwa). Patrząc jednak na to z odpowiedniej
perspektywy, jest to tylko kwestia skalowania: regresja logistyczna
zwraca cechę z przedziału 0-1, a pierwotne zmienne są w innych skalach.

W takim razie nic nie stoi na przeszkodzie, żeby taką zmienną dorzucić
do innego modelu. Nie byłoby sensu tworzyć na jej podstawie kolejnej
regresji logistycznej, bo byłoby to masło maślane, ale jako że GAM
patrzy na sprawę inaczej, w takim wypadku może to pomóc.

Jeszcze inne spojrzenie: regresja logistyczna dokonuje wstępnej
prognozy, a model GAM ją jedynie poprawia, koryguje (to już brzmi
bardziej jak *boosting* i jest to kolejny rodzaj *ensemble*).

Z tych dwóch dodatkowych cech ważniejsza była dla mnie `s(prob_xgb)`, bo
Gradient Boosting naprawdę patrzy inaczej niż GAM: potrafi wykryć
interakcje bardzo wysokich rzędów oraz modeluje relacje w sposób
nieciągły (bo bazuje na drzewach). Natomiast `s(prob_glm)` również
wnosiła coś do modelu, więc ją zostawiłem. Sprawdzałem również inne
bazowe modele, ale nie poprawiały wyników, więc ostatecznie je
pominąłem.

Zwykle do takiego *stackingu* używa się klasycznej regresji, ewentualnie
z karą LASSO (dodatkowo z pewnych względów wymusza się, by wszystkie
współczynniki były nieujemne). Czasem, szczególnie jak bazowych modeli
jest niewiele, bierze się po prostu średnią arytmetyczną z ich prognoz.
To jest bardzo intuicyjne: mamy kilka prognoz, nie wiemy, komu wierzyć,
więc “dla bezpieczeństwa” bierzemy średnią (tak naprawdę w regresji też,
ale średnią ważoną). Ja podszedłem do tego inaczej, głównie dlatego, że
sam modele GAM (tzn. bez tych dodatkowych cech z regresji i XGB) już był
bardzo dobry (albo inaczej, pierwotne cechy były bardzo mocne).

Wyjaśnię jeszcze, po co stosowałem te modele na podzbiorach
(`folds_stack`), zamiast od razu na całych danych treningowych. Przy
pomocy GAM muszę ustalić odpowiednie współczynniki dla prognoz z tych
modeli. Jeśli te prognozy powstałyby od razu na całych danych, jest
ryzyko nadmiernego dopasowania (szczególnie dla XGB) do zmiennej Y
(pulsar czy nie-pulsar). Przy ekstremalnym overfittingu, taka prognoza
stałaby się wręcz zmienną Y, czyli w modelu GAM próbowałbym przewidzieć
Y przy pomocy jego samego, otrzymując oczywiście idealne dopasowanie.
Dlatego trzeba do tego podejść inaczej: zbudować model na podzbiorze
danych (np. na 90%, jak u mnie) i dokonać prognozy na pozostałej części
(10%). W ten sposób otrzymuję wiarygodne (bez overfittingu) wartości
zmiennej, choć tylko dla tej części danych. Wystarczy jednak powtórzyć
tę operację (10-krotnie). W ostatecznym zastosowaniu modelu, gdy
przewiduję Y na zbiorze testowym, wykorzystuję już prognozy z modeli XGB
i LASSO zbudowanych na całych danych treningowych (`xgb_fit` i
`glm_fit`). Tu oczywiście overfitting mi nie grozi, bo do budowy tych
modeli nie wykorzystywałem danych testowych.

Poniższa funkcja `get_resamples` wyciąga prognozy z podzbiorów
`folds_stack`.

``` r
get_resamples <- function(resamples) {
  resamples %>%
    collect_predictions() %>%
    arrange(.row) %>% 
    pull(.pred_1)
}

pulsar <- pulsar %>% 
  mutate(
    prob_xgb = get_resamples(xgb_resamples),
    prob_glm = get_resamples(glm_resamples)
  )

gam_fit <- bam(formula_gam, data = pulsar, family = "binomial", 
  gamma = 1, discrete = TRUE)
```

Do budowy modelu GAM wykorzystałem funkcję `bam()` z pakietu `mgcv`. Nie
używałem `tidymodels`, bo po pierwsze, chciałem mieć większą kontrolę,
po drugie, w `tidymodels` można skorzystać tylko z funkcji `gam()`,
która jest znacznie wolniejsza od `bam(discrete = TRUE)`. Ta druga
została napisana specjalnie z myślą o dużych danych. Są w niej stosowane
pewne uproszczenia, ale nie zauważyłem żadnej różnicy w wynikach.

Wspomnę na koniec, że gdyby nie turniej, nie dodawałbym tych “dziwnych”
zmiennych z modeli XGB i regresji logistycznej. Znacznie komplikują
model, a praktyczny zysk niewielki. W takich wypadkach prostota jest
zwykle ważniejsza. Nie tylko dlatego, że łatwiej nam zrozumieć, co się
dzieje w modelu, ale też prostsze modele zwykle lepiej generalizują się
na nowe dane. Zbiór testowy, który jest używany na kaggle do ostatecznej
ewaluacji, to nie są naprawdę nowe dane. To tylko losowy podzbiór
wszystkich dostępnych w danym momencie danych, także rozkłady zmiennych
i relacje między nimi są praktycznie identyczne, jak w zbiorze
treningowych. W naprawdę nowych danych (które powstają zwykle później,
niż te dostępne na etapie budowy modelu) rzadko wszystko się zgadza.

## Prognoza

Trzeba jeszcze tylko dokonać prognozy na danych testowych i zapisać
wyniki do pliku *submission.csv*. Zostawiam kod, gdyby ktoś z Was chciał
wziąć udział w turnieju kaggle i potrzebowałby takie szablonu. Trzeba
tylko pamiętać, by zmienić ścieżkę do plików, bo znajdują się na
serwerze kaggle, a nie na naszym dysku.

``` r
pulsar_test <- read_csv("data/test.csv")
pulsar_test <- make_data(pulsar_test)
pulsar_test <- pulsar_test %>% 
  mutate(
    prob_glm = predict(glm_fit, pulsar_test, type = "prob") %>% pull(.pred_1),
    prob_xgb = predict(xgb_fit, pulsar_test, type = "prob") %>% pull(.pred_1)
  )

submission <- read_csv("data/sample_submission.csv")
submission <- submission %>% 
  mutate(Class = predict(gam_fit, pulsar_test, type = "response"))
write_csv(submission, "data/submission.csv")
```

## Dyskusja

Warto się jeszcze zastanowić, dlaczego ten model okazał się najlepszy?

1.  Mamy niewiele zmiennych, która już są cechami wysokiego poziomu.
    Innymi słowy, tzw. *feature engineering* już został wykonany za nas
    i niewiele da się go poprawić. Gdybyśmy mieli dostęp do pierwotnych
    danych (profili, na podstawie które zostały policzone statystyki),
    można by spróbować zrobić coś więcej (np. policzyć wyższe momenty,
    kwartyle itp.). Z drugiej strony, nie bez powodu w astronomii używa
    się akurat takich cech i możliwe, że nie wymyślilibyśmy nic
    lepszego.

2.  W takich turniejach zdecydowanie najczęściej używa się metod
    opartych na drzewach (np. Extreme Gradient Boosing lub las losowy).
    Problem w tym, że nie są one w stanie znaleźć “prawdziwych” relacji.
    Bo rzeczywiste związki między zmiennymi są raczej ciągłe w swej
    naturze – i drzewa decyzyjne będą jedynie ich przybliżeniem. Co
    prawda bardzo dobrym i przy ich pomocy można aproksymować prawie
    wszystko (np. interakcje wysokie rzędu), ale mimo wszystko świat tak
    nie działa. GAM z natury modeluje relacje w sposób ciągły. Natomiast
    trzeba dodać, że to nie znaczy, że GAM wszędzie się sprawdzi. Gdyby
    zmiennych było tu więcej, pewnie *boosting* okazałby się lepszy.

3.  GAM (przynajmniej w pakiecie `mgcv`) ma wbudowaną regularyzację,
    parametry są wybierane na podstawie wewnętrznej kroswalidacji. To
    sprawia, że to bardzo wygodny model w stosowaniu i mogłem swobodnie
    dorzucać interakcje i zmienne stworzone na podstawie XGB i LASSO.

Oprócz tego miałem pewną przewagę “techniczną” nad innymi uczestnikami
turnieju. Większość osób używa Pythona, a w nim implementacja GAM
pozostawia wiele do życzenia.