create or replace PROCEDURE import_invoice_uncefact(
    xml_clob   IN CLOB,         -- Input parameter for the XML data
    l_filename IN VARCHAR2      -- Input parameter for the filename
) AS

--ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';  -- tausender-trenner, dezimal-trenner (Deutsch)

-- Variables to store extracted data
 --   l_filename            VARCHAR2(255);
    l_invoice_id          VARCHAR2(20);
    l_issue_date          VARCHAR2(10); --DATE;
    l_note_content        VARCHAR2(2000);
    l_note_subject_code   VARCHAR2(50);
    l_note_content_code   VARCHAR2(100);
    l_buyer_id            VARCHAR2(20);
    l_buyer_reference     VARCHAR2(50);
    l_buyer_name          VARCHAR2(255);
    l_buyer_contact       VARCHAR2(255);
    l_buyer_address       VARCHAR2(255);
    l_buyer_postcode      VARCHAR2(100);
    l_buyer_city          VARCHAR2(100);
    l_buyer_country       VARCHAR2(20);
    l_buyer_email         VARCHAR2(255);
    l_seller_name         VARCHAR2(255);
    l_seller_id           VARCHAR2(100);
    l_seller_contact      VARCHAR2(255);
    l_seller_address      VARCHAR2(400);
    l_seller_postcode     VARCHAR2(50);
    l_seller_city         VARCHAR2(255);
    l_seller_email        VARCHAR2(255);
    l_seller_country      VARCHAR2(20);
    l_seller_tax_id_fc      varchar2(50);
    l_seller_tax_scheme_fc  varchar2(50);
    l_seller_tax_id_va      varchar2(50); 
    l_seller_tax_scheme_va  varchar2(50);
    l_payment_reference     varchar2(20);
    l_payment_means        VARCHAR2(100);
    l_document_currency   VARCHAR2(3);
    l_total_amount        VARCHAR2(20); --NUMBER;
    l_due_payable_amount  VARCHAR2(20); --NUMBER;
    l_billed_quantity     VARCHAR2(20); --NUMBER;
    l_quantity_unitcode   VARCHAR2(10);
    l_net_price           VARCHAR2(20); --NUMBER;
    l_line_id             VARCHAR2(50);
    l_product_name        VARCHAR2(255);
    l_product_description VARCHAR2(1000);
    l_line_total_amount   VARCHAR2(20); --NUMBER;
    l_charge_total_amount   VARCHAR2(20); --NUMBER;
    l_tax_rate            VARCHAR2(20); -- evtl. doch number ????
    l_tax_basis_total_amount     varchar2(20);  -- evtl. doch number ????
    l_payment_type_code        VARCHAR2(10);
    l_payment_information      VARCHAR2(255);
    l_iban_id                  VARCHAR2(50);
    l_account_name             VARCHAR2(255);
    l_bic_id                   VARCHAR2(50);


BEGIN

    IF xml_clob IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('XML CLOB is empty.');
        RETURN;
    END IF;

