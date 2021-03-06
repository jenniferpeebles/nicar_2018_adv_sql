/* First of all, thank you to Liz Lucas, who has taught this class in previous years, for posting her code here on Github. 
I have shamelessly copied it and tried to add on to it. Liz has the original code and the OSHA data for the class at 
https://github.com/eklucas/NICAR-Adv-SQL. */

/* So, let's first make sure all our records loaded and find out how many records are in our table if we don't know already. */

SELECT COUNT(*) 
FROM osha_inspection
;

/* Here's a handy trick: You can rename a field by using "as." Let me show you how by renaming that ugly COUNT(*) field. */

SELECT COUNT(*) AS total_number_of_records
FROM osha_inspection
;

/* Let's take a sneak peek at our data. You can take a peek at a large data set by using LIMIT.  */

SELECT *
FROM osha_inspection
LIMIT 100
;

/* Do we have duplicates we should be watching out for? Let's find out with DISTINCT. 
Note: This may take several minutes to run on
a table this large.  */

SELECT DISTINCT * 
FROM osha_inspection
LIMIT 2000000
;

/* Let's poke around a little more and get an idea of what's in the data and see if we can get a feel for how clean, or dirty, 
it might be. Let's look at the state field as an example. */

SELECT site_state, COUNT(*) AS number_of_this_state
FROM osha_inspection
GROUP BY 1
;

/* Are there blanks in the site_state field? */

SELECT *
FROM osha_inspection
WHERE site_state = ''
;

/* OK, so, there are some blanks in site_state. But what about blanks and nulls, too? */ 

SELECT *
FROM osha_inspection
WHERE site_state = '' OR site_state IS NULL
;

/* What about if there are 'N/A' in our site_state field? Let's count those, too. There aren't any N/As in this data, but
let's use this as an example to learn how to use IN to filter for multiple criteria at once easily.  */

SELECT *
FROM osha_inspection
WHERE site_state IN ('', 'N/A') OR site_state IS NULL
;

/* So, what date range does our table cover? Did they give us the date range we asked them for? 
Did they give us a few more months than we asked, or a few less, for some reason? */

SELECT open_date
FROM osha_inspection
ORDER BY 1 ASC
LIMIT 10
;

/* Now, flip that around ... */

SELECT open_date
FROM osha_inspection
ORDER BY 1 DESC
LIMIT 10
;

/* You can also get fancier and look at both the top and bottom of the list at the same time by using MAX. */

SELECT MAX(open_date) AS max_open_date, 
MIN(open_date) AS min_open_date
FROM osha_inspection
;

/* What happens when your data has a date field that is formatted like a text string? It won't sort right, and 
the computer can't do accurate date comparisons or do math with it. So let's reformat it into the right format, which
for MySQL is YYYY-MM-DD. Notice those are hyphens, not slashes. */

/* The first step to reformatting date data is to create a new, blank field that is actually formatted as a date. */

ALTER TABLE osha_inspection 
ADD COLUMN open_date2 DATE -- "Date" at the end here is data type for the field. It can also be VARCHAR, INTEGER, etc., if needed.  
AFTER open_date -- this just tells it where to situate the new field, otherwise, it'll stick it at the far end. 
;

/* Now, let's populate our new, empty field with data from the "open_date" field, but as we do that, we'll convert it to a date. 
We do this with an UPDATE query. */

UPDATE osha_inspection 
SET open_date2 = STR_TO_DATE(open_date, '%Y-%m-%d')
;

/* Let's take a peek and check our work. */

SELECT open_date, open_date2, COUNT(*) AS count_of_dates
FROM osha_inspection
GROUP BY 1, 2
;

/* Now, we've got a working date field. Let's put it to use by using some date functions. */

SELECT YEAR(open_date2), COUNT(*) AS inspections_this_year
FROM osha_inspection 
GROUP BY 1
ORDER BY 2 DESC
;


/* What if we just wanted to update some records in a table but not others? You can do that in an 
update query as well, using WHERE. */

