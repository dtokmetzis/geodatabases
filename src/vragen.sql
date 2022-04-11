--1. How many houses were planned in each municipality in 2010? 
--How would this translate to municipalities of 2022?

SELECT
	g.gm_naam AS gemeente,

	--number of houses is either in woningen_b (provided by municipality)
	--or in woningen_b (an estimation of De Nieuwe Kaart)
	SUM(CASE 
		WHEN p.woningen_b IS NULL THEN p.woningen_o
		WHEN p.woningen_o IS NULL THEN p.woningen_b
		ELSE p.woningen_b + p.woningen_o
		END) AS gepland_2010
FROM
	plannen_2010 p
JOIN
	gemeenten_public.gemeentegrenzen g
	ON
	ST_Intersects(p.geom, g.geom)
WHERE
	EXTRACT(YEAR FROM g.jaar) = 2022 --change to 2010 or other year if necessary
	AND p.bestemming = 'wonen'
	AND NOT (p.woningen_b IS NULL
		AND p.woningen_o IS NULL)
GROUP BY
	gemeente
	ORDER BY
gepland_2010 DESC;

--2. How many houses were built within the planning locations within the timeframe of the plans 
--(e.g. a plan could have a project date range from 2010 to 2015)? 
--Provide an overview of each municipality and each year.
--AND
--3. How many houses were built within the planning location after the project data provided in 2010? 
--Provide an overview of each municipality and each year.
--AND
--4. How many houses were built outside the planning locations? 
--Give an overview of each municipality. 
--AND
--5. Create a map for the whole of the Netherlands showing the difference between planned houses 
--and built houses in 2022 based on the different plans of 1997-2010.  (1997 is non-sensical...)


CREATE TABLE huizen_plannen_gemeenten AS

SELECT DISTINCT
	g.gm_naam AS gemeente
	, hg.huizen_in_gemeente AS gebouwd_in_gemeente_na_2010
	, pg.geplande_woningen
	, hg.huizen_in_gemeente - pg.geplande_woningen AS meer_gebouwd_dan_gepland
	, pv.huizen_gebouwd_in_plangebied
	, hg.huizen_in_gemeente - pv.huizen_gebouwd_in_plangebied AS huizen_gebouwd_buiten_plangebied
	, pv_tijd.huizen_gebouwd_in_plangebied_op_tijd
	, g.geom
FROM
	gemeenten_public.gemeentegrenzen g

--aggregate houses in municipalities

JOIN (
	SELECT 
	 	COUNT(vbo_id) AS huizen_in_gemeente
	 	, g.gm_naam
	 FROM 
		vbo v
	 JOIN 
		gemeenten_public.gemeentegrenzen g
	 ON 
		ST_Intersects(v.vbo_geom, g.geom)

	--The following statusses are used by the Statistics Bureau

	 WHERE 
		(v.vbo_status = 'verblijfsobject in gebruik'
	 	OR v.vbo_status = 'verblijfsobject in gebruik (niet ingemeten)'
	 	OR v.vbo_status = 'verbouwing verblijfsobject'
	 	OR v.vbo_status = 'verblijfsobject buiten gebruik')
	 	AND v.bouwjaar >= 2010
	 	AND EXTRACT(YEAR FROM g.jaar) = 2022
	 GROUP BY 
		g.gm_naam) AS hg
	 ON 
	 	hg.gm_naam = g.gm_naam

--planned houses in municipalities
--A left join is needed because not all municipalities have houses planned 
--(Ameland for instance). I don't want to lose information on municipalities.

LEFT JOIN (
	SELECT 
	 	SUM(CASE 
		WHEN p.woningen_b IS NULL THEN p.woningen_o
		WHEN p.woningen_o IS NULL THEN p.woningen_b
		ELSE p.woningen_b + p.woningen_o
		END) AS geplande_woningen
	 	, g.gm_naam
	FROM 
		plannen_2010 p
	JOIN 
	 	gemeenten_public.gemeentegrenzen g
	ON
		ST_Intersects(p.geom, g.geom)
	WHERE
	 	p.bestemming = 'wonen'
		AND EXTRACT(YEAR FROM g.jaar) = 2022
	GROUP BY
	 	g.gm_naam) AS pg
	ON 
		pg.gm_naam = g.gm_naam


--houses in planning zones

