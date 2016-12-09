-- ----------------------------------------------------------------------------------------------------------
-- Postgres pgAdmin III create, load, and query script for Fictional American Red Cross Blood Donation System
-- 
-- SQL statements for the American Red Cross database
-- 
-- Developer: Brian Henderson
-- Assignment: Final Project
-- 
-- Tested on Postgres 9.3.2
-- -----------------------------------------------------------------------------------------------------------

-- -----------------------
-- Drop Table statements
-- -----------------------
DROP VIEW IF EXISTS AvailableBloodBags;
DROP VIEW IF EXISTS locationInventories;

DROP TABLE IF EXISTS donation_records;
DROP TABLE IF EXISTS donation;
DROP TABLE IF EXISTS transfusion_records;
DROP TABLE IF EXISTS transfusion;
DROP TABLE IF EXISTS patient;
DROP TABLE IF EXISTS donor;
DROP TABLE IF EXISTS nurse;
DROP TABLE IF EXISTS persons;
DROP TABLE IF EXISTS requests;
DROP TABLE IF EXISTS global_inventory;
DROP TABLE IF EXISTS locations;
DROP TABLE IF EXISTS location_codes;
DROP TABLE IF EXISTS bloodbags;
DROP TABLE IF EXISTS pre_exam;
DROP TABLE IF EXISTS donation_types;

-- -----------------------
-- Create Table Statements
-- -----------------------

-- Persons --
CREATE TABLE persons (
    pid         char(8)     not null unique,
    first_name  text        not null,
    last_name   text        not null,
    age         integer     not null,
  primary key(pid)
);

-- Patient -- 
CREATE TABLE patient (
    pid         char(8)     not null references persons(pid),
    blood_type  char(3)     not null,
    need_status text        not null,
    weightLBS   integer     not null,
  CONSTRAINT check_status CHECK (need_status = 'high' OR need_status = 'low'),
  primary key(pid)
);

-- Donor --
CREATE TABLE donor (
    pid               char(8)     not null references persons(pid),
    blood_type        char(3)     not null,
    weightLBS         integer     not null,
    heightIN          integer     not null,
    gender            char(1)     not null,
    nextSafeDonation  DATE,
  CONSTRAINT check_gender CHECK (gender = 'M' OR gender = 'F'),
  primary key(pid)
);

-- Nurse --
CREATE TABLE nurse (
    pid                 char(8)     not null references persons(pid),
    years_experienced   integer     not null,
  primary key(pid)
);

-- Location Codes --
CREATE TABLE location_codes (
    lc       char(4)     not null unique,
    descrip  text        not null,
  primary key(lc)
);

-- Locations --
CREATE TABLE locations (
    lid     char(6)     not null unique,
    name    text        not null,
    lc      char(4)     not null references location_codes(lc),
    city    text        not null,
  primary key(lid)
);


-- Requests --
CREATE TABLE requests (
    rqid                    char(8)     not null unique,
    lid                     char(6)     not null references locations(lid),
    blood_type_requested    text        not null,
    date_requested          DATE        not null,
    quantity_requestedCC integer     not null,
  primary key(rqid)
 );

-- Donation Types --
CREATE TABLE donation_types (
    type            text    not null unique,
    frequency_days  integer not null,
  primary key(type)
);

-- Blood Bags --
CREATE TABLE bloodbags (
    bbid            char(10)      not null unique,
    quantity_CC     decimal(5,2)  not null,
    blood_type      char(3)       not null,
    donation_type   text          not null references donation_types(type),
  primary key(bbid)
);

-- Global Inventory --
CREATE TABLE global_inventory (
    bbid        char(10)    not null references bloodbags(bbid),
    lid         char(6)     not null references locations(lid),
    available   boolean     DEFAULT TRUE,
  primary key (bbid,lid)
);

-- Pre Exam --
CREATE TABLE pre_exam (
    peid            char(8)         not null,
    hemoglobin_gDL  decimal(5,2)    not null,
    temperature_F   decimal(5,2)    not null,
    blood_pressure  char(8)         not null,
    pulse_rate_BPM  integer         not null,
  primary key(peid)
);