ALTER TABLE osha_inspection
ADD COLUMN close_case_date2 DATE
AFTER close_case_date
;

UPDATE osha_inspection 
SET close_case_date2 = STR_TO_DATE(close_case_date, '%Y-%m-%d')
WHERE LEFT(close_case_date,4)='2015' 
;


/* What if we wanted to know, how long was the longest case open? MySQL has a whole slew of date and time functions. Let's use DATEDIFF. */

SELECT DATEDIFF(close_case_date, open_date) AS length_case_open
FROM osha_inspection
ORDER BY 1 DESC
;

/* But how long is that in years? You can do math with SQL! */

SELECT DATEDIFF(close_case_date2, open_date2)/365 AS length_case_open_in_years
FROM osha_inspection
ORDER BY 1 DESC
;

/* What if we want to filter and count at the same time? What inspections are in our data relating to the U.S. Postal Service? */

SELECT estab_name, COUNT(*) AS count_of_inspections
FROM osha_inspection
WHERE estab_name LIKE '%u%s%postal%service%' OR estab_name LIKE '%USPS%' OR estab_name LIKE '%postal%service%'
GROUP BY 1
;

/* Hmmm. There's one establishment we probably want to exclude in this list: "HIRUTS FLOWERS AND POSTAL SERVICE." 
Let's exclude them from our search with <>. */

SELECT estab_name, COUNT(*) AS count_of_inspections
FROM osha_inspection
WHERE (estab_name LIKE '%u%s%postal%service%' OR estab_name LIKE '%USPS%' OR estab_name LIKE '%postal%service%') AND estab_name <> 'HIRUTS FLOWERS AND POSTAL SERVICE'
;

/* Let's take a look at the inspections that are connected with a workplace or on-the-job accident. 
There's a helpful field near the end called osha_accident_indicator, which (according to the record layout) can have the values 1 or blank. */


SELECT osha_accident_indicator, COUNT(*) AS count_of_accident_indicators
FROM osha_inspection
GROUP BY 1
;

/* Looks like tens of thousands of inspections have been flagged as being associated with an accident. */

/* To find out more about the accidents, we'll have to bring in and join up data from a table that's just about accidents. */

/* The accident table has a lot of really interesting detail, like the event description. 
If we start digging into particular accidents, we're going to want this field. 
But the inspection table holds most of the crucial who-what-when-where-why, like where the accident took place. 
So we need both tables. */

/* So let's load our accidents table. */


DROP TABLE IF EXISTS osha_accident
;
CREATE TABLE osha_accident
(
summary_nr VARCHAR(10),
report_id VARCHAR(10),
event_date DATE DEFAULT NULL,
event_time VARCHAR(255) DEFAULT NULL,
event_desc VARCHAR(225),
event_keyword TEXT,
const_end_use VARCHAR(5),
build_stories INTEGER DEFAULT NULL,
nonbuilt_ht VARCHAR(5),
project_cost VARCHAR(5),
project_type VARCHAR(5),
sic_list VARCHAR(100),
fatality VARCHAR(2),
state_flag VARCHAR(2),
abstract_text VARCHAR(5)
)ENGINE=INNODB CHARSET=latin1
;

LOAD DATA LOCAL INFILE 'C:/Users/JP/Dropbox/osha_accident.csv'
INTO TABLE osha_accident
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 1 LINES
(
summary_nr,
report_id,
@event_date,
event_time,
event_desc,
event_keyword,
const_end_use,
@build_stories,
nonbuilt_ht,
project_cost,
project_type,
sic_list,
fatality,
state_flag,
abstract_text
)
SET
event_date = IF(@event_date NOT REGEXP '[0-9]', NULL, @event_date),
build_stories =IF(@build_stories NOT REGEXP '[0-9]', NULL, @build_stories)
;

/* So let's check and make sure all our records loaded in the accident table. */

SELECT COUNT(*) 
FROM osha_accident
;

