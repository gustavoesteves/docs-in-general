CREATE OR REPLACE PACKAGE BODY WT2MX_MASSIVELOAD_MNG  IS
  -- *********************
  -- * INTERNAL TYPES    *
  -- *********************
  -- 
  TYPE TRParameter IS RECORD (LINES          BINARY_INTEGER,
                              ROWPAG         BINARY_INTEGER,
                              COD_PARAMETRO  TKT_NPTC_PARAMETER.COD_PARAMETRO%TYPE,
                              VAL_PARAMETRO  TKT_NPTC_PARAMETER.VAL_PARAMETRO%TYPE,
                              DES_PARAMETRO  TKT_NPTC_PARAMETER.DES_PARAMETRO%TYPE);  

  -- Tipo para armazenar dados dos tipos de conteúdo em processamento
  TYPE RType IS RECORD (
    CD_MDL_REG        PTC_mss_MDL_REG.CD_MDL_REG%TYPE,
    DataType          ptc_mss_MDL_CTD.TP_DAD%TYPE,
    DataFormat        ptc_mss_MDL_CTD.DS_FMT_DAD%TYPE,
    DataSize          ptc_mss_MDL_CTD.NU_TAM_MAX%TYPE,
    DataPrecision     ptc_mss_MDL_CTD.NU_PCS%TYPE,
    Required          ptc_mss_MDL_CTD.IN_OBR%TYPE,
    FieldDescription  ptc_mss_MDL_CTD.DS_CTD%TYPE,
    ValuesListId      ptc_mss_MDL_CTD.CD_LST_VLR%TYPE);
  --
  TYPE TTypes IS TABLE OF RType INDEX BY ptc_mss_MDL_CTD.DS_RTL_CTD%TYPE; 
  --
  TYPE tReg1Types IS RECORD(Conteudo TTypes);
  TYPE tRegTypes IS TABLE OF tReg1Types INDEX BY BINARY_INTEGER;   
  --
  -- *********************
  -- * VARIAVEIS GLOBAIS *
  -- *********************
  --
  vModule               VARCHAR2(100);
  vAction               VARCHAR2(100);
  --
  vTrack                VARCHAR2(500);
  --
  gTypes tRegTypes;
  --
  --
  --
  -- **********************
  -- * MONITOR METHODS *
  -- **********************
  --
  PROCEDURE Auditoria( pProcedure IN VARCHAR2) IS -- 1.01
    vPar        TY_AUDIT_PARAM_TBL;
    vPos        NUMBER;
  BEGIN
    -- Auditoria -------------------------------------------------------------------
    vPar    := TY_AUDIT_PARAM_TBL();
    vPar.EXTEND(2);
    vPar(1) := TY_AUDIT_PARAM_OBJ('CD_ARQ'         , gFile.CD_ARQ);
    vPar(2) := TY_AUDIT_PARAM_OBJ('NU_REG'         , gFile.NU_REG);
    --
    WT2_AUDIT_UTL.AuditCreate(pCD_USU => SYS_CONTEXT('USERENV', 'OS_USER'),
                              pDS_ORI => pProcedure,
                              pEN_IP  => SYS_CONTEXT('USERENV', 'HOST'),
                              pID_MSG => NULL,
                              pID_REQ => NULL,
                              pPRM    => vPar,
                              pCLOB   => NULL);
    --
  END;
  --
  --
  PROCEDURE UpdateServiceMonitor IS
    --
    PRAGMA AUTONOMOUS_TRANSACTION;
    --
    vResumo      CLOB;
    vLinha       VARCHAR2(500);
    vLastFile    PTC_MSS_ARQ.CD_ARQ%TYPE;
    vLastReg     PTC_MSS_MDL_REG.CD_MDL_REG%TYPE;
    vFileIndex   INTEGER;
    vRegIndex    INTEGER;
    vDomainIndex INTEGER;
    --
    vModule     VARCHAR2(100);
    vAction     VARCHAR2(100);
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'UpdateServiceMonitor');
    --
    DBMS_LOB.CREATETEMPORARY(vResumo, TRUE);
    --
    DBMS_LOB.WRITEAPPEND(vResumo, 32, '<Running MassiveLoad Processes>' || CHR(10));
    --
    vLastFile := 0;
    vFileIndex    := 0;
    --
    FOR rLinha IN (SELECT A.CD_ARQ,
                          A.NM_ARQ,
                          A.NU_TOT_LIN,
                          MA.DS_MDL_ARQ,
                          A.DT_SOL,
                          A.DT_INI_PRC AS DT_INI_PRC_ARQ,
                          A.TP_PRC,
                          A.TP_ACA,
                          MA.IN_PRC_INT,
                          MR.CD_MDL_REG,
                          MR.DS_MDL_REG,
                          A.CD_STA_CMM,
                          S.DC_STA_CMM
                     FROM PTC_mss_ARQ A,
                          PTC_mss_MDL_ARQ MA,
                          PTC_mss_MDL_REG MR,
                          PTC_STA_CMM S
                    WHERE A.CD_STA_CMM  = 76
                      AND A.CD_MDL_ARQ  = MA.CD_MDL_ARQ
                      AND MA.CD_MDL_ARQ  = MR.CD_MDL_ARQ
                      AND A.CD_STA_CMM   = S.CD_STA_CMM
                    ORDER BY A.CD_ARQ, 
                             MR.NU_ORD_PRC)      LOOP
      --
      IF rLinha.CD_ARQ != vLastFile THEN
        --
        vFileIndex := vFileIndex + 1;
        --
        vLinha := 'File[' || vFileIndex || '].ID: ' || rLinha.CD_ARQ;
        DBMS_LOB.WRITEAPPEND(vResumo, Length(TRIM(vLinha)) + 1, TRIM(vLinha) || CHR(10));
        --
        vLinha := 'File[' || vFileIndex || '].FileName: ' || rLinha.NM_ARQ;
        DBMS_LOB.WRITEAPPEND(vResumo, Length(TRIM(vLinha)) + 1, TRIM(vLinha) || CHR(10));
        --
        vLinha := 'File[' || vFileIndex || '].Model: ' || rLinha.DS_MDL_ARQ;
        DBMS_LOB.WRITEAPPEND(vResumo, Length(TRIM(vLinha)) + 1, TRIM(vLinha) || CHR(10));
        --
        vLinha := 'File[' || vFileIndex || '].RowCount: ' || rLinha.NU_TOT_LIN;
        DBMS_LOB.WRITEAPPEND(vResumo, Length(TRIM(vLinha)) + 1, TRIM(vLinha) || CHR(10));
        --
        vLinha := 'File[' || vFileIndex || '].ProcessType: ' || CASE WHEN rLinha.TP_PRC = 'P' THEN 'Partial' ELSE 'Full' END;
        DBMS_LOB.WRITEAPPEND(vResumo, Length(TRIM(vLinha)) + 1, TRIM(vLinha) || CHR(10));
        --
        vLinha := 'File[' || vFileIndex || '].Action: ' || CASE WHEN rLinha.TP_ACA = 'V' THEN 'Validate' ELSE 'Apply' END;
        DBMS_LOB.WRITEAPPEND(vResumo, Length(TRIM(vLinha)) + 1, TRIM(vLinha) || CHR(10));
        --
        vLinha := 'File[' || vFileIndex || '].Interface: ' || CASE WHEN rLinha.In_Prc_Int = 'T' THEN 'Interface' ELSE 'NoInterface' END;
        DBMS_LOB.WRITEAPPEND(vResumo, Length(TRIM(vLinha)) + 1, TRIM(vLinha) || CHR(10));
        --
        vLinha := 'File[' || vFileIndex || '].RequestTime: ' || TO_CHAR(rLinha.DT_SOL, 'DD/MM/RRRR HH24:MI:SS');
        DBMS_LOB.WRITEAPPEND(vResumo, Length(TRIM(vLinha)) + 1, TRIM(vLinha) || CHR(10));
        --
        vLinha := 'File[' || vFileIndex || '].StartTime: ' || TO_CHAR(rLinha.DT_INI_PRC_ARQ, 'DD/MM/RRRR HH24:MI:SS') || ' [start delay: ' || TO_NUMBER(TO_CHAR(TO_DATE('1','J') + (TO_DATE(rLinha.DT_INI_PRC_ARQ, 'DD/MM/RRRR HH24:MI:SS') - TO_DATE(rLinha.DT_SOL, 'DD/MM/RRRR HH24:MI:SS')), 'J') - 1) || 'd ' || TO_CHAR(TO_DATE('00:00:00','HH24:MI:SS') + (rLinha.DT_INI_PRC_ARQ - rLinha.DT_SOL), 'HH24:MI:SS') || ']';
        DBMS_LOB.WRITEAPPEND(vResumo, Length(TRIM(vLinha)) + 1, TRIM(vLinha) || CHR(10));
        --
        vLastFile := rLinha.CD_ARQ;
        vLastReg := rLinha.CD_MDL_REG;
        vRegIndex := 0;
        vDomainIndex := 0;
        --
        vLinha := 'File[' || vFileIndex || '].RegistryModel[' || vRegIndex || '].ID: ' || rLinha.CD_MDL_REG;
        DBMS_LOB.WRITEAPPEND(vResumo, Length(TRIM(vLinha)) + 1, TRIM(vLinha) || CHR(10));
        --
        vLinha := 'File[' || vFileIndex || '].RegistryModel[' || vRegIndex || '].Name: ' || rLinha.DS_MDL_REG;
        DBMS_LOB.WRITEAPPEND(vResumo, Length(TRIM(vLinha)) + 1, TRIM(vLinha) || CHR(10));
        --
      ELSIF rLinha.CD_MDL_REG != vLastReg THEN
        --
        vRegIndex := vRegIndex + 1;
        --
        vLinha := 'File[' || vFileIndex || '].RegistryModel[' || vRegIndex || '].ID: ' || rLinha.CD_MDL_REG;
        DBMS_LOB.WRITEAPPEND(vResumo, Length(TRIM(vLinha)) + 1, TRIM(vLinha) || CHR(10));
        --
        vLinha := 'File[' || vFileIndex || '].RegistryModel[' || vRegIndex || '].Name: ' || rLinha.DS_MDL_REG;
        DBMS_LOB.WRITEAPPEND(vResumo, Length(TRIM(vLinha)) + 1, TRIM(vLinha) || CHR(10));
        --
        vLastReg := rLinha.CD_MDL_REG;
        vDomainIndex := 0;
        --
      END IF;
      --
      vDomainIndex := vDomainIndex + 1;
      --
      vLinha := 'File[' || vFileIndex || '].RegistryModel[' || vRegIndex || '].Domain[' || vDomainIndex || '].Status: ' || rLinha.DC_STA_CMM || '[' || rLinha.CD_STA_CMM || ']';
      DBMS_LOB.WRITEAPPEND(vResumo, Length(TRIM(vLinha)) + 1, TRIM(vLinha) || CHR(10));
      --
    END LOOP;
    --
    UPDATE PTC_MON_SVC MS
       SET DT_ULT_EXE = SYSDATE,
           DT_PRX_EXE = SYSDATE,
           MS.DC_RSM  = vResumo
     WHERE MS.EN_SRV  = UPPER(SYS_CONTEXT('USERENV', 'DB_NAME'))
       AND MS.NM_SVC  = 'Watts MassiveLoad Service';
    --
    IF  SQL%ROWCOUNT = 0 THEN
        INSERT INTO PTC_MON_SVC (EN_SRV,
                                 NM_SRV,
                                 NM_SVC,
                                 DT_ULT_EXE,
                                 DT_PRX_EXE,
                                 DC_RSM)
                         VALUES (UPPER(SYS_CONTEXT('USERENV', 'DB_NAME')),
                                 UPPER(SYS_CONTEXT('USERENV', 'DB_NAME')),
                                 'Watts MassiveLoad Service',
                                 SYSDATE,
                                 SYSDATE,
                                 vResumo);
        --
    END IF;
    --
    COMMIT;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      ROLLBACK;
      RAISE;
      --
  END UpdateServiceMonitor;  
  --
  PROCEDURE ServiceMonitoringUpdate(PEN_SRV   IN PTC_MON_SVC.EN_SRV%TYPE,
                                    PNM_SRV   IN PTC_MON_SVC.NM_SRV%TYPE,
                                    PNM_SVC   IN PTC_MON_SVC.NM_SVC%TYPE,
                                    PDC_RSM   IN PTC_MON_SVC.DC_RSM%TYPE := NULL,
                                    PMSG_USER OUT NOCOPY VARCHAR2,
                                    PCOD_RET  OUT NOCOPY NUMBER,
                                    PMSG_RET  OUT NOCOPY VARCHAR2) IS
    vCOUNT NUMBER;
  BEGIN
    SELECT COUNT(1)
      INTO vCOUNT
      FROM PTC_MON_SVC MS
     WHERE MS.EN_SRV = PEN_SRV
       AND MS.NM_SVC = PNM_SVC;
  
    IF vCOUNT = 0 THEN
      INSERT INTO PTC_MON_SVC
        (EN_SRV, NM_SRV, NM_SVC, DT_ULT_EXE, DT_PRX_EXE, DC_RSM)
      VALUES
        (PEN_SRV,
         PNM_SRV,
         PNM_SVC,
         SYSDATE,
         SYSDATE + (30 / 86400),
         PDC_RSM);
    ELSE
      UPDATE PTC_MON_SVC MS
         SET MS.NM_SRV     = PNM_SRV,
             MS.DT_ULT_EXE = SYSDATE,
             MS.DT_PRX_EXE = SYSDATE + (30 / 86400),
             MS.DC_RSM     = PDC_RSM
       WHERE MS.EN_SRV = PEN_SRV
         AND MS.NM_SVC = PNM_SVC;
    END IF;
  
    PMSG_USER := WT_UTILITY_PKG.GetMessage(SQLCODE);
    PCOD_RET  := SQLCODE;
    PMSG_RET  := SQLERRM;
  EXCEPTION
    WHEN OTHERS THEN
      PMSG_USER := WT_UTILITY_PKG.GetMessage(SQLCODE);
      PCOD_RET  := SQLCODE;
      PMSG_RET  := SQLERRM;
  END;  
  --  
  --
  -- **********************
  -- * MSS METHODS *
  -- **********************
  --
  ------------------------------------------------------
  -- Atualiza Status do arquivo
  ------------------------------------------------------
  PROCEDURE SetFileData(PCD_ARQ IN ptc_mss_ARQ.CD_ARQ%TYPE) IS
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'SetFileData');
    --
    SELECT A.CD_ARQ,
           A.CD_MDL_ARQ,
           A.TP_PRC,
           A.TP_ACA,
           M.IN_PRC_INT,
           M.IN_VLD_DUP,
           M.NM_PRC_FIN
      INTO gFile.CD_ARQ,     
           gFile.CD_MDL_ARQ,
           gFile.TP_PRC,
           gFile.TP_ACA,
           gFile.IN_PRC_INT,
           gFile.IN_VLD_DUP,
           gFile.NM_PRC_FIN
      FROM ptc_mss_ARQ A,
           PTC_mss_MDL_ARQ M
     WHERE A.CD_ARQ  = PCD_ARQ
       AND M.CD_MDL_ARQ = A.CD_MDL_ARQ;
    --
    /*FOR rPed IN (SELECT AP.NU_PED, 
                        PD.CD_TIP_PED,
                        AP.CD_DOM
                   FROM PTC_MSS_ARQ_PED   AP,
                        PTC_PED           PD 
                  WHERE AP.NU_PED = PD.NU_PED
                    AND AP.CD_ARQ = PCD_ARQ
                  ORDER BY AP.CD_DOM 
                  NULLS LAST)
    LOOP
      --
        gFile.NU_PED := rPed.NU_PED;
        gFile.CD_TIP_PED := rPed.CD_TIP_PED;
        --
        EXIT;
        --
    END LOOP;*/
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      RAISE;
    --
  END;
  --
  --
  ------------------------------------------------------
  -- Log de processamento
  ------------------------------------------------------
  PROCEDURE OperationLog(PCD_ARQ       IN PTC_MSS_ARQ.CD_ARQ%TYPE,
                         PCD_STA_CMM   IN PTC_STA_CMM.CD_STA_CMM%TYPE) IS
    --
    PRAGMA AUTONOMOUS_TRANSACTION;    
    --
    vSeq PTC_MSS_STA_LOG.Nu_Seq%type;
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'OperationLog');
    --
    BEGIN
      --
      UPDATE PTC_MSS_STA_LOG   L
         SET L.DT_FIM_STA = SYSTIMESTAMP
       WHERE L.CD_ARQ = PCD_ARQ
         AND L.DT_FIM_STA IS NULL
         AND L.CD_STA_CMM <> PCD_STA_CMM;
      --
    EXCEPTION
      --
      WHEN NO_DATA_FOUND THEN
        --
        NULL;
        --
    END;
    --
    SELECT NVL(MAX(NU_SEQ), 0) + 1 
    INTO vSeq
    FROM PTC_MSS_STA_LOG 
    WHERE CD_ARQ = PCD_ARQ;
    
    INSERT INTO PTC_MSS_STA_LOG (CD_ARQ,
                                     NU_SEQ,
                                     DT_INI_STA,
                                     DT_FIM_STA,
                                     CD_STA_CMM)
                             VALUES (PCD_ARQ,
                                     vSeq,
                                     SYSTIMESTAMP,
                                     DECODE(PCD_STA_CMM, 79, SYSTIMESTAMP,
                                                         80, SYSTIMESTAMP,
                                                         81, SYSTIMESTAMP,
                                                         82, SYSTIMESTAMP, 
                                                         85, SYSTIMESTAMP,
                                                         86, SYSTIMESTAMP,
                                                         87, SYSTIMESTAMP, NULL),
                                     PCD_STA_CMM);
    --
    COMMIT;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    WHEN OTHERS THEN
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
  END OperationLog;
  --  
  --
  ------------------------------------------------------
  -- Busca qual a linha detalhe principal
  ------------------------------------------------------
  FUNCTION DetailMainLine(PNU_REG      IN PTC_MSS_REG.NU_REG%TYPE) RETURN NUMBER IS
    vMdlReg     PTC_MSS_MDL_REG.CD_MDL_REG%TYPE;
    vNU_REG     PTC_MSS_REG.NU_REG%TYPE;
  BEGIN
    --
    SELECT M.CD_MDL_REG
    INTO vMdlReg
    FROM PTC_MSS_MDL_REG M
    WHERE M.CD_MDL_ARQ = gFile.CD_MDL_ARQ
      AND M.TP_MDL_REG = 'D'
      AND M.CD_MDL_REG_PAI = (SELECT MIN(H.CD_MDL_REG)
                              FROM PTC_MSS_MDL_REG H
                              WHERE H.CD_MDL_ARQ = gFile.CD_MDL_ARQ
                                AND H.TP_MDL_REG = 'H');
    --
    SELECT NVL(MAX(R.NU_REG), PNU_REG)
    INTO vNU_REG
    FROM PTC_MSS_REG R
    WHERE R.NU_REG <= PNU_REG
      AND R.CD_MDL_REG = vMdlReg
      AND R.CD_ARQ = gFile.CD_ARQ;
    
    --
    RETURN vNU_REG;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN PNU_REG;  
  END;  
  --  
  --
  ------------------------------------------------------
  -- Adiciona erro tipo no log
  ------------------------------------------------------
  PROCEDURE AddFileError(PNU_REG         IN PTC_MSS_REG.NU_REG%TYPE,
                         PCD_MSG_ERR     IN PTC_MSS_REG_ERR.CD_MSG_ERR%TYPE,
                         PDS_MSG_ERR     IN PTC_MSS_REG_ERR.DS_MSG_ERR%TYPE DEFAULT NULL,
                         PDS_MSG_AUX_ERR IN PTC_MSS_REG_ERR.DS_MSG_AUX_ERR%TYPE,
                         PTP_ERR         IN PTC_MSS_REG_ERR.TP_ERR%TYPE) IS
    --
    PRAGMA AUTONOMOUS_TRANSACTION;
    --
    vModule VARCHAR2(100);
    vAction VARCHAR2(100);
    --
    --
    vNU_SEQ         PTC_MSS_REG_ERR.NU_SEQ%TYPE;
    vDetailMainLine PTC_MSS_REG.NU_REG%TYPE;
    --
    PROCEDURE InsertError (PNumLinha PTC_MSS_REG.NU_REG%TYPE) IS
    BEGIN  
        UPDATE PTC_MSS_REG R
           SET R.IN_ERR_PRC = 'T'
         WHERE R.CD_ARQ = gFile.CD_ARQ
           AND R.NU_REG = PNumLinha
           AND NVL(R.IN_ERR_PRC, 'F') <> 'T'  ;
        --
        SELECT NVL(MAX(NU_SEQ),0) + 1
        INTO vNU_SEQ
        FROM PTC_MSS_REG_ERR R
        WHERE R.CD_ARQ = gFile.CD_ARQ
           AND R.NU_REG = PNumLinha;
        --
        INSERT INTO PTC_MSS_REG_ERR R
        (CD_ARQ        ,
         NU_REG        ,
         NU_SEQ        ,
         DS_MSG_ERR    ,
         CD_MSG_ERR    ,
         DS_MSG_AUX_ERR,
         TP_ERR)
        VALUES
        (gFile.CD_ARQ  ,
         PNumLinha     ,
         vNU_SEQ       ,
         PDS_MSG_ERR   ,
         PCD_MSG_ERR   ,
         PDS_MSG_AUX_ERR,
         PTP_ERR) ;      
    END;    
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'AddFileError');
    --
    --
    IF PNU_REG IS NOT NULL THEN
      --
      IF NVL(gFile.IN_VLD_DUP, 'F') = 'F' THEN
        --
        FOR Reg IN (SELECT C.ROWNUMBER
                    FROM (SELECT CR.NU_REG ROWNUMBER,
                                 LISTAGG('<' || CMC.DS_RTL_CTD || '>' || TRIM(CC.VL_CTD), '|') WITHIN GROUP (ORDER BY CR.NU_REG) AS ROWDATA
                            FROM PTC_MSS_REG CR,
                                 PTC_MSS_CTD CC,
                                 PTC_MSS_MDL_CTD CMC
                           WHERE CR.CD_ARQ      = gFile.CD_ARQ
                             AND CR.NU_REG      = PNU_REG
                             AND CR.CD_ARQ      = CC.CD_ARQ
                             AND CR.NU_REG      = CC.NU_REG
                             AND IN_KEY_VLR <> 'LINE_NUMBER'
                             --AND NVL(CR.IN_ERR_PRC, 'F') = 'F'  -- somente linhas que não tenham erro
                             AND CMC.CD_MDL_CTD = CC.CD_MDL_CTD
                           GROUP BY CR.NU_REG) C
                    WHERE C.ROWDATA = (SELECT LISTAGG('<' || XMC.DS_RTL_CTD || '>' || TRIM(XC.VL_CTD), '|') WITHIN GROUP (ORDER BY XC.NU_REG)
                                        FROM PTC_MSS_CTD XC,
                                             PTC_MSS_MDL_CTD XMC
                                       WHERE XC.CD_ARQ = gFile.CD_ARQ
                                         AND XC.NU_REG = PNU_REG
                                         AND XC.CD_MDL_CTD = XMC.CD_MDL_CTD
                                         AND IN_KEY_VLR <> 'LINE_NUMBER')) LOOP
        -- Linha do erro
        InsertError(Reg.Rownumber);
        --
        -- Linha pai do erro
        vDetailMainLine:= DetailMainLine(Reg.Rownumber);
        --
        IF vDetailMainLine <> Reg.Rownumber THEN
          --
          InsertError(vDetailMainLine);
          --
        END IF;
        --
        --  
      END LOOP;
      --
    ELSE
        --
        UPDATE PTC_MSS_REG R
           SET R.IN_ERR_PRC = 'T'
         WHERE R.CD_ARQ = gFile.CD_ARQ
           --AND R.NU_REG = PNU_REG
           AND NVL(R.IN_ERR_PRC, 'F') = 'T';
        --
        SELECT NVL(MAX(NU_SEQ),0) + 1
        INTO vNU_SEQ
        FROM PTC_MSS_REG_ERR R
        WHERE R.CD_ARQ = gFile.CD_ARQ
           AND R.NU_REG = PNU_REG;
        --
        INSERT INTO PTC_MSS_REG_ERR R
        (CD_ARQ        ,
         NU_REG        ,
         NU_SEQ        ,
         DS_MSG_ERR    ,
         CD_MSG_ERR    ,
         DS_MSG_AUX_ERR,
         TP_ERR)
        VALUES
        (gFile.CD_ARQ  ,
         PNU_REG ,
         vNU_SEQ       ,
         PDS_MSG_ERR   ,
         PCD_MSG_ERR   ,
         PDS_MSG_AUX_ERR,
         PTP_ERR) ; 
         --
      END IF;
      --
    ELSE
      --
      UPDATE PTC_MSS_REG R
         SET R.IN_ERR_PRC = 'T'
       WHERE R.CD_ARQ = gFile.CD_ARQ
         AND NVL(R.IN_ERR_PRC, 'F') <> 'T' ;
      --
      FOR E IN (SELECT *
                FROM PTC_MSS_REG R
                WHERE R.CD_ARQ = gFile.CD_ARQ) LOOP
        SELECT NVL(MAX(NU_SEQ),0) + 1
        INTO vNU_SEQ
        FROM PTC_MSS_REG_ERR R
        WHERE R.CD_ARQ = gFile.CD_ARQ
           AND R.NU_REG = E.NU_REG;
        --
        INSERT INTO PTC_MSS_REG_ERR R
        (CD_ARQ        ,
         NU_REG        ,
         NU_SEQ        ,
         DS_MSG_ERR    ,
         CD_MSG_ERR    ,
         DS_MSG_AUX_ERR,
         TP_ERR)
        VALUES
        (gFile.CD_ARQ  ,
         E.NU_REG ,
         vNU_SEQ       ,
         PDS_MSG_ERR   ,
         PCD_MSG_ERR   ,
         PDS_MSG_AUX_ERR,
         PTP_ERR) ; 
         --
      END LOOP; 
      --  
    END IF;
    --
    COMMIT;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      RAISE EProcessTotalException;
      --
  END;
  --
  --
  ------------------------------------------------------
  -- Processa erro para o arquivo/linha de arquivo
  ------------------------------------------------------
  PROCEDURE ProcessError( pErrorCode  IN NUMBER,
                          pErrorMessage IN VARCHAR2 DEFAULT NULL,
                          pAuxMessage IN VARCHAR2,
                          pErrorType  IN VARCHAR2,     -- ERR/EXC
                          pErrorLevel IN VARCHAR2) IS  -- REG/ARQ/NULL
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'ProcessError');
    --    
    --
    IF pErrorLevel IS NULL THEN
      RAISE ESkipProcess;
      --
    ELSIF pErrorLevel = 'REG' THEN
      --
      gData(gFile.NU_REG).Erros:= 'T';  
      -- 
      AddFileError(PNU_REG       => gFile.NU_REG,
                 PCD_MSG_ERR     => pErrorCode, 
                 PDS_MSG_ERR     => pErrorMessage,
                 PDS_MSG_AUX_ERR => pAuxMessage,
                 PTP_ERR         => pErrorType);       
      --
      IF pErrorType = 'ERR' THEN
        RAISE EProcessError;
      ELSE
        RAISE EProcessException; 
      END IF;
      --
    ELSIF pErrorLevel = 'ARQ' THEN
      --
      AddFileError(PNU_REG       => 0,--gFile.NU_REG,
                 PCD_MSG_ERR     => pErrorCode, 
                 PDS_MSG_ERR     => pErrorMessage,
                 PDS_MSG_AUX_ERR => pAuxMessage,
                 PTP_ERR         => pErrorType); 
      --           
      IF pErrorType = 'ERR' THEN
        RAISE EProcessTotalError;
      ELSE
        RAISE EProcessTotalException; 
      END IF;
    END IF;
    --
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);    
    --