-- Extract invoice-level data using XMLTable using namespaces
SELECT xt.* 
INTO l_invoice_id, l_issue_date, l_buyer_reference, l_document_currency, l_total_amount, l_due_payable_amount,l_line_total_amount,l_charge_total_amount, l_tax_basis_total_amount, l_payment_type_code, l_payment_information ,l_iban_id, l_account_name,l_bic_id, 
l_seller_tax_id_fc,l_seller_tax_scheme_fc ,l_seller_tax_id_va,l_seller_tax_scheme_va, l_payment_reference, l_payment_means
FROM XMLTable(
    XMLNamespaces(
        'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100' AS "rsm",
        'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100' AS "ram",
        'urn:un:unece:uncefact:data:standard:QualifiedDataType:100' AS "qdt",
        'urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100' AS "udt"
    ),
    '/rsm:CrossIndustryInvoice[1]'  -- Select only the first occurrence
    PASSING XMLType(xml_clob)
    COLUMNS
        invoice_id          VARCHAR2(50)  PATH 'rsm:ExchangedDocument/ram:ID[1]',  -- Use [1] to select first node
        issue_date          VARCHAR2(8)   PATH 'rsm:ExchangedDocument/ram:IssueDateTime/udt:DateTimeString[1]',
        buyer_reference     VARCHAR2(50)  PATH 'rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeAgreement/ram:BuyerReference[1]',
        document_currency   VARCHAR2(3)   PATH 'rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:InvoiceCurrencyCode[1]',
        total_amount        NUMBER        PATH 'rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:GrandTotalAmount[1]',
        due_payable_amount  NUMBER        PATH 'rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:DuePayableAmount[1]',
--  New fields from MonetarySummation
        line_total_amount      NUMBER     PATH 'rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:LineTotalAmount[1]',
        charge_total_amount    NUMBER     PATH 'rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:ChargeTotalAmount[1]',
--  allowance_total_amount NUMBER   PATH 'rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:AllowanceTotalAmount[1]',
        tax_basis_total_amount NUMBER     PATH 'rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxBasisTotalAmount[1]',
--  New payment details
        payment_type_code     VARCHAR2(10)  PATH 'rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/ram:TypeCode[1]',
        payment_information   VARCHAR2(255) PATH 'rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/ram:Information[1]',
        iban_id               VARCHAR2(50)  PATH 'rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/ram:PayeePartyCreditorFinancialAccount/ram:IBANID[1]',
        account_name          VARCHAR2(255) PATH 'rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/ram:PayeePartyCreditorFinancialAccount/ram:AccountName[1]',
        bic_id                VARCHAR2(50)  PATH 'rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:SpecifiedTradeSettlementPaymentMeans/ram:PayeeSpecifiedCreditorFinancialInstitution/ram:BICID[1]',
        payment_ref           VARCHAR2(50)  PATH 'rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram:PaymentReference',
        payment_means         VARCHAR2(100) PATH 'rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement/ram::SpecifiedTradeSettlementPaymentMeans',
 -- Addi
 -- Adding tax registration IDs and schemes
        seller_tax_id_fc      VARCHAR2(50) PATH 'ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration[ram:ID/@schemeID="FC"]/ram:ID',
        seller_tax_scheme_fc  VARCHAR2(10) PATH 'ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration[ram:ID/@schemeID="FC"]/ram:ID/@schemeID',
        seller_tax_id_va      VARCHAR2(50) PATH 'ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration[ram:ID/@schemeID="VA"]/ram:ID',
        seller_tax_scheme_va  VARCHAR2(10) PATH 'ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration[ram:ID/@schemeID="VA"]/ram:ID/@schemeID'
) xt;

-- Convert the issue date to a DATE type
l_issue_date := TO_DATE(l_issue_date, 'YYYYMMDD');

    -- Log the extracted values
    DBMS_OUTPUT.PUT_LINE('Invoice ID: ' || l_invoice_id);
    DBMS_OUTPUT.PUT_LINE('Issue Date: ' || l_issue_date);
    DBMS_OUTPUT.PUT_LINE('Buyer Reference: ' || l_buyer_reference);
    DBMS_OUTPUT.PUT_LINE('Document Currency: ' || l_document_currency);
    DBMS_OUTPUT.PUT_LINE('Total Amount: ' || l_total_amount);
    DBMS_OUTPUT.PUT_LINE('Due Payable Amount: ' || l_due_payable_amount);

    -- Insert invoice-level data into X_ExchangedDocument
    INSERT INTO X_ExchangedDocument (ID, TypeCode, IssueDate, buyer_ref, doc_currency, total_amount, due_payable_amount, 
    line_total_amount, charge_total_amount, tax_basis_total_amount, notecontent, payment_type_code, payment_information, 
    iban_id, account_name, bic_id, seller_tax_id_fc,seller_tax_scheme_fc ,seller_tax_id_va,seller_tax_scheme_va, payment_reference, payment_means ) 

    VALUES (l_invoice_id, '380', l_issue_date, l_buyer_reference,l_document_currency, l_total_amount, l_due_payable_amount, 
    l_line_total_amount, l_charge_total_amount, l_tax_basis_total_amount, l_filename,l_payment_type_code, l_payment_information, 
    l_iban_id, l_seller_name, l_bic_id, l_seller_tax_id_fc,l_seller_tax_scheme_fc ,l_seller_tax_id_va,l_seller_tax_scheme_va,l_payment_reference, l_payment_means); 

--    DBMS_OUTPUT.PUT_LINE('Inserted ExchangedDocument record.');

