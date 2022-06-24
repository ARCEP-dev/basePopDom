# Constitution d'une base de population pour les Départements d'Outre-Mer français

## 1. Contexte

L'Arcep souhaite pouvoir estimer et suivre l'évolution de couverture de la population ultra-marine.

Les bases de population utilisées pour la métropole étant jugées peu fiables dans les territoires d'outremer, il a été décidé d'étudié la conception, en se basant sur des données publiées en Open-Data, d'une base de population.

Les territoires traités sont :
- Guyane (971)
- Martinique (972)
- Guyane (973)
- Réunion (974)
- Mayotte (976)
- Saint-Barthélemy (977)
- Saint-Martin (978)

Le principe de construction cette base de population ultra-marine est le suivant : la population recensée à l'Iris est répartie sur l'ensemble des bâtiments de plus de 20m² localisés dans cet Iris, proportionnellement à la taille du bâtiment.


### 1.1. Contact

Unité Régulation par la Données, Arcep : opendata [chez] arcep [point] fr

### 1.2. Open Data

Vous pouvez retrouver les bases produites sur [data.gouv](https://www.data.gouv.fr/fr/datasets/5b4371e2c751df037a54e146), car elles sont publiées en opendata !

Les données finales sont au format shapefile, SRID local.

## 2. Préalables

### 2.1. Données sources

Bâtiments :
- Cadastre/bati depuis le [PCI retraité par Etalab](https://cadastre.data.gouv.fr/datasets/cadastre-etalab) - 2022 - Format : GeoJSON, SRID : WGS84, EPSG : 4326
- En complément, pour le département 973 : couche BATIMENT de la [BD Topo® (IGN)](https://geoservices.ign.fr/ressource/174776) - 2022 - Format : Shapefile, SRID : RGFG95 / UTM zone 22N, EPSG : 2972

Population :
- [Population - recensement infracommunal 2018 France hors Mayotte + Collectivités d'outre-mer](https://www.insee.fr/fr/statistiques/5650720) - 2018 - Format : csv
- [Population - recensement communal 2017 pour Mayotte](https://www.insee.fr/fr/statistiques/3286558) - 2017 - Format : Excel (xls)

Zones de référence :
- Départements 971, 972, 973, 974 : [Zones IRIS INSEE/IGN 2022](https://geoservices.ign.fr/contoursiris#telechargement) - 2022 - Format : Shapefile, SRID : local, EPSG : local
- Départements 977, 978 : [Zones IRIS INSEE/IGN 2021](https://geoservices.ign.fr/contoursiris#telechargement) - 2021 - Format : Shapefile, SRID : local, EPSG : local
- Département 976 : [Commune IGN juin 2022](https://geoservices.ign.fr/adminexpress) - 2022 - Format : Shapefile, SRID : RGM04_UTM_zone_38S, EPSG : 4471


### 2.2. OS utilisé

Windows

### 2.3. Langages

- sql
- bash

### 2.4. Outils

- GDAL 2.4+ : ogr2ogr, ogrinfo (par exemple via prompt anaconda)
- Postgres/Postgis : psql, shp2pgsql, pgsql2shp
- un tableur


## 3. Processus de production

### 3.1. Variables

```sh
set PGHOST=***
set PGPORT=***
set PGDATABASE=***
set PGUSER=***
set PGPASSWORD=***

set sigDirectory=***
```

### 3.2. Base de données

Création de la structure de la base de données avec l'extension QGIS

```sh
psql < CREATE_Structure.sql

set PGDATABASE=dom_pop
```


### 3.3. Cadastre

#### Préparation des données

1. Téléchargement des données,
1. Extraction,
1. Validation des géométries,
1. Conversion de format

```sh
# Téléchargement des données (si outil disponible, sinon à la main)
# Les données des COM 977 et 978 sont inclues dans le jeu de données du 971

wget -O %sigDirectory%\etalab\cadastre\2022\971_bati.json.gz --no-check-certificate https://cadastre.data.gouv.fr/data/etalab-cadastre/latest/geojson/departements/971/cadastre-971-batiments.json.gz
wget -O %sigDirectory%\etalab\cadastre\2022\972_bati.json.gz --no-check-certificate https://cadastre.data.gouv.fr/data/etalab-cadastre/latest/geojson/departements/972/cadastre-972-batiments.json.gz
wget -O %sigDirectory%\etalab\cadastre\2022\973_bati.json.gz --no-check-certificate https://cadastre.data.gouv.fr/data/etalab-cadastre/latest/geojson/departements/973/cadastre-973-batiments.json.gz
wget -O %sigDirectory%\etalab\cadastre\2022\974_bati.json.gz --no-check-certificate https://cadastre.data.gouv.fr/data/etalab-cadastre/latest/geojson/departements/974/cadastre-974-batiments.json.gz
wget -O %sigDirectory%\etalab\cadastre\2022\976_bati.json.gz --no-check-certificate https://cadastre.data.gouv.fr/data/etalab-cadastre/latest/geojson/departements/976/cadastre-976-batiments.json.gz


# Extraction (si outil disponible, sinon à la main)

"7zG" e 971_bati.json.gz
"7zG" e 972_bati.json.gz
"7zG" e 973_bati.json.gz
"7zG" e 974_bati.json.gz
"7zG" e 976_bati.json.gz


# Validation des géométries et conversion de format

ogr2ogr -f "ESRI Shapefile" %sigDirectory%\etalab\cadastre\2022\971_bati_valid.shp %sigDirectory%\etalab\cadastre\2022\971_bati.json -dialect sqlite -sql "SELECT ST_MakeValid(geometry) AS geometry, type, nom, commune  FROM \"971_bati\" WHERE GeometryType(ST_MakeValid(geometry)) IN ('POLYGON', 'MULTIPOLYGON')"
ogr2ogr -f "ESRI Shapefile" %sigDirectory%\etalab\cadastre\2022\972_bati_valid.shp %sigDirectory%\etalab\cadastre\2022\972_bati.json -dialect sqlite -sql "SELECT ST_MakeValid(geometry) AS geometry, type, nom, commune  FROM \"972_bati\" WHERE GeometryType(ST_MakeValid(geometry)) IN ('POLYGON', 'MULTIPOLYGON')"
ogr2ogr -f "ESRI Shapefile" %sigDirectory%\etalab\cadastre\2022\973_bati_valid.shp %sigDirectory%\etalab\cadastre\2022\973_bati.json -dialect sqlite -sql "SELECT ST_MakeValid(geometry) AS geometry, type, nom, commune  FROM \"973_bati\" WHERE GeometryType(ST_MakeValid(geometry)) IN ('POLYGON', 'MULTIPOLYGON')"
ogr2ogr -f "ESRI Shapefile" %sigDirectory%\etalab\cadastre\2022\974_bati_valid.shp %sigDirectory%\etalab\cadastre\2022\974_bati.json -dialect sqlite -sql "SELECT ST_MakeValid(geometry) AS geometry, type, nom, commune  FROM \"974_bati\" WHERE GeometryType(ST_MakeValid(geometry)) IN ('POLYGON', 'MULTIPOLYGON')"
ogr2ogr -f "ESRI Shapefile" %sigDirectory%\etalab\cadastre\2022\976_bati_valid.shp %sigDirectory%\etalab\cadastre\2022\976_bati.json -dialect sqlite -sql "SELECT ST_MakeValid(geometry) AS geometry, type, nom, commune  FROM \"976_bati\" WHERE GeometryType(ST_MakeValid(geometry)) IN ('POLYGON', 'MULTIPOLYGON')"
```

#### Chargement des données en base

```sh
shp2pgsql -D -a -g geom -s 4326 %sigDirectory%\etalab\cadastre\2022\971_bati_valid.shp import.bati | psql
shp2pgsql -D -a -g geom -s 4326 %sigDirectory%\etalab\cadastre\2022\972_bati_valid.shp import.bati | psql
shp2pgsql -D -a -g geom -s 4326 %sigDirectory%\etalab\cadastre\2022\973_bati_valid.shp import.bati | psql
shp2pgsql -D -a -g geom -s 4326 %sigDirectory%\etalab\cadastre\2022\974_bati_valid.shp import.bati | psql
shp2pgsql -D -a -g geom -s 4326 %sigDirectory%\etalab\cadastre\2022\976_bati_valid.shp import.bati | psql
```

#### Transfert des batis dans la table public.bati

1. Transfert dans une première table
1. Patch : création d'une table avec gid renseignés et doublons de geometrie supprimés

```sql

-- Transfert dans table d'origine

INSERT INTO public.bati (gid, geom, centroid, type, nom, code_insee, area, pop)
SELECT gid, geom, ST_Centroid(geom), type, nom, commune, Round(ST_Area(ST_Transform(geom, 3857))::numeric, 2), null
FROM import.bati;

TRUNCATE TABLE import.bati;

-- Patch pour suppression des doublons

CREATE TABLE public.bati_dedup(
  gid serial,
  geom geometry(MultiPolygon,4326),
  centroid geometry(Point,4326),
  type character varying(80),
  nom character varying(80),
  code_insee character varying(5),
  area numeric,
  pop double precision
);

INSERT INTO public.bati_dedup ( geom, centroid, type, nom, code_insee, area, pop)
SELECT geom, centroid, type, nom, code_insee, area, pop
FROM public.bati;

DELETE FROM  bati_dedup a  USING bati_dedup b
WHERE a.gid < b.gid AND a.geom = b.geom;

-- maj des codes insee stb et stm dans bati_dedup

UPDATE bati_dedup SET code_insee = '97701' WHERE code_insee like '97123';
UPDATE bati_dedup SET code_insee = '97801' WHERE code_insee like '97127';

TRUNCATE TABLE public.bati;
```


### 3.4. Recensements de population

#### Préparation des données

Télécharger les fichiers csv pour :
- France métropolitaine 
- Collectiviés d'outre-mer (COM) - concerne les données pour Saint-Pierre-et-Miquelon(non utilisé), Saint-Barthélemy, Saint-Martin)

Et le fichier xls pour : 
- Mayotte

__A partir des fichiers Métropole et COM :__
- dans le fichier COM, ajouter et remplir une colonne "dep" : Saint-Pierre-et-Miquelon = 975 (non utilisé) ; Saint-Barthélemy = 977 ; Saint-Martin = 978
- traitement via ogr2ogr des fichiers métropole et COM pour exporter les colonnes utiles et ajouter des colonnes vides si besoin (IRIS, REG, DEP, COM, TYP_IRIS, LAB_IRIS, P13_POP) et sélectionner les lignes correspondant à des départements d'OM.

```sh
# DOM
ogr2ogr -f "CSV" %sigDirectory%\insee\recensement\2018\pop_2018.csv %sigDirectory%\insee\recensement\2018\base-ic-evol-struct-pop-2018.csv -sql "SELECT iris, null as reg, SUBSTR(com,1,2) as dep, com, typ_iris, lab_iris, p18_pop AS pop FROM \"base-ic-evol-struct-pop-2018\" WHERE com LIKE '97%'"

# St Martin & St Barthélemy
ogr2ogr -f "CSV" %sigDirectory%\insee\recensement\2018\pop_st_mb_2018.csv %sigDirectory%\insee\recensement\2018\base-ic-evol-struct-pop-2018-com.csv -sql "SELECT iris, null AS reg, dep, com, null AS typ_iris, lab_iris, p18_pop AS pop FROM \"base-ic-evol-struct-pop-2018-com\""
```

__A partir du fichier Mayotte :__
- dans l'onglet "Figure 2" récupérer les données des colonnes "Commune de résidence" et "Population municipale/2017", les renommer "commune" et "pop"
- ajouter et compléter une colonne "code_insee"
- supprimer la colonne "commune"
- enregistrer en csv "pop_mayotte_2017.csv", délimiteur ';'


#### Chargement des données en base

```sh
psql -c "\copy import.recensement FROM '%sigDirectory%\insee\recensement\2018\pop_2018.csv' CSV HEADER DELIMITER ',';"
psql -c "\copy import.recensement FROM '%sigDirectory%\insee\recensement\2018\pop_st_mb_2018.csv' CSV HEADER DELIMITER ',';"
psql -c "\copy import.recensement_mayotte FROM '%sigDirectory%\insee\recensement\2017\pop_mayotte_2017.csv' CSV HEADER DELIMITER ';';"
```


#### Transfert des population à l'iris/commune dans la table public.recensement

OM hors Mayotte :
```sql
INSERT INTO public.recensement (dcomiris, code_reg, code_dep, code_insee, typ_iris, lab_iris, pop)
SELECT iris, reg, dep, com, typ_iris, lab_iris, pop
FROM import.recensement;

TRUNCATE TABLE import.recensement;
```

Mayotte :
```sql
INSERT INTO public.recensement (dcomiris, code_reg, code_dep, code_insee, typ_iris, lab_iris, pop)
SELECT code_insee, null, LEFT(code_insee, 3), code_insee, null, null, pop
FROM import.recensement_mayotte;

TRUNCATE TABLE import.recensement_mayotte;
```


### 3.5. Zonages (IRIS/commune Mayotte)

#### 3.5.1. IRIS

##### Téléchargement

Télécharger l'archive "Contour…IRIS® édition 2021" (CONTOURS-IRIS_2-1__SHP__FRA_2021-01-01), et récupérer les shapefiles pour :
1. Guadeloupe (971) - EPSG : 5490
1. Martinique (972) - EPSG : 5490
1. Guyane (973) - EPSG : 2972
1. Réunion (974) -  EPSG : 2975
1. Saint-Barthélemy - 5490
1. Saint-Martin - 5490

##### Chargement des données en base

Les données sont chargées une par une et leur SRID est transformé en WGS84 (EPSG 4326)

```sh

shp2pgsql -D -a -g geom -s 5490:4326  %sigDirectory%\CONTOURS-IRIS_2-1__SHP__FRA_2022-01-01\CONTOURS-IRIS\1_DONNEES_LIVRAISON_2022-06-00180\CONTOURS-IRIS_2-1_SHP_RGAF09UTM20_GLP-2022\CONTOURS_IRIS.SHP import.zone_iris | psql -d dom_pop

shp2pgsql -D -a -g geom -s 5490:4326  %sigDirectory%\CONTOURS-IRIS_2-1__SHP__FRA_2022-01-01\CONTOURS-IRIS\1_DONNEES_LIVRAISON_2022-06-00180\CONTOURS-IRIS_2-1_SHP_RGAF09UTM20_MTQ-2022\CONTOURS_IRIS.SHP import.zone_iris | psql -d dom_pop

shp2pgsql -D -a -g geom -s 2972:4326  %sigDirectory%\CONTOURS-IRIS_2-1__SHP__FRA_2022-01-01\CONTOURS-IRIS\1_DONNEES_LIVRAISON_2022-06-00180\CONTOURS-IRIS_2-1_SHP_UTM22RGFG95_GUF-2022\CONTOURS_IRIS.SHP import.zone_iris | psql -d dom_pop

shp2pgsql -D -a -g geom -s 2975:4326  %sigDirectory%\CONTOURS-IRIS_2-1__SHP__FRA_2022-01-01\CONTOURS-IRIS\1_DONNEES_LIVRAISON_2022-06-00180\CONTOURS-IRIS_2-1_SHP_RGR92UTM40S_REU-2022\CONTOURS_IRIS.SHP import.zone_iris | psql -d dom_pop

shp2pgsql -D -a -g geom -s 5490:4326  %sigDirectory%\IRIS-GE_2-0__SHP_RGAF09UTM20_SBA_2021-01-01\IRIS-GE\1_DONNEES_LIVRAISON_2021-06-00135\IRIS-GE_2-0_SHP_RGAF09UTM20_SBA-2021\IRIS_GE.SHP import.zone_iris | psql -d dom_pop

shp2pgsql -D -a -g geom -s 5490:4326  %sigDirectory%\IRIS-GE_2-0__SHP_RGAF09UTM20_SMA_2021-01-01\IRIS-GE\1_DONNEES_LIVRAISON_2021-06-00135\IRIS-GE_2-0_SHP_RGAF09UTM20_SMA-2021\IRIS_GE.SHP import.zone_iris | psql -d dom_pop

```

##### Suppression des doublons de zones iris

```sql
CREATE INDEX zone_iris_gid ON import.zone_iris USING btree(gid);
CREATE INDEX zone_iris_dcomiris ON import.zone_iris USING btree(code_iris);

DELETE FROM import.zone_iris
WHERE gid IN (
	SELECT t2.gid
	FROM import.zone_iris t1,  import.zone_iris t2
	WHERE t1.code_iris = t2.code_iris
	AND t1.gid > t2.gid
);

DROP INDEX import.zone_iris_gid;
DROP INDEX import.zone_iris_dcomiris;
```

##### Transfert des zones iris dans la table public.zone_iris

```sql
INSERT INTO public.zone_iris (geom, code_insee, nom_com, iris, dcomiris, nom_iris, typ_iris, origine, sum_area, pop)
SELECT geom, insee_com, nom_com, iris, code_iris, nom_iris, typ_iris, null, null, null
FROM import.zone_iris;

TRUNCATE import.zone_iris;
```

#### 3.5.2. Communes de Mayotte

##### Téléchargement

Télécharger l'archive "ADE-COG" et récupérer le shapefile des communes de Mayotte (EPSG 4471)

##### Chargement des données en base en reprojetant en WGS84

```sh
shp2pgsql -c -g geom -s 4471:4326 "%sigDirectory%\COMMUNE.shp" import.commune | psql
```

##### Transfert des communes de Mayotte dans la table public.zone_iris

```sql
INSERT INTO public.zone_iris (geom, code_insee, nom_com, iris, dcomiris, nom_iris, typ_iris, origine, sum_area, pop)
SELECT geom, insee_com, nom, null, insee_com, nom, null, null, null, null
FROM import.commune;

TRUNCATE import.commune;
```

### 3.6. Contrôles et patch

#### 3.6.1  Contrôle de la concordance des iris entre sources et patch

Vérification de l'existance des iris du recensement dans la table zone_iris (hors Saint-Pierre-et-Miquelon)
```sql
SELECT * FROM public.recensement r 
LEFT JOIN public.zone_iris z on r.dcomiris = z.dcomiris
WHERE z.dcomiris is null
AND code_dep not in ('975')
order by r.code_insee
```

__Patch :__

Pour 2021 uniquement : patch pour la commune de Maripasoula (97353). Plusieurs iris dans zone_iris, un seul iris dans le recensement. S'inspirer de ce patch si d'autres cas émergent.
```sql
INSERT INTO public.zone_iris (geom, code_insee, nom_com, iris, dcomiris, nom_iris, typ_iris, origine, sum_area, pop)
SELECT ST_Multi(ST_Union(z.geom)), z.code_insee,  z.nom_com, null, r.dcomiris, z.nom_com, null, null, null, null
FROM public.zone_iris z 
LEFT JOIN public.recensement r on r.code_insee=z.code_insee
WHERE z.code_insee like '97353'
GROUP BY z.code_insee, z.nom_com, r.dcomiris;
```

#### 3.6.2 Contrôle des points de populations et des iris et patch

Est-ce que tous les iris avec une population contiennent au moins un bâtiment sur lequel reporter cette population ?
```sql
SELECT z.code_insee, z.iris,  count(b.*)
FROM public.zone_iris as z
LEFT JOIN public.bati_dedup as b ON  ST_Contains(z.geom, b.centroid) and z.code_insee = b.code_insee
GROUP BY z.code_insee, z.iris
ORDER BY count(b.*)
```

__Patch :__

Pour 2022, un seul iris en Guyanne, dans la commune de Maripasoula, est peuplé selon le recensement, mais aucun bâtiment dans le cadastre n'est situé dans cette zone. Le bâti du cadastre, pour cet iris, est complété par des bâtiments issus de la BD Topo de l'IGN.

Télécharger la BD Topo pour le département de la Guyane (973) :https://geoservices.ign.fr/ressource/174776, et extraire uniquement le shapefile "BATIMENT" (BDTOPO_3-0_TOUSTHEMES_SHP_UTM22RGFG95_D973_2022-03-15\BDTOPO\1_DONNEES_LIVRAISON_2022-03-00081\BDT_3-0_SHP_UTM22RGFG95_D973-ED2022-03-15\BATI\BATIMENT.shp).

Chargement des données en base :
```sh
shp2pgsql -D -c -g geom -s 2972:4326 BATIMENT.shp import.bati_bdtopo_973 | psql -d dom_pop
```

Opérations en base : mise au format et intégration dans la table public.bati_dedup.

```psql
--Création d'une table avec uniquement les bâtis de l'iris et avec les champs nécessaires :
CREATE TABLE public.bati_dedup_bdtopo_973 AS 
SELECT z.gid, ST_Force2D(z.geom) as geom, st_centroid(z.geom) as centroid, null as type, null as nom, a.code_insee, Round(ST_Area(ST_Transform(z.geom, 3857))::numeric, 2) as area, 0 as pop
FROM import.bati_bdtopo_973 z
JOIN (SELECT * FROM public.zone_iris WHERE dcomiris LIKE '973530103') as a ON ST_Contains(a.geom, ST_Centroid(z.geom));

-- Import des données dans bati_dedup (après vérifications) :
INSERT INTO public.bati_dedup ( geom, centroid, type, nom, code_insee, area, pop)
SELECT geom, centroid, type, nom, code_insee, area, pop
FROM public.bati_dedup_bdtopo_973;
```


### 3.7. Création des points de population

```sql
-- Hypothèse : nous considerons que les batis jusqu'à 20 m² n'ont pas d'usage d'habitation.
\set bati_min_area 20.0

-- Association de la population du recensement à la zone iris
UPDATE public.zone_iris AS z
SET pop = (SELECT r.pop FROM public.recensement AS r WHERE r.dcomiris = z.dcomiris);

-- Supprimer les iris avec population NULL
DELETE FROM public.zone_iris
WHERE pop IS NULL;

-- Remonter la sum de surface batie, seulement les batis >= 20.0 m², au niveau de la zone iris
UPDATE public.zone_iris z
SET sum_area = (
	SELECT SUM(b.area)
	FROM public.bati_dedup b
	WHERE ST_Contains(z.geom, b.centroid)
	AND b.area >= :bati_min_area);

-- Ajout de la pop en fonction de la surface de bati
UPDATE public.bati_dedup AS b
SET pop = Round((
	SELECT b.area / z.sum_area * z.pop
	FROM public.zone_iris z
	WHERE ST_Contains(z.geom, b.centroid))::numeric, 3)
WHERE area >= :bati_min_area;
```

### 3.8. Contrôles

```sql
-- Récap des batis filtrés
\set start 0
\set stop 20
\set step 2

\set departement '971%'

WITH serie AS (
	SELECT generate_series AS val
	FROM generate_series(:start, :stop, :step)
)
SELECT val, count(*)
FROM bati
INNER JOIN serie ON area >= val AND area < val + :step
WHERE code_insee LIKE :'departement'
GROUP BY val
ORDER BY val;

-- nombre de points de population par iris 
-- pose problème si aucun point de bâti pour répartir la population !
SELECT z.code_insee, z.iris, count(b.*)
FROM public.zone_iris as z
LEFT JOIN public.bati_dedup as b ON  ST_Contains(z.geom, b.centroid) and z.code_insee = b.code_insee
WHERE z.pop > 0
GROUP BY z.code_insee, z.iris
ORDER BY count(b.*), z.code_insee

-- Comparaison entre le recensement et les valeurs de pop au bati agrégées à la zone iris
\set departement '971'

SELECT r.dcomiris, r.code_reg, r.code_dep, r.code_insee, r.pop AS recensement_pop,
z.sum_area AS sum_iris_bati_area, z.pop AS iris_pop,
SUM(b.area)::real AS sum_bati_area, SUM(b.pop)::real AS sum_bati_pop
FROM public.recensement AS r
INNER JOIN public.zone_iris AS z ON z.dcomiris = r.dcomiris
INNER JOIN public.bati_dedup AS b ON ST_Contains(z.geom, b.centroid)
WHERE r.code_dep = :'departement'
GROUP BY r.dcomiris, r.code_reg, r.code_dep, r.code_insee, r.pop, z.sum_area, z.pop
ORDER BY r.code_reg, r.code_dep, r.dcomiris;

-- population par commune : repérer les *null*
SELECT code_insee, sum(pop) FROM public.bati_dedup 
GROUP BY code_insee
ORDER BY sum(pop)

-- bati > 20m² sans population associée
SELECT code_insee, count(*) 
FROM public.bati_dedup 
WHERE pop is null AND area >= 20
GROUP BY code_insee

```

### 3.9. Création des fichiers finaux

#### Export en Shapefiles

Les données sont exportées dans les systèmes de projection conventionnels locaux. Si besoin, les données peuvent être directement exportées en WGS84, en enlevant la fonction ST_Transform().

```sh
pgsql2shp -f "%sigDirectory%\dom\base_pop_971" dom_pop "SELECT ST_Transform(centroid, 5490) AS geom, type, code_insee, pop FROM bati_dedup WHERE geom IS NOT NULL AND pop IS NOT NULL AND pop > 0 AND code_insee LIKE '971%' AND code_insee NOT IN ('97123', '97127')"

pgsql2shp -f "%sigDirectory%\dom\base_pop_972" dom_pop "SELECT ST_Transform(centroid, 5490) AS geom, type, code_insee, pop FROM bati_dedup WHERE geom IS NOT NULL AND pop IS NOT NULL AND pop > 0 AND code_insee LIKE '972%'"

pgsql2shp -f "%sigDirectory%\dom\base_pop_973" dom_pop "SELECT ST_Transform(centroid, 2972) AS geom, type, code_insee, pop FROM bati_dedup WHERE geom IS NOT NULL AND pop IS NOT NULL AND pop > 0 AND code_insee LIKE '973%'"

pgsql2shp -f "%sigDirectory%\dom\base_pop_974" dom_pop "SELECT ST_Transform(centroid, 2975) AS geom, type, code_insee, pop FROM bati_dedup WHERE geom IS NOT NULL AND pop IS NOT NULL AND pop > 0 AND code_insee LIKE '974%'"

pgsql2shp -f "%sigDirectory%\dom\base_pop_976" dom_pop "SELECT ST_Transform(centroid, 4471) AS geom, type, code_insee, pop FROM bati_dedup WHERE geom IS NOT NULL AND pop IS NOT NULL AND pop > 0 AND code_insee LIKE '976%'"

pgsql2shp -f "%sigDirectory%\dom\base_pop_977" dom_pop "SELECT ST_Transform(centroid, 5490) AS geom, type, code_insee, pop FROM bati_dedup WHERE geom IS NOT NULL AND pop IS NOT NULL AND pop > 0 AND code_insee LIKE '977%'"

pgsql2shp -f "%sigDirectory%\dom\base_pop_978" dom_pop "SELECT ST_Transform(centroid, 5490) AS geom, type, code_insee, pop FROM bati_dedup WHERE geom IS NOT NULL AND pop IS NOT NULL AND pop > 0 AND code_insee LIKE '978%'"
```

#### Génération des fichiers d'infos
```sh
ogrinfo -so "%sigDirectory%\dom\base_pop_971.shp" -sql "Select * From base_pop_971" > %sigDirectory%\dom\base_pop_971.info.txt
ogrinfo -so "%sigDirectory%\dom\base_pop_972.shp" -sql "Select * From base_pop_972" > %sigDirectory%\dom\base_pop_972.info.txt
ogrinfo -so "%sigDirectory%\dom\base_pop_973.shp" -sql "Select * From base_pop_973" > %sigDirectory%\dom\base_pop_973.info.txt
ogrinfo -so "%sigDirectory%\dom\base_pop_974.shp" -sql "Select * From base_pop_974" > %sigDirectory%\dom\base_pop_974.info.txt
ogrinfo -so "%sigDirectory%\dom\base_pop_976.shp" -sql "Select * From base_pop_976" > %sigDirectory%\dom\base_pop_976.info.txt
ogrinfo -so "%sigDirectory%\dom\base_pop_977.shp" -sql "Select * From base_pop_977" > %sigDirectory%\dom\base_pop_977.info.txt
ogrinfo -so "%sigDirectory%\dom\base_pop_978.shp" -sql "Select * From base_pop_978" > %sigDirectory%\dom\base_pop_978.info.txt
```

#### Création des archives
Si outil disponible, sinon à la main
```sh
7zG a -t7z %sigDirectory%\dom\2019-03-19_base_pop_971.7z %sigDirectory%\dom\base_pop_971.*
7zG a -t7z %sigDirectory%\dom\2019-03-19_base_pop_972.7z %sigDirectory%\dom\base_pop_972.*
7zG a -t7z %sigDirectory%\dom\2019-03-19_base_pop_973.7z %sigDirectory%\dom\base_pop_973.*
7zG a -t7z %sigDirectory%\dom\2019-03-19_base_pop_974.7z %sigDirectory%\dom\base_pop_974.*
7zG a -t7z %sigDirectory%\dom\2019-03-19_base_pop_976.7z %sigDirectory%\dom\base_pop_976.*
7zG a -t7z %sigDirectory%\dom\2019-03-19_base_pop_977.7z %sigDirectory%\dom\base_pop_977.*
7zG a -t7z %sigDirectory%\dom\2019-03-19_base_pop_978.7z %sigDirectory%\dom\base_pop_978.*
```


#### Export en GeoJSON

```sh
ogr2ogr -f "geojson" %sigDirectory%\dom\base_pop_971.json %sigDirectory%\dom\base_pop_971.shp
ogr2ogr -f "geojson" %sigDirectory%\dom\base_pop_972.json %sigDirectory%\dom\base_pop_972.shp
ogr2ogr -f "geojson" %sigDirectory%\dom\base_pop_973.json %sigDirectory%\dom\base_pop_973.shp
ogr2ogr -f "geojson" %sigDirectory%\dom\base_pop_974.json %sigDirectory%\dom\base_pop_974.shp
ogr2ogr -f "geojson" %sigDirectory%\dom\base_pop_976.json %sigDirectory%\dom\base_pop_976.shp
ogr2ogr -f "geojson" %sigDirectory%\dom\base_pop_977.json %sigDirectory%\dom\base_pop_977.shp
ogr2ogr -f "geojson" %sigDirectory%\dom\base_pop_978.json %sigDirectory%\dom\base_pop_978.shp
```
