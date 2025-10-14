create or replace PROCEDURE generate_invoice_xml4(p_invoice_id IN VARCHAR)
AS
    l_xml_clob   CLOB;
 --   l_xml_blob   BLOB; -- := DBMS_LOB.EMPTY_BLOB();
    l_invoice_exists NUMBER;

    dest_offset   INTEGER := 1;
    src_offset    INTEGER := 1;
 --   lang_context  INTEGER := DBMS_LOB.DEFAULT_LANG_CTX;
    warning       INTEGER := 0;

    v_total_line_net_amount NUMBER; -- for VAT Summation Calculation
    v_total_document_charge NUMBER; -- not in use
    v_total_document_allowance NUMBER; -- not in use

    vat_breakdown_xml CLOB := '';
 --   vat_breakdown_xml XMLTYPE;  -- Change to XMLTYPE
    v_tax_rate NUMBER;
    v_vat_category_code VARCHAR2(10);
    v_net_amount NUMBER;
    v_tax_amount NUMBER;

    CURSOR tax_cursor IS
        SELECT TAX_RATE, TAX_CATEGORY,
               SUM(BETRAG_SUMME) AS NET_AMOUNT
        FROM VC_RECHNUNG_POS
        WHERE RECHNUNG_FK = p_invoice_id
        GROUP BY TAX_RATE, TAX_CATEGORY;


