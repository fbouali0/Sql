
-- Restart the QUERYSEQ sequence to ensure it starts from the correct value
BEGIN
  DECLARE max_id INTEGER DEFAULT 0;

  -- Get the max QUERYID
  SELECT COALESCE(MAX(QUERYID), 0)
  INTO max_id
  FROM QUERY;

  -- Restart the sequence with max_id + 1
  EXECUTE IMMEDIATE 'ALTER SEQUENCE QUERYSEQ RESTART WITH ' || max_id;
END

-- Delete if existing queries to avoid duplicates
DELETE FROM QUERY WHERE clausename IN ('MY CPM meters shipment from LAB','MY RDC Obsolete meters shipment from CNC','MY PO TO BE RECEIVED','MY RDC meters shipment from RDC','MY RDC Serviceable meters shipment from CNC','MY CNC meters shipment from RDC','MY RDC Scrappable meters shipment from CNC','MY RDC meters shipment from CPM','MY RDC meters shipment from LAB','My RDC SAP RESERVATION TO RDC','My RDC SAP RESERVATION TO CNC','My RDC SAP RESERVATION TO CPM','My RDC SAP RESERVATION TO PROJECT','MY CNC meters shipment from CNC','MY CNC meters shipment from LAB','My CNC SAP RESERVATION TO RDC','My CNC SAP RESERVATION TO CNC','My CNC SAP RESERVATION TO TSU','My CNC SAP RESERVATION TO PROJECT','MY CPM meters shipment from RDC','MY LAB meters shipment from RDC','MY LAB meters shipment from CNC','MY LAB meters shipment from CPM');