/*  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      RAISE EProcessTotalException; */
      --
  END;
  --                                                  
  --
  -----------------------------------------------------
  -- Retorna modelo de conteúdo conforme label
  -----------------------------------------------------
  FUNCTION GetModelContentFromLabel(pCD_MDL_REG   PTC_MSS_MDL_REG.CD_MDL_REG%TYPE,
                                    pLabel        VARCHAR2) RETURN NUMBER IS
    --
    vModule VARCHAR2(100);
    vAction VARCHAR2(100);      
    --
    vCD_MDL_CTD    PTC_MSS_MDL_CTD.CD_MDL_CTD%TYPE;
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'GetModelContentFromLabel');    
    --
    SELECT C.CD_MDL_CTD
      INTO vCD_MDL_CTD
      FROM PTC_MSS_MDL_CTD C
     WHERE C.DS_RTL_CTD = pLabel
       AND C.CD_MDL_REG = pCD_MDL_REG  
       AND EXISTS (SELECT 1 
                     FROM PTC_MSS_MDL_REG   R
                    WHERE R.CD_MDL_ARQ IN (SELECT A.CD_MDL_ARQ
                                             FROM PTC_MSS_MDL_ARQ   A,
                                                  PTC_MSS_MDL_REG   R
                                            WHERE A.CD_MDL_ARQ = R.CD_MDL_ARQ
                                              AND R.CD_MDL_REG = pCD_MDL_REG));
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);    
    --
    RETURN vCD_MDL_CTD;
    --
  END GetModelContentFromLabel;  
  --
  --
  ------------------------------------------------------
  -- Carrega linhas d arquivo
  ------------------------------------------------------
  PROCEDURE CarregarLinhas IS
    --
    CURSOR cLines IS
      SELECT MIN(ROWNUMBER) ROWNUMBER,
             ID_CTD_REG,
             TIPOREG,
             ROWDATA,
             IN_VLD_DUP,
             NM_PRC_REG
      FROM (SELECT R.NU_REG ROWNUMBER,
                   R.CD_MDL_REG TIPOREG,
                   MR.ID_CTD_REG,
                   MR.NM_PRC_REG,
                   MA.IN_VLD_DUP,
                   LISTAGG('<' || MC.DS_RTL_CTD || '>' || TRIM(C.VL_CTD), '|') WITHIN GROUP (ORDER BY R.NU_REG) AS ROWDATA
                FROM ptc_mss_REG      R,
                     PTC_mss_MDL_REG  MR,
                     ptc_mss_CTD      C,
                     ptc_mss_MDL_CTD  MC,
                     PTC_mss_ARQ      A,
                     PTC_mss_MDL_ARQ  MA
               WHERE A.CD_ARQ      = R.CD_ARQ 
                 AND MA.CD_MDL_ARQ = A.CD_MDL_ARQ
                 AND R.CD_ARQ      = gFile.CD_ARQ
                 AND MR.CD_MDL_REG = R.CD_MDL_REG
                 AND C.CD_ARQ      = R.CD_ARQ      
                 AND C.NU_REG      = R.NU_REG      
                 AND MC.CD_MDL_CTD = C.CD_MDL_CTD
               GROUP BY R.NU_REG, R.CD_MDL_REG, MR.NM_PRC_REG, MR.ID_CTD_REG, NM_PRC_REG, MA.IN_VLD_DUP)
     GROUP BY ID_CTD_REG, TIPOREG, ROWDATA, NM_PRC_REG, IN_VLD_DUP
     ORDER BY ROWNUMBER;
    --
    rLines   cLines%ROWTYPE;
    --
    --
    CURSOR cTypes IS
      SELECT MC.CD_MDL_REG,
             MC.DS_RTL_CTD,
             MC.DS_CTD,
             MC.TP_DAD,
             MC.DS_FMT_DAD,
             MC.NU_TAM_MAX,
             MC.NU_PCS,
             MC.IN_OBR,
             MC.CD_LST_VLR
        FROM ptc_mss_MDL_CTD    MC,
             PTC_mss_MDL_REG   MR,
             ptc_mss_REG        R
       WHERE MC.CD_MDL_REG = MR.CD_MDL_REG
         AND MR.CD_MDL_REG = R.cd_mdl_reg
         AND R.CD_ARQ      = gFile.CD_ARQ;
    --
    vModule VARCHAR2(100);
    vAction VARCHAR2(100);
    --
  BEGIN
    --
    vTrack:= 'ler módulo do programa';
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'CarregarLinhas');
    --
    --
    vTrack:= 'abrir cursor cLines';
    OPEN cLines;
    FETCH cLines INTO rLines;
    --
    IF cLines%ROWCOUNT = 0 THEN
      --
      RAISE ESkipProcess;
      --
    END IF;  
    --
    --
    vTrack:= 'popular o array gTypes';
    --
    gTypes.DELETE;
    FOR rTypes IN CTypes LOOP
      gTypes(rTypes.CD_MDL_REG).Conteudo(rTypes.DS_RTL_CTD).CD_MDL_REG       := rTypes.CD_MDL_REG; 
      gTypes(rTypes.CD_MDL_REG).Conteudo(rTypes.DS_RTL_CTD).DataType         := rTypes.TP_DAD;
      gTypes(rTypes.CD_MDL_REG).Conteudo(rTypes.DS_RTL_CTD).DataFormat       := rTypes.DS_FMT_DAD;
      gTypes(rTypes.CD_MDL_REG).Conteudo(rTypes.DS_RTL_CTD).DataSize         := rTypes.NU_TAM_MAX;
      gTypes(rTypes.CD_MDL_REG).Conteudo(rTypes.DS_RTL_CTD).DataPrecision    := rTypes.NU_PCS;
      gTypes(rTypes.CD_MDL_REG).Conteudo(rTypes.DS_RTL_CTD).Required         := rTypes.IN_OBR;
      gTypes(rTypes.CD_MDL_REG).Conteudo(rTypes.DS_RTL_CTD).ValuesListId     := rTypes.CD_LST_VLR;
      gTypes(rTypes.CD_MDL_REG).Conteudo(rTypes.DS_RTL_CTD).FieldDescription := rTypes.DS_CTD;
    END LOOP;

    --      
    vTrack:= 'popular o array gData';
    --
    LOOP
      --
      EXIT WHEN cLines%NOTFOUND;
      --
      gData(rLines.ROWNUMBER).Linha        := rLines.Rownumber;
      gData(rLines.ROWNUMBER).Identificador:= rLines.ID_CTD_REG;
      gData(rLines.ROWNUMBER).Conteudo     := rLines.ROWDATA;
      gData(rLines.ROWNUMBER).Processamento:= rLines.NM_PRC_REG;
      gData(rLines.ROWNUMBER).CD_MDL_REG   := rLines.TIPOREG;
      --       
      FETCH cLines INTO rLines;
      --
    END LOOP;
    --
    CLOSE cLines;
    --
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN ESkipProcess THEN
      NULL;
    --
    WHEN OTHERS THEN  
      RAISE;
      /*pCOD_RET  := SQLCODE;
      pMSG_RET  := SQLERRM;
      pMSG_USER := WT_UTILITY_PKG.GetMessage(SQLCODE);
    */ 
     --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
  END;
  --
  --
  ------------------------------------------------------
  -- Carrega valores de uma linha de arquivo
  ------------------------------------------------------
  PROCEDURE CarregarValores(pNumLinha NUMBER, pProcedure OUT VARCHAR2, pValidar BOOLEAN DEFAULT FALSE) IS 
   --
    vIndex        INTEGER;
    vContent      VARCHAR2(4000) := NULL;
    --
    vModule VARCHAR2(100);
    vAction VARCHAR2(100);
    --
    pLine        VARCHAR2(4000);
    vCD_MDL_REG  PTC_mss_MDL_REG.CD_MDL_REG%TYPE;
    vCampo       ptc_mss_MDL_CTD.DS_RTL_CTD%TYPE;
    vNumero      NUMBER;
    vData        DATE;
    vDateFormat  VARCHAR2(100);
    vReturnError NUMBER;
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'GetContent');
    --
    --Identificar registro
    vTrack:= 'ler linha de valores';
    --
    pLine:= gData(pNumLinha).Conteudo;
    pProcedure:= gData(pNumLinha).Processamento;
    --
    vCD_MDL_REG:= gData(pNumLinha).CD_MDL_REG;
    --
    vCampo:= gTypes(vCD_MDL_REG).Conteudo.first;
    --
    WHILE vCampo IS NOT NULL LOOP
      BEGIN
        --
        vIndex := INSTR(PLine, '<' || TRIM(vCampo) || '>');
        --
        IF vIndex > 0 THEN
          --
          vContent := SUBSTR(PLine, vIndex + Length(TRIM(vCampo)) + 2);
          --
          IF INSTR(vContent, '|') > 0 THEN
            --
            vContent := SUBSTR(vContent, 1, INSTR(vContent, '|') - 1);
            --
          END IF;
          --
          --
          vTrack:= 'validar campo '|| vCampo;
          --
          IF gTypes(vCD_MDL_REG).Conteudo(vCampo).Required = 'T' AND vContent IS NULL THEN
             --
             vReturnError:= 182183;
             --
          END IF;
                  
          --
          --
          IF gTypes(vCD_MDL_REG).Conteudo(vCampo).DataType = 'D' THEN
            --
            SELECT MAX(P.VALUE)
              INTO vDateFormat
              FROM V$NLS_PARAMETERS P
             WHERE P.PARAMETER = 'NLS_DATE_FORMAT';
            --
            -- Validação de campo Date
            BEGIN
              --
              SELECT TO_DATE(vContent, NVL(gTypes(vCD_MDL_REG).Conteudo(vCampo).DataFormat, vDateFormat))
                INTO vData
                FROM DUAL;
              --
            EXCEPTION
              --
              WHEN OTHERS THEN
               --
               vReturnError:= 182184; 
               RAISE EProcessError;
               --              
            END;          
            --
            gValores(vCampo).DateValue:= TO_DATE(vContent, gTypes(vCD_MDL_REG).Conteudo(vCampo).DataFormat); 
          --
          --  
          ELSIF gTypes(vCD_MDL_REG).Conteudo(vCampo).DataType = 'N' THEN
            --  Para campos numéricos, elimina o "." e a "," para determinação do tamanho
            IF gTypes(vCD_MDL_REG).Conteudo(vCampo).DataSize < LENGTH(REPLACE(REPLACE(vContent,'.',''),',',''))  THEN
              --
              vReturnError:= 182331; 
              RAISE EProcessError;
              --              
            END IF;
            --
            -- Validação de campo numérico
            BEGIN
              --
              SELECT TO_NUMBER(vContent)
              INTO vNumero
              FROM DUAL;
              --
            EXCEPTION
              --
              WHEN OTHERS THEN
                --
                vReturnError:= 182184; 
                RAISE EProcessError;
                --
            END;          
            --
            gValores(vCampo).NumberValue:= TO_NUMBER(vContent);
            IF NVL(gTypes(vCD_MDL_REG).Conteudo(vCampo).DataPrecision,0) > 0 THEN
              gValores(vCampo).NumberValue:= gValores(vCampo).NumberValue;
            END IF;
            gValores(vCampo).StringValue:= TO_CHAR(gValores(vCampo).NumberValue);          
          --
          --  
          ELSE --gTypes(vCD_MDL_REG).Conteudo(vCampo).DataType = 'A' THEN
            --
            IF  gTypes(vCD_MDL_REG).Conteudo(vCampo).DataSize < LENGTH(vContent) THEN
              --
              vReturnError:= 182331; 
              RAISE EProcessError;
              --                 
            END IF;
            --   
            gValores(vCampo).StringValue:= vContent;
            --
          END IF;    
        --
        ELSE
          gValores(vCampo).DateValue:= NULL;
          gValores(vCampo).StringValue:= NULL;
          gValores(vCampo).NumberValue:= NULL;
        END IF;
        --
        --
      EXCEPTION
        --
        WHEN OTHERS THEN
          --
          pProcedure:= NULL;
          --
          IF pValidar THEN
            --
            IF vReturnError IS NULL THEN
              vReturnError:= SQLCODE;
            END IF;
            --       
             
            AddFileError(PNU_REG   => pNumLinha,
                   PCD_MSG_ERR     => vReturnError, 
                   PDS_MSG_AUX_ERR => 'Erro ao '||vTrack,
                   PTP_ERR         => 'ERR'); 
            --
          END IF;       
      END;
      --        
      vCampo:= gTypes(vCD_MDL_REG).Conteudo.Next(vCampo);
      --
         
    END LOOP;
    --
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      RAISE;
      --
  END ;
  --
  --
  ------------------------------------------------------
  -- Carrega valores de retorno de uma linha de arquivo
  ------------------------------------------------------
  PROCEDURE CarregarValoresRetorno(pNumLinha NUMBER, PCD_MDL_REG_RPT PTC_MSS_MDL_REG_RPT.CD_MDL_REG_RPT%TYPE ) IS 
   --
   vDS_RTL_CTD PTC_MSS_MDL_CTD_RPT.DS_RTL_CTD%TYPE;
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'GetContent');
    --
    --Identificar registros de respostas
    FOR Ctd IN (SELECT P.DS_RTL_CTD, P.VL_CTD
                FROM PTC_MSS_CTD_PRC P
                WHERE P.CD_ARQ = gFile.CD_ARQ
                  AND P.NU_REG = pNumLinha) LOOP
      --  
      gValores(Ctd.DS_RTL_CTD).StringValue:= Ctd.Vl_Ctd;            
      --
    END LOOP;
    --
    -- buscar erros
    SELECT  MIN(E.DS_RTL_CTD)
    INTO vDS_RTL_CTD
    FROM PTC_MSS_MDL_CTD_RPT E
    WHERE E.CD_MDL_REG_RPT = PCD_MDL_REG_RPT
      AND E.IN_ERR = 'T';
    
    IF vDS_RTL_CTD IS NOT NULL THEN
      --
      SELECT LPAD(NVL(MIN(E.CD_MSG_ERR), '0'), 4, '0')
      INTO gValores(vDS_RTL_CTD).StringValue
      FROM PTC_MSS_REG R, PTC_MSS_REG_ERR E
      WHERE R.CD_ARQ = gFile.CD_ARQ
        AND R.NU_REG = pNumLinha
        AND E.CD_ARQ = R.CD_ARQ
        AND E.NU_REG = R.NU_REG; 
      --   
    END IF;    
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      NULL;
      --
  END ;
  --
  --
  ------------------------------------------------------
  -- Procedure que analisa retorno Sunnel 
  ------------------------------------------------------
  PROCEDURE ValidateSunnelReturn(pEFFECT         IN VARCHAR2,
                              pRESPONSECODE      IN NUMBER,
                              pRESPONSEMESSAGE   IN VARCHAR2,
                              pCOD_RET      OUT NOCOPY NUMBER,
                              pMSG_RET      OUT NOCOPY VARCHAR2,
                              pTIP_RET      OUT NOCOPY VARCHAR2) IS
  BEGIN
      pTIP_RET:= 'NORMAL';
      --
      IF pEFFECT IS NULL THEN
        --
        pCOD_RET:= 182191;
        pMSG_RET:= WT_UTILITY_PKG.GetMessage(182191);

        pTIP_RET:= 'EXCEPTION';
        --
      ELSIF NVL(pEFFECT, 'X') <> 'R' AND pRESPONSEMESSAGE IS NOT NULL THEN
        --
        pCOD_RET:= 182655;
        pMSG_RET:= WTMX_UTILITY_PKG.GetMessage(pCOD_RET);

        pTIP_RET:= 'EXCEPTION';
        --
      ELSIF pEFFECT = 'R' AND pRESPONSEMESSAGE IS NULL THEN
        --
        pCOD_RET:= 182637;
        pMSG_RET:= WTMX_UTILITY_PKG.GetMessage(pCOD_RET);

        pTIP_RET:= 'EXCEPTION';
       --
      ELSIF pEFFECT = 'R' AND pRESPONSEMESSAGE IS NOT NULL THEN
        --
        pMSG_RET:= pRESPONSEMESSAGE;
        pCOD_RET:= NVL(WTMX_UTILITY_PKG.GetSunnelError(pRESPONSEMESSAGE ,18),183058);
        --
      ELSIF pEFFECT = 'P' THEN
        --
        NULL;
        --
      ELSE
        --
        pMSG_RET:= pRESPONSEMESSAGE;
        pCOD_RET:= NVL(WTMX_UTILITY_PKG.GetSunnelError(pRESPONSEMESSAGE ,18),183058);
 
        pTIP_RET:= 'EXCEPTION';
        --
      END IF;
  END;  
  --
  --
  ------------------------------------------------------
  -- Valida nome de interface
  ------------------------------------------------------
  FUNCTION ValidateInterfaceName (PLabelDefault      VARCHAR2) RETURN NUMBER IS
    --
    vReturnCode          INTEGER;
    vDSInterface         VARCHAR2(50);
    --
    vModule VARCHAR2(100);
    vAction VARCHAR2(100);
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'ValidateInterfaceName');
    --
    -- 1.01 (inicio)
    SELECT C.DS_RTL_CTD
    INTO vDSInterface
    FROM PTC_MSS_MDL_CTD C
    WHERE C.IN_KEY_VLR = 'INTERFACE_NAME'
      AND C.CD_MDL_REG IN (SELECT R.CD_MDL_REG FROM PTC_MSS_MDL_REG R
                           WHERE R.CD_MDL_ARQ = gFile.CD_MDL_ARQ);
    
    vDSInterface := gValores(vDSInterface).StringValue;
    -- 1.01 (fim)
    --
    SELECT DECODE(count(1),1,0, 2548 ) INTO vReturnCode
    FROM DUAL
    WHERE  vDSInterface LIKE replace(PLabelDefault,'–', '%') OR -- 1.01
           vDSInterface IS NULL; 
       
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    RETURN vReturnCode;
    --
  END;
  --
  --
  ---------------------------------------------------
  -- Analisa status atual do arquivo
  ---------------------------------------------------
  PROCEDURE AtualizarStatusArquivo IS
    vQtdeLinSucesso      NUMBER;
    vQtdeLinErro         NUMBER; 
  BEGIN
    --
    IF gFile.ErroTotal = 'T' THEN
      gFile.CD_STA_CMM := 80;
      RETURN;
    END IF;
    
    FOR Linha IN (SELECT M.CD_MDL_REG
                FROM PTC_mss_MDL_REG M
                WHERE M.CD_MDL_ARQ = gFile.CD_MDL_ARQ
                  AND M.TP_MDL_REG = 'D'
                  AND M.CD_MDL_REG_PAI = (SELECT MIN(H.CD_MDL_REG)
                                          FROM PTC_mss_MDL_REG H
                                          WHERE H.CD_MDL_ARQ = gFile.CD_MDL_ARQ
                                            AND H.TP_MDL_REG = 'H')) LOOP
      -- 1.01 (inicio correção)                                     
      SELECT NVL(vQtdeLinSucesso,0) + SUM(DECODE(NVL(REG.IN_ERR_PRC, 'F'), 'F', 1, 0)) OK,
             NVL(vQtdeLinErro,0)    + SUM(DECODE(NVL(REG.IN_ERR_PRC, 'F'), 'T', 1, 0)) ERRO
       INTO vQtdeLinSucesso, vQtdeLinErro
       FROM PTC_mss_REG      REG
      WHERE REG.CD_ARQ     = gFile.CD_ARQ
        AND REG.CD_MDL_REG = Linha.Cd_Mdl_Reg;
      -- 1.01 (fim correção) 
      --  
    END LOOP;    
    --
    -- Atualiza o status do Dominio do Arquivo para "Processado com Sucesso"
    IF gFile.TP_PRC = 'P' THEN
      IF vQtdeLinErro = 0 AND vQtdeLinSucesso = 0 THEN
        gFile.CD_STA_CMM := 80;
      ELSIF vQtdeLinErro > 0 AND vQtdeLinSucesso > 0 THEN
        gFile.CD_STA_CMM := 81;
      ELSIF vQtdeLinErro > 0 AND vQtdeLinSucesso = 0 THEN
        gFile.CD_STA_CMM := 80;
      ELSIF vQtdeLinErro = 0 AND vQtdeLinSucesso > 0 THEN
        gFile.CD_STA_CMM := 79;
      END IF;  
      --  
    ELSE    
      IF vQtdeLinErro = 0 AND vQtdeLinSucesso = 0 THEN
        gFile.CD_STA_CMM := 80;
      ELSIF vQtdeLinErro = 0 THEN
        gFile.CD_STA_CMM := 79;
      ELSE
        gFile.CD_STA_CMM := 80;
      END IF;  
      --
    END IF;
    --   
  END;
  --
  ----------------------------------------
  -- Atualiza Status de Arquivo
  ----------------------------------------
  PROCEDURE FileUpdateStatus( pCD_ARQ     IN PTC_MSS_ARQ.CD_ARQ%TYPE,
                              pDT_INI_PRC IN PTC_MSS_ARQ.DT_INI_PRC%TYPE,
                              pDT_FIM_PRC IN PTC_MSS_ARQ.DT_FIM_PRC%TYPE,
                              pCD_STA_CMM IN PTC_MSS_ARQ.CD_STA_CMM%TYPE) IS
    --
    PRAGMA AUTONOMOUS_TRANSACTION;
    --
    vModule VARCHAR2(100);
    vAction VARCHAR2(100);
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'FileUpdateStatus');
    --  
    --
    UPDATE PTC_mss_ARQ
       SET DT_INI_PRC = NVL(DT_INI_PRC, pDT_INI_PRC), -- se a data inicial ja existir, mantem
           DT_FIM_PRC = pDT_FIM_PRC,
           CD_STA_CMM = NVL(pCD_STA_CMM, 75)
     WHERE CD_ARQ = pCD_ARQ;
    --
    -- Se o tipo de ação for informado, limpa o codigo do servidor (Validate/Apply)
    --
    COMMIT;
    --
    OperationLog(PCD_ARQ     => PCD_ARQ,
                 PCD_STA_CMM => PCD_STA_CMM);
    --
    --    
    UpdateServiceMonitor;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      ROLLBACK;
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      RAISE EProcessTotalException;
      --
  END;  
  --
  --
  ----------------------------------------
  -- Deletar informações do processamento anterior
  ----------------------------------------
  PROCEDURE DeletarProcessamentoAnterior( pCD_ARQ     IN PTC_MSS_ARQ.CD_ARQ%TYPE) IS
    --
    PRAGMA AUTONOMOUS_TRANSACTION;
    --
  BEGIN
    --
    UPDATE ptc_mss_reg E SET E.IN_ERR_PRC=NULL WHERE CD_ARQ=pCD_ARQ;
    DELETE ptc_mss_reg_err WHERE CD_ARQ=pCD_ARQ;
    DELETE Ptc_Mss_Ctd_Prc WHERE CD_ARQ=pCD_ARQ;  
    --
    COMMIT;
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      NULL;
      --
  END;  
  --
  --  
  ------------------------------------------------------
  -- Identifica ultima linha do registro  1.01 (correção) 
  ------------------------------------------------------
  FUNCTION RegisterLastLine(PNU_REG      IN PTC_MSS_REG.NU_REG%TYPE) RETURN NUMBER IS
    vMdlReg     PTC_MSS_MDL_REG.CD_MDL_REG%TYPE;
    vMdlRegPai  PTC_MSS_MDL_REG.CD_MDL_REG_PAI%TYPE;
    vMdlRegTip  PTC_MSS_MDL_REG.TP_MDL_REG%TYPE;
    vMdlRegFim  PTC_MSS_MDL_REG.CD_MDL_REG%TYPE;
  BEGIN
    --
    SELECT L.CD_MDL_REG, R.TP_MDL_REG
    INTO vMdlReg, vMdlRegTip
    FROM PTC_MSS_REG L, PTC_MSS_MDL_REG R
    WHERE L.CD_ARQ     = gFile.CD_ARQ
      AND L.NU_REG     = PNU_REG
      AND R.CD_MDL_ARQ = gFile.CD_MDL_ARQ
      AND R.CD_MDL_REG = L.CD_MDL_REG;
    --
    IF vMdlRegTip <> 'D' THEN
      RETURN PNU_REG;
    END IF;
    --
    --
    SELECT  R.CD_MDL_REG
    INTO vMdlRegPai
    FROM PTC_MSS_MDL_REG R, PTC_MSS_MDL_REG P
    WHERE R.CD_MDL_ARQ = gFile.CD_MDL_ARQ
      AND P.CD_MDL_ARQ (+)= R.CD_MDL_ARQ
      AND P.CD_MDL_REG (+)= R.CD_MDL_REG_PAI
      AND R.TP_MDL_REG    = 'D'
      AND ROWNUM= 1
    ORDER BY R.NU_ORD_PRC;
    --
    IF vMdlRegPai IS NULL THEN   
      RETURN PNU_REG;
    END IF;
    --
    --         
    vMdlRegFim:= PNU_REG;
    FOR Lin IN (SELECT l.nu_reg, R.CD_MDL_REG_PAI
                FROM PTC_MSS_REG L, PTC_MSS_MDL_REG R
                WHERE L.CD_ARQ     = gFile.CD_ARQ
                  AND L.NU_REG     > PNU_REG
                  AND R.CD_MDL_ARQ = gFile.CD_MDL_ARQ
                  AND R.CD_MDL_REG = L.CD_MDL_REG
                ORDER BY 1) LOOP
      --
      IF NVL(Lin.CD_MDL_REG_PAI, -1 ) <> vMdlRegPai THEN
         --
         EXIT;
         --
      END IF;
      --            
      vMdlRegFim:= Lin.Nu_Reg;
      --
    END LOOP;
    --
    RETURN vMdlRegFim;
  END;
  --
  ------------------------------------------------------
  -- Carrega campos retornados pelo processamento
  ------------------------------------------------------
  PROCEDURE AddFieldResponse(PNU_REG      IN PTC_MSS_REG.NU_REG%TYPE,
                            PDS_RTL_CTD  IN ptc_MSS_MDL_CTD.DS_RTL_CTD%TYPE,
                            PCONTEUDO    IN VARCHAR2) IS
    --
    PRAGMA AUTONOMOUS_TRANSACTION;
    --
    vModule VARCHAR2(100);
    vAction VARCHAR2(100);
    --
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'AddFileResponse');
    --
    --
    INSERT INTO PTC_MSS_CTD_PRC
    (cd_arq     ,
     nu_reg     ,
     ds_rtl_ctd ,
     vl_ctd     )
    VALUES
    (gFile.CD_ARQ,     
     PNU_REG,     
     PDS_RTL_CTD,
     PCONTEUDO);  
    --
    COMMIT;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      RAISE EProcessTotalException;
      --
  END;
  --  
  --
  --  
  ----------------------------------------
  -- Insere dados de arquivo recebido
  ----------------------------------------
  PROCEDURE MassiveLoadFileCreate(pCD_ARQ     OUT PTC_mss_ARQ.CD_ARQ%TYPE,
                                  pCD_MDL_ARQ IN PTC_mss_ARQ.CD_MDL_ARQ%TYPE,
                                  pNM_ARQ     IN PTC_mss_ARQ.NM_ARQ%TYPE,
                                  pDT_SOL     IN  PTC_mss_ARQ.DT_SOL%TYPE,
                                  pNU_TOT_LIN IN PTC_mss_ARQ.NU_TOT_LIN%TYPE,
                                  pMSG_USER   OUT NOCOPY VARCHAR2,
                                  pCOD_RET    OUT NOCOPY NUMBER,
                                  pMSG_RET    OUT NOCOPY VARCHAR2) IS
    --
    vModule     VARCHAR2(100);
    vAction     VARCHAR2(100);
    vQtde       NUMBER;
    --
    vPermiteAgendamento     PTC_MSS_MDL_ARQ.IN_PMI_AGD%TYPE;
    vOLTP                   PTC_MSS_MDL_ARQ.IN_PRC_OLTP%TYPE;
    vStatusInicial          PTC_STA_CMM.CD_STA_CMM%TYPE;   
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'MassiveLoadFileCreate');
    --
    -- Verifica se o arquivo informado ja existe
    SELECT COUNT(1)
      INTO vQtde
      FROM PTC_MSS_ARQ
     WHERE UPPER(NM_ARQ) = UPPER(pNM_ARQ);
    --
    IF  vQtde  > 0 THEN
        pCOD_RET  := 152537;
        pMSG_USER := WT_UTILITY_PKG.GetMessage(pCOD_RET);
        pMSG_RET  := pMSG_USER;
        DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
        RETURN;
      --
    END IF;
    --
    --
    SELECT IN_PMI_AGD, IN_PRC_OLTP
      INTO vPermiteAgendamento, vOLTP
      FROM PTC_mss_MDL_ARQ 
     WHERE CD_MDL_ARQ = pCD_MDL_ARQ;
    --
    vStatusInicial := 74;
    --
    --
    SELECT SEQ_mss_ARQ.NextVal
      INTO pCD_ARQ
      FROM DUAL;
    --
    INSERT INTO PTC_mss_ARQ
      (CD_ARQ,
       CD_MDL_ARQ,
       NM_ARQ,
       DT_SOL,
       NU_TOT_LIN,
       CD_STA_CMM,
       IN_PRC_OLTP
       )
    VALUES
      (pCD_ARQ,
       pCD_MDL_ARQ,
       pNM_ARQ,
       pDT_SOL,
       pNU_TOT_LIN,
       92,
       vOLTP);
    --
    --OperationLog(PCD_ARQ     => PCD_ARQ,
    --             PCD_STA_CMM	=> vStatusInicial);  
    --
    --
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
    IF  NVL(pCOD_RET, 0) <> 0 THEN
        RETURN;
    END IF;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  END MassiveLoadFileCreate;  
  --
  --
  ----------------------------------------
  -- Insere dados de registro do arquivo recebido
  ----------------------------------------
  PROCEDURE MassiveLoadRegisterCreate(pCD_ARQ     IN  PTC_mss_REG.CD_ARQ%TYPE,
                                      pCD_MDL_REG IN  PTC_mss_REG.CD_MDL_REG%TYPE,
                                      pNU_REG     IN  PTC_mss_REG.NU_REG%TYPE,
                                      pMSG_USER   OUT NOCOPY VARCHAR2,
                                      pCOD_RET    OUT NOCOPY NUMBER,
                                      pMSG_RET    OUT NOCOPY VARCHAR2) IS
    --
    vModule   VARCHAR2(100);
    vAction   VARCHAR2(100);
    --
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'MassiveLoadRegisterCreate');
    --
    INSERT INTO PTC_mss_REG
      (CD_ARQ,
       NU_REG,
       CD_MDL_REG)
    VALUES
      (pCD_ARQ,
       pNU_REG,
       pCD_MDL_REG);
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      pMSG_USER := WT_UTILITY_PKG.GetMessage(SQLCODE);
      pCOD_RET  := SQLCODE;
      pMSG_RET  := SQLERRM;
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
  END MassiveLoadRegisterCreate;
  --
  --
  ----------------------------------------
  -- Insere dados de conteúdo do arquivo recebido
  ----------------------------------------
  PROCEDURE MassiveLoadContentCreate(pCD_CTD     OUT PTC_mss_CTD.CD_CTD%TYPE,
                                     pCD_ARQ     IN  PTC_mss_CTD.CD_ARQ%TYPE,
                                     pNU_REG     IN  PTC_mss_CTD.NU_REG%TYPE,
                                     pCD_MDL_CTD IN  PTC_mss_CTD.CD_MDL_CTD%TYPE,
                                     pVL_CTD     IN  PTC_mss_CTD.VL_CTD%TYPE,
                                     pMSG_USER   OUT NOCOPY VARCHAR2,
                                     pCOD_RET    OUT NOCOPY NUMBER,
                                     pMSG_RET    OUT NOCOPY VARCHAR2) IS
    --
    vModule VARCHAR2(100);
    vAction VARCHAR2(100);
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'MassiveLoadContentCreate');
    --
    --
    SELECT NVL(MAX(CTD.CD_CTD), 0) + 1
      INTO pCD_CTD
      FROM PTC_mss_CTD  CTD
     WHERE CTD.CD_ARQ = pCD_ARQ
       AND CTD.NU_REG = pNU_REG;
    --
    INSERT INTO PTC_mss_CTD
      (CD_ARQ,
       NU_REG,
       CD_CTD,
       CD_MDL_CTD,
       VL_CTD)
    VALUES
      (pCD_ARQ,
       pNU_REG,
       pCD_CTD,
       pCD_MDL_CTD,
       pVL_CTD);
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      pMSG_USER := WT_UTILITY_PKG.GetMessage(SQLCODE);
      pCOD_RET  := SQLCODE;
      pMSG_RET  := SQLERRM;
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
  END MassiveLoadContentCreate;    
  --
  --  
  ----------------------------------------------------
  -- Rotina principal para executar a carga massiva
  ----------------------------------------------------
  PROCEDURE MassiveLoadExecute(PCD_ARQ IN ptc_mss_ARQ.CD_ARQ%TYPE) IS
    --
    vProcedure                 PTC_mss_MDL_REG.NM_PRC_REG%TYPE;
  BEGIN
    --
    vTrack:= 'ler modulo atual';
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'MassiveLoadExecute');
    --    
    --
    vTrack:= 'buscar dados do arquivo';
    gFile.CD_ARQ:= PCD_ARQ;
    SetFileData(PCD_ARQ => PCD_ARQ);
    --
    gFile.ErroTotal:= 'F';
    --
    -- Atualiza o status do Dominio do Arquivo para "Processando Validacao"
    vTrack:= 'definir status 83 para o arquivo';
    FileUpdateStatus( pCD_ARQ     => gFile.CD_ARQ,
                      pDT_INI_PRC => SYSDATE,
                      pDT_FIM_PRC => NULL,
                      pCD_STA_CMM => 83); -- Processando Validacao

    --
    -- Leitura das linhas do dominio 
    vTrack:= 'carregar linhas';
    --
    CarregarLinhas;
    --
    --
    -- Coleta os dados carregados
    vTrack:= 'percorrer linhas do arquivo';
    --
    IF gData.COUNT > 0 THEN
      --
      gFile.NU_REG := gData.FIRST;
      --
      WHILE gFile.NU_REG IS NOT NULL LOOP
        --
        BEGIN
          --
          --
          vTrack:= 'carregar valores';
          CarregarValores(gFile.NU_REG, vProcedure, TRUE);
          --
          vTrack:= 'executar procedure '|| vProcedure;
          --
          IF vProcedure IS NOT NULL THEN
              -- Chama a Procedure Especialista para processamento da Carga
            BEGIN
              --
              vTrack:= 'executar procedure de Auditoria'; -- 1.01 
              --
              Auditoria(vProcedure); -- 1.01 
              --
              EXECUTE IMMEDIATE 'BEGIN ' ||
                                   vProcedure || '; ' ||
                                'END;';
              --
              gData(gFile.NU_REG).Erros:= 'F';
              --
              vTrack:= 'aplicar/desfazer operações';
              --
              IF gFile.TP_PRC = 'P' THEN
                --
                IF gFile.TP_ACA = 'A' THEN
                  --
                  COMMIT;
                  --
                ELSE
                  --
                  ROLLBACK;
                END IF;
                --
              END IF;
              --      
            EXCEPTION
              WHEN ESkipProcess THEN
                 NULL;
              WHEN EProcessException THEN 
                
                ROLLBACK; 
                --
                gData(gFile.NU_REG).Erros:= 'T';
                --
                IF gFile.TP_PRC = 'F' THEN
                  gFile.ErroTotal:= 'T';
                  EXIT; 
                  --
                END IF;
                -- 
              WHEN EProcessError THEN  
                ROLLBACK; 
                --
                gData(gFile.NU_REG).Erros:= 'T';
                --
                IF gFile.TP_PRC = 'F' THEN
                  gFile.ErroTotal:= 'T';
                  EXIT; 
                  --
                END IF;
                --
              WHEN EProcessTotalException THEN  
                ROLLBACK;
                gFile.ErroTotal:= 'T';
                gData(gFile.NU_REG).Erros:= 'T';
                EXIT; 
              WHEN EProcessTotalError THEN
                ROLLBACK;
                gFile.ErroTotal:= 'T';
                gData(gFile.NU_REG).Erros:= 'T';
                EXIT;               
              WHEN OTHERS THEN
                ROLLBACK;
                gFile.ErroTotal:= 'T';
                gData(gFile.NU_REG).Erros:= 'T';
                EXIT;
                --
            END;
            --
          END IF;
          --
          vTrack:= 'ler proxima linha';
          gFile.NU_REG := gData.NEXT(gFile.NU_REG);
          --
          --
        END;
        --
      END LOOP;
      --
      --
      vTrack:= 'aplicar/desfazer operações';
      --
      IF gFile.TP_PRC = 'F' THEN -- 1.01 
        --
        IF gFile.TP_ACA = 'A' THEN
          --
          COMMIT;
          --
        ELSE
          --
          ROLLBACK;
        END IF;
        --
      END IF;
      --   
      AtualizarStatusArquivo;   
      --
      IF NVL(gFile.CD_STA_CMM,0) IN (79, 81) THEN
        --
        IF gFile.IN_PRC_INT = 'F' THEN --nao tem interface
          --
          vTrack:= 'definir status 86 para o arquivo';
          --
          --
          IF gFile.NM_PRC_FIN IS NOT NULL THEN
            --
            BEGIN
              --
              EXECUTE IMMEDIATE 'BEGIN ' ||
                                   gFile.NM_PRC_FIN || '; ' ||
                                'END;';        
              --
            EXCEPTION
              WHEN OTHERS THEN
                --
                NULL;-- O Q FAZER QDO DER ERRO NO FINAL?
                --                    
            END;
            --
          END IF;
          --
          --
          vTrack:= 'definir status 79/81 para o arquivo';
          --
          AtualizarStatusArquivo;
          --
          FileUpdateStatus( pCD_ARQ     => gFile.CD_ARQ,
                        pDT_INI_PRC => SYSDATE,
                        pDT_FIM_PRC => SYSDATE,
                        pCD_STA_CMM => gFile.CD_STA_CMM); -- Nada a Processar
          --    
          --   
        ELSE
          --
          vTrack:= 'definir status 78 para o arquivo';
          --
          FileUpdateStatus( pCD_ARQ     => gFile.CD_ARQ,
                        pDT_INI_PRC => SYSDATE,
                        pDT_FIM_PRC => NULL,
                        pCD_STA_CMM => 78); -- Processando Financeiro (Interface)
          --  
        END IF;
        --
      ELSE
        --
        vTrack:= 'definir status 80 para o arquivo';
        --
        FileUpdateStatus( pCD_ARQ     => gFile.CD_ARQ,
                      pDT_INI_PRC => SYSDATE,
                      pDT_FIM_PRC => SYSDATE,
                      pCD_STA_CMM => 80); -- Processando Financeiro (Interface)
        -- 
      END IF;
      --
    ELSE
      --
      vTrack:= 'definir status 80 para o arquivo';
      --
      FileUpdateStatus( pCD_ARQ     => gFile.CD_ARQ,
                    pDT_INI_PRC => SYSDATE,
                    pDT_FIM_PRC => NULL,
                    pCD_STA_CMM => 80); -- Nada a Processar      
      --  
    END IF;
    --
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    WHEN OTHERS THEN 
      --
      ROLLBACK;
      --
      vTrack:= 'definir status 80 para o arquivo';
      FileUpdateStatus( pCD_ARQ     => gFile.CD_ARQ,
                        pDT_INI_PRC => SYSDATE,
                        pDT_FIM_PRC => SYSDATE,
                        pCD_STA_CMM => 80); -- Erros
                              
      --
      ProcessError( pErrorCode   => 182190, 
                    pAuxMessage => 'Erro ao ' || vTrack ||': ' ||SQLERRM, 
                    pErrorType  => 'EXC',
                    pErrorLevel => 'ARQ');         
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
  END;
  --
  --
  ------------------------------------------------------
  -- Scheduler para carga massiva
  ------------------------------------------------------
  PROCEDURE MassiveLoadScheduler(PCD_ARQ IN PTC_MSS_ARQ.CD_ARQ%TYPE) IS
    --
    vModule            VARCHAR2(100);
    vAction            VARCHAR2(100);
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'MassiveLoadScheduler');
    --
    MassiveLoadExecute(PCD_ARQ     => PCD_ARQ); 
    --
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      ProcessError( pErrorCode   => SQLCODE, 
                    pAuxMessage => 'Erro ao executar MassiveLoadScheduler: ' ||SQLERRM, 
                    pErrorType  => 'EXC',
                    pErrorLevel => 'ARQ');         
      --
  END;
  --
  --
  ------------------------------------------------------
  -- Gera arquivo de resposta
  ------------------------------------------------------
  PROCEDURE MassiveLoadResponse(PCD_ARQ IN PTC_MSS_ARQ.CD_ARQ%TYPE) IS
  --
  vProcedure                 PTC_mss_MDL_REG.NM_PRC_REG%TYPE;
  vLinha    VARCHAR2(4000);
  --
    PROCEDURE FormatarLinha(PCD_MDL_REG_RPT PTC_MSS_MDL_REG_RPT.CD_MDL_REG_RPT%TYPE) IS
      --
     vConteudo VARCHAR2(4000); 
     eErro EXCEPTION;
    BEGIN
      --
      vLinha:= null;
      --
      FOR Ctd IN (SELECT TP_DAD, NU_TAM_MAX, NU_PCS, DS_FMT_DAD,
                         DS_RTL_CTD, IN_OBR, VL_PDR, Nu_Pos_Ini
                  FROM MX_ADM.PTC_MSS_MDL_CTD_RPT  
                  WHERE CD_MDL_REG_RPT = PCD_MDL_REG_RPT
                  ORDER BY Nu_Pos_Ini) LOOP

        vConteudo:= NULL;
        --
        IF NOT gValores.exists(Ctd.DS_RTL_CTD) AND Ctd.Vl_Pdr IS NULL THEN -- 1.02
          --
          IF Ctd.Tp_Dad = 'D' THEN
            vConteudo:= RPAD(' ', Ctd.Nu_Tam_Max, ' ' ); -- 1.01
          ELSIF Ctd.Tp_Dad = 'N'  THEN
            vConteudo:= LPAD('0', Ctd.Nu_Tam_Max, '0');
          ELSE  
            vConteudo:= RPAD(' ', Ctd.Nu_Tam_Max, ' ');
          END IF;

        ELSE
          IF Ctd.Vl_Pdr IS NOT NULL THEN          -- 1.02
            vConteudo := Ctd.Vl_Pdr;              -- 1.02
          ELSE                                    -- 1.02
            IF Ctd.Tp_Dad = 'D' THEN
              vConteudo:= TO_CHAR(gValores(Ctd.DS_RTL_CTD).DateValue, NVL(Ctd.DS_FMT_DAD, SUBSTR('DDMMYYYYHH24MISS',1,Ctd.Nu_Tam_Max)));
              vConteudo:= RPAD(vConteudo, Ctd.Nu_Tam_Max, ' ');
            ELSE
              vConteudo:= gValores(Ctd.DS_RTL_CTD).StringValue; 
            END IF;  
          END IF;                                 -- 1.02
          
          IF Ctd.Tp_Dad = 'N' and trim(vConteudo) is not null THEN
            vConteudo:= LPAD(NVL(vConteudo, '0'), Ctd.Nu_Tam_Max, '0');
          ELSE  
            vConteudo:= RPAD(NVL(vConteudo,' '), Ctd.Nu_Tam_Max, ' ');
          END IF;
        END IF;
        vLinha:= vLinha || vConteudo; 
        
      END LOOP;
      --
    END;
    --  
  --
  BEGIN
    --    
    vTrack:= 'ler modulo atual';
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'MassiveLoadExecute');
    -- 
    vTrack:= 'buscar texto das mensagens de erro do arquivo';
    --    
    UPDATE PTC_MSS_REG_ERR
    SET DS_MSG_ERR = WTMX_UTILITY_PKG.GetMessage(CD_MSG_ERR)   
    WHERE CD_ARQ = PCD_ARQ
      AND DS_MSG_ERR IS NULL;
    --
    vTrack:= 'buscar dados do arquivo';
    gFile.CD_ARQ:= PCD_ARQ;
    SetFileData(PCD_ARQ => PCD_ARQ);
    --
    CarregarLinhas;
    --
    FOR RPT in (SELECT DISTINCT A.CD_ARQ , M.CD_MDL_ARQ_RPT, M.NM_PRC_RPT
                         FROM PTC_mss_ARQ A, PTC_MSS_MDL_ARQ_RPT M
                        WHERE A.CD_ARQ = PCD_ARQ
                          AND M.CD_MDL_ARQ = A.CD_MDL_ARQ
                          AND M.CD_STA_CMM = 1
                          --AND M.NM_PRC_RPT IS NOT NULL
                          AND NOT EXISTS (SELECT 1 
                                          FROM PTC_MSS_ARQ_RPT R
                                          WHERE R.CD_ARQ = A.CD_ARQ
                                            AND R.CD_MDL_ARQ_RPT = M.CD_MDL_ARQ_RPT)) LOOP

      --
      INSERT INTO PTC_MSS_ARQ_RPT
      (
      cd_arq         ,
      cd_mdl_arq_rpt ,
      dt_ini_prc     
      )
      VALUES
      (RPT.CD_ARQ,
       RPT.CD_MDL_ARQ_RPT,
       SYSDATE
      );                                    
      --
      -- Leitura das linhas do dominio 
      vTrack:= 'carregar linhas';
      --
      FOR REG in (SELECT R.NU_REG, R.CD_MDL_REG, R.IN_ERR_PRC, CD_MDL_REG_RPT , X.NM_PRC_REG
                  FROM PTC_MSS_REG R, PTC_MSS_MDL_REG M, PTC_MSS_MDL_REG_RPT X
                  WHERE R.CD_ARQ = RPT.CD_ARQ
                    AND M.CD_MDL_REG = R.CD_MDL_REG
                    AND X.CD_MDL_REG = M.CD_MDL_REG
                  ORDER BY 1) LOOP
        --
        -- 1.02 (inicio)
        --
        vTrack:= 'executar procedure '|| REG.NM_PRC_REG;
        --        
        
        IF REG.NM_PRC_REG IS NOT NULL THEN
          BEGIN
            -- Carrega Valores
            EXECUTE IMMEDIATE 'BEGIN ' ||
                                 REG.NM_PRC_REG || '('||REG.NU_REG||', '||REG.CD_MDL_REG||'); ' ||
                              'END;';
            --
          EXCEPTION
            --           
            WHEN OTHERS THEN
              ROLLBACK;
              EXIT;
            --
          END;
        END IF; 
        -- 1.02 (fim)        
        --
        vTrack:= 'carregar valores';
        CarregarValores(REG.NU_REG, vProcedure);
        CarregarValoresRetorno(REG.NU_REG, REG.CD_MDL_REG_RPT);        
        --
        vTrack:= 'executar procedure '|| vProcedure;
        --
        IF RPT.NM_PRC_RPT IS NOT NULL THEN
          BEGIN
            -- Carrega Valores
            EXECUTE IMMEDIATE 'BEGIN ' ||
                                 RPT.NM_PRC_RPT || '('||REG.NU_REG||', '||REG.CD_MDL_REG||'); ' ||
                              'END;';
            --
          EXCEPTION
            --           
            WHEN OTHERS THEN
              ROLLBACK;
              EXIT;
            --
          END;
        END IF; 
        --
        --
        -- Formatar Linha do registro
        FormatarLinha(REG.CD_MDL_REG_RPT);
        
        -- INSERT
        INSERT INTO PTC_MSS_REG_RPT
        (cd_arq        ,
         cd_mdl_arq_rpt,
         nu_reg        ,
         vl_rpt        )
        VALUES 
        (PCD_ARQ       ,
         RPT.CD_MDL_ARQ_RPT,
         REG.NU_REG    ,
         vLinha        );
      END LOOP;
      --
      UPDATE PTC_MSS_ARQ_RPT R
      SET DT_FIM_PRC = SYSDATE
      WHERE CD_ARQ = PCD_ARQ
        AND CD_MDL_ARQ_RPT = RPT.CD_MDL_ARQ_RPT;
    END LOOP;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    WHEN OTHERS THEN 
      --
      ROLLBACK; RAISE;
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
  END;
  --
  --
  ------------------------------------------------------
  -- Busca lista de arquivos para serem processados
  ------------------------------------------------------
  PROCEDURE MassiveLoadGetWaitingList(PWaitingList OUT TFileList) IS
    --
    vIndex             BINARY_INTEGER;
    kQueueID           CONSTANT TKT_NPTC_PARAMETER.COD_PARAMETRO%TYPE := 'MASSIVE_LOAD_QUEUE_SIZE';
    kIntervalSchedule  CONSTANT TKT_NPTC_PARAMETER.COD_PARAMETRO%TYPE := 'MASSIVELOAD_INTERVAL_SCHEDULE';
    kTimeOutProcessing CONSTANT TKT_NPTC_PARAMETER.COD_PARAMETRO%TYPE := 'MASSIVELOAD_TIMEOUT_PROCESSING';
    kTimeOutLoading    CONSTANT TKT_NPTC_PARAMETER.COD_PARAMETRO%TYPE := 'MASSIVELOAD_TIMEOUT_LOADING';
    vQueueSize         BINARY_INTEGER := 10;
    vUsedQueue         BINARY_INTEGER;
    vRequests          BINARY_INTEGER;
    vFreeQueue         BINARY_INTEGER;
    vQueueRatio        NUMBER;
    vListaFinal        BINARY_INTEGER;
    vProcessing        BINARY_INTEGER;
    vLimit             NUMBER;
    vRelReq            BINARY_INTEGER;
    vProporcao         NUMBER;
    vDataSistema       DATE;
    vDataBaseExtracao  DATE;
    vIntervalSchedule  BINARY_INTEGER := 1;
    vTimeOutProcessing BINARY_INTEGER := 120;
    vTimeOutLoading    BINARY_INTEGER := 120;
    vCUR_OUT           T_CURSOR;     
    vParameterList     VARCHAR2(2000) := kQueueID||','||kIntervalSchedule||','||kTimeOutProcessing||','||kTimeOutLoading;
    rParameterList     TRParameter;  
    vArq_Dup           NUMBER;
    v_StaCmm           NUMBER;
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'MassiveLoadGetWaitingList');
    --
    -- Tenta "fechar" o semáforo do ambiente
    IF SetSemaphore('MASSIVELOAD_SEMAPHORE', TRUE) THEN
      --
      -- Data do Sistema WATTS
      SELECT P.DT_STM
        INTO vDataSistema
        FROM PTC_PRM_NPT P;
      --
      IF EXTRACT(DAY FROM vDataSistema) = EXTRACT(DAY FROM SYSDATE) THEN
        --
        vDataSistema := SYSDATE;
        --
      END IF;
      --
      WT_UTILITY_PKG.ParameterGetFilteredList(PLISTCOD_PARAMETRO => vParameterList,
                                              CUR_OUT            => vCUR_OUT);
      --
      LOOP
        FETCH vCUR_OUT INTO rParameterList;
        EXIT WHEN vCUR_OUT%NOTFOUND;
        --
        IF rParameterList.COD_PARAMETRO = kQueueID THEN
          --
          vQueueSize := TO_NUMBER(NVL(rParameterList.VAL_PARAMETRO, 10));
          --
        ELSIF rParameterList.COD_PARAMETRO = kIntervalSchedule THEN
          --
          vIntervalSchedule := TO_NUMBER(NVL(rParameterList.VAL_PARAMETRO, 1));
          --
        ELSIF rParameterList.COD_PARAMETRO = kTimeOutProcessing THEN
          --
          vTimeOutProcessing := TO_NUMBER(NVL(rParameterList.VAL_PARAMETRO, 120));
          --
        ELSIF rParameterList.COD_PARAMETRO = kTimeOutLoading THEN
          --
          vTimeOutLoading := TO_NUMBER(NVL(rParameterList.VAL_PARAMETRO, 120));
          --
        END IF;
        --
      END LOOP;
      --
      -- Recoloca domínios de arquivos que constam com status "Processando" novamente na fila de processamento
      -- (quando o domínio permanece mais do que o tempo pré-determinado na plataforma com status "Processando" o mesmo deverá retornar para a fila para nova tentativa de processamento)
      FOR rReprocess IN (SELECT ARQ.CD_ARQ,
                                ARQ.CD_MDL_ARQ,
                                ARQ.CD_STA_CMM,
                                ARQ.DT_INI_PRC
                           FROM PTC_mss_ARQ       ARQ
                          WHERE ARQ.CD_STA_CMM = 76 
                            AND IN_PRC_OLTP = 'F'
                            AND (SYSDATE - DT_INI_PRC) * 1440 > vTimeOutProcessing)
      LOOP
        --
        FileUpdateStatus( pCD_ARQ     => rReprocess.CD_ARQ,
                          pDT_INI_PRC => NULL,
                          pDT_FIM_PRC => NULL,
                          pCD_STA_CMM => 75);
        --
      END LOOP;
      --
      -- Posições ocupadas na fila de processamento
      BEGIN
        SELECT COUNT(1)
          INTO vUsedQueue
          FROM PTC_mss_ARQ A
         WHERE IN_PRC_OLTP = 'F'
           AND A.CD_STA_CMM IN (76, 77, 78, 83, 46); -- 'EM PROCESSAMENTO' / 'PROCESSANDO WEM' / 'PROCESSANDO FINANCEIRO' / 'PROCESSANDO VALIDAÇÃO'
                                                      -- 'AGUARDANDO ENVIO FINANCEIRO'
      EXCEPTION
        WHEN OTHERS THEN
          vUsedQueue := 0;
      END;
      --
      -- Quantidade de requisiçoes pendentes
      BEGIN
        SELECT GREATEST(COUNT(1), 1)
          INTO vRequests
          FROM (SELECT A.CD_ARQ
                  FROM PTC_mss_ARQ A
                 WHERE IN_PRC_OLTP = 'F'
                   AND A.CD_STA_CMM IN (75, 76, 77, 78, 83, 46)  --'AGUARDANDO'/ 'EM PROCESSAMENTO' / 'PROCESSANDO WEM' / 'PROCESSANDO FINANCEIRO' / 'PROCESSANDO VALIDAÇÃO' / 'AGUARDANDO ENVIO FINANCEIRO'
                 UNION
                SELECT A.CD_ARQ
                  FROM PTC_mss_ARQ A
                 WHERE A.CD_STA_CMM = 84 -- AGENDADO
                   AND A.IN_PRC_OLTP = 'F'
                   AND A.DT_AGD <= vDataSistema); 
      EXCEPTION
        WHEN OTHERS THEN
          vRequests := 1;
      END;
      --
      -- Quantidade de posições livres na fila
      vFreeQueue := vQueueSize - vUsedQueue;
      --
      -- Proporção de processamento
      vQueueRatio := LEAST(vFreeQueue / vRequests, 1);
      --
      -- Número de itens a retornar
      vListaFinal := 0;
      --
      -- Processa as requisições para definir a priorização
      --
      vDataBaseExtracao := SYSDATE;
      --
      FOR rReserva IN (SELECT X.CD_ARQ
                            , X.CD_MDL_ARQ
                            , X.VL_PRI_EXE
                            , X.NU_EXE_SIM
                            , X.CD_STA_CMM
                            , X.ARQ_RANK
                         FROM (SELECT DISTINCT
                                      A.CD_ARQ
                                    , A.CD_MDL_ARQ
                                    , M.VL_PRI_EXE
                                    , M.NU_EXE_SIM
                                    , A.CD_STA_CMM
                                    , RANK() OVER(PARTITION BY A.CD_MDL_ARQ ORDER BY M.VL_PRI_EXE, A.CD_ARQ) ARQ_RANK
                                    , RANK() OVER(PARTITION BY A.CD_MDL_ARQ, M.VL_PRI_EXE, A.CD_ARQ ORDER BY A.CD_ARQ) DOM_RANK
                                 FROM PTC_mss_ARQ     A
                                    , PTC_mss_MDL_ARQ M
                                WHERE M.CD_MDL_ARQ = A.CD_MDL_ARQ
                                  AND M.IN_PRC_OLTP = 'F'
                                  AND (A.CD_STA_CMM = 75 OR
                                       (A.CD_STA_CMM = 84 AND A.DT_AGD <= vDataSistema))) X 
                        WHERE X.DOM_RANK = 1
                        ORDER BY X.VL_PRI_EXE, X.CD_ARQ) LOOP
        --
        IF vListaFinal >= vFreeQueue THEN
          EXIT;
        END IF;
        --
        -- Verifica quantas instâncias do arquivo selecionado estão rodando
        BEGIN
          SELECT COUNT(1)
            INTO vProcessing
            FROM PTC_mss_ARQ A, PTC_MSS_MDL_ARQ M
           WHERE A.CD_STA_CMM = 76 -- 'EM PROCESSAMENTO'
             AND M.CD_MDL_ARQ = A.CD_MDL_ARQ
             AND A.IN_PRC_OLTP = 'F'
             AND A.CD_MDL_ARQ = rReserva.CD_MDL_ARQ
             AND A.CD_STA_CMM IN (76, 77, 78, 83, 46); -- 'EM PROCESSAMENTO' / 'PROCESSANDO WEM' / 'PROCESSANDO FINANCEIRO' / 'PROCESSANDO VALIDAÇÃO' / 'AGUARDANDO ENVIO FINANCEIRO'
        EXCEPTION
          WHEN OTHERS THEN
            vProcessing := 0;
        END;
        --
        -- Verifica quantas instâncias do Relatório selecionado estão Em Requisição para proporção
        BEGIN
          SELECT COUNT(1)
            INTO vRelReq
            FROM PTC_mss_ARQ A, PTC_MSS_MDL_ARQ M
           WHERE A.CD_MDL_ARQ = rReserva.CD_MDL_ARQ
             AND M.CD_MDL_ARQ = A.CD_MDL_ARQ
             AND M.IN_PRC_OLTP = 'F'
             AND ((A.CD_STA_CMM = 75) OR -- 'AGUARDANDO PROCESSAMENTO'
                  (A.CD_STA_CMM = 84 AND A.DT_AGD <= vDataSistema) );
        EXCEPTION
          WHEN OTHERS THEN
            vRelReq := 0;
        END;
        --
        -- Calcula o limite proporcional de execuções para execução do relatorio selecionado
        vProporcao := vRelReq / vFreeQueue;
        --
        vLimit := GREATEST(1, TRUNC(rReserva.NU_EXE_SIM * vQueueRatio, 0), TRUNC(rReserva.NU_EXE_SIM * vProporcao, 0));
        --
        -- Verifica se o relatorio está elegível e dentro dos limites
        IF LEAST(rReserva.NU_EXE_SIM - vProcessing, vLimit) > 0 THEN
          --
          -- Se o arquivo está elegivel, reserva a execução setando o ID_SERVER.
          -- Caso o arquivo esteja como "AGUARDANDO PROCESSAMENTO" o status é alterado para "EM PROCESSAMENTO"
          IF rReserva.CD_STA_CMM = 75 THEN
            --
            -- Verifica se esta processando arquivo identico -- Versão 3.2
            SELECT COUNT(1)
              INTO vArq_Dup
              FROM PTC_mss_ARQ APR, PTC_MSS_MDL_ARQ MDL,
                   (SELECT CD_MDL_ARQ,
                           CD_CLI,
                           CD_BAS 
                      FROM PTC_mss_ARQ 
                     WHERE CD_ARQ = rReserva.CD_ARQ) PROC
             WHERE APR.CD_MDL_ARQ = PROC.CD_MDL_ARQ
               AND APR.CD_CLI     = PROC.CD_CLI
               AND APR.CD_BAS     = PROC.CD_BAS
               AND APR.CD_STA_CMM IN (76, 77, 78, 83)
               AND MDL.CD_MDL_ARQ = APR.CD_MDL_ARQ
               AND MDL.IN_PRC_OLTP = 'F';              

             -- Não encontrou nenhum arquivo da mesma Base/Cliente/Modelo processando -- Versão 3.2
             IF vArq_Dup = 0 THEN 
              
               FileUpdateStatus( pCD_ARQ     => rReserva.CD_ARQ,
                                 pDT_INI_PRC => vDataBaseExtracao,
                                 pDT_FIM_PRC => NULL,
                                 pCD_STA_CMM => 76); -- EM PROCESSAMENTO
          --
            END IF;
            --
          END IF;
          --
          --         
          SELECT CMS.CD_STA_CMM
            INTO v_StaCmm
            FROM PTC_mss_ARQ CMS
           WHERE CMS.CD_ARQ = rReserva.CD_ARQ;

          IF v_StaCmm = 76 THEN 
            
             FileUpdateStatus(pCD_ARQ     => rReserva.CD_ARQ,
                              pDT_INI_PRC => vDataBaseExtracao,
                              pDT_FIM_PRC => NULL,
                              pCD_STA_CMM => 76); -- EM PROCESSAMENTO
             END IF;
            --
          -- Incrementa o(s) contador(es)
          vListaFinal := vListaFinal + 1;
          vFreeQueue  := vFreeQueue  - 1;
          --
        END IF;
        --
      END LOOP;
      --
      COMMIT;
      --
      -- Prepara a lista e as variaveis para retorno
      PWaitingList.DELETE;
      vIndex := 0;
      --
      -- Monta Lista de Reportorno
      FOR rWaiting IN (SELECT A.CD_ARQ
                            , A.TP_ACA
                            , MA.VL_PRI_EXE
                         FROM PTC_mss_ARQ A
                            , PTC_mss_MDL_ARQ MA
                        WHERE A.CD_STA_CMM = 76  -- EM PROCESSAMENTO
                          AND MA.IN_PRC_OLTP = 'F'
                          AND A.DT_INI_PRC = vDataBaseExtracao
                          AND A.CD_MDL_ARQ  = MA.CD_MDL_ARQ
                        ORDER BY MA.VL_PRI_EXE
                               , A.CD_ARQ) LOOP
        --
        vIndex := vIndex + 1;
        --
        PWaitingList(vIndex).CD_ARQ := rWaiting.CD_ARQ; 
        --PWaitingList(vIndex).CD_DOM := rWaiting.CD_DOM;
        PWaitingList(vIndex).TP_ACA := rWaiting.TP_ACA;
        --
      END LOOP;
      --
      --
      -- Monta Lista de Response
      FOR rWaiting IN (SELECT DISTINCT A.CD_ARQ, A.CD_STA_CMM, A.DT_FIM_PRC
                         FROM PTC_mss_ARQ A, PTC_MSS_MDL_ARQ_RPT M
                        WHERE A.CD_STA_CMM IN (80, 81, 79)  
                          AND A.DT_FIM_PRC IS NOT NULL
                          AND M.CD_MDL_ARQ = A.CD_MDL_ARQ
                          AND NOT EXISTS (SELECT 1 
                                          FROM PTC_MSS_ARQ_RPT R
                                          WHERE R.CD_ARQ = A.CD_ARQ
                                            AND R.CD_MDL_ARQ_RPT = M.CD_MDL_ARQ_RPT)
                        ORDER BY A.DT_FIM_PRC) LOOP
        --
        vIndex := vIndex + 1;
        --
        PWaitingList(vIndex).CD_ARQ := rWaiting.CD_ARQ; 
        PWaitingList(vIndex).CD_STA_CMM := rWaiting.CD_STA_CMM;
        --
      END LOOP;
      --
      --
      IF SetSemaphore('MASSIVELOAD_SEMAPHORE', FALSE) THEN
        --
        NULL;
        --
      END IF;
      --
    END IF;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      IF SetSemaphore('MASSIVELOAD_SEMAPHORE', FALSE) THEN
        --
        NULL;
        --
      END IF;      
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
  END;
  --
  --
  ------------------------------------------------------
  -- Orquestra processamento de arquivos
  ------------------------------------------------------
  PROCEDURE MassiveLoadOrchestrator IS
    --
    vModule             VARCHAR2(100);
    vAction             VARCHAR2(100);
    --
    vWaitingList TFileList;
    vIndex       BINARY_INTEGER;
    -- 
    vDB_NAME     VARCHAR2(15);
    vCOD_RET     NUMBER;
    vMSG_USER    VARCHAR2(5000);
    vMSG_RET     VARCHAR2(5000);
    -- 
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'MassiveLoadOrchestrator');
    --
    -- 
    MassiveLoadGetWaitingList(PWaitingList => vWaitingList);
    --
    vIndex := vWaitingList.FIRST;
    --
    WHILE vIndex IS NOT NULL LOOP
      --
      -- response
      IF vWaitingList(vIndex).CD_STA_CMM IN (79,80,81) THEN
        --
        --
        DBMS_SCHEDULER.Create_Job(Job_Name            => 'MassiveLoadResponse_' || vWaitingList(vIndex).CD_ARQ, 
                                  Job_Type            => 'PLSQL_BLOCK', 
                                  Job_Action          => 'BEGIN ' || $$PLSQL_UNIT || '.MassiveLoadResponse(' || vWaitingList(vIndex).CD_ARQ || '); END;', 
                                  Start_Date          => SYSTIMESTAMP, 
                                  Enabled             => TRUE, 
                                  Auto_Drop           => TRUE,
                                  Comments            => 'MassiveLoad 3.0 Job - CD_ARQ: ' || vWaitingList(vIndex).CD_ARQ );
        --
      ELSE
        -- process
        DBMS_SCHEDULER.Create_Job(Job_Name            => 'MassiveLoad2_' || vWaitingList(vIndex).CD_ARQ, 
                                  Job_Type            => 'PLSQL_BLOCK', 
                                  Job_Action          => 'BEGIN ' || $$PLSQL_UNIT || '.MassiveLoadScheduler(' || vWaitingList(vIndex).CD_ARQ || '); END;', 
                                  Start_Date          => SYSTIMESTAMP, 
                                  Enabled             => TRUE, 
                                  Auto_Drop           => TRUE,
                                  Comments            => 'MassiveLoad 3.0 Job - CD_ARQ: ' || vWaitingList(vIndex).CD_ARQ );
      --
      END IF;
      --
      vIndex := vWaitingList.NEXT(vIndex);
      --
    END LOOP;
    --
    -- Grava a monitoração da execução do scheduler
    SELECT SUBSTR(Global_Name, 1, 15)
      INTO vDB_NAME
      FROM GLOBAL_NAME;
    -- 
    ServiceMonitoringUpdate(PEN_SRV   => vDB_NAME,
                            PNM_SRV   => TRIM(vDB_NAME) || ' - MassiveLoadOrchestrator',
                            PNM_SVC   => 'Watts CMS Scheduler Orchestrator',
                            PDC_RSM   => '<Running Scheduler MassiveLoadOrchestrator>',
                            PMSG_USER => vMSG_USER,
                            PCOD_RET  => vCOD_RET,
                            PMSG_RET  => vMSG_RET);
    
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      RAISE;
    --
  END;  
  --
  --
  ------------------------------------------------------
  -- Finaliza cargas massivas "paradas"
  ------------------------------------------------------
  PROCEDURE MassiveLoadOrphanFinisher IS
    --
    vCount       INTEGER;
    vJob         DBA_JOBS_RUNNING.JOB%TYPE;
    vModule      VARCHAR2(100);
    vAction      VARCHAR2(100); 
    --
    vDB_NAME     VARCHAR2(15);
    vCOD_RET     NUMBER;
    vMSG_USER    VARCHAR2(5000);
    vMSG_RET     VARCHAR2(5000);
    --   
    
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'MassiveLoadOrphanFinisher');    
    --
    SELECT COUNT(1)
      INTO vCount
      FROM PTC_CMS_SRV  S
     WHERE S.CD_SRV = 3;
    --
    IF vCount = 0 THEN
       DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
       RAISE_APPLICATION_ERROR(-20001, 'MassiveLoadOrphanFinisher - Servidor não cadastrado ' );
       --
    END IF;
    --
    FOR rOrphanList IN (SELECT A.CD_ARQ,
                               A.CD_STA_CMM
                          FROM PTC_MSS_ARQ A
                         WHERE A.CD_STA_CMM  = 76 -- 'EM PROCESSAMENTO'
                           AND A.CD_STA_CMM IN (76, 77, 78, 83, 46)) LOOP
      -- Verifica se há Job rodando para o arquivo/dominio sendo verificado
      IF rOrphanList.CD_STA_CMM IN (76, 77, 83) THEN  -- EM PROCESSAMENTO / PROCESSANDO WEM / PROCESSANDO VALIDAÇÃO
        --
        SELECT COUNT(1)
          INTO vCount
          FROM USER_SCHEDULER_RUNNING_JOBS USRJ
         WHERE UPPER(USRJ.JOB_NAME) = 'MassiveLoad2_' || rOrphanList.CD_ARQ ;
        --
      ELSE -- PROCESSANDO FINANCEIRO / AGUARDANDO ENVIO FINANCEIRO
        --
        BEGIN
          --
          SELECT PFR.JOBID
            INTO vJob
            FROM T_ITKTPROCESSINGFILERUNNING PFR
           WHERE PFR.FILEID = rOrphanList.CD_ARQ
             AND PFR.DOMAINID = 0;--rOrphanList.CD_DOM;
          --
          SELECT COUNT(1)
            INTO vCount
            FROM DBA_JOBS_RUNNING DJR
           WHERE DJR.JOB = vJob;
          --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --
            vJob := NULL;
            vCount := 0;
            --
        END;
        --
      END IF;
      --
      IF vCount = 0 THEN
        --
        ProcessError( pErrorCode   => 182672, 
                      pAuxMessage => 'Erro ao verificar rOrphanList',
                      pErrorType  => 'EXC',
                      pErrorLevel => 'ARQ');         
        --
      END IF;
      --
    END LOOP;
    --
    -- Grava a monitoração da execução do scheduler
    SELECT SUBSTR(Global_Name, 1, 15)
      INTO vDB_NAME
      FROM GLOBAL_NAME;
    -- 
    ServiceMonitoringUpdate(PEN_SRV   => vDB_NAME,
                            PNM_SRV   => TRIM(vDB_NAME) || ' - MassiveLoadOrphanFinisher',
                            PNM_SVC   => 'Watts CMS Scheduler Orphan Finisher',
                            PDC_RSM   => '<Running Scheduler MassiveLoadOrphanFinisher>',
                            PMSG_USER => vMSG_USER,
                            PCOD_RET  => vCOD_RET,
                            PMSG_RET  => vMSG_RET);
    --
    IF  vCOD_RET <> 0 THEN
      --
      ProcessError( pErrorCode   => vCOD_RET, 
                    pAuxMessage => 'Erro ao executar ServiceMonitoringUpdate',
                    pErrorType  => 'EXC',
                    pErrorLevel => 'ARQ');         
      --
    END IF;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN  
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
  END MassiveLoadOrphanFinisher;
  --
  -- 1.02 (inicio)
  PROCEDURE GetActionTypeDescription (PNREG       IN PTC_MSS_REG.NU_REG%TYPE, 
                                      PCD_MDL_REG IN PTC_MSS_MDL_REG.CD_MDL_REG%TYPE ) IS
    --
    vOperacao  VARCHAR2(20);
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'MassiveLoadOrphanFinisher');    
    --      
    
     CASE NVL(gFile.TP_ACA,'X')
      WHEN 'A' THEN vOperacao  := 'APPLY';
      WHEN 'V' THEN vOperacao  := 'VALIDATE';
      ELSE vOperacao := NULL;
     END CASE;
       
     IF vOperacao IS NOT NULL THEN
       AddFieldResponse(PNU_REG     => 1,               -- Na linha do header
                        PDS_RTL_CTD => 'DsActionType',  -- Descricao do tipo de acao (APPLY/VALIDATE)
                        PCONTEUDO   => vOperacao);
     END IF;

  EXCEPTION
    --
    WHEN OTHERS THEN  
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
  END GetActionTypeDescription;     
  -- 1.02 (fim)  
  --
END WT2MX_MASSIVELOAD_MNG;