/* Let's peek */

SELECT * 
FROM osha_accident
LIMIT 100
;

/* But wait ... Notice that there's no activity_nr field in this data. How will we join the two tables? The answer: 
There's a third table, the accident_injury table, that connects them.  (If the accident_injury table is not loaded on your computer
or you need to load it on your computer at home, there is a CREATE TABLE statement for it at the bottom of this file.) */

SELECT * 
FROM osha_accident_injury
LIMIT 100
;

/* OK, now before we go any further, we need to make sure our three tables are well-indexed. 

Let's make sure all 3 of our tables have primary keys and also have indexes on the fields we're going to be joining on. 
Let's add the primary key fields, which MySQL will automatically populate with AUTO_INCREMENT. 
The datatype for these is MEDIUMINT (medium integer). There's also TINYINT for small datasets and BIGINT for 
... guess what ... big data sets. */

ALTER TABLE osha_inspection
ADD COLUMN jp_id_num MEDIUMINT AUTO_INCREMENT PRIMARY KEY
;

ALTER TABLE osha_accident
ADD COLUMN jp_id_num MEDIUMINT AUTO_INCREMENT PRIMARY KEY
;

ALTER TABLE osha_accident_injury
ADD COLUMN jp_id_num MEDIUMINT AUTO_INCREMENT PRIMARY KEY
;

/* Next, let's create some indexes on the fields we'll be using in our joins. */

CREATE INDEX activity_nr ON osha_inspection (activity_nr)
;

CREATE INDEX rel_insp_nr ON osha_accident_injury (osha_accident_injury)
;

CREATE INDEX summary_nr ON osha_accident_injury (osha_accident_injury)
;

CREATE INDEX summary_nr ON osha_accident (summary_nr)
;


/* Let's check some things out on the joins before we go any further. AND let's learn about how easy it is 
to give a table a one-letter nickname (an alias)! */

SELECT COUNT(*) AS count_of_matched_records_in_join
FROM osha_inspection a
JOIN osha_accident_injury b
ON a.activity_nr = b.rel_insp_nr

/* If we had run that query and the count had come back as zero, we would know something was wrong, because 
we know those tables are supposed to join on that field, and it wouldn't make sense for there to be 
not a single match. */ 

/* Also, for every inspection that was flagged with the accident indicator, 
there should be at least one record in accident_injury. Is that true?
Let's find out. This query looks for any records that DO have the accident flag but 
DON'T have a matching record in accident_injury: */

SELECT a.*
FROM osha_inspection a
LEFT JOIN osha_accident_injury b
ON a.activity_nr = b.rel_insp_nr
WHERE b.rel_insp_nr IS NULL AND a.osha_accident_indicator = 't'
;

/* So, that looks good. So let's try marrying all three tables together. */

SELECT COUNT(*) AS our_count
FROM osha_inspection a
JOIN osha_accident_injury b
ON a.activity_nr = b.rel_insp_nr
JOIN osha_accident c
ON b.summary_nr = c.summary_nr
;

/* Let's circle back to our COUNT DISTINCT from earlier. 
You can write a subquery selecting all the DISTINCT records, and then query those results with a COUNT(*). 
Let's learn about subqueries -- queries inside queries! */

SELECT COUNT(*) AS count_of_distinct_records
FROM (SELECT DISTINCT *
FROM osha_inspection) AS mysubquery /* if you use a subquery in parentheses, 
you have to give it a name or you'll get an error message. */
;

/* You can use a subquery to create a summary number for something and then join that query back to the original table. */ 

SELECT a.*, b.estab_count
FROM osha_inspection a
JOIN (SELECT estab_name, COUNT(*) AS estab_count
		FROM osha_inspection
		GROUP BY 1) b
ON a.estab_name = b.estab_name
;

/* What if we want to make a copy of a table or make a table from a slice of our data? */

DROP TABLE IF EXISTS georgia_inspections_only
;

