CLASS lhc_ImportConsignment DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
PUBLIC SECTION.
  CLASS-DATA gt_create TYPE STANDARD TABLE OF zmm_impdet_upld WITH DEFAULT KEY.

  PRIVATE SECTION.
    METHODS GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST REQUESTED_AUTHORIZATIONS FOR ImportConsignment RESULT RESULT.

    METHODS CREATE FOR MODIFY
      IMPORTING ENTITIES FOR CREATE ImportConsignment.

    METHODS UPDATE FOR MODIFY
      IMPORTING ENTITIES FOR UPDATE ImportConsignment.

METHODS UploadDMS FOR MODIFY
  IMPORTING KEYS FOR ACTION ImportConsignment~UploadDMS
  RESULT result.

 METHODS DisplayDMS FOR MODIFY
  IMPORTING KEYS FOR ACTION ImportConsignment~DisplayDMS
  RESULT result.

    METHODS DELETE FOR MODIFY
      IMPORTING KEYS FOR DELETE ImportConsignment.

    METHODS READ FOR READ
      IMPORTING KEYS FOR READ ImportConsignment RESULT RESULT.

    METHODS LOCK FOR LOCK
      IMPORTING KEYS FOR LOCK ImportConsignment.

ENDCLASS.

CLASS lhc_ImportConsignment IMPLEMENTATION.

METHOD get_global_authorizations.

  "------------------------------------------------------------
  " CREATE
  " ZMM_IMP06 / ACTVT 01
  "------------------------------------------------------------
  IF requested_authorizations-%create = if_abap_behv=>mk-on.


    AUTHORITY-CHECK OBJECT 'ZMM_IMP06'
      ID 'ACTVT' FIELD '01'.

    IF sy-subrc = 0.
      result-%create = if_abap_behv=>auth-allowed.
    ELSE.
      result-%create = if_abap_behv=>auth-unauthorized.
    ENDIF.

  ENDIF.


  "------------------------------------------------------------
  " UPDATE
  " ZMM_IMP06 / ACTVT 01
  "
  " Currently using Create authorization for update.
  " We can change this to ACTVT 02 later if required.
  "------------------------------------------------------------

  IF requested_authorizations-%update = if_abap_behv=>mk-on.

    AUTHORITY-CHECK OBJECT 'ZMM_IMP06'
      ID 'ACTVT' FIELD '01'.

    IF sy-subrc = 0.
      result-%update = if_abap_behv=>auth-allowed.
    ELSE.
      result-%update = if_abap_behv=>auth-unauthorized.
    ENDIF.

  ENDIF.


  "------------------------------------------------------------
  " DELETE
  " ZMM_IMP06 / ACTVT 06
  "------------------------------------------------------------

  IF requested_authorizations-%delete = if_abap_behv=>mk-on.

    AUTHORITY-CHECK OBJECT 'ZMM_IMP06'
      ID 'ACTVT' FIELD '06'.

    IF sy-subrc = 0.
      result-%delete = if_abap_behv=>auth-allowed.
    ELSE.
      result-%delete = if_abap_behv=>auth-unauthorized.
    ENDIF.

  ENDIF.

ENDMETHOD.

