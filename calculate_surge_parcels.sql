-- sample distance query
select ST_Distance(ST_SetSRID(s.geom, 2236), (select geom from volusia.gis_parcels p2 where p2.altkey=3565215))/5280 as distance
from volusia.storm_surge s
order by ST_SetSRID(s.geom, 2236) <-> (select p2.geom from volusia.gis_parcels p2 where p2.altkey=3565215);
-- sample category query
select s.cat
from volusia.storm_surge s
order by ST_SetSRID(s.geom, 2236) <-> (select p2.geom from volusia.gis_parcels p2 where p2.altkey=3565215)
limit 1;

-- create and instantiate the surge_parcels table
drop table if exists volusia.surge_parcels;
create table volusia.surge_parcels (
	parid int, 
	dist_storm_surge float, 
	storm_surge_category integer
);
INSERT INTO volusia.surge_parcels (parid, dist_storm_surge, storm_surge_category)
SELECT parid, NULL, NULL
FROM volusia.parcel;


DO
LANGUAGE plpgsql
$do$
DECLARE
g1 geometry;
rec RECORD;
cat integer;
distanceFromSurge float;
total_parcels integer;
BEGIN
	-- it's nice to have a running count to be able to estimate how much time is left to run the query
	select count(DISTINCT altkey) into total_parcels 
	from volusia.gis_parcels g, volusia.surge_parcels p 
	where geom is not NULL and p.parid=g.altkey; --265149
		
	-- the big loop
	for rec in (select DISTINCT ON (g.altkey) altkey, g.geom
				from volusia.gis_parcels g, volusia.surge_parcels p
				where p.dist_storm_surge is NULL AND p.storm_surge_category is NULL and g.geom IS NOT NULL and p.parid=g.altkey) loop  --265149
		g1:=rec.geom;
			
		select ST_Distance(ST_SetSRID(s.geom, 2236), (g1))/5280, s.cat into distanceFromSurge, cat
			from volusia.storm_surge s
			order by ST_SetSRID(s.geom, 2236) <-> (g1)
			limit 1;  -- shortest distance is always first because of the order by clause
		
		total_parcels:=total_parcels-1;
		
		UPDATE volusia.surge_parcels SET dist_storm_surge = distanceFromSurge, storm_surge_category = cat WHERE parid=rec.altkey;
		RAISE NOTICE 'set to % % %, % parcels left', rec.altkey, cat, distanceFromSurge, total_parcels;
	END LOOP;
End; $do$;