-- Donations --
CREATE TABLE donation (
    did                 char(8)      not null,
    pid                 char(8)      not null references donor(pid),
    peid                char(8)      not null references pre_exam(peid),
    nurse               char(8)      not null references nurse(pid),
    amount_donated_CC  decimal(5,2) not null,
    donation_type       text         not null references donation_types(type),
  primary key(did)
);

-- Donation Records --
CREATE TABLE donation_records (
    did             char(8)     not null references donation(did),
    lid             char(4)     not null references locations(lid),
    donation_date   date        not null,
    bbid            char(10)    not null references bloodbags(bbid),
  primary key(did)
);

-- Transfusions --
CREATE TABLE transfusion (
    tid                 char(8)      not null,
    pid                 char(8)      not null references patient(pid),
    peid                char(8)      not null references pre_exam(peid),
    nurse               char(8)      not null references nurse(pid),
    amount_recieved_CC decimal(5,2) not null,
  primary key(tid)
);

-- Transfusions Records --
CREATE TABLE transfusion_records (
    tid                 char(8)     not null references transfusion(tid),
    lid                 char(4)     not null references locations(lid),
    transfusion_date    date        not null,
    bbid                char(10)    not null references bloodbags(bbid),
  primary key(tid)
);

-- ------------------------------------------------------------------------------ 

CREATE VIEW AvailableBloodBags as (
    SELECT gi.bbid, 
           gi.lid, 
           bb.blood_type, 
           bb.donation_type, 
           bb.quantity_CC
    FROM global_inventory gi INNER JOIN bloodbags bb 
      ON gi.bbid = bb.bbid
    WHERE gi.available = TRUE
);

-- 

CREATE VIEW locationInventories AS (
	SELECT gi.lid, 
    	   SUM(bb.quantity_CC) AS totQuantity, 
           bb.blood_type, 
           bb.donation_type
	FROM global_inventory gi INNER JOIN bloodbags bb ON gi.bbid = bb.bbid
                             INNER JOIN locations l  ON gi.lid  = l.lid
GROUP BY blood_type, 
         donation_type, 
         gi.lid
ORDER BY lid desc,
         totquantity desc
);

-- ------------------------------------------------------------------------------ 

CREATE OR REPLACE FUNCTION get_persons_donation_records (char(8), REFCURSOR) returns refcursor as
$$
DECLARE
    personID   char(8)    := $1;
    results    REFCURSOR  := $2;
BEGIN
    OPEN results FOR
        SELECT dr.did, dr.lid, dr.donation_date, d.pid, d.peid, d.nurse, d.amount_donated_CC, d.donation_type
        FROM donation_records dr INNER JOIN donation d ON dr.did = d.did
        WHERE personID = d.pid;
    RETURN results;
END;
$$
language plpgsql;

-- 

CREATE OR REPLACE FUNCTION update_inventory_status()
RETURNS TRIGGER AS 
$$
BEGIN
	IF NEW.bbid is NOT NULL THEN
    	UPDATE global_inventory
        SET available = FALSE
        WHERE NEW.bbid = global_inventory.bbid;
    END IF;
    RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;

-- 
 
CREATE OR REPLACE FUNCTION get_blood_type_inventory_percentage (char(3), REFCURSOR) returns refcursor as
$$
DECLARE    
   reqType    char(3)    := $1;
   results    REFCURSOR  := $2;
BEGIN    
   OPEN results FOR        
       SELECT TRUNC (
           CAST (
               ( SELECT COUNT(gi.bbid) AS selectedBBID
               FROM global_inventory gi INNER JOIN bloodbags bb
               		ON gi.bbid = bb.bbid
               WHERE bb.blood_type = reqType
                 AND gi.available = TRUE 
               ) as decimal(5,2)
             )
               /
               ( SELECT COUNT(gi.bbid) AS allBBIDs
                 FROM global_inventory gi
                 WHERE gi.available = TRUE
               )
          * 100
              )  AS BloodTypePercentage;
   RETURN results;
END;
$$
language plpgsql;