METHOD create.

  LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

    "==========================================================
    " 1. BOL / AWB NUMBER REQUIRED
    "==========================================================

    IF <entity>-bol_awb IS INITIAL.

      APPEND VALUE #(
        %cid = <entity>-%cid
      ) TO failed-importconsignment.

      APPEND VALUE #(
        %cid = <entity>-%cid
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'BOL/AWB is required'
        )
      ) TO reported-importconsignment.

      CONTINUE.

    ENDIF.


    "==========================================================
    " 2. BOL / AWB DATE REQUIRED
    "==========================================================

    IF <entity>-bol_awb_dt IS INITIAL.

      APPEND VALUE #(
        %cid = <entity>-%cid
      ) TO failed-importconsignment.

      APPEND VALUE #(
        %cid = <entity>-%cid
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'BOL/AWB date is required'
        )
      ) TO reported-importconsignment.

      CONTINUE.

    ENDIF.


    "==========================================================
    " 3. BOL / AWB COUNT REQUIRED
    "==========================================================

    IF <entity>-bol_awb_cnt IS INITIAL.

      APPEND VALUE #(
        %cid = <entity>-%cid
      ) TO failed-importconsignment.

      APPEND VALUE #(
        %cid = <entity>-%cid
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'BOL/AWB count is required'
        )
      ) TO reported-importconsignment.

      CONTINUE.

    ENDIF.


    "==========================================================
    " 4. RODTEP LICENSE NUMBER REQUIRED
    "==========================================================

    IF <entity>-rodtep_lic_no IS INITIAL.

      APPEND VALUE #(
        %cid = <entity>-%cid
      ) TO failed-importconsignment.

      APPEND VALUE #(
        %cid = <entity>-%cid
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'RoDTEP license number is required'
        )
      ) TO reported-importconsignment.

      CONTINUE.

    ENDIF.


    "==========================================================
    " 5. FUTURE BOL / AWB DATE
    "==========================================================

    IF <entity>-bol_awb_dt > sy-datum.

      APPEND VALUE #(
        %cid = <entity>-%cid
      ) TO failed-importconsignment.

      APPEND VALUE #(
        %cid = <entity>-%cid
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'BOL/AWB date cannot be in the future'
        )
      ) TO reported-importconsignment.

      CONTINUE.

    ENDIF.


   "==========================================================
" 6. DUPLICATE CHECK
"==========================================================

SELECT SINGLE
  FROM zmm_impdet_upld
  FIELDS delflg
  WHERE bol_awb       = @<entity>-bol_awb
    AND bol_awb_dt    = @<entity>-bol_awb_dt
    AND bol_awb_cnt   = @<entity>-bol_awb_cnt
    AND rodtep_lic_no = @<entity>-rodtep_lic_no
  INTO @DATA(lv_existing_delflg).

IF sy-subrc = 0.

  IF lv_existing_delflg = 'X'.

    APPEND VALUE #(
      %cid = <entity>-%cid
    ) TO failed-importconsignment.

    APPEND VALUE #(
      %cid = <entity>-%cid
      %msg = new_message_with_text(
        severity = if_abap_behv_message=>severity-error
        text     = |Bill No. { <entity>-bol_awb } exist & deleted |
      )
    ) TO reported-importconsignment.

  ELSE.

    APPEND VALUE #(
      %cid = <entity>-%cid
    ) TO failed-importconsignment.

    APPEND VALUE #(
      %cid = <entity>-%cid
      %msg = new_message_with_text(
        severity = if_abap_behv_message=>severity-error
        text     = |Bill No.{ <entity>-bol_awb } already exists.|
      )
    ) TO reported-importconsignment.

  ENDIF.

  CONTINUE.

ENDIF.




    "==========================================================
    " 7. VALID RECORD → TRANSACTION BUFFER
    "==========================================================

    APPEND VALUE #(

      mandt         = sy-mandt

      bol_awb       = <entity>-bol_awb
      bol_awb_dt    = <entity>-bol_awb_dt
      bol_awb_cnt   = <entity>-bol_awb_cnt
      rodtep_lic_no = <entity>-rodtep_lic_no

      rodtep_lic_dt  = <entity>-rodtep_lic_dt
      rodtep_lic_val = <entity>-rodtep_lic_val
      boe_ex_rt      = <entity>-boe_ex_rt
      ad_co          = <entity>-ad_co
      por_co          = <entity>-por_co
      lc_no           = <entity>-lc_no
      lc_dt           = <entity>-lc_dt
      duty_chl_no     = <entity>-duty_chl_no
      duty_chl_dt     = <entity>-duty_chl_dt
      duty_chl_val    = <entity>-duty_chl_val
      inv_pay_ref     = <entity>-inv_pay_ref
      inv_pay_dt      = <entity>-inv_pay_dt
      boe_stat        = <entity>-boe_stat
      sims_ref        = <entity>-sims_ref

      suppinv_dtyp    = <entity>-suppinv_dtyp
      suppinv_docno   = <entity>-suppinv_docno
      billlad_dtyp    = <entity>-billlad_dtyp
      billlad_docno   = <entity>-billlad_docno
      boe_dtyp        = <entity>-boe_dtyp
      boe_docno       = <entity>-boe_docno
      duty_chl_dtyp   = <entity>-duty_chl_dtyp
      duty_chl_no_idc = <entity>-duty_chl_no_idc
      imp_oth_dtyp    = <entity>-imp_oth_dtyp
      imp_others_no   = <entity>-imp_others_no

      ernam       = sy-uname
      erdat       = sy-datum
      ztime_creat = sy-uzeit

      delflg      = ''

    ) TO gt_create.


    "==========================================================
    " 8. RAP KEY MAPPING
    "==========================================================

    APPEND VALUE #(

      %cid = <entity>-%cid

      bol_awb       = <entity>-bol_awb
      bol_awb_dt    = <entity>-bol_awb_dt
      bol_awb_cnt   = <entity>-bol_awb_cnt
      rodtep_lic_no = <entity>-rodtep_lic_no

    ) TO mapped-importconsignment.

  ENDLOOP.