LEFT JOIN (
	SELECT 
	  g.gm_naam
	  , SUM(wp.aantal_huizen) AS huizen_gebouwd_in_plangebied
	FROM 
		gemeenten_public.gemeentegrenzen g
	 JOIN (
		SELECT 
			COUNT(v.vbo_id) AS aantal_huizen
		 	, p.geom AS plan_geom
		 FROM
		 	vbo v
		 JOIN
		 	plannen_2010 p
	  	ON
	  		ST_Intersects(v.vbo_geom, p.geom)
		WHERE v.bouwjaar >= 2010
		--filter on housing status
		AND (v.vbo_status = 'verblijfsobject in gebruik'
			 OR v.vbo_status = 'verblijfsobject in gebruik (niet ingemeten)'
			 OR v.vbo_status = 'verbouwing verblijfsobject'
			 OR v.vbo_status = 'verblijfsobject buiten gebruik')
		--filter on zoning plan type
		AND p.bestemming = 'wonen'
	 GROUP BY p.geom) AS wp
	ON ST_Intersects(g.geom, wp.plan_geom)
	WHERE 
		EXTRACT(YEAR FROM g.jaar) = 2022
	GROUP BY
		g.gm_naam) AS pv
	ON pv.gm_naam = g.gm_naam
	
--houses in planning date range

LEFT JOIN (
	SELECT
	  g.gm_naam
	  , SUM(wp_tijd.aantal_huizen) AS huizen_gebouwd_in_plangebied_op_tijd
	FROM 
		gemeenten_public.gemeentegrenzen g
	 JOIN (
		SELECT 
			COUNT(v.vbo_id) AS aantal_huizen
		 	, p.geom AS plan_geom
		 FROM
		 	vbo v
		 JOIN
		 	plannen_2010 p
	  	ON
	  		ST_Intersects(v.vbo_geom, p.geom)
		WHERE v.bouwjaar >= (SELECT p.startdatum)
		AND v.bouwjaar <= (SELECT p.einddatum)
		--filter op type woning
		AND (v.vbo_status = 'verblijfsobject in gebruik'
			 OR v.vbo_status = 'verblijfsobject in gebruik (niet ingemeten)'
			 OR v.vbo_status = 'verbouwing verblijfsobject'
			 OR v.vbo_status = 'verblijfsobject buiten gebruik')
		--filter op bestemmingsplan
		AND p.bestemming = 'wonen'
	 GROUP BY p.geom) AS wp_tijd
	ON ST_Intersects(g.geom, wp_tijd.plan_geom)
	WHERE 
		EXTRACT(YEAR FROM g.jaar) = 2022
	GROUP BY
		g.gm_naam) AS pv_tijd
	ON pv_tijd.gm_naam = g.gm_naam
WHERE EXTRACT(YEAR FROM g.jaar) = 2022;

--create a spatial index
	
CREATE INDEX sidx_huizen_plannen_gemeenten ON huizen_plannen_gemeenten USING GIST(geom);
		 

--6. How many houses were built just outside the planning locations 
--(use 250m and 500m buffers) in the period 2010-2022 in each municipality (2022)? 

ALTER TABLE plannen_2010
ADD COLUMN buffer_250 geometry(Geometry, 28992);

ALTER TABLE plannen_2010
ADD COLUMN buffer_500 geometry(Geometry, 28992);


UPDATE plannen_2010
SET buffer_250 = ST_Buffer(geom, 250)
FROM spatial_ref_sys
WHERE ST_SRID(geom) = srid;

UPDATE plannen_2010
SET buffer_500 = ST_Buffer(geom, 500)
FROM spatial_ref_sys
WHERE ST_SRID(geom) = srid;


--CREATE TABLE huizen_plangebied_buffers AS

SELECT DISTINCT
	g.gm_naam AS gemeente
	, p250.gebouwde_woningen_250 - vp.gebouwde_woningen AS huizen_gebouwd_buffer_250
	, p500.gebouwde_woningen_500 - vp.gebouwde_woningen AS huizen_gebouwd_buffer_500
	, vp.gebouwde_woningen AS huizen_gebouwd_plangebied
FROM
	gemeenten_public.gemeentegrenzen g
