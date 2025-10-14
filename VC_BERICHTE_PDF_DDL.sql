CREATE TABLE "VC_BERICHTE_PDF" 
   (	"ID" NUMBER NOT NULL ENABLE, 
	"DATEI_NAME" VARCHAR2(300), 
	"DATEI_MIMETYPE" VARCHAR2(20), 
	"DATEI_BLOB" BLOB, 
	"DATUM_ERSTELLT" DATE, 
	"ERSTELLT_VON" VARCHAR2(50), 
	"MITGLIED_FK" NUMBER, 
	"RECHNUNG_FK" NUMBER, 
	"MAIL_ANHANG" VARCHAR2(5), 
	 CONSTRAINT "VC_BERICHTE_PDF_PK" PRIMARY KEY ("ID")
  USING INDEX  ENABLE
   ) ;

  CREATE OR REPLACE EDITIONABLE TRIGGER "BI_VC_BERICHTE_PDF" 
  before insert on "VC_BERICHTE_PDF"               
  for each row  
begin   
  if :NEW."ID" is null then 
    select "VC_BERICHTE_PDF_SEQ".nextval into :NEW."ID" from sys.dual; 
  end if; 
end; 



/
ALTER TRIGGER "BI_VC_BERICHTE_PDF" ENABLE;

   CREATE SEQUENCE  "VC_BERICHTE_PDF_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;


create or replace TRIGGER "BI_VC_BERICHTE_PDF" 
  before insert on "VC_BERICHTE_PDF"               
  for each row  
begin   
  if :NEW."ID" is null then 
    select "VC_BERICHTE_PDF_SEQ".nextval into :NEW."ID" from sys.dual; 
  end if; 

end; 