ENDMETHOD.


METHOD UploadDMS.

  LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).

    DATA(lv_document_type) = <key>-%param-document_type.
    DATA(lv_bol_awb)       = <key>-%param-bol_awb.

    DATA(lv_filename) = <key>-%param-_File-filename.
    DATA(lv_mimetype) = <key>-%param-_File-mimetype.

    DATA(lv_pdf_xstring) = <key>-%param-_File-streamproperty.

    DATA: lt_binary TYPE STANDARD TABLE OF solix,
          lv_size   TYPE i.

    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer        = lv_pdf_xstring
      IMPORTING
        output_length = lv_size
      TABLES
        binary_tab    = lt_binary.

    IF lv_size IS INITIAL.

      APPEND VALUE #(
        %cid = <key>-%cid
        %param = VALUE #(
          dummy          = 'X'
          document_type  = lv_document_type
          document_number = ''
          document_part  = ''
          document_version = ''
          message_type   = 'E'
          message        = 'Uploaded PDF is empty.'
        )
      ) TO result.

      CONTINUE.

    ENDIF.


    "------------------------------------------------------------
    " Create temporary server-side PDF file
    "------------------------------------------------------------

    DATA(lv_temp_file) =
      |/tmp/rap_dms_upload_{ sy-uzeit }.pdf|.

    OPEN DATASET lv_temp_file
      FOR OUTPUT
      IN BINARY MODE.

    IF sy-subrc <> 0.

      APPEND VALUE #(
        %cid = <key>-%cid
        %param = VALUE #(
          dummy           = 'X'
          document_type   = lv_document_type
          document_number = ''
          document_part   = ''
          document_version = ''
          message_type    = 'E'
          message         = 'Unable to create temporary PDF file.'
        )
      ) TO result.

      CONTINUE.

    ENDIF.


    LOOP AT lt_binary ASSIGNING FIELD-SYMBOL(<binary>).
      TRANSFER <binary> TO lv_temp_file.
    ENDLOOP.

    CLOSE DATASET lv_temp_file.


    "------------------------------------------------------------
    " Verify temporary file
    "------------------------------------------------------------

    OPEN DATASET lv_temp_file
      FOR INPUT
      IN BINARY MODE.

    IF sy-subrc <> 0.

      APPEND VALUE #(
        %cid = <key>-%cid
        %param = VALUE #(
          dummy           = 'X'
          document_type   = lv_document_type
          document_number = ''
          document_part   = ''
          document_version = ''
          message_type    = 'E'
          message         = 'Temporary PDF file could not be opened.'
        )
      ) TO result.

      CONTINUE.

    ENDIF.

    CLOSE DATASET lv_temp_file.


    "------------------------------------------------------------
    " BAPI DOCUMENT CREATE
    "------------------------------------------------------------

    DATA: ls_bapi_doc         TYPE bapi_doc_draw2,
          lt_bapi_doc_files2  TYPE STANDARD TABLE OF bapi_doc_files2,
          lv_doctype          TYPE bapi_doc_draw2-documenttype,
          lv_docnumber        TYPE bapi_doc_draw2-documentnumber,
          lv_docpart          TYPE bapi_doc_aux-docpart,
          lv_docversion       TYPE bapi_doc_aux-docversion,
          ls_return           TYPE bapiret2.


    ls_bapi_doc = VALUE #(
      documenttype    = lv_document_type
      documentpart    = '000'
      documentversion = '00'
      description     = lv_filename
      laboratory      = '001'
    ).


