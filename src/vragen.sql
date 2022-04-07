--1. How many houses were planned in each municipality in 2010? 
--How would this translate to municipalities of 2022?

SELECT
	g.gm_naam AS gemeente,
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
	EXTRACT(YEAR FROM g.jaar) = 2022
	AND p.bestemming = 'wonen'
	AND NOT (p.woningen_b IS NULL
		AND p.woningen_o IS NULL)
GROUP BY
	gemeente
	ORDER BY
gepland_2010 DESC;

--TODO: sum of houses differs between gemeenten_2010 and gemeenten_2022.
--Why?

--2. How many houses were built within the planning locations within the timeframe of the plans 
--(e.g. a plan could have a project date range from 2010 to 2015)? 
--Provide an overview of each municipality and each year.
--AND
--3. How many houses were built within the planning location after the project data provided in 2010? 
--Provide an overview of each municipality and each year.

CREATE TABLE huizen_plannen_gemeenten AS

SELECT DISTINCT
	g.gm_naam AS gemeente
	, hg.huizen_in_gemeente AS gebouwd_in_gemeente_na_2010
	, pg.geplande_woningen
	, hg.huizen_in_gemeente - pg.geplande_woningen AS meer_gebouwd_dan_gepland
	, pv.huizen_gebouwd_in_plangebied
	, pg.geplande_woningen - pv.huizen_gebouwd_in_plangebied AS huizen_gebouwd_buiten_plangebied
	, pv_tijd.huizen_gebouwd_in_plangebied_op_tijd
	, g.geom
FROM
	gemeenten_public.gemeentegrenzen g

--huizen per gemeente

lEFT JOIN (
	SELECT 
	 	COUNT(vbo_id) AS huizen_in_gemeente
	 	, g.gm_naam
	 FROM 
		vbo v
	 JOIN 
		gemeenten_public.gemeentegrenzen g
	 ON 
		ST_Intersects(v.vbo_geom, g.geom)
	 WHERE 
		(v.vbo_status = 'verblijfsobject in gebruik'
		AND v.bouwjaar >= 2010
	 	OR v.vbo_status = 'verblijfsobject in gebruik (niet ingemeten)'
	 	OR v.vbo_status = 'verbouwing verblijfsobject')
	 	AND EXTRACT(YEAR FROM g.jaar) = 2022
	 GROUP BY 
		g.gm_naam) AS hg
	 ON 
	 	hg.gm_naam = g.gm_naam

--geplande huizen in gemeenten	

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


--huizen in plangebied

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
		--filter op type woning
		AND (v.vbo_status = 'verblijfsobject in gebruik'
			 OR v.vbo_status = 'verblijfsobject in gebruik (niet ingemeten)'
			 OR v.vbo_status = 'verbouwing verblijfsobject')
		--filter op bestemmingsplan
		AND p.bestemming = 'wonen'
	 GROUP BY p.geom) AS wp
	ON ST_Intersects(g.geom, wp.plan_geom)
	WHERE 
		EXTRACT(YEAR FROM g.jaar) = 2022
	GROUP BY
		g.gm_naam) AS pv
	ON pv.gm_naam = g.gm_naam
	
--Huizen in planperiode

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
			 OR v.vbo_status = 'verbouwing verblijfsobject')
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
	
CREATE INDEX sidx_huizen_plannen_gemeenten ON huizen_plannen_gemeenten USING GIST(geom);
		 
	  

	


	


--4. How many houses were built outside the planning locations? 
--Give an overview of each municipality and each year. 



--5. Create a map for the whole of the Netherlands showing the difference between planned houses 
--and built houses in 2022 based on the different plans of 1997-2010. 



--6. How many houses were built just outside the planning locations 
--(use 250m and 500m buffers) in the period 2010-2022 in each municipality (2022)? 




--7. How many plan locations were part of the built environment (bebouwde kom) in 2010? 
--Please describe the number of projected houses involved and break the numbers down for 
--each municipality (2022). Compare this with the number of houses actually built in 
--and outside the built environment. 




--8. What houses were built on locations that weren’t in the plans of 2010, 
--but were built on land owned by building and development companies, 
--municipalities and social housing corporations (2019). 
--And the same question, but then for land owned by building and development companies in 2022? 





--9. What parcels was bought by which building and development company 
--that was also in the plans of 2010? 




--10. Perform the same calculations as described above, 
--but for each year for which planning data is available (1997, 2002-2009). 
--Describe the problems that occur when comparing the different years. 
