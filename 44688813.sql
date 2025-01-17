-- INFS2200 Assignment, Semester 2 - 2017

-- Student Number: 44688813-- Student Name: Ali Nawaz Maan 
-- DOG_ID: 3376

--########################################################################################

-- 

SET TIMING ON;

-- Task 1: Constraints

-- a)

SELECT OWNER, CONSTRAINT_NAME, TABLE_NAME, SEARCH_CONDITION,
INDEX_NAME FROM USER_CONSTRAINTS;

-- b)

ALTER TABLE CUSTOMERS 
ADD CONSTRAINT PK_CUSTOMERS  PRIMARY KEY (C_ID); 

ALTER TABLE DOGS ADD CONSTRAINT FK_C_ID FOREIGN KEY (C_ID)
REFERENCES CUSTOMERS (C_ID); 

ALTER TABLE DOGS MODIFY DOG_NAME VARCHAR2(50) NOT NULL;

ALTER TABLE CUSTOMERS MODIFY DOB DATE NOT NULL;

ALTER TABLE SERVICES MODIFY PRICE NUMBER(4,2) NOT NULL;

ALTER TABLE SERVICE_HISTORY ADD CONSTRAINT  CK_FINISHED 
CHECK ((FINISHED = 'T') OR (FINISHED = 'F')); 

ALTER TABLE CUSTOMERS ADD CONSTRAINT  CK_DOB 
CHECK (EXTRACT(YEAR FROM DOB) < 1999); 

ALTER TABLE SERVICE_HISTORY_DETAIL ADD CONSTRAINT  CK_START_TIME_END_TIME  
CHECK (END_TIME > START_TIME); 

ALTER TABLE SERVICE_HISTORY_DETAIL ADD CONSTRAINT  CK_SERVICE_DATE  
CHECK (EXTRACT(YEAR FROM END_TIME) < 2018); 

commit;

--########################################################################################

-- Task 2: Triggers

-- a)

CREATE SEQUENCE "SEQ_CUSTOMER" MINVALUE 10000 MAXVALUE 999999999999
INCREMENT BY 1 START WITH 10000;

CREATE OR REPLACE TRIGGER "TR_CUSTOMER_ID"
BEFORE INSERT ON "CUSTOMERS"
FOR EACH ROW
BEGIN
 SELECT "SEQ_CUSTOMER".NEXTVAL INTO :NEW.C_ID FROM DUAL;
END;
/



-- b)



CREATE SEQUENCE "SEQ_SERVICE_HISTORY" MINVALUE 125000 MAXVALUE 999999999999
INCREMENT BY 1 START WITH 125000;

CREATE OR REPLACE TRIGGER "TR_SERVICE_ID"
BEFORE INSERT ON "SERVICE_HISTORY"
FOR EACH ROW
BEGIN
 SELECT "SEQ_SERVICE_HISTORY".NEXTVAL INTO :NEW.SERVICE_ID FROM DUAL;
END;
/


-- c)

CREATE OR REPLACE TRIGGER "TR_SERVICE_HISTORY_MESSAGE"
BEFORE INSERT OR UPDATE ON SERVICE_HISTORY
FOR EACH ROW
DECLARE
    CUSTOMER_F VARCHAR2(50);
	CUSTOMER_L VARCHAR2(50);
    DOG VARCHAR2(50);
    BREED VARCHAR2(50);
	STORE VARCHAR2(50);
	STORE_MESSAGE VARCHAR2(200);
