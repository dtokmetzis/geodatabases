--Tables:
--bouw_namen
--grondeigendom_bouw_2022
--grondeigendom_rvo_2019
--top10nl_functioneel_gebied_totaal
--top10nl_plaats_totaal

--Create spatial indexes on top10s

CREATE INDEX functioneel_gebied_idx ON top10nl_functioneel_gebied_totaal USING GIST (geom);
CREATE INDEX plaats_totaal_idx ON top10nl_plaats_totaal USING GIST (geom);

--First get some basic statistics on grondeigendom_bouw

--Wie heeft het meeste gebied?

SELECT
	b.naam_genormaliseerd AS naam,
	ROUND(SUM(ST_Area(g.geom))) AS oppervlakte
FROM
	grondeigendom_bouw_2022 g
JOIN
	bouw_namen b
	ON
	b.naam_rechtspersoon = g.naam
GROUP BY
	b.naam_genormaliseerd
ORDER BY oppervlakte DESC;

--Oppervlakte per jaar per bedrijf

SELECT
	b.naam_genormaliseerd AS naam,
	EXTRACT(YEAR FROM g.inschrijfdatum_stuk) AS jaar,
	ROUND(SUM(ST_Area(g.geom))) AS oppervlakte
FROM
	grondeigendom_bouw_2022 g
JOIN
	bouw_namen b
	ON
	b.naam_rechtspersoon = g.naam
GROUP BY
	b.naam_genormaliseerd,
	jaar
ORDER BY oppervlakte DESC;

--Oppervlakte per jaar

SELECT
	EXTRACT(YEAR FROM g.inschrijfdatum_stuk) AS jaar,
	ROUND(SUM(ST_Area(g.geom))) AS oppervlakte
FROM
	grondeigendom_bouw_2022 g
GROUP BY
	jaar
ORDER BY jaar DESC;

--Bebouwde kom

--1. Vind alle percelen
--2. Bekijk welke overlappen met bebouwde kom
--3. Als overlap, dan oppervlakte overlap en percentage van perceel
--4. Als geen overlap, dan oppervlakte overlap en percentage is 0

CREATE TABLE eigendom_bebouwdekom AS

SELECT DISTINCT
	bn.naam_genormaliseerd AS naam_bedrijf
	, SUM(ST_Area(b.geom)) AS oppervlakte_perceel
	, p.bebouwdekom
	, g.gm_naam AS gemeentenaam
	, b.geom AS perceel_geom
	, g.geom AS gemeente_geom
FROM
	grondeigendom_bouw_2022 b
LEFT JOIN 
	brt_public.plaats p
	ON
	ST_Intersects(b.geom, ST_Buffer(ST_GeomFromWKB(p."vlakGeometrie", 28992), -1)) --set buffer to -1 to exclude parcels that border on a bebouwdekom
JOIN
	gemeenten_public.gemeentegrenzen g
	ON
	ST_Intersects(g.geom, b.geom)
JOIN
	bouw_namen bn
	ON
	bn.naam = b.naam
WHERE 
	EXTRACT(YEAR FROM g.jaar) = 2022
GROUP BY
	naam_bedrijf
	, bebouwdekom
	, gemeentenaam
	, perceel_geom
	, gemeente_geom;

	
CREATE INDEX sidx_gemeente_geom ON eigendom_bebouwdekom USING GIST (gemeente_geom);
CREATE INDEX sidx_perceel_geom ON eigendom_bebouwdekom USING GIST (perceel_geom);

--Of via een andere tabel...

CREATE TABLE grondeigendom_bebouwdekom AS

SELECT
	g.id
	, ST_Area(ST_INTERSECTION(g.geom, ST_GeomFromWKB(b."vlakGeometrie", 28992))) AS overlap
	, ROUND(ST_Area(ST_INTERSECTION(g.geom, ST_GeomFromWKB(b."vlakGeometrie", 28992))) / ST_Area(g.geom) *100) AS perc_overlap
	, b.bebouwdekom
	, g.geom AS perceel_geom
	, b."vlakGeometrie" AS bkom_geom
