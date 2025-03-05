# Bundestagswahl: Historische Wahlkreis-Ergebnisse auf Grenzen von 2025 umgerechnet

Weil es von offizieller Seite keine Geografien (Shapefile, GeoJson etc.) der historischen Bundestags-Wahlkreisgrenzen vor 1998 gibt, hat sich Zeit Online daran gemacht, diese zu erstellen. Das Resultat davon wird in diesem Repository veröffentlicht. Nachfolgend ist der Prozess umrissen, wie dies genau geschieht. Die Daten wurden am 12. Februar 2025 in diesem [Artikel auf Zeit Online](https://www.zeit.de/politik/deutschland/2025-02/historische-bundestagswahlergebnisse-wahlkreise-1949) veröffentlicht. Die Daten wurden außerdem am Wahltag (23. Februar) in den 299 Wahlkreis-Seiten ([Bsp](https://www.zeit.de/politik/deutschland/bundestagswahl-2025/wahlergebnis-wahlkreis-uckermark-barnim-1-live)) als Liniendiagramm veröffentlicht.

## Ordnerstruktur

- [data](./data)\
Historische Wahlkreisergebnisse, Quelle: Bundeswahlleiterin
- [images](./images)\
Ausgangsmaterial, Quellen siehe Tabelle unten
- [shapes_2025](./shapes_2025)\
Wahlkreisgrenzen von 2025, Quelle: [Bundeswahlleiterin](https://www.bundeswahlleiterin.de/bundestagswahlen/2025/wahlkreiseinteilung/downloads.html)
- [zensus-2022-geocute-pointcloud.bin.br](./zensus-2022-geocute-pointcloud.bin.br)\
Bevölkerungszahlen in 100m-Gitterzellen, Quelle: [Zensus 2022](https://www.zensus2022.de/DE/Ergebnisse-des-Zensus/gitterzellen.html)
- [shapes_historical](./shapes_historical)\
Historische Wahlkreisgrenzen als Shapefile und GeoJson (Schritte 1-8)
- [geocute_results](./geocute_results)\
Umrechnungstabellen von historischen auf aktuelle Wahlkreisgrenzen (Schritt 9)

#### Bildquellen

 **Jahr** | **Quelle 1** | **Quelle 2**          
----------|--------------|-----------------------
 **1949** | [Wikipedia](https://de.wikipedia.org/wiki/Bundestagswahl_1949#/media/Datei:Bundestagswahl_1949_-_Ergebnisse_Wahlkreise.png)    | [Wahlen in Deutschland](https://www.wahlen-in-deutschland.de/buKarte1949.htm) 
 **1965** | [Wikipedia](https://de.wikipedia.org/wiki/Bundestagswahl_1965#/media/Datei:Bundestagswahl_1965_-_Ergebnisse_Wahlkreise.png)    | [Wahlen in Deutschland](https://www.wahlen-in-deutschland.de/buKarte1965.htm) 
 **1976** | [Wikipedia](https://de.wikipedia.org/wiki/Bundestagswahl_1976#/media/Datei:Bundestagswahl_1976_-_Ergebnisse_Wahlkreise.png)    | [Wahlen in Deutschland](https://www.wahlen-in-deutschland.de/buKarte1976.htm) 
 **1980** | [Wikipedia](https://de.wikipedia.org/wiki/Bundestagswahl_1980#/media/Datei:Bundestagswahl_1980_-_Ergebnisse_Wahlkreise.png)    | [Wahlen in Deutschland](https://www.wahlen-in-deutschland.de/buKarte1980.htm)

## Prozessbeschreibung

### Wahlkreisgrenzen seit 1998

Für die Jahre 1998 und fortfolgend gibt es die Wahlkreisgrenzen auf der [Website der Bundeswahlleiterin](https://www.bundeswahlleiterin.de/bundeswahlleiter.html) als Shapefile zum Download. Sie liegen im Ordner [shapes_historical](./shapes_historical).

### Wahlkreisgrenzen 1990-94

Für die Wahljahre 1990 und 1994 haben wir das [Shapefile für das Wahljahr 1998](./shapes_historical/wkr1998.shp) genommen und sind die Veränderungen, die auf Wikipedia beschrieben werden (für [1990](https://de.wikipedia.org/wiki/Liste_der_Bundestagswahlkreise_1994), für [1994](https://de.wikipedia.org/wiki/Liste_der_Bundestagswahlkreise_1998)) durchgangen und haben die Polygone von Hand abgeändert. Anschließend haben wir die Dateien ebenfalls in [shapes_historical](./shapes_historical) abgelegt.

### Wahlkreisgrenzen 1949-1987

1. Bilder von Wikipedia (siehe Tabelle unten) heruntergeladen
2. Mittels **GIMP** Bilder auf Wahlkreisgrenzen reduziert (schwarze Pixel) reduziert (alle anderen Pixel transparent) und sichergestellt, dass sie genug dick sind (dupliziert und um 1px verschoben)\
👉🏼 Resultat liegen im Ordner [images](./images)
3. Bilder in **QGIS** georeferenziert und als Rasterdaten (GeoTif) gespeichert
4. Rasterdaten mittels **GRASS** (`r.thin` mit 250 Iterationen und `r.to.vect` mit output type „line“) in Linien umgewandelt
5. Bundesländergrenzen als Linien ergänzt und Linien aus Schritt 4 so angepasst, dass vollständig geschlossene Flächen entstehen
6. Mittels **QGIS** polygonisiert, Kleinstflächen von Hand korrigiert
7. Wahlkreisnummern in **QGIS** anhand der Nr-Bilder im Ordner [images](./images) hinzugefügt (Quelle: [Wahlen in Deutschland](https://www.wahlen-in-deutschland.de/) per Mail)
8. Als Shapefile und GeoJson exportiert\
👉🏼 Resultat liegt im Ordner [shapes_historical](./shapes_historical). \
In den weiteren Schritten werden auch die Dateien für die Wahljahre ab 1990 miteinbezogen.
9. Mittels [Geocute](https://github.com/MichaelKreil/geocute) Umrechnungstabellen erstellt (siehe [run_geocute.sh](./run_geocute.sh))\
👉🏼 Resultat liegt im Ordner [geocute_results](./geocute_results)
10. Historische Ergebnisse (Quelle: Bundeswahlleiterin, liegen im Ordner [data](./data)) einlesen und mittels Geocute-Tabellen auf neuste Wahlkreisgrenzen (liegen im Ordner [shapes_2025](./shapes_2025)) umrechnen (siehe [main.R](./main.R))

## Datenbeschreibung

Das Ergebnis dieses Prozesses liegt in dieser Datei:

### historische_wahlkreisergebnisse.csv

Sie liegt als CSV und RDS (R data serialized) vor und beinhaltet folgende Spalten:

 **Spaltenname**     | **Typ**   | **Beschreibung**                                                                        
---------------------|-----------|-----------------------------------------------------------------------------------------
 **jahr**            | integer   | Das Wahljahr                                                                            
 **wahlkreis_nr**    | integer   | Die Wahlkreisnummer im Jahr 2025                                                        
 **wahlkreis_name**  | character | Der Wahlkreisname im Jahr 2025                                                          
 **partei**          | factor    | Partei-Kürzel (siehe Liste)                                                             
 **stimmen**         | integer   | Anzahl Stimmen der Partei im angegebenen Wahljahr                                       
 **anteil**          | double    | Anteil der Partei an den gültigen Stimmen                                               
 **wahlberechtigte** | integer   | Anzahl Wahlberechtigte im Wahljahr                                                      
 **waehlende**       | integer   | Anzahl Wählende im Wahljahr                                                             
 **gueltige**        | integer   | Anzahl gültige Stimmen im Wahljahr                                                      
 **ungueltige**      | integer   | Anzahl ungültige Stimmen im Wahljahr                                                    
 **keys_hist**       | character | Wahlkreisnummern, die damals (im Wahljahr) in der heutigen (2025) Wahlkreisnummer lagen, kommagetrennt
 **fractions**       | character | Anteil der eben genannten damaligen Wahlkreise am heutigen (2025) Wahlkreis, kommagetrennt

#### Ungenauigkeiten

Der beschriebene Prozess hat Ungenauigkeiten an verschiedenen Stellen:

- Im Geocute-Schritt gehen wir implizit davon aus, dass die **geografische Verteilung der Wählenden** zum Zeitpunkt der historischen Wahl genau gleich ist wie im Jahr 2022. Dies ist selbstverständlich nicht der Fall. Gemeinden und Stadtteile innerhalb eines Wahlkreises können seit 1949 stark gewachsen oder stark geschrumpft sein. In dem Fall würden die Anteile in der Spalte `fractions` nicht die Realität wiedergeben.
- In den Gitterzellen des **Zensus** sind sowohl Personen unter 18 Jahren als auch ausländische Staatsangehörige enthalten. Eine Gitterzelle mit hunderten Personen fällt entsprechend stark ins Gewicht, auch wenn womöglich viele von ihnen **nicht wahlberechtigt** sind.
- Die Wahlkreisgrenzen lagen lediglich als **Pixelgrafiken** vor. Wir gehen davon aus, dass diese wiederum auf Scans aus Büchern basieren. Die Projektion dieser Karten war uns unbekannt. Dies führte dazu, dass die Georeferenzierung **unpräzise** war. Die vektorisierten Grenzen weichen deshalb von den tatsächlichen Grenzen teilweise um einige hundert Meter – manchmal auch wenige Kilometer ab. In Städten können so schonmal einige tausend Wählende dem falschen Wahlkreis zugeschlagen werden. In dünn besiedelten Gebieten fällt dieser Effekt geringer aus.
- Es ist nicht ausgeschlossen, dass die Pixelgrafiken Fehler enthielten und entweder eine Wahlkreisnummer vertauscht wurde oder die Grenze in der Realität anders verlief.

Trotz alledem war dies der beste uns zugängliche Prozess, um historische Wahldaten auf aktuelle Grenzen umzurechnen. Verbesserungsvorschläge nehmen wir gerne entgegen – gerne auch direkt per Pull-Request.


#### Anmerkungen

- Die **DDR** ist nicht in den Daten enthalten. Für die Jahre vor 1990 nutzen wir deshalb für die Umrechnung (Schritt 9) eine Datei der 2025er-Grenzen ohne Ostdeutschland.
- Für das Jahr 2021 gab es eine **offizielle Umrechnung** der Werte von der Bundeswahlleiterin. Wir haben unsere Berechnungen im Resultat mit den offiziellen Zahlen ersetzt.
- **Westberlin** [nahm bis 1990 nicht an Bundestagswahlen teil](https://de.wikipedia.org/wiki/Berliner_Bundestagsabgeordneter).
- Das **Saarland** [trat erst 1957 der Bundesrepublik Deutschland bei](https://de.wikipedia.org/wiki/Saarland_1947_bis_1956). Entsprechend gab es davor dort keine Bundestagswahl. In der ersten Wahl traten CDU und CSU beide gegeneinander an. Dies war in keinem anderen Bundesland jemals der Fall. Wir rechnen die Zahlen beider Parteien zusammen.
- Wir haben auch die **Erststimmen** mit demselben Prozess umgerechnet. Da es sich dabei um Personenwahlen handelt, ist diese Umrechnung allerdings nicht sinnvoll und die Erststimmen sind nicht im Resultat enthalten.

---

<p xmlns:cc="http://creativecommons.org/ns#" xmlns:dct="http://purl.org/dc/terms/"><a property="dct:title" rel="cc:attributionURL" href="https://github.com/ZeitOnline/zg-bundestagswahl-2025-gemeinde-daten">Dieser Datensatz</a> von <a rel="cc:attributionURL dct:creator" property="cc:attributionName" href="https://www.zeit.de/daten-und-visualisierung">Zeit Online</a> untersteht der Lizenz <a href="https://creativecommons.org/licenses/by-sa/4.0/?ref=chooser-v1" target="_blank" rel="license noopener noreferrer" style="display:inline-block;">CC BY-SA 4.0 <img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/cc.svg?ref=chooser-v1" alt=""><img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/by.svg?ref=chooser-v1" alt=""><img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/sa.svg?ref=chooser-v1" alt=""></a></p> 

