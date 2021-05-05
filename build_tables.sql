failed query to prevent accidentally running the entire file

select * from volusia.parcel limit 100;
select * from volusia.gis_parcels limit 100;

-- table to store new data
drop table if exists volusia.surge_parcels;
create table volusia.surge_parcels (
	parid int, 
	dist_storm_surge float, 
	storm_surge_category integer
);
INSERT INTO volusia.surge_parcels (parid, dist_storm_surge, storm_surge_category)
SELECT parid, NULL, NULL
FROM volusia.parcel;

-- add to parcel table
ALTER TABLE volusia.parcel
	ADD column dist_storm_surge float,
	ADD column storm_surge_category integer;

UPDATE volusia.parcel p
	SET    dist_storm_surge = s.dist_storm_surge, storm_surge_category = s.storm_surge_category
	FROM   volusia.surge_parcels s
	WHERE  p.parid = s.parid;
SELECT parid, luc_desc, dist_storm_surge, storm_surge_category FROM volusia.parcel WHERE dist_storm_surge=0;
SELECT count(*), storm_surge_category FROM volusia.parcel GROUP BY storm_surge_category;

-- for the data collection part of the project
ALTER TABLE volusia.sales_analysis
	ADD column dist_storm_surge float;

UPDATE volusia.sales_analysis p
	SET    dist_storm_surge = s.dist_storm_surge
	FROM   volusia.surge_parcels s
	WHERE  p.parid = s.parid;
SELECT parid, luc_desc, sale_date, price, dist_storm_surge FROM volusia.sales_analysis;
SELECT count(*) FROM volusia.sales_analysis WHERE dist_storm_surge < 1;

-- some sample queries to verify the database data
select * from volusia.gis_parcels where pid IS NOT null limit 50;
select pid, count(*) from volusia.gis_parcels group by pid;
select pid, count(*) from volusia.parcel group by pid;
select parid, geom from volusia.parcel where parid IS NOT null and geom IS NOT null limit 50;

select cat, count(*) from volusia.storm_surge group by cat;
select * from volusia.storm_surge;

-- make sure the parcel table isn't duplicated (thanks AWS)
select parid, count(*) from volusia.parcel group by parid having count(*) > 1;

-- compare the spatial reference identifiers for the relevant geometry columns
SELECT Find_SRID('volusia', 'gis_parcels', 'geom');  --2236
SELECT Find_SRID('volusia', 'storm_surge', 'geom');

-- query used to build the storm_surge table, but only on parcel #3565215
select cat, ST_Distance(ST_SetSRID(s.geom, 2236), (select geom from volusia.gis_parcels p2 where p2.altkey=3565215))/5280 as distance
from volusia.storm_surge s
order by ST_SetSRID(s.geom, 2236) <-> (select p2.geom from volusia.gis_parcels p2 where p2.altkey=3565215);

-- verify the data after the surge_parcels table is built
select count(*) from volusia.surge_parcels where dist_storm_surge is not NULL;
select count(*) from volusia.surge_parcels where dist_storm_surge is NULL;  -- expected because some parcels don't have geoms
select * from volusia.surge_parcels where dist_storm_surge is not NULL;
select * from volusia.surge_parcels where dist_storm_surge is NULL;  -- expected because some parcels don't have geoms
