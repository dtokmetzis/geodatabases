# Geodatabases

This repository accompanies the assignment TAA3 and TAA4 for the UNIGIS course geodatabases. This is still work in progress so be sure to check with the author the status of the project before using any data or code.

## Data sources

Data sources used are:

1. BAG pand and BAG vbo through [Geoparaat](https://geoparaat.nl). The tables were imported into PostgreSQL using ogr2ogr. For instance with the command:

```
ogr2ogr -overwrite -f PostgreSQL "PG:dbname=bagv2" snapshot_20220101.gpkg
```

2. Top10NL plaats and functioneel gebied through [PDOK](https://www.pdok.nl/downloads/-/article/basisregistratie-topografie-brt-topnl). The tables were imported into PostgreSQL using ogr2ogr. 

3. Plannen 1997, 2002, 2006 and 2010 from De Nieuwe Kaart available in the [data folder](https://github.com/dtokmetzis/geodatabases/data) of this repo. 

4. Plannen_eib_2021 from the EIB (Economisch Instituut voor de Bouw), available in the [data folder](https://github.com/dtokmetzis/geodatabases/data) of this repo. 

5. Gemeentegrenzen, available at [het Centraal Bureau voor de Statistiek](https://www.cbs.nl/nl-nl/reeksen/geografische-data). 

A postgres dump and additional non-public information is available on request. 