--EXCEPTION
  --  WHEN DUP_VAL_ON_INDEX THEN
      -- Log the error or handle it, e.g., skip or update the existing record
  --    DBMS_OUTPUT.PUT_LINE('Duplicate invoice: ' || l_invoice_id);

  -- Now loop through all <ram:IncludedNote> entries
    FOR note IN (
        SELECT xt_notes.* 
        FROM XMLTable(
            XMLNamespaces(
                'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100' AS "rsm",
                'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100' AS "ram"
            ),
            '/rsm:CrossIndustryInvoice/rsm:ExchangedDocument/ram:IncludedNote'
            PASSING XMLType(xml_clob)
            COLUMNS
                content_code VARCHAR2(50)   PATH 'ram:ContentCode',
                content      VARCHAR2(2000) PATH 'ram:Content',
                subject_code VARCHAR2(50)   PATH 'ram:SubjectCode'
        ) xt_notes
    ) LOOP
        -- Log extracted values
        DBMS_OUTPUT.PUT_LINE('Content Code: ' || note.content_code);
        DBMS_OUTPUT.PUT_LINE('Content: ' || note.content);
        DBMS_OUTPUT.PUT_LINE('Subject Code: ' || note.subject_code);

        -- Insert the extracted data into the X_IncludedNotes table
        INSERT INTO X_INCLUDEDNOTES (CONTENTCODE, CONTENT, SUBJECTCODE,  TRANSACTION_FK)
                VALUES ( note.content_code, note.content, note.subject_code, l_invoice_id);
    END LOOP;

    -- Commit the transaction
    COMMIT;

    -- Extract seller and buyer information
    SELECT xt_seller.* INTO l_seller_name, l_seller_id, l_seller_contact, l_seller_email, l_seller_address, l_seller_postcode,l_seller_city, l_seller_country, 
    l_seller_tax_id_fc, l_seller_tax_scheme_fc , l_seller_tax_id_va , l_seller_tax_scheme_va,
    l_buyer_id, l_buyer_name, l_buyer_contact, l_buyer_email, l_buyer_address, l_buyer_postcode, l_buyer_city, l_buyer_country
    FROM XMLTable(
        XMLNamespaces(
            'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100' AS "rsm",
            'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100' AS "ram"
        ),
        '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction'

        PASSING XMLType(xml_clob)
        COLUMNS
            seller_name         VARCHAR2(255) PATH 'ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:Name',
            seller_id           VARCHAR2(100) PATH 'ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedLegalOrganization/ram:ID',          
            seller_contact      VARCHAR2(255) PATH 'ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:DefinedTradeContact/ram:PersonName',
            seller_email        VARCHAR2(255) PATH 'ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:DefinedTradeContact/ram:EmailURIUniversalCommunication/ram:URIID',
            seller_address      VARCHAR2(400) PATH 'ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:PostalTradeAddress/ram:LineOne',
            seller_postcode     VARCHAR2(400) PATH 'ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:PostalTradeAddress/ram:PostcodeCode',
            seller_city         VARCHAR2(400) PATH 'ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:PostalTradeAddress/ram:CityName',
            seller_country      VARCHAR2(10) PATH  'ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:PostalTradeAddress/ram:CountryID',

            seller_tax_id_fc      VARCHAR2(50) PATH 'ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration[ram:ID/@schemeID="FC"]/ram:ID',
            seller_tax_scheme_fc  VARCHAR2(10) PATH 'ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration[ram:ID/@schemeID="FC"]/ram:ID/@schemeID',
            seller_tax_id_va      VARCHAR2(50) PATH 'ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration[ram:ID/@schemeID="VA"]/ram:ID',
            seller_tax_scheme_va  VARCHAR2(10) PATH 'ram:ApplicableHeaderTradeAgreement/ram:SellerTradeParty/ram:SpecifiedTaxRegistration[ram:ID/@schemeID="VA"]/ram:ID/@schemeID',       

            buyer_id            VARCHAR2(20) PATH 'ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:Name',
            buyer_name          VARCHAR2(255) PATH 'ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:Name',
            buyer_contact       VARCHAR2(255) PATH 'ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:DefinedTradeContact/ram:PersonName',
            buyer_email         VARCHAR2(255) PATH 'ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:URIUniversalCommunication/ram:URIID',
            buyer_address       VARCHAR2(400) PATH 'ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:PostalTradeAddress/ram:LineOne',
            buyer_postcode      VARCHAR2(400) PATH 'ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:PostalTradeAddress/ram:PostcodeCode',
            buyer_city          VARCHAR2(400) PATH 'ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:PostalTradeAddress/ram:CityName',
            buyer_country       VARCHAR2(10) PATH  'ram:ApplicableHeaderTradeAgreement/ram:BuyerTradeParty/ram:PostalTradeAddress/ram:CountryID'



    ) xt_seller;

    -- Log seller and buyer information
    DBMS_OUTPUT.PUT_LINE('Seller Name: ' || l_seller_name);
    DBMS_OUTPUT.PUT_LINE('Buyer Name: ' || l_buyer_name);

    -- Insert seller information into X_SellerTradeParty
    INSERT INTO X_SellerTradeParty (Name, ContactPersonName,  AddressLine1, postcodecode, cityname, countryid,uri,  exchangeddocument_fk) -- Seller_id ist mit X_SELLERTRADEPARTY_SEQ.NEXTVAL per default vorbelegt
    VALUES (l_seller_name, l_seller_contact, l_seller_address,l_seller_postcode, l_seller_city,l_seller_country, l_seller_email, l_invoice_id);

    -- Insert buyer information into X_BuyerTradeParty
    INSERT INTO X_BuyerTradeParty (BUYER_ID, Name, ContactPersonName,  AddressLine1,postcodecode, cityname,countryid ,email, exchangeddocument_fk)
    VALUES (X_BUYERTRADEPARTY_SEQ.NEXTVAL, l_buyer_name, l_buyer_contact, l_buyer_address, l_buyer_postcode, l_buyer_city, l_buyer_country, l_buyer_email,l_invoice_id);

