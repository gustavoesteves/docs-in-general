CREATE OR REPLACE PACKAGE BODY WTMX_CMS_PREAUTHORIZATION_PKG IS
  --
  -- *********************
  -- * INTERNAL TYPES    *
  -- *********************
  --
  TYPE TLinhasParcial IS TABLE OF NUMBER;
  --
  TYPE T_Rec IS RECORD(
    NU_LINHA             NUMBER(6),
    IN_ERRO              NUMBER(1),
    IN_FINANCEIRO        VARCHAR2(1),
    NU_PED               PTC_PAT.NU_PED%TYPE,
    CD_PAT               PTC_PAT.CD_PAT%TYPE,
    CD_TIP_PAT           PTC_PAT.CD_TIP_PAT%TYPE,
    DT_HR_INI_VIG        PTC_PAT.DT_HR_INI_VIG%TYPE,
    DT_HR_FIM_VIG        PTC_PAT.DT_HR_FIM_VIG%TYPE,
    NU_MAX_OPE           PTC_PAT.NU_MAX_OPE%TYPE,
    VL_TOT_INF           PTC_PAT.VL_TOT_INF%TYPE,
    VL_MIN_CAN_AUT       PTC_PAT.VL_MIN_CAN_AUT%TYPE,
    NU_PCT_MIN_CAN_AUT   PTC_PAT.NU_PCT_MIN_CAN_AUT%TYPE,
    CD_VGE               PTC_PAT.CD_VGE%TYPE,
    CD_PTD               PTC_PAT.CD_PTD%TYPE,
    CD_TRJ               PTC_PAT.CD_TRJ%TYPE,
    DC_OBS               PTC_PAT.DC_OBS%TYPE,
    IN_BMB_PRP           varchar2(1),         -- 1.03
    TP_CSM               PTC_PAT.TP_CSM%TYPE, -- 1.03
    NU_PED_EXT           PTC_PAT.NU_PED_EXT%TYPE,
    CD_CTR_ETB           PTC_CTR_ETB.CD_CTR%TYPE,
    MerchandiseList      VARCHAR2(32000),
    DriverList           VARCHAR2(32000),
    RestrictionList      VARCHAR2(32000),
    ContractList         VARCHAR2(32000),
    CD_SUB_RED           TKT_CMS_1038_155_PREAUT_HEADER.ACCEPTRESTRICTIONIDENTIFACTION%TYPE);


  --
  TYPE T_Tab_Rec IS TABLE OF T_Rec INDEX BY BINARY_INTEGER;
  --
  -- *********************
  -- * VARIAVEIS GLOBAIS *
  -- *********************
  --
  vModule            VARCHAR2(100);
  vAction            VARCHAR2(100);
  vUserMessageLine   VARCHAR2(500);
  vReturnCodeLine    NUMBER;
  vReturnMessageLine VARCHAR2(500);
  --
  -- ***********************************************
  -- * VARIAVEIS PARA CONTROLE DE EXCECOES GLOBAIS *
  -- ***********************************************
  --
  vExceptionType VARCHAR2(50);
  --
  -- **********************
  -- * GetContent METHODS *
  -- **********************
  --

  --
  -- *********************
  -- * PUBLIC METHODS    *
  -- *********************
  --
  ----------------------------------------------------
  -- Procedure Especialista - ProcessError
  ----------------------------------------------------
  PROCEDURE ProcessError(PCOD_RET   IN PTC_CMS_ARQ_EXC.CD_ERR_EXC%TYPE,
                         PTRACK     IN PTC_CMS_ARQ_EXC.DC_CPL_EXC%TYPE,
                         PRAISE     IN BOOLEAN DEFAULT FALSE) IS
    BEGIN
      --
      WTMX_MASSIVELOAD_PKG.InsertException
                        (PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                         PCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                         PNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                         PCD_ERR_EXC => PCOD_RET,
                         PDC_ERR_EXC => WTMX_UTILITY_PKG.GetMessage(PCOD_RET),
                         PDC_CPL_EXC => PTRACK);
      IF PRAISE THEN
        -- Error in call to CardIssuingCreate
        RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
      END IF;
  END;

 ----------------------------------------------------
  -- Procedure Especialista - UpdateLine
  ----------------------------------------------------
  PROCEDURE UpdateLine(PNU_REG     IN INTEGER DEFAULT NULL,
                       PCD_MSG_ERR IN PTC_CMS_REG.CD_MSG_ERR%TYPE,
                       PDS_MSG_ERR IN PTC_CMS_REG.DS_MSG_ERR%TYPE,
                       PTRACK      IN PTC_CMS_ARQ_EXC.DC_CPL_EXC%TYPE,
                       PRAISE_EXC  IN BOOLEAN DEFAULT FALSE) IS
  vUserMessageLine   VARCHAR2(500);
  vReturnCodeLine    NUMBER;
  vReturnMessageLine VARCHAR2(500);
  --
  BEGIN
    --
    WTMX_MASSIVELOAD_PKG.UpdateRelatedLines(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                            PCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                            PNU_REG     => PNU_REG,
                                            PCD_MSG_ERR => PCD_MSG_ERR,
                                            PDS_MSG_ERR => NVL(PDS_MSG_ERR, WT_UTILITY_PKG.GetMessage(PCD_MSG_ERR)),
                                            pMSG_USER   => vUserMessageLine,
                                            pCOD_RET    => vReturnCodeLine,
                                            pMSG_RET    => vReturnMessageLine);
    --
    IF NVL(vReturnCodeLine,0) <> 0 THEN
      --
      ProcessError(vReturnCodeLine, PTRACK, PRAISE_EXC);
      --
    END IF;
  END;

  ----------------------------------------------------------------------
  -- Procedure para a geração da interface
  ----------------------------------------------------------------------

  PROCEDURE GenerateInterface(pCD_ARQ         IN TKT_CMS_1038_155_PREAUT_HEADER.FILEID%TYPE,
                                           pCD_DOM         IN TKT_CMS_1038_155_PREAUT_HEADER.DOMAINID%TYPE,
                                           pCD_BAS         IN PTC_BAS.CD_BAS%TYPE,
                                           pCD_CTR_CLI     IN PTC_CTR_CLI.CD_CTR_CLI%TYPE,
                                           pTab_Rec        IN T_Tab_Rec,
                                           pQtd_int        OUT INTEGER,
                                           PMSG_USER       OUT NOCOPY VARCHAR2,
                                           PCOD_RET        OUT NOCOPY NUMBER,
                                           PMSG_RET        OUT NOCOPY VARCHAR2) IS
    --
    PRAGMA AUTONOMOUS_TRANSACTION;
    --
  BEGIN
    --
    pQtd_int:=0;
    --
    DELETE TKT_CMS_1038_155_PREAUT_HEADER
     WHERE FILEID = pCD_ARQ
       AND DOMAINID = pCD_DOM;
    --
    FOR i IN pTab_Rec.FIRST() .. pTab_Rec.LAST() LOOP
      --
      IF NVL(pTab_Rec(i).IN_ERRO,0) = 0  THEN
        --
        pQtd_int:= NVL(pQtd_int,0) + 1;
        --
        INSERT INTO TKT_CMS_1038_155_PREAUT_HEADER
                   (FILEID,
                    DOMAINID,
                    ROWNUMBER,
                    OPERATIONCLASS,
                    CORPORATELEVELID,
                    CARDHOLDERID,
                    CREDITLINETYPEID,
                    CUSTOMERCONTRACTID,
                    ORDERID,
                    ORDERNUMBER,
                    CREDITAMOUNT,
                    CURRENCYID,
                    ORDEREDQUANTITY,
                    EXPIRATIONBEGINDATETIME,
                    EXPIRATIONENDDATETIME,
                    MINIMUMVALUETOCANCEL,
                    MINIMUMPERCENTAGETOCANCEL,
                    TYPEIDENTIFICATION,
                    USAGEQUANTITY,
                    TRIPREFERENCE,
                    ACCEPTRESTRICTIONIDENTIFACTION)
        VALUES
         (pCD_ARQ, -- Codigo do Arquivo a ser processado
          pCD_DOM, -- Codigo do dominio a ser processado
          pTab_Rec(i).NU_LINHA, -- Numero da Linha a ser processada
          'CREATE',
          pCD_BAS,
          pTab_Rec(i).CD_PTD,
          1,
          pCD_CTR_CLI,
          NULL,
          NULL,
          pTab_Rec(i).VL_TOT_INF,
          484,
          1,
          pTab_Rec(i).DT_HR_INI_VIG,
          pTab_Rec(i).DT_HR_FIM_VIG,
          pTab_Rec(i).VL_MIN_CAN_AUT,
          pTab_Rec(i).NU_PCT_MIN_CAN_AUT,
          pTab_Rec(i).CD_TIP_PAT,
          pTab_Rec(i).NU_MAX_OPE,
          pTab_Rec(i).CD_VGE,
          pTab_Rec(i).CD_SUB_RED);

          FOR Contract IN (SELECT COLUMN01 CD_CTR_ETB
                           FROM TABLE(mx_adm.SplitTable(pTab_Rec(i).ContractList, '|', '|'))) LOOP

              INSERT INTO TKT_CMS_1038_155_PREAUT_MERCHT
                        (FILEID,
                         DOMAINID,
                         ROWNUMBER,
                         MERCHANTCONTRACTID,
                         EFFECT,
                         RESPONSEMESSAGE,
                         RESPONSECODE)
                 VALUES (pCD_ARQ,              -- FILEID
                         pCD_DOM,              -- DOMAINID
                         pTab_Rec(i).NU_LINHA, -- ROWNUMBER
                         Contract.CD_CTR_ETB,  -- MERCHANTCONTRACTID
                         NULL,                 -- EFFECT
                         NULL,                 -- RESPONSEMESSAGE
                         NULL);                -- RESPONSECODE


          END LOOP;
      END IF;
      --
    END LOOP;
    --
    COMMIT;
    --
  EXCEPTION
    WHEN OTHERS THEN
      PMSG_USER := WT_UTILITY_PKG.GetMessage(SQLCODE);
      PCOD_RET  := SQLCODE;
      PMSG_RET  := SQLERRM;
      --
      ROLLBACK;
      --
  END;

  --
  ----------------------------------------------------------------------
  -- Procedure de Parcial Especialista
  ----------------------------------------------------------------------
  PROCEDURE PreAuthorizationCrud(pCD_BAS         IN OUT PTC_BAS.CD_BAS%TYPE,
                                 pCD_GST         IN OUT PTC_GST.CD_GST%TYPE,
                                 pCD_CSL         IN OUT PTC_GST.CD_CSL%TYPE,
                                 pCD_CTR_CLI     IN PTC_CTR_CLI.CD_CTR_CLI%TYPE,
                                 pInFinanceiro   IN VARCHAR2 DEFAULT NULL,
                                 pTab_Rec        IN OUT T_Tab_Rec,
                                 pIN_PARCIAL_SNN IN BOOLEAN DEFAULT FALSE,
                                 pMSG_USER       OUT NOCOPY VARCHAR2,
                                 pCOD_RET        OUT NOCOPY NUMBER,
                                 pMSG_RET        OUT NOCOPY VARCHAR2) IS
    --
    vCD_PDT           PTC_CTR_CLI.CD_PDT%TYPE;
    vTrack            VARCHAR2(500);
    --
    vCD_USU_SOL     PTC_USU.CD_USU%TYPE;

  BEGIN
    --
    SELECT CD_PDT
    INTO vCD_PDT
    FROM PTC_CTR_CLI CC
    WHERE CC.CD_CTR_CLI = pCD_CTR_CLI;
    --
    --
    FOR i IN pTab_Rec.FIRST() .. pTab_Rec.LAST() LOOP
      --
      vTrack:= 'ler linhas retornadas';
      --
      vReturnCodeLine:= 0;
      --
      IF NVL(pTab_Rec(i).IN_ERRO,0) = 0 AND
         (pInFinanceiro IS NULL OR pInFinanceiro = pTab_Rec(i).IN_FINANCEIRO) THEN
        --
        --
        BEGIN
          --
          SAVEPOINT spLINHA;
          --

    SELECT MAX(GST.CD_USU)
                     INTO vCD_USU_SOL
                     FROM PTC_GST GST
                    WHERE GST.CD_GST = pCD_GST
                      AND GST.CD_CSL = pCD_CSL;
          --
          --
          --
          vTrack:= 'cadastrar nota vale';
          --
          WT2MX_PREAUTHORIZATION_MNT.PreAuthorizationOrderCreate( pNU_PED      => pTab_Rec(i).NU_PED, -- 1.03
                                pCD_PAT               => pTab_Rec(i).CD_PAT,
                                pCD_USU_SOL           => vCD_USU_SOL,
                                pCD_BAS               => pCD_BAS,
                                pCD_TIP_PAT           => pTab_Rec(i).CD_TIP_PAT,
                                pDT_HR_INI_VIG        => pTab_Rec(i).DT_HR_INI_VIG,
                                pDT_HR_FIM_VIG        => pTab_Rec(i).DT_HR_FIM_VIG,
                                pNU_MAX_OPE           => pTab_Rec(i).NU_MAX_OPE,
                                pVL_TOT_INF           => pTab_Rec(i).VL_TOT_INF,
                                pVL_MIN_CAN_AUT       => pTab_Rec(i).VL_MIN_CAN_AUT,
                                pNU_PCT_MIN_CAN_AUT   => pTab_Rec(i).NU_PCT_MIN_CAN_AUT,
                                pCD_VGE               => pTab_Rec(i).CD_VGE,
                                pCD_PTD               => pTab_Rec(i).CD_PTD,
                                pCD_TRJ               => pTab_Rec(i).CD_TRJ,
                                pDC_OBS               => pTab_Rec(i).DC_OBS,
                                pCD_GST               => pCD_GST,
                                pTP_CSM               => pTab_Rec(i).TP_CSM, --IN_BMB_PRP, -- 4.11, 1.03
                                pMerchandiseList      => pTab_Rec(i).MerchandiseList,
                                pDriverList           => pTab_Rec(i).DriverList,
                                pRestrictionList      => pTab_Rec(i).RestrictionList,
                                pNU_PED_EXT           => pTab_Rec(i).NU_PED_EXT,
                                pUSER                 => NULL,
                                pIP                   => 'MASSIVE LOAD',
                                PMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                PCOD_RET => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                PMSG_RET => WTMX_MASSIVELOAD_PKG.vReturnMessage);
          --
          IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
            --
            UpdateLine(pNU_REG     => pTab_Rec(i).NU_LINHA,
                       pCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                       pDS_MSG_ERR => NVL(WTMX_MASSIVELOAD_PKG.vUserMessage, WTMX_MASSIVELOAD_PKG.vReturnMessage),
                       PTRACK      => 'PreAuthorizationCrud. Erro ao '||vTrack,
                       PRAISE_EXC  => TRUE);
            --
            RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
            --
          END IF;
          --
          -- Associar pedido ao arquivo
          INSERT INTO PTC_CMS_ARQ_PED
          (CD_ARQ, NU_PED, CD_DOM)
          VALUES
          (WT_MASSIVELOAD_PKG.gFile.CD_ARQ, pTab_Rec(i).NU_PED, WT_MASSIVELOAD_PKG.gFile.CD_DOM);
          --
          --
          IF WT_MASSIVELOAD_PKG.gFile.TP_PRC = 'P' THEN
            IF WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'A' THEN
              COMMIT;
            ELSE
              ROLLBACK TO spLINHA;
            END IF;
          END IF;
          --
        EXCEPTION
          WHEN WTMX_MASSIVELOAD_PKG.EProcessError THEN
            --
            ROLLBACK TO spLINHA;
            --
            IF pIN_PARCIAL_SNN  THEN
              pMSG_USER:= WTMX_MASSIVELOAD_PKG.vReturnMessage;
              pCOD_RET := WTMX_MASSIVELOAD_PKG.vReturnCode;
              pMSG_RET := pMSG_USER;
              RAISE;
            END IF;
            --
          WHEN OTHERS THEN
            --
            ROLLBACK TO spLINHA;
            --
            UpdateLine(pNU_REG     => pTab_Rec(i).NU_LINHA,
                     pCD_MSG_ERR => SQLCODE,
                     pDS_MSG_ERR => SQLERRM,
                     PTRACK      => 'PreAuthorizationCrud. Erro ao '||vTrack,
                     PRAISE_EXC  => TRUE);
            --
            IF pIN_PARCIAL_SNN  THEN
              pMSG_USER:= WTMX_MASSIVELOAD_PKG.vReturnMessage;
              pCOD_RET := WTMX_MASSIVELOAD_PKG.vReturnCode;
              pMSG_RET := pMSG_USER;
              RAISE;
            END IF;
            --
        END;
        --
      END IF;
      --
    END LOOP;
    --
    --
  EXCEPTION
  --
    WHEN WTMX_MASSIVELOAD_PKG.EProcessError THEN
      --
      --ROLLBACK;
      --
      pCOD_RET := NVL(pCOD_RET, 9999);
      pMSG_USER:= WTMX_UTILITY_PKG.GetMessage(pCOD_RET);
      pMSG_RET := pMSG_USER;
      --
      WTMX_MASSIVELOAD_PKG.vExceptionType := 'EProcessError';
      --
    WHEN OTHERS THEN
      --
      --ROLLBACK;
      --
      pCOD_RET := SQLCODE;
      pMSG_USER:= WTMX_UTILITY_PKG.GetMessage(pCOD_RET);
      pMSG_RET := pMSG_USER;
      --
      UpdateLine(pNU_REG     => NULL,
                 pCD_MSG_ERR => SQLCODE,
                 pDS_MSG_ERR => SQLERRM,
                 PTRACK      => 'PreAuthorizationCrud. Erro ao '||vTrack,
                 PRAISE_EXC  => FALSE);
      --
  END;
  --
  -------------------------------------------------------------------
  -- Procedure para Carga de Dados
  -------------------------------------------------------------------
  PROCEDURE PreAuthorizationLoad(pCD_BAS         IN OUT PTC_BAS.CD_BAS%TYPE,
                                 pCD_GST         IN OUT PTC_GST.CD_GST%TYPE,
                                 pCD_CSL         IN OUT PTC_GST.CD_CSL%TYPE,
                                 pCD_CTR_CLI     IN OUT PTC_CTR_CLI.CD_CTR_CLI%TYPE,
--                                 pNU_PED_EXT     IN OUT PTC_PED.NU_PED_EXT%TYPE,
                                 pTab_Rec        IN OUT T_Tab_Rec,
                                 pIN_VALIDACAO_INICIAL  IN BOOLEAN DEFAULT TRUE,
                                 pQtde_PTD       IN OUT NUMBER,
                                 pQtde_CAT       IN OUT NUMBER,
                                 pLinhasParcial  IN     tLinhasParcial DEFAULT NULL,
                                 pMSG_USER       OUT NOCOPY VARCHAR2,
                                 pCOD_RET        OUT NOCOPY NUMBER,
                                 pMSG_RET        OUT NOCOPY VARCHAR2) IS
    --
    vPar        TY_AUDIT_PARAM_TBL;
    --
    -- Variaveis de trabalho e retorno
    iSeq            NUMBER(6);
    vTpReg          NUMBER(2);
   -- vSeq            NUMBER;
    vCD_GST         PTC_GST.CD_GST%TYPE;
    vCD_TIP_GST     PTC_GST.CD_TIP_GST%TYPE;
    vQtde           NUMBER;
    vQtde_PTD       NUMBER;
    vQtde_CAT       NUMBER;
    vRiskConditionReasonCodeId T_GCARD.RISKCONDITIONREASONCODEID%TYPE;
    --
    --
    --
    vTrack VARCHAR2(500);
    --
    vPartial BOOLEAN;
    --
    vLinhaParcial INTEGER;
    vIdxParcial   INTEGER;
    --
    vCdMercadoria   PTC_MRD.CD_MRD%TYPE;
    vQtMercadoria   NUMBER;
    vVlUnMercadoria NUMBER;
    vQtdKM NUMBER;
    vRendimento NUMBER;
    vCD_ETD_PSS     PTC_ETD.CD_ETD%TYPE;
    vHrInicio       DATE;
    vHrFim          DATE;
    vPeriodicidade  PTC_PDC.CD_PDC%TYPE;
    --
    vCard                 VARCHAR2(20);
    vTagNfcNum            VARCHAR2(20);
    vTagNfcId             VARCHAR2(20);

  BEGIN
    --
    -- Auditoria -------------------------------------------------------------------
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'PreAuthorizationLoad');
    vPar    := TY_AUDIT_PARAM_TBL();
    vPar.EXTEND(3);
    vPar(1) := TY_AUDIT_PARAM_OBJ('CD_ARQ'         , WT_MASSIVELOAD_PKG.gFile.CD_ARQ);
    vPar(2) := TY_AUDIT_PARAM_OBJ('CD_DOM'         , WT_MASSIVELOAD_PKG.gFile.CD_DOM);
    vPar(3) := TY_AUDIT_PARAM_OBJ('NU_REG'         , WT_MASSIVELOAD_PKG.gFile.NU_REG);
    --
    WT2_AUDIT_UTL.AuditCreate(pCD_USU => SYS_CONTEXT('USERENV', 'OS_USER'),
                              pDS_ORI => $$PLSQL_UNIT||'.PreAuthorizationLoad',
                              pEN_IP  => SYS_CONTEXT('USERENV', 'HOST'),
                              pID_MSG => NULL,
                              pID_REQ => NULL,
                              pPRM    => vPar,
                              pCLOB   => NULL);
    ---------------------------------------------------------------------------
    --
    --
    -- Preparação do Type de Veiculos para validações
    vTrack:= 'inicializar variaveis';
    iSeq      := 0;
    vQtde_PTD := 0;
    vQtde_CAT := 0;
    pTab_Rec.DELETE;
    vPartial  := FALSE;

    --
    -- Tratamento para as linhas retornadas da validação
    IF WTMX_MASSIVELOAD_PKG.vLines.COUNT > 0 THEN
    --
      vTrack:= 'ler linhas retornadas';

      IF pLinhasParcial IS NOT NULL AND pLinhasParcial.COUNT > 0 THEN
        vPartial:= TRUE;
        vLinhaParcial:= WT_MASSIVELOAD_PKG.gFile.NU_REG;
      END IF;
      --
      IF vPartial THEN
         WT_MASSIVELOAD_PKG.gFile.NU_REG := pLinhasParcial(pLinhasParcial.FIRST);
         vIdxParcial                     := pLinhasParcial.FIRST;
      ELSE
         WT_MASSIVELOAD_PKG.gFile.NU_REG := WTMX_MASSIVELOAD_PKG.vLines.FIRST;
      END IF;
      --
      --
      WHILE WT_MASSIVELOAD_PKG.gFile.NU_REG IS NOT NULL LOOP
        --
        vTrack:= 'ler registro '||WT_MASSIVELOAD_PKG.gFile.NU_REG;
        vTpReg := WTMX_MASSIVELOAD_PKG.GetContent('TpRegistro', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
        --
        BEGIN
          --
          IF vTpReg = 0 THEN
            -- Header
            -- Valida a Descrição da Interface no Header
            --
            IF WTMX_MASSIVELOAD_PKG.ValidateInterfaceName('DsInterface','INT1038.154 - NOTA VALE') > 0 THEN
               --
               vReturnCodeLine    := 182548;
               vReturnMessageLine := WT_UTILITY_PKG.GetMessage(vReturnCodeLine);
               RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
               --
            END IF;
            --
          ELSIF vTpReg = 1 THEN
            -- Gestor
            pCD_GST := WTMX_MASSIVELOAD_PKG.GetContent('Manager', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            pCD_BAS := WTMX_MASSIVELOAD_PKG.GetContent('Base', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            --
            -- Verificação da Abrangencia do Gestor
            WTMX_CORPORATELEVEL_PKG.ManagerHierarchyValidate(pCD_CSL         => NULL,
                                                             pCD_CLI         => NULL,
                                                             pCD_BAS         => pCD_BAS,
                                                             pCD_CTR_CLI     => NULL,
                                                             pCD_GST         => pCD_GST,
                                                             pCD_USU         => NULL,
                                                             pCD_HIE_ETD     => NULL,
                                                             pCD_GST_RET     => vCD_GST,
                                                             pCD_TIP_GST_RET => vCD_TIP_GST,
                                                             pCD_CSL_RET     => pCD_CSL,
                                                             pMSG_USER       => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                             pCOD_RET        => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                             pMSG_RET        => WTMX_MASSIVELOAD_PKG.vReturnMessage);
            --
            IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
              -- Manager incompatible with hierarchy
              vReturnCodeLine    := WTMX_MASSIVELOAD_PKG.vReturnCode;
              vReturnMessageLine := WTMX_MASSIVELOAD_PKG.vReturnMessage;
              RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
              --
            END IF;
            --
            -- Obtem o Contrato
            --
            BEGIN
              SELECT CC.CD_CTR_CLI
                INTO pCD_CTR_CLI
                FROM PTC_CTR_CLI CC, PTC_CLI C, PTC_BAS B, PTC_GST G
               WHERE B.CD_BAS = pCD_BAS
                 AND B.CD_CLI = C.CD_CLI
                 AND C.CD_CSL = G.CD_CSL
                 AND G.CD_GST = pCD_GST
                 AND C.CD_CLI = CC.CD_CLI;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                --
                vReturnCodeLine    := 182257;
                vReturnMessageLine := WT_UTILITY_PKG.GetMessage(vReturnCodeLine);
                RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                --
            END;
            --
            --
          ELSIF vTpReg = 2 THEN

            --
            --
            iSeq := iSeq + 1;
            --
            pTab_Rec(iSeq):= null;
            --
            pTab_Rec(iSeq).IN_FINANCEIRO := 'F';
            --
            pTab_Rec(iSeq).NU_LINHA := WT_MASSIVELOAD_PKG.gFile.NU_REG;
            --
            --vSeq  := vSeq + 1;
            --
            pTab_Rec(iSeq).IN_ERRO           := 0;
            pTab_Rec(iSeq).NU_PED            := NULL;
            pTab_Rec(iSeq).CD_PAT            := NULL;
            pTab_Rec(iSeq).CD_TIP_PAT        := WTMX_MASSIVELOAD_PKG.GetContent    ('TpNV'        , WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            pTab_Rec(iSeq).DT_HR_INI_VIG     := WTMX_MASSIVELOAD_PKG.GetContentDate('IniVig'      , WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            pTab_Rec(iSeq).DT_HR_FIM_VIG     := WTMX_MASSIVELOAD_PKG.GetContentDate('FimVig'      , WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            pTab_Rec(iSeq).NU_MAX_OPE        := WTMX_MASSIVELOAD_PKG.GetContent    ('QtdUsos'     , WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            pTab_Rec(iSeq).VL_TOT_INF        := WTMX_MASSIVELOAD_PKG.GetContent    ('ValorNV'     , WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            pTab_Rec(iSeq).VL_MIN_CAN_AUT    := WTMX_MASSIVELOAD_PKG.GetContent    ('VlrMinCancel', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            pTab_Rec(iSeq).NU_PCT_MIN_CAN_AUT:= WTMX_MASSIVELOAD_PKG.GetContent    ('PctMinCancel', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            pTab_Rec(iSeq).CD_VGE            := WTMX_MASSIVELOAD_PKG.GetContent    ('CdViagem'    , WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            pTab_Rec(iSeq).CD_PTD            := NULL;
            pTab_Rec(iSeq).DC_OBS            := WTMX_MASSIVELOAD_PKG.GetContent    ('DsNV'        , WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            pTab_Rec(iSeq).IN_BMB_PRP        := WTMX_MASSIVELOAD_PKG.GetContent    ('IndAutoConsumo',WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            pTab_Rec(iSeq).NU_PED_EXT        := WTMX_MASSIVELOAD_PKG.GetContent    ('NuPedExt'    , WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            pTab_Rec(iSeq).MerchandiseList   := NULL;
            pTab_Rec(iSeq).DriverList        := NULL;
            pTab_Rec(iSeq).RestrictionList   := NULL;
            --
            pTab_Rec(iSeq).CD_SUB_RED        := WTMX_MASSIVELOAD_PKG.GetContent    ('CdRedRestrita', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            --
            -- inicio 1.03
            IF NVL(pTab_Rec(iSeq).IN_BMB_PRP, 'F') = 'T' THEN
               pTab_Rec(iSeq).TP_CSM        := 'I';
            ELSE
               pTab_Rec(iSeq).TP_CSM        := 'E';
            END IF;
            -- fim 1.03

            -- GetContent('CdRedRestrita', vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            --
            -- Verifica Bomba Propria
            --
            IF NVL(pTab_Rec(iSeq).IN_BMB_PRP, 'F') = 'T' THEN
              SELECT DECODE(COUNT(1), 0, 0, 1)
              INTO vQtde
              FROM PTC_BAS B,
                   PTC_NIV_CTR_ITE_SVC_PTE_NEG NCISPN
              WHERE B.CD_BAS = pCD_BAS
                AND B.CD_PTE_NEG = NCISPN.CD_PTE_NEG
                AND NCISPN.CD_ITE_SVC IN (3, 6);
              --
              IF vQtde = 0 THEN
                --
                vReturnCodeLine    := 183015;
                vReturnMessageLine := '"Autoconsumo Nota Vale" is only allowed when CorporateLevel have "Bomba Própria" Service Item.';
                RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                --
              END IF;
              --
            END IF;
            --
            --
            IF  pTab_Rec(iSeq).CD_SUB_RED  = 0 THEN
               pTab_Rec(iSeq).CD_SUB_RED := NULL;
            END IF;
            --
            -- Verifica se Rede Restrita é do Consolidador
            IF NVL(pTab_Rec(iSeq).CD_SUB_RED,0) > 0 THEN
              BEGIN
                SELECT CD_SUB_RED
                  INTO pTab_Rec(iSeq).CD_SUB_RED
                  FROM PTC_SUB_RED
                 WHERE CD_SUB_RED = pTab_Rec(iSeq).CD_SUB_RED
                   AND CD_CSL     = pCD_CSL;

                EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                      --
                      vReturnCodeLine    := 180596;
                      vReturnMessageLine := 'AcceptanceRestrictionIdentification invalid.';
                      RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                      --
              END;
            END IF;
            --
            --
            IF pTab_Rec(iSeq).VL_MIN_CAN_AUT >= pTab_Rec(iSeq).VL_TOT_INF THEN
              --
              vReturnCodeLine    := 182545;
              vReturnMessageLine := 'MinimumValueToCancel must be less then value';
              RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
              --
            END IF;
            --
            --
            -- NV gerada
            IF NOT pIN_VALIDACAO_INICIAL THEN
              --
              IF WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'V' THEN
                pTab_Rec(iSeq).CD_PAT := -99999;
              ELSE
                SELECT PREAUTHORIZATIONID
                INTO pTab_Rec(iSeq).CD_PAT
                FROM TKT_CMS_1038_155_PREAUT_HEADER
                WHERE FILEID   = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
                  AND DOMAINID = WT_MASSIVELOAD_PKG.gFile.CD_DOM
                  AND ROWNUMBER= WT_MASSIVELOAD_PKG.gFile.NU_REG;
              END IF;
            END IF;
          ELSIF vTpReg = 3 THEN
            --
            IF pTab_Rec(iSeq).CD_PTD IS NOT NULL THEN
              --
              vReturnCodeLine    := 9999; --Mais de um portador para a NV
              vReturnMessageLine := WT_UTILITY_PKG.GetMessage(vReturnCodeLine);
              RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
              --
            END IF;
            --

              vCard      := WTMX_MASSIVELOAD_PKG.GetContent('NuCartao', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
              vTagNfcNum := WTMX_MASSIVELOAD_PKG.GetContent('TAGNFCNum', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
              vTagNfcId  := WTMX_MASSIVELOAD_PKG.GetContent('TAGNFC', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));

              -- Se CARD_NUMBER não for informado, obter o cartão ativo a partir dos novos campos
              -- (TAG_NUMERICA ou TAG_HEXADECIMAL)
              BEGIN
                --
                IF vCard IS NOT NULL THEN
                  --
                  SELECT CC.CARDID
                  INTO vCard
                  FROM PTC_CAT C, PTC_DAD_VEI_EQP D, PTC_VEI_EQP V, PTC_CAT C2, T_GCURRENTCARD CC -- 1.01
                  WHERE C.NU_CAT = vCard
                    AND C2.CD_PTD = C.CD_PTD
                    AND C2.CD_BAS = C.CD_BAS
                    AND CC.CARDID = C2.NU_CAT
                    AND V.CD_PTD  = C2.CD_PTD
                    AND D.CD_VEI_EQP = V.CD_VEI_EQP
                    AND (vTagNfcNum  IS NULL OR vTagNfcNum  = D.NU_TAG_NFC)
                    AND (vTagNfcId IS NULL OR vTagNfcId = D.ID_TAG_NFC);
                  --
                ELSIF vTagNfcNum IS NOT NULL THEN
                  --
                  SELECT C.NU_CAT
                  INTO vCard
                  FROM PTC_DAD_VEI_EQP D, PTC_VEI_EQP V, PTC_CAT C, T_GCURRENTCARD CC
                  WHERE vTagNfcNum   = D.NU_TAG_NFC
                    AND (vTagNfcId IS NULL OR vTagNfcId = D.ID_TAG_NFC)
                    AND V.CD_VEI_EQP = D.CD_VEI_EQP
                    AND C.CD_PTD     = V.CD_PTD
                    AND CC.CARDID    = C.NU_CAT;
                  --
                ELSIF vTagNfcId IS NOT NULL THEN
                  --
                  SELECT C.NU_CAT
                  INTO vCard
                  FROM PTC_DAD_VEI_EQP D, PTC_VEI_EQP V, PTC_CAT C, T_GCURRENTCARD CC
                  WHERE D.ID_TAG_NFC = vTagNfcId
                    AND V.CD_VEI_EQP = D.CD_VEI_EQP
                    AND C.CD_PTD     = V.CD_PTD
                    AND CC.CARDID = C.NU_CAT;
                  --
                ELSE
                  --
                  vReturnCodeLine    := 183143;  -- Could not find Card Number
                  vReturnMessageLine := WT_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode);
                  RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                  --
                END IF;
                --
              EXCEPTION
                WHEN OTHERS THEN
                  --
                  vReturnCodeLine    := 183143;  -- Could not find Card Number
                  vReturnMessageLine := WT_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode);
                  RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                  --
              END;
              --
              --
              -- Se o cartão obtido estiver com bloqueio emissor (T_GCARD.RISKCONDITIONREASONCODEID = 99),
              -- apontar erro específico (3139)
              SELECT C.RISKCONDITIONREASONCODEID
              INTO vRiskConditionReasonCodeId
              FROM T_GCARD C
              WHERE CARDID = vCard;
              --
              IF vRiskConditionReasonCodeId = 99 THEN
                  --
                  vReturnCodeLine    := 183139;
                  vReturnMessageLine := WT_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode);
                  RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                  --
              END IF;
            --
            --
            BEGIN
              SELECT CAT.CD_PTD
                INTO pTab_Rec(iSeq).CD_PTD
                FROM PTC_CAT  CAT
               WHERE CAT.NU_CAT = vCard;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                --
                pTab_Rec(iSeq).CD_PTD := NULL;
                --
            END;
            --
                 SELECT COUNT(CD_PTD)
                   INTO vQtde
                   FROM PTC_PTD
                  WHERE CD_PTD = pTab_Rec(iSeq).CD_PTD
                    AND CD_BAS = pCD_BAS;
                 --
                 IF  vQtde  = 0 THEN
                    --
                    vReturnCodeLine    := 182549; --Invalid Cardholder
                    vReturnMessageLine := WT_UTILITY_PKG.GetMessage(vReturnCodeLine);
                    RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                    --
                 END IF;
                 --
                 --
                 -- Verifica se o portador informado pertence a abrangencia de gest?o
                 IF vCD_TIP_GST <>  5        THEN
                    -- Qtde de portadores
                   SELECT COUNT(*)
                      INTO vQtde
                      FROM PTC_PTD           PTD,
                           PTC_VEI_EQP       VEI,
                           PTC_PSS           PSS,
                           PTCMX_CNT_CUS     CCU
                     WHERE PTD.CD_PTD      = VEI.CD_PTD (+)
                       AND PTD.CD_PTD      = PSS.CD_PTD (+)
                       AND CCU.CD_CNT_CUS  = NVL(VEI.CD_CEN_CUS, PSS.CD_CEN_CUS)
                       AND PTD.CD_PTD      = pTab_Rec(iSeq).CD_PTD
                       AND CCU.CD_HIE_ETD IN (SELECT  HIE.CD_HIE_ETD
                                                FROM PTCMX_HIE_ETD   HIE
                                          START WITH HIE.CD_HIE_ETD   IN (SELECT GSTH.CD_HIE_ETD
                                                                            FROM PTCMX_GST_HIE_ETD GSTH
                                                                           WHERE GSTH.CD_GST     = pCD_GST
                                                                             AND GSTH.CD_CSL     = pCD_CSL)
                                     CONNECT BY PRIOR HIE.CD_HIE_ETD = HIE.CD_HIE_ETD_PAI);
                    --
                    -- Verifica diferenca nos totais
                    --
                    IF  vQtde = 0 THEN
                      --
                      vReturnCodeLine    := 152339; --Manager incompatible with Hierarchy
                      vReturnMessageLine := WT_UTILITY_PKG.GetMessage(vReturnCodeLine);
                      RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                      --
                    END IF;
                    --
                 END IF;
            --
            pTab_Rec(iSeq).CD_TRJ:= WTMX_MASSIVELOAD_PKG.GetContent('CdTrajeto', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            --
            --
          ELSIF vTpReg = 4 THEN  -- Mercadorias
           --
           vCdMercadoria   := WTMX_MASSIVELOAD_PKG.GetContent('CdMercadoria',   WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
           vQtMercadoria   := WTMX_MASSIVELOAD_PKG.GetContent('QtMercadoria',   WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
           vVlUnMercadoria := WTMX_MASSIVELOAD_PKG.GetContent('VlUnMercadoria', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
           --
           vQtdKM          := WTMX_MASSIVELOAD_PKG.GetContent('QtdKM'      ,    WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
           vRendimento     := WTMX_MASSIVELOAD_PKG.GetContent('Rendimento',     WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));

            -- Valida infors x tipo NV -- 4.11
            IF (pTab_Rec(iSeq).CD_TIP_PAT  = 1 AND  (vQtdKM IS NOT NULL OR vRendimento IS NOT NULL)) OR
               (pTab_Rec(iSeq).CD_TIP_PAT  = 2 AND  (vCdMercadoria IS NULL OR vQtMercadoria IS NULL OR vVlUnMercadoria IS NULL OR vQtdKM IS NOT NULL OR vRendimento IS NOT NULL)) OR
               (pTab_Rec(iSeq).CD_TIP_PAT  = 3 AND  (vCdMercadoria IS NULL OR vVlUnMercadoria IS NULL OR vQtdKM IS NULL OR vRendimento IS NULL)) THEN
              --
              vReturnCodeLine := 183046; -- Invalid informations for PreAuthorization Type.
              vReturnMessageLine := WT_UTILITY_PKG.GetMessage(vReturnCodeLine);
              RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
              --
            END IF;

            --
            SELECT COUNT(CD_TIP_MRD)
             INTO vQtde
             FROM PTC_MRD_TIP_MRD
            WHERE CD_TIP_MRD = 1  -- Combustivel
              AND CD_MRD     = vCdMercadoria;
            --
            IF  vQtde = 0 THEN
             --
             vReturnCodeLine := 182457; -- Mercadoria Invalida
             vReturnMessageLine := WT_UTILITY_PKG.GetMessage(vReturnCodeLine);
             RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
             --
            END IF;
            --
            IF NVL(vQtMercadoria,   0) = 0 OR
              NVL(vVlUnMercadoria, 0) = 0 THEN
              --
              vReturnCodeLine    := 182457; -- Required invalid information
              vReturnMessageLine := WT_UTILITY_PKG.GetMessage(vReturnCodeLine);
              RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
            END IF;
            --
            IF pTab_Rec(iSeq).MerchandiseList IS NOT NULL THEN
               pTab_Rec(iSeq).MerchandiseList := pTab_Rec(iSeq).MerchandiseList || '|';
            END IF;
            --
            pTab_Rec(iSeq).MerchandiseList := pTab_Rec(iSeq).MerchandiseList      ||
                                 vCdMercadoria  || ';' ||
                                 vQtMercadoria  || ';' ||
                                 vVlUnMercadoria|| ';' ||
                                 vQtdKM         || ';' || -- 4.11
                                 vRendimento;
           --
          ELSIF vTpReg = 5 THEN -- Estabelacimento
            --
            pTab_Rec(iSeq).CD_CTR_ETB := WTMX_MASSIVELOAD_PKG.GetContent('CtrEstRestrito', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            --
            IF pTab_Rec(iSeq).ContractList IS NOT NULL THEN
               pTab_Rec(iSeq).ContractList := pTab_Rec(iSeq).ContractList || '|';
            END IF;
            --
            pTab_Rec(iSeq).ContractList := pTab_Rec(iSeq).ContractList      ||
                                              pTab_Rec(iSeq).CD_CTR_ETB   ;

          ELSIF vTpReg = 6 THEN     -- Condutores
            --
            vCD_ETD_PSS:= WTMX_MASSIVELOAD_PKG.GetContent('CdCondutor', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            --
                 SELECT COUNT(FSC.CD_PSS_FSC)
                   INTO vQtde
                   FROM PTC_PSS_FSC      FSC,
                        PTC_PSS          PSS
                  WHERE FSC.CD_ETD     = vCD_ETD_PSS
                    AND FSC.CD_PSS_FSC = PSS.CD_PSS_FSC
                    AND PSS.CD_BAS     = PCD_BAS
                    AND PSS.CD_STA_CMM = 1;  -- 1.02
                 --
                 IF vQtde  = 0 THEN
                   --
                   vReturnCodeLine := 182461; -- Condutor Invalido
                   vReturnMessageLine := WT_UTILITY_PKG.GetMessage(vReturnCodeLine);
                   RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                   --
                 END IF;
                 --

                IF  pTab_Rec(iSeq).DriverList IS NOT NULL THEN
                    pTab_Rec(iSeq).DriverList := pTab_Rec(iSeq).DriverList || '|';
                END IF;
                --
                pTab_Rec(iSeq).DriverList := pTab_Rec(iSeq).DriverList || vCD_ETD_PSS;
                --

          ELSIF vTpReg = 7 THEN -- Restricao
            --
                 BEGIN
                   --
                   vHrInicio  := TO_DATE('01/01/2000 ' ||
                                 WTMX_MASSIVELOAD_PKG.GetContent('HrInicio', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),
                                 'DD/MM/YYYY HH24MI');
                   --
                   vHrFim    := TO_DATE('01/01/2000 ' ||
                                 WTMX_MASSIVELOAD_PKG.GetContent('HrFim', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),
                                 'DD/MM/YYYY HH24MI');
                   --
                 EXCEPTION
                   WHEN OTHERS THEN
                     --
                     vReturnCodeLine :=  182555; -- Invalid start or end time
                     vReturnMessageLine := WT_UTILITY_PKG.GetMessage(vReturnCodeLine);
                     RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                     --
                 END;
                 --
                 vPeriodicidade := WTMX_MASSIVELOAD_PKG.GetContent('Periodicidade', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
                 --
                 SELECT COUNT(CD_PDC)
                   INTO vQtde
                   FROM PTC_PDC
                  WHERE CD_PDC = vPeriodicidade
                    AND vPeriodicidade IN (8, 10, 11, 12);  -- Dias Uteis / Sabado / Domingo / Feriados
                 --
                 IF  vQtde = 0 THEN
                     --
                     vReturnCodeLine :=  180962; -- Periodicidade Invalida
                     vReturnMessageLine := WT_UTILITY_PKG.GetMessage(vReturnCodeLine);
                     RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                     --
                 END IF;
                 --
                    --
                    IF  pTab_Rec(iSeq).RestrictionList IS NOT NULL THEN
                        pTab_Rec(iSeq).RestrictionList := pTab_Rec(iSeq).RestrictionList || '|';
                    END IF;
                    --
                    pTab_Rec(iSeq).RestrictionList := pTab_Rec(iSeq).RestrictionList ||
                                              TO_CHAR(vHrInicio, 'HH24:MI') || ';' ||
                                              TO_CHAR(vHrFim,    'HH24:MI') || ';' ||
                                              vPeriodicidade;
                    --
           --
          ELSIF vTpReg = 99 THEN  -- Trailler
            --
            NULL;
            --
          END IF;
          --
        EXCEPTION
          --
          WHEN WTMX_MASSIVELOAD_PKG.EProcessError THEN
            --
            IF WT_MASSIVELOAD_PKG.gFile.NU_REG IS NULL OR
               vTpReg IN (0, 1, 99) THEN
              --
              UpdateLine(pNU_REG      => pTab_Rec(iSeq).NU_LINHA, -- WT_MASSIVELOAD_PKG.gFile.NU_REG,
                          pCD_MSG_ERR => vReturnCodeLine,
                          pDS_MSG_ERR => vReturnMessageLine,
                          PTRACK      => 'PreAuthorizationLoad. Erro ao '||vTrack,
                          PRAISE_EXC  => TRUE);
              --
              RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
              --
            ELSE
              --
              pTab_Rec(iSeq).IN_ERRO := 1;
              --
              IF pTab_Rec(iSeq).CD_PTD IS NOT NULL THEN
                vQtde_PTD:= vQtde_PTD - 1;
              END IF;
              --
              UpdateLine(PNU_REG     => pTab_Rec(iSeq).NU_LINHA, -- WT_MASSIVELOAD_PKG.gFile.NU_REG,
                         PCD_MSG_ERR => vReturnCodeLine,
                         PDS_MSG_ERR => vReturnMessageLine,
                         PTRACK      => 'PreAuthorizationLoad. Erro ao '||vTrack,
                         PRAISE_EXC  => TRUE);
              --
            END IF;
          WHEN OTHERS THEN
            --
            IF WT_MASSIVELOAD_PKG.gFile.NU_REG IS NULL OR
               vTpReg IN (0, 1, 99) THEN
              --
              UpdateLine(pNU_REG      => pTab_Rec(iSeq).NU_LINHA, -- WT_MASSIVELOAD_PKG.gFile.NU_REG,
                          pCD_MSG_ERR => SQLCODE,
                          pDS_MSG_ERR => SQLERRM,
                          PTRACK      => 'PreAuthorizationLoad. Erro ao '||vTrack,
                          PRAISE_EXC  => TRUE);
              --
              RAISE;
              --
            ELSE
              --
              pTab_Rec(iSeq).IN_ERRO := 1;
              --
              UpdateLine(pNU_REG      => pTab_Rec(iSeq).NU_LINHA, -- WT_MASSIVELOAD_PKG.gFile.NU_REG,
                          pCD_MSG_ERR => SQLCODE,
                          pDS_MSG_ERR => SQLERRM,
                          PTRACK      => 'PreAuthorizationLoad. Erro ao '||vTrack,
                          PRAISE_EXC  => TRUE);
              --
            END IF;
            --
        END;
        --
        IF vPartial THEN
          --
          IF pLinhasParcial.EXISTS(pLinhasParcial.NEXT(vIdxParcial)) THEN
             WT_MASSIVELOAD_PKG.gFile.NU_REG := pLinhasParcial(pLinhasParcial.NEXT(vIdxParcial));
             vIdxParcial                     := pLinhasParcial.NEXT(vIdxParcial);
          ELSE
            WT_MASSIVELOAD_PKG.gFile.NU_REG := NULL;
          END IF;
          --
        ELSE
          --
          WT_MASSIVELOAD_PKG.gFile.NU_REG := WTMX_MASSIVELOAD_PKG.vLines.NEXT(WT_MASSIVELOAD_PKG.gFile.NU_REG);
          --
        END IF;
        --
      END LOOP; -- Loop WTMX_MASSIVELOAD_PKG.vLines
      --
    END IF;
    --
    IF vPartial AND vLinhaParcial IS NOT NULL THEN
        WT_MASSIVELOAD_PKG.gFile.NU_REG:= vLinhaParcial;
    END IF;
    --
    vTrack:= 'finalizar leitura do arquivo';
    --
    pQtde_PTD := vQtde_PTD;
    pQtde_CAT := vQtde_CAT;
    --

    --
    --
  EXCEPTION
    --
    WHEN WTMX_MASSIVELOAD_PKG.EProcessError THEN
      --
      --ROLLBACK;
      IF vPartial AND vLinhaParcial IS NOT NULL THEN
          WT_MASSIVELOAD_PKG.gFile.NU_REG:= vLinhaParcial;
      END IF;
      --
      pCOD_RET := NVL(pCOD_RET, 9999);
      pMSG_USER:= WTMX_UTILITY_PKG.GetMessage(pCOD_RET);
      pMSG_RET := pMSG_USER;
      --
      WTMX_MASSIVELOAD_PKG.vExceptionType := 'EProcessError';
      --
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
    WHEN OTHERS THEN
      -- Auditoria -------------------------------------------------
      WT2_AUDIT_UTL.AuditError($$PLSQL_UNIT||'.PreAuthorizationLoad - ' || SQLERRM);
      ------------------------------------------------------------
      --
      --ROLLBACK;
    --
      IF vPartial AND vLinhaParcial IS NOT NULL THEN
          WT_MASSIVELOAD_PKG.gFile.NU_REG:= vLinhaParcial;
      END IF;
      --
      pCOD_RET := SQLCODE;
      pMSG_USER:= WTMX_UTILITY_PKG.GetMessage(pCOD_RET);
      pMSG_RET := pMSG_USER;
      --
      UpdateLine(pNU_REG     => NULL,
                 pCD_MSG_ERR => SQLCODE,
                 pDS_MSG_ERR => SQLERRM,
                 PTRACK      => 'PreAuthorizationLoad. Erro ao '||vTrack,
                 PRAISE_EXC  => FALSE);
      --
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
  END;
  --
  -------------------------------------------------------------------
  -- Procedure Especialista
  -------------------------------------------------------------------
  PROCEDURE PreAuthorizationExecute IS
    --
    vPar        TY_AUDIT_PARAM_TBL;
    --
    -- Variaveis de Apoio
    vCD_GST     PTC_GST.CD_GST%TYPE;
    vCD_CSL     PTC_GST.CD_CSL%TYPE;
    vCD_BAS     PTC_BAS.CD_BAS%TYPE;
    vQtde_PTD   NUMBER := 0;
    vQtde_CAT   NUMBER := 0;
    --
    vModule VARCHAR2(100);
    vAction VARCHAR2(100);
    --
    vTab_Rec T_Tab_Rec; -- Registros
    --
    -- Variaveis do Arquivo de Veiculos
    vCD_CTR_CLI PTC_CTR_CLI.CD_CTR_CLI%TYPE;
    --
    vTrack VARCHAR2(500);
    vStatus PTC_CMS_ARQ_DOM.CD_STA_CMM%TYPE;
    --
    vQtd_int INTEGER;
  BEGIN
    --
    -- Auditoria -----------------------------------------------------------------
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'PreAuthorizationExecute');
    vPar    := TY_AUDIT_PARAM_TBL();
    vPar.EXTEND(2);
    vPar(1) := TY_AUDIT_PARAM_OBJ('CD_ARQ'         , WT_MASSIVELOAD_PKG.gFile.CD_ARQ);
    vPar(2) := TY_AUDIT_PARAM_OBJ('CD_DOM'         , WT_MASSIVELOAD_PKG.gFile.CD_DOM);
    --
    WT2_AUDIT_UTL.AuditCreate(pCD_USU => SYS_CONTEXT('USERENV', 'OS_USER'),
                              pDS_ORI => $$PLSQL_UNIT||'.PreAuthorizationExecute',
                              pEN_IP  => SYS_CONTEXT('USERENV', 'HOST'),
                              pID_MSG => NULL,
                              pID_REQ => NULL,
                              pPRM    => vPar,
                              pCLOB   => NULL);
    ---------------------------------------------------------------------------
    --
    -- Atualiza o status do Dominio do Arquivo para "Processando Validação"
    vTrack:= 'atualizar status do arquivo (Processando Validação)';
    WTMX_MASSIVELOAD_PKG.MassiveLoadFileDomainUpdStatus(pCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                        pCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                        pDT_INI_PRC => SYSDATE,
                                                        pDT_FIM_PRC => NULL,
                                                        pCD_STA_CMM => 83, -- Processando Validação
                                                        pMSG_USER   => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                        pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                        pMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage);
    --
    IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
       ProcessError(WTMX_MASSIVELOAD_PKG.vReturnCode, 'PreAuthorizationExecute. Erro ao '||vTrack, TRUE);
    END IF;
    --
    -- Leitura das linhas do dominio
    WTMX_MASSIVELOAD_PKG.GetDomainLinesValidate(PCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                PCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                PData     => WTMX_MASSIVELOAD_PKG.vLines,
                                                pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
    --
    IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
      --
      ProcessError(WTMX_MASSIVELOAD_PKG.vReturnCode, 'PreAuthorizationExecute. Erro ao '||vTrack, TRUE);
      --
    END IF;
    --
    -- Recupera quantidade total de linhas e quantidade de linhas com erro
    vTrack:= 'atualizar status do pedido (1)';
    vStatus:= WTMX_MASSIVELOAD_PKG.GetFileEndProcStatus(WT_MASSIVELOAD_PKG.gFile.CD_ARQ);
    --
    IF vStatus = 80 THEN
      --
      RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
      --
    END IF;
    --
    -- Carga e validação das linhas do arquivo
    --
    PreAuthorizationLoad(pCD_BAS         => vCD_BAS,
                         pCD_GST         => vCD_GST,
                         pCD_CSL         => vCD_CSL,
                         pCD_CTR_CLI     => vCD_CTR_CLI,
                         pTab_Rec        => vTab_Rec,
                         pQtde_PTD       => vQtde_PTD,
                         pQtde_CAT       => vQtde_CAT,
                         pMSG_USER       => WTMX_MASSIVELOAD_PKG.vUserMessage,
                         pCOD_RET        => WTMX_MASSIVELOAD_PKG.vReturnCode,
                         pMSG_RET        => WTMX_MASSIVELOAD_PKG.vReturnMessage);
    --
    IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
      --
      ProcessError(WTMX_MASSIVELOAD_PKG.vReturnCode, 'PreAuthorizationExecute. Erro ao '||vTrack, TRUE);
      --
    END IF;
    --

    -- Recupera quantidade total de linhas e quantidade de linhas com erro
    vTrack:= 'atualizar status do pedido (2)';
    vStatus:= WTMX_MASSIVELOAD_PKG.GetFileEndProcStatus(WT_MASSIVELOAD_PKG.gFile.CD_ARQ);
    --
    IF vStatus=80 THEN
      --
      RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
      --
    END IF;
    --
   /* -- busca dados adicionais
    vTrack:= 'criar ordem (OrderCreate)';
    SELECT MAX(G.CD_USU)
      INTO vCD_USU_GST
      FROM PTC_GST G,
           PTC_BAS B,
           PTC_CLI C
     WHERE B.CD_BAS = vCD_BAS
       AND B.CD_CLI = C.CD_CLI
       AND C.CD_CSL = G.CD_CSL
       AND G.CD_GST = vCD_GST;

     vOrderItems := vOrderItems                               || '3;' || -- CD_TIP_PED
                    0                                         ||  ';' || -- QT_ITE_PED
                    TO_CHAR(vDT_PED, 'DD/MM/YYYY HH24:MI:SS') ||  ';' || -- DT_AGD
                    TO_CHAR(vDT_PED, 'DD/MM/YYYY HH24:MI:SS') ||  ';' || -- DT_EXE
                    1                                         ||  ';' || -- CD_STA_TIP_ITM_PED
                    WT_MASSIVELOAD_PKG.gFile.CD_CLI           ||  ';' || -- CD_CLI
                    TO_CHAR(vMenorUE);                                   -- CD_UND_ETG

    --
    -- Cria o pedido na WEM
    WTMX_ORDER_PKG.OrderCreate(PNU_PED => vNU_PED,
                               PDT_PED => vDT_PED,
                               PDT_APV => vDT_PED,
                               PDT_EXE => vDT_PED,
                               PDC_OBS => vDC_OBS,
                               PCD_USU_SOL => vCD_USU_GST,
                               PCD_USU_APV => vCD_USU_GST,
                               PCD_BAS => vCD_BAS,
                               PCD_STA_PED => 2, --ESPERANDO PROCESAMIENTO --8,
                               PCD_TIP_PED => 101,
                               PITEMLIST => vOrderItems,
                               pUSER => NULL,
                               pIP => 'MASSIVELOAD',
                               PEXTERNALORDERNUMBER => vNU_PED_EXT,
                               pCD_GST   => vCD_GST,
                               PMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                               PCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                               PMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
    --
    IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode,0) <> 0 THEN
      --
      -- Error in call to OrderCreate
      UpdateLine(PNU_REG     => NULL,
                 PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                 PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                 PTRACK      => 'PreAuthorizationExecute. Erro ao '||vTrack,
                 PRAISE_EXC  => TRUE);
      --
      RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
      --
    END IF;
    --
    -- associa o pedido criado ao processo de carga massiva
    vTrack:= 'associar pedido a carga massiva';
    WTMX_MASSIVELOAD_PKG.MassiveLoadOrderCreate(PCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                PCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                PNU_PED   => vNU_PED,
                                                PMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                PCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                PMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
    --
    IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode,0) <> 0 THEN
      --
      -- Error in call to OrderCreate
      UpdateLine(PNU_REG     => NULL,
                 PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                 PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                 PTRACK      => 'PreAuthorizationExecute. Erro ao '||vTrack,
                 PRAISE_EXC  => TRUE);
      --
      RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
      --
    END IF;*/

    --
    --
    --IF (WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'A' AND vQtde_PTD > 0) OR
    --   (WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'V' AND (vQtde_PTD + vQtde_CAT) > 0) THEN
      --
      vTrack:= 'gerar interface';
      --
      GenerateInterface(pCD_ARQ         => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                     pCD_DOM         => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                     pCD_BAS         => vCD_BAS,
                                     pCD_CTR_CLI     => vCD_CTR_CLI,
                                     pTab_Rec        => vTab_Rec,
                                     pQtd_int        => vQtd_int,
                                     pMSG_USER       => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                     pCOD_RET        => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                     pMSG_RET        => WTMX_MASSIVELOAD_PKG.vReturnMessage);

      --
      IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
        --
        UpdateLine(PNU_REG     => NULL,
                   PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                   PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                   PTRACK      => 'PreAuthorizationExecute. Erro ao '||vTrack,
                   PRAISE_EXC  => TRUE);
        --
        RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
      --
      END IF;
      --
    --END IF;

    IF NVL(vQtd_int,0) > 0 THEN
      /*-- Atualiza quantidade de itens final
      vTrack:= 'atualizar quantidade de itens final';
      UPDATE PTC_ITE_PED I
      SET I.QT_ITE_PED = vQtd_int
      WHERE NU_PED = vNU_PED
       AND ROWNUM = 1;      */
      --
      WTMX_MASSIVELOAD_PKG.vFinancialInd := 'T'; -- Como foi OK, executa o Sunnel
      --
      -- Atualiza o status do Dominio do Arquivo para "Em processamento Financeiro"
      --
      WTMX_MASSIVELOAD_PKG.MassiveLoadFileDomainUpdStatus(pCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                          pCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                          pDT_INI_PRC => NULL,
                                                          pDT_FIM_PRC => NULL,
                                                          pCD_STA_CMM => 78, -- 78 = Processando Financeiro
                                                          pMSG_USER   => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                          pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                          pMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
    ELSE
      --
      WTMX_MASSIVELOAD_PKG.vFinancialInd := 'F';
      --
      -- Chama a finalizadora
      --
      WTMX_MASSIVELOAD_PKG.MassiveLoadFinish(PCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                             PCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                             pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                             pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                             pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
    END IF;
    --
    --
    IF WT_MASSIVELOAD_PKG.gFile.TP_ACA <> 'A' THEN
      -- Como a ação não e de APPLY, desfaz qualquer alteração na WEN e preserva
      -- a interface gerada e os status de processamento da CM
      ROLLBACK;
      --
    END IF;
    --
    WTMX_MASSIVELOAD_PKG.vUserMessage   := SQLERRM;
    WTMX_MASSIVELOAD_PKG.vReturnMessage := WTMX_MASSIVELOAD_PKG.vUserMessage;
    WTMX_MASSIVELOAD_PKG.vReturnCode    := SQLCODE;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN WTMX_MASSIVELOAD_PKG.EProcessReturn THEN
      --
      ROLLBACK; -- Desfaz eventuais alterações ja efetuadas
      --
      WTMX_MASSIVELOAD_PKG.MassiveLoadFileDomainUpdStatus(pCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                          pCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                          pDT_INI_PRC => NULL,
                                                          pDT_FIM_PRC => NULL,
                                                          pCD_STA_CMM => 80, -- 80 = PROCESSADO COM ERROS
                                                          pMSG_USER   => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                          pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                          pMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      -- Executa a proc para a geração do arquivo de retorno    --
      WTMX_MASSIVELOAD_PKG.MassiveLoadGenerateRespFile(pCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                       pCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                       pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                       pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                       pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      RETURN;
      --
    WHEN WTMX_MASSIVELOAD_PKG.EProcessError THEN
      --
      ROLLBACK; -- Desfaz eventuais alterações ja efetuadas
      --
      WTMX_MASSIVELOAD_PKG.vFinancialInd := 'F'; -- Para não executar o Sunnel
      vExceptionType                     := 'WTMX_MASSIVELOAD_PKG.EProcessError';
      --
      WTMX_MASSIVELOAD_PKG.MassiveLoadFileDomainUpdStatus(pCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                          pCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                          pDT_INI_PRC => NULL,
                                                          pDT_FIM_PRC => NULL,
                                                          pCD_STA_CMM => 80, -- 80 = PROCESSADO COM ERROS
                                                          pMSG_USER   => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                          pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                          pMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      -- Executa a proc para a geração do arquivo de retorno    --
      WTMX_MASSIVELOAD_PKG.MassiveLoadGenerateRespFile(pCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                       pCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                       pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                       pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                       pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      RAISE;
      --
    WHEN OTHERS THEN
      -- Auditoria -------------------------------------------------
      WT2_AUDIT_UTL.AuditError($$PLSQL_UNIT||'.PreAuthorizationExecute - ' || SQLERRM);
      ------------------------------------------------------------
      --
      ROLLBACK; -- Desfaz eventuais alterações ja efetuadas
      --
      WTMX_MASSIVELOAD_PKG.vFinancialInd := 'F';
      --
      WTMX_MASSIVELOAD_PKG.MassiveLoadFileDomainUpdStatus(pCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                          pCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                          pDT_INI_PRC => NULL,
                                                          pDT_FIM_PRC => NULL,
                                                          pCD_STA_CMM => 80, -- 80 = PROCESSADO COM ERROS
                                                          pMSG_USER   => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                          pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                          pMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      -- Executa a proc para a geração do arquivo de retorno    --
      WTMX_MASSIVELOAD_PKG.MassiveLoadGenerateRespFile(pCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                       pCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                       pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                       pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                       pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      ProcessError(SQLCODE, 'PreAuthorizationExecute. Erro ao '||vTrack, TRUE);
      --
      RAISE;
      --
  END;
  --
  ----------------------------------------------------------------------
  -- Procedure de Parcial Especialista --
  ----------------------------------------------------------------------
  PROCEDURE PreAuthorizationParcial IS
    --
    vPar        TY_AUDIT_PARAM_TBL;
    --
    vStatus           PTC_STA_CMM.CD_STA_CMM%TYPE;
    vReturnTip        VARCHAR2(10);
    vResponseCode     NUMBER;
    vInterface        TKT_CMS_1038_155_PREAUT_HEADER%ROWTYPE;
    --
    vTab_Rec    T_Tab_Rec; -- Registros
    --
    vCD_GST     PTC_GST.CD_GST%TYPE;
    vCD_CSL     PTC_GST.CD_CSL%TYPE;
    vCD_BAS     PTC_BAS.CD_BAS%TYPE;
    vCD_CTR_CLI PTC_CTR_CLI.CD_CTR_CLI%TYPE;
    vQtde_PTD   NUMBER := 0;
    vQtde_CAT   NUMBER := 0;
    --
    vTrack VARCHAR2(500);
    --
    vTypes         WT_MASSIVELOAD_PKG.TTypes;
    --
    vLinhasParcial TLinhasParcial:= TLinhasParcial();
    l              INTEGER;
  BEGIN
    --
    l:= 0;
    --
    IF WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'V' THEN
      SAVEPOINT spPARTIAL;
    END IF;

    --
    -- Auditoria------------------------------------------------------------------
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'PreAuthorizationParcial');
    vPar    := TY_AUDIT_PARAM_TBL();
    vPar.EXTEND(3);
    vPar(1) := TY_AUDIT_PARAM_OBJ('CD_ARQ'         , WT_MASSIVELOAD_PKG.gFile.CD_ARQ);
    vPar(2) := TY_AUDIT_PARAM_OBJ('CD_DOM'         , WT_MASSIVELOAD_PKG.gFile.CD_DOM);
    vPar(3) := TY_AUDIT_PARAM_OBJ('NU_REG'         , WT_MASSIVELOAD_PKG.gFile.NU_REG);
    --
    WT2_AUDIT_UTL.AuditCreate(pCD_USU => SYS_CONTEXT('USERENV', 'OS_USER'),
                              pDS_ORI => $$PLSQL_UNIT||'.PreAuthorizationParcial',
                              pEN_IP  => SYS_CONTEXT('USERENV', 'HOST'),
                              pID_MSG => NULL,
                              pID_REQ => NULL,
                              pPRM    => vPar,
                              pCLOB   => NULL);
    ---------------------------------------------------------------------------
    --
    --
    WTMX_MASSIVELOAD_PKG.vFinancialInd  := 'T';
    --
    vReturnCodeLine    := 0;
    vReturnMessageLine := NULL;
    --
    vTrack:= 'buscar status do arquivo';
    SELECT AD.CD_STA_CMM
      INTO vStatus
      FROM PTC_CMS_ARQ_DOM  AD
     WHERE AD.CD_ARQ = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
       AND AD.CD_DOM = WT_MASSIVELOAD_PKG.gFile.CD_DOM;
    --
    BEGIN
      vTrack:= 'buscar resposta sunnel';
      --
      SELECT *
        INTO vInterface
        FROM MX_INTERFACE.TKT_CMS_1038_155_PREAUT_HEADER X
       WHERE FILEID = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
         AND DOMAINID = WT_MASSIVELOAD_PKG.gFile.CD_DOM
         AND ROWNUMBER= WT_MASSIVELOAD_PKG.gFile.NU_REG;
    --
    EXCEPTION
      --
      WHEN NO_DATA_FOUND THEN
        --
        UpdateLine(PNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                   PCD_MSG_ERR => 9999,
                   PDS_MSG_ERR => 'Linha de interface não encontrada',
                   PTRACK      => 'PreAuthorizationParcial. Erro ao '||vTrack,
                   PRAISE_EXC  => TRUE);
        --
        RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
        --
    END;
    --
    --
    IF 1=1 THEN--vStatus = 78 THEN -- 78 = PROCESSANDO FINANCEIRO
      --
      vTrack:= 'buscar resposta sunnel';
      --
      BEGIN
        vResponseCode:= TO_NUMBER(vInterface.ResponseCode);
      EXCEPTION
        WHEN OTHERS THEN
          UpdateLine(PNU_REG      => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                      PCD_MSG_ERR => 9999,
                      PDS_MSG_ERR => 'Numero invalido de resposta Sunnel',
                      PTRACK      => 'PreAuthorizationParcial. Erro ao '||vTrack,
                      PRAISE_EXC  => TRUE);
          --
          RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
          --
      END;
      --
      -- Verifica se as colunas EFFECT estao preenchidas
PRC_T1('PreAuthorizationParcial'|| vInterface.EFFECT ||' '||   vInterface.ResponseMessage);
      WTMX_MASSIVELOAD_PKG.ValidateSunnelReturn(pEFFECT          => vInterface.EFFECT,
                                                pResponseCode    => vResponseCode,
                                                pResponseMessage => vInterface.ResponseMessage,
                                                pCOD_RET         => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                pMSG_RET         => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                                pTIP_RET         => vReturnTip);
      --
      IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode,0) <> 0 THEN
        --
        UpdateLine(PNU_REG      => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                    PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                    PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                    PTRACK      => 'PreAuthorizationParcial. Erro ao '||vTrack,
                    PRAISE_EXC  => TRUE);
        --
        RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
        --
      END IF;
      --
    END IF;
    --
    --
    IF NVL(vInterface.EFFECT,'R') = 'P' THEN
      -- Carrega Header
      l:= l + 1;
      vLinhasParcial.extend;
      vLinhasParcial(l):= 1;
      --
      IF NOT WTMX_MASSIVELOAD_PKG.vLines.EXISTS(1) THEN
        --
        WTMX_MASSIVELOAD_PKG.GetSpecificLine(PCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                        PCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                        PNU_REG   => 1,
                        PData     => WT_MASSIVELOAD_PKG.gLines(1),
                        PType     => vTypes,
                        pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                        pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                        pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
        WTMX_MASSIVELOAD_PKG.vLines(1):= WT_MASSIVELOAD_PKG.gLines(1);
        --
        IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
          --
          ProcessError(WTMX_MASSIVELOAD_PKG.vReturnCode, 'PreAuthorizationParcial. Erro ao '||vTrack, TRUE);
          --
        END IF;
      END IF;
      --
      -- Carrega Linha de autenticação
      l:= l + 1;
      vLinhasParcial.extend;
      vLinhasParcial(l):= 2;
      --
      IF NOT WTMX_MASSIVELOAD_PKG.vLines.EXISTS(2) THEN
        WTMX_MASSIVELOAD_PKG.GetSpecificLine(PCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                        PCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                        PNU_REG   => 2,
                        PData     => WT_MASSIVELOAD_PKG.gLines(2),
                        PType     => vTypes,
                        pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                        pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                        pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
        WTMX_MASSIVELOAD_PKG.vLines(2):= WT_MASSIVELOAD_PKG.gLines(2);
        --
        IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
          --
          ProcessError(WTMX_MASSIVELOAD_PKG.vReturnCode, 'PreAuthorizationParcial. Erro ao '||vTrack, TRUE);
          --
        END IF;
        --
      END IF;
      --
      -- Carrega linhas adicionais do registro (quebras)
      l:= l + 1;
      vLinhasParcial.extend;
      vLinhasParcial(l):= WT_MASSIVELOAD_PKG.gFile.NU_REG;
      FOR RegAdc IN (SELECT R.NU_REG, M.CD_MDL_REG, M.IN_TOT_REG, M.NU_ORD_PRC
                     FROM PTC_CMS_REG R, PTC_CMS_MDL_REG M
                     WHERE CD_ARQ = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
                       AND NU_REG > WT_MASSIVELOAD_PKG.gFile.NU_REG
                       AND M.CD_MDL_REG = R.CD_MDL_REG
                     ORDER BY R.NU_REG) LOOP
         IF RegAdc.IN_TOT_REG = 'T' OR RegAdc.NU_ORD_PRC > 9 THEN -- ainda mesmo registro
           EXIT;
         END IF;
         --
         l:= l + 1;
         vLinhasParcial.extend;
         vLinhasParcial(l):= RegAdc.NU_REG;
         WTMX_MASSIVELOAD_PKG.GetSpecificLine(PCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                        PCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                        PNU_REG   => RegAdc.NU_REG, --WT_MASSIVELOAD_PKG.gFile.NU_REG+1,
                        PData     => WT_MASSIVELOAD_PKG.gLines(RegAdc.NU_REG),
                        PType     => vTypes,
                        pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                        pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                        pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
         WTMX_MASSIVELOAD_PKG.vLines(RegAdc.NU_REG):= WT_MASSIVELOAD_PKG.gLines(RegAdc.NU_REG);
         --
         IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
           --
           ProcessError(WTMX_MASSIVELOAD_PKG.vReturnCode, 'PreAuthorizationParcial. Erro ao '||vTrack, TRUE);
           --
         END IF;
         --
       END LOOP;
       --
       -- Load
       PreAuthorizationLoad(pCD_BAS         => vCD_BAS,
                         pCD_GST         => vCD_GST,
                         pCD_CSL         => vCD_CSL,
                         pCD_CTR_CLI     => vCD_CTR_CLI,
                         pTab_Rec        => vTab_Rec,
                         pIN_VALIDACAO_INICIAL=> FALSE,
                         pQtde_PTD       => vQtde_PTD,
                         pQtde_CAT       => vQtde_CAT,
                         pLinhasParcial  => vLinhasParcial,
                         pMSG_USER   => WTMX_MASSIVELOAD_PKG.vUserMessage,
                         pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode,
                         pMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage);
       --
       IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
         --
         ProcessError(WTMX_MASSIVELOAD_PKG.vReturnCode, 'PreAuthorizationParcial. Erro ao '||vTrack, TRUE);
         --
       END IF;
       --
       PreAuthorizationCrud( pCD_BAS         => vCD_BAS,
                             pCD_GST         => vCD_GST,
                             pCD_CSL         => vCD_CSL,
                             pCD_CTR_CLI     => vCD_CTR_CLI,
                             pTab_Rec        => vTab_Rec,
                             PMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                             PCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                             PMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);

       --
       IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
         --
         ProcessError(WTMX_MASSIVELOAD_PKG.vReturnCode, 'PreAuthorizationParcial. Erro ao '||vTrack, TRUE);
         --
       END IF;
       --
    --
    END IF;
    --

    IF WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'V' THEN
      ROLLBACK TO spPARTIAL;
    END IF;
    --
    WTMX_MASSIVELOAD_PKG.vUserMessage   := SQLERRM;
    WTMX_MASSIVELOAD_PKG.vReturnMessage := WTMX_MASSIVELOAD_PKG.vUserMessage;
    WTMX_MASSIVELOAD_PKG.vReturnCode    := SQLCODE;
    --
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --

  EXCEPTION
    --
    WHEN WTMX_MASSIVELOAD_PKG.EProcessError THEN
      --
      --
      IF WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'V' THEN
        ROLLBACK TO spPARTIAL;
      END IF;
      --
      --
      WT_MASSIVELOAD_PKG.gProcessInfo.ExceptionType := 'EProcessError';
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      RAISE;
      --
    WHEN WTMX_MASSIVELOAD_PKG.EProcessReturn THEN
      --
      --
      IF WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'V' THEN
        ROLLBACK TO spPARTIAL;
      END IF;
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      RETURN;
      --
    WHEN OTHERS THEN
      --
      IF WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'V' THEN
        ROLLBACK TO spPARTIAL;
      END IF;
      --
      -- Auditoria -----------------------------------------------
      WT2_AUDIT_UTL.AuditError($$PLSQL_UNIT||'.PreAuthorizationParcial - ' || SQLERRM);
      ------------------------------------------------------------
      --
      UpdateLine(PNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                 PCD_MSG_ERR => SQLCODE,
                 PDS_MSG_ERR => SQLERRM,
                 PTRACK      => 'PreAuthorizationParcial. Erro ao '||vTrack,
                 PRAISE_EXC  => FALSE);
      --
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      RAISE;
  END PreAuthorizationParcial;
  --
  ----------------------------------------------------------------------
  -- Procedure de Finalização Especialista -
  ----------------------------------------------------------------------
  PROCEDURE PreAuthorizationFinish(PCOD_RET OUT NUMBER) IS
    --
    vPar             TY_AUDIT_PARAM_TBL;
    --
    -- Variaveis de Apoio
    vCD_GST          PTC_GST.CD_GST%TYPE;
    vCD_CSL          PTC_GST.CD_CSL%TYPE;
    vCD_BAS          PTC_BAS.CD_BAS%TYPE;
    vNU_PED          PTC_PED_CAT.NU_PED%TYPE;
    vQtde_PTD        NUMBER := 0;
    vQtde_CAT        NUMBER := 0;
    --
    vModule          VARCHAR2(100);
    vAction          VARCHAR2(100);
    --
    vTab_Rec         T_Tab_Rec; -- Registros
    --
    -- Variaveis do Arquivo
    vCD_CTR_CLI      PTC_CTR_CLI.CD_CTR_CLI%TYPE;
    --
    vStatus          PTC_CMS_ARQ_DOM.CD_STA_CMM%TYPE;
    --
    vTrack           VARCHAR2(500);
    --
    vTIP_RET         varchar2(30);
    --
    vAllEffects      VARCHAR2(1);
  BEGIN
    --
    -- Auditoria -------------------------------------------------------------------
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'PreAuthorizationFinish');
    vPar    := TY_AUDIT_PARAM_TBL();
    vPar.EXTEND(2);
    vPar(1) := TY_AUDIT_PARAM_OBJ('CD_ARQ'         , WT_MASSIVELOAD_PKG.gFile.CD_ARQ);
    vPar(2) := TY_AUDIT_PARAM_OBJ('CD_DOM'         , WT_MASSIVELOAD_PKG.gFile.CD_DOM);
    --
    WT2_AUDIT_UTL.AuditCreate(pCD_USU => SYS_CONTEXT('USERENV', 'OS_USER'),
                              pDS_ORI => $$PLSQL_UNIT||'.PreAuthorizationFinish',
                              pEN_IP  => SYS_CONTEXT('USERENV', 'HOST'),
                              pID_MSG => NULL,
                              pID_REQ => NULL,
                              pPRM    => vPar,
                              pCLOB   => NULL);
    ---------------------------------------------------------------------------
    --
    WTMX_MASSIVELOAD_PKG.vFinancialInd := 'F';
    --
    -- Numero Pedido gerado
    vTrack:= 'buscar numero do pedido gerado';
    SELECT MAX(NU_PED)
    INTO vNU_PED
    FROM PTC_CMS_ARQ_PED
    WHERE CD_ARQ = WT_MASSIVELOAD_PKG.gFile.CD_ARQ;

    --
    -- Efetuar as leituras de status antes de seguir processamento
    vTrack:= 'ler status atual do arquivo';
    SELECT AD.CD_STA_CMM
      INTO vStatus
      FROM PTC_CMS_ARQ_DOM AD
     WHERE AD.CD_ARQ = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
       AND AD.CD_DOM = WT_MASSIVELOAD_PKG.gFile.CD_DOM;
    --
    IF vStatus = 78 THEN
      --
      WTMX_MASSIVELOAD_PKG.vFinancialInd := 'T';
      --
      -- Verifica os erros no arquivo de interface
      --
      vTrack:= 'verifica os erros no arquivo de interface';
    --
      vAllEffects := 'T';
      IF WT_MASSIVELOAD_PKG.gFile.TP_PRC = 'F' THEN
        --
        SELECT DECODE(COUNT(1), 0, 'T', 'F')
        INTO  vAllEffects
        FROM TKT_CMS_1038_155_PREAUT_HEADER
                    WHERE FILEID = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
                      AND DOMAINID = WT_MASSIVELOAD_PKG.gFile.CD_DOM
                      AND NVL(EFFECT, 'X') = 'R';
        --
      END IF;
      --
      FOR R1 IN (SELECT EFFECT, ROWNUMBER , RESPONSEMESSAGE
                   FROM TKT_CMS_1038_155_PREAUT_HEADER
                  WHERE FILEID = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
                    AND DOMAINID = WT_MASSIVELOAD_PKG.gFile.CD_DOM
                    AND (vAllEffects = 'T' OR NVL(EFFECT, 'X') = 'R' ) ) LOOP
        --
        -- Verifica as colunas EFFECT do detalhe
        WTMX_MASSIVELOAD_PKG.ValidateSunnelReturn(pEFFECT => R1.EFFECT,
                              pRESPONSECODE      => NVL(WTMX_UTILITY_PKG.GetSunnelError(R1.RESPONSEMESSAGE ,18),9999),
                              pRESPONSEMESSAGE   => R1.RESPONSEMESSAGE,
                              pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode,
                              pMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                              pTIP_RET    => vTIP_RET);
        --
        --
        IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode,0) <> 0 THEN
          --
          IF NVL(vTIP_RET, 'NORMAL') <> 'NORMAL' THEN
            PCOD_RET:= WTMX_MASSIVELOAD_PKG.vReturnCode;
          END IF;
          --
          UpdateLine(PNU_REG     => R1.ROWNUMBER,
                     PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                     PDS_MSG_ERR => WTMX_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode),
                     PTRACK      => 'PreAuthorizationFinish. Erro ao '||vTrack,
                     PRAISE_EXC  => TRUE);
          --
        END IF;
        --
      END LOOP;
      --
      IF NVL(PCOD_RET,0) <> 0 THEN
        --
        ProcessError(PCOD_RET, 'PreAuthorizationFinish. Erro ao '||vTrack, TRUE);
        --
      END IF;
      --
    END IF;
    --
    -- Recupera quantidade total de linhas e quantidade de linhas com erro
    vTrack:= 'ler status do processamento';
    vStatus:= WTMX_MASSIVELOAD_PKG.GetFileEndProcStatus(WT_MASSIVELOAD_PKG.gFile.CD_ARQ);

    --
    --
    -- Verifica se o Processamento e Total ou nao houve parte financeira
    IF ( WT_MASSIVELOAD_PKG.gFile.TP_PRC = 'F' AND vStatus <> 80 )THEN
      --
      -- Atualiza o status do Dominio do Arquivo para "Processando WEM"
      vTrack:= 'atualizar o status do Dominio do Arquivo para "Processando WEM';
      WTMX_MASSIVELOAD_PKG.MassiveLoadFileDomainUpdStatus(pCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                          pCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                          pDT_INI_PRC => NULL,
                                                          pDT_FIM_PRC => NULL,
                                                          pCD_STA_CMM => 77, -- Processando WEM
                                                          pMSG_USER   => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                          pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                          pMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
         --
         PCOD_RET:= WTMX_MASSIVELOAD_PKG.vReturnCode;
         ProcessError(PCOD_RET, 'PreAuthorizationFinish. Erro ao '||vTrack, TRUE);
         --
      END IF;
      --
      -- Carga e validação das linhas do arquivo
      --
      -- Faz a leitura das linhas do dominio, desprezando as linhas com erro
      vTrack:= 'ler linhas do dominio';
      --
      WTMX_MASSIVELOAD_PKG.GetDomainLines(pCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                          pCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                          PIN_QUEBRA=> TRUE,
                                          pData     => WTMX_MASSIVELOAD_PKG.vLines,
                                          pType     => WTMX_MASSIVELOAD_PKG.vTypes,
                                          pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                          pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                          pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
        --
        PCOD_RET:= WTMX_MASSIVELOAD_PKG.vReturnCode;
        ProcessError(PCOD_RET, 'PreAuthorizationFinish. Erro ao '||vTrack, TRUE);
        --
      END IF;
      --
      --
      vTrack:= 'executar PreAuthorizationLoad';
      PreAuthorizationLoad(pCD_BAS         => vCD_BAS,
                           pCD_GST         => vCD_GST,
                           pCD_CSL         => vCD_CSL,
                           pCD_CTR_CLI     => vCD_CTR_CLI,
                           pTab_Rec        => vTab_Rec,
                           pIN_VALIDACAO_INICIAL => FALSE,
                           pQtde_PTD       => vQtde_PTD,
                           pQtde_CAT       => vQtde_CAT,
                           PMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                           PCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                           PMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
        --
        PCOD_RET:= WTMX_MASSIVELOAD_PKG.vReturnCode;
        ProcessError(PCOD_RET, 'PreAuthorizationFinish. Erro ao '||vTrack, TRUE);
        --
      END IF;
      --
      --
      vTrack:= 'cadastrar NV';
      PreAuthorizationCrud( pCD_BAS   => vCD_BAS,
                               pCD_GST         => vCD_GST,
                               pCD_CSL         => vCD_CSL,
                               pCD_CTR_CLI     => vCD_CTR_CLI,
                               pTab_Rec        => vTab_Rec,
                               PMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                               PCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                               PMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
        --
        PCOD_RET:= WTMX_MASSIVELOAD_PKG.vReturnCode;
        ProcessError(PCOD_RET, 'PreAuthorizationFinish. Erro ao '||vTrack, TRUE);
        --
      END IF;
      --
    END IF;
    --
    --
    IF WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'A' THEN
      COMMIT;
    ELSE
      ROLLBACK;
    END IF;
   --
   --
   vTrack:= 'atualizar status do pedido';
   vStatus:= WTMX_MASSIVELOAD_PKG.GetFileEndProcStatus(WT_MASSIVELOAD_PKG.gFile.CD_ARQ);
   --
   IF vStatus = 80 THEN
      --
      WTMX_MASSIVELOAD_PKG.vFinancialInd := 'F';
      --
   END IF;
   --
   COMMIT;
   --
   --
   PCOD_RET:= 0;
   --
   DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
   --
  EXCEPTION
    --
    WHEN WTMX_MASSIVELOAD_PKG.EProcessReturn THEN
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      RETURN;
      --
    WHEN WTMX_MASSIVELOAD_PKG.EProcessError THEN
      --
      IF NVL(PCOD_RET,0) = 0 THEN
        PCOD_RET:= SQLCODE;
      END IF;
      --
      IF NVL(PCOD_RET,0) = 0 THEN
        PCOD_RET:= 9999;
      END IF;
      --
      WTMX_MASSIVELOAD_PKG.vFinancialInd := 'F';
      --
      WTMX_MASSIVELOAD_PKG.vExceptionType := 'EProcessError';
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
    WHEN OTHERS THEN
      -- Auditoria -------------------------------------------------
      WT2_AUDIT_UTL.AuditError($$PLSQL_UNIT||'.PreAuthorizationFinish - ' || SQLERRM);
      ------------------------------------------------------------
      --
      WTMX_MASSIVELOAD_PKG.vFinancialInd := 'F';
      --
      PCOD_RET:= SQLCODE;
      ProcessError(SQLCODE, 'PreAuthorizationFinish. WHEN OTHERS - '||SQLERRM, FALSE);
      UpdateLine(PNU_REG     => NULL,
                 PCD_MSG_ERR => PCOD_RET,
                 PDS_MSG_ERR => SQLERRM,
                 PTRACK      => 'PreAuthorizationFinish. Erro ao '||vTrack,
                 PRAISE_EXC  => TRUE);
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      RAISE;
      --
  END;
  --
  ----------------------------------------------------------------------
  -- Procedure de Finalizac?o Especialista -
  ----------------------------------------------------------------------
  PROCEDURE PreAuthorizationResponse(pCD_ARQ      IN PTC_CMS_ARQ_DOM.CD_ARQ%TYPE,
                                     pCD_DOM      IN PTC_CMS_ARQ_DOM.CD_DOM%TYPE,
                                     pNM_ARQ     OUT PTC_CMS_ARQ.NM_ARQ%TYPE,
                                     pResponse   OUT WTMX_MASSIVELOAD_PKG.TResponseList,
                                     pMSG_USER   OUT NOCOPY VARCHAR2,
                                     pCOD_RET    OUT NOCOPY NUMBER,
                                     pMSG_RET    OUT NOCOPY VARCHAR2) IS
    --
    vPar        TY_AUDIT_PARAM_TBL;
    --
    vOperacao       VARCHAR2(10);
    vNomeArquivo    PTC_CMS_ARQ.NM_ARQ%TYPE;
    vStatus         PTC_CMS_ARQ.CD_STA_CMM%TYPE;
    vTpReg          NUMBER(2);
    vInd            BINARY_INTEGER  := 0;
    vCD_PAT         PTC_PAT.CD_PAT%TYPE;
    vNU_PED         PTC_PAT.NU_PED%TYPE;
    --
    vModule         VARCHAR2(100);
    vAction         VARCHAR2(100);
    --
    vCard                 VARCHAR2(20);
    vTagNfcNum            VARCHAR2(20);
    vTagNfcId             VARCHAR2(20);
    --
    --vRiskConditionReasonCodeId T_GCARD.RISKCONDITIONREASONCODEID%TYPE;
    --
  BEGIN
    --
    -- Auditoria -------------------------------------------------------------------
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'PreAuthorizationResponse');
    vPar    := TY_AUDIT_PARAM_TBL();
    vPar.EXTEND(2);
    vPar(1) := TY_AUDIT_PARAM_OBJ('CD_ARQ'         , WT_MASSIVELOAD_PKG.gFile.CD_ARQ);
    vPar(2) := TY_AUDIT_PARAM_OBJ('CD_DOM'         , WT_MASSIVELOAD_PKG.gFile.CD_DOM);
    --
    WT2_AUDIT_UTL.AuditCreate(pCD_USU => SYS_CONTEXT('USERENV', 'OS_USER'),
                              pDS_ORI => $$PLSQL_UNIT||'.PreAuthorizationResponse',
                              pEN_IP  => SYS_CONTEXT('USERENV', 'HOST'),
                              pID_MSG => NULL,
                              pID_REQ => NULL,
                              pPRM    => vPar,
                              pCLOB   => NULL);
    ---------------------------------------------------------------------------

    --
    -- Recupera valores do Cabecalho do arquivo
    SELECT DECODE(ARQ.TP_ACA, 'A', 'APPLY', 'V', 'VALIDATE', ARQ.TP_ACA),
           ARQ.NM_ARQ,
           ARQ.CD_STA_CMM
      INTO vOperacao,
           vNomeArquivo,
           vStatus
      FROM PTC_CMS_ARQ      ARQ,
           PTC_CMS_MDL_ARQ  MDL
     WHERE ARQ.CD_ARQ     = pCD_ARQ
       AND ARQ.CD_MDL_ARQ = MDL.CD_MDL_ARQ;
    --
    -- Popula os dados do arquivo em execucao
    WTMX_MASSIVELOAD_PKG.SetFileData(pCD_ARQ => pCD_ARQ,
                                     pCD_DOM => pCD_DOM);
    --
    --
    -- Leitura de todas as linhas do dominio
    WTMX_MASSIVELOAD_PKG.GetAllDomainLines(PCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                           PCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                           PData     => WTMX_MASSIVELOAD_PKG.vLines,
                                           PType     => WTMX_MASSIVELOAD_PKG.vTypes,
                                           pMSG_USER => pMSG_USER,
                                           pCOD_RET  => pCOD_RET,
                                           pMSG_RET  => pMSG_RET);
    --
    IF  NVL(pCOD_RET,0) <> 0 THEN
        RETURN;
    END IF;
    --
    --
    -- Tratamento para as linhas retornadas da validac?o
    IF WTMX_MASSIVELOAD_PKG.vLines.COUNT > 0 THEN
       WT_MASSIVELOAD_PKG.gFile.NU_REG := WTMX_MASSIVELOAD_PKG.vLines.FIRST;
       --
       WHILE WT_MASSIVELOAD_PKG.gFile.NU_REG IS NOT NULL LOOP
         --
         BEGIN
           --
           vInd  := vInd + 1;
           vTpReg := WTMX_MASSIVELOAD_PKG.GetContent('TpRegistro', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
           --
           IF    vTpReg        = 0 THEN  -- Header
                 vNomeArquivo    := REPLACE(vNomeArquivo, '1038154I', '1038154O');
                 vNomeArquivo    := SUBSTR(vNomeArquivo,  1, 24) || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') || '.TXT';
                 pNM_ARQ         := vNomeArquivo;
                 --
                 pResponse(vInd) := '00' ||
                                    LPAD(WTMX_MASSIVELOAD_PKG.GetContent('Linha',        WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  7, '0') ||
                                    LPAD(WTMX_MASSIVELOAD_PKG.GetContent('NroRemessa',   WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 10, '0') ||
                                    TO_CHAR(SYSDATE, 'DDMMYYYYHH24MISS')                                             ||
                                    RPAD('INT1038.154 - RETORNO CARGA MASIVA DE NOTA VALE', 50, ' ')                 ||
                                    RPAD(vOperacao, 10, ' ');
                                    --
           ELSIF vTpReg = 1 THEN         -- Gestor
                 --
                 pResponse(vInd) := '01' ||
                                    LPAD(WTMX_MASSIVELOAD_PKG.GetContent('Linha',        WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  7, '0') ||
                                    LPAD(WTMX_MASSIVELOAD_PKG.GetContent('Manager',      WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 12, '0') ||
                                    LPAD(WTMX_MASSIVELOAD_PKG.GetContent('Base',         WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 12, '0') ||
                                    SUBSTR(LPAD(WTMX_MASSIVELOAD_PKG.GetContent('CodErroReg', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  6, '0'), 3, 4);
                                    --
           ELSIF vTpReg = 2 THEN            -- Nota Vale
                 --
                 BEGIN
                     SELECT PAT.CD_PAT,
                            PAT.NU_PED
                       INTO vCD_PAT,
                            vNU_PED
                       FROM TKT_CMS_1038_155_PREAUT_HEADER TKT,
                            PTC_PAT                        PAT
                      WHERE TKT.PREAUTHORIZATIONID  = PAT.CD_PAT
                        AND TKT.FILEID              = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
                        AND TKT.DOMAINID            = WT_MASSIVELOAD_PKG.gFile.CD_DOM
                        AND TKT.ROWNUMBER           = WT_MASSIVELOAD_PKG.gFile.NU_REG;
                 EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                          vCD_PAT  := 0;
                          vNU_PED  := 0;
                 END;
                 --
                 pResponse(vInd) := '02' ||
                                    LPAD(WTMX_MASSIVELOAD_PKG.GetContent('Linha',        WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  7, '0') ||
                                    LPAD(NVL(WTMX_MASSIVELOAD_PKG.GetContent('NuPedExt', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),0), 30, '0') ||
                                    LPAD(vNU_PED,                                                           12, '0') ||
                                    LPAD(vCD_PAT,                                                           12, '0') ||
                                    SUBSTR(LPAD(WTMX_MASSIVELOAD_PKG.GetContent('CodErroReg', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  6, '0'), 3, 4);
                                    --
           ELSIF vTpReg = 3 THEN            -- Portador
                 --
             --
             vCard      := WTMX_MASSIVELOAD_PKG.GetContent('NuCartao', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
             vTagNfcNum := WTMX_MASSIVELOAD_PKG.GetContent('TagNfcNum', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
             vTagNfcId  := WTMX_MASSIVELOAD_PKG.GetContent('TagNfcId', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
             -- Se CARD_NUMBER não for informado, obter o cartão ativo a partir dos novos campos
             -- (TAG_NUMERICA ou TAG_HEXADECIMAL)
             --
             IF vCard IS NULL THEN
               IF vTagNfcNum IS NOT NULL THEN
                --
                SELECT MAX(C.NU_CAT)
                INTO vCard
                FROM PTC_DAD_VEI_EQP D, PTC_VEI_EQP V, PTC_CAT C, T_GCURRENTCARD CC
                WHERE vTagNfcNum   = D.NU_TAG_NFC
                  AND V.CD_VEI_EQP = D.CD_VEI_EQP
                  AND C.CD_PTD     = V.CD_PTD
                  AND CC.CARDID    = C.NU_CAT;
                --
               ELSIF vTagNfcId IS NOT NULL THEN
                --
                SELECT MAX(C.NU_CAT)
                INTO vCard
                FROM PTC_DAD_VEI_EQP D, PTC_VEI_EQP V, PTC_CAT C, T_GCURRENTCARD CC
                WHERE D.ID_TAG_NFC = vTagNfcId
                  AND V.CD_VEI_EQP = D.CD_VEI_EQP
                  AND C.CD_PTD     = V.CD_PTD
                  AND CC.CARDID = C.NU_CAT;
                --
               END IF;
             END IF;
             --
             /*SELECT max(C.RISKCONDITIONREASONCODEID)
             INTO vRiskConditionReasonCodeId
             FROM T_GCARD C
             WHERE CARDID = vCard;*/

                 pResponse(vInd) := '03' ||
                                    LPAD(WTMX_MASSIVELOAD_PKG.GetContent('Linha',        WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),      7, '0') ||
                                    LPAD(NVL(WTMX_MASSIVELOAD_PKG.GetContent('NuPedExt2',WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 0), 30, '0') ||
                                    LPAD(vCard,     19, '0') ||
                                    LPAD(vNU_PED,                                                                 12, '0') ||
                                    LPAD(vCD_PAT,                                                                 12, '0') ||
                                    --LPAD(NVL(vRiskConditionReasonCodeId, '0'), 2, '0')||
                                    SUBSTR(LPAD(WTMX_MASSIVELOAD_PKG.GetContent('CodErroReg', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 6, '0'), 3, 4);
                                    --
           ELSIF vTpReg = 4 THEN            -- Mercadorias
                 --
                 pResponse(vInd) := '04' ||
                                    LPAD(WTMX_MASSIVELOAD_PKG.GetContent('Linha',         WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  7, '0') ||
                                    LPAD(NVL(WTMX_MASSIVELOAD_PKG.GetContent('NuPedExt3', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),0), 30, '0') ||
                                    LPAD(WTMX_MASSIVELOAD_PKG.GetContent('CdMercadoria',  WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  5, '0') ||
                                    LPAD(vNU_PED,                                                              12, '0') ||
                                    LPAD(vCD_PAT,                                                              12, '0') ||
                                    SUBSTR(LPAD(WTMX_MASSIVELOAD_PKG.GetContent('CodErroReg', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  6, '0'), 3, 4);
                                    --
           ELSIF vTpReg = 5 THEN            -- Estabelacimento
                 --
                 pResponse(vInd) := '05' ||
                                    LPAD(WTMX_MASSIVELOAD_PKG.GetContent('Linha',         WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  7, '0') ||
                                    LPAD(NVL(WTMX_MASSIVELOAD_PKG.GetContent('NuPedExt4', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),0), 30, '0') ||
                                    LPAD(WTMX_MASSIVELOAD_PKG.GetContent('CtrEstRestrito',WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 12, '0') ||
                                    LPAD(vNU_PED,                                                              12, '0') ||
                                    LPAD(vCD_PAT,                                                              12, '0') ||
                                    SUBSTR(LPAD(WTMX_MASSIVELOAD_PKG.GetContent('CodErroReg', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  6, '0'), 3, 4);
                                    --
           ELSIF vTpReg = 6 THEN            -- Condutores
                 --
                 pResponse(vInd) := '06' ||
                                    LPAD(WTMX_MASSIVELOAD_PKG.GetContent('Linha',         WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  7, '0') ||
                                    LPAD(NVL(WTMX_MASSIVELOAD_PKG.GetContent('NuPedExt5', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),0), 30, '0') ||
                                    LPAD(WTMX_MASSIVELOAD_PKG.GetContent('CdCondutor',    WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 12, '0') ||
                                    LPAD(vNU_PED,                                                              12, '0') ||
                                    LPAD(vCD_PAT,                                                              12, '0') ||
                                    SUBSTR(LPAD(WTMX_MASSIVELOAD_PKG.GetContent('CodErroReg', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  6, '0'), 3, 4);
                                    --
           ELSIF vTpReg = 7 THEN            -- Restric?o
                 --
                 pResponse(vInd) := '07' ||
                                    LPAD(WTMX_MASSIVELOAD_PKG.GetContent('Linha',           WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),     7, '0') ||
                                    LPAD(NVL(WTMX_MASSIVELOAD_PKG.GetContent('NuPedExt6',   WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),0), 30, '0') ||
                                    LPAD(NVL(WTMX_MASSIVELOAD_PKG.GetContent('HrInicio',    WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),0),  4, '0') ||
                                    LPAD(NVL(WTMX_MASSIVELOAD_PKG.GetContent('HrFim',       WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),0),  4, '0') ||
                                    LPAD(WTMX_MASSIVELOAD_PKG.GetContent('Periodicidade',   WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),     6, '0') ||
                                    LPAD(vNU_PED,                                                                   12, '0') ||
                                    LPAD(vCD_PAT,                                                                   12, '0') ||
                                    SUBSTR(LPAD(WTMX_MASSIVELOAD_PKG.GetContent('CodErroReg', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),   6, '0'), 3, 4);
                                    --
            ELSIF vTpReg = 99 THEN           -- Trailler
                 pResponse(vInd) := '99' ||
                                    LPAD(WTMX_MASSIVELOAD_PKG.GetContent('Linha',            WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),   7, '0') ||
                                    LPAD(WTMX_MASSIVELOAD_PKG.GetContent('NroRemessa',       WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  10, '0') ||
                                    TO_CHAR(WTMX_MASSIVELOAD_PKG.GetContentDate('DtRemessa', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),'DDMMYYYYHH24MISS') ||
                                    LPAD(WTMX_MASSIVELOAD_PKG.GetContent('QtRegistros',      WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  15, '0');
           END IF;
          --
        END;
        --
        WT_MASSIVELOAD_PKG.gFile.NU_REG := WTMX_MASSIVELOAD_PKG.vLines.NEXT(WT_MASSIVELOAD_PKG.gFile.NU_REG);
        --
        --
      END LOOP;     -- Loop vLines
      --
    END IF;
    --
  EXCEPTION
    WHEN OTHERS THEN
      -- Auditoria -------------------------------------------------
      WT2_AUDIT_UTL.AuditError($$PLSQL_UNIT||'.PreAuthorizationResponse - ' || SQLERRM);
      ------------------------------------------------------------
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      RAISE;
  END;
  --
END WTMX_CMS_PREAUTHORIZATION_PKG;
