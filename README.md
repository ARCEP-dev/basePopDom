# Constitution d'une base de population pour les Départements d'Outre-Mer français

## Contexte

L'Arcep souhaite pouvoir estimer et suivre l'évolution de couverture de la population ultra-marine.

Les bases de population existantes étant jugées peu fiables, il a été décidé d'étudié la conception, en se basant sur des données publiées en Open-Data, d'une base de population.

## Contact

Romain MAZIERE (Arcep) - romain [point] maziere [chez] arcep [point] fr

## Open Data

Vous pouvez retrouver les bases produites sur [data.gouv](https://www.data.gouv.fr/fr/datasets/5b4371e2c751df037a54e146), car elles sont publiées en opendata !

## Données sources

- Cadastre/bati [PCI retraité par Etalab](https://cadastre.data.gouv.fr/datasets/cadastre-etalab) - Format : GeoJSON, SRID : WGS84, EPSG : 4326
- [Zones IRIS INSEE/IGN 2018](https://www.data.gouv.fr/fr/datasets/r/a1ce4923-4128-4334-8117-3df7f6b73ba4) - Format : Shapefile, SRID : WGS84, EPSG : 4326
- [Population - recensement 2016 hors Mayotte](https://www.insee.fr/fr/statistiques/4228434) - Format : Excel (xls)
- [Population - recensement 2017 pour Mayotte](https://www.insee.fr/fr/statistiques/3286558) - Format : Excel (xls)

## Langages

- sql
- bash

## Outils

- GDAL ogr2ogr 2.4+,
- Postgres/Postgis

## OS utilisé

Malheureusement, Windows.

## Processus de production

### Variables

```sh
set PGHOST=***
set PGPORT=***
set PGDATABASE=***
set PGUSER=***
set PGPASSWORD=***

set sigDirectory=***
```

### Base de données

#### Création de la structure de la base de données

```sh
psql < CREATE_Structure.sql

set PGDATABASE=dom_pop
```


### Cadastre

1. Téléchargement des données,
1. Extraction,
1. Validation des géométries,
1. Conversion de format

```sh
# Téléchargement des données

wget -O %sigDirectory%\etalab\cadastre\2019\971_bati.json.gz --no-check-certificate https://cadastre.data.gouv.fr/data/etalab-cadastre/latest/geojson/departements/971/cadastre-971-batiments.json.gz
wget -O %sigDirectory%\etalab\cadastre\2019\972_bati.json.gz --no-check-certificate https://cadastre.data.gouv.fr/data/etalab-cadastre/latest/geojson/departements/972/cadastre-972-batiments.json.gz
wget -O %sigDirectory%\etalab\cadastre\2019\973_bati.json.gz --no-check-certificate https://cadastre.data.gouv.fr/data/etalab-cadastre/latest/geojson/departements/973/cadastre-973-batiments.json.gz
wget -O %sigDirectory%\etalab\cadastre\2019\974_bati.json.gz --no-check-certificate https://cadastre.data.gouv.fr/data/etalab-cadastre/latest/geojson/departements/974/cadastre-974-batiments.json.gz
wget -O %sigDirectory%\etalab\cadastre\2019\976_bati.json.gz --no-check-certificate https://cadastre.data.gouv.fr/data/etalab-cadastre/latest/geojson/departements/976/cadastre-976-batiments.json.gz


# Extraction

"7zG" e 971_bati.json.gz
"7zG" e 972_bati.json.gz
"7zG" e 973_bati.json.gz
"7zG" e 974_bati.json.gz
"7zG" e 976_bati.json.gz


# Validation des géométries et conversion de format

ogr2ogr -f "ESRI Shapefile" %sigDirectory%\etalab\cadastre\2019\971_bati_valid.shp %sigDirectory%\etalab\cadastre\2019\971_bati.json -dialect sqlite -sql "SELECT ST_MakeValid(geometry) AS geometry, type, nom, commune  FROM \"971_bati\" WHERE GeometryType(ST_MakeValid(geometry)) IN ('POLYGON', 'MULTIPOLYGON')"
ogr2ogr -f "ESRI Shapefile" %sigDirectory%\etalab\cadastre\2019\972_bati_valid.shp %sigDirectory%\etalab\cadastre\2019\972_bati.json -dialect sqlite -sql "SELECT ST_MakeValid(geometry) AS geometry, type, nom, commune  FROM \"972_bati\" WHERE GeometryType(ST_MakeValid(geometry)) IN ('POLYGON', 'MULTIPOLYGON')"
ogr2ogr -f "ESRI Shapefile" %sigDirectory%\etalab\cadastre\2019\973_bati_valid.shp %sigDirectory%\etalab\cadastre\2019\973_bati.json -dialect sqlite -sql "SELECT ST_MakeValid(geometry) AS geometry, type, nom, commune  FROM \"973_bati\" WHERE GeometryType(ST_MakeValid(geometry)) IN ('POLYGON', 'MULTIPOLYGON')"
ogr2ogr -f "ESRI Shapefile" %sigDirectory%\etalab\cadastre\2019\974_bati_valid.shp %sigDirectory%\etalab\cadastre\2019\974_bati.json -dialect sqlite -sql "SELECT ST_MakeValid(geometry) AS geometry, type, nom, commune  FROM \"974_bati\" WHERE GeometryType(ST_MakeValid(geometry)) IN ('POLYGON', 'MULTIPOLYGON')"
ogr2ogr -f "ESRI Shapefile" %sigDirectory%\etalab\cadastre\2019\976_bati_valid.shp %sigDirectory%\etalab\cadastre\2019\976_bati.json -dialect sqlite -sql "SELECT ST_MakeValid(geometry) AS geometry, type, nom, commune  FROM \"976_bati\" WHERE GeometryType(ST_MakeValid(geometry)) IN ('POLYGON', 'MULTIPOLYGON')"
```

#### Chargement des données en base

```sh
shp2pgsql -D -c -g geom -s 4326 %sigDirectory%\etalab\cadastre\2019\971_bati_valid.shp import.bati | psql
shp2pgsql -D -a -g geom -s 4326 %sigDirectory%\etalab\cadastre\2019\972_bati_valid.shp import.bati | psql
shp2pgsql -D -a -g geom -s 4326 %sigDirectory%\etalab\cadastre\2019\973_bati_valid.shp import.bati | psql
shp2pgsql -D -a -g geom -s 4326 %sigDirectory%\etalab\cadastre\2019\974_bati_valid.shp import.bati | psql
shp2pgsql -D -a -g geom -s 4326 %sigDirectory%\etalab\cadastre\2019\976_bati_valid.shp import.bati | psql
```

#### Transfert des zones iris dans la table de destination

```sql
INSERT INTO public.bati (gid, geom, centroid, type, nom, code_insee, area, pop)
SELECT gid, geom, ST_Centroid(geom), type, nom, commune, Round(ST_Area(ST_Transform(geom, 3857))::numeric, 2), null
FROM import.bati;

TRUNCATE TABLE import.bati;
```

#### Patch : création d'une table du bati avec gid renseignés et doublons de geometrie supprimés

```sql
CREATE TABLE public.bati_dedup(
  gid serial,
  geom geometry(MultiPolygon,4326),
  centroid geometry(Point,4326),
  type character varying(80),
  nom character varying(80),
  code_insee character varying(5),
  area numeric,
  pop numeric
);

INSERT INTO public.bati_dedup ( geom, centroid, type, nom, code_insee, area, pop)
SELECT geom, centroid, type, nom, code_insee, area, pop
FROM public.bati;

DELETE FROM  bati_dedup a  USING bati_dedup b
WHERE a.gid < b.gid AND a.geom = b.geom;

TRUNCATE TABLE public.bati;
```


### Recensement de population
1. Suppression des 5 premières lignes de l'onglet "IRIS"
1. Enregistrement en csv
1. Traitement via ogr2ogr pour exporter seulement les colonnes utiles (IRIS, REG, DEP, COM, TYP_IRIS, LAB_IRIS, P13_POP)

```sh
# Métropole et DOM
ogr2ogr -f "CSV" %sigDirectory%\insee\recensement\2015\pop_2015.csv %sigDirectory%\insee\recensement\2015\base-ic-evol-struct-pop-2015.csv -sql "SELECT iris, reg, dep, com, typ_iris, lab_iris, p15_pop AS pop FROM \"base-ic-evol-struct-pop-2015\" WHERE dep LIKE '97%'"

# St Martin & St Barthélemy
ogr2ogr -f "CSV" %sigDirectory%\insee\recensement\2015\pop_st_mb_2015.csv %sigDirectory%\insee\recensement\2015\base-ic-evol-struct-pop-2015-com.csv -sql "SELECT iris, null AS reg, dep, com, null AS typ_iris, lab_iris, p15_pop AS pop FROM \"base-ic-evol-struct-pop-2015-com\""
```

#### Chargement des données en base

```sh
psql -c "\copy import.recensement FROM '%sigDirectory%\insee\recensement\2015\pop_2015.csv' CSV HEADER DELIMITER ',';"
psql -c "\copy import.recensement FROM '%sigDirectory%\insee\recensement\2015\pop_st_mb_2015.csv' CSV HEADER DELIMITER ',';"
```

#### Transfert des zones iris dans la table de destination

```sql
INSERT INTO public.recensement (dcomiris, code_reg, code_dep, code_insee, typ_iris, lab_iris, pop)
SELECT iris, reg, dep, com, typ_iris, lab_iris, pop
FROM import.recensement;

TRUNCATE TABLE import.recensement;
```

### Recensement de population Mayotte

#### Chargement des données en base (alternative : recoder les libellés d'iris pour avoir la population de Mayotte par IRIS)

```sh
psql -c "\copy import.recensement_mayotte FROM '%sigDirectory%\insee\recensement\2012\pop_mayotte_2012.csv' CSV HEADER DELIMITER ';';"
```

#### Transfert du recensement de Mayotte

```sql
INSERT INTO public.recensement (dcomiris, code_reg, code_dep, code_insee, typ_iris, lab_iris, pop)
SELECT code_insee, null, LEFT(code_insee, 3), code_insee, null, null, pop
FROM import.recensement_mayotte;

TRUNCATE TABLE import.recensement_mayotte;
```



### Zones Iris

#### Chargement des données en base

```sh
shp2pgsql -D -c -g geom -s 4326 %sigDirectory%\dom\ziris\iris-2013-01-01_dom.shp import.zone_iris | psql
```

#### Suppression des doublons de zones iris

```sql
CREATE INDEX zone_iris_gid ON import.zone_iris USING btree(gid);
CREATE INDEX zone_iris_dcomiris ON import.zone_iris USING btree(dcomiris);

DELETE FROM import.zone_iris
WHERE gid IN (
	SELECT t2.gid
	FROM import.zone_iris t1,  import.zone_iris t2
	WHERE t1.dcomiris = t2.dcomiris
	AND t1.gid > t2.gid
);

DROP INDEX import.zone_iris_gid;
DROP INDEX import.zone_iris_dcomiris;
```

#### Transfert des zones iris dans la table de destination

```sql
INSERT INTO public.zone_iris (geom, code_insee, nom_com, iris, dcomiris, nom_iris, typ_iris, origine, sum_area, pop)
SELECT geom, depcom, nom_com, iris, dcomiris, nom_iris, typ_iris, origine, null, null
FROM import.zone_iris;

TRUNCATE import.zone_iris;
```

### Communes de Mayotte

#### Chargement des données en base en reprojetant en WGS84

```sh
shp2pgsql -c -g geom -s 4471:4326 "%sigDirectory%\ign\2018\admin_express\ADE-COG_1-1_SHP_RGM04UTM38S_D976\COMMUNE.shp" import.commune | psql
```

#### Transfert des communes de Mayotte en tant que "zones iris"

```sql
INSERT INTO public.zone_iris (geom, code_insee, nom_com, iris, dcomiris, nom_iris, typ_iris, origine, sum_area, pop)
SELECT geom, insee_com, nom_com, null, insee_com, nom_com, null, null, null, null
FROM import.commune;

TRUNCATE import.commune;
```


### Workflow

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


### Contrôle

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
```


### Export en Shapefiles
#### dans les systèmes de projection conventionnels
```sh
pgsql2shp -f "%sigDirectory%\dom\base_pop_971" dom_pop "SELECT ST_Transform(centroid, 32620) AS geom, type, code_insee, pop FROM bati WHERE geom IS NOT NULL AND pop IS NOT NULL AND pop > 0 AND code_insee LIKE '971%' AND code_insee NOT IN ('97123', '97127')"

pgsql2shp -f "%sigDirectory%\dom\base_pop_972" dom_pop "SELECT ST_Transform(centroid, 32620) AS geom, type, code_insee, pop FROM bati WHERE geom IS NOT NULL AND pop IS NOT NULL AND pop > 0 AND code_insee LIKE '972%'"

pgsql2shp -f "%sigDirectory%\dom\base_pop_973" dom_pop "SELECT ST_Transform(centroid, 2972) AS geom, type, code_insee, pop FROM bati WHERE geom IS NOT NULL AND pop IS NOT NULL AND pop > 0 AND code_insee LIKE '973%'"

pgsql2shp -f "%sigDirectory%\dom\base_pop_974" dom_pop "SELECT ST_Transform(centroid, 2975) AS geom, type, code_insee, pop FROM bati WHERE geom IS NOT NULL AND pop IS NOT NULL AND pop > 0 AND code_insee LIKE '974%'"

pgsql2shp -f "%sigDirectory%\dom\base_pop_976" dom_pop "SELECT ST_Transform(centroid, 32738) AS geom, type, code_insee, pop FROM bati WHERE geom IS NOT NULL AND pop IS NOT NULL AND pop > 0 AND code_insee LIKE '976%'"

pgsql2shp -f "%sigDirectory%\dom\base_pop_977" dom_pop "SELECT centroid AS geom, type, code_insee, pop FROM bati WHERE geom IS NOT NULL AND pop IS NOT NULL AND pop > 0 AND code_insee = '97123'"

pgsql2shp -f "%sigDirectory%\dom\base_pop_978" dom_pop "SELECT centroid AS geom, type, code_insee, pop FROM bati WHERE geom IS NOT NULL AND pop IS NOT NULL AND pop > 0 AND code_insee = '97127'"
```

### Génération des fichiers d'infos
```sh
ogrinfo -so "%sigDirectory%\dom\base_pop_971.shp" -sql "Select * From base_pop_971" > %sigDirectory%\dom\base_pop_971.info.txt
ogrinfo -so "%sigDirectory%\dom\base_pop_972.shp" -sql "Select * From base_pop_972" > %sigDirectory%\dom\base_pop_972.info.txt
ogrinfo -so "%sigDirectory%\dom\base_pop_973.shp" -sql "Select * From base_pop_973" > %sigDirectory%\dom\base_pop_973.info.txt
ogrinfo -so "%sigDirectory%\dom\base_pop_974.shp" -sql "Select * From base_pop_974" > %sigDirectory%\dom\base_pop_974.info.txt
ogrinfo -so "%sigDirectory%\dom\base_pop_976.shp" -sql "Select * From base_pop_976" > %sigDirectory%\dom\base_pop_976.info.txt
ogrinfo -so "%sigDirectory%\dom\base_pop_977.shp" -sql "Select * From base_pop_977" > %sigDirectory%\dom\base_pop_977.info.txt
ogrinfo -so "%sigDirectory%\dom\base_pop_978.shp" -sql "Select * From base_pop_978" > %sigDirectory%\dom\base_pop_978.info.txt
```

### Création des archives

```sh
7zG a -t7z %sigDirectory%\dom\2019-03-19_base_pop_971.7z %sigDirectory%\dom\base_pop_971.*
7zG a -t7z %sigDirectory%\dom\2019-03-19_base_pop_972.7z %sigDirectory%\dom\base_pop_972.*
7zG a -t7z %sigDirectory%\dom\2019-03-19_base_pop_973.7z %sigDirectory%\dom\base_pop_973.*
7zG a -t7z %sigDirectory%\dom\2019-03-19_base_pop_974.7z %sigDirectory%\dom\base_pop_974.*
7zG a -t7z %sigDirectory%\dom\2019-03-19_base_pop_976.7z %sigDirectory%\dom\base_pop_976.*
7zG a -t7z %sigDirectory%\dom\2019-03-19_base_pop_977.7z %sigDirectory%\dom\base_pop_977.*
7zG a -t7z %sigDirectory%\dom\2019-03-19_base_pop_978.7z %sigDirectory%\dom\base_pop_978.*
```


### Export en GeoJSON

```sh
ogr2ogr -f "geojson" %sigDirectory%\dom\base_pop_971.json %sigDirectory%\dom\base_pop_971.shp
ogr2ogr -f "geojson" %sigDirectory%\dom\base_pop_972.json %sigDirectory%\dom\base_pop_972.shp
ogr2ogr -f "geojson" %sigDirectory%\dom\base_pop_973.json %sigDirectory%\dom\base_pop_973.shp
ogr2ogr -f "geojson" %sigDirectory%\dom\base_pop_974.json %sigDirectory%\dom\base_pop_974.shp
ogr2ogr -f "geojson" %sigDirectory%\dom\base_pop_976.json %sigDirectory%\dom\base_pop_976.shp
ogr2ogr -f "geojson" %sigDirectory%\dom\base_pop_977.json %sigDirectory%\dom\base_pop_977.shp
ogr2ogr -f "geojson" %sigDirectory%\dom\base_pop_978.json %sigDirectory%\dom\base_pop_978.shp
```
