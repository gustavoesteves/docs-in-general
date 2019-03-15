  -----------------------------------------------------
  -- Retorna o valor de um conteudo especifico
  -----------------------------------------------------
  FUNCTION GetContentNumber(PLabel IN VARCHAR2,
                            PLine  IN VARCHAR2) RETURN NUMBER IS
    --
    vIndex          INT;
    vFunction       PTC_CMS_MDL_CTD.NM_FUN_CTD%TYPE := NULL;
    vFormat         PTC_CMS_MDL_CTD.DS_FMT_DAD%TYPE := NULL;
    vDataType       PTC_CMS_MDL_CTD.TP_DAD%TYPE     := NULL;
    vContent        VARCHAR2(4000) := NULL;
    vNumberContent  NUMBER;
    vSQLScript      VARCHAR2(200);
    --
    vUserMessage    VARCHAR2(500);
    vReturnCode     NUMBER;
    vReturnMessage  VARCHAR2(500);
    --
    vModule VARCHAR2(100);
    vAction VARCHAR2(100);
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'GetContent');
    --
    BEGIN
      --
      SELECT MC.NM_FUN_CTD,
             MC.DS_FMT_DAD,
             MC.TP_DAD
        INTO vFunction,
             vFormat,
             vDataType
        FROM PTC_CMS_MDL_CTD MC,
             PTC_CMS_REG R
       WHERE R.CD_ARQ = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
         AND R.NU_REG = WT_MASSIVELOAD_PKG.gFile.NU_REG
         AND R.CD_MDL_REG = MC.CD_MDL_REG
         AND MC.DS_RTL_CTD = PLabel;
      --
    EXCEPTION
      --
      WHEN NO_DATA_FOUND THEN
        --
        vFunction := NULL;
        --
    END;
    --
    IF vFunction IS NOT NULL THEN
      --
      vSQLScript := 'CALL ' || vFunction || ' INTO :vContent';
      gLine := PLine;
      --
      EXECUTE IMMEDIATE vSQLScript
              USING OUT vContent;
      --
    ELSE
      --
      vIndex := INSTR(PLine, '<' || TRIM(PLabel) || '>');
      --
      IF vIndex > 0 THEN
         vContent := SUBSTR(PLine, vIndex + Length(TRIM(PLabel)) + 2);
         --
         IF INSTR(vContent, '|') > 0 THEN
            vContent := SUBSTR(vContent, 1, INSTR(vContent, '|') - 1);
         END IF;
        --
      END IF;
    END IF;
    --
    SELECT DECODE(TO_NUMBER(vContent), 0, NULL, TO_NUMBER(vContent))
      INTO vNumberContent
      FROM DUAL;
    
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
    RETURN vNumberContent;
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      UpdateRelatedLines(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                         PCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                         PNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                         PCD_MSG_ERR => 182190,
                         PDS_MSG_ERR => '<'|| PLabel ||'> - ' || SQLERRM,
                         PMSG_USER   => vUserMessage,
                         pCOD_RET    => vReturnCode,
                         pMSG_RET    => vReturnMessage);
      --
  END GetContentNumber;
  --

  ------------------------------------------------------
  -- Procedure InsertException
  ------------------------------------------------------
  PROCEDURE InsertException(PCD_ARQ    IN PTC_CMS_ARQ_EXC.CD_ARQ%TYPE,
                           PCD_DOM    IN PTC_CMS_ARQ_EXC.CD_DOM%TYPE,
                           PNU_REG    IN PTC_CMS_ARQ_EXC.NU_REG%TYPE,
                           PCD_ERR_EXC IN PTC_CMS_ARQ_EXC.CD_ERR_EXC%TYPE,
                           PDC_ERR_EXC IN PTC_CMS_ARQ_EXC.DC_ERR_EXC%TYPE,
                           PDC_CPL_EXC IN PTC_CMS_ARQ_EXC.DC_CPL_EXC%TYPE) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    --
    vModule VARCHAR2(100);
    vAction VARCHAR2(100);
    --
    vStatus PTC_CMS_ARQ_DOM.CD_STA_CMM%TYPE;
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'MassiveLoadPartial');
    --
    --
    SELECT AD.CD_STA_CMM
      INTO vStatus
      FROM PTC_CMS_ARQ_DOM AD
     WHERE AD.CD_ARQ = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
       AND AD.CD_DOM = WT_MASSIVELOAD_PKG.gFile.CD_DOM;
    --   
    INSERT INTO PTC_CMS_ARQ_EXC
      (CD_ARQ     
      ,NU_SEQ     
      ,CD_DOM     
      ,CD_STA_CMM 
      ,NU_REG
      ,CD_ERR_EXC
      ,DT_GEC_EXC 
      ,DC_ERR_EXC 
      ,DC_CPL_EXC )
    VALUES  
      (PCD_ARQ     
      ,(SELECT NVL(MAX(M.NU_SEQ),0)+1 FROM PTC_CMS_ARQ_EXC M WHERE M.CD_ARQ = WT_MASSIVELOAD_PKG.gFile.CD_ARQ)     
      ,PCD_DOM     
      ,vStatus 
      ,PNU_REG
      ,PCD_ERR_EXC
      ,SYSTIMESTAMP 
      ,PDC_ERR_EXC 
      ,PDC_CPL_EXC ) ;
    commit;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
  END InsertException;
  --  