-- Insert new queries for meters shipment and SAP reservations
INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_METERSRECEIPTS', 'MY PO TO BE RECEIVED', 'Z4837655', 'Material to be received in My RDC from supplier', 'historyflag = 0  
  and status = ''APPR''
  and n_po_type!=''SAPRESERVATION''
  and receipts != ''COMPLETE'' 
  and exists (
    select 1 
    from poline 
    where poline.ponum = po.ponum 
      and poline.siteid = po.siteid 
      and poline.revisionnum = po.revisionnum
      and exists (
        select 1
        from locations
        where location in (
          select n_rdcstoreroom
          from n_relatedstore
          where n_cncstoreroom is null 
           and laborid in (
            select laborid 
            from labor 
            where personid in (
              select personid 
              from maxuser 
              where userid = :user 
            )
          )
        )
        and (exists( select 1 from n_receivingstore where  n_receivingstore.locationsid = locations.locationsid and n_receivingstore.storeroom = poline.storeloc)
        or 
        (
           poline.storeloc in (location, n_aggregatedstore)
        )
        )
      )
  )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_METERS_SHIPMENTRECEIPTS', 'MY CNC meters shipment from CNC', 'Z4837655', 'Shipment of  Meters from another CNC to my CNC', 'exists(select 1 from invuse where invuse.invusenum = shipment.invusenum and invuse.siteid = shipment.siteid and invuse.receipts != ''COMPLETE'' and INVUSE.STATUS != ''CANCELLED'' )
  and exists (
    select 1 
    from shipmentline 
    where shipmentline.shipmentnum = shipment.shipmentnum 
      and shipmentline.siteid = shipment.siteid 
      and exists(select 1 from invuselinesplit where invuselinesplit.invuselinesplitid = shipmentline.invuselinesplitid and exists(select 1 from asset where invuselinesplit.rotassetnum = asset.assetnum and invuselinesplit.siteid = asset.siteid  ))
      and exists(
          select 1
          from n_relatedstore
          where laborid in (
            select laborid 
            from labor 
            where n_type=''CNC'' and personid in (
              select personid 
              from maxuser 
              where userid = :user
            )
          )  and exists(select 1 from invuseline where invuseline.invuselineid = shipmentline.invuselineid and invuseline.n_sap_to_sloc <''5000'' and invuseline.n_sap_from_sloc <''5000'' and invuseline.n_sap_to_plant=n_rdcstoreroom and invuseline.n_sap_to_sloc=n_cncstoreroom)
        )
      )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_METERS_SHIPMENTRECEIPTS', 'MY CNC meters shipment from LAB', 'Z4837655', 'Shipment of  Meters from LAB to my CNC', 'exists(select 1 from invuse where invuse.invusenum = shipment.invusenum and invuse.siteid = shipment.siteid and invuse.receipts != ''COMPLETE'' and INVUSE.STATUS != ''CANCELLED'' )
  and exists (
    select 1 
    from shipmentline 
    where shipmentline.shipmentnum = shipment.shipmentnum 
      and shipmentline.siteid = shipment.siteid 
      and exists(select 1 from invuseline where invuseline.invuselineid = shipmentline.invuselineid and invuseline.n_sap_to_sloc< ''5000''
      and exists(
          select 1
          from n_relatedstore
          where n_relatedstore.N_CNCSTOREROOM = invuseline.N_SAP_TO_SLOC and exists(
            select 1 
            from labor 
            where n_type=''CNC'' and labor.laborid=n_relatedstore.laborid and  exists (
              select 1 
              from maxuser 
              where labor.personid=maxuser.personid and  userid =:user
            )
          )
        )
        AND invuseline.FROMSTORELOC IN (SELECT location FROM LOCATIONS WHERE n_TYPE = ''LAB'')
        )
      )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_METERS_SHIPMENTRECEIPTS', 'MY CNC meters shipment from RDC', 'Z4837655', 'Shipment of  Meters from RDC to my CNC', 'exists(select 1 from invuse where invuse.invusenum = shipment.invusenum and invuse.siteid = shipment.siteid and invuse.receipts != ''COMPLETE'' and INVUSE.STATUS != ''CANCELLED'' )
  and exists (
    select 1 
    from shipmentline 
    where shipmentline.shipmentnum = shipment.shipmentnum 
      and shipmentline.siteid = shipment.siteid 
      and exists(select 1 from invuselinesplit where invuselinesplit.invuselinesplitid = shipmentline.invuselinesplitid and exists(select 1 from asset where invuselinesplit.rotassetnum = asset.assetnum and invuselinesplit.siteid = asset.siteid  ))
      and exists(
          select 1
          from n_relatedstore
          where laborid in (
            select laborid 
            from labor 
            where n_type=''CNC'' and personid in (
              select personid 
              from maxuser 
              where userid = :user 
            )
          )  and exists(select 1 from invuseline where invuseline.invuselineid = shipmentline.invuselineid and invuseline.n_sap_to_sloc <''5000'' and invuseline.n_sap_from_sloc >=''5000'' and invuseline.n_sap_to_plant=n_rdcstoreroom and invuseline.n_sap_to_sloc=n_cncstoreroom)
        )
      )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_METERS_SHIPMENTRECEIPTS', 'MY CPM meters shipment from RDC', 'Z4837655', 'Shipment of  Meters from RDC to my CPM', 'exists(select 1 from invuse where invuse.invusenum = shipment.invusenum and invuse.siteid = shipment.siteid and invuse.receipts != ''COMPLETE'' and INVUSE.STATUS != ''CANCELLED'')

  and exists (

    select 1 

    from shipmentline 

    where shipmentline.shipmentnum = shipment.shipmentnum 

      and shipmentline.siteid = shipment.siteid 

      and exists(select 1 from invuseline where invuseline.invuselineid = shipmentline.invuselineid and invuseline.n_sap_from_sloc >= ''5000'')

      and exists(

          select 1

          from n_relatedstore

          where n_relatedstore.n_cpm_storeroom=shipmentline.tostoreloc and exists(

            select 1 

            from labor 

            where n_type=''CPM'' and labor.laborid=n_relatedstore.laborid and  exists (

              select 1 

              from maxuser 

              where labor.personid=maxuser.personid and  userid = :user

            )

          )

        )

      )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_METERS_SHIPMENTRECEIPTS', 'MY LAB meters shipment from CNC', 'Z4837655', 'Shipment of  Meters from CNC to my LAB', 'exists(select 1 from invuse where invuse.invusenum = shipment.invusenum and invuse.siteid = shipment.siteid and invuse.receipts != ''COMPLETE'' and INVUSE.STATUS != ''CANCELLED'')

  and exists (

    select 1 

    from shipmentline 

    where shipmentline.shipmentnum = shipment.shipmentnum 

      and shipmentline.siteid = shipment.siteid 

      and exists(select 1 from invuseline where invuseline.invuselineid = shipmentline.invuselineid and invuseline.n_sap_from_sloc < ''5000'')

      and exists(

          select 1

          from n_relatedstore

          where n_relatedstore.n_lab_storeroom=shipmentline.tostoreloc and exists(

            select 1 

            from labor 

            where n_type=''LAB'' and labor.laborid=n_relatedstore.laborid and  exists (

              select 1 

              from maxuser 

              where labor.personid=maxuser.personid and  userid =:USER 

            )

          )

        )

      )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_METERS_SHIPMENTRECEIPTS', 'MY LAB meters shipment from CPM', 'Z4837655', 'Shipment of  Meters from CPM to my LAB', 'exists(select 1 from invuse where invuse.invusenum = shipment.invusenum and invuse.siteid = shipment.siteid and invuse.receipts != ''COMPLETE'' and INVUSE.STATUS != ''CANCELLED'' )

  and exists (

    select 1 

    from shipmentline 

    where shipmentline.shipmentnum = shipment.shipmentnum 

      and shipmentline.siteid = shipment.siteid 

      and exists(select 1 from invuseline where invuseline.invuselineid = shipmentline.invuselineid and invuseline.fromstoreloc in (select location from locations where n_type=''CPM''))

      and exists(

          select 1

          from n_relatedstore

          where n_relatedstore.n_lab_storeroom=shipmentline.tostoreloc and exists(

            select 1 

            from labor 

            where n_type=''lab'' and labor.laborid=n_relatedstore.laborid and  exists (

              select 1 

              from maxuser 

              where labor.personid=maxuser.personid and  userid = :user

            )

          )

        )

      )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_METERS_SHIPMENTRECEIPTS', 'MY LAB meters shipment from RDC', 'Z4837655', 'Shipment of  Meters from RDC to my LAB', 'exists(select 1 from invuse where invuse.invusenum = shipment.invusenum and invuse.siteid = shipment.siteid and invuse.receipts != ''COMPLETE'' and INVUSE.STATUS != ''CANCELLED'')

  and exists (

    select 1 

    from shipmentline 

    where shipmentline.shipmentnum = shipment.shipmentnum 

      and shipmentline.siteid = shipment.siteid 

      and exists(select 1 from invuseline where invuseline.invuselineid = shipmentline.invuselineid and invuseline.n_sap_from_sloc >= ''5000'')

      and exists(

          select 1

          from n_relatedstore

          where n_relatedstore.N_lab_STOREROOM=shipmentline.tostoreloc and exists(

            select 1 

            from labor 

            where n_type=''LAB'' and labor.laborid=n_relatedstore.laborid and  exists (

              select 1 

              from maxuser 

              where labor.personid=maxuser.personid and  userid =:user

            )

          )

        )

      )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_METERS_SHIPMENTRECEIPTS', 'MY RDC Obsolete meters shipment from CNC', 'Z4837655', 'Shipment of  Obsolete Meters from CNC to my RDC', 'exists(select 1 from invuse where invuse.invusenum = shipment.invusenum and invuse.siteid = shipment.siteid and invuse.receipts != ''COMPLETE'' and INVUSE.STATUS != ''CANCELLED'' )
  and exists (
    select 1 
    from shipmentline 
    where shipmentline.shipmentnum = shipment.shipmentnum 
      and shipmentline.siteid = shipment.siteid 
      and exists(select 1 from invuselinesplit where invuselinesplit.invuselinesplitid = shipmentline.invuselinesplitid and exists(select 1 from asset where invuselinesplit.rotassetnum = asset.assetnum and invuselinesplit.siteid = asset.siteid and asset.n_meteractionstatus = ''OBSOLETE'' ))
      and exists(
          select 1
          from n_relatedstore
          where laborid in (
            select laborid 
            from labor 
            where n_type=''RDC'' and personid in (
              select personid 
              from maxuser 
              where userid = :user 
            )
          )  and exists(select 1 from invuseline where invuseline.invuselineid = shipmentline.invuselineid and invuseline.n_sap_to_sloc >=''5000'' and invuseline.n_sap_from_sloc <''5000'' and invuseline.n_sap_to_plant=n_rdcstoreroom)
        )
      )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_METERS_SHIPMENTRECEIPTS', 'MY RDC Scrappable meters shipment from CNC', 'Z4837655', 'Shipment of  Scrappable Meters from CNC to my RDC', 'exists(select 1 from invuse where invuse.invusenum = shipment.invusenum and invuse.siteid = shipment.siteid and invuse.receipts != ''COMPLETE'' and INVUSE.STATUS != ''CANCELLED'' )
  and exists (
    select 1 
    from shipmentline 
    where shipmentline.shipmentnum = shipment.shipmentnum 
      and shipmentline.siteid = shipment.siteid 
      and exists(select 1 from invuselinesplit where invuselinesplit.invuselinesplitid = shipmentline.invuselinesplitid and exists(select 1 from asset where invuselinesplit.rotassetnum = asset.assetnum and invuselinesplit.siteid = asset.siteid and asset.n_meteractionstatus = ''SCRAPPABLE'' ))
      and exists(
          select 1
          from n_relatedstore
          where laborid in (
            select laborid 
            from labor 
            where n_type=''RDC'' and personid in (
              select personid 
              from maxuser 
              where userid = :user
            )
          )  and exists(select 1 from invuseline where invuseline.invuselineid = shipmentline.invuselineid and invuseline.n_sap_to_sloc >=''5000'' and invuseline.n_sap_from_sloc <''5000'' and invuseline.n_sap_to_plant=n_rdcstoreroom)
        )
      )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_METERS_SHIPMENTRECEIPTS', 'MY RDC Serviceable meters shipment from CNC', 'Z4837655', 'Shipment of  Serviceable Meters from CNC to my RDC', 'exists(select 1 from invuse where invuse.invusenum = shipment.invusenum and invuse.siteid = shipment.siteid and invuse.receipts != ''COMPLETE'' and INVUSE.STATUS != ''CANCELLED'')
  and exists (
    select 1 
    from shipmentline 
    where shipmentline.shipmentnum = shipment.shipmentnum 
      and shipmentline.siteid = shipment.siteid 
      and exists(select 1 from invuselinesplit where invuselinesplit.invuselinesplitid = shipmentline.invuselinesplitid and exists(select 1 from asset where invuselinesplit.rotassetnum = asset.assetnum and invuselinesplit.siteid = asset.siteid ))
      and exists(
          select 1
          from n_relatedstore
          where laborid in (
            select laborid 
            from labor 
            where n_type=''RDC'' and personid in (
              select personid 
              from maxuser 
              where userid = :user
            )
          )  and exists(select 1 from invuseline where invuseline.invuselineid = shipmentline.invuselineid and invuseline.n_sap_to_sloc >=''5000'' and invuseline.n_sap_from_sloc <''5000'' and invuseline.n_sap_to_plant=n_rdcstoreroom)
        )
      )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_METERS_SHIPMENTRECEIPTS', 'MY RDC meters shipment from CPM', 'Z4837655', 'Shipment of Meters from CPM to my RDC', 'exists(select 1 from invuse where invuse.invusenum = shipment.invusenum and invuse.siteid = shipment.siteid and invuse.receipts != ''COMPLETE'' and INVUSE.STATUS != ''CANCELLED'')
  and exists (
    select 1 
    from shipmentline 
    where shipmentline.shipmentnum = shipment.shipmentnum 
      and shipmentline.siteid = shipment.siteid 
      and exists(select 1 from invuseline where invuseline.invuselineid = shipmentline.invuselineid and invuseline.n_sap_to_sloc >= ''5000''
      and exists(
          select 1
          from n_relatedstore
          where n_relatedstore.N_RDCSTOREROOM = invuseline.N_SAP_TO_PLANT and exists(
            select 1 
            from labor 
            where n_type=''RDC'' and labor.laborid=n_relatedstore.laborid and  exists (
              select 1 
              from maxuser 
              where labor.personid=maxuser.personid and  userid =:user
            )
          )
        )
        AND invuseline.FROMSTORELOC IN (SELECT location FROM LOCATIONS WHERE n_TYPE = ''CPM'')
        )
      )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_METERS_SHIPMENTRECEIPTS', 'MY RDC meters shipment from LAB', 'Z4837655', 'Shipment of  Meters from LAB to my RDC', 'exists(select 1 from invuse where invuse.invusenum = shipment.invusenum and invuse.siteid = shipment.siteid and invuse.receipts != ''COMPLETE'' and INVUSE.STATUS != ''CANCELLED'')
  and exists (
    select 1 
    from shipmentline 
    where shipmentline.shipmentnum = shipment.shipmentnum 
      and shipmentline.siteid = shipment.siteid 
      and exists(select 1 from invuseline where invuseline.invuselineid = shipmentline.invuselineid and invuseline.n_sap_to_sloc >= ''5000''
      and exists(
          select 1
          from n_relatedstore
          where n_relatedstore.N_RDCSTOREROOM = invuseline.N_SAP_TO_PLANT and exists(
            select 1 
            from labor 
            where n_type=''RDC'' and labor.laborid=n_relatedstore.laborid and  exists (
              select 1 
              from maxuser 
              where labor.personid=maxuser.personid and  userid =:user
            )
          )
        )
        AND invuseline.FROMSTORELOC IN (SELECT location FROM LOCATIONS WHERE n_TYPE = ''LAB'')
        )
      )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_METERS_SHIPMENTRECEIPTS', 'MY RDC meters shipment from RDC', 'Z4837655', 'Shipment of  Meters from another RDC to my RDC', 'exists(select 1 from invuse where invuse.invusenum = shipment.invusenum and invuse.siteid = shipment.siteid and invuse.receipts != ''COMPLETE'' and INVUSE.STATUS != ''CANCELLED'' )
  and exists (
    select 1 
    from shipmentline 
    where shipmentline.shipmentnum = shipment.shipmentnum 
      and shipmentline.siteid = shipment.siteid 
      and exists(select 1 from invuselinesplit where invuselinesplit.invuselinesplitid = shipmentline.invuselinesplitid and exists(select 1 from asset where invuselinesplit.rotassetnum = asset.assetnum and invuselinesplit.siteid = asset.siteid   ))
      and exists(
          select 1
          from n_relatedstore
          where laborid in (
            select laborid 
            from labor 
            where n_type=''RDC'' and personid in (
              select personid 
              from maxuser 
              where userid = :user
            )
          )  and exists(select 1 from invuseline where invuseline.invuselineid = shipmentline.invuselineid and invuseline.n_sap_to_sloc >=''5000'' and invuseline.n_sap_from_sloc >=''5000'' and invuseline.n_sap_to_plant=n_rdcstoreroom)
        )
      )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_SAPRESERV', 'My CNC SAP RESERVATION TO CNC', 'Z4837655', 'SAP Reservation from my CNC to another CNC', 'historyflag = 0 

 and po.n_sap_from_sloc <''5000''
  and n_po_type=''SAPRESERVATION''
  and  exists (
        select 1 
          from n_relatedstore
          where laborid in (
            select laborid 
            from labor 
            where n_type=''CNC'' and  personid in (
              select personid 
              from maxuser 
              where userid = :user 
            )
          )
          and po.n_sap_from_sloc = n_cncstoreroom 
          and po.n_sap_from_plant = n_rdcstoreroom
        )
     and  exists (
    select 1 
    from poline 
    where poline.ponum = po.ponum 
      and poline.siteid = po.siteid 
      and poline.revisionnum = po.revisionnum
      and poline.n_sap_to_sloc < ''5000'' AND poline.N_REMAININGQTY > 0
  )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_SAPRESERV', 'My CNC SAP RESERVATION TO PROJECT', 'Z4837655', 'SAP Reservation from my CNC to PROJECT', 'historyflag = 0

  and po.n_sap_from_sloc  < ''5000''
  and n_po_type=''SAPRESERVATION''
  and N_SAP_TRANSACTION_TYPE IN (''221'',''222'')
  and  exists (
        select 1 
          from n_relatedstore
          where laborid in (
            select laborid 
            from labor 
            where n_type=''CNC'' and personid in (
              select personid 
              from maxuser 
              where userid =:user
            )
          )
          and po.n_sap_from_plant = n_rdcstoreroom and  po.n_sap_from_sloc = n_cncstoreroom 
        )
     and  exists (
    select 1 
    from poline 
    where poline.ponum = po.ponum 
      and poline.siteid = po.siteid 
      and poline.revisionnum = po.revisionnum
      and poline.n_sap_wbs is not null  AND POLINE.N_SAP_CC IS NULL 
      AND POLINE.N_SAP_IO IS  NULL  AND poline.N_REMAININGQTY > 0 and (POLINE.N_IGNORERECEIPT=0 and POLINE.N_DELETED=0)
  )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_SAPRESERV', 'My CNC SAP RESERVATION TO RDC', 'Z4837655', 'SAP Reservation from my CNC to RDC', 'historyflag = 0 

 and po.n_sap_from_sloc  < ''5000''
  and n_po_type=''SAPRESERVATION''
  and  exists (
        select 1 
          from n_relatedstore
          where laborid in (
            select laborid 
            from labor 
            where n_type=''CNC'' and personid in (
              select personid 
              from maxuser 
              where userid = :user
            )
          )
          and po.n_sap_from_plant = n_rdcstoreroom and  po.n_sap_from_sloc = n_cncstoreroom
        )
     and  exists (
    select 1 
    from poline 
    where poline.ponum = po.ponum 
      and poline.siteid = po.siteid 
      and poline.revisionnum = po.revisionnum
      and poline.n_sap_to_sloc >=''5000'' AND poline.N_REMAININGQTY > 0
  )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_SAPRESERV', 'My CNC SAP RESERVATION TO TSU', 'Z4837655', 'SAP Reservation from my CNC to TSU/EPO', 'historyflag = 0 

  and po.n_sap_from_sloc  < ''5000''
  and po.n_po_type=''SAPRESERVATION''
  AND po.N_SAP_TRANSACTION_TYPE IN (''221'',''222'',''201'',''202'',''261'',''262'')
  and  exists (
        select 1 
          from n_relatedstore
          where laborid in (
            select laborid 
            from labor 
            where n_type=''CNC'' and personid in (
              select personid 
              from maxuser 
              where userid =:user
            )
          )
          and po.n_sap_from_plant = n_rdcstoreroom and  po.n_sap_from_sloc = n_cncstoreroom 
        )
     and  exists (
    select 1 
    from poline 
    where poline.ponum = po.ponum 
      and poline.siteid = po.siteid 
      and poline.revisionnum = po.revisionnum
      and (poline.n_sap_io  is not null or POLINE.N_SAP_WBS IS NOT NULL 
              OR POLINE.N_SAP_CC IS NOT NULL  ) 
      AND POLINE.N_SAP_TO_PLANT IS NULL 
      AND POLINE.N_SAP_TO_SLOC IS NULL
      AND poline.N_REMAININGQTY > 0
  )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_SAPRESERV', 'My RDC SAP RESERVATION TO CNC', 'Z4837655', 'SAP Reservation from my RDC to CNC', 'historyflag = 0

 and po.n_sap_from_sloc  >= ''5000''
  and n_po_type=''SAPRESERVATION''
  and  exists (
        select 1 
          from n_relatedstore
          where laborid in (
            select laborid 
            from labor 
            where n_type=''RDC'' and personid in (
              select personid 
              from maxuser 
              where userid = :user 
            )
          )
          and po.n_sap_from_plant = n_rdcstoreroom
        )
     and  exists (
    select 1 
    from poline 
    where poline.ponum = po.ponum 
      and poline.siteid = po.siteid 
      and poline.revisionnum = po.revisionnum
      and poline.n_sap_to_sloc < ''5000'' AND poline.N_REMAININGQTY > 0
  )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_SAPRESERV', 'My RDC SAP RESERVATION TO CPM', 'Z4837655', 'SAP Reservation from my RDC to CPM', '(historyflag = 0 
and po.n_sap_from_sloc  >= ''5000''
  and n_po_type=''SAPRESERVATION''
  and  exists (
        select 1 
          from n_relatedstore
          where laborid in (
            select laborid 
            from labor 
            where n_type=''RDC'' and personid in (
              select personid 
              from maxuser 
              where userid = :user 
            )
          )
          and po.n_sap_from_plant = n_rdcstoreroom
        )
     and  exists (
    select 1 
    from poline 
    where poline.ponum = po.ponum 
      and poline.siteid = po.siteid 
      and poline.revisionnum = po.revisionnum
      and poline.storeloc in ( select location from locations where n_type=''CPM'') AND poline.N_REMAININGQTY > 0
  ))

 and ( (N_SAP_TRANSACTION_TYPE LIKE ''2%'' 
    AND EXISTS (
        SELECT 1 
        FROM POLINE 
        WHERE PO.PONUM = POLINE.PONUM 
          AND POLINE.N_SAP_TO_PLANT IS NULL 
          AND POLINE.N_SAP_TO_SLOC IS NULL
    ))
  OR (
    N_SAP_TRANSACTION_TYPE LIKE ''3%'' 
    AND EXISTS (
        SELECT 1 
        FROM POLINE 
        WHERE PO.PONUM = POLINE.PONUM 
          AND POLINE.N_SAP_TO_SLOC = ''5033''
    )
))', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_SAPRESERV', 'My RDC SAP RESERVATION TO PROJECT', 'Z4837655', 'SAP Reservation from my RDC to PROJECT', 'historyflag = 0 

  and po.n_sap_from_sloc  >= ''5000''
  and n_po_type=''SAPRESERVATION''
  and N_SAP_TRANSACTION_TYPE IN (''221'',''222'')
  and  exists (
        select 1 
          from n_relatedstore
          where laborid in (
            select laborid 
            from labor 
            where n_type=''RDC'' and personid in (
              select personid 
              from maxuser 
              where userid = :user 
            )
          )
          and po.n_sap_from_plant = n_rdcstoreroom
        )
     and  exists (
    select 1 
    from poline 
    where poline.ponum = po.ponum 
      and poline.siteid = po.siteid 
      and poline.revisionnum = po.revisionnum
      and poline.n_sap_wbs is not null  AND POLINE.N_SAP_CC IS NULL 
      AND POLINE.N_SAP_IO IS  NULL  AND poline.N_REMAININGQTY > 0
  )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_SAPRESERV', 'My RDC SAP RESERVATION TO RDC', 'Z4837655', 'SAP Reservation from my RDC to another RDC', 'historyflag = 0
 
 and po.n_sap_from_sloc  >= ''5000''
  and n_po_type=''SAPRESERVATION''
  and  exists (
        select 1 
          from n_relatedstore
          where laborid in (
            select laborid 
            from labor 
            where n_type=''RDC'' and personid in (
              select personid 
              from maxuser 
              where userid = :user 
            )
          )
          and po.n_sap_from_plant = n_rdcstoreroom
        )
     and  exists (
    select 1 
    from poline 
    where poline.ponum = po.ponum 
      and poline.siteid = po.siteid 
      and poline.revisionnum = po.revisionnum
      and poline.n_sap_to_sloc >=''5000'' AND poline.N_REMAININGQTY > 0
  )', 1, 'EN', NULL, NULL, 0, NULL);

