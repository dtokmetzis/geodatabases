--BAG

--WITH NLEXTRACT

--Create index on pand identificatie (for joining later)

CREATE INDEX identificatie_idx ON pand(identificatie);

--CREATE index on array in verblijfsobject

CREATE INDEX pandref_idx on verblijfsobject USING GIN ("pandref");

SET enable_seqscan TO off;

--CREATE FDW on bag

CREATE SERVER bag_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', dbname 'bagv2');

CREATE USER MAPPING FOR CURRENT_USER
SERVER bag_server
OPTIONS (user 'xxxx', password 'xxxx'); --change arguments

CREATE SCHEMA bag_public;
IMPORT FOREIGN SCHEMA public
FROM SERVER bag_server
INTO bag_public;

--CREATE new table with filtered vbo data and join with relevant pand data

VACUUM ANALYZE;

EXPLAIN ANALYZE;

CREATE TABLE vbo AS

SELECT 
	v.gid AS gid_vbo,
	p.gid AS gid_pand,
	p.oorspronkelijkbouwjaar AS bouwjaar,
	v.gebruiksdoel,
	v.hoofdadresnummeraanduidingref,
	v.nevenadresnummeraanduidingref,
	v.pandref,
	v.identificatie AS identificatie_vbo,
	p.identificatie AS identificatie_pand,
	v.status AS status_vbo,
	p.status AS status_pand,
	v.geconstateerd,
	v.documentdatum,
	v.documentnummer,
	v.voorkomenidentificatie,
	v.begingeldigheid,
	v.eindgeldigheid,
	v.tijdstipregistratie,
	v.eindregistratie,
	ST_GeomFromWKB(v.wkb_geometry, 28992) AS geom_vbo,
	ST_GeomFromWKB(p.wkb_geometry, 28992) AS geom_pand,
	v.wkb_geometry AS wkb_geometry_vbo,
	p.wkb_geometry AS wkb_geometry_pand
FROM 
	bag_public.verblijfsobject v	
JOIN 
	bag_public.pand p ON p.identificatie = ANY(v.pandref)
WHERE 
	v.gebruiksdoel::text LIKE '{woonfunctie%' AND 
	v.begingeldigheid >= '1997-01-01' AND
	v.begingeldigheid < '2022-01-01' AND
	(v.status = 'Verblijfsobject in gebruik' OR
	v.status = 'Verblijfsobject niet in gebruik' OR
	v.status = 'Verblijfsobject in gebruik (niet ingemeten)' OR
	v.status = 'Verbouwing verblijfsobject') AND
	p.oorspronkelijkbouwjaar >=1997 AND
	p.oorspronkelijkbouwjaar < 2022;

--CREATE spatial index on vbo

CREATE INDEX vbo_idx ON vbo USING GIST (geom_vbo);
CREATE INDEX pand_idx ON vbo USING GIST (geom_pand);

--CREATE BAG TABLES WITH GEOPARAAT

--There are not filters yet on status fields. We can do that later.

EXPLAIN ANALYZE

CREATE TABLE vbo AS

SELECT
	v.fid AS vbo_id,
	p.fid AS pand_id,
	v.identificatie AS vbo_identificatie,
	p.identificatie AS pand_identificatie,
	v.oppervlakte,
	v.pand_id AS vbo_pand_id,
	v.begindatum,
	v.einddatum,
	p.bouwjaar,
	vsc.label AS vbo_status,
	psc.label AS pand_status,
	w.label AS woningtype,
	v.geom,
	v.pand_id_geom	
FROM 
	bag_public.vbo v
INNER JOIN
	bag_public.pand p ON v.pand_id = p.identificatie
INNER JOIN
	bag_public.pand_status_code psc ON p.statuscode = psc.code
INNER JOIN
	bag_public.vbo_status_code vsc ON v.statuscode = vsc.code
INNER JOIN
	bag_public.pand_woningtype w ON p.woningtype = w.code
WHERE 
	v.woon
	AND p.bouwjaar >= 1997
	AND p.bouwjaar < 2022
	--AND (v.statuscode = 3
	--	 OR v.statuscode = 4
	--	 OR v.statuscode = 5
	--	 OR v.statuscode = 7)
	--AND (p.statuscode = 4
	--	OR p.statuscode = 5
	--	OR p.statuscode = 9)
	--AND v.begindatum >= '19970101'
	--AND v.einddatum < '20220101'

CREATE INDEX vbo_geom_idx ON vbo USING GIST (geom);
CREATE INDEX pand_geom_idx ON vbo USING GIST (pand_id_geom);


--Join with plannen_2010 via ST_Intersects. 

CREATE TABLE vbo_plannen_2010 AS

SELECT
	v.vbo_id,
	v.pand_id,
	v.vbo_identificatie,
	v.pand_identificatie,
	v.bouwjaar,
	v.vbo_status,
	v.pand_status,
	v.woningtype,
	p.plan_id
	p.unieknr,
	p.woningen_b,
	p.woningen_o,
	p.plannaam,
	p.plansoort,
	p.planstatus,
	p.startdatum,
	p.einddatum,
	p.opmerking,
	p.geom AS geom_plannen,
	v.geom AS geom_vbo,
	v.pand_id_geom AS geom_pand
FROM
	vbo v
JOIN 
	plannen_2010 p
ON
	ST_Intersects(p.geom, v.geom)
WHERE
	p.bestemming = 'wonen';
	

CREATE INDEX vbo_plannen_2010_geom_idx ON vbo_plannen_2010 USING GIST (geom_vbo);
CREATE INDEX pand_plannen_2010_geom_idx ON vbo_plannen_2010 USING GIST (geom_pand);
CREATE INDEX plannen_plannen_2010_geom_idx ON vbo_plannen_2010 USING GIST (geom_plannen);