-- select get_blood_type_inventory_percentage('B-', 'results');
-- fetch all from results;

-- 

CREATE OR REPLACE FUNCTION update_next_donation_date()
RETURNS TRIGGER AS 
$$
BEGIN
	IF NEW.DID IS NOT NULL THEN
    	UPDATE donor
    	SET nextSafeDonation = now()
    	WHERE donor.pid IN ( SELECT donor.pid
                         	FROM donation d INNER JOIN donation_records dr ON d.did = dr.did
                                         	INNER JOIN donor ON donor.pid = d.pid
                             WHERE d.did = NEW.did
                       	   );
    END IF;
	RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;
    
    

-- ------------------------------------------------------------------------------ 

CREATE TRIGGER update_next_donation_date
	BEFORE INSERT ON donation_records
    FOR EACH ROW
    EXECUTE PROCEDURE update_next_donation_date();
    
    
CREATE TRIGGER update_inventory_status_trigger
	BEFORE INSERT ON transfusion_records
    FOR EACH ROW
    EXECUTE PROCEDURE update_inventory_status();
    
-- ------------------------------------------------------------------------------ 

SELECT p.pid, p.first_name, p.last_name, count(d.pid) AS TimesDonated, SUM(d.amount_donated_CC) AS TotalAmount
FROM persons p INNER JOIN donation d ON p.pid = d.pid
GROUP BY p.pid
order by totalAmount desc;

-- 
SELECT bb.blood_type, bb.donation_type, SUM(quantity_cc) AS totQuantity
FROM bloodbags bb INNER JOIN global_inventory gi ON bb.bbid = gi.bbid
GROUP BY bb.blood_type, bb.donation_type
ORDER BY totQuantity desc;

-- ------------------------------------------------------------------------------ 



INSERT INTO Persons(pid, first_name, last_name, age)
 	VALUES('p1' , 'John' , '	Centra' , 23);
    
INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p2' , 'Anne' , 'Parker' , 42);
    
INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p3' , 'Ryan' , 'Fowler' , 32);
    
INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p4' , 'Peter' , 'Cruz' , 21);
    
INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p5' , 'Stephanie' , 'Collins' , 46);

INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p6' , 'Harry' , 'Bryant' , 62);

INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p7' , 'James' , 'Bond' , 40);

INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p8' , 'David' , 'King' , 34);

INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p9' , 'Thomas' , 'Tank' , 24);

INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p10', 'Jessica' , 'Roberts' , 42 );
    
INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p11' , 'Carol' , 'Porter' , 62 );
    
INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p12' , 'Emily' , 'Murphy' , 21 );
 
INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p13' , 'Matthew' , 'McDermmot' , 37);

INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p14' , 'Joseph' , 'Ruggiero' , 19 );
    
INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p15' , 'Hannah' , 'Taylor' , 17 );

INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p16' , 'Anne' , 'Miller' , 48 );
    
INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p17' , 'Caroline' , 'Powers' , 38 );

INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p18' , 'Emily' , 'McFelice' , 40 );

INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p19' , 'Pattricia' , 'Wilson' , 39 );

INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p20' , 'Bill' , 'Bowerman' , 26 );

INSERT INTO Persons(pid, first_name, last_name, age)
	VALUES('p21' , 'Mickey' , 'Globe' , 23 );


-- 

INSERT INTO Nurse(pid, years_experienced)
 	VALUES ('p2' , 12 );

INSERT INTO Nurse(pid, years_experienced)
	VALUES ('p4' , 17 );

INSERT INTO Nurse(pid, years_experienced)
	VALUES ('p10' , 5 );

INSERT INTO Nurse(pid, years_experienced)
 	VALUES ('p16' , 18 );

INSERT INTO Nurse(pid, years_experienced)
 	VALUES ('p17' , 9 );

INSERT INTO Nurse(pid, years_experienced)
 	VALUES ('p18' , 10 );

INSERT INTO Nurse(pid, years_experienced)
 	VALUES ('p19' , 12 );

-- 

