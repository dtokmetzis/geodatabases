--PLANNEN_2010

--concat woningen_o and woningen_b

ALTER TABLE plannen_2010
ADD COLUMN woningen varchar(50);

UPDATE plannen_2010
SET woningen = 
	CASE WHEN 
		(woningen_b, woningen_o) IS NULL THEN NULL
    ELSE 
		concat(woningen_b, woningen_o) END;
		
ALTER TABLE plannen_2010
ALTER COLUMN woningen TYPE numeric USING woningen::numeric;

--change startdatum, einddatum to date

ALTER TABLE plannen_2010
ALTER COLUMN startdatum TYPE date USING to_date(startdatum, 'YYYY'),
ALTER COLUMN einddatum TYPE date USING to_date(einddatum, 'YYYY');

--clean dates and 0 values

UPDATE plannen_2010
SET einddatum = NULL
WHERE einddatum = '9999';

UPDATE plannen_2010
SET startdatum = NULL
WHERE startdatum = '9999';

UPDATE plannen_2010
SET dat_status = NULL
WHERE dat_status = '9999-01-01';

UPDATE plannen_2010
SET woningen_b = NULL
WHERE woningen_b = 0;
	
UPDATE plannen_2010
SET woningen_o = NULL
WHERE woningen_o = 0;

--drop fields

ALTER TABLE plannen_2010 
DROP COLUMN sl_wonen_b,
DROP COLUMN srt_object,
DROP COLUMN sl_wonen_o,
DROP COLUMN net_uitg_b,
DROP COLUMN net_uitg_o,
DROP COLUMN opp_ha_b,
DROP COLUMN opp_ha_o,
DROP COLUMN opp_bvo_b,
DROP COLUMN opp_bvo_o,
DROP COLUMN opmerking,
DROP COLUMN invoer_dat,
DROP COLUMN locnaam,
DROP COLUMN opm_plan,
DROP COLUMN reltermijn,
DROP COLUMN beheerder,
DROP COLUMN website,
DROP COLUMN infobeh_pl,
DROP COLUMN infobeheer,
DROP COLUMN gemnaam,
DROP COLUMN gemcode,
DROP COLUMN provnaam,
DROP COLUMN provcode,
DROP COLUMN opm_pl_txt,
DROP COLUMN legenda;

--rename columns

ALTER TABLE plannen_2010 
RENAME COLUMN opm_txt TO opmerking;

--PLANNEN_1997

--drop fields

ALTER TABLE plannen_1997
DROP COLUMN type_plan,
DROP COLUMN afgekort,
DROP COLUMN ontwerp,
DROP COLUMN stadsdeel,
DROP COLUMN provincie,
DROP COLUMN nummer,
DROP COLUMN layer,
DROP COLUMN type,
DROP COLUMN quadrant,
DROP COLUMN x,
DROP COLUMN y,
DROP COLUMN element,
DROP COLUMN ident,
DROP COLUMN regio,
DROP COLUMN aantal_ha,
DROP COLUMN aantal_m2,
DROP COLUMN teken_opp,
DROP COLUMN infrastruc,
DROP COLUMN woongebied,
DROP COLUMN kantoren,
DROP COLUMN werkgebied,
DROP COLUMN voorzienin,
DROP COLUMN groen,
DROP COLUMN recreatie,
DROP COLUMN natuur,
DROP COLUMN overig
DROP COLUMN gemeente,
DROP COLUMN cbscode,
DROP COLUMN legenda;

--clean aantal plannen

UPDATE plannen_1997
set aantal = replace(aantal, ' won', NULL);

UPDATE plannen_1997
SET aantal = replace(aantal, '< ', NULL);

UPDATE plannen_1997
SET aantal = replace(aantal, 'Onbekend', NULL);

UPDATE plannen_1997
SET aantal = replace(aantal, ',', '');

UPDATE plannen_1997
SET aantal_won = NULL
WHERE aantal_won = 0;

--rename

ALTER TABLE plannen_1997 
RENAME COLUMN aantal TO woningen;

ALTER TABLE plannen_1997
ALTER COLUMN woningen TYPE numeric USING woningen::numeric;

--PLANNEN_2002

--drop fields

ALTER TABLE plannen_2002
DROP COLUMN opmfg
DROP COLUMN omgeoobj,
DROP COLUMN eenheid,
DROP COLUMN netwondich,
DROP COLUMN gemnaam,
DROP COLUMN hafg,
DROP COLUMN relplan,
DROP COLUMN provnaam,
DROP COLUMN ontwerper,
DROP COLUMN toevdat,
DROP COLUMN datingeg,
DROP COLUMN haplan,
DROP COLUMN website1,
DROP COLUMN website2,
DROP COLUMN faseinuit,
DROP COLUMN dateingfg;

