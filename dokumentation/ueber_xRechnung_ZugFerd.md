<b>XRechnung</b> ist erstmal nur das CIUS (Core Invoice Usage Specification) von den deutschen Bundesbehörden.<br>
Das wurde aber in der Syntax UBL (OASIS) definiert. <br><br>
<b>ZUGFeRD</b> steht als Kurzform für <b>„Zentraler User Guide des Forums elektronische Rechnung Deutschland“.</b><br>
Das Format für den elektronischen Rechnungsaustausch ZUGFeRD soll künftig bundesweit die bestehenden EDI-Standards ergänzen und papierbasierte Prozesse ablösen.<br>
ZUGFeRD nutzt eine andere Syntax und zwar die von CII (Cross Industy Invoice von UN/CEFACT).<br><br>

Den Umfang beider Syntaxen werden von der EU Norm EN 16931 definiert.<br><br>

Dabei ist aber zu beachten, das nur die UBL Syntax (xRechnung) basierend auf der Norm Peppol fähig ist.<br><br>

Peppol hat aber eine eigene CIUS und in der Regel ist die EN16931 Norm nur eine Teilmenge davon.<br><br>

Die SAP Lösung für Deutschland bedient sich der CIUS des Peppol Netzwerkes (BIS 3.0) und lokalisiert es auf die XRechnung, um es über Peppol zu versenden. Bei dem E-Mail Versand, wandelt ein Konverter diese UBL in eine CII-XML um und wird in der Cloud validiert. Bei der positiver Rückmeldung muss das dazugehörige PDF noch hinzugefügt werden und beim E-Mail Versand wird aus beiden eine ZUGFeRD Rechnung gemacht und versendet.<br><br>

Source: https://community.sap.com/t5/enterprise-resource-planning-q-a/unterschied-xrechnung-un-cefact-und-zugferd-rechnung/qaq-p/12278543
<br><br>

<a target=new href="https://de.wikipedia.org/wiki/ZUGFeRD"><b>Wikipedia (ausführlich)</b></a><br><br>

<a target=new href ="https://lsb-niedersachsen.vibss.de/vereinsmanagement/aktuelles/detail/elektronische-rechnungen">Der LSB schreibt dazu hier</a><br><br>

<b>xRechnung/ZUGFeRD und die Vereinscloud</b><br>
08.10.24/fw - Da xRechnung im Wesentlichen für die deutschen Behörden gedacht ist (nach meinem Verständnis), habe ich mich für die VereinsCloud auf ZUGFeRD fokussiert.<br>
Zunächst kann man auf der Startseite ZUGFeRD-Rechnungen (das .xml) <b>empfangen und einlesen</b>.<br>
Als 2. Schritt wird man die Rechnung anweisen/bezahlen und <br>
3. dann (über den Kontoauszug) verbuchen können.<br>
4. ist der Nebenefffekt die Speicherung und <b>Archivierung</b><br>
5. Schritt wird dann die Erstellung einer ZUGFeRD-Rechnung sein: ein PDF + xml-Datei als Anhang zum Versenden.<br><br>

<a target=new href="https://www.ferd-net.de/standards/zugferd-2.3/zugferd-2.3.html">Aktuelle Version ZUGFeRD 2.3.0</a><br><br>

<a target=new href="https://github.com/itplr-kosit/xrechnung-testsuite/tree/master/src/test/business-cases/standard">(alte)Testsuite/Cases</a> xRechnung und UNCEFACT (ZugFerd):<br><br>

<a target = new href ="https://www.seeburger.com/resources/good-to-know/what-is-peppol">Was ist Peppol ?</a><br><br>

<a target=new href ="https://easy-software.com/de/newsroom/peppol-was-ist-das-wem-hilfts-kann-man-es-schon-nutzen/">Erklärt von Easy-Software.de</a><br><br>

<b>Interesting:</b><br>
<a target=new href="https://github.com/pretix/python-drafthorse/tree/master">Github/Python Implementierung!!!</a>