CREATE TABLE georgia_inspections_only AS
SELECT *
FROM osha_inspection
WHERE site_state LIKE '%GA%'
;

/* That copied all the fields. What if we only wanted a few fields? Let's try again. */

DROP TABLE IF EXISTS georgia_inspections_only
;

CREATE TABLE georgia_inspections_only AS
SELECT a.activity_nr, a.reporting_id, a.estab_name, a.site_address, a.site_city, a.site_state, a.site_zip
FROM osha_inspection a
WHERE a.site_state LIKE '%GA%'

/* Let's look at our new, stripped-down table */

SELECT *
FROM georgia_inspections_only
;

/* What if we want to combine some fields or a field and some text and then another field? Use CONCAT! */

SELECT CONCAT('The establishment called ', a.estab_name, 'is at ', a.site_address, ', ', a.site_city, ', ', a.site_state)
FROM osha_inspection a
;

/* What if we need to make a crosstab comparing things? Let's compare the numbers of inspections performed in Georgia
and the surrounding states. We'll use IF to look in the site_state field and count 1 if it finds that state, and we'll
wrap our IF clause with SUM to make it add up all the 1's it finds. */
SELECT SUM(IF(a.site_state = 'GA', 1,0)) AS inspections_in_Georgia,
SUM(IF(a.site_state = 'AL', 1,0)) AS inspections_in_Alabama,
SUM(IF(a.site_state = 'SC', 1,0)) AS inspections_in_SC,
SUM(IF(a.site_state = 'TN', 1,0)) AS inspections_in_Tenn,
SUM(IF(a.site_state = 'NC', 1,0)) AS inspections_in_NC,
SUM(IF(a.site_state = 'FL', 1,0)) AS inspections_in_Fla
FROM osha_inspection a
;

/* What if we need to create a new field and fill it with something depending on what's in another field, or multiple other fields? 
Let's use CASE statements. Let's assign counties to some of our Georgia inspections, based on the city name. */

SELECT a.estab_name, a.site_city, a.site_state,
CASE WHEN a.site_city = 'Atlanta' THEN 'Fulton'
WHEN a.site_city = 'Alpharetta' THEN 'Fulton'
WHEN a.site_city = 'Tifton' THEN 'Tift'
WHEN a.site_city = 'Norcross' THEN 'Gwinnett'
WHEN a.site_city = 'Macon' THEN 'Bibb'
WHEN a.site_city = 'College Park' THEN 'Fulton'
WHEN a.site_city = 'Duluth' THEN 'Gwinnett'
WHEN a.site_city = 'Augusta' THEN 'Richmond'
WHEN a.site_city = 'Savannah' THEN 'Chatham'
WHEN a.site_city = 'Columbus' THEN 'Muscogee'
ELSE ''
END AS county_we_assigned
FROM osha_inspection a
WHERE a.site_state = 'GA' 
;

/* ADDENDUM: BREAKING DOWN HOW TO ACTUALLY LOAD A DATA FILE INTO MYSQL */

/* Let's load some data! */

/* There are 3 tables in our data set: Inspections, accidents and accident_injury. Let's first load 
our inspections table. We'll first make sure that there's not already a table in our database by that name. */

DROP TABLE IF EXISTS osha_inspection
;

/* Now, we create our empty table by that name. */