INSERT INTO Patient(pid, blood_type, need_status, weightLBS)
 	VALUES ('p1' ,'O+' , 'low' , 172 );

INSERT INTO Patient(pid, blood_type, need_status, weightLBS)
 	VALUES ('p3' ,'A+' , 'low' ,185 );

INSERT INTO Patient(pid, blood_type, need_status, weightLBS)
 	VALUES ('p6' ,'AB+' , 'high' , 128 );

INSERT INTO Patient(pid, blood_type, need_status, weightLBS)
 	VALUES ('p11' ,'B+' , 'low' , 120 );

INSERT INTO Patient(pid, blood_type, need_status, weightLBS)
 	VALUES ('p12' ,' A+' , 'low' , 118 );

--

INSERT INTO Donor(pid, blood_type, weightLBS, heightIN, gender)
 	VALUES ('p4' ,'O+' , 149 , 70, 'M' );

INSERT INTO Donor(pid, blood_type, weightLBS, heightIN, gender)
 	VALUES ('p7' ,'O-' , 170 , 74, 'M' );

INSERT INTO Donor(pid, blood_type, weightLBS, heightIN, gender)
 	VALUES ('p8' ,'AB-' , 148 , 66, 'M' );

INSERT INTO Donor(pid, blood_type, weightLBS, heightIN, gender)
 	VALUES ('p9' ,'B-' , 180 , 71, 'M' );

INSERT INTO Donor(pid, blood_type, weightLBS, heightIN, gender)
 	VALUES ('p13' ,'O+' , 212 , 76, 'M' );

INSERT INTO Donor(pid, blood_type, weightLBS, heightIN, gender)
 	VALUES ('p14' ,'B+' , 128 , 68, 'M' );

INSERT INTO Donor(pid, blood_type, weightLBS, heightIN, gender)
 	VALUES ('p15' ,'O+' , 104 , 63, 'F' );

INSERT INTO Donor(pid, blood_type, weightLBS, heightIN, gender)
 	VALUES ('p20' ,'A+' , 178 , 65, 'M' );

INSERT INTO Donor(pid, blood_type, weightLBS, heightIN, gender)
 	VALUES ('p21' ,'AB+' , 120 , 57, 'F' );

-- 
INSERT INTO donation_types(type, frequency_days)
	VALUES ('Blood', 56);

INSERT INTO donation_types(type, frequency_days)
	VALUES ('Platelets', 7);

INSERT INTO donation_types(type, frequency_days)
	VALUES ('Plasma', 28);

INSERT INTO donation_types(type, frequency_days)
	VALUES ('Power Red', 112);

--

INSERT INTO location_codes (lc, descrip)
	VALUES ('ARCF','American Red Cross Facility') ;

INSERT INTO location_codes (lc, descrip)
	VALUES ('BDHS','Blood Drive - High School') ;

INSERT INTO location_codes (lc, descrip)
	VALUES ('BDUN','Blood Drive - University') ;

INSERT INTO location_codes (lc, descrip)
	VALUES ('BDCO','Blood Drive - College ') ;

INSERT INTO location_codes (lc, descrip)
	VALUES ('BDOG','Blood Drive - Orginization ') ;

INSERT INTO location_codes (lc, descrip)
	VALUES ('MILT',' Military Facility ') ;
 
INSERT INTO location_codes (lc, descrip)
	VALUES ('CLIN',' Clinics ') ;
    
INSERT INTO location_codes (lc, descrip)
	VALUES ('HSPT',' Hospital ') ;

INSERT INTO location_codes (lc, descrip)
	VALUES ('RESR',' Research Facility ') ;

-- 

INSERT INTO Locations(lid, name, lc, city)
	VALUES ('L1','Mid Hudson Regional Hospital', 'HSPT', 'Poughkeepsie');
    
INSERT INTO Locations(lid, name, lc, city)
	VALUES ('L2','Vassar Brothers Medical Center', 'CLIN', 'Vassar');
    
INSERT INTO Locations(lid, name, lc, city)
	VALUES ('L3','Marist College', 'BDCO', 'Poughkeepsie');
    
