DROP DATABASE IF EXISTS dom_pop;

CREATE DATABASE dom_pop
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'French_France.1252'
    LC_CTYPE = 'French_France.1252'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

\c dom_pop;

BEGIN;

CREATE EXTENSION postgis;
CREATE SCHEMA import;

-- import
CREATE TABLE import.recensement(
  iris character varying(10),
  reg integer,
  dep character varying(3),
  com character varying(5),
  typ_iris character varying(1),
  lab_iris character varying(1),
  pop integer
);

CREATE TABLE import.recensement_mayotte(
  code_insee character varying(5),
  pop integer
);

CREATE TABLE import.bati(
  gid integer,
  geom geometry(MultiPolygon,4326),
  type character varying(80),
  nom character varying(80),
  commune character varying(80),
  created date,
  updated date
);

CREATE TABLE import.zone_iris(
  gid integer,
  geom geometry(MultiPolygon,4326),
  depcom character varying(5),
  nom_com character varying(45),
  iris character varying(4),
  dcomiris character varying(9),
  nom_iris character varying(45),
  typ_iris character varying(1),
  origine character varying(1)
);

CREATE TABLE import.commune(
  gid integer,
  geom geometry(MultiPolygon,4326),
  id character varying(24),
  statut character varying(22),
  insee_com character varying(5),
  nom_com character varying(50),
  insee_arr character varying(2),
  nom_dep character varying(30),
  insee_dep character varying(3),
  nom_reg character varying(35),
  insee_reg character varying(2),
  code_epci character varying(9),
  nom_com_m character varying(50),
  population integer
);

-- public
CREATE TABLE public.recensement(
  id serial,
  dcomiris character varying(10),
  code_reg integer,
  code_dep character varying(3),
  code_insee character varying(5),
  typ_iris character varying(1),
  lab_iris character varying(1),
  pop integer
);

CREATE TABLE public.zone_iris(
  gid serial,
  geom geometry(MultiPolygon,4326),
  code_insee character varying(5),
  nom_com character varying(45),
  iris character varying(4),
  dcomiris character varying(9),
  nom_iris character varying(45),
  typ_iris character varying(1),
  origine character varying(1),
  sum_area numeric,
  pop integer
);

CREATE TABLE public.bati(
  gid integer,
  geom geometry(MultiPolygon,4326),
  centroid geometry(Point,4326),
  type character varying(80),
  nom character varying(80),
  code_insee character varying(5),
  area numeric,
  pop numeric
);

CREATE INDEX public_bati_code_insee ON public.bati USING btree(code_insee);
CREATE INDEX public_bati_area ON public.bati USING btree(area);
CREATE INDEX public_bati_centroid ON public.bati USING GIST(centroid);
CREATE INDEX public_bati_geom ON public.bati USING GIST(geom);
CREATE INDEX public_zone_iris_geom ON public.zone_iris USING GIST(geom);
CREATE INDEX public_zone_iris_gid ON public.zone_iris USING btree(gid);
CREATE INDEX public_recensement_dcomiris ON public.recensement USING btree(dcomiris);

COMMIT;
