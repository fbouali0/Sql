-- Delete existing printer with same printernum
DELETE FROM sm_printer
WHERE printernum = 'MOB_PRINTER';

-- Get the max sm_printerid
DECLARE @max_id INT = 0;

SELECT @max_id = ISNULL(MAX(sm_printerid), 0)
FROM sm_printer;

-- Restart the sequence
DECLARE @sql NVARCHAR(MAX);

SET @sql = 'ALTER SEQUENCE SM_PRINTERSEQ RESTART WITH ' + CAST(@max_id + 1 AS NVARCHAR);

EXEC(@sql);

-- Insert new record
INSERT INTO sm_printer (
    sm_printerid, description, ipaddress, orgid, port,
    printernum, siteid, hasld, langcode,
    printer_connect, name, sm_appclienthost
)
VALUES (
    NEXT VALUE FOR SM_PRINTERSEQ,
    'Mobile app printer',
    '10.1.10.115',
    'EAGLENA',
    9100,
    'MOB_PRINTER',
    'SMTK',
    0,
    'EN',
    'Ethernet',
    NULL,
    'https://labelprint.smartech.local:8080'
);