INSERT INTO Locations(lid, name, lc, city)
	VALUES ('L4','Fort Monmouth', 'MILT', 'Eatontown');

INSERT INTO Locations(lid, name, lc, city)
	VALUES ('L5','American Red Cross Eastern New York Chapter', 'ARCF', 'Albany');

INSERT INTO Locations(lid, name, lc, city)
	VALUES ('L6','Ramsey High School', 'BDHS', 'Ramsey');

INSERT INTO Locations(lid, name, lc, city)
	VALUES ('L7','Charlesville Emergency Clinic', 'CLIN', 'Chatstown');

INSERT INTO Locations(lid, name, lc, city)
	VALUES ('L8','IBM', 'BDOG', 'Poughkeepsie');

INSERT INTO Locations(lid, name, lc, city)
	VALUES ('L9','Poughkeepsie Galleria', 'BDOG', 'Poughkeepsie');

INSERT INTO Locations(lid, name, lc, city)
	VALUES ('L10','American Red Cross New York City Chapter', 'ARCF', 'New York');

-- 

INSERT INTO Requests (rqid, lid, blood_type_requested, date_requested, quantity_requestedCC)
	VALUES ('rq1', 'L1','A+', now(), 10000);

INSERT INTO Requests (rqid, lid, blood_type_requested, date_requested, quantity_requestedCC)
	VALUES ('rq2', 'L4','A-', now(), 9000);

INSERT INTO Requests (rqid, lid, blood_type_requested, date_requested, quantity_requestedCC)
	VALUES ('rq3', 'L1','A-', now(), 3600);

INSERT INTO Requests (rqid, lid, blood_type_requested, date_requested, quantity_requestedCC)
	VALUES ('rq4', 'L2','O-', now(), 13000);

INSERT INTO Requests (rqid, lid, blood_type_requested, date_requested, quantity_requestedCC)
	VALUES ('rq5', 'L1','AB-', now(), 7000);

INSERT INTO Requests (rqid, lid, blood_type_requested, date_requested, quantity_requestedCC)
	VALUES ('rq6', 'L1','B-', now(), 6000);

INSERT INTO Requests (rqid, lid, blood_type_requested, date_requested, quantity_requestedCC)
	VALUES ('rq7', 'L7','O-', now(), 12000);

-- 

INSERT INTO bloodbags (bbid, quantity_CC, blood_type, donation_type)
	VALUES ('bb1', 473, 'O+', 'Blood');

INSERT INTO bloodbags (bbid, quantity_CC, blood_type, donation_type)
	VALUES ('bb2', 473, 'O-', 'Blood');

INSERT INTO bloodbags (bbid, quantity_CC, blood_type, donation_type)
	VALUES ('bb3', 946, 'O+', 'Power Red');
    
INSERT INTO bloodbags (bbid, quantity_CC, blood_type, donation_type)
	VALUES ('bb4', 473, 'AB-', 'Plasma');

INSERT INTO bloodbags (bbid, quantity_CC, blood_type, donation_type)
	VALUES ('bb5', 473, 'B-', 'Blood');

INSERT INTO bloodbags (bbid, quantity_CC, blood_type, donation_type)
	VALUES ('bb6', 473, 'B+', 'Blood');

INSERT INTO bloodbags (bbid, quantity_CC, blood_type, donation_type)
	VALUES ('bb7', 473, 'O+', 'Platelets');
 
INSERT INTO bloodbags (bbid, quantity_CC, blood_type, donation_type)
	VALUES ('bb8', 473, 'A+', 'Blood');

INSERT INTO bloodbags (bbid, quantity_CC, blood_type, donation_type)
	VALUES ('bb9', 473, 'AB+', 'Blood');
    
INSERT INTO bloodbags (bbid, quantity_CC, blood_type, donation_type)
	VALUES ('bb10', 473, 'A+', 'Blood');  

INSERT INTO bloodbags (bbid, quantity_CC, blood_type, donation_type)
	VALUES ('bb11', 473, 'B+', 'Blood');  

INSERT INTO bloodbags (bbid, quantity_CC, blood_type, donation_type)
	VALUES ('bb12', 473, 'O+', 'Blood');  