CREATE TABLE osha_inspection
(
activity_nr VARCHAR(15), /* You can adjust the number of characters in the VARCHAR to whatever you need them to be, up to 255. If you need more than 255 characters, try TEXT. If you need longer than that, try LONGTEXT. Need longer than LONGTEXT? Are you writing a book? Are you sure you need a database for whatever you're doing? */
reporting_id VARCHAR(15),
state_flag VARCHAR(15),
estab_name VARCHAR(255),
site_address VARCHAR(150),
site_city VARCHAR(100),
site_state VARCHAR(15),
site_zip VARCHAR(15),
owner_type VARCHAR(15),
owner_code VARCHAR(15),
adv_notice VARCHAR(15),
safety_hlth VARCHAR(15),
sic_code VARCHAR(15),
naics_code VARCHAR(15),
insp_type VARCHAR(15),
insp_scope VARCHAR(15),
why_no_insp VARCHAR(15),
union_status VARCHAR(15),
safety_manuf VARCHAR(15),
safety_const VARCHAR(15),
safety_marit VARCHAR(15),
health_manuf VARCHAR(15),
health_const VARCHAR(15),
health_marit VARCHAR(15),
migrant VARCHAR(15),
mail_street VARCHAR(255),
mail_city VARCHAR(150),
mail_state VARCHAR(15),
mail_zip VARCHAR(15),
host_est_key VARCHAR(150),
nr_in_estab VARCHAR(15),
open_date DATE DEFAULT NULL,
case_mod_date DATE, /* I like to make my date fields null if they're going to be blank, that's just my personal preference. you don't have to. */
close_conf_date DATE DEFAULT NULL,
close_case_date DATE DEFAULT NULL,
open_year YEAR DEFAULT NULL,
case_mod_year YEAR DEFAULT NULL,
close_conf_year YEAR DEFAULT NULL,
close_case_year  YEAR DEFAULT NULL,
osha_accident_indicator VARCHAR(15),
violation_type_s VARCHAR(15),
violation_type_o VARCHAR(15),
violation_type_r VARCHAR(15),
violation_type_u VARCHAR(15),
violation_type_w VARCHAR(15),
inspection_to_filter VARCHAR(15)
)ENGINE=INNODB CHARSET=latin1
/* You may also be able to use ENGINE=MYISAM instead of INNODB. Either one will probably work about the same. Check with your database admin. */
;

/* Now, we need to load our data into our new empty table. */

/* Watch the direction the slashes in the file path here ... */
LOAD DATA LOCAL INFILE 'C:/Users/JP/Dropbox/osha_inspection.csv'
-- LOAD DATA LOCAL INFILE 'C:/Blah_Blah_Blah/Your_File_Path/osha_inspection.csv'
INTO TABLE osha_inspection
FIELDS TERMINATED BY ',' -- If it's a CSV. Change this out if it's separated by pipes, etc. 
OPTIONALLY ENCLOSED BY '"' -- For stuff in quotes in a CSV
-- LINES TERMINATED BY '\r\n' -- You may not need this line at all! 
IGNORE 1 LINES -- don't use if no header row in your spreadsheet!
/* this next section tells the database what order the columns are going to come in as. */
(
activity_nr,
reporting_id,
state_flag,
estab_name,
@site_address,
site_city,
site_state,
site_zip,
owner_type,
owner_code,
adv_notice,
safety_hlth,
sic_code,
naics_code,
insp_type,
insp_scope,
why_no_insp,
union_status,
safety_manuf,
safety_const,
safety_marit,
health_manuf,
health_const,
health_marit,
migrant,
mail_street,
mail_city,
mail_state,
mail_zip,
host_est_key,
nr_in_estab,
@open_date,
@case_mod_date,
@close_conf_date,
@close_case_date,
@open_year,
@case_mod_year,
@close_conf_year,
@close_case_year,
osha_accident_indicator,
violation_type_s,
violation_type_o,
violation_type_r,
violation_type_u,
violation_type_w,
inspection_to_filter
)
/* Now, we get to use SET and mess with our variables before they are inserted into the table! */
SET
/* You can use TRIM to trim off extra blank spaces. There's also LTRIM and RTRIM to 
just trim one end of a string. */
site_address = TRIM(@site_address),
/* use STR_TO_DATE to format dates properly. Most dates in a CSV or Excel tend to be '%m/%d/%Y' but these are '%Y-%m-%d' */
open_date = STR_TO_DATE(@open_date, '%Y-%m-%d'),
case_mod_date = STR_TO_DATE(@case_mod_date, '%Y-%m-%d'),
close_conf_date = STR_TO_DATE(@close_conf_date, '%Y-%m-%d'),
close_case_date = STR_TO_DATE(@close_case_date, '%Y-%m-%d'),
/* Next, we'll null out any blank year fields by using IFs that look for blanks. If the field is blank,
it will null it; otherwise, it will plop the variable in. */
open_year = IF(@open_year IN ('') OR @open_year IS NULL, NULL, @open_year),
case_mod_year = IF(@open_year IN ('') OR @open_year IS NULL, NULL, @open_year),
close_conf_year = IF(@open_year IN ('') OR @open_year IS NULL, NULL, @open_year),
/* An alternate to the IF statements above: use a regular expression in SQL. This one looks to see if there are
any numbers in the @close_case_year variable. If there aren't, it nulls it. If there are, it plops the number in there. Regular expressions are super-powerful and are the subject of an entire class at #NICAR18, but you can also learn them 
on your own through online tutorials if you can't get to the regex class. */
close_case_year = IF(@close_case_year NOT REGEXP '[0-9]', NULL, @close_case_year)
;