--clean startdatum and einddatum

UPDATE plannen_2002
SET startdat = NULL
WHERE startdat = 'onbekend';

UPDATE plannen_2002
SET einddat = NULL
WHERE einddat = 'onbekend';

-- to date

ALTER TABLE plannen_2002
ALTER COLUMN startdat TYPE date USING to_date(startdat, 'YYYY'),
ALTER COLUMN einddat TYPE date USING to_date(einddat, 'YYYY');

--rename fields

ALTER TABLE plannen_2002
RENAME COLUMN startdat TO startdatum;

ALTER TABLE plannen_2002
RENAME COLUMN einddat TO einddatum;

ALTER TABLE plannen_2002
RENAME COLUMN aantal TO woningen;

ALTER TABLE plannen_2002
RENAME COLUMN jurplanst TO planstatus;

ALTER TABLE plannen_2002
RENAME COLUMN unieknumfg TO unieknr;

ALTER TABLE plannen_2002
RENAME COLUMN dateingeg TO dat_status;

ALTER TABLE plannen_2002
RENAME COLUMN opmalg TO opmerking;

--PLANNEN_2006

-- drop fields

ALTER TABLE plannen_2006
DROP COLUMN won_p_ha,
DROP COLUMN bron,
DROP COLUMN planfase,
DROP COLUMN aanduiding,
DROP COLUMN won_v_hs,
DROP COLUMN won_sloop,
DROP COLUMN won_verbet,
DROP COLUMN verk_huur,
DROP COLUMN won_na_hs,
DROP COLUMN h_per_huur,
DROP COLUMN t_per_huur,
DROP COLUMN partijen,
DROP COLUMN bouwper,
DROP COLUMN fys_maatr,
DROP COLUMN gsb_plan,
DROP COLUMN hoort_bij,
DROP COLUMN invoerdat,
DROP COLUMN i_bestem,
DROP COLUMN i_aant_won,
DROP COLUMN i_won_p_ha,
DROP COLUMN i_aanduidi,
DROP COLUMN i_opmerkin,
DROP COLUMN i_won_v_hs,
DROP COLUMN i_won_sloo,
DROP COLUMN i_won_verb,
DROP COLUMN i_verk_huu,
DROP COLUMN i_won_na_h,
DROP COLUMN i_h_per_hu,
DROP COLUMN i_t_per_hu,
DROP COLUMN i_partijen,
DROP COLUMN i_bouwper,
DROP COLUMN i_fys_maat,
DROP COLUMN i_gsb_plan,
DROP COLUMN i_hoort_bi,
DROP COLUMN i_invoerda,
DROP COLUMN legenda,
DROP COLUMN gemeente,
DROP COLUMN provincie,
DROP COLUMN ontwerper,
DROP COLUMN website,
DROP COLUMN aand_plan,
DROP COLUMN opm_plan,
DROP COLUMN metadata,
DROP COLUMN p_hoort_by,
DROP COLUMN i_plannaam,
DROP COLUMN i_gemeente,
DROP COLUMN i_provinci,
DROP COLUMN i_plansoor,
DROP COLUMN i_planfase,
DROP COLUMN i_planstat,
DROP COLUMN i_dat_stat,
DROP COLUMN i_startdat,
DROP COLUMN i_einddatu,
DROP COLUMN i_bron,
DROP COLUMN i_ontwerpe,
DROP COLUMN i_website,
DROP COLUMN i_aand_pla,
DROP COLUMN i_opm_plan,
DROP COLUMN i_metadata,
DROP COLUMN i_p_hoortb;

--rename columns

ALTER TABLE plannen_2006
RENAME COLUMN idn TO unieknr;

ALTER TABLE plannen_2006
RENAME COLUMN bestem TO bestemming;

ALTER TABLE plannen_2006
RENAME COLUMN aant_won TO woningen;

--clean dates

UPDATE plannen_2006
SET dat_status = NULL
WHERE dat_status = '11111111';

UPDATE plannen_2006
SET startdatum = NULL
WHERE startdatum = '11111111';

UPDATE plannen_2006
SET einddatum = NULL
WHERE einddatum = '11111111';

--STILL TO DO!!!!!!!!!

ALTER TABLE plannen_2006
ALTER COLUMN startdatum TYPE date USING to_date(startdatum, 'YYYYMMDD'),
ALTER COLUMN einddatum TYPE date USING to_date(einddatum, 'YYYYMMDD'),
ALTER COLUMN dat_status TYPE date USING to_date(dat_status, 'YYYYMMDD');

--PLANNEN_EIB_2021

--concat opxx to einddatum (there is some data loss here)

ALTER TABLE plannen_eib_2021
ADD COLUMN einddatum varchar(20);