INSERT INTO bloodbags (bbid, quantity_CC, blood_type, donation_type)
	VALUES ('bb13', 473, 'O+', 'Blood');  

 -- 
 
 INSERT INTO global_inventory (bbid, lid)
	VALUES	('bb1','L5');

INSERT INTO global_inventory (bbid, lid)
	VALUES	('bb2','L5');
    
INSERT INTO global_inventory (bbid, lid)
	VALUES	('bb3','L10');

INSERT INTO global_inventory (bbid, lid)
	VALUES	('bb4','L5');

INSERT INTO global_inventory (bbid, lid)
	VALUES	('bb5','L10');

INSERT INTO global_inventory (bbid, lid)
	VALUES	('bb6','L10');

INSERT INTO global_inventory (bbid, lid)
	VALUES	('bb7','L5');

INSERT INTO global_inventory (bbid, lid)
	VALUES	('bb8','L5');
    
INSERT INTO global_inventory (bbid, lid)
	VALUES	('bb9','L10');

INSERT INTO global_inventory (bbid, lid)
	VALUES	('bb10','L10');

INSERT INTO global_inventory (bbid, lid)
	VALUES	('bb11','L5');

INSERT INTO global_inventory (bbid, lid)
	VALUES	('bb12','L10');

INSERT INTO global_inventory (bbid, lid)
	VALUES	('bb13','L10');
-- 

INSERT INTO pre_exam (peid, hemoglobin_gDL, temperature_F, blood_pressure, pulse_rate_BPM)
	VALUES ('pe1', 15.2, 98.6, '120/80', 70);

INSERT INTO pre_exam (peid, hemoglobin_gDL, temperature_F, blood_pressure, pulse_rate_BPM)
	VALUES ('pe2', 14.9, 98.5, '110/70', 75);

INSERT INTO pre_exam (peid, hemoglobin_gDL, temperature_F, blood_pressure, pulse_rate_BPM)
	VALUES ('pe3', 15.7, 98.5, '130/85', 59);    

INSERT INTO pre_exam (peid, hemoglobin_gDL, temperature_F, blood_pressure, pulse_rate_BPM)
	VALUES ('pe4', 16.1, 98.4, '120/80', 67);

INSERT INTO pre_exam (peid, hemoglobin_gDL, temperature_F, blood_pressure, pulse_rate_BPM)
	VALUES ('pe5', 14.2, 98.3, '90/80', 90);

INSERT INTO pre_exam (peid, hemoglobin_gDL, temperature_F, blood_pressure, pulse_rate_BPM)
	VALUES ('pe6', 17.1, 98.2, '110/70', 44);

INSERT INTO pre_exam (peid, hemoglobin_gDL, temperature_F, blood_pressure, pulse_rate_BPM)
	VALUES ('pe7', 14.2, 98.1, '140/90', 79);

INSERT INTO pre_exam (peid, hemoglobin_gDL, temperature_F, blood_pressure, pulse_rate_BPM)
	VALUES ('pe8', 7.1, 98.9, '90/60', 65); 

INSERT INTO pre_exam (peid, hemoglobin_gDL, temperature_F, blood_pressure, pulse_rate_BPM)
	VALUES ('pe9', 8.0, 98.6, '130/85', 80);

INSERT INTO pre_exam (peid, hemoglobin_gDL, temperature_F, blood_pressure, pulse_rate_BPM)
	VALUES ('pe10', 7.9, 98.7, '120/80', 82);

INSERT INTO pre_exam (peid, hemoglobin_gDL, temperature_F, blood_pressure, pulse_rate_BPM)
	VALUES ('pe11', 7.6, 98.4, '90/60', 76);

INSERT INTO pre_exam (peid, hemoglobin_gDL, temperature_F, blood_pressure, pulse_rate_BPM)
	VALUES ('pe12', 6.9, 98.5, '120/80', 70);

INSERT INTO pre_exam (peid, hemoglobin_gDL, temperature_F, blood_pressure, pulse_rate_BPM)
	VALUES ('pe13', 14.5, 98.3, '120/80', 70);