BEGIN

    SELECT DISTINCT F_NAME 
      INTO CUSTOMER_F 
      FROM CUSTOMERS, DOGS, SERVICE_HISTORY 
      WHERE DOGS.DOG_ID= :NEW.DOG_ID
	  AND DOGS.C_ID = CUSTOMERS.C_ID;
	  
	  SELECT DISTINCT L_NAME 
      INTO CUSTOMER_L 
      FROM CUSTOMERS, DOGS, SERVICE_HISTORY 
      WHERE DOGS.DOG_ID= :NEW.DOG_ID
	  AND DOGS.C_ID = CUSTOMERS.C_ID;
	  
	  SELECT DISTINCT DOG_NAME 
      INTO DOG 
      FROM DOGS, SERVICE_HISTORY 
      WHERE DOGS.DOG_ID= :NEW.DOG_ID;
	  
	  SELECT DISTINCT DOG_BREED 
      INTO BREED 
      FROM DOGS, SERVICE_HISTORY 
      WHERE DOGS.DOG_ID= :NEW.DOG_ID;
	  
	  SELECT DISTINCT STORE_AREA 
      INTO STORE 
      FROM STORES, SERVICE_HISTORY 
      WHERE STORES.STORE_ID= :NEW.STORE_ID;

    IF (:NEW.FINISHED ='T') THEN
	  STORE_MESSAGE := ' is ready for pick-up at ' || STORE || '.';
    ELSE
      STORE_MESSAGE := ' is not ready to be picked up yet.';
    END IF;

    :NEW.MESSAGE := 'Hi ' || CUSTOMER_F || ' ' || CUSTOMER_L || ' your dog ' || DOG || ' of breed: ' || BREED || ' ' || STORE_MESSAGE;

    END;
/

commit;

-- d)

INSERT INTO CUSTOMERS (F_NAME, L_NAME, DOB)
VALUES (�Luke�, �Cheung�, �08-OCT-1996�);

INSERT INTO SERVICE_HISTORY (DOG_ID, STORE_ID, FINISHED)
VALUES (1234, 30, 'F');

commit;

--########################################################################################

-- Task 3: Views

-- a)

CREATE VIEW V_DOG_BREED_STATISTICS AS
SELECT DOG_BREED, SUM(PRICE) AS TOTAL, AVG(PRICE) AS MEAN, STDDEV(PRICE) AS STANDARD_DEV
FROM SERVICE_HISTORY, DOGS, DOG_BREEDS, SERVICE_HISTORY_DETAIL, SERVICES
WHERE
SERVICE_HISTORY.DOG_ID = DOGS.DOG_ID AND
DOGS.DOG_BREED = DOG_BREEDS.BREED AND
SERVICE_HISTORY.SERVICE_ID = SERVICE_HISTORY_DETAIL.SERVICE_ID AND
SERVICE_HISTORY_DETAIL.SERVICE_NAME = SERVICES.SERVICE_NAME
GROUP BY DOG_BREED;



-- b)

CREATE MATERIALIZED VIEW MV_DOG_BREED_STATISTICS AS
SELECT DOG_BREED, SUM(PRICE) AS TOTAL, AVG(PRICE) AS MEAN, STDDEV(PRICE) AS STANDARD_DEV
FROM SERVICE_HISTORY, DOGS, DOG_BREEDS, SERVICE_HISTORY_DETAIL, SERVICES
WHERE
SERVICE_HISTORY.DOG_ID = DOGS.DOG_ID AND
DOGS.DOG_BREED = DOG_BREEDS.BREED AND
SERVICE_HISTORY.SERVICE_ID = SERVICE_HISTORY_DETAIL.SERVICE_ID AND
SERVICE_HISTORY_DETAIL.SERVICE_NAME = SERVICES.SERVICE_NAME
GROUP BY DOG_BREED;

commit;
--########################################################################################

-- Task 4: Function Based Indexes


-- a)

SELECT * FROM (

SELECT DOGS.DOG_ID, DOGS.DOG_NAME, STORES.STORE_ID, STORES.STORE_AREA, START_TIME-END_TIME AS TIME_TAKEN
FROM SERVICE_HISTORY_DETAIL, SERVICE_HISTORY, DOGS, STORES
WHERE
SERVICE_HISTORY_DETAIL.SERVICE_ID = SERVICE_HISTORY.SERVICE_ID AND
SERVICE_HISTORY.STORE_ID = STORES.STORE_ID AND
SERVICE_HISTORY.DOG_ID = DOGS.DOG_ID AND
SERVICE_NAME = 'Dental Checkup'
ORDER BY TIME_TAKEN DESC)