-- extract the item_lines:

 FOR li IN (
        SELECT xt_line_items.*
        FROM XMLTable(
            XMLNamespaces(
                'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100' AS "rsm",
                'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100' AS "ram"
            ),
            '/rsm:CrossIndustryInvoice/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem'
--            '/rsm:SupplyChainTradeTransaction/ram:IncludedSupplyChainTradeLineItem'

            PASSING XMLType(xml_clob)
            COLUMNS
                line_id            VARCHAR2(200)  PATH 'ram:AssociatedDocumentLineDocument/ram:LineID',
                product_name       VARCHAR2(200)  PATH 'ram:SpecifiedTradeProduct/ram:Name',
                net_price          number         PATH 'ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice/ram:ChargeAmount',
                billed_quantity    number         PATH 'ram:SpecifiedLineTradeDelivery/ram:BilledQuantity',
                quantity_unitcode VARCHAR2(10)    PATH 'ram:SpecifiedLineTradeDelivery/ram:BilledQuantity/@unitCode',
                tax_typecode      VARCHAR2(10)   PATH 'ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:TypeCode',
                tax_categorycode  VARCHAR2(3)   PATH 'ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:CategoryCode',
                tax_rate           VARCHAR2(20)   PATH 'ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax/ram:RateApplicablePercent',
                line_totalamount  number   PATH 'ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount'
        ) xt_line_items
    ) LOOP
        -- Log extracted values for each line item
        DBMS_OUTPUT.PUT_LINE('Line ID: ' || li.line_id);
        DBMS_OUTPUT.PUT_LINE('Product Name: ' || li.product_name);
        DBMS_OUTPUT.PUT_LINE('Net Price: ' || li.net_price);
        DBMS_OUTPUT.PUT_LINE('Billed Quantity: ' || li.billed_quantity || ' ' || li.quantity_unitcode);
        DBMS_OUTPUT.PUT_LINE('Tax Type Code: ' || li.tax_typecode);
        DBMS_OUTPUT.PUT_LINE('Tax Category Code: ' || li.tax_categorycode);
        DBMS_OUTPUT.PUT_LINE('Tax Rate: ' || li.tax_rate);
        DBMS_OUTPUT.PUT_LINE('Line Total Amount: ' || li.line_totalamount);

      -- Insert line item data into X_SupplyChainTradeLineItem
INSERT INTO X_SupplyChainTradeLineItem (
    LINEID,  PRODUCTNAME, NETPRICE, BILLEDQUANTITY, QUANTITYUNITCODE, TAXTYPECODE, TAXCATEGORYCODE, TAXRATE, LINETOTALAMOUNT,TRANSACTIONID)
VALUES (li.line_id, li.product_name, li.net_price, li.billed_quantity, li.quantity_unitcode, li.tax_typecode, li.tax_categorycode, li.tax_rate, li.line_totalamount, l_invoice_id);

end loop;

--   insert into vc_log (name, von_module, action_date, action_von, anzahl, comment)
--    values ( l_filename, 'Import_ZUGFeRD_Rechnung', sysdate, 'Bernhard','1', null );

   EXCEPTION
    WHEN OTHERS THEN
        -- Log the error or handle it
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
      --  insert into vc_log (name, von_module, action_date, action_von, anzahl, comment)
      --  values ('Error: ' || SQLERRM, 'Import_invoice_uncefact', sysdate, 'Bernhard', NULL, 'Line item error');
        RAISE; -- Re-raise the exception if you want to propagate it


END import_invoice_uncefact;