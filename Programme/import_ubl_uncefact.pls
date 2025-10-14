create or replace PROCEDURE import_ubl_uncefact(xml_clob CLOB) AS
    l_root_element VARCHAR2(100);  -- To store the root element name
    l_namespace    VARCHAR2(200);  -- To store the root namespace URI
BEGIN
    -- Step 1: Extract root element using XMLQuery and cast it to VARCHAR2
    BEGIN
        SELECT XMLCast(
                  XMLQuery('fn:local-name(/*)[1]'  -- Limit to the first root element
 --                  XMLQuery('fn:local-name(/*)'
                            PASSING XMLType(xml_clob)
                            RETURNING CONTENT)
                   AS VARCHAR2(100)
               )
        INTO l_root_element
        FROM dual;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error extracting root element: ' || SQLERRM);
            RAISE_APPLICATION_ERROR(-20002, 'Error extracting root element');
    END;

    -- Step 2: Extract root namespace using XMLQuery
    BEGIN
        SELECT XMLCast(
            XMLQuery('fn:namespace-uri(/*)[1]'  -- Limit to the first namespace element
--                   XMLQuery('fn:namespace-uri(/*)'
                            PASSING XMLType(xml_clob)
                            RETURNING CONTENT)
                   AS VARCHAR2(100)
               )
        INTO l_namespace
        FROM dual;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error extracting namespace: ' || SQLERRM);
            RAISE_APPLICATION_ERROR(-20003, 'Error extracting namespace');
    END;

    -- Debugging output to understand what root element and namespace are being extracted
    DBMS_OUTPUT.PUT_LINE('Root Element: ' || l_root_element);
    DBMS_OUTPUT.PUT_LINE('Namespace: ' || l_namespace);

    -- Step 3: Determine the XML format based on the root element and namespace
    IF l_root_element = 'Invoice' 
       AND l_namespace = 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2' THEN
        -- It's a UBL invoice, call the UBL procedure
        DBMS_OUTPUT.PUT_LINE('UBL Format detected, calling import_invoice...');
        import_ubl_invoice(xml_clob);

    ELSIF l_root_element = 'CrossIndustryInvoice' 
          AND l_namespace = 'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100' THEN
        -- It's a UN/CEFACT invoice, call the UN/CEFACT procedure
        DBMS_OUTPUT.PUT_LINE('UN/CEFACT Format detected, calling import_uncefact...');
        import_invoice_uncefact(xml_clob);

    ELSE
        -- Unrecognized format
        DBMS_OUTPUT.PUT_LINE('Error: Unknown invoice format.');
        RAISE_APPLICATION_ERROR(-20001, 'Unsupported XML format: ' || l_root_element || ', ' || l_namespace);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        -- Capture all other exceptions and output the error message
        DBMS_OUTPUT.PUT_LINE('Error processing invoice: ' || SQLERRM);
        RAISE;
END import_ubl_uncefact;