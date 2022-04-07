Relevant tables:

1. pand: fid, identificatie, bouwjaar, woningtype, statuscode, begindatum, einddatum, nr_woon, geom
2. pand_status_code: fid, code, label
3. pand_woningtype: fid, code, label
4. vbo: fid, identificatie, oppervlakte, nummeraanduiding_id, pand_id, pand_id_geom, statuscode, begindatum, einddatum, woon, geom
5. vbo_status_code: fid, code, label
6. vbo_gerelateerd_pand, fid, identificatie_pand_id


--pand_status_code
--relevant codes: 4, 5, 9

0	"onbekend"
1	"bouwvergunning verleend"
2	"niet gerealiseerd pand"
3	"bouw gestart"
4	"pand in gebruik (niet ingemeten)"
5	"pand in gebruik"
6	"sloopvergunning verleend"
7	"pand gesloopt"
8	"pand buiten gebruik"
9	"verbouwing pand"
10	"pand ten onrechte opgevoerd"

--pand_woningtype

0	"geen woonpand"
1	"vrijstaand"
2	"twee onder 1 kap"
3	"hoekwoning"
4	"tussenwoning"
5	"meergezinspand"

--vbo_status_code
--relevant codes: 3, 4, 5, 7

0	"onbekend"
1	"verblijfsobject gevormd"
2	"niet gerealiseerd verblijfsobject"
3	"verblijfsobject in gebruik (niet ingemeten)"
4	"verblijfsobject in gebruik"
5	"verblijfsobject ingetrokken"
6	"verblijfsobject buiten gebruik"
7	"verbouwing verblijfsobject"
8	"verblijfsobject ten onrechte opgevoerd"


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