UPDATE plannen_eib_2021
        SET einddatum =   
        CASE  
			WHEN op2019 > 0 THEN '2019-01-01' 
			WHEN op202024 > 0 THEN '2024-01-01' 
			WHEN op202529 > 0 THEN '2029-01-01' 
			WHEN op20302050 > 0 THEN '2050-01-01'
            ELSE NULL
		END;
		
ALTER TABLE plannen_eib_2021
ALTER COLUMN einddatum TYPE date USING to_date(einddatum, 'YYYYMMDD');

ALTER TABLE plannen_eib_2021
RENAME COLUMN objectid TO unieknr;

ALTER TABLE plannen_eib_2021
RENAME COLUMN aantalrest TO woningen;

ALTER TABLE plannen_eib_2021
RENAME COLUMN datum TO dat_status;

ALTER TABLE plannen_eib_2021
RENAME COLUMN plantype TO plansoort;

--Drop fields

ALTER TABLE plannen_eib_2021
DROP COLUMN objectid_1,
DROP COLUMN et_id,
DROP COLUMN provincie,
DROP COLUMN gem_naam,
DROP COLUMN sloop,
DROP COLUMN op2019,
DROP COLUMN op202024,
DROP COLUMN op202529,
DROP COLUMN op20302050,
DROP COLUMN oplonb,
DROP COLUMN wtypggb,
DROP COLUMN wtypapp,
DROP COLUMN wtyponb,
DROP COLUMN huur,
DROP COLUMN koop,
DROP COLUMN schatting,
DROP COLUMN pslegenda,
DROP COLUMN uit,
DROP COLUMN hrkponb,
DROP COLUMN shape_leng,
DROP COLUMN shape_area;

--GRONDEIGENDOM_BOUW_2022

-- split table

CREATE TABLE bedrijven AS

SELECT 
	naam_niet_natuurlijke_persoon AS naam, 
	kvk_nummer, 
	soort_nnp, 
	b.naam_genormaliseerd
FROM 
	grondeigendom_bouw_2022 g
JOIN 
	bouw_namen b 
	ON 
	b.naam_rechtspersoon = g.naam_niet_natuurlijke_persoon
WHERE 
	g.kvk_nummer IS NOT NULL
GROUP BY 
	naam, 
	b.naam_genormaliseerd, 
	kvk_nummer, 
	soort_nnp;

--rename field

ALTER TABLE grondeigendom_bouw_2022
RENAME COLUMN naam_niet_natuurlijke_persoon TO naam;

--drop fields

ALTER TABLE grondeigendom_bouw_2022
DROP COLUMN oppervlakte_perceel,
DROP COLUMN pht,
DROP COLUMN vbo_id,
DROP COLUMN pand_id,
DROP COLUMN kvk_nummer,
DROP COLUMN soort_nnp,
DROP COLUMN pand_bouwjaar,
DROP COLUMN pandoppervlakte;

--GRONDEIGENDOM_RVO_2019

--drop fields

ALTER TABLE grondeigendom_rvo_2019
DROP COLUMN shape_area,
DROP COLUMN shape_length;

--rename field

ALTER TABLE grondeigendom_rvo_2019
RENAME COLUMN catagorie_pbl TO categorie_pbl;

--BRT_PLAATS

CREATE TABLE brt_plaats_totaal AS

SELECT * 
FROM 
	brt.top10nl_plaats_vlak
UNION
SELECT * 
FROM 
	brt.top10nl_plaats_multivlak;

--BRT_FUNCTIONEEL_GEBIED

CREATE TABLE brt_functioneel_gebied_totaal AS

SELECT * 
FROM 
	brt.top10nl_functioneel_gebied_vlak
UNION
SELECT * 
FROM 
	brt.top10nl_functioneel_gebied_multivlak;

--CREATE FOREIGN DATA WRAPPERS FOR BRT, BAG and Gemeenten

CREATE EXTENSION postgres_fdw;

CREATE SERVER brt_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', dbname 'brt');

CREATE USER MAPPING FOR CURRENT_USER
SERVER brt_server
OPTIONS (user 'xxxx', password 'xxxx'); --change arguments

CREATE SCHEMA brt_public;

IMPORT FOREIGN SCHEMA public
FROM SERVER brt_server
INTO brt_public;

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

CREATE SERVER gemeenten
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', dbname 'bestuurlijke_grenzen');

CREATE USER MAPPING FOR CURRENT_USER
SERVER gemeenten
OPTIONS (user 'xxxx', password 'xxxx'); --change arguments

CREATE SCHEMA gemeenten_public;
IMPORT FOREIGN SCHEMA public
FROM SERVER gemeenten
INTO gemeenten_public;

