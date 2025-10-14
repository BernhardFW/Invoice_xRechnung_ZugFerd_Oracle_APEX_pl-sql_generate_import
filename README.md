# Invoice_xRechnung_ZugFerd_Oracle_APEX_pl-sql_generate_import
Author: Bernhard Fischer-Wasels -13.10.2025
-------------------------------------------

ZUGFeRD - xRechnung Importieren/Generieren - how to:

-----------------------------------------------------

<b>Allgemein:</b>

Ab dem 01.01.2025 gilt die E-Rechnung für B2B Unternehmen als verpflichtend, obgleich noch einige, wenige Ausnahmen bis 2027 vom Gesetzesgeber gewährt werden. Ab 2028 müssen dann alle B2B Unternehmen die Anforderungen von elektronischen Rechnungen erfüllen. Eine E-Rechnung stellt Rechnungsinhalte in einem strukturierten und maschinell lesbaren Datensatz dar. Ein Rechnungssteller kann diese E-Rechnungen mittels „XRechnung“ oder „ZUGFeRD“ einreichen.

Aber was verbirgt sich hinter diesen Begriffen und worin unterscheiden sie sich? Das und mehr erfahren Sie in diesem Artikel unseres EDI-Blogs von HÜNGSBERG…

ZUGFeRD und X-Rechnung: Was ist das?
Die XRechnung stellt ein Standardrechnungsformat für den Versand von elektronischen Rechnungen an deutsche Bundesbehörden dar und basiert auf der europäischen Norm EN 16831.

ZUGFeRD ist ein branchenübergreifendes Datenformat für den Austausch elektronischer Rechnungsdaten. Das Format ZUGFeRD steht für Zentraler User Guide des Forums elektronische Rechnung Deutschland und wurde vom Forum elektronische Rechnung Deutschland (FeRD) mit Unterstützung des Bundesministeriums für Wirtschaft und Energie (BMWK) erarbeitet.

Quelle: https://www.huengsberg.com/edi-blog/edi/zugferd-vs-xrechnung.html

<b>Mein Ansatz:</b>

Da der von mir EDV-mäßig betreute Sportverein auch diese Anforderungen erfüllen muß, habe ich mich mit diesem Thema beschäftigt.

Gemeinnützige Vereine sind zwar eigentlich von diesen Anforderungen ausgenommen, aber in dem Moment, wo der Verein kommerzielle Einnahmen hat (wie z.B. aus Bandenwerbung oder Trikotwerbung), gilt diese Ausnahme nicht mehr...


"Export"

Im "APEX Rechnungsmodul" kann man eine Rechnung erstellen und diese als PDF und XML per Email versenden. Die PDF-Rechnung erstelle ich mittels <a target=new href ="https://www.jaspersoft.com/products/jaspersoft-community">TIBCO Jasper Reports (Community Edition).</a>

"Import"

Ferner kann man im APEX Rechnungsmodul Rechnungen im xml-Format importieren, sie in Tabellen importieren und somit in die eigene Buchhaltung integrieren (nicht Teil des Rechnungsmoduls) und dann verbuchen.

<b>Umsetzung</b>

Es sind dazu 4 pl/sql-procedures notwendig:

1) GENERATE_INVOICE_XML.PLS - Generierung einer ZUGFeRD-xml

2) IMPORT_INVOICE_UNCEFACT.PLS - ZUGFeRT-Format xml importieren (Cross Industry Invoice)

3) IMPORT_UBL_INVOICE.PLS - xRechnung-Format importieren (eigentlich nur ein Format der Bundesbehörden)

4) IMPORT_UBL_UNCEFACT.PLS - eine Weiche, die beim Import entscheidet, ob Programm 2) oder 3) genommen werden soll.

Und es gibt das Rechnungsmodul als APEX-Anwendung mit Apex-Workspace-User-Authentication.

---------------------------------
<b>Vorgehensweise:</b>
---------------------------------

Die APEX-Anwendung APEX_24.1.2_XML_IMPORTIEREN_APP_f320.sql importieren.

Einloggen mit WS-User (APEX workspace Authentication).

<b>Import:</b>

Startseite: [ Importieren ] - oder - [ Generieren ]

Auf der Import-Startseite kann man (zur Zeit nur) xml-Rechnungen im ZUGFeRD-Format importieren.
Wenn man beide Formate importieren möchte, müßte man das Procedure mit der "Weiche" aufrufen (oben Nr. 4)

Der Import nutzt 8 Tabellen, die ich an die Namespaces bzw. XMLElements angelehnt habe.

X_BUYERTRADEPART

X_SELLERTRADEPARTY

X_EXCHANGEDDOCUMNT - Rechnung_invoice_header

X_EXCHANGEDDOCUMENTCONTEXT

X_SUPPLYCHAINTRADELINEITEM - Rechnungs-Positionen

X_SUPPLYCHAINTRADETRANSACTION

X_TRADETAX

X_INCLUDEDNOTES


<b>"Export": ZUGFeRD-XML Generieren:</b>

Rechnung erstellen (Tabellen: VC_RECHNUNG und VC_RECHNUNG_POS)  und dann Button [xml generieren] klicken
Es wird dann eine ZUGFeRD-xml erstellt (ohne UST bzw. UST = 0.00 )und in die Tabelle VC_DATEIEN abgelegt (clob/xmltype).
Mehrere UST/MWSt-Sätze müssten noch ergänzt werden (bei der Generierung der xml-datei).

--> Region ganz unten "XML-Dateien in VC_DATEIEN"

Dort ist auch ein Button, mit dem man dann die xml-Rechnung mailen kann.

Der Mailprozess muss angepasst werden - dort sind hardkodierte Daten/Empfänger und Mail-Text drin.

Eine Rechnung als PDF erstelle ich über TIBCO-Jasper reports...
Oben : "Jasper_Reports_6.16_VC_XRECHNUNG.jrxml"

Ich kann für Oracle APEX in Kombination mit Jasper reports den Hosting Provider Maxapex.com empfehlen. Alle meine produktiven Anwendungen - auch für zahlende Kunden - laufen dort seit 5-6 Jahren ohne Downtime.

Maxapex bietet neben dem <b>APEX Hosting auch einen Jasper Reports SERVER</b>, sodaß man in Jasper Reports Studio entwickelte Formulare dort laufen lassen kann und sie von APEX aus ansprechen kann.

Maxapex ist stets auf der aktuellen APEX Version (aktuell 24.2.) und man "mietet" dort quasi die Oracle Datenbank (XE) mit APEX und Jasper Reports Server.

Mehr auf https://maxapex.com

Siehe auch: https://bfw-design.de

Wittorf, 6.11.24