WHERE ROWNUM=1;




 

-- b)

CREATE INDEX SUBTRACT_START_END ON SERVICE_HISTORY_DETAIL(START_TIME-END_TIME);

commit;

--########################################################################################

-- Task 5: Bitmap Indexing

-- a)

SELECT COUNT(*), SERVICE_NAME 
FROM SERVICE_HISTORY_DETAIL 
GROUP BY SERVICE_NAME;

-- b)

CREATE BITMAP INDEX BIDX_SERVICE ON SERVICE_HISTORY_DETAIL(SERVICE_NAME);

commit;

--########################################################################################

-- Task 6: Execution Plan & Analysis

SELECT GET_UNIQUE_SNUMBER(44688813) FROM DUAL;

-- UNIQUE DOG_ID: 7939

-- b)

SELECT *
FROM (SELECT A.INDEX_NAME, A.TABLE_NAME, A.COLUMN_NAME, B.INDEX_TYPE
	FROM USER_IND_COLUMNS A, USER_INDEXES B
	WHERE A.TABLE_NAME='STORES' AND A.INDEX_NAME=B.INDEX_NAME AND
	B.INDEX_TYPE='NORMAL'), 
	
	(SELECT A.INDEX_NAME, A.TABLE_NAME, A.COLUMN_NAME, B.INDEX_TYPE
	FROM USER_IND_COLUMNS A, USER_INDEXES B
	WHERE A.TABLE_NAME='SERVICE_HISTORY' AND A.INDEX_NAME=B.INDEX_NAME AND
	B.INDEX_TYPE='NORMAL'),
	
	(SELECT A.INDEX_NAME, A.TABLE_NAME, A.COLUMN_NAME, B.INDEX_TYPE
	FROM USER_IND_COLUMNS A, USER_INDEXES B
	WHERE A.TABLE_NAME='SERVICE_HISTORY_DETAIL' AND A.INDEX_NAME=B.INDEX_NAME AND
	B.INDEX_TYPE='NORMAL');


-- c)


EXPLAIN PLAN FOR SELECT COUNT(*) FROM SERVICE_HISTORY, SERVICE_HISTORY_DETAIL  
WHERE DOG_ID=7939 AND SERVICE_HISTORY.SERVICE_ID = SERVICE_HISTORY_DETAIL.SERVICE_ID;


SELECT PLAN_TABLE_OUTPUT FROM TABLE (DBMS_XPLAN.DISPLAY);

-- d)

ALTER TABLE SERVICE_HISTORY_DETAIL DROP CONSTRAINT FK_SHD_SERVICE_ID;

ALTER TABLE SERVICE_HISTORY_DETAIL DROP CONSTRAINT PK_SHD;

ALTER TABLE SERVICE_HISTORY DROP CONSTRAINT PK_SERVICE_HISTORY;

SELECT OWNER, CONSTRAINT_NAME, TABLE_NAME, SEARCH_CONDITION,
INDEX_NAME FROM USER_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_SHD_SERVICE_ID';

SELECT OWNER, CONSTRAINT_NAME, TABLE_NAME, SEARCH_CONDITION,
INDEX_NAME FROM USER_CONSTRAINTS WHERE CONSTRAINT_NAME = 'PK_SHD';

SELECT OWNER, CONSTRAINT_NAME, TABLE_NAME, SEARCH_CONDITION,
INDEX_NAME FROM USER_CONSTRAINTS WHERE CONSTRAINT_NAME = 'PK_SERVICE_HISTORY';

-- e)

ANALYZE INDEX PK_STORES VALIDATE STRUCTURE;

SELECT NAME, USED_SPACE, HEIGHT, LF_BLKS, BLKS_GETS_PER_ACCESS FROM INDEX_STATS;


--########################################################################################


COMMIT;