/* BUT WAIT, there's more! 

You've learned that you can create a table and load data into it while doing cleanup on things like formatting dates and blank or null fields. Did you know, you can also create a table and load data into it while doing all those things AND also creating primary keys and putting on indexes? You can! Here's the same CREATE TABLE statement for osha_inspection that does all those things: does cleanup with SET and variables while also creating primary keys and putting on indexes. */

DROP TABLE IF EXISTS osha_inspection
;

CREATE TABLE osha_inspection
(
jp_id_num MEDIUMINT AUTO_INCREMENT PRIMARY KEY /* field made-up by me, we're telling the computer to fill it with an automatically incremented number and also make this field the primary key of the table. */
activity_nr VARCHAR(15), INDEX (activity_nr(5)), /* You can adjust the number of characters in the VARCHAR to whatever you need them to be, up to 255. If you need more than 255 characters, try TEXT. If you need longer than that, try LONGTEXT. If you need longer than LONGTEXT, WTF, dude, are you writing a book? Are you sure you need a database for whatever you're doing? */
reporting_id VARCHAR(15), INDEX (reporting_id(5)),
state_flag VARCHAR(15), INDEX (state_flag(3)),
estab_name VARCHAR(255), INDEX (estab_name(5)),
site_address VARCHAR(150),
site_city VARCHAR(100),
site_state VARCHAR(15), INDEX (site_state(2)),
site_zip VARCHAR(15),
owner_type VARCHAR(15),
owner_code VARCHAR(15),
adv_notice VARCHAR(15),
safety_hlth VARCHAR(15),
sic_code VARCHAR(15),
naics_code VARCHAR(15), INDEX (naics_code(6)),
insp_type VARCHAR(15),
insp_scope VARCHAR(15),
why_no_insp VARCHAR(15),
union_status VARCHAR(15),
safety_manuf VARCHAR(15),
safety_const VARCHAR(15),
safety_marit VARCHAR(15),
health_manuf VARCHAR(15),
health_const VARCHAR(15),
health_marit VARCHAR(15),
migrant VARCHAR(15),
mail_street VARCHAR(255),
mail_city VARCHAR(150),
mail_state VARCHAR(15),
mail_zip VARCHAR(15),
host_est_key VARCHAR(150),
nr_in_estab VARCHAR(15),
open_date DATE DEFAULT NULL, INDEX (open_date),
case_mod_date DATE DEFAULT NULL,
close_conf_date DATE DEFAULT NULL,
close_case_date DATE DEFAULT NULL, INDEX (close_case_date),
open_year YEAR DEFAULT NULL,
case_mod_year YEAR DEFAULT NULL,
close_conf_year YEAR DEFAULT NULL,
close_case_year  YEAR DEFAULT NULL,
osha_accident_indicator VARCHAR(15), INDEX (osha_accident_indicator(2)),
violation_type_s VARCHAR(15),
violation_type_o VARCHAR(15),
violation_type_r VARCHAR(15),
violation_type_u VARCHAR(15),
violation_type_w VARCHAR(15),
inspection_to_filter VARCHAR(15)
)ENGINE=INNODB CHARSET=latin1
/* You may also be able to use ENGINE=MYISAM instead of INNODB. Either one will probably work about the same. Check with your
database admin. */
;