BEGIN
    -- Initialize VAT breakdown XML
 --   vat_breakdown_xml := XMLTYPE('<vat_breakdowns/>');  -- oben

    -- Loop through each tax rate and generate VAT breakdown elements
   -- Loop für VAT-Berechnung und Erstellung der ApplicableTradeTax-Elemente
  /*********************************
    FOR tax_record IN tax_cursor LOOP
        v_tax_rate := tax_record.TAX_RATE;
        v_vat_category_code := tax_record.TAX_CATEGORY;
        v_net_amount := tax_record.NET_AMOUNT;
        v_tax_amount := v_net_amount * v_tax_rate / 100;

        -- Nur hinzufügen, wenn ein Steuersatz > 0
        IF v_tax_rate > 0 THEN
            vat_breakdown_xml := vat_breakdown_xml || 
                XMLElement("ram:ApplicableTradeTax",
                    XMLElement("ram:CalculatedAmount", TO_CHAR(v_tax_amount, '9990.99')),
                    XMLElement("ram:TypeCode", 'VAT'),
                    XMLElement("ram:BasisAmount", TO_CHAR(v_net_amount, '9990.99')),
                    XMLElement("ram:CategoryCode", v_vat_category_code),
                    XMLElement("ram:RateApplicablePercent", TO_CHAR(v_tax_rate, '9990.99'))
                ).getClobVal();
        END IF;
    END LOOP;

    -- Fall für steuerfreie Rechnungen (ohne VAT)
    IF vat_breakdown_xml IS NULL THEN
        vat_breakdown_xml := XMLElement("ram:ApplicableTradeTax",
            XMLElement("ram:CalculatedAmount", '0.00'),
            XMLElement("ram:TypeCode", 'VAT'),
            XMLElement("ram:BasisAmount", TO_CHAR(v_net_amount, '9990.99')),
            XMLElement("ram:CategoryCode", 'Z'),  -- "Z" für steuerfrei
            XMLElement("ram:RateApplicablePercent", '0.00')
        ).getClobVal();
    END IF;
*************************************/

 -- MAINPART XML-ERSTELLUNG

    SELECT 
        XMLSERIALIZE(DOCUMENT
            XMLElement(
                "rsm:CrossIndustryInvoice",
                XMLAttributes(
                    'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100' AS "xmlns:rsm",
                    'urn:un:unece:uncefact:data:standard:QualifiedDataType:100' AS "xmlns:qdt",
                    'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100' AS "xmlns:ram",
                    'http://www.w3.org/2001/XMLSchema' AS "xmlns:xs",
                    'urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100' AS "xmlns:udt"
                ),
                XMLElement("rsm:ExchangedDocumentContext",
                    XMLElement("ram:GuidelineSpecifiedDocumentContextParameter",
                        XMLElement("ram:ID", 'urn:cen.eu:en16931:2017')
                    )
                ),
                XMLElement("rsm:ExchangedDocument",
                    XMLElement("ram:ID", x_inv.ID),
                    XMLElement("ram:TypeCode", '380'), -- 380 = Handelsrechnung nach Codeliste UNTDID 1001
                    XMLElement("ram:IssueDateTime",
                        XMLElement("udt:DateTimeString", XMLAttributes('102' AS "format"), TO_CHAR(x_inv.ERSTELLT_DATUM, 'YYYYMMDD'))
                    ),
                CASE 
                    WHEN x_inv.NOTE_1 IS NOT NULL THEN
                        XMLElement("ram:IncludedNote",
                            XMLElement("ram:Content", x_inv.NOTE_1),
                            XMLElement("ram:SubjectCode", 'REG')
                        )
                END,
                CASE 
                    WHEN x_inv.NOTE_2 IS NOT NULL THEN
                        XMLElement("ram:IncludedNote",
                            XMLElement("ram:Content", x_inv.NOTE_2),
                            XMLElement("ram:SubjectCode", 'AAI')
                        )
                END,
                CASE 
                    WHEN x_inv.NOTE_3 IS NOT NULL THEN
                        XMLElement("ram:IncludedNote",
                            XMLElement("ram:Content", x_inv.NOTE_3),
                            XMLElement("ram:SubjectCode", 'AAI')
                        )
                END
            ),

            XMLElement("rsm:SupplyChainTradeTransaction",
                    -- Items / positionen
                    (SELECT XMLAgg(
                        XMLElement("ram:IncludedSupplyChainTradeLineItem",
                            XMLElement("ram:AssociatedDocumentLineDocument",
                                XMLElement("ram:LineID", x_item.ID)
                            ),
                            XMLElement("ram:SpecifiedTradeProduct",
                                XMLElement("ram:Name", x_item.BEZEICHNUNG)
                            ),
                            XMLElement("ram:SpecifiedLineTradeAgreement",
                                XMLElement("ram:GrossPriceProductTradePrice",
                                    XMLElement("ram:ChargeAmount", x_item.BETRAG_EINZEL)
                                ),
                                XMLElement("ram:NetPriceProductTradePrice",
                                    XMLElement("ram:ChargeAmount", x_item.BETRAG_EINZEL)
                                )
                            ),
                            XMLElement("ram:SpecifiedLineTradeDelivery",
                                XMLElement("ram:BilledQuantity", XMLAttributes('C62' AS "unitCode"), x_item.MENGE)
                            ),
                            XMLElement("ram:SpecifiedLineTradeSettlement",
                                XMLElement("ram:ApplicableTradeTax",
                                    XMLElement("ram:TypeCode", 'VAT'),
                                    XMLElement("ram:CategoryCode", 'E'),  -- S = standard
            --                        XMLElement("ram:ExemptionReason", 'Steuerfreie Leistung gemäß §4 Nr.1b UStG'),  -- in  ZUGFeRD en16931 nicht erlaubt
                                    XMLElement("ram:RateApplicablePercent", x_item.TAX_RATE)
                                ),
                                XMLElement("ram:SpecifiedTradeSettlementLineMonetarySummation",
                                    XMLElement("ram:LineTotalAmount", x_item.BETRAG_SUMME)
                                )
                            )
                        )
                    ) AS ram_items FROM VC_RECHNUNG_POS x_item WHERE x_item.RECHNUNG_FK = p_invoice_id
                    ),
                    XMLElement("ram:ApplicableHeaderTradeAgreement",
                        XMLElement("ram:SellerTradeParty",
                            XMLElement("ram:ID", '2025654321'), -- x_inv.SELLER_ID
                            XMLElement("ram:GlobalID", XMLAttributes('0088' AS "schemeID"), '4000001123452'), -- x_inv.VERSENDER_GOBAL_ID
                            XMLElement("ram:Name", x_inv.VERSENDER),
                            XMLElement("ram:PostalTradeAddress",
                                XMLElement("ram:PostcodeCode", x_inv.VERSENDER_POSTCODE),
                                XMLElement("ram:LineOne", x_inv.VERSENDER_STRASSE),
                                XMLElement("ram:CityName", x_inv.VERSENDER_CITY),
                                XMLElement("ram:CountryID", x_inv.VERSENDER_COUNTRY_CODE)
                            ),
                            XMLElement("ram:SpecifiedTaxRegistration",
                                XMLElement("ram:ID", XMLAttributes('FC' AS "schemeID"), x_inv.VERSENDER_STEUER_NR)
                            ),
                            XMLElement("ram:SpecifiedTaxRegistration",
                                XMLElement("ram:ID", XMLAttributes('VA' AS "schemeID"), x_inv.VERSENDER_UST_ID)
                            )
                        ),
                        XMLElement("ram:BuyerTradeParty",
                            XMLElement("ram:ID", x_inv.ID),
                            XMLElement("ram:Name", x_inv.EMPFAENGER),
                            XMLElement("ram:PostalTradeAddress",
                                XMLElement("ram:PostcodeCode", x_inv.POSTCODE),
                                XMLElement("ram:LineOne", x_inv.STRASSE),
                                XMLElement("ram:CityName", x_inv.CITY),
                                XMLElement("ram:CountryID", x_inv.COUNTRY_CODE)
                            )
                        )
                    ),

                     XMLElement("ram:ApplicableHeaderTradeDelivery",
                     XMLElement("ram:ShipToTradeParty",
                      XMLElement("ram:Name", x_inv.EMPFAENGER),  -- Replace with actual column for the recipient's name
                       XMLElement("ram:PostalTradeAddress",
                        XMLElement("ram:PostcodeCode", x_inv.POSTCODE),  -- Recipient's postal code
                        XMLElement("ram:LineOne", x_inv.STRASSE),        -- Recipient's street address
                        XMLElement("ram:CityName", x_inv.CITY),         -- Recipient's city
                        XMLElement("ram:CountryID", x_inv.COUNTRY_CODE) -- Recipient's country code
                    )
                ),

                XMLElement("ram:ActualDeliverySupplyChainEvent",
                    XMLElement("ram:OccurrenceDateTime",
                        XMLElement("udt:DateTimeString", XMLAttributes('102' AS "format"), TO_CHAR(x_inv.DATUM_LEISTUNG, 'YYYYMMDD'))
                    )
                )
            ),

                    XMLElement("ram:ApplicableHeaderTradeSettlement",
                        XMLElement("ram:InvoiceCurrencyCode", x_inv.WAEHRUNG_CODE),
                        XMLElement("ram:ApplicableTradeTax",
                                    XMLElement("ram:CalculatedAmount", '0.00'), -- x_inv.LINE_TOTAL_AMOUNT), --'0.00'), --v_vat_amount),  -- VAT amount
                                    XMLElement("ram:TypeCode", 'VAT'),
                                    XMLElement("ram:ExemptionReason", 'Steuerfreie Leistung gemäß §4 Nr.1b UStG'),
                                   XMLElement("ram:BasisAmount", x_inv.LINE_TOTAL_AMOUNT + x_inv.CHARGE_TOTAL_AMOUNT + x_inv.ALLOWANCE_TOTAL_AMOUNT ), -- VAT category taxable amount (BT-116)
                                    XMLElement("ram:CategoryCode", 'E') , -- Z = Zero  -- 'Standard rated'), E = Exemption -- BT-118
                                    XMLElement("ram:RateApplicablePercent", '0.00') --v_tax_rate)  -- BT-119
                        ),

                        XMLElement("ram:SpecifiedTradePaymentTerms",
                            XMLElement("ram:Description", x_inv.PAYMENT_TERMS)
                        ),

                        XMLElement("ram:SpecifiedTradeSettlementHeaderMonetarySummation",
                            XMLElement("ram:LineTotalAmount", x_inv.LINE_TOTAL_AMOUNT), -- Netto BT 106
                            XMLElement("ram:ChargeTotalAmount", x_inv.CHARGE_TOTAL_AMOUNT),  --Zuschlag  BT 107
                            XMLElement("ram:AllowanceTotalAmount", x_inv.ALLOWANCE_TOTAL_AMOUNT), -- Abschlag BT 108
                            XMLElement("ram:TaxBasisTotalAmount", x_inv.LINE_TOTAL_AMOUNT + x_inv.CHARGE_TOTAL_AMOUNT - x_inv.ALLOWANCE_TOTAL_AMOUNT ), --BT 109
                            XMLElement("ram:TaxTotalAmount", XMLAttributes(x_inv.WAEHRUNG_CODE AS "currencyID"), x_inv.TAX_TOTAL_AMOUNT), --BT 110
                            XMLElement("ram:GrandTotalAmount", x_inv.BRUTTOSUMME), --  BT 115
                            XMLElement("ram:DuePayableAmount", x_inv.BRUTTOSUMME)  -- BT 115
                        )
                    )
                )
            )
        ) INTO l_xml_clob
    FROM VC_RECHNUNG x_inv WHERE x_inv.ID = p_invoice_id
    AND ROWNUM = 1;

    -- Check if the invoice record exists in VC_DATEIEN table
    SELECT COUNT(*)
    INTO l_invoice_exists
    FROM VC_DATEIEN
    WHERE beleg_nr = p_invoice_id
    AND ROWNUM = 1;

    IF l_invoice_exists > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Updating existing entry for Invoice ID: ' || p_invoice_id);
        UPDATE VC_DATEIEN
        SET datei_xml = XMLTYPE(l_xml_clob) -- , datei_blob = l_xml_blob
        WHERE beleg_nr = p_invoice_id;
    ELSE
        DBMS_OUTPUT.PUT_LINE('Inserting new entry for Invoice ID: ' || p_invoice_id);
        INSERT INTO VC_DATEIEN (beleg_nr, datei_xml,  dateiname, mimetype)  -- datei_blob,
        VALUES (p_invoice_id, XMLTYPE(l_xml_clob),'TUS_RECHNUNG_' || p_invoice_id || '.xml', 'application/xml'); --  l_xml_blob, 
    END IF;

    COMMIT;
  --  DBMS_LOB.FREETEMPORARY(l_xml_blob);
  --  DBMS_OUTPUT.PUT_LINE('Transaction committed successfully.');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error during insert/update: ' || SQLERRM);
 --       DBMS_LOB.FREETEMPORARY(l_xml_blob);
        RAISE;

END generate_invoice_xml4;