lt_bapi_doc_files2 = VALUE #(
  (
    wsapplication   = 'PDF'
    description     = lv_filename
    docfile         = lv_temp_file
    storagecategory = 'ZDMS'
    originaltype    = '1'
    active_version  = 'X'
    checkedin       = 'X'
  )
).


CALL FUNCTION 'BAPI_DOCUMENT_CREATE2'
  EXPORTING
    documentdata    = ls_bapi_doc
    hostname        = 'DEFAULT'
    pf_ftp_dest     = 'SAPFTPA'
    pf_http_dest    = 'SAPHTTPA'
  IMPORTING
    documenttype    = lv_doctype
    documentnumber  = lv_docnumber
    documentpart    = lv_docpart
    documentversion = lv_docversion
    return          = ls_return
  TABLES
    documentfiles   = lt_bapi_doc_files2.


    "------------------------------------------------------------
    " Return BAPI result to RAP action
    "------------------------------------------------------------

    APPEND VALUE #(
      %cid = <key>-%cid
      %param = VALUE #(
        dummy             = 'X'
        document_type     = lv_doctype
        document_number   = lv_docnumber
        document_part     = lv_docpart
        document_version  = lv_docversion
        message_type      = ls_return-type
        message           = ls_return-message
      )
    ) TO result.


    "------------------------------------------------------------
    " Delete temporary file
    "------------------------------------------------------------

    DELETE DATASET lv_temp_file.

  ENDLOOP.

ENDMETHOD.

