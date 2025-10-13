# Invoice_xRechnung_ZugFerd_Oracle_APEX_pl-sql_generate_import
Author: Bernhard Fischer-Wasels -13.10.2025
-------------------------------------------

ZUGFeRD - xRechnung Importieren/Generieren - how to:

-----------------------------------------------------

Es sind dazu 4 pl/sql-procedures notwendig:

1) IMPORT_INVOICE_UNCEFACT.PLS - ZUGFeRT-Format xml importieren

2) IMPORT_UBL_INVOICE.PLS - xRechnung-Format importieren (eigentlich nur ein Format der Bundesbehörden)

3) GENERATE_INVOICE_XML.PLS - Generierung einer ZUGFeRD-xml
(im zip-File)

4) IMPORT_UBL_UNCEFACT.PLS - eine Weiche, die beim Import entscheidet, ob Programm 1) oder 2) genommen werden soll.

5) APEX-Anwendung mit Apex-Workspace-User-Authentication

Vorgehensweise:

Die APEX-Anwendung APEX_24.1.2_XML_IMPORTIEREN_APP_f320.sql importieren.

Einloggen mit WS-User (APEX workspace Authentication).

Import:

Startseite: [ Importieren ] - oder - [ Generieren ]

Auf der Import-Startseite kann man (zur Zeit nur) xml-Rechnungen im ZUGFeRD-Format importieren.
Wenn man beide Formate importieren möchte, müßte man das Procedure mit der "Weiche" aufrufen...
Bei Bedarf die DDL's der Tabellen anfragen bei Bernhard@fischer-Wasels.de

Der Import nutzt 8 Tabellen, die ich an die Namespaces bzw. XMLElements angelehnt habe.
X_BUYERTRADEPART
X_SELLERTRADEPARTY
X_EXCHANGEDDOCUMNT - Rechnung_invoice_header
X_EXCHANGEDDOCUMENTCONTEXT
X_SUPPLYCHAINTRADELINEITEM - Rechnungs-Positionen
X_SUPPLYCHAINTRADETRANSACTION
X_TRADETAX
X_INCLUDEDNOTES

ZUGFeRD-XML Generieren:

Rechnung erstellen (Tabellen: VC_RECHNUNG und VC_RECHNUNG_POS)  und dann Button [xml generieren] klicken
Es wird dann eine ZUGFeRD-xml erstellt (ohne UST bzw. UST = 0.00 )und in die Tabelle VC_DATEIEN abgelegt (clob/xmltype).
Mehrere UST/MWSt-Sätze müssten noch ergänzt werden (bei der Generierung der xml-datei).

--> Region ganz unten "XML-Dateien in VC_DATEIEN"

Dort ist auch ein Button, mit dem man dann die xml-Rechnung mailen kann.

Der Mailprozess muss angepasst werden - dort sind hardkodierte Daten/Empfänger und Mail-Text drin.

Eine Rechnung als PDF erstelle ich über TIBCO-Jasper reports...
Oben : "Jasper_Reports_6.16_VC_XRECHNUNG.jrxml"

Ich kann für Oracle APEX in Kombination mit Jasper reports den Hosting Provider Maxapex.com empfehlen. Alle meine produktiven Anwendungen - auch für zahlende Kunden - laufen dort seit 5-6 Jahren ohne Downtime.

Siehe auch: https://bfw-design.de

Wittorf, 6.11.24