FROM
	grondeigendom_bouw_2022 g
JOIN
	brt_public.plaats b
	ON
	ST_Intersects(g.geom, ST_GeomFromWKB(b."vlakGeometrie", 28992))
WHERE 
	b.bebouwdekom = 'ja';
	
CREATE INDEX sidx_perceel_geom ON grondeigendom_bebouwdekom USING GIST (perceel_geom);
CREATE INDEX sidx_bkom_geom ON grondeigendom_bebouwdekom USING GIST (bkom_geom);


--Join with bezit

CREATE TABLE bezit_bkom AS

SELECT
	g.*
	, b.bebouwdekom
	, b.overlap
	, b.perc_overlap
	, b.bkom_geom
FROM grondeigendom_bouw_2022 g
LEFT JOIN 
	grondeigendom_bebouwdekom b
	ON
	g.id = b.id

--Replace NULL values in bebouwdekom with 'nee'

UPDATE eigendom_bebouwdekom
SET bebouwdekom = 'nee'
WHERE bebouwdekom IS NULL;

--Reken percentages uit

SELECT DISTINCT
	e.naam_bedrijf
	, ROUND(SUM(oppervlakte_perceel)) / 1000000 AS in_bkom
	, buiten.buiten_bkom / 1000000 AS buiten_bkom 
	, ROUND(ROUND(SUM(oppervlakte_perceel)) / (ROUND(SUM(oppervlakte_perceel)) + buiten.buiten_bkom) * 100) AS perc_in_bkom
FROM eigendom_bebouwdekom e
JOIN (SELECT naam_bedrijf AS bedrijf
	  , ROUND(SUM(oppervlakte_perceel)) AS buiten_bkom
	  FROM eigendom_bebouwdekom
	  WHERE bebouwdekom= 'nee'
	  GROUP BY naam_bedrijf) AS buiten
	  ON buiten.bedrijf = e.naam_bedrijf
WHERE bebouwdekom = 'ja'
GROUP BY
	naam_bedrijf,
	buiten_bkom

--RVO

-- Create table

CREATE TABLE grondeigendom_rvo AS

SELECT
	g.id
	, ST_Area(ST_INTERSECTION(g.geom, r.geom)) AS overlap
	, ROUND(ST_Area(ST_INTERSECTION(g.geom, r.geom)) / ST_Area(g.geom) *100) AS perc_overlap
	, g.geom AS perceel_geom
	, r.geom AS rvo_geom
FROM
	grondeigendom_bouw_2022 g
JOIN
	grondeigendom_rvo_2019 r
	ON
	ST_Intersects(g.geom, r.geom)
WHERE 
	r.categorie_pbl = 'Bedrijf_projectontwikkelaar_of_bouwer';
	
CREATE INDEX sidx_perceel_geom ON grondeigendom_rvo USING GIST (perceel_geom);
CREATE INDEX sidx_rvo_geom ON grondeigendom_rvo USING GIST (rvo_geom);

UPDATE bezit_bkom
SET perc_overlap = 0
WHERE perc_overlap IS NULL;

UPDATE bezit_bkom
SET overlap = 0
WHERE overlap IS NULL;

--Create final bezit rvo table

CREATE TABLE bezit_rvo AS

SELECT
	g.*
	, r.overlap
	, r.perc_overlap
	, r.rvo_geom
FROM grondeigendom_bouw_2022 g
LEFT JOIN 
	grondeigendom_rvo r
	ON
	g.id = r.id;
	
CREATE INDEX sdix_rvo_geom_bezit ON bezit_rvo USING GIST (rvo_geom);

UPDATE bezit_rvo
SET perc_overlap = 0
WHERE perc_overlap IS NULL;

UPDATE bezit_rvo
SET overlap = 0
WHERE overlap IS NULL;