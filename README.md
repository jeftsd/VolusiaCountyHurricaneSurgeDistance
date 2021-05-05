# VolusiaParcelPriceEstimator
The goal of this GitHub project is to determine the distance from each parcel in Volusia County to the nearest floodzone, and its severity. 

**Why?** This information can be extremely useful when searching for properities in the Volusia County area since the state of Florida is susceptible to flood every year during hurricane season. This can help existing residents understand when their house might be impacted by hurricanes and/or flooding, and can help prospective residents make informed decisions about their residential purchases.

**FYI:** The information for Storm Surge areas is gathered from the Volusia County website at [this page](http://maps.vcgov.org/gis/download/shapes.htm). The files for Storm Surges were last updated in 2017, so the maps might be slightly off. According to the Volusia County website, "This Storm Surge data was developed as part of the Statewide Regional Evacuation Study (SRES) conducted by the Florida Department of Emergency Management and is an output of the storm surge model created for the SRES study. **THIS DATA IS FINAL**, metadata was created by the East Central Florida Regional Planning Council. **Last Revision Date April 2017**"

Information about the Storm Surge Categories:
|  Category 	|  Sustained Winds  	| Types of Damage Due to Hurricane Winds                                                                                                                                                                                                                                                                                                                                                          	|
|:---------:	|:-----------------:	|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	|
|     1     	|     74-95 mph     	| Very dangerous winds will produce some damage: Well-constructed frame homes could have damage to roof, shingles, vinyl siding and gutters. Large branches of trees will snap and shallowly rooted trees may be toppled. Extensive damage to power lines and poles likely will result in power outages that could last a few to several days.                                                    	|
|     2     	|     96-110 mph    	| Extremely dangerous winds will cause extensive damage: Well-constructed frame homes could sustain major roof and siding damage. Many shallowly rooted trees will be snapped or uprooted and block numerous roads. Near-total power loss is expected with outages that could last from several days to weeks.                                                                                    	|
| 3 (major) 	|    111-129 mph    	| Devastating damage will occur: Well-built framed homes may incur major damage or removal of roof decking and gable ends. Many trees will be snapped or uprooted, blocking numerous roads. Electricity and water will be unavailable for several days to weeks after the storm passes.                                                                                                           	|
| 4 (major) 	|    130-156 mph    	| Catastrophic damage will occur: Well-built framed homes can sustain severe damage with loss of most of the roof structure and/or some exterior walls. Most trees will be snapped or uprooted and power poles downed. Fallen trees and power poles will isolate residential areas. Power outages will last weeks to possibly months. Most of the area will be uninhabitable for weeks or months. 	|
| 5 (major) 	| 157 mph or higher 	| Catastrophic damage will occur: A high percentage of framed homes will be destroyed, with total roof failure and wall collapse. Fallen trees and power poles will isolate residential areas. Power outages will last for weeks to possibly months. Most of the area will be uninhabitable for weeks or months.                                                                                  	|

***

# Instructions:
The repository has the following files: `surge_parcels_table.csv`, `calculate_surge_parcels.sql`, and `build_tables.sql`.

**Option 1:** The easiest way to import the storm surge distances data is to download `surge_parcels_table.csv`, import it to your database, and join it with the parcels table on the parid.

To import the `surge_parcels` table:
```postgres
drop table if exists volusia.surge_parcels;

create table volusia.surge_parcels (
	parid int, 
	dist_storm_surge float, 
	storm_surge_category integer
);

COPY volusia.surge_parcels FROM 'C:\temp\cs540\surge_parcels_table.csv' WITH (FORMAT 'csv', DELIMITER E'\t', NULL '', HEADER);
```

To join the `surge_parcels` table with `parcel`:
```postgres
ALTER TABLE volusia.parcel
	ADD column dist_storm_surge float,
	ADD column storm_surge_category integer;
SELECT * FROM volusia.parcel p LEFT OUTER JOIN volusia.surge_parcels s ON (p.parid=s.parid) WHERE s.dist_storm_surge IS NOT NULL;
  UPDATE volusia.parcel p
  SET    dist_storm_surge = s.dist_storm_surge, storm_surge_category = s.storm_surge_category
  FROM   volusia.surge_parcels s
  WHERE  p.parid = s.parid;
```

Please note that there are many parcels that had either invalid or null geometry data, therefor there are many parcels in the `surge_parcels` table that have a `NULL` distance/category listed. This is expected behaviour.


**Option 2:** Another option is to follow the same steps I did to acquire the distances which requires calculating the distances between the storm surges and parcel geometries.

1. Download the Shape files for the Volusia County Hurricane Storm Surge Lines [here](http://maps.vcgov.org/gis/download/shpfiles/stormsurge.zip).
2. Load the Shape file (`Strm_SurgeFDEM2017.shp`) into QGIS as a layer.
3. Import the layer and its data into PostgreSQL using the DB Manager Import/Export feature.
4. Run the code from the file `calculate_surge_parcels.sql` which will create the `surge_parcels` and then fill it with all of the relevant data, using the geometry from `volusia.gis_parcels`

NOTE: The CSV may look empty but if you scroll through it there are entries. I used the `parcel` table to instantiate the `surge_parcels` table and those empty/null cells are results of `parids` that don't have matching geometries in `volusia.gis_parcels`.