METHOD DisplayDMS.

  DATA:
    lv_document_number  TYPE draw-doknr,
    lv_document_type    TYPE draw-dokar,
    lv_document_part    TYPE draw-doktl,
    lv_document_version TYPE draw-dokvr.

  DATA:
    ls_draw TYPE draw.

  DATA:
    ls_documentdata TYPE bapi_doc_draw2,
    ls_return       TYPE bapiret2.

  DATA:
    lt_bapi_files  TYPE STANDARD TABLE OF bapi_doc_files2,
    lt_cvapi_files TYPE STANDARD TABLE OF cvapi_doc_file,
    lt_content     TYPE STANDARD TABLE OF drao.

  DATA:
    lv_xstring  TYPE xstring,
    lv_base64   TYPE string,
    lv_filename TYPE string,
    lv_length   TYPE i.

  DATA:
    lt_orblk TYPE STANDARD TABLE OF drao-orblk.

  LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).

    CLEAR:
      lv_document_number,
      lv_document_type,
      lv_document_part,
      lv_document_version,
      ls_draw,
      ls_documentdata,
      ls_return,
      lv_xstring,
      lv_base64,
      lv_filename,
      lv_length.

    CLEAR:
      lt_bapi_files,
      lt_cvapi_files,
      lt_content,
      lt_orblk.

    "------------------------------------------------------------
    " Get only DMS document number from the action parameter
    "------------------------------------------------------------

    lv_document_number = |{ <key>-%param-document_number alpha = in }|.

    IF lv_document_number IS INITIAL.
      CONTINUE.
    ENDIF.

    "------------------------------------------------------------
    " Determine DMS document type/part/version from DRAW
    "------------------------------------------------------------

    SELECT SINGLE
      dokar,
      doknr,
      doktl,
      dokvr
      FROM draw
      WHERE doknr = @lv_document_number
      INTO CORRESPONDING FIELDS OF @ls_draw.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    lv_document_type    = ls_draw-dokar.
    lv_document_number  = ls_draw-doknr.
    lv_document_part    = ls_draw-doktl.
    lv_document_version = ls_draw-dokvr.

    "------------------------------------------------------------
    " Get DMS document details
    "------------------------------------------------------------

    CALL FUNCTION 'BAPI_DOCUMENT_GETDETAIL2'
      EXPORTING
        documenttype    = ls_draw-dokar
        documentnumber  = ls_draw-doknr
        documentpart    = ls_draw-doktl
        documentversion = ls_draw-dokvr
        getactivefiles  = 'X'
        getdocfiles     = 'X'
      IMPORTING
        documentdata    = ls_documentdata
        return          = ls_return
      TABLES
        documentfiles   = lt_bapi_files.

    IF ls_return-type CA 'EA'.
      CONTINUE.
    ENDIF.

    IF lt_bapi_files IS INITIAL.
      CONTINUE.
    ENDIF.

    "------------------------------------------------------------
    " Convert BAPI file table to CVAPI file table
    "------------------------------------------------------------

    CALL FUNCTION 'MAP2I_BAPI_FILE2_TO_API_FILE'
      TABLES
        bapi_doc_file = lt_bapi_files
        api_doc_file  = lt_cvapi_files.

    IF lt_cvapi_files IS INITIAL.
      CONTINUE.
    ENDIF.

    "------------------------------------------------------------
    " Checkout document content
    "------------------------------------------------------------

    CALL FUNCTION 'CVAPI_DOC_CHECKOUTVIEW'
      EXPORTING
        pf_dokar           = ls_draw-dokar
        pf_doknr           = ls_draw-doknr
        pf_dokvr           = ls_draw-dokvr
        pf_doktl           = ls_draw-doktl
        pf_content_provide = 'TBL'
      TABLES
        pt_files            = lt_cvapi_files
        ptx_content         = lt_content
      EXCEPTIONS
        error               = 1
        no_authority        = 2
        not_found           = 3
        no_original         = 4
        OTHERS              = 5.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    IF lt_content IS INITIAL.
      CONTINUE.
    ENDIF.

    "------------------------------------------------------------
    " Build binary content
    "------------------------------------------------------------

    CLEAR:
      lt_orblk,
      lv_length.

    LOOP AT lt_content ASSIGNING FIELD-SYMBOL(<content>).

      APPEND <content>-orblk TO lt_orblk.

      lv_length =
        lv_length + <content>-orln.

    ENDLOOP.

    IF lt_orblk IS INITIAL.
      CONTINUE.
    ENDIF.

    "------------------------------------------------------------
    " Convert binary content to XSTRING
    "------------------------------------------------------------

    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING
        input_length = lv_length
      IMPORTING
        buffer       = lv_xstring
      TABLES
        binary_tab   = lt_orblk
      EXCEPTIONS
        failed = 1
        OTHERS = 2.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    IF lv_xstring IS INITIAL.
      CONTINUE.
    ENDIF.

    "------------------------------------------------------------
    " Convert XSTRING to Base64
    "------------------------------------------------------------

    CALL FUNCTION 'SCMS_BASE64_ENCODE_STR'
      EXPORTING
        input  = lv_xstring
      IMPORTING
        output = lv_base64
      EXCEPTIONS
        failed = 1
        OTHERS = 2.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    IF lv_base64 IS INITIAL.
      CONTINUE.
    ENDIF.

    "------------------------------------------------------------
    " Get original filename
    "------------------------------------------------------------

    READ TABLE lt_cvapi_files ASSIGNING FIELD-SYMBOL(<cvfile>)
      INDEX 1.

    IF sy-subrc = 0.
      lv_filename = <cvfile>-filename.
    ENDIF.

    IF lv_filename IS INITIAL.

      lv_filename =
        |{ lv_document_number }.pdf|.

    ENDIF.

    "------------------------------------------------------------
    " Return document
    "------------------------------------------------------------

    APPEND VALUE #(
      %cid = <key>-%cid

      %param = VALUE #(
        dummy            = <key>-%param-dummy
        document_type    = lv_document_type
        document_number  = lv_document_number
        document_part    = lv_document_part
        document_version = lv_document_version
        document_base64  = lv_base64
        mimetype         = 'application/pdf'
        filename         = lv_filename
      )
    ) TO result.

  ENDLOOP.

ENDMETHOD.

