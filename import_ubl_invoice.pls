create or replace PROCEDURE import_ubl_invoice(xml_clob IN CLOB) IS
    -- Variables for storing extracted data
    l_invoice_id            VARCHAR2(20);
    l_issue_date            DATE;
    l_due_date              DATE;
    l_invoice_type_code     VARCHAR2(10);
    l_document_currency     VARCHAR2(3);
    l_buyer_reference       VARCHAR2(50);
    l_total_payable_amount  number;
    l_line_extension_amount number;
    l_iban                  varchar2(100);

    -- Supplier details
    l_supplier_name         VARCHAR2(100);
    l_supplier_id           VARCHAR2(255);
    l_supplier_company_id   VARCHAR2(50);
    l_supplier_street       VARCHAR2(100);
    l_supplier_city         VARCHAR2(50);
    l_supplier_postal_zone  VARCHAR2(20);
    l_supplier_country_code VARCHAR2(2);
    l_supplier_contact_name VARCHAR2(50);
    l_supplier_contact_phone VARCHAR2(20);
    l_supplier_contact_email VARCHAR2(100);

    -- Customer details
    l_customer_name         VARCHAR2(100);
    l_customer_id           NUMBER;
    l_customer_company_id   VARCHAR2(50);
    l_customer_street       VARCHAR2(100);
    l_customer_city         VARCHAR2(50);
    l_customer_postal_zone  VARCHAR2(20);
    l_customer_country_code VARCHAR2(2);

    -- variables for constraint uq_invoice_supplier UNIQUE (supplier_id, invoice_id) to ensure uniqueness of invoice;
    v_supplier_id   VARCHAR2(255);
    v_invoice_id    VARCHAR2(255); 

BEGIN
   -- Extract the supplier ID from the XML using XMLTable or XMLQuery
   SELECT x.supplier_id
     INTO v_supplier_id
     FROM XMLTable(
        XMLNamespaces(
         'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2' AS "ubl",
         'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2' AS "cac",
         'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2' AS "cbc"
       ),
--       '/ubl:Invoice/cac:AccountingSupplierParty/cbc:EndpointID'
     '/ubl:Invoice/cac:AccountingSupplierParty/cac:Party/cbc:EndpointID'

       PASSING XMLTYPE(xml_clob)
       COLUMNS supplier_id VARCHAR2(255) PATH 'text()'
   ) x;

/**
<cac:AccountingSupplierParty>
<cac:Party>
<cbc:EndpointID schemeID="9918">DE16520503531004885412</cbc:EndpointID>
<cac:PostalAddress>
<cbc:StreetName>Teichstr. 15</cbc:StreetName>
<cbc:CityName>Berlin</cbc:CityName>
<cbc:PostalZone>10232</cbc:PostalZone>
<cac:Country>
<cbc:IdentificationCode>DE</cbc:IdentificationCode>
</cac:Country>
</cac:PostalAddress>
<cac:PartyTaxScheme>
<cbc:CompanyID>279247134</cbc:CompanyID>
<cac:TaxScheme>
<cbc:ID>FC</cbc:ID>
</cac:TaxScheme>
</cac:PartyTaxScheme>
<cac:PartyLegalEntity>
<cbc:RegistrationName>PC Service GmbH</cbc:RegistrationName>
<cbc:CompanyID>279247134</cbc:CompanyID>
</cac:PartyLegalEntity>
<cac:Contact>
<cbc:Name>Max Siebert</cbc:Name>
<cbc:Telephone>0312424323</cbc:Telephone>
<cbc:ElectronicMail>max.siebert@pc-service-berlin.de</cbc:ElectronicMail>
</cac:Contact>
</cac:Party>
</cac:AccountingSupplierParty>

**/

   -- Extract the invoice ID from the XML
   -- Extract the first invoice ID from the XML