LOAD DATA LOCAL INFILE 'C:/Blah_Blah_Blah/Your_File_Path/osha_inspection.csv'
INTO TABLE osha_inspection
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"' 
IGNORE 1 LINES 
(
activity_nr,
reporting_id,
state_flag,
estab_name,
@site_address,
site_city,
site_state,
site_zip,
owner_type,
owner_code,
adv_notice,
safety_hlth,
sic_code,
naics_code,
insp_type,
insp_scope,
why_no_insp,
union_status,
safety_manuf,
safety_const,
safety_marit,
health_manuf,
health_const,
health_marit,
migrant,
mail_street,
mail_city,
mail_state,
mail_zip,
host_est_key,
nr_in_estab,
@open_date,
@case_mod_date,
@close_conf_date,
@close_case_date,
@open_year,
@case_mod_year,
@close_conf_year,
@close_case_year,
osha_accident_indicator,
violation_type_s,
violation_type_o,
violation_type_r,
violation_type_u,
violation_type_w,
inspection_to_filter
)
SET
site_address = TRIM(@site_address),
open_date = STR_TO_DATE(@open_date, '%Y-%m-%d'),
case_mod_date = STR_TO_DATE(@case_mod_date, '%Y-%m-%d'),
close_conf_date = STR_TO_DATE(@close_conf_date, '%Y-%m-%d'),
close_case_date = STR_TO_DATE(@close_case_date, '%Y-%m-%d'),
open_year = IF(@open_year IN ('') OR @open_year IS NULL, NULL, @open_year),
case_mod_year = IF(@open_year IN ('') OR @open_year IS NULL, NULL, @open_year),
close_conf_year = IF(@open_year IN ('') OR @open_year IS NULL, NULL, @open_year),
close_case_year = IF(@close_case_year NOT REGEXP '[0-9]', NULL, @close_case_year)
;

/* Now, we still need to load the accident_injury table. */

DROP TABLE IF EXISTS osha_accident_injury
;

CREATE TABLE osha_accident_injury
(
jp_id_num MEDIUMINT AUTO_INCREMENT PRIMARY KEY, /* made-up field for use as primary key */
summary_nr VARCHAR(15), INDEX (summary_nr(5)),
rel_insp_nr VARCHAR(15),
age INTEGER,
sex VARCHAR(5),
nature_of_inj VARCHAR(15),
part_of_body VARCHAR(15),
src_of_injury VARCHAR(15),
event_type VARCHAR(15),
evn_factor VARCHAR(15),
hum_factor VARCHAR(15),
occ_code VARCHAR(15),
degree_of_inj VARCHAR(15),
task_assigned VARCHAR(15),
hazsub VARCHAR(15),
const_op VARCHAR(15),
const_op_cause VARCHAR(15),
fat_cause VARCHAR(15),
fall_distance VARCHAR(15),
fall_ht VARCHAR(15),
injury_line_nr VARCHAR(15)
)ENGINE=INNODB CHARSET=latin1
;

LOAD DATA LOCAL INFILE 'C:/Users/JP/Dropbox/osha_accident_injury.csv'
INTO TABLE osha_accident_injury
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
IGNORE 1 LINES
(
summary_nr,
rel_insp_nr,
age,
sex,
nature_of_inj,
part_of_body,
src_of_injury,
event_type,
evn_factor,
hum_factor,
occ_code,
degree_of_inj,
task_assigned,
hazsub,
const_op,
const_op_cause,
fat_cause,
fall_distance,
fall_ht,
injury_line_nr
)