INSERT INTO pre_exam (peid, hemoglobin_gDL, temperature_F, blood_pressure, pulse_rate_BPM)
	VALUES ('pe14', 15.3, 98.4, '110/70', 77);

INSERT INTO pre_exam (peid, hemoglobin_gDL, temperature_F, blood_pressure, pulse_rate_BPM)
	VALUES ('pe15', 14.3, 98.3, '120/80', 63);

INSERT INTO pre_exam (peid, hemoglobin_gDL, temperature_F, blood_pressure, pulse_rate_BPM)
	VALUES ('pe16', 13.9, 98.3, '110/70', 81);
    
INSERT INTO pre_exam (peid, hemoglobin_gDL, temperature_F, blood_pressure, pulse_rate_BPM)
	VALUES ('pe17', 16.4, 98.8, '120/80', 72);
    
INSERT INTO pre_exam (peid, hemoglobin_gDL, temperature_F, blood_pressure, pulse_rate_BPM)
	VALUES ('pe18', 17.1, 98.1, '120/80', 59);


-- 
INSERT INTO transfusion (tid, pid, peid, nurse, amount_recieved_CC)
	VALUES ('t1','p1','pe8','p2',473);

INSERT INTO transfusion (tid, pid, peid, nurse, amount_recieved_CC)
	VALUES ('t2','p3','pe9','p4',946);

INSERT INTO transfusion (tid, pid, peid, nurse, amount_recieved_CC)
	VALUES ('t3','p6','pe10','p2',473);

INSERT INTO transfusion (tid, pid, peid, nurse, amount_recieved_CC)
	VALUES ('t4','p11','pe11','p10',716);

INSERT INTO transfusion (tid, pid, peid, nurse, amount_recieved_CC)
	VALUES ('t5','p12','pe12','p4',473);
-- 

INSERT INTO transfusion_records (tid, lid, transfusion_date, bbid)
	VALUES ('t1','L1', '2016-09-10','bb1');

INSERT INTO transfusion_records (tid, lid, transfusion_date, bbid)
	VALUES ('t2','L5', '2016-11-13','bb8');

INSERT INTO transfusion_records (tid, lid, transfusion_date, bbid)
	VALUES ('t3','L1', '2016-11-21','bb9');

INSERT INTO transfusion_records (tid, lid, transfusion_date, bbid)
	VALUES ('t4','L10', '2016-12-02','bb6');

INSERT INTO transfusion_records (tid, lid, transfusion_date, bbid)
 	VALUES ('t5','L5', '2016-12-05','bb10');

-- 

 INSERT INTO donation(did, pid, peid, nurse, amount_donated_CC, donation_type)
	VALUES ('d1','p4','pe1','p16',946,'Power Red');

INSERT INTO donation(did, pid, peid, nurse, amount_donated_CC, donation_type)
	VALUES ('d2','p7','pe2','p17',473,'Blood');
    
INSERT INTO donation(did, pid, peid, nurse, amount_donated_CC, donation_type)
	VALUES ('d3','p8','pe3','p18',473,'Plasma');

INSERT INTO donation(did, pid, peid, nurse, amount_donated_CC, donation_type)
	VALUES ('d4','p9','pe4','p19',473,'Blood');

INSERT INTO donation(did, pid, peid, nurse, amount_donated_CC, donation_type)
	VALUES ('d5','p13','pe5','p16',473,'Platelets');

INSERT INTO donation(did, pid, peid, nurse, amount_donated_CC, donation_type)
	VALUES ('d6','p14','pe6','p16',473,'Blood');

INSERT INTO donation(did, pid, peid, nurse, amount_donated_CC, donation_type)
	VALUES ('d7','p15','pe7','p16',473,'Blood');

INSERT INTO donation(did, pid, peid, nurse, amount_donated_CC, donation_type)
	VALUES ('d8','p4','pe13','p16',473,'Blood');

INSERT INTO donation(did, pid, peid, nurse, amount_donated_CC, donation_type)
	VALUES ('d9','p14','pe14','p16',473,'Blood');