SELECT x.invoice_id
INTO v_invoice_id
FROM XMLTable(
    XMLNamespaces(
        'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2' AS "ubl",
        'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2' AS "cac",
        'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2' AS "cbc"
    ),
    '/ubl:Invoice/cbc:ID[fn:position() = 1]' -- Use fn:position() to select the first element explicitly
    PASSING XMLTYPE(xml_clob)
    COLUMNS invoice_id VARCHAR2(255) PATH 'text()'
) x;

    -- Extract invoice-level data using XMLTable with XMLNamespaces
    SELECT xt.* INTO l_invoice_id, l_issue_date, l_due_date, l_invoice_type_code, l_document_currency, l_buyer_reference, l_total_payable_amount,l_line_extension_amount,l_iban
    FROM XMLTable(
        XMLNamespaces(
            'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2' AS "ubl",
            'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2' AS "cac",
            'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2' AS "cbc"
        ),
        '/ubl:Invoice'
        PASSING XMLType(xml_clob)
        COLUMNS
            invoice_id            VARCHAR2(20) PATH 'cbc:ID',
            issue_date            DATE         PATH 'cbc:IssueDate',
            due_date              DATE         PATH 'cbc:DueDate',
            invoice_type_code     VARCHAR2(10) PATH 'cbc:InvoiceTypeCode',
            document_currency     VARCHAR2(3)  PATH 'cbc:DocumentCurrencyCode',
            buyer_reference       VARCHAR2(50) PATH 'cbc:BuyerReference',
            total_payable_amount  NUMBER       PATH 'cac:LegalMonetaryTotal/cbc:PayableAmount',
            line_extension_amount NUMBER       PATH 'cac:LegalMonetaryTotal/cbc:LineExtensionAmount',
            iban                  varchar2(30) PATH 'cac:PaymentMeans/cac:PayeeFinancialAccount/cbc:ID'  

-- <cac:PaymentMeans>
-- <cbc:PaymentMeansCode>42</cbc:PaymentMeansCode>
-- <cac:PayeeFinancialAccount>
-- <cbc:ID>DE13520503531004885466</cbc:ID>
-- <cbc:Name>Viktor Settel</cbc:Name>
-- <cac:FinancialInstitutionBranch>
-- <cbc:ID>HELADEF1KAS</cbc:ID>
-- </cac:FinancialInstitutionBranch>
-- </cac:PayeeFinancialAccount>
--</cac:PaymentMeans>
           ) xt;

    -- Extract supplier details
    SELECT xt.* INTO l_supplier_name, l_supplier_company_id, l_supplier_street, l_supplier_city, l_supplier_postal_zone, 
                      l_supplier_country_code, l_supplier_contact_name, l_supplier_contact_phone, l_supplier_contact_email
    FROM XMLTable(
        XMLNamespaces(
            'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2' AS "ubl",
            'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2' AS "cac",
            'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2' AS "cbc"
        ),
        '/ubl:Invoice/cac:AccountingSupplierParty/cac:Party'
        PASSING XMLType(xml_clob)
        COLUMNS
            supplier_name         VARCHAR2(100) PATH 'cac:PartyLegalEntity/cbc:RegistrationName',
            supplier_company_id   VARCHAR2(50)  PATH 'cac:PartyLegalEntity/cbc:CompanyID',
            supplier_street       VARCHAR2(100) PATH 'cac:PostalAddress/cbc:StreetName',
            supplier_city         VARCHAR2(50)  PATH 'cac:PostalAddress/cbc:CityName',
            supplier_postal_zone  VARCHAR2(20)  PATH 'cac:PostalAddress/cbc:PostalZone',
            supplier_country_code VARCHAR2(2)   PATH 'cac:PostalAddress/cac:Country/cbc:IdentificationCode',
            supplier_contact_name VARCHAR2(50)  PATH 'cac:Contact/cbc:Name',
            supplier_contact_phone VARCHAR2(20) PATH 'cac:Contact/cbc:Telephone',
            supplier_contact_email VARCHAR2(100) PATH 'cac:Contact/cbc:ElectronicMail'
    ) xt;

    -- Insert supplier data into SUPPLIER table, returning supplier_id
    INSERT INTO SUPPLIERS (company_name, company_id, street_name, city_name, postal_zone, country_code, contact_name, contact_phone, contact_email)
    VALUES (l_supplier_name, l_supplier_company_id, l_supplier_street, l_supplier_city, l_supplier_postal_zone, l_supplier_country_code,
            l_supplier_contact_name, l_supplier_contact_phone, l_supplier_contact_email)
    RETURNING supplier_id INTO l_supplier_id;

    -- Extract customer details
    SELECT xt.* INTO l_customer_name, l_customer_company_id, l_customer_street, l_customer_city, l_customer_postal_zone, l_customer_country_code
    FROM XMLTable(
        XMLNamespaces(
            'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2' AS "ubl",
            'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2' AS "cac",
            'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2' AS "cbc"
        ),
        '/ubl:Invoice/cac:AccountingCustomerParty/cac:Party'
        PASSING XMLType(xml_clob)
        COLUMNS
            customer_name         VARCHAR2(100) PATH 'cac:PartyLegalEntity/cbc:RegistrationName',
            customer_company_id   VARCHAR2(50)  PATH 'cac:PartyLegalEntity/cbc:CompanyID',
            customer_street       VARCHAR2(100) PATH 'cac:PostalAddress/cbc:StreetName',
            customer_city         VARCHAR2(50)  PATH 'cac:PostalAddress/cbc:CityName',
            customer_postal_zone  VARCHAR2(20)  PATH 'cac:PostalAddress/cbc:PostalZone',
            customer_country_code VARCHAR2(2)   PATH 'cac:PostalAddress/cac:Country/cbc:IdentificationCode'
    ) xt;

    -- Insert customer data into CUSTOMER table, returning customer_id
    INSERT INTO CUSTOMER (company_name, company_id, street_name, city_name, postal_zone, country_code)
    VALUES (l_customer_name, l_customer_company_id, l_customer_street, l_customer_city, l_customer_postal_zone, l_customer_country_code)
    RETURNING customer_id INTO l_customer_id;

    -- Insert data into INVOICE table
    INSERT INTO INVOICE (invoice_id, issue_date, due_date, document_currency_code, buyer_reference, supplier_id, customer_id, total_payable_amount,line_extension_amount, iban)
    VALUES (v_invoice_id, l_issue_date, l_due_date,  l_document_currency, l_buyer_reference, v_supplier_id, l_customer_id, l_total_payable_amount, l_line_extension_amount, l_iban);
