CREATE OR REPLACE PACKAGE BODY WTMX_FILEPROCESSOR_PKG IS
  --
  EProcessTransferError     EXCEPTION;
  ECMSError                 EXCEPTION;
  --
  vModule                   VARCHAR2(100);
  vAction                   VARCHAR2(100);
  --
  -- INTERNAL CONSTANTS 
  --
  FuncColSeparator  CONSTANT VARCHAR2(1) := ';';
  FuncItemsEparator CONSTANT VARCHAR2(1) := '|';

  -- Dados do arquivo - CMS
  TYPE tpARQ_CMS IS RECORD (CD_ARQ     PTC_CMS_ARQ.CD_ARQ%TYPE,
                            CD_STA_CMM PTC_CMS_ARQ.CD_STA_CMM%TYPE,
                            DT_INI_PRC PTC_CMS_ARQ.DT_INI_PRC%TYPE,
                            DT_FIM_PRC PTC_CMS_ARQ.DT_FIM_PRC%TYPE);
  --
  gArq   tpARQ_CMS;
  --
  --------------------------------------------------------------------------------
  -- Reindexa posições do modelo de arquivo
  --------------------------------------------------------------------------------
  PROCEDURE ReIndex(pCD_MDL_ARQ  IN TKT_ARQ.CD_MDL_ARQ%TYPE)  IS
    --
    vColuna      INTEGER;
    vUltReg      INTEGER;
    --
    PRAGMA AUTONOMOUS_TRANSACTION;
    --
  BEGIN
    --
    vColuna := 1;
    --
    FOR vReg IN (SELECT ITE.CD_SET_ARQ         CD_MDL_REG,
                        ITE.CD_ITE_ARQ         CD_MDL_CTD,
                        ITE.VL_POS_INI_ITE_ARQ NU_POS_INI,
                        ITE.VL_POS_FIM_ITE_ARQ NU_POS_FIM,
                        ITE.VL_TAM_COL_ITE_ARQ NU_TAM_CTD
                   FROM TKT_SET_ARQ  STR,
                        TKT_ITE_ARQ  ITE
                  WHERE STR.CD_SET_ARQ = ITE.CD_SET_ARQ
                    AND STR.CD_MDL_ARQ = pCD_MDL_ARQ
                  ORDER BY STR.VL_SEQ_SET_ARQ, ITE.VL_SEQ_ITE_ARQ)
    LOOP
      --
      IF vUltReg <> vReg.CD_MDL_REG THEN
        --
        vColuna := 1;
        --
      END IF;
      --
      vUltReg := vReg.CD_MDL_REG;    
      --
      UPDATE TKT_ITE_ARQ   CTD
         SET CTD.VL_POS_INI_ITE_ARQ = vColuna,
             CTD.VL_POS_FIM_ITE_ARQ = vColuna + vReg.NU_TAM_CTD - 1
       WHERE CTD.CD_ITE_ARQ = vReg.CD_MDL_CTD;
      --
      vColuna := vColuna + vReg.NU_TAM_CTD;
      --
    END LOOP;
    --
    COMMIT;
    --
  END ReIndex;
  --
  
  --------------------------------------------------------------------------------
  -- Busca valor na linha
  --------------------------------------------------------------------------------
  FUNCTION LerConteudo(pCD_ARQ     IN TKT_ARQ.CD_ARQ%TYPE,
                       pCD_SET_ARQ IN TKT_SET_ARQ.CD_SET_ARQ%TYPE,
                       pNM_ITE_ARQ IN TKT_ITE_ARQ.NM_ITE_ARQ%TYPE, 
                       pNU_LIN     IN TKT_ARQ_CTD.NU_LIN%TYPE) RETURN VARCHAR2 IS
    vFirstPosition    INTEGER;
    vSize             INTEGER;
    vValor            VARCHAR2(1000);    
  BEGIN
    NULL;
    --
    SELECT I.VL_POS_INI_ITE_ARQ  FirstPosition,
           I.VL_TAM_COL_ITE_ARQ  SizeItem
      INTO vFirstPosition,
           vSize
      FROM TKT_SET_ARQ    S,
           TKT_ITE_ARQ    I
     WHERE S.CD_SET_ARQ = I.CD_SET_ARQ
       AND S.CD_SET_ARQ = pCD_SET_ARQ
       AND I.NM_ITE_ARQ = pNM_ITE_ARQ
     ORDER BY I.VL_SEQ_ITE_ARQ;
    --
    SELECT TRIM(DBMS_LOB.SUBSTR(C.VL_LIN, vSize, vFirstPosition))
      INTO vValor
      FROM TKT_ARQ_CTD   C
     WHERE C.CD_ARQ = pCD_ARQ
       AND C.NU_LIN = pNU_LIN;
    --
    RETURN vValor;
  EXCEPTION
    WHEN OTHERS THEN  
      RETURN NULL;
  END;
  
  --------------------------------------------------------------------------------
  -- Valida informações do modelo
  --------------------------------------------------------------------------------
  FUNCTION ModelValidator (pCD_CMS_MDL_ARQ   IN PTC_CMS_MDL_ARQ.CD_MDL_ARQ%TYPE) RETURN BOOLEAN IS
    --
    CURSOR cCMSModel IS
      SELECT CTD.NU_POS_INI,
             CTD.NU_POS_FIM,
             CTD.TP_DAD
        FROM PTC_CMS_MDL_ARQ    ARQ,
             PTC_CMS_MDL_REG    REG,
             PTC_CMS_MDL_CTD    CTD
       WHERE ARQ.CD_MDL_ARQ = REG.CD_MDL_ARQ
         AND REG.CD_MDL_REG = CTD.CD_MDL_REG
         AND ARQ.CD_MDL_ARQ = pCD_CMS_MDL_ARQ
         AND CTD.NU_POS_INI IS NOT NULL
         AND CTD.NU_POS_FIM IS NOT NULL
         AND CTD.VL_SEQ_MDL_CTD IS NOT NULL
       ORDER BY REG.NU_ORD_PRC,
                CTD.NU_POS_INI;
    --
    CURSOR cExtMXModel IS
      SELECT ITE.VL_POS_INI_ITE_ARQ    NU_POS_INI,
             ITE.VL_POS_FIM_ITE_ARQ    NU_POS_FIM,
             DECODE(ITE.VL_TIP_DAD_ITE_ARQ, 'NUMBER', 'N',
                                            'VARCHAR2', 'C',
                                            'CHAR', 'C',
                                            'DATE', 'D')    TP_DAD
        FROM TKT_MDL_ARQ    ARQ,
             TKT_SET_ARQ    STR,
             TKT_ITE_ARQ    ITE
       WHERE ARQ.CD_MDL_ARQ     = STR.CD_MDL_ARQ
         AND STR.CD_SET_ARQ     = ITE.CD_SET_ARQ
         AND ARQ.CD_CMS_MDL_ARQ = pCD_CMS_MDL_ARQ
         AND ITE.VL_SEQ_ITE_ARQ IS NOT NULL
         AND ITE.CD_CMS_MDL_CTD IS NOT NULL
       ORDER BY STR.VL_SEQ_SET_ARQ,
                ITE.VL_POS_INI_ITE_ARQ;

    --
    rCMSModel    cCMSModel%ROWTYPE;
    rExtMXModel  cExtMXModel%ROWTYPE;
    vCD_MDL_ARQ  TKT_MDL_ARQ.CD_MDL_ARQ%TYPE;
    --
  BEGIN
    --
    SELECT MA.CD_MDL_ARQ
      INTO vCD_MDL_ARQ
      FROM TKT_MDL_ARQ   MA
     WHERE MA.CD_CMS_MDL_ARQ = pCD_CMS_MDL_ARQ;
    --
    ReIndex(pCD_MDL_ARQ => vCD_MDL_ARQ);
    --
    OPEN cCMSModel;
    OPEN cExtMXModel;
    --
    LOOP
      FETCH cCMSModel INTO rCMSModel;
      FETCH cExtMXModel INTO rExtMXModel;
      EXIT WHEN cCMSModel%NOTFOUND AND cExtMXModel%NOTFOUND;
      --
      IF rCMSModel.NU_POS_INI <> rExtMXModel.NU_POS_INI OR
         rCMSModel.NU_POS_FIM <> rExtMXModel.NU_POS_FIM OR
         rCMSModel.TP_DAD <> rExtMXModel.TP_DAD THEN
         --
         RETURN FALSE;
         --
      END IF;
      --
    END LOOP;
    --
    RETURN TRUE;
    --
  END ModelValidator;
  --
  --------------------------------------------------------------------------------
  -- Busca dados de processamento na CMS
  --------------------------------------------------------------------------------
  FUNCTION ProcessCompleted (pCD_CMS_ARQ  IN PTC_CMS_ARQ.CD_ARQ%TYPE) RETURN BOOLEAN IS
      --
      vStatus    BOOLEAN;
      --
  BEGIN
      --
      BEGIN
          SELECT CD_ARQ,
                 CD_STA_CMM,
                 DT_INI_PRC,
                 DT_FIM_PRC          
            INTO gArq
            FROM PTC_CMS_ARQ    ARQ
           WHERE ARQ.CD_ARQ = pCD_CMS_ARQ
             AND ARQ.DT_FIM_PRC IS NOT NULL;
          --
          vStatus := TRUE;
          --
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
              vStatus := FALSE;
      END;
      --
      RETURN vStatus;
      --
  END ProcessCompleted;
  --
  --
  FUNCTION MSSProcessCompleted (pCD_CMS_ARQ  IN PTC_CMS_ARQ.CD_ARQ%TYPE) RETURN BOOLEAN IS
      --
      vStatus    BOOLEAN;
      --
  BEGIN
      --
      BEGIN
          SELECT CD_ARQ,
                 CD_STA_CMM,
                 DT_INI_PRC,
                 DT_FIM_PRC          
            INTO gArq
            FROM PTC_MSS_ARQ    ARQ
           WHERE ARQ.CD_ARQ = pCD_CMS_ARQ
             AND ARQ.DT_FIM_PRC IS NOT NULL;
          --
          vStatus := TRUE;
          --
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
              vStatus := FALSE;
      END;
      --
      RETURN vStatus;
      --
  END MSSProcessCompleted;  

  --------------------------------------------------------------------------------
  -- Popula Type com o conteúdo do Arquivo
  --------------------------------------------------------------------------------

  PROCEDURE FileLoad (pDados            IN CLOB,
                      pSeparator        IN VARCHAR2,
                      pSeparatorLine    IN VARCHAR2,
                      pContent         OUT TabMassiveLoadArchive) IS
    --
    vList       CLOB;
    vList2      CLOB;
    vClobNULL   CLOB;
    --
    vLine       VARCHAR2(32767);
    vInd        INT;
   
    --
    vModule VARCHAR2(100);
    vAction VARCHAR2(100);
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'FileLoad');
    --
    pContent.DELETE;
    vInd    := 0;
    --
    DBMS_LOB.CREATETEMPORARY(vList,     TRUE);
    DBMS_LOB.CREATETEMPORARY(vList2,    TRUE);
    DBMS_LOB.CREATETEMPORARY(vClobNULL, TRUE);
    --
    IF    pDados IS NULL THEN
          RETURN;
          --
    ELSIF DBMS_LOB.SUBSTR(pDados, 1, DBMS_LOB.GETLENGTH(pDados)) <> pSeparatorLine THEN
          vList  := pDados;
          DBMS_LOB.WRITEAPPEND(vList,1, pSeparatorLine);
    ELSE
          vList  := pDados;
    END IF;
    --
    LOOP
        vLine := DBMS_LOB.SUBSTR(vList, DBMS_LOB.INSTR(vList, pSeparatorLine) - 1, 1);
        --
        IF  DBMS_LOB.GETLENGTH(vList) - DBMS_LOB.INSTR(vList, pSeparatorLine) > 0  THEN
            DBMS_LOB.COPY(vList2, vList, (DBMS_LOB.GETLENGTH(vList) - DBMS_LOB.INSTR(vList, pSeparatorLine)), 1, DBMS_LOB.INSTR(vList, pSeparatorLine) + 1);
            vList  := vList2;
            vList2 := vClobNULL;
        ELSE
            DBMS_LOB.CREATETEMPORARY(vList2, TRUE);
            vList := vList2;
        END IF;
        --
        IF  SUBSTR(vLine, -1) <> pSeparator THEN
            vLine := vLine || pSeparator;
        END IF;
        --
        vInd := vInd + 1;
        --
      
        pContent(vInd).Linha    := SUBSTR(vLine, 1, INSTR(vLine, pSeparator) - 1);
        vLine                   := SUBSTR(vLine,    INSTR(vLine, pSeparator) + 1);
        pContent(vInd).Dados    := SUBSTR(vLine, 1, INSTR(vLine, pSeparator) - 1);
        --
        EXIT WHEN DBMS_LOB.GETLENGTH(vList) = 0;
        --
    END LOOP;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  END;

  --------------------------------------------------------------------------------
  -- Atualiza status do arquivo
  --------------------------------------------------------------------------------
  PROCEDURE FileStatusUpdate(pCD_ARQ          IN TKT_ARQ.CD_ARQ%TYPE,
                             pCD_ORI_ARQ      IN TKT_ARQ.CD_ORI_ARQ%TYPE DEFAULT 1,
                             pCD_STA_PRC_ARQ  IN TKT_ARQ.CD_STA_PRC_ARQ%TYPE,
                             pDT_INI_PRC_ARQ  IN TKT_ARQ.DT_INI_PRC_ARQ%TYPE DEFAULT NULL,
                             pDT_FIM_PRC_ARQ  IN TKT_ARQ.DT_FIM_PRC_ARQ%TYPE DEFAULT NULL,
                             pVL_MSG_PRC_ARQ  IN TKT_ARQ.VL_MSG_PRC_ARQ%TYPE DEFAULT NULL,
                             pCD_CMS_ARQ      IN PTC_CMS_ARQ.CD_ARQ%TYPE DEFAULT NULL,
                             pDT_REC_RET      IN TKT_ARQ.DT_REC_RET%TYPE DEFAULT NULL) IS
    --
    PRAGMA AUTONOMOUS_TRANSACTION;
    --
    vModule VARCHAR2(100);
    vAction VARCHAR2(100); 
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'FileStatusUpdate');
    --
    UPDATE TKT_ARQ   ARQ
       SET ARQ.CD_STA_PRC_ARQ = pCD_STA_PRC_ARQ,
           ARQ.DT_INI_PRC_ARQ = NVL(pDT_INI_PRC_ARQ, ARQ.DT_INI_PRC_ARQ),
           ARQ.DT_FIM_PRC_ARQ = NVL(pDT_FIM_PRC_ARQ, ARQ.DT_FIM_PRC_ARQ),
           ARQ.VL_MSG_PRC_ARQ = NVL(pVL_MSG_PRC_ARQ, ARQ.VL_MSG_PRC_ARQ),
           ARQ.CD_CMS_ARQ     = NVL(pCD_CMS_ARQ, ARQ.CD_CMS_ARQ),
           ARQ.DT_REC_RET     = NVL(pDT_REC_RET, ARQ.DT_REC_RET)
     WHERE ARQ.CD_ARQ = pCD_ARQ
       AND ARQ.CD_ORI_ARQ = PCD_ORI_ARQ;
    --
    COMMIT;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  END FileStatusUpdate;
  --
  --------------------------------------------------------------------------------
  -- Atualiza status da linha
  --------------------------------------------------------------------------------
  PROCEDURE ContentLineFileUpdate(pCD_ARQ          IN TKT_ARQ_CTD.CD_ARQ%TYPE,
                                  pCD_ORI_ARQ      IN TKT_ARQ_CTD.CD_ORI_ARQ%TYPE     DEFAULT 1,
                                  pNU_LIN          IN TKT_ARQ_CTD.NU_LIN%TYPE         DEFAULT NULL,
                                  pCD_STA_PRC_LIN  IN TKT_ARQ_CTD.CD_STA_PRC_LIN%TYPE DEFAULT NULL,
                                  pDT_INI_PRC_LIN  IN TKT_ARQ_CTD.DT_INI_PRC_LIN%TYPE DEFAULT NULL,
                                  pDT_FIM_PRC_LIN  IN TKT_ARQ_CTD.DT_FIM_PRC_LIN%TYPE DEFAULT NULL,
                                  pCD_MSG_PRC_CTD  IN INTEGER                         DEFAULT NULL,
                                  pVL_MSG_PRC_CTD  IN TKT_ARQ_CTD.VL_MSG_PRC_CTD%TYPE DEFAULT NULL,
                                  pVL_LIN_RET      IN TKT_ARQ_CTD.VL_LIN_RET%TYPE     DEFAULT NULL) IS  -- 1.2
    --
    PRAGMA AUTONOMOUS_TRANSACTION;
    --
    vModule VARCHAR2(100);
    vAction VARCHAR2(100); 
    --
    vVL_MSG_PRC_CTD               TKT_ARQ_CTD.VL_MSG_PRC_CTD%TYPE;
    vOccurrenceMax                INTEGER;
    vMsgErr                       PTC_ERR_WTS.DC_ERR_WTS%TYPE;
    vMsgErrSunnel                 PTC_ERR_WTS.DC_MSG_SNN%TYPE;
    vMsgDynContent                VARCHAR2(100);    
    vMsgItem                      VARCHAR2(100);
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'ContentLineFileUpdate');
    --
    vOccurrenceMax := REGEXP_COUNT(pVL_MSG_PRC_CTD, '{\d}');
    --
    IF vOccurrenceMax > 0 THEN
      --
      SELECT ERR.DC_ERR_WTS,
             ERR.DC_MSG_SNN
        INTO vMsgErr,
             vMsgErrSunnel
        FROM PTC_ERR_WTS   ERR
       WHERE ERR.CD_ERR_WTS = SUBSTR(pCD_MSG_PRC_CTD, -4);
      --
      vVL_MSG_PRC_CTD := vMsgErr;      
      --
      FOR i IN 1 .. vOccurrenceMax 
      LOOP
        --
        vMsgDynContent := SUBSTR(pVL_MSG_PRC_CTD, INSTR(pVL_MSG_PRC_CTD, '|'), LENGTH(pVL_MSG_PRC_CTD) - INSTR(pVL_MSG_PRC_CTD, '|')+1);
        --
        SELECT REPLACE(SUBSTR(vMsgDynContent, INSTR(vMsgDynContent, '|', i), DECODE(INSTR(vMsgDynContent, '|', i+1), 0, LENGTH(vMsgDynContent), INSTR(vMsgDynContent, '|', i+1))), '|', '')
          INTO vMsgItem
          FROM DUAL;
        --
        vVL_MSG_PRC_CTD := REPLACE(vVL_MSG_PRC_CTD, '{'|| (i-1) ||'}', vMsgItem);
        --
      END LOOP;
      --
    ELSE
      --
      IF NVL(pCD_MSG_PRC_CTD, 0) > 0 AND pVL_MSG_PRC_CTD IS NULL THEN
        --
        vVL_MSG_PRC_CTD := WT_UTILITY_PKG.GetMessage(pCD_MSG_PRC_CTD);
        --
      ELSIF NVL(pCD_MSG_PRC_CTD, 0) < 0 THEN
        --
        vVL_MSG_PRC_CTD := 'Internal error ('||pCD_MSG_PRC_CTD||')';
        --
      ELSE
        --
        vVL_MSG_PRC_CTD := pVL_MSG_PRC_CTD;
        --
      END IF;
      --
    END IF;

    --
    UPDATE TKT_ARQ_CTD   CTD
       SET CTD.CD_STA_PRC_LIN = pCD_STA_PRC_LIN,
           CTD.DT_INI_PRC_LIN = NVL(pDT_INI_PRC_LIN, CTD.DT_INI_PRC_LIN),
           CTD.DT_FIM_PRC_LIN = pDT_FIM_PRC_LIN,
           CTD.VL_MSG_PRC_CTD = NVL(vVL_MSG_PRC_CTD, CTD.VL_MSG_PRC_CTD),
           CTD.VL_LIN_RET     = NVL(pVL_LIN_RET, CTD.VL_LIN_RET)       -- 1.2
     WHERE CTD.CD_ARQ = pCD_ARQ
       AND CTD.CD_ORI_ARQ = PCD_ORI_ARQ
       AND CTD.NU_LIN = NVL(pNU_LIN, CTD.NU_LIN);
    --
    COMMIT;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  END ContentLineFileUpdate;
  --
  --------------------------------------------------------------------------------
  -- Procedure de carga de dados de interface para estrutura de Carga Massiva
  --------------------------------------------------------------------------------
  --
  PROCEDURE OldFileReceivedLoader(PCD_ARQ TKT_ARQ.CD_ARQ%TYPE,            -- 1.8
                                  PCD_ORI_ARQ TKT_ARQ.CD_ORI_ARQ%TYPE) IS -- 1.8
    --
    vMSG_USER    VARCHAR2(500);
    vCOD_RET     NUMBER;
    vMSG_RET     VARCHAR2(500);
    
    eErroCarga   EXCEPTION; -- 1.4
    --
    -- Dados do(s) arquivo(s) recebidos
    CURSOR cFileRec IS
      SELECT ARQ.CD_ARQ,
             ARQ.CD_ORI_ARQ,
             ARQ.CD_MDL_ARQ,
             ARQ.CD_CMS_ARQ,
             ARQ.NM_ARQ,
             ARQ.DT_REC_ARQ,
             ARQ.CD_CLI,
             ARQ.CONTROL_SEQ_ID,
             MDL.QT_DGT_SET,
             MDL.CD_CMS_MDL_ARQ
        FROM TKT_ARQ       ARQ,
             TKT_MDL_ARQ   MDL
       WHERE ARQ.CD_MDL_ARQ     = MDL.CD_MDL_ARQ
         AND MDL.CD_CMS_MDL_ARQ IS NOT NULL
         AND ARQ.CD_STA_PRC_ARQ = 1
         AND ARQ.CD_ARQ = PCD_ARQ           -- 1.8
         AND ARQ.CD_ORI_ARQ = PCD_ORI_ARQ;  -- 1.8

    --
    CURSOR cFileCtd (PCD_ARQ     TKT_ARQ_CTD.CD_ARQ%TYPE, 
                     PCD_ORI_ARQ TKT_ARQ_CTD.CD_ORI_ARQ%TYPE) IS
      SELECT CTD.CD_ARQ,
             CTD.NU_LIN,
             CTD.VL_LIN
        FROM TKT_ARQ_CTD   CTD
       WHERE CTD.CD_ARQ         = PCD_ARQ
         AND CTD.CD_ORI_ARQ     = PCD_ORI_ARQ 
         AND CTD.CD_STA_PRC_LIN = 2
      ORDER BY CTD.NU_LIN;
    --
    -- Dados de modelo de arquivo
    CURSOR cFileStr (pCD_MDL_ARQ  TKT_SET_ARQ.CD_MDL_ARQ%TYPE) IS
      SELECT ROWNUM    NU_REG,
             STR.CD_SET_ARQ,
             STR.VL_IDE_SET_ARQ,
             ITE.IN_OBR_ITE_ARQ,
             STR.NM_SET_ARQ,
             ITE.CD_ITE_ARQ,
             STR.CD_CMS_MDL_REG,
             ITE.NM_ITE_ARQ,
             ITE.CD_CMS_MDL_CTD,
             ITE.VL_POS_INI_ITE_ARQ
        FROM TKT_SET_ARQ  STR,
             TKT_ITE_ARQ  ITE
       WHERE STR.CD_SET_ARQ = ITE.CD_SET_ARQ
         AND STR.CD_MDL_ARQ = pCD_MDL_ARQ
         AND STR.CD_STA_SET_ARQ = 1
         AND NVL(ITE.IN_REF_SET, 'F') = 'T'
       ORDER BY STR.VL_SEQ_SET_ARQ;
    -- 
    CURSOR cFileIte (pCD_SET_ARQ  TKT_SET_ARQ.CD_SET_ARQ%TYPE) IS
      SELECT ITE.VL_SEQ_ITE_ARQ,
             ITE.NM_ITE_ARQ,
             ITE.VL_TAM_COL_ITE_ARQ,
             ITE.VL_TIP_DAD_ITE_ARQ,
             ITE.VL_POS_INI_ITE_ARQ,
             ITE.VL_POS_FIM_ITE_ARQ,
             ITE.VL_FMT_MSK_ITE_ARQ,
             ITE.VL_TAM_DEC_COL_ITE_ARQ,
             ITE.CD_CMS_MDL_CTD
        FROM TKT_ITE_ARQ  ITE
       WHERE ITE.CD_SET_ARQ = pCD_SET_ARQ
         AND ITE.CD_CMS_MDL_CTD IS NOT NULL
         AND NVL(ITE.IN_REF_SET, 'F') = 'F'
       ORDER BY ITE.VL_SEQ_ITE_ARQ;
    --
    vNU_LIN          TKT_ARQ_CTD.NU_LIN%TYPE := NULL;
    vCD_SET_ARQ      TKT_SET_ARQ.CD_SET_ARQ%TYPE;
    vCD_CMS_ARQ      PTC_CMS_ARQ.CD_ARQ%TYPE;
    --vTP_PRC          PTC_CMS_ARQ.TP_PRC%TYPE := 'F';  -- FULL
    --vTP_ACA          PTC_CMS_ARQ.TP_ACA%TYPE := 'A';  -- Apply
    vCD_CMS_CTD      PTC_CMS_CTD.CD_CTD%TYPE;
    vVL_CMS_CTD      PTC_CMS_CTD.VL_CTD%TYPE;
    vCD_BASE         PTC_BAS.CD_BAS%TYPE := NULL;
    --vCD_DOC_GST      PTC_ETD.VL_ETD%TYPE := NULL;
    --
    vNU_TOT_LIN      PTC_CMS_ARQ.NU_TOT_LIN%TYPE;
    --
    vValidModel      BOOLEAN; 
    --
    vAction_Type  VARCHAR2(1);  -- 1.7
    vProcess_Type VARCHAR2(1); -- 1.7 
    vSetor_Autentic TKT_SET_ARQ.CD_SET_ARQ%TYPE;-- 1.7
    vLinha_Autentic TKT_ARQ_CTD.NU_LIN%TYPE;   -- 1.7 
    vCD_GST       PTC_CMS_ARQ.CD_GST%TYPE;-- 1.7
    vCD_CSL       PTC_CMS_ARQ.CD_CSL%TYPE;-- 1.7
    vCD_CLI       PTC_CMS_ARQ.CD_CLI%TYPE;-- 1.7
    vCD_BAS       PTC_CMS_ARQ.CD_BAS%TYPE;-- 1.7
    vCD_USU       PTC_GST.CD_USU%TYPE;-- 1.7
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'FileReceivedLoader');
    --
    -- 1.3
    -- Geração de Log de Auditoria
    WTMX_UTILITY_PKG.AuditLogCreate(pCD_USU => NULL,
				                            pEN_IP  => NULL,
				                            pNM_PCK => 'WTMX_FILEPROCESSOR_PKG.FileReceivedLoader');

    BEGIN
      EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '',. ''';
    END;
    --
    FOR rFileRec IN cFileRec LOOP
      BEGIN
        --
        IF NVL(rFileRec.Control_Seq_Id, 0) = 0 THEN
          --
          UPDATE TKT_ARQ  ARQ
             SET ARQ.CONTROL_SEQ_ID = ARQ.CD_ARQ
           WHERE ARQ.CD_ARQ = rFileRec.CD_ARQ
             AND ARQ.CD_ORI_ARQ = rFileRec.CD_ORI_ARQ;
          --
        END IF;
        --
        COMMIT;
        --
        vCD_BASE := NULL;
        vNU_LIN  := NULL;
        vCD_SET_ARQ := NULL;          
        --
        vValidModel := ModelValidator(rFileRec.CD_CMS_MDL_ARQ);
        --
        IF NOT vValidModel THEN
          --
          FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                           pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ, 
                           pCD_STA_PRC_ARQ => 5,
                           pDT_INI_PRC_ARQ => NULL,
                           pDT_FIM_PRC_ARQ => NULL,
                           pVL_MSG_PRC_ARQ => 'As configurações de modelo de arquivo estão incompatíveis.');
        END IF;
        --
        
        -- Verifica total de linhas do arquivo
        SELECT COUNT(1)
          INTO vNU_TOT_LIN
          FROM TKT_ARQ_CTD  CTD
         WHERE CTD.CD_ARQ = rFileRec.CD_ARQ;
         
        -- 1.4 início
        BEGIN
           SELECT ARQ.CD_ARQ
             INTO vCD_CMS_ARQ
             FROM PTC_CMS_ARQ ARQ
            WHERE ARQ.NM_ARQ = rFileRec.NM_ARQ;
            
            UPDATE PTC_CMS_ARQ
            SET NU_TOT_LIN = vNU_TOT_LIN
            WHERE CD_ARQ = vCD_CMS_ARQ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- Verifica config arquivo -- 1.7 (INICIO)
            IF rFileRec.CD_ORI_ARQ = 2 THEN
              vSetor_Autentic:= NULL; 
              BEGIN
                --
                FOR Header IN (SELECT CTD.NU_LIN, CTD.VL_LIN
                               FROM TKT_ARQ_CTD   CTD
                               WHERE CTD.CD_ARQ       = rFileRec.CD_ARQ
                               AND CTD.CD_ORI_ARQ     = rFileRec.CD_ORI_ARQ 
                               AND CTD.CD_STA_PRC_LIN = 2
                               ORDER BY CTD.NU_LIN) LOOP
                  BEGIN
                    SELECT STR.CD_SET_ARQ
                    INTO vSetor_Autentic             
                    FROM TKT_SET_ARQ  STR,
                               TKT_ITE_ARQ  ITE
                          WHERE STR.CD_SET_ARQ = ITE.CD_SET_ARQ
                            AND STR.CD_MDL_ARQ = rFileRec.Cd_Mdl_Arq
                            AND STR.CD_STA_SET_ARQ = 1
                            AND NVL(ITE.IN_REF_SET, 'F') = 'T'
                            AND STR.VL_IDE_SET_ARQ = '01' -- Setor de autenticação
                            AND STR.VL_IDE_SET_ARQ = SUBSTR(TO_CHAR(Header.VL_LIN), VL_POS_INI_ITE_ARQ, rFileRec.Qt_Dgt_Set)
                          ORDER BY STR.VL_SEQ_SET_ARQ;   
                  EXCEPTION
                    WHEN OTHERS THEN
                      NULL;
                  END;
                      
                  IF vSetor_Autentic IS NOT NULL THEN
                    vLinha_Autentic:= Header.Nu_Lin;
                    vAction_Type:= LerConteudo(pCD_ARQ    => rFileRec.CD_ARQ,
                                                pCD_SET_ARQ=> vSetor_Autentic,
                                                pNM_ITE_ARQ=> 'ACTION_TYPE',
                                                pNU_LIN    => Header.Nu_Lin);
                        
                    vProcess_Type:= LerConteudo(pCD_ARQ    => rFileRec.CD_ARQ,
                                                pCD_SET_ARQ=> vSetor_Autentic,
                                                pNM_ITE_ARQ=> 'PROCESS_TYPE',
                                                pNU_LIN    => Header.Nu_Lin);
                    --
                    vCD_GST:= LerConteudo(pCD_ARQ    => rFileRec.CD_ARQ,
                                                pCD_SET_ARQ=> vSetor_Autentic,
                                                pNM_ITE_ARQ=> 'MANAGER_IDENTIFICATION',
                                                pNU_LIN    => Header.Nu_Lin);

                    vCD_BAS:= LerConteudo(pCD_ARQ    => rFileRec.CD_ARQ,
                                                pCD_SET_ARQ=> vSetor_Autentic,
                                                pNM_ITE_ARQ=> 'CORPORATE_LEVEL_IDENTIF',
                                                pNU_LIN    => Header.Nu_Lin);

                    vCD_CLI:= LerConteudo(pCD_ARQ    => rFileRec.CD_ARQ,
                                                pCD_SET_ARQ=> vSetor_Autentic,
                                                pNM_ITE_ARQ=> 'CUSTOMER_IDENTIFICATION',
                                                pNU_LIN    => Header.Nu_Lin);
                                                
                    vCD_CSL:= LerConteudo(pCD_ARQ    => rFileRec.CD_ARQ,
                                                pCD_SET_ARQ=> vSetor_Autentic,
                                                pNM_ITE_ARQ=> 'PRIME_COMPANY_IDENTIFICATION',
                                                pNU_LIN    => Header.Nu_Lin);

                    vCD_USU:= LerConteudo(pCD_ARQ    => rFileRec.CD_ARQ,
                                                pCD_SET_ARQ=> vSetor_Autentic,
                                                pNM_ITE_ARQ=> 'MANAGER_USER',
                                                pNU_LIN    => Header.Nu_Lin);
                    -- Cliente
                    IF vCD_CLI IS NULL AND
                       vCD_BAS IS NOT NULL AND vCD_GST IS NOT NULL THEN
                      BEGIN
                        SELECT C.CD_CLI INTO vCD_CLI
                        FROM PTC_CLI C, PTC_BAS B, PTC_GST G
                        WHERE B.CD_BAS = vCD_BAS
                          AND B.CD_CLI = C.CD_CLI
                          AND C.CD_CSL = G.CD_CSL
                          AND G.CD_GST = vCD_GST;
                      EXCEPTION
                        WHEN OTHERS THEN
                          NULL;
                      END;        
                    END IF;
                   
                    -- Usuario
                    IF vCD_USU IS NULL AND
                       vCD_GST IS NOT NULL THEN 
                      FOR Usu IN (SELECT GST.CD_TIP_GST, MAX(CD_USU) CD_USU
                                   FROM PTC_GST GST
                                  WHERE GST.CD_GST = vCD_GST
                                    AND (vCD_CSL IS NULL OR GST.CD_CSL = vCD_CSL)
                                    AND GST.CD_STA_USU = 1
                                  GROUP BY GST.CD_TIP_GST 
                                  ORDER BY CD_TIP_GST) LOOP
                          vCD_USU:= Usu.CD_USU;
                          EXIT;
                      END LOOP;    
                    END IF;               
                                                                                                
                    EXIT;                            
                  END IF;                              
                --
                END LOOP;
                        
                IF vAction_Type IS NOT NULL AND vProcess_Type IS NOT NULL THEN
                  -- 
                  WTMX_MASSIVELOAD_PKG.MassiveLoadFileCreate(pCD_ARQ     => vCD_CMS_ARQ, 
                                               pCD_MDL_ARQ => rFileRec.Cd_Cms_Mdl_Arq,
                                               pCD_GST     => vCD_GST,
                                               pNM_ARQ     => rFileRec.NM_ARQ,    
                                               pCD_CSL     => vCD_CSL, 
                                               pCD_CLI     => vCD_CLI,
                                               pCD_BAS     => vCD_BAS,
                                               pDT_SOL     => rFileRec.Dt_Rec_Arq,    
                                               pTP_PRC     => vProcess_Type,    
                                               pTP_ACA     => vAction_Type,    
                                               pNU_TOT_LIN => vNU_TOT_LIN,
                                               pDT_AGD     => NULL,
                                               pCD_USU     => vCD_USU,
                                               pMSG_USER   => vMSG_USER,
                                               pCOD_RET    => vCOD_RET,
                                               pMSG_RET    => vMSG_RET);  
                  --
                  IF NVL(vCOD_RET, 0) <> 0 THEN
                    --
                    ROLLBACK;
                    --
                    ContentLineFileUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                          pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                          pNU_LIN         => vLinha_Autentic,
                                          pCD_STA_PRC_LIN => 9,  -- Erro em transferência
                                          pDT_FIM_PRC_LIN => SYSDATE,
                                          pVL_MSG_PRC_CTD => 'Transferência não realizada. ERRO ao criar registro para arquivo CMS (1. '|| vMSG_RET ||
' CD_GST='|| vCD_GST || ' CD_BAS='|| vCD_BAS ||
' CD_CLI='|| vCD_CLI || ' CD_CSL='|| vCD_CSL || ' CD_USU='|| vCD_USU ||')');
                    --
                    -- Atualiza status de processamento do arquivo na interface com a WEM
                    FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                     pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                     pCD_STA_PRC_ARQ => 10);
                    RAISE eErroCarga;                    
                  END IF;                                                                                  
                  --   
                ELSE 
                  ROLLBACK;
                  --
                    ContentLineFileUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                          pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                          pNU_LIN         => vLinha_Autentic,
                                          pCD_STA_PRC_LIN => 9,  -- Erro em transferência
                                          pDT_FIM_PRC_LIN => SYSDATE,
                                          pVL_MSG_PRC_CTD => 'Transferência não realizada. Action_Type/Process_Type não informados.');
                    --

                  -- Atualiza status de processamento do arquivo na interface com a WEM
                  FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                   pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                   pCD_STA_PRC_ARQ => 10);
                  RAISE eErroCarga;   
                END IF;
              EXCEPTION
                WHEN OTHERS THEN 
                  --
                  ROLLBACK;
                  -- Atualiza status de processamento do arquivo na interface com a WEM
                  FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ, 
                                   pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                   pCD_STA_PRC_ARQ => 10,
                                   pVL_MSG_PRC_ARQ => SQLERRM);  
                  RAISE eErroCarga;                        
              END;

            -- 1.7 (FIM)  
            ELSE 
              ROLLBACK;
              --
              -- Atualiza status de processamento do arquivo na interface com a WEM
              FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                               pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                               pCD_STA_PRC_ARQ => 10);
              RAISE eErroCarga;   
            END IF;    
            --          
          WHEN OTHERS THEN -- 1.7
            ROLLBACK;
            -- Atualiza status de processamento do arquivo na interface com a WEM
            FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ, 
                             pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                             pCD_STA_PRC_ARQ => 10,
                             pVL_MSG_PRC_ARQ => SQLERRM);     
        END;
        -- 1.4 fim

        --
        -- Atualiza status de processamento do arquivo na interface com a WEM
        FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                         pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                         pCD_STA_PRC_ARQ => 3,
                         pCD_CMS_ARQ     => vCD_CMS_ARQ);
        --
        FOR rFileCtd IN cFileCtd(rFileRec.CD_ARQ, rFileRec.CD_ORI_ARQ) LOOP
          --
          IF NVL(vNU_LIN,-1) <> rFileCtd.NU_LIN THEN
            --
            FOR rFileStr IN cFileStr(rFileRec.CD_MDL_ARQ) LOOP
              --
              SELECT SUBSTR(rFileCtd.VL_LIN,
                            rFileStr.VL_POS_INI_ITE_ARQ,
                            rFileRec.QT_DGT_SET)
                INTO vVL_CMS_CTD
                FROM DUAL;
              --
              IF TRIM(vVL_CMS_CTD) IS NULL AND rFileStr.IN_OBR_ITE_ARQ = 'T' THEN
                --
                ROLLBACK;
                --
                -- Atualiza status de processamento do arquivo na interface com a WEM
                FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                 pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                 pCD_STA_PRC_ARQ => 10);
                --
              END IF;
              --
              IF TRIM(vVL_CMS_CTD) = rFileStr.VL_IDE_SET_ARQ THEN
                --
                WTMX_MASSIVELOAD_PKG.MassiveLoadRegisterCreate(pCD_ARQ     => vCD_CMS_ARQ,
                                                               pCD_MDL_REG => rFileStr.CD_CMS_MDL_REG,
                                                               pNU_REG     => rFileCtd.NU_LIN,
                                                               pMSG_USER   => vMSG_USER,
                                                               pCOD_RET    => vCOD_RET,
                                                               pMSG_RET    => vMSG_RET);
                --
                IF NVL(vCOD_RET, 0) <> 0 THEN
                  --
                  ROLLBACK;
                  --
                  ContentLineFileUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                        pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                        pNU_LIN         => rFileCtd.NU_LIN,
                                        pCD_STA_PRC_LIN => 9,  -- Erro em transferência
                                        pDT_FIM_PRC_LIN => SYSDATE,
                                        pVL_MSG_PRC_CTD => 'Transferência não realizada. ERRO ao criar registro linha para arquivo CMS'|| vMSG_RET ||' CMS_ARQ = '||vCD_CMS_ARQ||
' CD_GST='|| vCD_GST || ' CD_BAS='|| vCD_BAS ||
' CD_CLI='|| vCD_CLI || ' CD_CSL='|| vCD_CSL || ' CD_USU='|| vCD_USU ||')');
                  --
                  -- Atualiza status de processamento do arquivo na interface com a WEM
                  FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                   pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                   pCD_STA_PRC_ARQ => 10);
                  --
                ELSE
                  --
                  -- Abre registro atual
                  ContentLineFileUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                        pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                        pNU_LIN         => rFileCtd.NU_LIN,
                                        pCD_STA_PRC_LIN => 3,
                                        pDT_INI_PRC_LIN => SYSDATE);
                  --
                  vNU_LIN := rFileCtd.NU_LIN;
                  vCD_SET_ARQ := rFileStr.CD_SET_ARQ;
                  --
                END IF;
                --
                WTMX_MASSIVELOAD_PKG.MassiveLoadContentCreate (pCD_CTD     => vCD_CMS_CTD,
                                                               pCD_ARQ     => vCD_CMS_ARQ,
                                                               pNU_REG     => rFileCtd.NU_LIN,
                                                               pCD_MDL_CTD => rFileStr.CD_CMS_MDL_CTD,
                                                               pVL_CTD     => vVL_CMS_CTD,
                                                               pMSG_USER   => vMSG_USER,
                                                               pCOD_RET    => vCOD_RET,
                                                               pMSG_RET    => vMSG_RET);
                --
                IF NVL(vCOD_RET, 0) <> 0 THEN
                  --
                  ROLLBACK;
                  --
                  ContentLineFileUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                        pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                        pNU_LIN         => rFileCtd.NU_LIN,
                                        pCD_STA_PRC_LIN => 9,  -- Erro em transferência
                                        pDT_FIM_PRC_LIN => SYSDATE,
                                        PVL_MSG_PRC_CTD => 'ERRO ao criar conteúdo para arquivo CMS.');
                  --
                  -- Atualiza status de processamento do arquivo na interface com a WEM
                  FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                   pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                   pCD_STA_PRC_ARQ => 10);
                  --
                END IF;             
                  --
              END IF;
              --
            END LOOP;
            --
          END IF;
          --
          FOR rFileIte IN cFileIte(vCD_SET_ARQ) LOOP
            --
            -- Efetua parse do conteúdo para gravação
            BEGIN
              --
              SELECT TRIM(SUBSTR(rFileCtd.VL_LIN, 
                            rFileIte.VL_POS_INI_ITE_ARQ,     -- Posição inicial
                            rFileIte.VL_TAM_COL_ITE_ARQ))    -- Tamanho do item
                INTO vVL_CMS_CTD
                FROM DUAL;
              --
            EXCEPTION
              WHEN OTHERS THEN
                --
                ROLLBACK;
                --
                ContentLineFileUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                      pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                      pNU_LIN         => rFileCtd.NU_LIN,
                                      pCD_STA_PRC_LIN => 9,  -- Erro em transferência
                                      pDT_FIM_PRC_LIN => SYSDATE,
                                      pVL_MSG_PRC_CTD => 'ERRO ao recuperar conteúdo para arquivo criação de conteúdo CMS.');
                --
                -- Atualiza status de processamento do arquivo na interface com a WEM
                FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                 pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                 pCD_STA_PRC_ARQ => 10);
                --
            END;
            --
            IF rFileIte.VL_FMT_MSK_ITE_ARQ IS NOT NULL OR rFileIte.VL_TAM_DEC_COL_ITE_ARQ > 0 THEN
              --
              IF rFileIte.VL_TIP_DAD_ITE_ARQ = 'DATE' OR rFileIte.VL_TIP_DAD_ITE_ARQ = 'DATETIME' THEN
                --
                BEGIN
                  --
                  vVL_CMS_CTD := TO_CHAR(TO_DATE(vVL_CMS_CTD, ''''||rFileIte.VL_FMT_MSK_ITE_ARQ||''''), 
                                          ''||rFileIte.VL_FMT_MSK_ITE_ARQ||'');
                  --
                EXCEPTION
                  WHEN OTHERS THEN
                    --
                    ROLLBACK;
                    --
                    ContentLineFileUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                          pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                          pNU_LIN         => rFileCtd.NU_LIN,
                                          pCD_STA_PRC_LIN => 9,  -- Erro em transferência
                                          pDT_FIM_PRC_LIN => SYSDATE,
                                          pVL_MSG_PRC_CTD => 'ERRO ao recuperar conteúdo para arquivo criação de conteúdo CMS.');
                    --
                    -- Atualiza status de processamento do arquivo na interface com a WEM
                    FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                     pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                     pCD_STA_PRC_ARQ => 10);
                    --
                END;
                --
              ELSIF rFileIte.VL_TIP_DAD_ITE_ARQ = 'NUMBER' THEN
                --
                IF rFileIte.VL_FMT_MSK_ITE_ARQ IS NOT NULL THEN
                  --
                  BEGIN
                    --
                    vVL_CMS_CTD := TO_CHAR(TO_NUMBER(vVL_CMS_CTD, ''||rFileIte.VL_FMT_MSK_ITE_ARQ||''), ''||rFileIte.VL_FMT_MSK_ITE_ARQ||'');
                    --
                  EXCEPTION
                    WHEN OTHERS THEN
                      --
                      ROLLBACK;
                      --
                      ContentLineFileUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                            pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                            pNU_LIN         => rFileCtd.NU_LIN,
                                            pCD_STA_PRC_LIN => 9,  -- Erro em transferência
                                            pDT_FIM_PRC_LIN => SYSDATE,
                                            pVL_MSG_PRC_CTD => 'ERRO ao recuperar conteúdo para arquivo criação de conteúdo CMS.');
                      --
                      -- Atualiza status de processamento do arquivo na interface com a WEM
                      FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                       pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                       pCD_STA_PRC_ARQ => 10);
                      --
                  END;
                  --
                ELSIF rFileIte.VL_TAM_DEC_COL_ITE_ARQ > 0 THEN
                  --
                  BEGIN
                    --
                    SELECT TO_NUMBER(vVL_CMS_CTD) / POWER(10, rFileIte.VL_TAM_DEC_COL_ITE_ARQ)
                      INTO vVL_CMS_CTD
                      FROM DUAL;
                    --
                  EXCEPTION
                    WHEN OTHERS THEN
                      --
                      ROLLBACK;
                      --
                      ContentLineFileUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                            pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                            pNU_LIN         => rFileCtd.NU_LIN,
                                            pCD_STA_PRC_LIN => 9,  -- Erro em transferência
                                            pDT_FIM_PRC_LIN => SYSDATE,
                                            pVL_MSG_PRC_CTD => 'ERRO ao recuperar conteúdo para arquivo criação de conteúdo CMS.');
                      --
                      -- Atualiza status de processamento do arquivo na interface com a WEM
                      FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                       pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                       pCD_STA_PRC_ARQ => 10);
                      --
                  END;
                  --
                END IF;
                --
              END IF;
              --
            END IF;
            --
            WTMX_MASSIVELOAD_PKG.MassiveLoadContentCreate (pCD_CTD     => vCD_CMS_CTD,
                                                           pCD_ARQ     => vCD_CMS_ARQ,
                                                           pNU_REG     => rFileCtd.NU_LIN,
                                                           pCD_MDL_CTD => rFileIte.CD_CMS_MDL_CTD,
                                                           pVL_CTD     => vVL_CMS_CTD,
                                                           pMSG_USER   => vMSG_USER,
                                                           pCOD_RET    => vCOD_RET,
                                                           pMSG_RET    => vMSG_RET);
            --
            IF NVL(vCOD_RET, 0) <> 0 THEN
              --
              ROLLBACK;
              --
              ContentLineFileUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                    pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                    pNU_LIN         => rFileCtd.NU_LIN,
                                    pCD_STA_PRC_LIN => 9,  -- Erro em transferência
                                    pDT_FIM_PRC_LIN => SYSDATE,
                                    PVL_MSG_PRC_CTD => 'ERRO ao criar conteúdo para arquivo CMS.');
              --
              -- Atualiza status de processamento do arquivo na interface com a WEM
              FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                               pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                               pCD_STA_PRC_ARQ => 10);
              --
            END IF;             
            --
          END LOOP;
          --
          -- Finaliza registro anterior
          ContentLineFileUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                pNU_LIN         => rFileCtd.NU_LIN,
                                pCD_STA_PRC_LIN => 4,
                                pDT_INI_PRC_LIN => SYSDATE);
          --
        END LOOP;
        --
        COMMIT;
        --
        IF vCD_CMS_ARQ IS NOT NULL THEN
          --
          -- Disponibilizando dados para processamento
          WTMX_MASSIVELOAD_PKG.MassiveLoadFileDomainUpdStatus(pCD_ARQ     => vCD_CMS_ARQ,
                                                              pDT_INI_PRC => NULL,
                                                              pDT_FIM_PRC => NULL,
                                                              pCD_STA_CMM => 75,
                                                              pMSG_USER   => vMSG_USER,
                                                              pCOD_RET    => vCOD_RET,
                                                              pMSG_RET    => vMSG_RET);
          --
          IF NVL(vCOD_RET, 0) <> 0 THEN
            --
            ROLLBACK;
            --
            ContentLineFileUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                  pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                  pCD_STA_PRC_LIN => 9,  -- Erro em transferência
                                  pDT_FIM_PRC_LIN => SYSDATE,
                                  pVL_MSG_PRC_CTD => 'ERRO ao atualizar arquivo CMS.');
            --
            -- Atualiza status de processamento do arquivo na interface com a WEM
            FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                             pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                             pCD_STA_PRC_ARQ => 10);
            --
          END IF;
          --
          WTMX_MASSIVELOAD_PKG.MassiveLoadFileUpdateStatus(pCD_ARQ     => vCD_CMS_ARQ,
                                                           pDT_INI_PRC => NULL,
                                                           pDT_FIM_PRC => NULL,
                                                           pCD_STA_CMM => 75,
                                                           pMSG_USER   => vMSG_USER,
                                                           pCOD_RET    => vCOD_RET,
                                                           pMSG_RET    => vMSG_RET);
          --
          IF NVL(vCOD_RET, 0) <> 0 THEN
            --
            ROLLBACK;
            --
            ContentLineFileUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                  pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                                  pCD_STA_PRC_LIN => 9,  -- Erro em transferência
                                  pDT_FIM_PRC_LIN => SYSDATE,
                                  PVL_MSG_PRC_CTD => 'ERRO ao atualizar arquivo CMS.');
            --
            -- Atualiza status de processamento do arquivo na interface com a WEM
            FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                             pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                             pCD_STA_PRC_ARQ => 10);
            --
          END IF;
          --
        END IF;
        --
        -- Atualiza status de processamento do arquivo na interface com a WEM
        FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ, 
                         pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                         pCD_STA_PRC_ARQ => 4);
        --
      EXCEPTION
        WHEN OTHERS THEN -- 1.6 tratamento exceção inesperada
          --
          ROLLBACK;
          -- Atualiza status de processamento do arquivo na interface com a WEM
          FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ, 
                           pCD_ORI_ARQ     => rFileRec.CD_ORI_ARQ,
                           pCD_STA_PRC_ARQ => 10,
                           pVL_MSG_PRC_ARQ => SQLERRM);          
              
      END;
    END LOOP;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      ROLLBACK;
    --
  END OldFileReceivedLoader;
  --
  --
  PROCEDURE NewFileReceivedLoader(PCD_ARQ TKT_ARQ.CD_ARQ%TYPE) IS -- 1.8
    --
    vMSG_USER    VARCHAR2(500);
    vCOD_RET     NUMBER;
    vMSG_RET     VARCHAR2(500);
    
    eErroCarga   EXCEPTION;
    --
    -- Dados do(s) arquivo(s) recebidos
    CURSOR cFileRec IS
         SELECT ARQ.CD_ARQ,
             ARQ.CD_MDL_ARQ,
             ARQ.CD_CMS_ARQ,
             ARQ.NM_ARQ,
             ARQ.DT_REC_ARQ,
             ARQ.CONTROL_SEQ_ID,
             PRC.CD_MDL_ARQ_PRC
        FROM TKT_ARQ         ARQ,
             TKT_MDL_ARQ_PRC PRC, -- 1.9
             PTC_MSS_MDL_ARQ   MDL
       WHERE ARQ.CD_ARQ         = PCD_ARQ
         AND PRC.CD_MDL_ARQ     = ARQ.CD_MDL_ARQ 
         AND PRC.IN_DST_PRC     = 'MSS'
         AND PRC.CD_STA_CMM     = 1
         AND MDL.CD_MDL_ARQ     = PRC.CD_MDL_ARQ_PRC
         AND ARQ.CD_STA_PRC_ARQ = 1;
         
    --
    CURSOR cFileCtd (PCD_ARQ     TKT_ARQ_CTD.CD_ARQ%TYPE) IS
      SELECT CTD.CD_ARQ,
             CTD.NU_LIN,
             CTD.VL_LIN
        FROM TKT_ARQ_CTD   CTD
       WHERE CTD.CD_ARQ         = PCD_ARQ
         AND CTD.CD_ORI_ARQ     = 2 
         AND CTD.CD_STA_PRC_LIN = 2
      ORDER BY CTD.NU_LIN;
    --
    -- Dados de modelo de arquivo
    -- Registros
    CURSOR cFileStr (pCD_MDL_ARQ  PTC_MSS_MDL_ARQ.CD_MDL_ARQ%TYPE) IS
      SELECT ROWNUM         NU_REG,
             REG.CD_MDL_REG CD_MDL_REG,
             REG.ID_CTD_REG VL_IDE_SET_ARQ,
             CTD.IN_OBR     IN_OBR_ITE_ARQ,
             REG.CD_MDL_REG CD_MSS_MDL_REG,
             CTD.CD_MDL_CTD CD_MSS_MDL_CTD,
             CTD.NU_POS_INI VL_POS_INI_ITE_ARQ,
             CTD.NU_TAM_MAX NU_TAM_MAX,
             REG.TP_MDL_REG TP_MDL_REG
      FROM PTC_MSS_MDL_REG REG,
           PTC_MSS_MDL_CTD CTD 
      WHERE REG.CD_MDL_ARQ = pCD_MDL_ARQ
        AND CTD.CD_MDL_REG = REG.CD_MDL_REG
        AND CTD.IN_KEY_VLR = 'REGISTER_TYPE'
        AND REG.CD_STA_CMM = 1
      ORDER BY REG.NU_ORD_PRC;
    --
    -- Campos        
    -- 
    CURSOR cFileIte (pCD_MDL_REG  PTC_MSS_MDL_REG.CD_MDL_REG%TYPE) IS
      SELECT ROWNUM  VL_SEQ_ITE_ARQ,
             CTD.DS_RTL_CTD      NM_ITE_ARQ,
             CTD.NU_TAM_MAX      VL_TAM_COL_ITE_ARQ,
             CTD.TP_DAD          VL_TIP_DAD_ITE_ARQ,
             CTD.NU_POS_INI      VL_POS_INI_ITE_ARQ,
             CTD.NU_POS_FIM      VL_POS_FIM_ITE_ARQ,
             CTD.DS_FMT_DAD      VL_FMT_MSK_ITE_ARQ,
             CTD.NU_PCS          VL_TAM_DEC_COL_ITE_ARQ,
             CTD.CD_MDL_CTD      CD_MSS_MDL_CTD,
             CTD.IN_KEY_VLR      IN_KEY_VLR
      FROM PTC_MSS_MDL_CTD CTD
      WHERE CD_MDL_REG = pCD_MDL_REG   
        AND NVL(CTD.IN_KEY_VLR,'X') <> 'REGISTER_TYPE'          
      ORDER BY CTD.NU_POS_INI;  

    --
    --
    vNU_LIN          TKT_ARQ_CTD.NU_LIN%TYPE := NULL;
    vCD_MDL_REG      PTC_MSS_MDL_REG.CD_MDL_REG%TYPE;
    vCD_MDL_CTD      PTC_MSS_MDL_CTD.CD_MDL_CTD%TYPE;    
    vCD_CMS_ARQ      PTC_CMS_ARQ.CD_ARQ%TYPE;
    vCD_CMS_CTD      PTC_CMS_CTD.CD_CTD%TYPE;
    vVL_CMS_CTD      PTC_CMS_CTD.VL_CTD%TYPE;
    vNU_TOT_LIN      PTC_CMS_ARQ.NU_TOT_LIN%TYPE;
    vTP_MDL_REG      PTC_MSS_MDL_REG.TP_MDL_REG%TYPE;
    --
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'FileReceivedLoader');
    --
    -- Geração de Log de Auditoria
    WTMX_UTILITY_PKG.AuditLogCreate(pCD_USU => NULL,
				                            pEN_IP  => NULL,
				                            pNM_PCK => 'WTMX_FILEPROCESSOR_PKG.NewFileReceivedLoader');

    BEGIN
      EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '',. ''';
    END;
    -----------------------------------
    -- Arquivos recebidos
    -----------------------------------
    FOR rFileRec IN cFileRec LOOP
      BEGIN
        --
        IF NVL(rFileRec.Control_Seq_Id, 0) = 0 THEN
          --
          UPDATE TKT_ARQ  ARQ
             SET ARQ.CONTROL_SEQ_ID = ARQ.CD_ARQ
           WHERE ARQ.CD_ARQ = rFileRec.CD_ARQ;
          --
        END IF;
        --
        COMMIT;
        --
        vNU_LIN  := NULL;
        vCD_MDL_REG := NULL;          
        --
        --
        -- Verifica total de linhas do arquivo
        SELECT COUNT(1)
          INTO vNU_TOT_LIN
          FROM TKT_ARQ_CTD  CTD
         WHERE CTD.CD_ARQ = rFileRec.CD_ARQ;
        -- 
        -- Cria arquivo
        WT2MX_MASSIVELOAD_MNG.MassiveLoadFileCreate(pCD_ARQ     => vCD_CMS_ARQ, 
                                     pCD_MDL_ARQ => rFileRec.Cd_Mdl_Arq_Prc, -- 1.9
                                     pNM_ARQ     => rFileRec.NM_ARQ,    
                                     pDT_SOL     => rFileRec.Dt_Rec_Arq,    
                                     pNU_TOT_LIN => vNU_TOT_LIN,
                                     pMSG_USER   => vMSG_USER,
                                     pCOD_RET    => vCOD_RET,
                                     pMSG_RET    => vMSG_RET);  
        --
        IF NVL(vCOD_RET, 0) <> 0 THEN
          --
          RAISE eErroCarga;                    
          --
        END IF;                                                                                  
        --   
        --
        -- Atualiza status de processamento do arquivo na interface com a WEM
        FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                         pCD_ORI_ARQ     => 2, 
                         pCD_STA_PRC_ARQ => 3, -- Processando interface
                         pCD_CMS_ARQ     => vCD_CMS_ARQ);
        --
        --------------------------------------------------
        -- Linhas do arquivo
        --------------------------------------------------
        FOR rFileCtd IN cFileCtd(rFileRec.CD_ARQ) LOOP
          --
          vNU_LIN:= rFileCtd.NU_LIN;
          
            --
            -- Encontra identificador do registro
            FOR rFileStr IN cFileStr(rFileRec.Cd_Mdl_Arq_Prc) LOOP -- 1.9
              --
              --
              SELECT SUBSTR(rFileCtd.VL_LIN,
                            rFileStr.VL_POS_INI_ITE_ARQ,
                            rFileStr.Nu_Tam_Max)
                INTO vVL_CMS_CTD
                FROM DUAL;
              --
              -- inserir registro identificador
              IF NVL(TRIM(vVL_CMS_CTD),'X') = rFileStr.VL_IDE_SET_ARQ THEN
                --
                vCD_MDL_REG  := rFileStr.CD_MDL_REG ;
                vCD_MDL_CTD  := rFileStr.Cd_MSS_Mdl_Ctd;
                vTP_MDL_REG  := rFileStr.TP_MDL_REG;
                --
                WT2MX_MASSIVELOAD_MNG.MassiveLoadRegisterCreate(pCD_ARQ     => vCD_CMS_ARQ,
                                                               pCD_MDL_REG => rFileStr.CD_MSS_MDL_REG,
                                                               pNU_REG     => rFileCtd.NU_LIN,
                                                               pMSG_USER   => vMSG_USER,
                                                               pCOD_RET    => vCOD_RET,
                                                               pMSG_RET    => vMSG_RET);
                --
                IF NVL(vCOD_RET, 0) <> 0 THEN
                  --
                  RAISE eErroCarga;
                  --
                END IF; 
                --
                EXIT; -- encontrou ok
                -- 
              ELSE
                --
                vCD_CMS_CTD := NULL;
                vCD_MDL_REG := NULL;
                vCD_MDL_CTD := NULL;
                vVL_CMS_CTD := NULL;
                vTP_MDL_REG := NULL;
                --
              END IF;
              --
            END LOOP;
            --
            --
            IF vCD_MDL_CTD IS NULL THEN
              RAISE eErroCarga; -- não encontrou
            END IF;              
            --
            -- Cria conteudo que identifica registro
            WT2MX_MASSIVELOAD_MNG.MassiveLoadContentCreate(pCD_CTD     => vCD_CMS_CTD,
                                                           pCD_ARQ     => vCD_CMS_ARQ,
                                                           pNU_REG     => rFileCtd.NU_LIN,
                                                           pCD_MDL_CTD => vCD_MDL_CTD,
                                                           pVL_CTD     => vVL_CMS_CTD,
                                                           pMSG_USER   => vMSG_USER,
                                                           pCOD_RET    => vCOD_RET,
                                                           pMSG_RET    => vMSG_RET);
            --
            IF NVL(vCOD_RET, 0) <> 0 THEN
              --
              RAISE eErroCarga;
              --
            END IF;
            --
            -- Abre registro atual
            ContentLineFileUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                  pCD_ORI_ARQ     => 2, 
                                  pNU_LIN         => rFileCtd.NU_LIN,
                                  pCD_STA_PRC_LIN => 3,
                                  pDT_INI_PRC_LIN => SYSDATE);
            --
            --
            ----------------------------------------------
            -- Conteudos da linha
            ----------------------------------------------
            FOR rFileIte IN cFileIte(vCD_MDL_REG) LOOP  
              --
              -- Efetua parse do conteúdo para gravação
              BEGIN
                --
                SELECT TRIM(SUBSTR(rFileCtd.VL_LIN, 
                              rFileIte.VL_POS_INI_ITE_ARQ,     -- Posição inicial
                              rFileIte.VL_TAM_COL_ITE_ARQ))    -- Tamanho do item
                  INTO vVL_CMS_CTD
                  FROM DUAL;
                --
              EXCEPTION
                WHEN OTHERS THEN
                  RAISE eErroCarga;
              END;
              --
              IF rFileIte.VL_FMT_MSK_ITE_ARQ IS NOT NULL OR rFileIte.VL_TAM_DEC_COL_ITE_ARQ > 0 THEN
                --
                IF rFileIte.VL_TIP_DAD_ITE_ARQ = 'D' OR rFileIte.VL_TIP_DAD_ITE_ARQ = 'T' THEN
                  --
                  BEGIN
                    --
                    vVL_CMS_CTD := TO_CHAR(TO_DATE(vVL_CMS_CTD, ''''||rFileIte.VL_FMT_MSK_ITE_ARQ||''''), 
                                            ''||rFileIte.VL_FMT_MSK_ITE_ARQ||'');
                    --
                  EXCEPTION
                    WHEN OTHERS THEN
                      --
                      RAISE eErroCarga;
                      --
                  END;
                  --
                ELSIF rFileIte.VL_TIP_DAD_ITE_ARQ = 'N' THEN
                  --
                  IF rFileIte.VL_FMT_MSK_ITE_ARQ IS NOT NULL THEN
                    --
                    BEGIN
                      --
                      vVL_CMS_CTD := TO_CHAR(TO_NUMBER(vVL_CMS_CTD, ''||rFileIte.VL_FMT_MSK_ITE_ARQ||''), ''||rFileIte.VL_FMT_MSK_ITE_ARQ||'');
                      --
                    EXCEPTION
                      WHEN OTHERS THEN
                        --
                        RAISE eErroCarga;
                        --
                    END;
                    --
                  ELSIF rFileIte.VL_TAM_DEC_COL_ITE_ARQ > 0 THEN
                    --
                    BEGIN
                      --
                      SELECT TO_NUMBER(vVL_CMS_CTD) / POWER(10, rFileIte.VL_TAM_DEC_COL_ITE_ARQ)
                        INTO vVL_CMS_CTD
                        FROM DUAL;
                      --
                    EXCEPTION
                      WHEN OTHERS THEN
                        --
                        RAISE eErroCarga;
                        --
                    END;
                    --
                  END IF;
                  --
                END IF;
                --
              END IF;
              --
              WT2MX_MASSIVELOAD_MNG.MassiveLoadContentCreate (pCD_CTD     => vCD_CMS_CTD,
                                                             pCD_ARQ     => vCD_CMS_ARQ,
                                                             pNU_REG     => rFileCtd.NU_LIN,
                                                             pCD_MDL_CTD => rFileIte.CD_MSS_MDL_CTD,
                                                             pVL_CTD     => vVL_CMS_CTD,
                                                             pMSG_USER   => vMSG_USER,
                                                             pCOD_RET    => vCOD_RET,
                                                             pMSG_RET    => vMSG_RET);
              --
              IF NVL(vCOD_RET, 0) <> 0 THEN
                --
                RAISE eErroCarga;
                --
              END IF;             
              --
              --
              -- Se for linha de autenticação, salvar dados do arquivo na ptc_MSS_arq
              IF vTP_MDL_REG = 'A' AND rFileIte.IN_KEY_VLR IS NOT NULL THEN
                --
                IF rFileIte.IN_KEY_VLR = 'CD_GST' THEN
                  UPDATE PTC_MSS_ARQ
                  SET CD_GST = vVL_CMS_CTD
                  WHERE CD_ARQ = vCD_CMS_ARQ;
                --
                ELSIF rFileIte.IN_KEY_VLR = 'CD_BAS' THEN
                  UPDATE PTC_MSS_ARQ
                  SET CD_BAS = vVL_CMS_CTD
                  WHERE CD_ARQ = vCD_CMS_ARQ;
                --
                ELSIF rFileIte.IN_KEY_VLR = 'ACTION_TYPE' THEN
                  UPDATE PTC_MSS_ARQ A
                  SET A.TP_ACA = vVL_CMS_CTD
                  WHERE CD_ARQ = vCD_CMS_ARQ;
                --
                ELSIF rFileIte.IN_KEY_VLR = 'PROCESS_TYPE' THEN
                  UPDATE PTC_MSS_ARQ
                  SET TP_PRC = vVL_CMS_CTD
                  WHERE CD_ARQ = vCD_CMS_ARQ;
                END IF;
                --
              END IF;
              --
              
            END LOOP; -- conteudo da linha
            --
            -- Finaliza registro anterior
            ContentLineFileUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                  pCD_ORI_ARQ     => 2, --rFileRec.CD_ORI_ARQ,
                                  pNU_LIN         => rFileCtd.NU_LIN,
                                  pCD_STA_PRC_LIN => 4,
                                  pDT_INI_PRC_LIN => SYSDATE);
            --
          --END IF;
        END LOOP; -- linhas
        --
        COMMIT;
        --
        IF vCD_CMS_ARQ IS NOT NULL THEN
          --
          -- Disponibilizando dados para processamento
          WT2MX_MASSIVELOAD_MNG.FileUpdateStatus(pCD_ARQ     => vCD_CMS_ARQ,
                                              pDT_INI_PRC => NULL,
                                              pDT_FIM_PRC => NULL,
                                              pCD_STA_CMM => 75);
          --
          IF NVL(vCOD_RET, 0) <> 0 THEN
            --
            RAISE eErroCarga;
            --
          END IF;
          --
        END IF;
        --
        -- Atualiza status de processamento do arquivo na interface com a WEM
        FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ, 
                         pCD_ORI_ARQ     => 2, 
                         pCD_STA_PRC_ARQ => 4);
        --
      EXCEPTION
        WHEN OTHERS THEN -- tratamento todas exceções do arquivo
          --
          ROLLBACK;
          --
          ContentLineFileUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                                pCD_ORI_ARQ     => 2, --rFileRec.CD_ORI_ARQ,
                                pNU_LIN         => vNU_LIN,
                                pCD_STA_PRC_LIN => 9,  -- Erro em transferência
                                pDT_FIM_PRC_LIN => SYSDATE,
                                pVL_MSG_PRC_CTD => 'ERRO ao recuperar conteúdo para arquivo criação de conteúdo CMS. '||sqlerrm); -- 1.9
          --
          -- Atualiza status de processamento do arquivo na interface com a WEM
          FileStatusUpdate(pCD_ARQ         => rFileRec.CD_ARQ,
                           pCD_ORI_ARQ     => 2, 
                           pCD_STA_PRC_ARQ => 10);
          --        
              
      END;
      --
    END LOOP; -- Arquivos
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      ROLLBACK;
    --
  END NewFileReceivedLoader;
  --
  --
  PROCEDURE FileReceivedLoader IS
    --
    -- Dados do(s) arquivo(s) recebidos
    CURSOR cFileRec IS
      SELECT ARQ.CD_ARQ,
             ARQ.CD_ORI_ARQ,
             ARQ.CD_MDL_ARQ,
             PRC.CD_MDL_ARQ_PRC CD_CMS_MDL_ARQ,
             PRC.IN_DST_PRC     Processamento
        FROM TKT_ARQ         ARQ,
             TKT_MDL_ARQ_PRC PRC -- 1.9
       WHERE ARQ.CD_STA_PRC_ARQ = 1
         AND PRC.CD_MDL_ARQ     = ARQ.CD_MDL_ARQ    
         AND PRC.CD_STA_CMM     = 1 ;         
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'FileReceivedLoader');
    --
    -- Geração de Log de Auditoria
    WTMX_UTILITY_PKG.AuditLogCreate(pCD_USU => NULL,
				                            pEN_IP  => NULL,
				                            pNM_PCK => 'WTMX_FILEPROCESSOR_PKG.FileReceivedLoader');

    BEGIN
      EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '',. ''';
    END;
    --
    FOR rFileRec IN cFileRec LOOP
      --
      IF rFileRec.Processamento = 'MSS' THEN -- 1.9
        NewFileReceivedLoader(rFileRec.CD_ARQ);
      ELSE 
        OldFileReceivedLoader(rFileRec.CD_ARQ, rFileRec.CD_ORI_ARQ);
      END IF; 
      --
      COMMIT;
      --
    END LOOP;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      ROLLBACK;
    --
  END FileReceivedLoader;
  --
  --    
  --------------------------------------------------------------------------------
  -- Procedure para atualização dos dados conforme processamento de Carga Massiva
  --------------------------------------------------------------------------------
  --
  --
  PROCEDURE NewFileReceivedFinisher IS -- 1.8
    --
    CURSOR cFilePending IS
      SELECT ARQ.CD_ARQ,
             ARQ.CD_ORI_ARQ,
             ARQ.NM_ARQ,
             ARQ.CONTROL_SEQ_ID,
             ARQ.CD_CMS_ARQ
        FROM TKT_ARQ         ARQ,
             TKT_MDL_ARQ_PRC MDL, -- 1.9
             PTC_MSS_ARQ   MSS -- 1.9
       WHERE ARQ.CD_STA_PRC_ARQ = 4
         AND ARQ.CD_CMS_ARQ IS NOT NULL
         AND MDL.CD_MDL_ARQ = ARQ.CD_MDL_ARQ
         AND MDL.CD_STA_CMM = 1
         AND MDL.IN_DST_PRC = 'MSS'
         AND MSS.CD_ARQ = ARQ.CD_CMS_ARQ
         AND EXISTS (SELECT 1 
                      FROM PTC_MSS_ARQ_RPT R
                      WHERE R.CD_ARQ = ARQ.CD_CMS_ARQ)
       ORDER BY ARQ.DT_INI_PRC_ARQ;
    --
    CURSOR cRegFlPending (pCD_ARQ  TKT_ARQ.CD_ARQ%TYPE) IS
      SELECT CTD.CD_ARQ,
             CTD.NU_LIN
        FROM TKT_ARQ_CTD   CTD
       WHERE CTD.CD_ARQ = pCD_ARQ
       ORDER BY CTD.NU_LIN;
    --
    vStatus         TKT_ARQ.CD_STA_PRC_ARQ%TYPE;
    vNU_LIN         TKT_ARQ_CTD.NU_LIN%TYPE;
    vCD_MSG_PRC_CTD NUMBER;
    vVL_MSG_PRC_CTD TKT_ARQ_CTD.VL_MSG_PRC_CTD%TYPE;
    --
    vResponse       CLOB;  -- 1.2
    --
  BEGIN
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'FileReceivedFinisher');
    --
    FOR rFilePending IN cFilePending LOOP
      --
      IF MSSProcessCompleted(rFilePending.CD_CMS_ARQ) THEN
        --
        BEGIN
          --
          IF rFilePending.CD_ORI_ARQ = 2 THEN -- Golden Gate
            --
            FOR rRegFlPending IN cRegFlPending(rFilePending.CD_ARQ) LOOP
              --
              SELECT REG.NU_REG, 
                     CASE 
                       WHEN NVL(REG.IN_ERR_PRC,'T') = 'T' THEN  8  -- Processado com sucesso (linha)
                       WHEN NVL(REG.IN_ERR_PRC,'T') = 'F' THEN  9  -- Processado com erros (linha)
                     END,
                     RPT.VL_RPT                        
                INTO vNU_LIN,
                     vStatus,
                     vResponse                         
                FROM PTC_MSS_REG   REG,
                     PTC_MSS_REG_RPT RPT
               WHERE REG.CD_ARQ = gArq.CD_ARQ
                 AND REG.NU_REG = rRegFlPending.NU_LIN
                 AND REG.CD_ARQ = RPT.CD_ARQ(+)        
                 AND REG.NU_REG = RPT.NU_REG(+);       
              --
              IF vStatus = 9 THEN
                BEGIN
                  SELECT E.CD_MSG_ERR, E.DS_MSG_ERR
                  INTO vCD_MSG_PRC_CTD,
                       vVL_MSG_PRC_CTD
                  FROM PTC_MSS_REG_ERR E
                  WHERE CD_ARQ = gArq.CD_ARQ
                    AND NU_REG = rRegFlPending.NU_LIN    
                    AND ROWNUM = 1;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    NULL;    
                --
                END;    
              END IF;
              
              ContentLineFileUpdate(pCD_ARQ         => rFilePending.CD_ARQ,
                                    pCD_ORI_ARQ     => rFilePending.CD_ORI_ARQ,
                                    pNU_LIN         => vNU_LIN,
                                    pCD_STA_PRC_LIN => vStatus,
                                    PDT_INI_PRC_LIN => gArq.DT_INI_PRC,
                                    pDT_FIM_PRC_LIN => gArq.DT_FIM_PRC,
                                    pCD_MSG_PRC_CTD => vCD_MSG_PRC_CTD,
                                    pVL_MSG_PRC_CTD => vVL_MSG_PRC_CTD,
                                    pVL_LIN_RET     => vResponse);       -- 1.2
              --
            END LOOP;
            --
          END IF;
          --
          -- 1.5 - início
          /*
          SELECT CASE 
                   WHEN gArq.CD_STA_CMM IN (79, 81, 80) THEN 6  -- Processado WEM
                 END
            INTO vStatus
            FROM DUAL;
          */
          vStatus := 6;
          -- 1.5 - fim
          --
          FileStatusUpdate(pCD_ARQ         => rFilePending.CD_ARQ,
                           pCD_ORI_ARQ     => rFilePending.CD_ORI_ARQ,
                           pCD_STA_PRC_ARQ => vStatus,
                           PDT_INI_PRC_ARQ => gArq.DT_INI_PRC,
                           pDT_FIM_PRC_ARQ => gArq.DT_FIM_PRC,
                           pDT_REC_RET     => SYSTIMESTAMP);
          --
          COMMIT;
          --
        EXCEPTION

          WHEN OTHERS THEN
            --
            ROLLBACK; 
            --
        END;
        --
      END IF;
      --
    END LOOP;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    WHEN OTHERS THEN
      --
      ROLLBACK; 
      --
  END NewFileReceivedFinisher;
    
  PROCEDURE OldFileReceivedFinisher IS
    --
    CURSOR cFilePending IS
      SELECT ARQ.CD_ARQ,
             ARQ.CD_ORI_ARQ,
             ARQ.NM_ARQ,
             ARQ.CONTROL_SEQ_ID,
             ARQ.CD_CMS_ARQ
        FROM TKT_ARQ         ARQ,
             TKT_MDL_ARQ_PRC MDL, -- 1.9
             PTC_CMS_ARQ     CMS  -- 1.9
       WHERE ARQ.CD_STA_PRC_ARQ = 4
         AND ARQ.CD_CMS_ARQ IS NOT NULL
         AND MDL.CD_MDL_ARQ = ARQ.CD_MDL_ARQ
         AND MDL.IN_DST_PRC = 'CMS'
         AND MDL.CD_STA_CMM = 1
         AND CMS.CD_ARQ = ARQ.CD_CMS_ARQ  -- 1.9
       ORDER BY ARQ.DT_INI_PRC_ARQ;
    --
    CURSOR cRegFlPending (pCD_ARQ  TKT_ARQ.CD_ARQ%TYPE) IS
      SELECT CTD.CD_ARQ,
             CTD.NU_LIN
        FROM TKT_ARQ_CTD   CTD
       WHERE CTD.CD_ARQ = pCD_ARQ
       ORDER BY CTD.NU_LIN;
    --
    vStatus         TKT_ARQ.CD_STA_PRC_ARQ%TYPE;
    vNU_LIN         TKT_ARQ_CTD.NU_LIN%TYPE;
    vCD_MSG_PRC_CTD NUMBER;
    vVL_MSG_PRC_CTD TKT_ARQ_CTD.VL_MSG_PRC_CTD%TYPE;
    --
    vResponse       CLOB;  -- 1.2
    --
  BEGIN
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'FileReceivedFinisher');
    --
    FOR rFilePending IN cFilePending LOOP
      --
      IF ProcessCompleted(rFilePending.CD_CMS_ARQ) THEN
        --
        BEGIN
          --
          IF rFilePending.CD_ORI_ARQ = 2 THEN -- Golden Gate
            --
            FOR rRegFlPending IN cRegFlPending(rFilePending.CD_ARQ) LOOP
              --
              SELECT REG.NU_REG, 
                     REG.CD_MSG_ERR, 
                     REG.DS_MSG_ERR,
                     CASE 
                       WHEN REG.DS_MSG_ERR IS NULL AND REG.CD_MSG_ERR IS NULL        THEN  8  -- Processado com sucesso (linha)
                       WHEN REG.DS_MSG_ERR IS NOT NULL OR REG.CD_MSG_ERR IS NOT NULL THEN  9  -- Processado com erros (linha)
                     END,
                     RPT.VL_RPT                        -- 1.2
                INTO vNU_LIN,
                     vCD_MSG_PRC_CTD,
                     vVL_MSG_PRC_CTD,
                     vStatus,
                     vResponse                         -- 1.2
                FROM PTC_CMS_REG   REG,
                     PTC_CMS_REG_RPT RPT
               WHERE REG.CD_ARQ = gArq.CD_ARQ
                 AND REG.NU_REG = rRegFlPending.NU_LIN
                 AND REG.CD_ARQ = RPT.CD_ARQ(+)        -- 1.2
                 AND REG.NU_REG = RPT.NU_REG(+);       -- 1.2
              --
              ContentLineFileUpdate(pCD_ARQ         => rFilePending.CD_ARQ,
                                    pCD_ORI_ARQ     => rFilePending.CD_ORI_ARQ,
                                    pNU_LIN         => vNU_LIN,
                                    pCD_STA_PRC_LIN => vStatus,
                                    PDT_INI_PRC_LIN => gArq.DT_INI_PRC,
                                    pDT_FIM_PRC_LIN => gArq.DT_FIM_PRC,
                                    pCD_MSG_PRC_CTD => vCD_MSG_PRC_CTD,
                                    pVL_MSG_PRC_CTD => vVL_MSG_PRC_CTD,
                                    pVL_LIN_RET     => vResponse);       -- 1.2
              --
            END LOOP;
            --
          END IF;
          --
          -- 1.5 - início
          /*
          SELECT CASE 
                   WHEN gArq.CD_STA_CMM IN (79, 81, 80) THEN 6  -- Processado WEM
                 END
            INTO vStatus
            FROM DUAL;
          */
          vStatus := 6;
          -- 1.5 - fim
          --
          FileStatusUpdate(pCD_ARQ         => rFilePending.CD_ARQ,
                           pCD_ORI_ARQ     => rFilePending.CD_ORI_ARQ,
                           pCD_STA_PRC_ARQ => vStatus,
                           PDT_INI_PRC_ARQ => gArq.DT_INI_PRC,
                           pDT_FIM_PRC_ARQ => gArq.DT_FIM_PRC,
                           pDT_REC_RET     => SYSTIMESTAMP);
          --
          COMMIT;
          --
        EXCEPTION

          WHEN OTHERS THEN
            --
            ROLLBACK; 
            --
        END;
        --
      END IF;
      --
    END LOOP;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    WHEN OTHERS THEN
      --
      ROLLBACK; 
      --
  END OldFileReceivedFinisher;
  --
  --
  PROCEDURE FileReceivedFinisher IS
  BEGIN
    --
    OldFileReceivedFinisher; -- 1.8
    --
    NewFileReceivedFinisher; -- 1.8
    --
  END;
  --
  --  
  --------------------------------------------------------------------------------
  -- Retorna dados do modelo de arquivo (arquivo, setor e itens)
  --------------------------------------------------------------------------------
  PROCEDURE FileModelGetItem(pCD_MDL_ARQ      IN TKT_MDL_ARQ.CD_MDL_ARQ%TYPE,
                             CUR_OUT         OUT T_CURSOR,
                             CUR_SET         OUT T_CURSOR,
                             CUR_ITE         OUT T_CURSOR) IS
    --
    vModule VARCHAR2(100);
    vAction VARCHAR2(100);
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'FileModelGetItem');
    --
    OPEN CUR_OUT FOR SELECT ARQ.CD_MDL_ARQ,
                            ARQ.NM_MDL_ARQ,
                            ARQ.DC_MDL_ARQ,
                            ARQ.CD_CLI,
                            ARQ.NM_PDR_ARQ,
                            ARQ.VL_EXT_ARQ,
                            ARQ.NM_DIR_ARQ,
                            ARQ.IN_TIP_ARQ,
                            ARQ.IN_ARQ_OK,
                            ARQ.IN_TIP_DOS,
                            ARQ.NM_INT,
                            ARQ.VL_DAT_PRC,
                            ARQ.VL_SEP_VLR,
                            ARQ.IN_ARQ_RET,
                            ARQ.IN_ARQ_RET_PDR,
                            ARQ.CD_MDL_ARQ_ORI,
                            ARQ.QT_DGT_SET,
                            ARQ.CD_CMS_MDL_ARQ
                       FROM TKT_MDL_ARQ    ARQ
                      WHERE ARQ.CD_MDL_ARQ = pCD_MDL_ARQ;
    --
    OPEN CUR_SET FOR SELECT SEA.CD_SET_ARQ,
                            SEA.CD_MDL_ARQ,
                            SEA.VL_SEQ_SET_ARQ,
                            SEA.NM_SET_ARQ,
                            SEA.DC_SET_ARQ,
                            SEA.VL_IDE_SET_ARQ,
                            SEA.IN_CTD_SET_ARQ,
                            SEA.DS_SQL_FRO_SET_ARQ,
                            SEA.DS_SQL_WHE_SET_ARQ,
                            SEA.CD_STA_SET_ARQ,
                            SEA.DT_STA_SET_ARQ,
                            SEA.IN_SET_HDR,
                            SEA.IN_SET_TRL,
                            SEA.CD_CMS_MDL_REG,
                            SEA.IN_SET_OBR,
                            SEA.IN_SET_UNI,
                            SEA.NU_SET_TAM
                       FROM TKT_SET_ARQ    SEA
                      WHERE SEA.CD_MDL_ARQ = pCD_MDL_ARQ
                      ORDER BY SEA.CD_MDL_ARQ;
    --
    OPEN CUR_ITE FOR SELECT ITE.CD_ITE_ARQ,
                            ITE.CD_SET_ARQ,
                            ITE.VL_SEQ_ITE_ARQ,
                            ITE.DC_ITE_ARQ,
                            ITE.NM_ITE_ARQ,
                            ITE.NM_COL_ITE_ARQ,
                            ITE.IN_OBR_ITE_ARQ,
                            ITE.VL_TIP_DAD_ITE_ARQ,
                            ITE.VL_TAM_COL_ITE_ARQ,
                            ITE.VL_TAM_DEC_COL_ITE_ARQ,
                            ITE.IN_ALI_COL_ITE_ARQ,
                            ITE.VL_FMT_MSK_ITE_ARQ,
                            ITE.VL_POS_INI_ITE_ARQ,
                            ITE.VL_POS_FIM_ITE_ARQ,
                            ITE.IN_TIP_ORI_ITE_ARQ,
                            ITE.IN_ITE_TOT,
                            ITE.CD_CMS_MDL_CTD
                       FROM TKT_ITE_ARQ   ITE,
                            TKT_SET_ARQ   SEA
                      WHERE SEA.CD_MDL_ARQ = pCD_MDL_ARQ
                        AND SEA.CD_SET_ARQ = ITE.CD_SET_ARQ
                        AND ITE.VL_POS_INI_ITE_ARQ IS NOT NULL
                        AND ITE.VL_POS_FIM_ITE_ARQ IS NOT NULL
                      ORDER BY SEA.CD_SET_ARQ,
                               ITE.CD_ITE_ARQ;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  END;
  --

  --------------------------------------------------------------------------------
  -- Retorna Lista de Arquivos
  --------------------------------------------------------------------------------
  PROCEDURE FileModelGetList(STARTPAGE        IN NUMBER := NULL,
                             PAGEROWS         IN NUMBER := NULL,
                             CUR_OUT         OUT T_CURSOR) IS
    --
    vModule VARCHAR2(100);
    vAction VARCHAR2(100);
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'FileModelGetList');
    --
    IF  STARTPAGE IS NULL AND
        PAGEROWS IS NULL THEN
        OPEN CUR_OUT FOR
          SELECT (COUNT(1) OVER(PARTITION BY 1)) LINES,
                 ROWNUM ROWPAG,
                 ARQ.CD_MDL_ARQ,
                 ARQ.NM_MDL_ARQ,
                 ARQ.DC_MDL_ARQ,
                 ARQ.CD_CLI,
                 CLI.NM_RAZ_SOC,
                 ARQ.NM_PDR_ARQ,
                 ARQ.VL_EXT_ARQ,
                 ARQ.NM_DIR_ARQ,
                 ARQ.IN_TIP_ARQ,
                 ARQ.IN_ARQ_OK,
                 ARQ.IN_TIP_DOS,
                 ARQ.NM_INT,
                 ARQ.VL_DAT_PRC,
                 ARQ.VL_SEP_VLR,
                 ARQ.IN_ARQ_RET,
                 ARQ.IN_ARQ_RET_PDR,
                 ARQ.CD_MDL_ARQ_ORI,
                 ARQ.QT_DGT_SET,
                 ARQ.CD_CMS_MDL_ARQ
            FROM TKT_MDL_ARQ    ARQ,
                 PTC_CLI        CLI
           WHERE ARQ.CD_CLI   = CLI.CD_CLI (+)
           ORDER BY ARQ.CD_MDL_ARQ;                                            
    ELSE
        OPEN CUR_OUT FOR
          SELECT *
            FROM (SELECT (COUNT(1) OVER(PARTITION BY 1)) LINES,
                         RANK() OVER(ORDER BY ARQ.CD_MDL_ARQ) ROWPAG,
                         ARQ.CD_MDL_ARQ,
                         ARQ.NM_MDL_ARQ,
                         ARQ.DC_MDL_ARQ,
                         ARQ.CD_CLI,
                         CLI.NM_RAZ_SOC,
                         ARQ.NM_PDR_ARQ,
                         ARQ.VL_EXT_ARQ,
                         ARQ.NM_DIR_ARQ,
                         ARQ.IN_TIP_ARQ,
                         ARQ.IN_ARQ_OK,
                         ARQ.IN_TIP_DOS,
                         ARQ.NM_INT,
                         ARQ.VL_DAT_PRC,
                         ARQ.VL_SEP_VLR,
                         ARQ.IN_ARQ_RET,
                         ARQ.IN_ARQ_RET_PDR,
                         ARQ.CD_MDL_ARQ_ORI,
                         ARQ.QT_DGT_SET,
                         ARQ.CD_CMS_MDL_ARQ
                    FROM TKT_MDL_ARQ    ARQ,
                         PTC_CLI        CLI
                   WHERE ARQ.CD_CLI   = CLI.CD_CLI (+)
                   ORDER BY ARQ.CD_MDL_ARQ) RETORNO 
             WHERE RETORNO.ROWPAG BETWEEN ((STARTPAGE * PAGEROWS) + 1) 
               AND ((STARTPAGE * PAGEROWS) + PAGEROWS);  
     
    END IF;
    --
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  END;
  --
  --------------------------------------------------------------------------------
  -- Criação de Arquivos
  --------------------------------------------------------------------------------
  PROCEDURE FileCreate(pCD_MDL_ARQ     IN TKT_ARQ.CD_MDL_ARQ%TYPE,
                       pNM_ARQ         IN TKT_ARQ.NM_ARQ%TYPE,
                       pCD_CTR_EXT     IN TKT_ARQ.CD_CTR_EXT%TYPE,
                       pCONTROL_SEQ_ID IN TKT_ARQ.CONTROL_SEQ_ID%TYPE DEFAULT NULL,
                       pDT_REC_ARQ     IN TKT_ARQ.DT_REC_ARQ%TYPE,    
                       pCD_ARQ_ORI     IN TKT_ARQ.CD_ARQ_ORI%TYPE DEFAULT NULL,
                       pCD_CLI         IN TKT_ARQ.CD_CLI%TYPE DEFAULT NULL,
                       pCD_CMS_ARQ     IN TKT_ARQ.CD_CMS_ARQ%TYPE,    
                       pCD_ARQ        OUT TKT_ARQ.CD_ARQ%TYPE,
                       pMSG_USER      OUT NOCOPY VARCHAR2,
                       pCOD_RET       OUT NOCOPY NUMBER,
                       pMSG_RET       OUT NOCOPY VARCHAR2) IS
    --
    vModule     VARCHAR2(100);
    vAction     VARCHAR2(100);
    --
    vQtde       NUMBER;
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'FileCreate');
    --
    -- 1.3
    -- Geração de Log de Auditoria
    WTMX_UTILITY_PKG.AuditLogCreate(pCD_USU => NULL,
				                            pEN_IP  => NULL,
			                              pNM_PCK => 'WTMX_FILEPROCESSOR_PKG.FileCreate');
    --
    -- Verifica se o arquivo informado já existe
    SELECT COUNT(1)
      INTO vQtde
      FROM TKT_ARQ
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
    
    -- Obtém a próxima sequencia a ser utilizada
    SELECT NVL(MAX(CD_ARQ), 0) + 1
      INTO pCD_ARQ
      FROM TKT_ARQ;
    --
    -- Inclusão da TKT_ARQ
    --
    INSERT INTO TKT_ARQ (CD_ARQ,
                         CD_MDL_ARQ,	
                         CD_CTR_EXT,
                         CONTROL_SEQ_ID,	
                         NM_ARQ,	
                         DT_REC_ARQ,	
                         DT_INI_PRC_ARQ,
                         DT_FIM_PRC_ARQ,
                         CD_STA_PRC_ARQ,	
                         VL_MSG_PRC_ARQ,
                         CD_ARQ_ORI,
                         CD_CLI,	
                         CD_CMS_ARQ)
                 VALUES (pCD_ARQ,	
                         pCD_MDL_ARQ,
                         pCD_CTR_EXT,
                         NVL(pCONTROL_SEQ_ID, 0),	
                         pNM_ARQ,	
                         NVL(pDT_REC_ARQ, SYSDATE),
                         NULL,          -- DT_INI_PRC_ARQ
                         NULL,          -- DT_FIM_PRC_ARQ
                         0,             -- CD_STA_PRC_ARQ  (0 = Recebendo Dados)
                         NULL,          -- VL_MSG_PRC_ARQ	
                         pCD_ARQ_ORI,
                         pCD_CLI,
                         pCD_CMS_ARQ);
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    WHEN OTHERS THEN
      pMSG_USER := WT_UTILITY_PKG.GetMessage(SQLCODE);
      pCOD_RET  := SQLCODE;
      pMSG_RET  := SQLERRM;
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
  END;
  --
  
  --------------------------------------------------------------------------------
  -- Criação do Conteúdo de Arquivos
  --------------------------------------------------------------------------------
  PROCEDURE FileContentCreate(pCD_ARQ         IN TKT_ARQ.CD_ARQ%TYPE,
                              pNU_REG         IN TKT_ARQ_CTD.NU_LIN%TYPE,
                              pCONTENT        IN TKT_ARQ_CTD.VL_LIN%TYPE,
                              pMSG_USER      OUT NOCOPY VARCHAR2,
                              pCOD_RET       OUT NOCOPY NUMBER,
                              pMSG_RET       OUT NOCOPY VARCHAR2) IS
    --
    vModule     VARCHAR2(100);
    vAction     VARCHAR2(100);
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'FileContentCreate');
    --
    -- 1.3
    -- Geração de Log de Auditoria
    WTMX_UTILITY_PKG.AuditLogCreate(pCD_USU => NULL,
				                            pEN_IP  => NULL,
				                            pNM_PCK => 'WTMX_FILEPROCESSOR_PKG.FileContentCreate');
    --
    -- Inclusão da TKT_ARQ_CTD
    INSERT INTO TKT_ARQ_CTD (NU_LIN,
                             CD_ARQ,
                             VL_LIN)
                     VALUES (pNU_REG,
                             pCD_ARQ,
                             pCONTENT);
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      pMSG_USER := WT_UTILITY_PKG.GetMessage(SQLCODE);
      pCOD_RET  := SQLCODE;
      pMSG_RET  := SQLERRM;
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
  END;
  --
  --------------------------------------------------------------------------------
  -- Criação do Conteúdo de Arquivos - Versão Lista
  --------------------------------------------------------------------------------
  PROCEDURE FileContentCreate(pCD_ARQ   IN TKT_ARQ.CD_ARQ%TYPE,
                              pCONTENT  IN CLOB,
                              pMSG_USER OUT NOCOPY VARCHAR2,
                              pCOD_RET  OUT NOCOPY NUMBER,
                              pMSG_RET  OUT NOCOPY VARCHAR2) IS
    --
    vContent         TabMassiveLoadArchive;
    --
    vModule VARCHAR2(100);
    vAction VARCHAR2(100);
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'FileContentCreate');
    --
    -- 1.3
    -- Geração de Log de Auditoria
    WTMX_UTILITY_PKG.AuditLogCreate(pCD_USU => NULL,
			    	                        pEN_IP  => NULL,
			                              pNM_PCK => 'WTMX_FILEPROCESSOR_PKG.FileContentCreate');
    --
    IF  pCONTENT IS NOT NULL THEN
        FileLoad(pDados           => pCONTENT,
                 pSeparator       => FuncColSeparator,
                 pSeparatorLine   => FuncItemsEparator,
                 pContent         => vContent);
        --
        
        FOR i IN vContent.FIRST() .. vContent.LAST() LOOP
            -- Inclusão da TKT_ARQ_CTD
            INSERT INTO TKT_ARQ_CTD (NU_LIN,
                                     CD_ARQ,
                                     VL_LIN)
                             VALUES (vContent(i).Linha,
                                     pCD_ARQ,
                                     vContent(i).Dados);
            --
        END LOOP;
        --
    END IF;
    --
    COMMIT; -- Como terminou de realizar a inclusão total dos registros, grava as alterações
    --
    FileProcess(pCD_ARQ     => pCD_ARQ, 
                pMSG_USER   => pMSG_USER, 
                pCOD_RET    => pCOD_RET, 
                pMSG_RET    => pCOD_RET);
    --
    -- Executa a proc de transferência do conteúdo das TKTs para as CMSs (processo em avaliação)
    --
    IF  NVL(pCOD_RET, 0) = 0 THEN
        FileReceivedLoader;
    END IF;
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
  END;
  --

  --------------------------------------------------------------------------------
  -- Disponibiliza arquivo e itens para processamento
  --------------------------------------------------------------------------------
  PROCEDURE FileProcess(pCD_ARQ         IN TKT_ARQ.CD_ARQ%TYPE,
                        pCD_ORI_ARQ     IN TKT_ARQ.CD_ORI_ARQ%TYPE DEFAULT 1,
                        pMSG_USER      OUT NOCOPY VARCHAR2,
                        pCOD_RET       OUT NOCOPY NUMBER,
                        pMSG_RET       OUT NOCOPY VARCHAR2) IS
    --
    vModule     VARCHAR2(100);
    vAction     VARCHAR2(100);
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'FileProcess');
    --
    -- 1.3
    -- Geração de Log de Auditoria
    WTMX_UTILITY_PKG.AuditLogCreate(pCD_USU => NULL,
    			                          pEN_IP  => NULL,
			                              pNM_PCK => 'WTMX_FILEPROCESSOR_PKG.FileProcess');
    --
    ContentLineFileUpdate(pCD_ARQ          => PCD_ARQ,
                          pCD_ORI_ARQ      => pCD_ORI_ARQ,
                          pCD_STA_PRC_LIN  => 2);
    --
    FileStatusUpdate(pCD_ARQ         => PCD_ARQ,
                     pCD_ORI_ARQ     => pCD_ORI_ARQ,
                     pCD_STA_PRC_ARQ => 1);
    --
    pCOD_RET := 0;
    pMSG_USER := WT_UTILITY_PKG.GetMessage(pCOD_RET);
    pMSG_RET := pMSG_USER;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);        
    --
  EXCEPTION
    WHEN OTHERS THEN
      --
      pMSG_USER := WT_UTILITY_PKG.GetMessage(SQLCODE);
      pCOD_RET  := SQLCODE;
      pMSG_RET  := SQLERRM;
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
  END FileProcess;
  --  
  ------------------------------------------------------------------------------------------------
  -- Disponibiliza todos os arquivo e itens pendentes recebidos por GoldenGate para processamento
  ------------------------------------------------------------------------------------------------
  PROCEDURE FileProcessAllGG IS
    --
    vModule     VARCHAR2(100);
    vAction     VARCHAR2(100);
    --
    vMSG_USER   VARCHAR2(500);
    vCOD_RET    NUMBER;
    vMSG_RET    VARCHAR2(500);
    --
    vTrailler INTEGER;
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'FileProcessAllGG');
    --
    FOR rFilePendente IN (SELECT A.CD_ARQ
                            FROM TKT_ARQ A
                           WHERE A.CD_ORI_ARQ = 2 -- recebido por replicação 
                             AND A.CD_STA_PRC_ARQ = 0) LOOP
      --
      SELECT COUNT(1)
      INTO vTrailler
      FROM TKT_ARQ_CTD C
      WHERE C.CD_ARQ = rFilePendente.Cd_Arq
        AND SUBSTR(TO_CHAR(C.VL_LIN), 1, 2) = '99';
      --  
      IF vTrailler > 0 THEN  
        FileProcess(pCD_ARQ     => rFilePendente.CD_ARQ, 
                    pCD_ORI_ARQ => 2,
                    pMSG_USER   => vMSG_USER,
                    pCOD_RET    => vCOD_RET, 
                    pMSG_RET    => vMSG_RET);
        --
        IF NVL(vCOD_RET, 0) > 0 THEN
          --
          RAISE EProcessTransferError;
          --
        END IF;
        --
      END IF;
      
    END LOOP;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);        
    --
  EXCEPTION
    WHEN OTHERS THEN
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      RAISE_APPLICATION_ERROR(-20001, TO_CHAR(vCOD_RET) || ' - ' || vMSG_RET);
      --
  END FileProcessAllGG;
  --
END WTMX_FILEPROCESSOR_PKG;