JOIN (
	SELECT
		g.gm_naam
		, SUM(wp.aantal_huizen) AS gebouwde_woningen
	FROM
		gemeenten_public.gemeentegrenzen g
	JOIN (
		SELECT
			COUNT(v.vbo_id) AS aantal_huizen
			, p.geom AS plan_geom
		FROM vbo v
		JOIN
			plannen_2010 p
		ON
			ST_Intersects(v.vbo_geom, p.geom)
		WHERE
			v.bouwjaar >= 2010
			AND (v.vbo_status = 'verblijfsobject in gebruik'
			OR v.vbo_status = 'verblijfsobject in gebruik (niet ingemeten)'
			OR v.vbo_status = 'verbouwing verblijfsobject'
			OR v.vbo_status = 'verblijfsobject buiten gebruik')
			AND p.bestemming = 'wonen'
	 	GROUP BY p.geom) AS wp
	ON
		ST_Intersects(g.geom, wp.plan_geom)
	WHERE
		EXTRACT(YEAR FROM g.jaar) = 2022
	GROUP BY
		g.gm_naam) AS vp
	ON
		vp.gm_naam = g.gm_naam
--Buffer_250. There is a problem with overlapping buffers so that houses are
--counted for each buffered polygon
JOIN (
	SELECT DISTINCT
		g.gm_naam
		, SUM(wp_250.aantal_huizen_250) AS gebouwde_woningen_250
	FROM
		gemeenten_public.gemeentegrenzen g
	JOIN (
		SELECT
			COUNT(v.vbo_id) AS aantal_huizen_250
			, p.buffer_250 AS buffer_250
		FROM vbo v
		JOIN
			plannen_2010 p
		ON
			ST_Intersects(v.vbo_geom, p.buffer_250)
		WHERE
			v.bouwjaar >= 2010
			AND (v.vbo_status = 'verblijfsobject in gebruik'
			OR v.vbo_status = 'verblijfsobject in gebruik (niet ingemeten)'
			OR v.vbo_status = 'verbouwing verblijfsobject'
			OR v.vbo_status = 'verblijfsobject buiten gebruik')
			AND p.bestemming = 'wonen'
	 	GROUP BY p.buffer_250) AS wp_250
	ON
		ST_Intersects(g.geom, wp_250.buffer_250)
	WHERE
		EXTRACT(YEAR FROM g.jaar) = 2022
	GROUP BY
		g.gm_naam) AS p250
	ON
		p250.gm_naam = g.gm_naam

--Buffer_500. There is a problem with overlapping buffers so that houses are
--counted for each buffered polygon
JOIN (
	SELECT DISTINCT
		g.gm_naam
		, SUM(wp_500.aantal_huizen_500) AS gebouwde_woningen_500
	FROM
		gemeenten_public.gemeentegrenzen g
	JOIN (
		SELECT
			COUNT(v.vbo_id) AS aantal_huizen_500
			, p.buffer_500 AS buffer_500
		FROM vbo v
		JOIN
			plannen_2010 p
		ON
			ST_Intersects(v.vbo_geom, p.buffer_500)
		WHERE
			v.bouwjaar >= 2010
			AND (v.vbo_status = 'verblijfsobject in gebruik'
			OR v.vbo_status = 'verblijfsobject in gebruik (niet ingemeten)'
			OR v.vbo_status = 'verbouwing verblijfsobject'
			OR v.vbo_status = 'verblijfsobject buiten gebruik')
			AND p.bestemming = 'wonen'
	 	GROUP BY p.buffer_500) AS wp_500
	ON
		ST_Intersects(g.geom, wp_500.buffer_500)
	WHERE
		EXTRACT(YEAR FROM g.jaar) = 2022
	GROUP BY
		g.gm_naam) AS p500
	ON
		p500.gm_naam = g.gm_naam

	

--7. How many plan locations were part of the built environment (bebouwde kom) in 2010? 
--Please describe the number of projected houses involved and break the numbers down for 
--each municipality (2022). Compare this with the number of houses actually built in 
--and outside the built environment. 

--1. First get all the overlapping polygons
--2. Join with plannen_2010 totaal
--3. create table with new plan table and municipalities and vbo
--4. Aggregate everything

--Step 1, 2
CREATE TABLE plannen_bebouwdekom AS

SELECT
	p.id
	, ROUND(ST_Area(ST_INTERSECTION(p.geom, ST_GeomFromWKB(b."vlakGeometrie", 28992)))) AS overlap
	, ROUND(ST_Area(ST_INTERSECTION(p.geom, ST_GeomFromWKB(b."vlakGeometrie", 28992))) / ST_Area(p.geom) *100) AS perc_overlap
	, b.bebouwdekom
	, p.geom AS plan_geom
	, b."vlakGeometrie" AS bkom_geom