INSERT INTO donation(did, pid, peid, nurse, amount_donated_CC, donation_type)
	VALUES ('d10','p20','pe15','p17',473,'Blood');

INSERT INTO donation(did, pid, peid, nurse, amount_donated_CC, donation_type)
	VALUES ('d11','p15','pe16','p18',473,'Blood');

INSERT INTO donation(did, pid, peid, nurse, amount_donated_CC, donation_type)
	VALUES ('d12','p21','pe17','p19',473,'Blood');
    
INSERT INTO donation(did, pid, peid, nurse, amount_donated_CC, donation_type)
	VALUES ('d13','p20','pe18','p16',473,'Blood');


-- 
INSERT INTO donation_records (did, lid, donation_date, bbid)
	VALUES ('d1','L3', '2016-07-01','bb3');  

INSERT INTO donation_records (did, lid, donation_date, bbid)
	VALUES ('d2','L6', '2016-07-30','bb2'); 

INSERT INTO donation_records (did, lid, donation_date, bbid)
	VALUES ('d3','L8', '2016-08-14','bb4'); 

INSERT INTO donation_records (did, lid, donation_date, bbid)
	VALUES ('d4','L9', '2016-09-18','bb5'); 
    
INSERT INTO donation_records (did, lid, donation_date, bbid)
	VALUES ('d5','L3', '2016-08-12','bb7');  
    
INSERT INTO donation_records (did, lid, donation_date, bbid)
	VALUES ('d6','L3', '2016-12-01','bb11');   
    
INSERT INTO donation_records (did, lid, donation_date, bbid)
	VALUES ('d7','L3', '2016-08-18','bb12'); 

INSERT INTO donation_records (did, lid, donation_date, bbid)
	VALUES ('d8','L3', '2016-09-03','bb13');

INSERT INTO donation_records (did, lid, donation_date, bbid)
	VALUES ('d9','L3', '2016-09-03','bb1'); 
    
INSERT INTO donation_records (did, lid, donation_date, bbid)
	VALUES ('d10','L6', '2016-08-13','bb6'); 

INSERT INTO donation_records (did, lid, donation_date, bbid)
	VALUES ('d11','L6', '2016-07-08','bb8'); 

INSERT INTO donation_records (did, lid, donation_date, bbid)
	VALUES ('d12','L8', '2016-11-20','bb9'); 

INSERT INTO donation_records (did, lid, donation_date, bbid)
	VALUES ('d13','L3', '2016-12-06' ,'bb10'); 
-- 

-- 
-- SECURITY ROLES 
-- 
DROP ROLE IF EXISTS ADMIN;
DROP ROLE IF EXISTS REGISTER;
DROP ROLE IF EXISTS REQUESTER;

CREATE ROLE ADMIN;
GRANT ALL ON ALL TABLES IN SCHEMA PUBLIC TO ADMIN;

CREATE ROLE REGISTER;
REVOKE ALL ON ALL TABLES IN SCHEMA PUBLIC FROM REGISTER;
GRANT SELECT ON ALL TABLES IN SCHEMA PUBLIC TO REGISTER;
GRANT INSERT ON PERSONS, PATIENT, NURSE, DONOR, 
			    PRE_EXAM, TRANSFUSION, DONATION, 
                BLOODBAGS, DONATION_RECORDS, 
                TRANSFUSION_RECORDS         
	            TO REGISTER;
GRANT UPDATE ON PERSONS, PATIENT, NURSE, DONOR, 
			    PRE_EXAM, TRANSFUSION, DONATION, 
                BLOODBAGS, DONATION_RECORDS, 
                TRANSFUSION_RECORDS         
	            TO REGISTER;


CREATE ROLE REQUESTER;
REVOKE ALL ON ALL TABLES IN SCHEMA PUBLIC FROM REQUESTER;
GRANT SELECT ON REQUESTS, LOCATIONS, LOCATION_CODES
	TO REQUESTER;
GRANT INSERT ON REQUESTS, LOCATIONS, LOCATION_CODES
	TO REQUESTER;
GRANT UPDATE ON REQUESTS, LOCATIONS, LOCATION_CODES
	TO REQUESTER;