INSERT INTO MAXIMO.QUERY (QUERYID, APP, CLAUSENAME, OWNER, DESCRIPTION, CLAUSE, ISPUBLIC, LANGCODE, INTOBJECTNAME, PRIORITY, ISUSERLIST, NOTES)
VALUES (QUERYSEQ.NEXTVAL, 'N_METERS_SHIPMENTRECEIPTS', 'MY CPM meters shipment from LAB', 'Z4837655', 'Shipment of meters from LAB to my CPM', 'exists(select 1 from invuse where invuse.invusenum = shipment.invusenum and invuse.siteid = shipment.siteid and invuse.receipts != ''COMPLETE'' and invuse.status != ''CANCELLED'' )

  and exists (

    select 1 

    from shipmentline 

    where shipmentline.shipmentnum = shipment.shipmentnum 

      and shipmentline.siteid = shipment.siteid 

      and exists(select 1 from invuseline where invuseline.invuselineid = shipmentline.invuselineid and invuseline.fromstoreloc in (select location from locations where n_type=''LAB''))

      and exists(

          select 1

          from n_relatedstore

          where n_relatedstore.n_cpm_storeroom=shipmentline.tostoreloc and exists(

            select 1 

            from labor 

            where n_type=''CPM'' and labor.laborid=n_relatedstore.laborid and  exists (

              select 1 

              from maxuser 

              where labor.personid=maxuser.personid and  userid =  :user

            )

          )

        )

      )', 1, 'EN', NULL, NULL, 0, NULL);

COMMIT;