FROM
	plannen_2010 p
JOIN
	brt_public.plaats b
	ON
	ST_Intersects(p.geom, ST_GeomFromWKB(b."vlakGeometrie", 28992))
WHERE 
	b.bebouwdekom = 'ja'
	AND p.bestemming = 'wonen';
	
CREATE INDEX sdix_plannen_bebwoudekom_plannen ON plannen_bebouwdekom USING GIST (plan_geom);
CREATE INDEX sdix_plannen_bebwoudekom_bkom ON plannen_bebouwdekom USING GIST (bkom_geom);

--Step 1,2 

CREATE TABLE plannen_bkom AS

SELECT
	p.*
	, pb.overlap
	, pb.perc_overlap
	, pb.bkom_geom
FROM plannen_2010 p

LEFT JOIN 
	plannen_bebouwdekom pb
	ON
	p.id = pb.id

WHERE p.bestemming = 'wonen';
	
CREATE INDEX sdix_plannen_geom_bkom ON plannen_bkom USING GIST (bkom_geom);
CREATE INDEX sdix_plannen_geom ON plannen_bkom USING GIST (geom);

UPDATE plannen_bkom
SET perc_overlap = 0
WHERE perc_overlap IS NULL;

UPDATE plannen_bkom
SET overlap = 0
WHERE overlap IS NULL;

--Step 3,4


--We don't know exactly where the individual houses were planned, so the final number is not that exact.
--It could be, for instance, that a plan partially overlaps with the bebouwdekom, but we don't know
--how many houses were planned in the bebouwdekom and how many outside of it.

SELECT DISTINCT
	g.gm_naam AS gemeente
	, binnen.gepland_binnen_bebouwdekom AS gepland_binnen_bebouwdekom
	, buiten.gepland_buiten_bebouwdekom AS gepland_buiten_bebouwdekom
FROM
	gemeenten_public.gemeentegrenzen g 

--houses in planning areas

JOIN (
	SELECT DISTINCT
		g.gm_naam
		,SUM(CASE 
		WHEN p_binnen.woningen_b IS NULL THEN p_binnen.woningen_o
		WHEN p_binnen.woningen_o IS NULL THEN p_binnen.woningen_b
		ELSE p_binnen.woningen_b + p_binnen.woningen_o
		END) AS gepland_binnen_bebouwdekom
	FROM 
		plannen_bkom p_binnen
	JOIN
		gemeenten_public.gemeentegrenzen g
	ON
		ST_Intersects(p_binnen.geom, g.geom)
	WHERE
		p_binnen.overlap != 0
		AND EXTRACT(YEAR FROM g.jaar) = 2022
	GROUP BY
		g.gm_naam) AS binnen
	ON binnen.gm_naam = g.gm_naam

--Plans within and outside bebouwdekom


--Within

SELECT DISTINCT
	g.gm_naam AS gemeente
	, COUNT(p.id) AS number_of_plans_in_built_area
	, SUM(p.overlap) AS planning_zone_in_built_area
	, ROUND(AVG(p.perc_overlap)) AS avg_perc_overlap_in_built_area
FROM
	gemeenten_public.gemeentegrenzen g
JOIN
	plannen_bkom p
ON
	ST_Intersects(p.geom, g.geom)
WHERE
	EXTRACT(YEAR FROM g.jaar) = 2022
	AND p.bestemming = 'wonen'
	AND p.ovelap > 0
GROUP BY
	g.gm_naam

--Outside

SELECT DISTINCT
	g.gm_naam AS gemeente
	, COUNT(p.id) AS number_of_plans_in_built_area
	, SUM(p.overlap) AS planning_zone_in_built_area
	, ROUND(AVG(p.perc_overlap)) AS avg_perc_overlap_in_built_area
FROM
	gemeenten_public.gemeentegrenzen g
JOIN
	plannen_bkom p
ON
	ST_Intersects(p.geom, g.geom)
WHERE
	EXTRACT(YEAR FROM g.jaar) = 2022
	AND p.bestemming = 'wonen'
	AND p.ovelap = 0
GROUP BY
	g.gm_naam

--Planned houses outside bebouwdekom