-- INSERT INTO INVOICE (invoice_id, issue_date, due_date, document_currency_code, buyer_reference, supplier_id, customer_id)
--    VALUES (l_invoice_id, l_issue_date, l_due_date,  l_document_currency, l_buyer_reference, l_supplier_id, l_customer_id);

    -- Process and insert line items (InvoiceLine)
    FOR rec IN (
        SELECT xt.*
        FROM XMLTable(
            XMLNamespaces(
                'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2' AS "ubl",
                'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2' AS "cac",
                'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2' AS "cbc"
            ),
            '/ubl:Invoice/cac:InvoiceLine'
            PASSING XMLType(xml_clob)
            COLUMNS
                line_id                NUMBER(10)    PATH 'cbc:ID',
                invoiced_quantity      NUMBER        PATH 'cbc:InvoicedQuantity',
                unit_code              VARCHAR2(10)  PATH 'cbc:InvoicedQuantity/@unitCode',
                line_extension_amount  NUMBER        PATH 'cbc:LineExtensionAmount',
                item_name              VARCHAR2(100) PATH 'cac:Item/cbc:Name',
                price_amount           NUMBER        PATH 'cac:Price/cbc:PriceAmount',
                tax_percent            NUMBER        PATH 'cac:Item/cac:ClassifiedTaxCategory/cbc:Percent'
        ) xt
    ) LOOP
        -- Insert line item data
        INSERT INTO INVOICE_LINE_ITEMS (invoice_id, line_number, invoiced_quantity, unit_code, line_extension_amount, item_name, price_amount, tax_percent)
        VALUES (l_invoice_id, rec.line_id, rec.invoiced_quantity, rec.unit_code, rec.line_extension_amount, rec.item_name, rec.price_amount, rec.tax_percent);
    END LOOP;

    -- Commit the transaction
    COMMIT;
 -- Log successful ID extraction
    DBMS_OUTPUT.PUT_LINE('Extracted Invoice ID: ' || v_invoice_id);

EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Multiple Invoice IDs found.');
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No Invoice ID found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        RAISE;

END import_ubl_invoice;