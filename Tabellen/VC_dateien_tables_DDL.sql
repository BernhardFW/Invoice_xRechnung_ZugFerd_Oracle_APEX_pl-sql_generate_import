  CREATE TABLE "VC_DATEIEN" 
   (	"ID" NUMBER NOT NULL ENABLE, 
	"DATEINAME" VARCHAR2(100), 
	"MIMETYPE" VARCHAR2(20), 
	"DATEI_BLOB" BLOB, 
	"CHARSET" VARCHAR2(20), 
	"LAST_UPDATED" DATE, 
	"MITGLIED_FK" NUMBER, 
	"PERSONAL_FK" NUMBER, 
	"BELEG_FK" NUMBER, 
	"BELEG_NR" VARCHAR2(20), 
	"BESCHREIBUNG" VARCHAR2(200), 
	"DATEI_XML" "XMLTYPE", 
	 CONSTRAINT "VC_DATEIEN_PK" PRIMARY KEY ("ID")
  USING INDEX  ENABLE
   ) ;

  CREATE OR REPLACE EDITIONABLE TRIGGER "BI_VC_DATEIEN" 
  before insert on "VC_DATEIEN"               
  for each row  
begin   
  if :NEW."ID" is null then 
    select "VC_DATEIEN_SEQ".nextval into :NEW."ID" from sys.dual; 
  end if; 
end; 

CREATE SEQUENCE  "VC_DATEIEN_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;

/
ALTER TRIGGER "BI_VC_DATEIEN" ENABLE;


create or replace TRIGGER "BI_VC_DATEIEN"   
  before insert on "VC_DATEIEN"               
  for each row  
begin   
  if :NEW."ID" is null then 
    select "VC_DATEIEN_SEQ".nextval into :NEW."ID" from sys.dual; 
  end if; 
end; 

/