JOIN (
	SELECT DISTINCT
		g.gm_naam
		,SUM(CASE 
		WHEN p_buiten.woningen_b IS NULL THEN p_buiten.woningen_o
		WHEN p_buiten.woningen_o IS NULL THEN p_buiten.woningen_b
		ELSE p_buiten.woningen_b + p_buiten.woningen_o
		END) AS gepland_buiten_bebouwdekom
	FROM 
		plannen_bkom p_buiten
	JOIN
		gemeenten_public.gemeentegrenzen g
	ON
		ST_Intersects(p_buiten.geom, g.geom)
	WHERE
		p_buiten.overlap = 0
		AND EXTRACT(YEAR FROM g.jaar) = 2022
	GROUP BY
		g.gm_naam) AS buiten
	ON buiten.gm_naam = g.gm_naam



--8. What houses were built on locations that weren’t in the plans of 2010, 
--but were built on land owned by building and development companies, 
--municipalities and social housing corporations (2019). 
--And the same question, but then for land owned by building and development companies in 2022? 

--Starting a first try

SELECT
	v.vbo_id
	, v.bouwjaar
	, r.id
	, r.categorie_pbl
	, r.geom AS rvo_geom
	, v.vbo_geom
FROM 
	vbo v
JOIN
	grondeigendom_rvo_2019 r
	ON
	ST_Intersects(r.geom, v.vbo_geom)
WHERE
	v.bouwjaar >= 2021
	AND (r.categorie_pbl = 'Publiek_gemeente'
	--OR r.categorie_pbl = 'Bedrijf_projectontwikkelaar_of_bouwer'
	--OR r.categorie_pbl = 'Woningbouworganisatie_of_vve'
		)

--Second try

CREATE TABLE rvo_gemeenten AS 

SELECT
	g.gm_naam
	, r.categorie_pbl AS categorie
	, r.id
	, r.geom AS rvo_geom
FROM
	gemeenten_public.gemeentegrenzen g
JOIN
	grondeigendom_rvo_2019 r
	ON
	ST_Intersects(r.geom, g.geom)
WHERE
	(r.categorie_pbl = 'Publiek_gemeente'
	OR r.categorie_pbl = 'Bedrijf_projectontwikkelaar_of_bouwer'
	OR r.categorie_pbl = 'Woningbouworganisatie_of_vve')
	AND EXTRACT(YEAR FROM g.jaar) = 2022;
CREATE INDEX sidx_rvo_gemeente ON rvo_gemeenten USING GIST (rvo_geom)

CREATE TABLE gemeenten_woningen_buiten_plangebied AS

SELECT 
	vbo_id
	, v.vbo_geom
FROM
	vbo v
LEFT JOIN
	plannen_2010 p
	ON
	ST_Disjoint(v.vbo_geom, p.geom)
WHERE 
	v.bouwjaar >= 2010
	--filter op type woning
	AND (v.vbo_status = 'verblijfsobject in gebruik'
		 OR v.vbo_status = 'verblijfsobject in gebruik (niet ingemeten)'
		 OR v.vbo_status = 'verbouwing verblijfsobject'
		OR v.vbo_status = 'verblijfsobject buiten gebruik')
	--filter op bestemmingsplan
	AND p.bestemming = 'wonen'
	


--9. What parcels were bought by which building and development company 
--that was also in the plans of 2010? 

CREATE TABLE bouw_plannen_2010 AS

SELECT
	g.id AS grond_id
	, g.naam
	, g.inschrijfdatum_stuk
	, p.id AS plan_id
	, p.woningen_b
	, p.woningen_o
	, p.plannaam
	, p.startdatum
	, p.einddatum
	, ST_Area(g.geom) AS area_perceel
	, ST_Area(ST_INTERSECTION(p.geom, g.geom)) AS overlap
	, ROUND(ST_Area(ST_INTERSECTION(g.geom, p.geom)) / ST_Area(g.geom) * 100) AS perc_overlap
	, p.geom AS plan_geom
	, g.geom AS bouw_geom

FROM
	grondeigendom_bouw_2022 g
JOIN
	plannen_2010 p
	ON
	ST_Intersects(g.geom, p.geom)
WHERE
	p.bestemming = 'wonen';
	
CREATE INDEX sidx_bouw_plannen ON bouw_plannen_2010 USING GIST (bouw_geom);
CREATE INDEX sidx_plannen_bouw ON bouw_plannen_2010 USING GIST (plan_geom);


--10. Perform the same calculations as described above, 
--but for each year for which planning data is available (1997, 2002-2009). 
--Describe the problems that occur when comparing the different years. 