METHOD update.

  LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

    UPDATE zmm_impdet_upld
      SET rodtep_lic_dt   = @<entity>-rodtep_lic_dt,
          rodtep_lic_val  = @<entity>-rodtep_lic_val,
          boe_ex_rt       = @<entity>-boe_ex_rt,
          ad_co            = @<entity>-ad_co,
          por_co           = @<entity>-por_co,
          lc_no            = @<entity>-lc_no,
          lc_dt            = @<entity>-lc_dt,
          duty_chl_no      = @<entity>-duty_chl_no,
          duty_chl_dt      = @<entity>-duty_chl_dt,
          duty_chl_val     = @<entity>-duty_chl_val,
          inv_pay_ref      = @<entity>-inv_pay_ref,
          inv_pay_dt       = @<entity>-inv_pay_dt,
          boe_stat         = @<entity>-boe_stat,
          sims_ref         = @<entity>-sims_ref,
          suppinv_dtyp     = @<entity>-suppinv_dtyp,
          suppinv_docno    = @<entity>-suppinv_docno,
          billlad_dtyp     = @<entity>-billlad_dtyp,
          billlad_docno    = @<entity>-billlad_docno,
          boe_dtyp         = @<entity>-boe_dtyp,
          boe_docno        = @<entity>-boe_docno,
          duty_chl_dtyp    = @<entity>-duty_chl_dtyp,
          duty_chl_no_idc  = @<entity>-duty_chl_no_idc,
          imp_oth_dtyp     = @<entity>-imp_oth_dtyp,
          imp_others_no    = @<entity>-imp_others_no
      WHERE bol_awb       = @<entity>-bol_awb
        AND bol_awb_dt    = @<entity>-bol_awb_dt
        AND bol_awb_cnt   = @<entity>-bol_awb_cnt
        AND rodtep_lic_no = @<entity>-rodtep_lic_no.

  ENDLOOP.


ENDMETHOD.


METHOD delete.

  LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).

    "------------------------------------------------------------
    " Soft delete the selected Import Consignment record
    "------------------------------------------------------------
    UPDATE zmm_impdet_upld
      SET delflg = 'X'
      WHERE bol_awb       = @<key>-bol_awb
        AND bol_awb_dt    = @<key>-bol_awb_dt
        AND bol_awb_cnt   = @<key>-bol_awb_cnt
        AND rodtep_lic_no = @<key>-rodtep_lic_no.

    "------------------------------------------------------------
    " Check whether the database record was updated
    "------------------------------------------------------------
    IF sy-subrc = 0.

      "----------------------------------------------------------
      " Success message
      "----------------------------------------------------------
      APPEND VALUE #(
        %tky = <key>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-success
          text = |Import Consignment { <key>-bol_awb } deleted successfully.|
        )
      ) TO reported-importconsignment.

    ELSE.

      "----------------------------------------------------------
      " Mark delete operation as failed
      "----------------------------------------------------------
      APPEND VALUE #(
        %tky = <key>-%tky
        %fail-cause = if_abap_behv=>cause-unspecific
      ) TO failed-importconsignment.

      "----------------------------------------------------------
      " Error message
      "----------------------------------------------------------
      APPEND VALUE #(
        %tky = <key>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = |Unable to delete Import Consignment { <key>-bol_awb }.|
        )
      ) TO reported-importconsignment.

    ENDIF.

  ENDLOOP.

ENDMETHOD.

METHOD read.

  SELECT FROM zmm_impdet_upld
    FIELDS *
    FOR ALL ENTRIES IN @keys
    WHERE bol_awb       = @keys-bol_awb
      AND bol_awb_dt    = @keys-bol_awb_dt
*      AND bol_awb_cnt   = @keys-bol_awb_cnt
*      AND rodtep_lic_no = @keys-rodtep_lic_no
    INTO CORRESPONDING FIELDS OF TABLE @result.

ENDMETHOD.

  METHOD LOCK.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_MM_IMPDET DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_SAVER.
  PROTECTED SECTION.

    METHODS FINALIZE REDEFINITION.

    METHODS CHECK_BEFORE_SAVE REDEFINITION.

    METHODS SAVE REDEFINITION.

    METHODS CLEANUP REDEFINITION.

    METHODS CLEANUP_FINALIZE REDEFINITION.

ENDCLASS.

CLASS lsc_ZI_MM_IMPDET IMPLEMENTATION.

  METHOD FINALIZE.


  ENDMETHOD.

  METHOD CHECK_BEFORE_SAVE.
  ENDMETHOD.


METHOD save.

  IF lhc_ImportConsignment=>gt_create IS INITIAL.
    RETURN.
  ENDIF.

  INSERT zmm_impdet_upld
    FROM TABLE @lhc_ImportConsignment=>gt_create.

ENDMETHOD.


  METHOD CLEANUP.
   CLEAR lhc_ImportConsignment=>gt_create.
  ENDMETHOD.

  METHOD CLEANUP_FINALIZE.
  ENDMETHOD.

ENDCLASS.
