CREATE OR REPLACE PACKAGE BODY WTMX_CMS_ORDER_PKG IS
  -- *********************
  -- * INTERNAL TYPES    *
  -- *********************
  -- 
  TYPE RCurCardOperationCardList IS RECORD (
    LINES            NUMBER,
    ROWPAG           NUMBER,
    NU_CAT           PTC_CAT.NU_CAT%TYPE,
    NU_CAT_OPE       PTC_CAT.NU_CAT%TYPE,
    CD_TIP_CAT       PTC_TIP_CAT.CD_TIP_CAT%TYPE
  );
  --
  TYPE TUnidadeEntrega IS TABLE OF NUMBER INDEX BY VARCHAR2(12);
  TYPE TEntidade IS TABLE OF NUMBER INDEX BY VARCHAR2(12);
  --
  -- *********************
  -- * VARIAVEIS GLOBAIS *
  -- *********************
  --
  vModule               VARCHAR2(100);
  vAction               VARCHAR2(100);
  vUserMessageLine      VARCHAR2(500);
  vReturnCodeLine       NUMBER;
  vReturnMessageLine    VARCHAR2(500);
  --
  -- ***********************************************
  -- * VARIAVEIS PARA CONTROLE DE EXCECOES GLOBAIS *
  -- ***********************************************
  --
  vExceptionType   VARCHAR2(50);
  --
  -- **********************
  -- * GETCONTENT METHODS *
  -- **********************
  ----------------------------------------------------------------------------------------
  -- Retorna o Codigo do Contrato Cliente a partir do Codigo da Base
  ----------------------------------------------------------------------------------------
  FUNCTION GetContractIDFromCL(PLabelCorpLevel IN VARCHAR2) RETURN NUMBER IS
    --
    vClientContract   PTC_CTR_CLI.CD_CTR_CLI%TYPE;
    vCorporateLevelID PTC_BAS.CD_BAS%TYPE;
    --
    gModule VARCHAR2(100);
    gAction VARCHAR2(100);
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(gModule, gAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'GetContractIDFromCL');
    --
   
    vCorporateLevelID := WTMX_MASSIVELOAD_PKG.GetContentNumber(PLabel => PLabelCorpLevel,
                                                               PLine  => WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
                                                                  
    --
    BEGIN
      --
      SELECT CC.CD_CTR_CLI
        INTO vClientContract
        FROM PTC_BAS     BAS,
             PTC_CTR_CLI CC
       WHERE BAS.CD_CLI = CC.CD_CLI
         AND BAS.CD_BAS = vCorporateLevelID;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --
        vClientContract := NULL;
        --
    END;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(gModule, gAction);
    --
    RETURN vClientContract;
    --
  END GetContractIDFromCL;  
  --
  ----------------------------------------------------------------------------------------
  -- Retorna o Codigo do Usuario a partir do Codigo do Gestor
  ----------------------------------------------------------------------------------------
  FUNCTION GetUserFromManager(PLabelManager   IN VARCHAR2,
                              PLabelCorpLevel IN VARCHAR2) RETURN NUMBER IS
    --
    vManagerID        PTC_GST.CD_GST%TYPE;
    vCorporateLevelID PTC_BAS.CD_BAS%TYPE;
    vUser             PTC_GST.CD_USU%TYPE;
    --
    gModule VARCHAR2(100);
    gAction VARCHAR2(100);
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(gModule, gAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'GetUserFromManager');
    --
    vManagerID := WTMX_MASSIVELOAD_PKG.GetContentNumber(PLabel => PLabelManager,
                                                  PLine  => WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
    --
    vCorporateLevelID := WTMX_MASSIVELOAD_PKG.GetContentNumber(PLabel => PLabelCorpLevel,
                                                         PLine  => WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
    --                                                     
    BEGIN
      --
      SELECT MAX(G.CD_USU)
        INTO vUser
        FROM PTC_GST G,
             PTC_BAS B, 
             PTC_CLI C 
       WHERE B.CD_BAS = vCorporateLevelID 
         AND B.CD_CLI = C.CD_CLI 
         AND C.CD_CSL = G.CD_CSL 
         AND G.CD_GST = vManagerID;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --
        vUser := NULL;
        --
    END;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(gModule, gAction);
    --
    RETURN vUser;
    --
  END GetUserFromManager;  
  --
  ----------------------------------------------------------------------------------------
  -- Retorna o ProductCreditLineType ID a partir do Codigo da Base
  ----------------------------------------------------------------------------------------
  FUNCTION GetProdCreditLineFromCorpLevel(PLabelCorpLevel IN VARCHAR2) RETURN NUMBER IS
    --
    vCorporateLevelID PTC_BAS.CD_BAS%TYPE;
    vResult           PTC_PDT_SVC_LIN_CDT_SNN.CD_PDT_LIN_CRD%TYPE;
    --
    gModule VARCHAR2(100);
    gAction VARCHAR2(100);
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(gModule, gAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'GetProdCreditLineFromCorpLevel');
    --
    vCorporateLevelID := WTMX_MASSIVELOAD_PKG.GetContentNumber(PLabel => PLabelCorpLevel,
                                                         PLine  => WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
    --                                                     
    BEGIN
      --
      SELECT PSLCS.CD_PDT_LIN_CRD
        INTO vResult
        FROM PTC_BAS B,
             PTC_PDT_SVC_LIN_CDT_SNN PSLCS 
       WHERE B.CD_BAS = vCorporateLevelID
         AND B.CD_MDL_FAT = PSLCS.CD_MDL_FAT;        
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --
        vResult := NULL;
        --
    END;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(gModule, gAction);
    --
    RETURN vResult;
    --
  END GetProdCreditLineFromCorpLevel;  
  --
  ----------------------------------------------------------------------------------------
  -- Retorna o Codigo do Produto a partir do Codigo do Contrato Cliente 
  ----------------------------------------------------------------------------------------
  FUNCTION GetProductFromContract(PLabelContract IN VARCHAR2) RETURN NUMBER IS
    --
    vClientContract   PTC_CTR_CLI.CD_CTR_CLI%TYPE;
    vProduct          PTC_CTR_CLI.CD_PDT%TYPE;
    --
    gModule VARCHAR2(100);
    gAction VARCHAR2(100);
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(gModule, gAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'GetProductFromContract');
    --
    vClientContract := WTMX_MASSIVELOAD_PKG.GetContent(PLabel => PLabelContract,
                                                       PLine  => WT_MASSIVELOAD_PKG.gLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
    --
    BEGIN
      --
      SELECT CC.CD_PDT
        INTO vProduct
        FROM PTC_CTR_CLI CC
       WHERE CC.CD_CTR_CLI = vClientContract;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --
        vProduct := NULL;
        --
    END;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(gModule, gAction);
    --
    RETURN vProduct;
    --
  END GetProductFromContract;   
  --
  -- *********************
  -- * PUBLIC METHODS    *
  -- *********************
  
  ----------------------------------------------------
  -- Procedure Especialista - Grava o erro 
  ----------------------------------------------------
  PROCEDURE ProcessError(PCOD_RET PTC_CMS_ARQ_EXC.CD_ERR_EXC%TYPE,
                         PTRACK   PTC_CMS_ARQ_EXC.DC_CPL_EXC%TYPE DEFAULT NULL,
                         PRAISE   BOOLEAN DEFAULT FALSE) IS  
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
        RAISE WTMX_MASSIVELOAD_PKG.EProcessError;                   
      END IF;  
  END;
  ----------------------------------------------------------
  -- Procedure Especialista - Valida o cartão ativo 
  -- 1.25 
  ----------------------------------------------------------
  PROCEDURE GetCardFromTagNFC ( PNU_CARD    IN  OUT    PTC_CAT.NU_CAT%TYPE,
                                PID_TAG_NFC IN         PTC_DAD_VEI_EQP.ID_TAG_NFC%TYPE,
                                PNU_TAG_NFC IN         PTC_DAD_VEI_EQP.NU_TAG_NFC%TYPE,
                                pCOD_RET    OUT NOCOPY NUMBER
                              ) IS
   --
   vCard              PTC_CAT.NU_CAT%TYPE;                 
   vIdTagNfc          PTC_DAD_VEI_EQP.ID_TAG_NFC%TYPE;
   vNuTagNfc          PTC_DAD_VEI_EQP.NU_TAG_NFC%TYPE;
   --
   EReturnError       EXCEPTION;
   --
   BEGIN
     --
     IF PNU_CARD IS NOT NULL THEN   -- Validação do cartão
        --
        BEGIN
           SELECT CAT.NU_CAT, DVE.ID_TAG_NFC, DVE.NU_TAG_NFC
             INTO vCard,
                  vIdTagNfc,
                  vNuTagNfc
             FROM PTC_CAT         CAT, 
                  PTC_DAD_VEI_EQP DVE, 
                  PTC_VEI_EQP     VEI
            WHERE CAT.NU_CAT     = PNU_CARD
              AND VEI.CD_PTD     = CAT.CD_PTD
              AND DVE.CD_VEI_EQP = VEI.CD_VEI_EQP;   
         EXCEPTION
           WHEN NO_DATA_FOUND THEN 
             pCOD_RET    := 183143;  -- Could not find Card Number
             RETURN;           
           WHEN OTHERS THEN 
             pCOD_RET    := 182190;  -- Internal error.
             RETURN;
             --
        END;
        --
        -- Validar a TAG HEX, quando fornecido
        IF NVL(PID_TAG_NFC,vIdTagNfc) <> vIdTagNfc OR
          (vIdTagNfc IS NULL  AND PID_TAG_NFC IS NOT NULL)  THEN
           pCOD_RET    := 183156;  -- The hexadecimal tag is different from the one registered for the vehicle / card provided
           RETURN;
        END IF;
        --
        IF NVL(PNU_TAG_NFC,vNuTagNfc) <> vNuTagNfc  THEN
           pCOD_RET    := 183157;     -- Could not found Vehicle with numerical TAG informed.
           RETURN;
        END IF;
        --                
     ELSIF PID_TAG_NFC IS NOT NULL THEN        -- TAG Hexadecimal        
        --
        BEGIN -- Validacao da TAG Hexadecimal 
           SELECT CAT.NU_CAT, DVE.NU_TAG_NFC
             INTO vCard,
                  vNuTagNfc
             FROM PTC_DAD_VEI_EQP DVE, 
                  PTC_VEI_EQP     VEI, 
                  PTC_CAT         CAT, 
                  T_GCURRENTCARD  CUC
            WHERE DVE.ID_TAG_NFC = PID_TAG_NFC
              AND VEI.CD_VEI_EQP = DVE.CD_VEI_EQP
              AND CAT.CD_PTD     = VEI.CD_PTD
              AND CUC.CARDID     = CAT.NU_CAT;
           --
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            pCOD_RET    := 183156;  -- Could not found Vehicle with hexadecimal TAG informed.
            RETURN;
          WHEN OTHERS THEN 
            pCOD_RET    := 182190;  -- Internal error.
            RETURN;
        END; -- 1.25 
        -- 
        IF NVL(PNU_TAG_NFC,vNuTagNfc) <> vNuTagNfc  THEN
           pCOD_RET    := 183157;     -- Could not found Vehicle with numerical TAG informed.
           RETURN;
        END IF;
     ELSIF PNU_TAG_NFC IS NOT NULL THEN      -- TAG Numerica          
        --
        BEGIN -- Validação da TAG Numerica 
           SELECT CAT.NU_CAT
             INTO vCard
             FROM PTC_DAD_VEI_EQP DVE, 
                  PTC_VEI_EQP     VEI, 
                  PTC_CAT         CAT, 
                  T_GCURRENTCARD  CUC
            WHERE DVE.NU_TAG_NFC  = PNU_TAG_NFC
              AND VEI.CD_VEI_EQP  = DVE.CD_VEI_EQP
              AND CAT.CD_PTD      = VEI.CD_PTD
              AND CUC.CARDID      = CAT.NU_CAT;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            pCOD_RET    := 183157;  -- Could not found Vehicle with numerical TAG informed.
            RETURN;
          WHEN OTHERS THEN 
            pCOD_RET    := 182190;  -- Internal error.
            RETURN;
        END; 
        --
     END IF;   
     --
     IF vCard IS NULL THEN 
       --
       pCOD_RET  := 183143;  -- Could not find Card Number
       --
     ELSE
       PNU_CARD  := vCard;
     END IF; 
  EXCEPTION
      WHEN OTHERS THEN
         pCOD_RET := 9999;
   
  END GetCardFromTagNFC;  -- 1.25
                               
  ----------------------------------------------------
  -- Procedure Especialista - Distribuicao de Credito
  ----------------------------------------------------
  PROCEDURE CreditDistributionExecute IS
    --
    vNU_REG               PTC_CMS_REG.NU_REG%TYPE;
    vQtdeLinErro          NUMBER;
    vQtdeLinDetalheErro   NUMBER; -- 1.11
    vQtdeLinDetalhe       NUMBER; -- 1.11
    vQtdeTotLin           NUMBER;
    vErro                 NUMBER;
    vTpReg                NUMBER(2);
    vCD_GST               PTC_GST.CD_GST%TYPE;
    vCD_BAS               PTC_BAS.CD_BAS%TYPE;
    vCD_GST_RET           PTC_GST.CD_GST%TYPE;                
    vCD_USU_SOL           PTC_USU.CD_USU%TYPE;
    vCD_CSL               PTC_CSL.CD_CSL%TYPE;                
    vCD_TIP_GST           PTC_GST.CD_TIP_GST%TYPE;   
    vExtPed               PTC_PED.NU_PED_EXT%TYPE;
    vNU_PED               PTC_PED_CAT.NU_PED%TYPE;
    vDt_Agd               PTC_ITE_PED.DT_AGD%TYPE;
    vCD_TIP_PED           PTC_PED_CAT.CD_TIP_PED%TYPE;
    vVL_PED_FIN_BAS       PTC_PED_FIN_BAS.VL_PED_FIN_BAS%TYPE;
    vQT_ITE_PED           PTC_ITE_PED.QT_ITE_PED%TYPE;
    vVL_TRF               NUMBER;
    vCD_CIC_APU           PTC_CIC_APU.CD_CIC_APU%TYPE;
    VCD_TIP_ETD           PTC_ETD.CD_TIP_ETD%TYPE;
    vContrato             PTC_CTR_CLI.CD_CTR_CLI%TYPE;
    vCreditLineType       PTC_PED_FIN_CAT.CD_TIP_LIN_CDT%TYPE;
    vCard                 VARCHAR2(20);
    vTagNfcId             VARCHAR2(20); -- 1.22
    vTagNfcNum            PTC_DAD_VEI_EQP.NU_TAG_NFC%TYPE; -- 1.25  VARCHAR2(20); -- 1.22 
    vCardType             PTC_CAT.CD_TIP_CAT%TYPE;
    vCardStatus           PTC_CAT.CD_STA_CAT%TYPE;
    vCurOut               T_CURSOR;
    vCardOperationList    RCurCardOperationCardList;
    vValue                NUMBER;
    vCreditType           NUMBER;
    vUnitType             NUMBER;
    vMerchandise          NUMBER;
    vMerchQuantity        NUMBER;
    vMerchPrice           NUMBER;
    vAdditionalInfo       VARCHAR2(200); 
    vExpirationDate       DATE;
    vCardBalance          NUMBER;
    vMerchUnit            NUMBER;
    vRoute                VARCHAR2(50);
    vCurrency             NUMBER;
    vCardHolder           NUMBER;
    vOperationClass       VARCHAR2(20);
    vItemDist             CLOB;
    vTrue                 VARCHAR2(1);
    --
    vKM_Quantity               PTC_GPO_DST_CRD_PTD.QT_KM%TYPE;  -- 1.14
    vNU_RND                    PTC_GPO_DST_CRD_PTD.NU_RND%TYPE; -- 1.14   
    --
    eSkipError EXCEPTION; 
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'CreditDistributionExecute');
    --
    -- Atualiza o status do Dominio do Arquivo para "Processando Validacao"
    WTMX_MASSIVELOAD_PKG.MassiveLoadFileDomainUpdStatus(pCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                        pCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                        pDT_INI_PRC => SYSDATE,
                                                        pDT_FIM_PRC => NULL,
                                                        pCD_STA_CMM => 83, -- Processando Validacao
                                                        pMSG_USER   => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                        pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                        pMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage);
    --
    IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
      --
      RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
      --
    END IF;
    --
    BEGIN
      --
      SELECT REQUESTNUMBERFINANCIALTRANSFER  -- 1.09
        INTO vNU_PED
        FROM MX_INTERFACE.TKT_CMS_1027_28_ORDER_HEADER
       WHERE FILEID = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
         AND DOMAINID = WT_MASSIVELOAD_PKG.gFile.CD_DOM;
      --
    EXCEPTION
      --
      WHEN OTHERS THEN
        --
        vNU_PED := NULL;
        --
    END;
    --
    IF vNU_PED IS NOT NULL THEN
      --
      WTMX_MASSIVELOAD_PKG.vFinancialInd := 'T';
      --
      UPDATE MX_INTERFACE.TKT_CMS_1027_28_ORDER_HEADER H
         SET H.EFFECT = NULL,
             H.RESPONSEMESSAGE = NULL,
             H.RESPONSECODE = NULL
       WHERE H.FILEID = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
         AND H.DOMAINID = WT_MASSIVELOAD_PKG.gFile.CD_DOM;
      --
      UPDATE MX_INTERFACE.TKT_CMS_1027_28_ORDER_DETAIL D
         SET D.EFFECT = NULL,
             D.RESPONSEMESSAGE = NULL,
             D.RESPONSECODE = NULL,
             D.CREDITOPERATIONID = NULL,
             D.DEBITOPERATIONID = NULL
       WHERE D.FILEID = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
         AND D.DOMAINID = WT_MASSIVELOAD_PKG.gFile.CD_DOM;
      --
    ELSE
      --
      -- Leitura das linhas do dominio 
      WTMX_MASSIVELOAD_PKG.GetDomainLinesValidate(PCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                  PCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                  PData     => WTMX_MASSIVELOAD_PKG.vLines,
                                                  pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                  pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                  pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode,0) <> 0 THEN
        --
        RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
        --
      END IF;
      --
      -- Recupera quantidade total de linhas e quantidade de linhas com erro
      SELECT COUNT(NULLIF(REG.CD_MSG_ERR, 0)), -- 1.01
             COUNT(CASE WHEN MDL.IN_TOT_REG = 'T' THEN 1 ELSE NULL END), -- 1.11 vQtdeLinDetalhe
             COUNT(CASE WHEN MDL.IN_TOT_REG = 'T' AND NVL(REG.CD_MSG_ERR,0) <> 0 THEN 1 ELSE NULL END), -- 1.11 vQtdeLinDetalheErro
             COUNT(1)
        INTO vQtdeLinErro,
             vQtdeLinDetalhe,
             vQtdeLinDetalheErro,
             vQtdeTotLin
        FROM PTC_CMS_REG      REG
        JOIN PTC_CMS_MDL_REG  MDL ON MDL.CD_MDL_REG = REG.CD_MDL_REG -- 1.11
       WHERE REG.CD_ARQ      = WT_MASSIVELOAD_PKG.gFile.CD_ARQ;  
      --
      IF (WT_MASSIVELOAD_PKG.gFile.TP_PRC = 'F' AND NVL(vQtdeLinErro, 0) > 0)
      OR (WT_MASSIVELOAD_PKG.gFile.TP_PRC = 'P' AND NVL(vQtdeLinErro, 0) = NVL(vQtdeTotLin, 0)) 
      OR (WT_MASSIVELOAD_PKG.gFile.TP_PRC = 'P' AND NVL(vQtdeLinDetalheErro, 0) = NVL(vQtdeLinDetalhe, -1)) -- 1.11
      THEN
        --
        RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
        --
      END IF;
      --
      -- Refaz a leitura das linhas do dominio, desprezando as linhas com erro
      WTMX_MASSIVELOAD_PKG.GetDomainLines(PCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                          PCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                          PData     => WTMX_MASSIVELOAD_PKG.vLines,
                                          PType     => WTMX_MASSIVELOAD_PKG.vTypes,
                                          pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                          pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                          pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode,0) <> 0 THEN
        --
        RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
        --
      END IF;
      --
      -- Coleta os dados carretgados
      IF WTMX_MASSIVELOAD_PKG.vLines.COUNT > 0 THEN
        --
        WT_MASSIVELOAD_PKG.gFile.NU_REG := WTMX_MASSIVELOAD_PKG.vLines.FIRST;
        --
        WHILE WT_MASSIVELOAD_PKG.gFile.NU_REG IS NOT NULL LOOP
          --
          WT_MASSIVELOAD_PKG.gLine        := WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG); 
          vTpReg := WTMX_MASSIVELOAD_PKG.GetContent('TipoRegistro', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          --
          IF vTpReg = 0 THEN  -- Header
            --
            -- Valida a Descric?o da Interface no Header
            vErro := WTMX_MASSIVELOAD_PKG.ValidateInterfaceName('NomeInterface','INT1027.17 ? DISPERSION DE CREDITOS');
            --
            IF vErro > 0 THEN
              --
              WTMX_MASSIVELOAD_PKG.vReturnCode := 182548; -- Invalid Interface Name
              RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
              --
            END IF;
            --
          ELSIF vTpReg = 1 THEN  -- Autenticacão
            --
            vCD_GST := WTMX_MASSIVELOAD_PKG.GetContentNumber('Manager', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            vCD_BAS := WTMX_MASSIVELOAD_PKG.GetContentNumber('Base', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            vCreditLineType := WTMX_MASSIVELOAD_PKG.GetContentNumber('LinhaCredito', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            --
            -- Verificac?o da Abrangencia do Gestor
            WTMX_CORPORATELEVEL_PKG.ManagerHierarchyValidate(pCD_CSL          => NULL,
                                                             pCD_CLI          => NULL,
                                                             pCD_BAS          => vCD_BAS,
                                                             pCD_CTR_CLI      => NULL,
                                                             pCD_GST          => vCD_GST,
                                                             pCD_USU          => NULL,
                                                             pCD_HIE_ETD      => NULL,
                                                             pCD_GST_RET      => vCD_GST_RET,
                                                             pCD_TIP_GST_RET  => vCD_TIP_GST,
                                                             pCD_CSL_RET      => vCD_CSL,
                                                             pMSG_USER        => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                             pCOD_RET         => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                             pMSG_RET         => WTMX_MASSIVELOAD_PKG.vReturnMessage);
            --
            IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode,0) <> 0 THEN
              --
              -- Manager incompatible with hierarchy
              WTMX_MASSIVELOAD_PKG.UpdateLine(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                              PNU_REG     => NULL,            -- WT_MASSIVELOAD_PKG.gFile.NU_REG,
                                              PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,     -- 182190,  
                                              PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,  -- SQLERRM,
                                              pMSG_USER   => vUserMessageLine,
                                              pCOD_RET    => vReturnCodeLine,
                                              pMSG_RET    => vReturnMessageLine);
              --
              IF NVL(vReturnCodeLine,0) <> 0 THEN
                --
                RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                --
              END IF;
              --
              WTMX_MASSIVELOAD_PKG.vUserMessage       := NULL;
              WTMX_MASSIVELOAD_PKG.vReturnCode        := NULL;
              WTMX_MASSIVELOAD_PKG.vReturnMessage     := NULL;
              WTMX_MASSIVELOAD_PKG.vFinancialInd      := NULL;
              --
              RAISE WTMX_MASSIVELOAD_PKG.EProcessReturn; --EProcessError;
              --
            END IF;
            --
            vCD_USU_SOL := WTMX_MASSIVELOAD_PKG.GetContentNumber('UsuarioGestor', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            vContrato := WTMX_MASSIVELOAD_PKG.GetContentNumber('Contrato', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            --
          ELSIF vTpReg = 2 THEN  -- Cabecalho Pedido
            --
            vExtPed         := WTMX_MASSIVELOAD_PKG.GetContent('NroPedido', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            vDt_Agd         := WTMX_MASSIVELOAD_PKG.GetContentDate('DataPedido', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            vVL_PED_FIN_BAS := WTMX_MASSIVELOAD_PKG.GetContentNumber('ValorPedido', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            vQT_ITE_PED     := WTMX_MASSIVELOAD_PKG.GetContentNumber('QtdItens', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            --
            vCD_TIP_PED     := WTMX_MASSIVELOAD_PKG.GetContent('IndPedCredito', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            IF vCD_TIP_PED = 1 THEN
              --
              vCD_TIP_PED := 11; -- Pedido para base e distribuic?o de credito
              --
            ELSIF vCD_TIP_PED = 2 THEN
              --
              vCD_TIP_PED := 2;  -- Somente distribuic?o de credito
              --
            ELSIF vCD_TIP_PED = 3 THEN  
              --
              vCD_TIP_PED := 12;  -- Recolhimento              
              --
            END IF;
            --
          ELSIF vTpReg = 3 THEN  -- Detalhe Pedido
            --
            BEGIN
              WTMX_MASSIVELOAD_PKG.vReturnCode := NULL; 
              WTMX_MASSIVELOAD_PKG.vReturnMessage := NULL;
              --
              vCard      := WTMX_MASSIVELOAD_PKG.GetContent('NroCartao', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
              vTagNfcId  := WTMX_MASSIVELOAD_PKG.GetContent('TagNfcId',  WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)); -- 1.22
              vTagNfcNum := WTMX_MASSIVELOAD_PKG.GetContentNumber('TagNfcNum', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));  -- 1.25

              --
              --

              -- 1.22 / 1.25 inicio
              -- Se CARD_NUMBER não for informado, obter o cartão ativo a partir dos novos campos 
              -- (TAG_NUMERICA ou TAG_HEXADECIMAL)
              
              GetCardFromTagNFC ( PNU_CARD    => vCard ,     
                                  PID_TAG_NFC => vTagNfcId,
                                  PNU_TAG_NFC => vTagNfcNum,
                                  pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode );
              --
              --
              IF WTMX_MASSIVELOAD_PKG.vReturnCode <> 0 THEN   -- Validação do cartão -- 1.25
                 --
                 WTMX_MASSIVELOAD_PKG.vReturnMessage := WT_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode);
                 --
                 -- Atualiza registros com duplicidade
                 WTMX_MASSIVELOAD_PKG.UpdateLine(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                 PNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                                                 PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                 PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                                 pMSG_USER   => vUserMessageLine,
                                                 pCOD_RET    => vReturnCodeLine,
                                                 pMSG_RET    => vReturnMessageLine);
                  --
                  IF NVL(vReturnCodeLine,0) <> 0 THEN
                    --
                    RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                    --
                  END IF;
                  --
                  RAISE eSkipError;
                  --    
              END IF; -- 1.25    
              --
              -- 1.22 / 1.25 fim
              
              --
              vValue := NVL(WTMX_MASSIVELOAD_PKG.GetContentNumber('Valor', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),0);
              vCreditType := WTMX_MASSIVELOAD_PKG.GetContentNumber('TpCredito', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));              
              --
              IF NVL(WT_MASSIVELOAD_PKG.gFile.IN_VLD_DUP, 'F') = 'T' THEN
                --
                -- verifica duplicidade
                IF DBMS_LOB.instr(vItemDist, vCard) > 0 THEN
                  --
                  WTMX_MASSIVELOAD_PKG.vReturnCode := 182589;  -- Numero do cart?o duplicado no arquivo
                  WTMX_MASSIVELOAD_PKG.vReturnMessage := WT_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode);
                  --
                  -- Atualiza registros com duplicidade
                  WTMX_MASSIVELOAD_PKG.UpdateLine(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                  PNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                                                  PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                  PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                                  pMSG_USER   => vUserMessageLine,
                                                  pCOD_RET    => vReturnCodeLine,
                                                  pMSG_RET    => vReturnMessageLine);
                  --
                  IF NVL(vReturnCodeLine,0) <> 0 THEN
                    --
                    RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                    --
                  END IF;
                  --
                  RAISE eSkipError;
                  --                
                END IF;
                --
              END IF;
              --
              IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) = 0 THEN
                --
                -- valida cartao
                BEGIN 
                  SELECT CAT.CD_TIP_CAT
                    INTO vCardType
                    FROM PTC_CAT   CAT
                   WHERE CAT.NU_CAT = vCard;
                EXCEPTION -- 1.01
                  WHEN NO_DATA_FOUND THEN
                    WTMX_MASSIVELOAD_PKG.vReturnCode := 182297; 
                    WTMX_MASSIVELOAD_PKG.vReturnMessage := WT_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode);
                    --
                    -- Atualiza registros com duplicidade
                    WTMX_MASSIVELOAD_PKG.UpdateLine(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                    PNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                                                    PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                    PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                                    pMSG_USER   => vUserMessageLine,
                                                    pCOD_RET    => vReturnCodeLine,
                                                    pMSG_RET    => vReturnMessageLine);
                    --
                    IF NVL(vReturnCodeLine,0) <> 0 THEN
                      --
                      RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                      --
                    END IF;
                    --
                    RAISE eSkipError;
                    --
                END; 
                --
                IF vCardType = 4 THEN  -- Caso seja cart?o estoque deve recuperar o cart?o de operac?o
                  --
                  -- Busca o cart?o de operac?o do cart?o informado (quando houver)
                  WTMX_CARD_PKG.CardGetOperationCardList(CARDLIST  => vCard,
                                                         STARTPAGE => NULL,
                                                         PAGEROWS  => NULL,
                                                         CUR_OUT   => vCurOut);
                  --
                  FETCH vCurOut INTO vCardOperationList;
                  --
                  IF vCardOperationList.NU_CAT_OPE IS NOT NULL THEN
                    --
                    vCard := vCardOperationList.NU_CAT_OPE;
                    --
                  ELSE
                    --
                    WTMX_MASSIVELOAD_PKG.vReturnCode := 180716; 
                    WTMX_MASSIVELOAD_PKG.vReturnMessage := WT_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode);
                    --
                    -- Atualiza registros com duplicidade
                    WTMX_MASSIVELOAD_PKG.UpdateLine(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                    PNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                                                    PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                    PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                                    pMSG_USER   => vUserMessageLine,
                                                    pCOD_RET    => vReturnCodeLine,
                                                    pMSG_RET    => vReturnMessageLine);
                    --
                    IF NVL(vReturnCodeLine,0) <> 0 THEN
                      --
                      RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                      --
                    END IF;
                    --
                    RAISE eSkipError;
                    --                  
                  END IF;
                  --
                  CLOSE vCurOut;
                  --
                END IF;
                --
                BEGIN
                  --
                  SELECT C.CD_STA_CAT
                    INTO vCardStatus
                    FROM PTC_CAT   C
                   WHERE C.NU_CAT = vCard;
                  --
                EXCEPTION                   -- 1.12
                   WHEN NO_DATA_FOUND THEN  -- 1.12
                     vCardStatus := NULL;   -- 1.12
                END;
                --
                IF vCD_TIP_PED = 12 THEN -- 1.15
                  vOperationClass := 'PICKINGUP';
                ELSE  
                  --
                  IF  vValue > 0 AND vCardStatus IS NOT NULL THEN -- 1.12 ref. vCardStatus
                    --
                    vOperationClass := 'DISBURSEMENT';
                    --
                    IF vCardStatus = 6 THEN
                      --
                      WTMX_MASSIVELOAD_PKG.vReturnCode := 182465; 
                      WTMX_MASSIVELOAD_PKG.vReturnMessage := WT_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode);
                      --
                      -- Atualiza registros com duplicidade
                      WTMX_MASSIVELOAD_PKG.UpdateLine(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                      PNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                                                      PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                      PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                                      pMSG_USER   => vUserMessageLine,
                                                      pCOD_RET    => vReturnCodeLine,
                                                      pMSG_RET    => vReturnMessageLine);
                      --
                      IF NVL(vReturnCodeLine,0) <> 0 THEN
                        --
                        RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                        --
                      END IF;
                      --
                      RAISE eSkipError;
                      --
                    END IF;
                    --
                  ELSIF (vValue < 0 AND vCardStatus IS NOT NULL) OR  -- 1.12 ref. vCardStatus  
                        (vValue = 0 AND vCardStatus IS NOT NULL AND vCreditType = 2) THEN -- 1.17 recolhimento qdo relativo NONACCUM
                    --
                    vOperationClass := 'PICKINGUP';
                    --
                  ELSE
                    --
                    vOperationClass := 'BYPASS'; 
                    -- 1.17 (inicio)
                    WTMX_MASSIVELOAD_PKG.vReturnCode := 180491; 
                    WTMX_MASSIVELOAD_PKG.vReturnMessage := WT_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode);
                    --
                    -- Atualiza registros sem valor
                    WTMX_MASSIVELOAD_PKG.UpdateLine(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                    PNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                                                    PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                    PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                                    pMSG_USER   => vUserMessageLine,
                                                    pCOD_RET    => vReturnCodeLine,
                                                    pMSG_RET    => vReturnMessageLine);
                    --
                    IF NVL(vReturnCodeLine,0) <> 0 THEN
                      --
                      RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                      --
                    END IF;
                    --
                    RAISE eSkipError;
                    -- 1.17 (fim)
                  END IF;
                  --
                END IF;
                --
              END IF;
              --
              IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) = 0 AND vOperationClass <> 'BYPASS' THEN
                --
                WTMX_MASSIVELOAD_PKG.vFinancialInd := 'T';
                --
                vCreditType := WTMX_MASSIVELOAD_PKG.GetContentNumber('TpCredito', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
                vUnitType := NVL(WTMX_MASSIVELOAD_PKG.GetContentNumber('TpDistribuicao', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 1); -- 1.14
                vMerchandise := WTMX_MASSIVELOAD_PKG.GetContentNumber('Mercadoria', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
                vMerchQuantity := WTMX_MASSIVELOAD_PKG.GetContentNumber('QtdMercadoria', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
                vMerchPrice := WTMX_MASSIVELOAD_PKG.GetContentNumber('PrecoMercadoria', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
                vAdditionalInfo := WTMX_MASSIVELOAD_PKG.GetContent('Obs', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
                vExpirationDate := WTMX_MASSIVELOAD_PKG.GetContentDate('DtExpiracao', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
                vCardBalance := WTMX_MASSIVELOAD_PKG.GetContentNumber('SaldoCartao', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
                vRoute := WTMX_MASSIVELOAD_PKG.GetContent('Rota', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
                vCurrency := WTMX_MASSIVELOAD_PKG.GetContentNumber('Moeda', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
                --vCardHolder := WTMX_MASSIVELOAD_PKG.GetContentNumber('Portador', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)); -- 1.2
                --
                -- 1.22 inicio
                BEGIN
                  SELECT CAT.CD_PTD
                    INTO vCardHolder
                    FROM PTC_CAT  CAT
                   WHERE CAT.NU_CAT = TRIM(vCard);
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    --
                    vCardHolder := NULL;
                    --
                END;
                -- 1.22 fim      
                --
                vKM_Quantity := WTMX_MASSIVELOAD_PKG.GetContentNumber('QtdKM', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));      -- 1.14
                vNU_RND      := WTMX_MASSIVELOAD_PKG.GetContentNumber('Rendimento', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)); -- 1.14    
                --

                -- Valida infors x tipo NV -- 1.14
                IF (vUnitType = 1 AND  (vKM_Quantity IS NOT NULL OR vNU_RND IS NOT NULL)) OR
                   (vUnitType = 2 AND  (vMerchandise IS NULL OR vMerchQuantity IS NULL OR vMerchPrice IS NULL OR vKM_Quantity IS NOT NULL OR vNU_RND IS NOT NULL)) OR
                   (vUnitType = 3 AND  (vMerchandise IS NULL OR vMerchPrice IS NULL OR vKM_Quantity IS NULL OR vNU_RND IS NULL)) THEN
                   --
                    WTMX_MASSIVELOAD_PKG.vReturnCode := 183046; 
                    WTMX_MASSIVELOAD_PKG.vReturnMessage := WT_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode);
                    --
                    -- Atualiza registros com duplicidade
                    WTMX_MASSIVELOAD_PKG.UpdateLine(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                    PNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                                                    PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                    PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                                    pMSG_USER   => vUserMessageLine,
                                                    pCOD_RET    => vReturnCodeLine,
                                                    pMSG_RET    => vReturnMessageLine);
                    --
                    IF NVL(vReturnCodeLine,0) <> 0 THEN
                      --
                      RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                      --
                    END IF;
                    --
                    RAISE eSkipError;
                    --                  
                END IF;

                -- Valida se portador NÃO está associado a uma controle de Nota Vale
                IF WT_ORDER_PKG.ISCardHolderPreAutorization(NULL, vCardHolder) = 'T' THEN -- 1.13
                  WTMX_MASSIVELOAD_PKG.vReturnCode := 182542; -- Cardholder is associated a PreAuthorization CardGroup
                  WTMX_MASSIVELOAD_PKG.vReturnMessage := WT_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode);
                  --
                  -- Atualiza registros com duplicidade
                  WTMX_MASSIVELOAD_PKG.UpdateLine(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                  PNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                                                  PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                  PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                                  pMSG_USER   => vUserMessageLine,
                                                  pCOD_RET    => vReturnCodeLine,
                                                  pMSG_RET    => vReturnMessageLine);
                  --
                  IF NVL(vReturnCodeLine,0) <> 0 THEN
                    --
                    RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                    --
                  END IF;
                  --
                  RAISE eSkipError;
                  --                  
                END IF;        
                                       
                
                IF vMerchandise IS NOT NULL THEN -- 1.01
                  SELECT M.CD_UND_MRD
                    INTO vMerchUnit
                    FROM PTC_MRD M
                   WHERE M.CD_MRD = vMerchandise;
                ELSE
                  vMerchUnit:= NULL;   
                END IF; 
                --
                IF vItemDist IS NOT NULL THEN
                  --
                  vItemDist  := vItemDist || '|';
                  --
                END IF;
                --          
                vItemDist  := vItemDist                ||
                              TO_CLOB(vCard)           || ';' ||  
                              TO_CLOB(vCreditLineType) || ';' ||  
                              TO_CLOB(vValue)          || ';' ||  
                              TO_CLOB(vCreditType)     || ';' ||  
                              TO_CLOB(vMerchandise)    || ';' ||  
                              TO_CLOB(vMerchQuantity)  || ';' ||  
                              TO_CLOB(vMerchPrice)     || ';' ||  
                              TO_CLOB(vAdditionalInfo) || ';' ||  
                              TO_CLOB(vExpirationDate) || ';' ||  
                              TO_CLOB(vCardBalance)    || ';' ||  
                              TO_CLOB(vRoute)          || ';' ||  
                              TO_CLOB(vKM_Quantity)    || ';' ||  -- 1.14
                              TO_CLOB(vNU_RND)         || ';' ||  -- 1.14
                              TO_CLOB(vMerchUnit);                              
                --
                -- insere a linha na interface
                --
                INSERT INTO MX_INTERFACE.TKT_CMS_1027_28_ORDER_DETAIL
                  (FILEID,
                   DOMAINID,
                   ROWNUMBER,
                   CORPORATELEVELID,
                   CUSTOMERMANAGERID,
                   CREDITTYPE,
                   OPERATIONCLASS,
                   UNITTYPE,
                   VALUE,
                   PURCHASEITEMTYPEID,
                   PURCHASEITEMQUANTITY,
                   PURCHASEUNITPRICE,
                   EXPIRATIONDATE,
                   CURRENCYID,
                   CREDITLINETYPEID,
                   CARDHOLDERID,
                   CARDID,
                   TRANSACTIONAMOUNT,
                   BALANCEACTUALDATE,
                   EFFECT,
                   RESPONSEMESSAGE,
                   RESPONSECODE,
                   CREDITOPERATIONID,
                   DEBITOPERATIONID,
                   CORPLEVELFINTRANSFERREQUESTID)
                VALUES
                  (WT_MASSIVELOAD_PKG.gFile.CD_ARQ             --FILEID,
                  ,WT_MASSIVELOAD_PKG.gFile.CD_DOM             --DOMAINID,
                  ,WT_MASSIVELOAD_PKG.gFile.NU_REG             --ROWNUMBER,
                  ,vCD_BAS                                     --CORPORATELEVELID,
                  ,vCD_GST                                     --CUSTOMERMANAGERID,
                  ,DECODE(vCreditType, 1, 'ACCUM', 'NONACCUM') --CREDITTYPE,
                  ,vOperationClass                             --OPERATIONCLASS,
                  ,DECODE(vUnitType, 2, 'LTS', NULL)           --UNITTYPE, -- 1.14
                  ,vValue                                      --VALUE,
                  ,vMerchandise                                --PURCHASEITEMTYPEID,
                  ,vMerchQuantity                              --PURCHASEITEMQUANTITY,
                  ,vMerchPrice                                 --PURCHASEUNITPRICE,
                  ,vExpirationDate                             --EXPIRATIONDATE,
                  ,vCurrency                                   --CURRENCYID,
                  ,vCreditLineType                             --CREDITLINETYPEID,
                  ,vCardHolder                                 --CARDHOLDERID,
                  ,vCard                                       --CARDID,
                  ,ABS(vValue)                                 --TRANSACTIONAMOUNT,
                  ,NULL                                        --BALANCEACTUALDATE,
                  ,NULL                                        --EFFECT,
                  ,NULL                                        --RESPONSEMESSAGE,
                  ,NULL                                        --RESPONSECODE,
                  ,NULL                                        --CREDITOPERATIONID,
                  ,NULL                                        --DEBITOPERATIONID,
                  ,NULL);                                      --CORPLEVELFINTRANSFERREQUESTID);
              END IF;
              --
              WTMX_MASSIVELOAD_PKG.vUserMessage       := NULL;
              WTMX_MASSIVELOAD_PKG.vReturnCode        := NULL;
              WTMX_MASSIVELOAD_PKG.vReturnMessage     := NULL;
              --WTMX_MASSIVELOAD_PKG.vFinancialInd      := NULL; -- 1.01
              --
              IF WT_MASSIVELOAD_PKG.gFile.TP_PRC = 'P' THEN -- 1.13
                COMMIT;
              END IF;              
            EXCEPTION
              WHEN eSkipError THEN -- 1.13
                IF WT_MASSIVELOAD_PKG.gFile.TP_PRC = 'P' THEN
                  ROLLBACK;
                END IF;
            END;
          ELSIF vTpReg = 99 THEN  -- Trailer
            --
            -- validar contador???
            NULL;
            --
          END IF;
          --
          vNU_REG:= WT_MASSIVELOAD_PKG.gFile.NU_REG;
          WT_MASSIVELOAD_PKG.gFile.NU_REG := WTMX_MASSIVELOAD_PKG.vLines.NEXT(WT_MASSIVELOAD_PKG.gFile.NU_REG);
          --
        END LOOP;
        --
      END IF;  
      --
      -- Recupera quantidade total de linhas e quantidade de linhas com erro
      SELECT COUNT(NULLIF(REG.CD_MSG_ERR, 0)), -- 1.01
             COUNT(CASE WHEN MDL.IN_TOT_REG = 'T' THEN 1 ELSE NULL END), -- 1.11 vQtdeLinDetalhe
             COUNT(CASE WHEN MDL.IN_TOT_REG = 'T' AND NVL(REG.CD_MSG_ERR,0) <> 0 THEN 1 ELSE NULL END), -- 1.11 vQtdeLinDetalheErro
             COUNT(1)
        INTO vQtdeLinErro,
             vQtdeLinDetalhe,
             vQtdeLinDetalheErro,
             vQtdeTotLin
        FROM PTC_CMS_REG      REG
        JOIN PTC_CMS_MDL_REG  MDL ON MDL.CD_MDL_REG = REG.CD_MDL_REG -- 1.11
       WHERE REG.CD_ARQ      = WT_MASSIVELOAD_PKG.gFile.CD_ARQ;
      --
      IF (WT_MASSIVELOAD_PKG.gFile.TP_PRC = 'F' AND NVL(vQtdeLinErro, 0) > 0)
      OR (WT_MASSIVELOAD_PKG.gFile.TP_PRC = 'P' AND NVL(vQtdeLinErro, 0) = NVL(vQtdeTotLin, 0))
      OR (WT_MASSIVELOAD_PKG.gFile.TP_PRC = 'P' AND NVL(vQtdeLinDetalheErro, 0) = NVL(vQtdeLinDetalhe, -1)) -- 1.11
      THEN
         --
         RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
         --
      END IF;
      --
      IF NVL(WTMX_MASSIVELOAD_PKG.vFinancialInd, 'F') = 'T' THEN
        -- Criacao do Pedido na WEM
         
        WTMX_ORDER_PKG.CreditDistribuctionCreate(PNU_PED => vNU_PED, 
                                                 PCD_USU_SOL => vCD_USU_SOL, 
                                                 PCD_BAS => vCD_BAS, 
                                                 PQT_ITE_PED => vQT_ITE_PED, 
                                                 PDT_AGD => vDt_Agd, 
                                                 PCD_TIP_LIN_CDT => vCreditLineType,
                                                 PITEMLIST => vItemDist, 
                                                 pUSER => NULL, 
                                                 pIP => 'MASSIVELOAD', 
                                                 PEXTERNALORDERNUMBER => vExtPed, 
                                                 PSUNNELORDERNUMBER => NULL,
                                                 pCD_TIP_PED => vCD_TIP_PED, 
                                                 PVL_PED_FIN_BAS => vVL_PED_FIN_BAS, 
                                                 PVL_TRF => vVL_TRF, 
                                                 PCD_CIC_APU => vCD_CIC_APU, 
                                                 PCD_TIP_ETD => vCD_TIP_ETD, 
                                                 PMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage, 
                                                 PCOD_RET => WTMX_MASSIVELOAD_PKG.vReturnCode, 
                                                 PMSG_RET => WTMX_MASSIVELOAD_PKG.vReturnMessage);
        --
        IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode,0) <> 0 THEN
          --
          WTMX_MASSIVELOAD_PKG.UpdateRelatedLines(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                  PCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                  PNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG, --NULL,
                                                  PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                  PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                                  pMSG_USER   => vUserMessageLine,
                                                  pCOD_RET    => vReturnCodeLine,
                                                  pMSG_RET    => vReturnMessageLine);
          --
          IF NVL(vReturnCodeLine,0) <> 0 THEN
            --
            RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
            --
          END IF;
          --
          RAISE WTMX_MASSIVELOAD_PKG.EProcessReturn; --1.02;
        END IF;
        --
        -- criação das linhas de interface
        BEGIN
          --  1.07
          IF TRUNC(vDt_Agd) > TRUNC(SYSDATE) THEN
            vTrue := 'F';
          ELSE
            vTrue := 'T';
          END IF;        
          --
          INSERT INTO MX_INTERFACE.TKT_CMS_1027_28_ORDER_HEADER
            (FILEID,
             DOMAINID,
             ROWNUMBER,
             CUSTOMERCONTRACTID,
             ORDERID,
             ORDERNUMBER,
             REQUESTNUMBERFINANCIALORDER,
             REQUESTNUMBERFINANCIALTRANSFER,
             SCHEDULEDATE,
             CREDITAMOUNT,
             COMMITBALANCEIND,
             CORPORATELEVELBALANCE,
             EFFECT,
             RESPONSEMESSAGE,
             RESPONSECODE)
          VALUES
            (WT_MASSIVELOAD_PKG.gFile.CD_ARQ               -- FILEID
            ,WT_MASSIVELOAD_PKG.gFile.CD_DOM               -- DOMAINID
            --,WT_MASSIVELOAD_PKG.gFile.NU_REG               -- ROWNUMBER
            ,vNU_REG
            ,vContrato                                     -- CUSTOMERCONTRACTID
            ,vNU_PED --NULL 1.08                           -- ORDERID 
            ,vExtPed                                       -- ORDERNUMBER
            ,NULL                                          -- 1.09 REQUESTNUMBERFINANCIALORDER
            ,vNU_PED                                       -- 1.09 REQUESTNUMBERFINANCIALTRANSFER
            ,vDt_Agd                                       -- SCHEDULEDATE
            ,vVL_PED_FIN_BAS                               -- CREDITAMOUNT
            ,vTrue                                         -- COMMITBALANCEIND 1.07
            ,0                                             -- CORPORATELEVELBALANCE
            ,NULL                                          -- EFFECT
            ,NULL                                          -- RESPONSEMESSAGE
            ,NULL);                                        -- RESPONSECODE
          --
        EXCEPTION
          --
          WHEN OTHERS THEN
            --
            WTMX_MASSIVELOAD_PKG.vReturnCode := 182190; 
            WTMX_MASSIVELOAD_PKG.vReturnMessage := sqlerrm;
            WTMX_MASSIVELOAD_PKG.vReturnMessage := WTMX_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode);
            --
            WTMX_MASSIVELOAD_PKG.UpdateRelatedLines(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                    PCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                    PNU_REG     => NULL,
                                                    PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                    PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                                    pMSG_USER   => vUserMessageLine,
                                                    pCOD_RET    => vReturnCodeLine,
                                                    pMSG_RET    => vReturnMessageLine);
            --
            IF NVL(vReturnCodeLine,0) <> 0 THEN
              --
              RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
              --
            END IF;
            --
            RAISE WTMX_MASSIVELOAD_PKG.EProcessReturn; -- 1.02;
        END;
        --
        WTMX_MASSIVELOAD_PKG.MassiveLoadOrderCreate(PCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ, 
                                                    PCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM, 
                                                    PNU_PED   => vNU_PED, 
                                                    PMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage, 
                                                    PCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode, 
                                                    PMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
        --
        IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
          --
          WTMX_MASSIVELOAD_PKG.UpdateRelatedLines(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                  PCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                  PNU_REG     => NULL,
                                                  PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                  PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                                  pMSG_USER   => vUserMessageLine,
                                                  pCOD_RET    => vReturnCodeLine,
                                                  pMSG_RET    => vReturnMessageLine);
          --
          IF NVL(vReturnCodeLine,0) <> 0 THEN
            --
            RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
            --
          END IF;
          --
          RAISE WTMX_MASSIVELOAD_PKG.EProcessReturn; -- 1.02;
        END IF;
      --
      END IF;
      --
    END IF;
    --
    -- Se o processamento envolver Greentech, atualiza status para processamento das interfaces necessarias
    IF WTMX_MASSIVELOAD_PKG.vFinancialInd = 'T' THEN
      --
      -- Atualiza o status do Dominio do Arquivo para "Aguardando Envio Financeiro"
      WTMX_MASSIVELOAD_PKG.MassiveLoadFileDomainUpdStatus(pCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                          pCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                          pDT_INI_PRC => NULL,
                                                          pDT_FIM_PRC => NULL,
                                                          pCD_STA_CMM => 78,          -- 78 = Processando Financeiro
                                                          pMSG_USER   => WTMX_MASSIVELOAD_PKG.vUserMessage, 
                                                          pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode, 
                                                          pMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
        -- Se o processo de update deu erro, forca o retorno do erro
        RAISE WTMX_MASSIVELOAD_PKG.EProcessReturn;
        --
      END IF;
      --
    ELSE
      --
      -- Atualiza o status do Dominio do Arquivo para "Nada a processar"
      WTMX_MASSIVELOAD_PKG.MassiveLoadFileDomainUpdStatus(pCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                          pCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                          pDT_INI_PRC => NULL,
                                                          pDT_FIM_PRC => SYSDATE,
                                                          pCD_STA_CMM => 86, -- 86 - Nada a Processar
                                                          pMSG_USER   => WTMX_MASSIVELOAD_PKG.vUserMessage, 
                                                          pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode, 
                                                          pMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage);      
      --
      WTMX_MASSIVELOAD_PKG.MassiveLoadFinish(PCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                             PCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                             pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage, 
                                             pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode, 
                                             pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
    END IF;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN WTMX_MASSIVELOAD_PKG.EProcessReturn THEN
      --
      ROLLBACK;        -- Desfaz eventuais alterac?es ja efetuadas
      --
      -- Executa a proc para a gerac?o do arquivo de retorno    --
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
      ROLLBACK;        -- Desfaz eventuais alterac?es ja efetuadas
      --
      WTMX_MASSIVELOAD_PKG.vFinancialInd  := 'F';  -- Para n?o executar o Sunnel
      vExceptionType := 'EProcessError';
      -- Executa a proc para a gerac?o do arquivo de retorno    --
      WTMX_MASSIVELOAD_PKG.MassiveLoadGenerateRespFile(pCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                       pCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                       pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                       pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                       pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      RAISE;
      --
    WHEN OTHERS THEN
      --
      ROLLBACK;        -- Desfaz eventuais alterac?es ja efetuadas
      --
      
      -- 1.02
      WTMX_MASSIVELOAD_PKG.UpdateRelatedLines(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                              PCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                              PNU_REG     => NULL,
                                              PCD_MSG_ERR => 182190 ,
                                              PDS_MSG_ERR => sqlerrm,
                                              pMSG_USER   => vUserMessageLine,
                                              pCOD_RET    => vReturnCodeLine,
                                              pMSG_RET    => vReturnMessageLine);
      --

      -- Executa a proc para a gerac?o do arquivo de retorno    --
      WTMX_MASSIVELOAD_PKG.MassiveLoadGenerateRespFile(pCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                       pCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                       pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                       pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                       pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --         
      WTMX_MASSIVELOAD_PKG.vFinancialInd := 'F';  -- Para n?o executar o Sunnel
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      RAISE;
      --
  END CreditDistributionExecute;
  --

  ----------------------------------------------------------------------------------
  -- Procedure Especialista - Distribuicao de Credito - Processamento Parcial - 1.13
  ----------------------------------------------------------------------------------
  PROCEDURE CreditDistributionParcial IS
    --
    vInterfaceHeader  MX_INTERFACE.TKT_CMS_1027_28_ORDER_HEADER%ROWTYPE;
    vInterfaceDetail  MX_INTERFACE.TKT_CMS_1027_28_ORDER_DETAIL%ROWTYPE;
    vStatus           PTC_STA_CMM.CD_STA_CMM%TYPE;
    vReturnTip        VARCHAR2(10);   
    vNU_PED           PTC_PED.NU_PED%TYPE;
    --
    vResponseCode     NUMBER;
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'CreditDistributionParcial');
    --
    -- tratamento erro GTech 1.21 (inicio)
    IF WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'V' THEN
      SAVEPOINT spPARTIAL;
    END IF;  
    -- tratamento erro GTech 1.21 (fim)
    --
    WTMX_MASSIVELOAD_PKG.vFinancialInd  := 'T';
    --
    vReturnCodeLine    := 0;
    vReturnMessageLine := NULL;
    --
    SELECT AD.CD_STA_CMM
      INTO vStatus
      FROM PTC_CMS_ARQ_DOM  AD
     WHERE AD.CD_ARQ = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
       AND AD.CD_DOM = WT_MASSIVELOAD_PKG.gFile.CD_DOM;
    --
    BEGIN
      --
      SELECT *
        INTO vInterfaceHeader
        FROM MX_INTERFACE.TKT_CMS_1027_28_ORDER_HEADER
       WHERE FILEID = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
         AND DOMAINID = WT_MASSIVELOAD_PKG.gFile.CD_DOM;
      --
      SELECT *
        INTO vInterfaceDetail
        FROM MX_INTERFACE.TKT_CMS_1027_28_ORDER_DETAIL
       WHERE FILEID = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
         AND DOMAINID = WT_MASSIVELOAD_PKG.gFile.CD_DOM
         AND ROWNUMBER = WT_MASSIVELOAD_PKG.gFile.NU_REG;

      --
    EXCEPTION
      --
      WHEN NO_DATA_FOUND THEN
        --
        RAISE WTMX_MASSIVELOAD_PKG.EProcessReturn;
        --
    END;
    --
    IF vStatus = 78 THEN -- 78 = PROCESSANDO FINANCEIRO
      BEGIN
        vResponseCode:= TO_NUMBER(vInterfaceDetail.ResponseCode);
      EXCEPTION
        WHEN OTHERS THEN
          vResponseCode:= 9999;  
      END;
      --
      -- Verifica se as colunas EFFECT estao preenchidas
      WTMX_MASSIVELOAD_PKG.ValidateSunnelReturn(pEFFECT          => vInterfaceDetail.EFFECT,
                                                pResponseCode    => vResponseCode, -- 1.16 vInterfaceDetail.ResponseCode,
                                                pResponseMessage => vInterfaceDetail.ResponseMessage,
                                                pCOD_RET         => vReturnCodeLine,
                                                pMSG_RET         => vReturnMessageLine,
                                                pTIP_RET         => vReturnTip);
      IF NVL(vReturnCodeLine,0) <> 0 THEN
        --
        WTMX_MASSIVELOAD_PKG.UpdateRelatedLines(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                PCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                PNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                                                PCD_MSG_ERR => vReturnCodeLine,
                                                PDS_MSG_ERR => WT_UTILITY_PKG.GetMessage(vReturnCodeLine),
                                                pMSG_USER   => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                                pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                pMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage);
        --
        IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
          --
          RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
          --
        END IF;
        --

        IF vReturnTip <> 'NORMAL' THEN
          RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
        END IF;
      END IF;  
      --
    END IF;
    --
    IF WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'A' THEN
      --
      vNU_PED := vInterfaceHeader.RequestNumberFinancialTransfer;
      --
      IF NVL(vInterfaceDetail.EFFECT,'R') = 'P' THEN -- 1.16
         WTMX_ORDER_PKG.AutonomousCardFinOrdUpdtStatus(pNU_PED              => vNU_PED,
                                                        pNU_CAT             => vInterfaceDetail.CardID,
                                                        pCD_STA_ITE_PED_DET => 2, -- 2=Processado com Sucesso
                                                        pDS_MSG_PRC         => NULL,
                                                        pMSG_USER           => WT_MASSIVELOAD_PKG.gProcessInfo.UserMessage,
                                                        pCOD_RET            => WT_MASSIVELOAD_PKG.gProcessInfo.ReturnCode,
                                                        pMSG_RET            => WT_MASSIVELOAD_PKG.gProcessInfo.ReturnMessage);
        --
        IF NVL(vReturnCodeLine, 0) <> 0 THEN
          WTMX_MASSIVELOAD_PKG.UpdateRelatedLines(pCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                  pCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                  pNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                                                  pCD_MSG_ERR => nvl(vReturnCodeLine,9999), 
                                                  pDS_MSG_ERR => vReturnMessageLine,
                                                  pMSG_USER   => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                                  pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                  pMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage);
          --
          IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
            --
            RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
            --
          END IF;
          --
          RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
        END IF;
        
      ELSE -- 1.16
        --
        WTMX_ORDER_PKG.AutonomousCardFinOrdUpdtStatus(pNU_PED             => vNU_PED,
                                                      pNU_CAT             => vInterfaceDetail.CardID,
                                                      pCD_STA_ITE_PED_DET => 3, -- 3=Processado com Erro
                                                      pDS_MSG_PRC         => vInterfaceDetail.Operationclass||' - '||NVL(vInterfaceDetail.Responsemessage, 'Sunnel error'),
                                                      pMSG_USER           => vUserMessageLine,
                                                      pCOD_RET            => vReturnCodeLine,
                                                      pMSG_RET            => vReturnMessageLine);
        --
        IF NVL(vReturnCodeLine, 0) <> 0 THEN
          WTMX_MASSIVELOAD_PKG.UpdateRelatedLines(pCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                  pCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                  pNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                                                  pCD_MSG_ERR => NVL(vReturnCodeLine,9999), 
                                                  pDS_MSG_ERR => vReturnMessageLine,
                                                  pMSG_USER   => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                                  pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                  pMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage);
          --
          IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
            --
            RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
            --
          END IF;
          --
          RAISE WTMX_MASSIVELOAD_PKG.EProcessError;     
        END IF; 
        --
      END IF;  
    END IF;  
    --

    -- tratamento erro GTech 1.21 (inicio)
    IF WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'V' THEN
      ROLLBACK TO spPARTIAL;
    END IF;  
    -- tratamento erro GTech 1.21 (fim)
        
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    --
    WHEN WTMX_MASSIVELOAD_PKG.EProcessError THEN
      -- tratamento erro GTech 1.21 (inicio)
      IF WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'V' THEN
        ROLLBACK TO spPARTIAL;
      END IF;  
      -- tratamento erro GTech 1.21 (fim)      
      --
      WT_MASSIVELOAD_PKG.gProcessInfo.ExceptionType := 'EProcessError';
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      RAISE;
      --
    WHEN WTMX_MASSIVELOAD_PKG.EProcessReturn THEN
      -- tratamento erro GTech 1.21 (inicio)
      IF WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'V' THEN
        ROLLBACK TO spPARTIAL;
      END IF;  
      -- tratamento erro GTech 1.21 (fim)    
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      RETURN;
      --
    WHEN OTHERS THEN
      -- tratamento erro GTech 1.21 (inicio)
      IF WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'V' THEN
        ROLLBACK TO spPARTIAL;
      END IF;  
      -- tratamento erro GTech 1.21 (fim)    
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      RAISE;
      --
  END CreditDistributionParcial;
  --

  -------------------------------------------------------------------
  -- Procedure de Finalizacao Especialista - Distribuicao de Credito
  -------------------------------------------------------------------
  PROCEDURE CreditDistributionFinish(PCOD_RET OUT NUMBER) IS
    --
    vStatus PTC_CMS_ARQ_DOM.CD_STA_CMM%TYPE;
    vQtdeLinErro          NUMBER;
    --
    vTIP_RET           varchar2(30);
    --
    v_CD_STA_PED           PTC_PED.CD_STA_PED%TYPE;           
    v_CD_STA_ITE_PED       PTC_ITE_PED.CD_STA_TIP_ITM_PED%TYPE;
    v_NU_PED_SNN           PTC_ITE_PED.NU_PED_SNN%TYPE  := NULL;  -- 1.25
    --
    vTrack VARCHAR2(500);
    --
    PROCEDURE Cancela_Pedido IS
      BEGIN
        vTrack:= 'cancelar pedido';
        IF WT_MASSIVELOAD_PKG.gFile.NU_PED IS NOT NULL AND WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'A' THEN
          --
          WTMX_ORDER_PKG.AutonomousCredDistribCancel(pNU_PED     => WT_MASSIVELOAD_PKG.gFile.NU_PED,
                                                     pCD_USU_SOL => WT_MASSIVELOAD_PKG.gFile.CD_USU,
                                                     PMSG_USER   => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                     PCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                     PMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage);
          --
          IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
            WTMX_MASSIVELOAD_PKG.UpdateRelatedLines(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                  PCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                  PNU_REG     => NULL,
                                                  PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                  PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                                  pMSG_USER   => vUserMessageLine,
                                                  pCOD_RET    => vReturnCodeLine,
                                                  pMSG_RET    => vReturnMessageLine);
            --
            IF NVL(vReturnCodeLine, 0) <> 0 THEN
              --
              PCOD_RET:= vReturnCodeLine;
              ProcessError(PCOD_RET, 'CreditDistributionFinish. Erro ao '||vTrack, TRUE);
              --
            END IF;          
          END IF;  
          --
        END IF;       
      END;
  BEGIN
    -- 1.19 Proc reformulada
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'CreditDistributionFinish');
    --
    -- Efetuar as leituras de status antes de seguir processamento
    SELECT AD.CD_STA_CMM
      INTO vStatus
      FROM PTC_CMS_ARQ_DOM AD
     WHERE AD.CD_ARQ = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
       AND AD.CD_DOM = WT_MASSIVELOAD_PKG.gFile.CD_DOM;
    --
    IF vStatus = 78 THEN
      --
      -- Se o processamento envolveu Greentech,
      -- ler os status de processamento das tabelas de interface
      -- e atualiza na tabela de Registro de Carga Massiva (PTC_CMS_REG)
      vTrack:= 'validar resposta Sunnel';
      FOR R1 IN (SELECT HDR.REQUESTNUMBERFINANCIALORDER,
                        DTL.CUSTOMERMANAGERID,
                        DECODE(HDR.EFFECT, 'R', NULL, DTL.ROWNUMBER) ROWNUMBER,    --1.20
                        DTL.CardID,
                        HDR.EFFECT          EFFECT_HDR,
                        DTL.EFFECT          EFFECT_DTL,
                        HDR.RESPONSECODE    RESPONSECODE_HDR,
                        DTL.RESPONSECODE    RESPONSECODE_DTL,
                        HDR.RESPONSEMESSAGE RESPONSEMESSAGE_HDR,
                        DTL.RESPONSEMESSAGE RESPONSEMESSAGE_DTL
                   FROM MX_INTERFACE.TKT_CMS_1027_28_ORDER_HEADER    HDR,
                        MX_INTERFACE.TKT_CMS_1027_28_ORDER_DETAIL    DTL
                  WHERE HDR.FILEID   = DTL.FILEID
                    AND HDR.DOMAINID = DTL.DOMAINID
                    AND HDR.FILEID   = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
                    AND HDR.DOMAINID = WT_MASSIVELOAD_PKG.gFile.CD_DOM
                    AND (DTL.EFFECT = 'R' OR HDR.EFFECT = 'R')                     --1.20
                  ORDER BY DTL.EFFECT) LOOP        
        -- Verifica as colunas EFFECT do detalhe
        WTMX_MASSIVELOAD_PKG.ValidateSunnelReturn(pEFFECT => R1.EFFECT_DTL,
                              pRESPONSECODE      => NVL(WTMX_UTILITY_PKG.GetSunnelError(R1.RESPONSEMESSAGE_DTL ,18),9999),
                              pRESPONSEMESSAGE   => R1.RESPONSEMESSAGE_DTL,
                              pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode,
                              pMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                              pTIP_RET    => vTIP_RET);
        -- Verifica as colunas EFFECT do header 
        --1.20
        IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode,0) = 0 THEN
           WTMX_MASSIVELOAD_PKG.ValidateSunnelReturn(pEFFECT => R1.EFFECT_HDR,
                              pRESPONSECODE      => NVL(WTMX_UTILITY_PKG.GetSunnelError(R1.RESPONSEMESSAGE_HDR ,18),9999),
                              pRESPONSEMESSAGE   => R1.RESPONSEMESSAGE_HDR,
                              pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode,
                              pMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                              pTIP_RET    => vTIP_RET);
        END IF;
        --1.20
        IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode,0) <> 0 THEN
          IF NVL(vTIP_RET, 'NORMAL') <> 'NORMAL' THEN
            PCOD_RET:= WTMX_MASSIVELOAD_PKG.vReturnCode;
            ProcessError(PCOD_RET, 'CreditDistributionFinish. Erro ao '||vTrack);
          END IF;           
          --
          WTMX_MASSIVELOAD_PKG.UpdateRelatedLines(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                  PCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                  PNU_REG     => R1.ROWNUMBER,
                                                  PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                  PDS_MSG_ERR => WTMX_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode),
                                                  pMSG_USER   => vUserMessageLine,
                                                  pCOD_RET    => vReturnCodeLine,
                                                  pMSG_RET    => vReturnMessageLine);
          --
          IF NVL(vReturnCodeLine, 0) <> 0 THEN
            --
            PCOD_RET:= vReturnCodeLine;
            ProcessError(PCOD_RET, 'CreditDistributionFinish. Erro ao '||vTrack, TRUE);
            --
          END IF;
          --
        END IF; 
        --
      END LOOP;
      --
      IF NVL(PCOD_RET,0) <> 0 THEN
        --
        ProcessError(PCOD_RET, 'CreditDistributionFinish. Erro ao '||vTrack, TRUE);
        --
      END IF;
      --
    END IF;
    --
    -- inicio 1.16
    IF WT_MASSIVELOAD_PKG.gFile.TP_PRC = 'F' THEN 
      vTrack:= 'ler registros do dominio em processamento';
      --
      -- Atualiza o status do Domínio do Arquivo para "Processando WEM"
      WTMX_MASSIVELOAD_PKG.MassiveLoadFileDomainUpdStatus(pCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                          pCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                          pDT_INI_PRC => SYSDATE,
                                                          pDT_FIM_PRC => NULL,
                                                          pCD_STA_CMM => 77, -- Processando WEM
                                                          pMSG_USER   => vUserMessageLine,
                                                          pCOD_RET    => vReturnCodeLine,
                                                          pMSG_RET    => vReturnMessageLine);
      --
      IF NVL(vReturnCodeLine, 0) <> 0 THEN
        --
        PCOD_RET:= vReturnCodeLine;
        ProcessError(PCOD_RET, 'CreditDistributionFinish. Erro ao '||vTrack, TRUE);
        --
      END IF;

      --
      -- Efetua a leitura dos registros do dominio em processamento
      WTMX_MASSIVELOAD_PKG.GetDomainLines(PCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                          PCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                          PData     => WT_MASSIVELOAD_PKG.gLines,
                                          PType     => WT_MASSIVELOAD_PKG.gTypes,
                                          pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                          pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                          pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode,0) <> 0 THEN
        --
        PCOD_RET:= WTMX_MASSIVELOAD_PKG.vReturnCode;
        ProcessError(PCOD_RET, 'CreditDistributionFinish. Erro ao '||vTrack, TRUE);
        --
      END IF;
      --
      IF WT_MASSIVELOAD_PKG.gLines.COUNT > 0 THEN
        --
        WT_MASSIVELOAD_PKG.gFile.NU_REG := WT_MASSIVELOAD_PKG.gLines.FIRST;
        --
        WHILE WT_MASSIVELOAD_PKG.gFile.NU_REG IS NOT NULL LOOP
          IF WTMX_MASSIVELOAD_PKG.GetContent('TipoRegistro', WT_MASSIVELOAD_PKG.gLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)) = 3 THEN
            --
            vTrack:= 'processar linha';
            WTMX_MASSIVELOAD_PKG.MassiveLoadPartial(PCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                    PCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                    PNU_REG   => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                                                    pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                    pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                    pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
          END IF;
          --
          WT_MASSIVELOAD_PKG.gFile.NU_REG := WT_MASSIVELOAD_PKG.gLines.NEXT(WT_MASSIVELOAD_PKG.gFile.NU_REG);
          --
        END LOOP;
        --
      END IF;
      --
    END IF;
        
    --
    -- Recupera quantidade total de linhas e quantidade de linhas com erro
    -- 
    vTrack:= 'atualizar status do pedido';
    vStatus:= WTMX_MASSIVELOAD_PKG.GetFileEndProcStatus(WT_MASSIVELOAD_PKG.gFile.CD_ARQ);
    --
    IF vStatus = 80 THEN
      --
      Cancela_Pedido;
      --
    ELSIF vStatus IN (79, 81) THEN
      -- Confirma Pedido
      IF WT_MASSIVELOAD_PKG.gFile.NU_PED IS NULL THEN  
        --
        PCOD_RET:= 9999;
        ProcessError(PCOD_RET, 'CreditDistributionFinish. Erro ao '||vTrack, TRUE);
        --
      END IF;
      -- 
      -- Atualizar Status Pedido     
      SELECT COUNT(1)
      INTO vQtdeLinErro         
      FROM PTC_PED_FIN_CAT
      WHERE NU_PED = WT_MASSIVELOAD_PKG.gFile.NU_PED
        AND nvl(CD_STA_ITE_PED_DET, 3) = 3; -- ERRO
        
      IF NVL(vQtdeLinErro, 0) > 0 THEN
        v_CD_STA_PED     :=  9;  -- Finalizado Parcialmente
        v_CD_STA_ITE_PED := 101; -- Processado Parcialmente
      ELSE
        v_CD_STA_PED     := 4;   -- Finalizado com Sucesso
        v_CD_STA_ITE_PED := 100; -- Finalizado com Sucesso
      END IF; 
      
      WTMX_ORDER_PKG.AutonomousCredDistUpdateStatus(    pNU_PED         => WT_MASSIVELOAD_PKG.gFile.NU_PED,
                                                        pCD_STA_PED     => v_CD_STA_PED,
                                                        pCD_STA_ITE_PED => v_CD_STA_ITE_PED,
                                                        pMSG_USER       => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                        pCOD_RET        => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                        pMSG_RET        => WTMX_MASSIVELOAD_PKG.vReturnMessage);
                                                        
      IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode,0) <> 0 THEN
         WTMX_MASSIVELOAD_PKG.UpdateLine(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                         PNU_REG     => NULL,
                                         PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                         PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                         pMSG_USER   => vUserMessageLine,
                                         pCOD_RET    => vReturnCodeLine,
                                         pMSG_RET    => vReturnMessageLine); 
         PCOD_RET:= vReturnCodeLine;    
         ProcessError(PCOD_RET, 'CreditDistributionFinish. Erro ao '||vTrack, TRUE);                                   
      END IF;   
      -- 1.25 Atualiza o no. pedido Sunnel - Inicio
      BEGIN
        vTrack := 'Atualizar o no. pedido Sunnel';
        --
        SELECT TRIM(DBMS_LOB.substr(CORPLEVELFINTRANSFERREQUESTID))
          INTO v_NU_PED_SNN
          FROM MX_INTERFACE.TKT_CMS_1027_28_ORDER_DETAIL DTL
         WHERE DTL.FILEID     = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
           AND DTL.DOMAINID   = WT_MASSIVELOAD_PKG.gFile.CD_DOM
           AND DTL.EFFECT     = 'P'
           AND DTL.CORPLEVELFINTRANSFERREQUESTID IS NOT NULL 
           AND ROWNUM         = 1;
        --
        -- Atualiza 
        UPDATE PTC_ITE_PED PED
           SET PED.NU_PED_SNN = v_NU_PED_SNN
         WHERE NU_PED         = WT_MASSIVELOAD_PKG.gFile.NU_PED
           AND CD_TIP_PED     IN (2, 11, 12); 

      --
      EXCEPTION
      --
      WHEN OTHERS THEN
        --       
        ProcessError(PCOD_RET, 'CreditDistributionFinish. Erro ao '||vTrack);
        --
      END;
      -- 1.25 Fim
    END IF;                                         
    -- fim 1.16
    PCOD_RET:= 0; -- sem exceções
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
      WTMX_MASSIVELOAD_PKG.vExceptionType := 'EProcessError';
      --
      Cancela_Pedido;
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
    WHEN OTHERS THEN
      -- 1.05
      ProcessError(SQLCODE, 'CreditDistributionFinish. WHEN OTHERS', FALSE);
      WTMX_MASSIVELOAD_PKG.UpdateRelatedLines(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                              PCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                              PNU_REG     => NULL,
                                              PCD_MSG_ERR => 9999,
                                              PDS_MSG_ERR => SQLERRM,
                                              pMSG_USER   => vUserMessageLine,
                                              pCOD_RET    => vReturnCodeLine,
                                              pMSG_RET    => vReturnMessageLine);
      --
      Cancela_Pedido;
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      RAISE;
      --
  END CreditDistributionFinish;
  --
  ----------------------------------------------------------------------
  -- Procedure de Resposta Especialista - Distribuicao de Credito
  ----------------------------------------------------------------------
  PROCEDURE CreditDistributionResponse(pCD_ARQ      IN PTC_CMS_ARQ_DOM.CD_ARQ%TYPE,
                                       pCD_DOM      IN PTC_CMS_ARQ_DOM.CD_DOM%TYPE,
                                       pNM_ARQ     OUT PTC_CMS_ARQ.NM_ARQ%TYPE,
                                       pResponse   OUT WTMX_MASSIVELOAD_PKG.TResponseList,
                                       pMSG_USER   OUT NOCOPY VARCHAR2,
                                       pCOD_RET    OUT NOCOPY NUMBER,
                                       pMSG_RET    OUT NOCOPY VARCHAR2) IS
    --                          
    vOperacao       VARCHAR2(10);
    vNomeArquivo    PTC_CMS_ARQ.NM_ARQ%TYPE;
    vStatus         PTC_CMS_ARQ.CD_STA_CMM%TYPE;
    vTpReg          NUMBER(2);
    vInd            BINARY_INTEGER  := 0;
    vNU_PED         PTC_PED_CAT.NU_PED%TYPE;
    vRiskConditionReasonCodeId T_GCARD.RISKCONDITIONREASONCODEID%TYPE; -- 1.24
    vCard                 VARCHAR2(20); -- 1.22
    vTagNfcNum            VARCHAR2(20); -- 1.22
    vTagNfcId             VARCHAR2(20); -- 1.22    
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'CreditDistributionResponse');
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
    -- Popula os dados do arquivo em execuc?o
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
    IF NVL(pCOD_RET,0) <> 0 THEN
      --
      RETURN;
      --
    END IF;
    --
    
    -- Numero do Pedido Gerado
    BEGIN
      SELECT REQUESTNUMBERFINANCIALTRANSFER -- 1.09 REQUESTNUMBERFINANCIALORDER
        INTO vNU_PED
        FROM MX_INTERFACE.TKT_CMS_1027_28_ORDER_HEADER
       WHERE FILEID = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
         AND DOMAINID = WT_MASSIVELOAD_PKG.gFile.CD_DOM;
    EXCEPTION
      WHEN OTHERS THEN
        vNU_PED := NULL;
    END;
        
    -- Tratamento para as linhas retornadas da validac?o 
    IF WTMX_MASSIVELOAD_PKG.vLines.COUNT > 0 THEN
      --
      WT_MASSIVELOAD_PKG.gFile.NU_REG := WTMX_MASSIVELOAD_PKG.vLines.FIRST;
      --
      WHILE WT_MASSIVELOAD_PKG.gFile.NU_REG IS NOT NULL LOOP
        --
        BEGIN
          --
          vInd  := vInd + 1;
          vTpReg := WTMX_MASSIVELOAD_PKG.GetContent('TipoRegistro', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          --
          IF vTpReg = 0 THEN  -- Header
            --  
            vNomeArquivo    := REPLACE(vNomeArquivo, '1027017I', '1027017O');
            vNomeArquivo    := SUBSTR(vNomeArquivo,  1, 24) || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') || '.TXT';
            pNM_ARQ         := vNomeArquivo;
            --                 
            pResponse(vInd) := '00' || 
                               LPAD(WTMX_MASSIVELOAD_PKG.GetContent('NroLinha', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  7, '0') ||
                               LPAD(WTMX_MASSIVELOAD_PKG.GetContent('NroRemessa', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 10, '0') ||
                               TO_CHAR(SYSDATE, 'DDMMYYYYHH24MISS')                                             ||
                               RPAD('INT1027.17 - RETORNO DISPERSION DE CREDITOS', 50, ' ')                 ||
                               RPAD(vOperacao, 10, ' ') ||
                               SUBSTR(LPAD(WTMX_MASSIVELOAD_PKG.GetContent('CodErroReg', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  6, '0'), 3, 4);
            --
          ELSIF vTpReg = 1 THEN  -- Gestor
            --
            pResponse(vInd) := '01' || 
                               LPAD(WTMX_MASSIVELOAD_PKG.GetContent('NroLinha', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  7, '0') ||
                               LPAD(WTMX_MASSIVELOAD_PKG.GetContent('Manager', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 12, '0') ||
                               LPAD(WTMX_MASSIVELOAD_PKG.GetContent('Base', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 12, '0') ||
                               SUBSTR(LPAD(WTMX_MASSIVELOAD_PKG.GetContent('CodErroReg', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  6, '0'), 3, 4);
             --
           ELSIF vTpReg = 2 THEN  -- Order Header
             --
             pResponse(vInd) := '02' || 
                                LPAD(WTMX_MASSIVELOAD_PKG.GetContent('NroLinha', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  7, '0') ||
                                LPAD(NVL(WTMX_MASSIVELOAD_PKG.GetContent('NroPedido', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),0), 12, '0') ||
                                LPAD(NVL(vNU_PED/*WT_MASSIVELOAD_PKG.gFile.NU_PED*/,0), 12, '0') ||
                                SUBSTR(LPAD(WTMX_MASSIVELOAD_PKG.GetContent('CodErroReg', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  6, '0'), 3, 4);
             --
           ELSIF vTpReg = 3 THEN  -- Order Detail
             --
             -- 1.22 inicio
             --
             vCard      := WTMX_MASSIVELOAD_PKG.GetContent('NroCartao', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
             vTagNfcNum := WTMX_MASSIVELOAD_PKG.GetContent('TagNfcNum', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));  -- 1.22
             vTagNfcId  := WTMX_MASSIVELOAD_PKG.GetContent('TagNfcId', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)); -- 1.22
             -- Se CARD_NUMBER não for informado, obter o cartão ativo a partir dos novos campos 
             -- (TAG_NUMERICA ou TAG_HEXADECIMAL)
             --
             IF vCard IS NULL THEN
               -- 1.25 
               IF vTagNfcId IS NOT NULL THEN   -- TAG Hexadecimal             
                --
                SELECT MAX(C.NU_CAT)
                INTO vCard
                FROM PTC_DAD_VEI_EQP D, PTC_VEI_EQP V, PTC_CAT C, T_GCURRENTCARD CC
                WHERE D.ID_TAG_NFC = vTagNfcId
                  AND V.CD_VEI_EQP = D.CD_VEI_EQP
                  AND C.CD_PTD     = V.CD_PTD
                  AND CC.CARDID = C.NU_CAT;
                --
               ELSIF vTagNfcNum IS NOT NULL THEN   -- TAG Numerica
                --
                SELECT MAX(C.NU_CAT)
                INTO vCard
                FROM PTC_DAD_VEI_EQP D, PTC_VEI_EQP V, PTC_CAT C, T_GCURRENTCARD CC
                WHERE vTagNfcNum   = D.NU_TAG_NFC
                  AND V.CD_VEI_EQP = D.CD_VEI_EQP
                  AND C.CD_PTD     = V.CD_PTD
                  AND CC.CARDID    = C.NU_CAT;
                --
               END IF;
             END IF;   
             -- 1.22 fim
             
             
             -- 1.24 inicio
             SELECT max(C.RISKCONDITIONREASONCODEID)
             INTO vRiskConditionReasonCodeId
             FROM T_GCARD C
             WHERE CARDID = vCard;
             -- 1.24 fim   

             pResponse(vInd) := '03' || 
                                LPAD(WTMX_MASSIVELOAD_PKG.GetContent('NroLinha', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),      7, '0') ||
                                LPAD(NVL(WTMX_MASSIVELOAD_PKG.GetContent('NroPedido',WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 0), 12, '0') ||
                                LPAD(nvl(vCard,'0'),     19, '0') || -- 1.22
                                LPAD(NVL(vNU_PED/*WT_MASSIVELOAD_PKG.gFile.NU_PED*/,0), 12, '0') ||
                                LPAD(NVL(vRiskConditionReasonCodeId, '0'), 2, '0')               || -- 1.24
                                SUBSTR(LPAD(WTMX_MASSIVELOAD_PKG.GetContent('CodErroReg', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 6, '0'), 3, 4);
                                --RPAD(NVL(SUBSTR(LPAD(WTMX_MASSIVELOAD_PKG.GetContent('CodErroReg', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 6, '0'), 3, 4),' '), 50, ' ') || -- 1.23

             --                                    
            ELSIF vTpReg = 99 THEN  -- Trailer
              --
              pResponse(vInd) := '99' || 
                                 LPAD(WTMX_MASSIVELOAD_PKG.GetContent('NroLinha', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),   7, '0') ||
                                 LPAD(WTMX_MASSIVELOAD_PKG.GetContent('NroRemessa', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  10, '0') ||
                                 TO_CHAR(WTMX_MASSIVELOAD_PKG.GetContentDate('DataRemessa', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),'DDMMYYYYHH24MISS') ||
                                 LPAD(WTMX_MASSIVELOAD_PKG.GetContent('QtdeRegistros', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  15, '0') ||
                                 SUBSTR(LPAD(WTMX_MASSIVELOAD_PKG.GetContent('CodErroReg', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  6, '0'), 3, 4);
              --
           END IF;
          --           
        END;
        --
        WT_MASSIVELOAD_PKG.gFile.NU_REG := WTMX_MASSIVELOAD_PKG.vLines.NEXT(WT_MASSIVELOAD_PKG.gFile.NU_REG);
        --
      END LOOP;     -- Loop vLines
      --
    END IF;
    --
  END CreditDistributionResponse;
  --
  ----------------------------------------------------
  -- Procedure Especialista - Pedido de Cartao
  ----------------------------------------------------
  PROCEDURE CardRequisitionExecute IS
    --
    vQtde                      NUMBER;
    vQtdeTotLin                NUMBER;
    vErro                      NUMBER;
    vTpReg                     NUMBER(2);
    vCD_GST                    PTC_GST.CD_GST%TYPE;
    vCD_BAS                    PTC_BAS.CD_BAS%TYPE;
    vCD_GST_RET                PTC_GST.CD_GST%TYPE;                
    vCD_CSL                    PTC_CSL.CD_CSL%TYPE;                
    vCD_TIP_GST                PTC_GST.CD_TIP_GST%TYPE;   
    vContrato                  PTC_CTR_CLI.CD_CTR_CLI%TYPE;
    vExtPed                    PTC_PED.NU_PED_EXT%TYPE;
    vDtPed                     PTC_PED.DT_PED%TYPE;
    vObs                       PTC_PED.DC_OBS%TYPE;
    vManagerUser               PTC_PED.CD_USU_SOL%TYPE;
    vInputList                 CLOB;
    vEntity                    PTC_ETD.CD_ETD%TYPE;
    vEntityType                PTC_ETD.CD_TIP_ETD%TYPE;
    vDeliverinUnitID           PTC_UND_ETG.CD_UND_ETG%TYPE;
    vListaUE                   TUnidadeEntrega;
    vListaEntidade             TEntidade;
    vProductCreditLineTypeID   PTC_TIP_LIN_SNN.CD_TIP_LIN_CDT%TYPE;
    vExpensesBudgetAmount      NUMBER;
    vCardGroupID               PTC_CAT.CD_GPO_CAT%TYPE;
    vCreditDistrGroupIdent     PTC_GPO_DST_CRD.CD_GPO_DST_CRD%TYPE;
    vCreditDistrGroupValue     PTC_GPO_DST_CRD_PTD.VL_DST%TYPE;
    vCreditDistrGrValueTypeId  PTC_GPO_DST_CRD_PTD.CD_NAT_DST%TYPE; 
    vMerchandiseIdentification PTC_GPO_DST_CRD_PTD.CD_MRD%TYPE;
    vMerchandiseQuantity       PTC_GPO_DST_CRD_PTD.QT_MRD%TYPE;
    vCardTechnologyType        PTC_TIP_TCN_CAT.CD_TIP_TCN_CAT%TYPE;
    vValueTypeIdentification   VARCHAR2(10);
    vIdentificationNumber      PTC_ETD.VL_ETD%TYPE;
    vIdentificationType        PTC_ETD.CD_TIP_ID%TYPE;
    vCostCenter                PTC_CNT_CUS.CD_CNT_CUS%TYPE;
    vBirthDate                 PTC_PSS_FSC.DT_NSC%TYPE;
    vName                      PTC_PSS_FSC.NM_NOM%TYPE;
    vSurname                   PTC_PSS_FSC.NM_SBM%TYPE;
    vEmbossingName             PTC_PSS_FSC.NM_NOM_EBS%TYPE;
    vCardHolderName            VARCHAR2(60);
    vTagNumber                 PTC_DAD_VEI_EQP.DC_PLC%TYPE;
    vVehicleType               PTC_DAD_VEI_EQP.CD_TIP_VEI%TYPE;
    vRegistrationNumber        PTC_DAD_VEI_EQP.DC_RNA%TYPE;
    vVehicleYear               PTC_DAD_VEI_EQP.AA_FBR%TYPE;
    vNU_PED                    PTC_PED_CAT.NU_PED%TYPE;
    vProduct                   PTC_CTR_CLI.CD_PDT%TYPE;
    vOrderItems                VARCHAR2(4000);
    vErrorList                 WTMX_CARD_PKG.TCardIssuingErrorList;
    --
    vQuantidade                PTC_ITE_PED.QT_ITE_PED%TYPE;
    vMenorUE                   PTC_UND_ETG.CD_UND_ETG%TYPE;
    --
  BEGIN
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'CardRequisitionExecute');
    --
    -- Atualiza o status do Dominio do Arquivo para "Processando Validacao"
    WTMX_MASSIVELOAD_PKG.MassiveLoadFileDomainUpdStatus(pCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                        pCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                        pDT_INI_PRC => SYSDATE,
                                                        pDT_FIM_PRC => NULL,
                                                        pCD_STA_CMM => 83, -- Processando Validacao
                                                        pMSG_USER   => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                        pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                        pMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage);
    --
    IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
      --
      RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
      --
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
    IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode,0) <> 0 THEN
      --
      RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
      --
    END IF;
    --
    -- Recupera quantidade total de linhas e quantidade de linhas com erro
    SELECT COUNT(NULLIF(REG.CD_MSG_ERR, 0)), -- 1.01
           COUNT(1)
      INTO vQtde,
           vQtdeTotLin
      FROM PTC_CMS_REG REG
     WHERE REG.CD_ARQ      = WT_MASSIVELOAD_PKG.gFile.CD_ARQ;     
    --
    IF (WT_MASSIVELOAD_PKG.gFile.TP_PRC  = 'F' AND NVL(vQtde, 0) > 0) OR
       (WT_MASSIVELOAD_PKG.gFile.TP_PRC <> 'F' AND NVL(vQtde, 0) = NVL(vQtdeTotLin, 0)) THEN
      --
      RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
      --
    END IF;
    --
    -- Refaz a leitura das linhas do dominio, desprezando as linhas com erro
    WTMX_MASSIVELOAD_PKG.GetDomainLines(PCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                        PCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                        PData     => WTMX_MASSIVELOAD_PKG.vLines,
                                        PType     => WTMX_MASSIVELOAD_PKG.vTypes,
                                        pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                        pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                        pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
    --
    IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode,0) <> 0 THEN
      --
      RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
      --
    END IF;
    --
    -- Coleta os dados carretgados
    IF WTMX_MASSIVELOAD_PKG.vLines.COUNT > 0 THEN
      --
      WT_MASSIVELOAD_PKG.gFile.NU_REG := WTMX_MASSIVELOAD_PKG.vLines.FIRST;
      --
      WHILE WT_MASSIVELOAD_PKG.gFile.NU_REG IS NOT NULL LOOP
        --
        vTpReg := WTMX_MASSIVELOAD_PKG.GetContent('TipoRegistro', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
        --
        IF vTpReg = 0 THEN  -- Header
          --
          -- Valida a Descric?o da Interface no Header
          vErro := WTMX_MASSIVELOAD_PKG.ValidateInterfaceName('NomeInterface', 'INT1038.112 ? PEDIDO DE TARJETAS');
          --
          IF vErro > 0 THEN
            --
            WTMX_MASSIVELOAD_PKG.vReturnCode := 182548; -- Invalid Interface Name
            RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
            --
          END IF;
          --
        ELSIF vTpReg = 1 THEN  -- Autenticacao
          --
          vCD_GST := WTMX_MASSIVELOAD_PKG.GetContentNumber('Manager', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          vCD_BAS := WTMX_MASSIVELOAD_PKG.GetContentNumber('Base', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          --
          -- Verificac?o da Abrangencia do Gestor
          WTMX_CORPORATELEVEL_PKG.ManagerHierarchyValidate(pCD_CSL          => NULL,
                                                           pCD_CLI          => NULL,
                                                           pCD_BAS          => vCD_BAS,
                                                           pCD_CTR_CLI      => NULL,
                                                           pCD_GST          => vCD_GST,
                                                           pCD_USU          => NULL,
                                                           pCD_HIE_ETD      => NULL,
                                                           pCD_GST_RET      => vCD_GST_RET,
                                                           pCD_TIP_GST_RET  => vCD_TIP_GST,
                                                           pCD_CSL_RET      => vCD_CSL,
                                                           pMSG_USER        => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                           pCOD_RET         => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                           pMSG_RET         => WTMX_MASSIVELOAD_PKG.vReturnMessage);
          --
          IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode,0) <> 0 THEN
            --
            -- Manager incompatible with hierarchy
            WTMX_MASSIVELOAD_PKG.UpdateLine(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                            PNU_REG     => NULL,            -- WT_MASSIVELOAD_PKG.gFile.NU_REG,
                                            PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,     -- 182190,  
                                            PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,  -- SQLERRM,
                                            pMSG_USER   => vUserMessageLine,
                                            pCOD_RET    => vReturnCodeLine,
                                            pMSG_RET    => vReturnMessageLine);
            --
            IF NVL(vReturnCodeLine,0) <> 0 THEN
              --
              RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
              --
            END IF;
            --
            WTMX_MASSIVELOAD_PKG.vUserMessage       := NULL;
            WTMX_MASSIVELOAD_PKG.vReturnCode        := NULL;
            WTMX_MASSIVELOAD_PKG.vReturnMessage     := NULL;
            WTMX_MASSIVELOAD_PKG.vFinancialInd      := NULL;
            --
            RAISE WTMX_MASSIVELOAD_PKG.EProcessReturn; --EProcessError;
            --
          END IF;
          --
          vContrato := WTMX_MASSIVELOAD_PKG.GetContentNumber('Contrato', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          vProductCreditLineTypeID := WTMX_MASSIVELOAD_PKG.GetContentNumber('ProdLinhaCredit', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          vManagerUser := WTMX_MASSIVELOAD_PKG.GetContentNumber('UsuarioGestor', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          vProduct := WTMX_MASSIVELOAD_PKG.GetContentNumber('Produto', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          --
        ELSIF vTpReg = 2 THEN  -- Cabecalho Pedido
          --
          vExtPed := WTMX_MASSIVELOAD_PKG.GetContent('NroPedido', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          vDtPed := WTMX_MASSIVELOAD_PKG.GetContentDate('DataPedido', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          vObs := WTMX_MASSIVELOAD_PKG.GetContent('Obs', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          --
        ELSIF vTpReg = 3 THEN  -- Dados dos portadores
          --
          vEntity := WTMX_MASSIVELOAD_PKG.GetContentNumber('Entidade', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          --
          -- validar duplicidade
          IF DBMS_LOB.INSTR(vInputList, vEntity) > 0 THEN
            -- 
            WTMX_MASSIVELOAD_PKG.vReturnCode := 182589;  -- Portador duplicado no arquivo
            WTMX_MASSIVELOAD_PKG.vReturnMessage := WT_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode);
            --
            -- Atualiza registros com duplicidade
            WTMX_MASSIVELOAD_PKG.UpdateLine(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                            PNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                                            PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                            PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                            pMSG_USER   => vUserMessageLine,
                                            pCOD_RET    => vReturnCodeLine,
                                            pMSG_RET    => vReturnMessageLine);
            --
            IF NVL(vReturnCodeLine,0) <> 0 THEN
              --
              RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
              --
            END IF;
            --
          END IF;
          --
          vEntityType := WTMX_MASSIVELOAD_PKG.GetContentNumber('TipoEntidade', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          --
          -- validar se ja existe cartao para a entidade
          IF vEntityType = 1 THEN
            --
            SELECT COUNT(*)
              INTO vQtde
              FROM PTC_PSS_FSC FSC,
                   PTC_PSS     PSS,
                   PTC_CAT     CAT
             WHERE FSC.CD_PSS_FSC = PSS.CD_PSS_FSC
               AND PSS.CD_PTD = CAT.CD_PTD
               AND FSC.CD_ETD = vEntity;
            --
          ELSE
            --
            SELECT COUNT(*)
              INTO vQtde
              FROM PTC_DAD_VEI_EQP DAD,
                   PTC_VEI_EQP     VEI,
                   PTC_CAT         CAT
             WHERE DAD.CD_VEI_EQP = VEI.CD_VEI_EQP
               AND VEI.CD_PTD     = CAT.CD_PTD
               AND DAD.CD_ETD     = vEntity;
            --
          END IF;
          --
          IF vQtde > 0 THEN
            -- 
            WTMX_MASSIVELOAD_PKG.vReturnCode := 181753;  -- Portador já possui cartão
            WTMX_MASSIVELOAD_PKG.vReturnMessage := WT_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode);
            --
            -- Atualiza registros 
            WTMX_MASSIVELOAD_PKG.UpdateLine(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                            PNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                                            PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                            PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                            pMSG_USER   => vUserMessageLine,
                                            pCOD_RET    => vReturnCodeLine,
                                            pMSG_RET    => vReturnMessageLine);
            --
            IF NVL(vReturnCodeLine,0) <> 0 THEN
              --
              RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
              --
            END IF;
            --
          END IF;
          --
          vDeliverinUnitID := WTMX_MASSIVELOAD_PKG.GetContentNumber('UnidadeEntrega', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          --                                                                      
          -- Verifica se a Unidade de Entrega existe para o Consolidador Informado
          SELECT COUNT(*)
            INTO vQtde
            FROM PTC_UND_ETG ETG
           WHERE ETG.CD_UND_ETG = vDeliverinUnitID
             AND ETG.CD_CSL = vCD_CSL;--WT_MASSIVELOAD_PKG.gFile.CD_CSL;
          --
          IF vQtde = 0 THEN
            -- 
            WTMX_MASSIVELOAD_PKG.vReturnCode := 181606;  -- Unidade de Entrega nao existe para o Consolidador
            WTMX_MASSIVELOAD_PKG.vReturnMessage := WT_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode);
            --
            -- Atualiza registros 
            WTMX_MASSIVELOAD_PKG.UpdateLine(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                            PNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                                            PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                            PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                            pMSG_USER   => vUserMessageLine,
                                            pCOD_RET    => vReturnCodeLine,
                                            pMSG_RET    => vReturnMessageLine);
            --
            IF NVL(vReturnCodeLine,0) <> 0 THEN
              --
              RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
              --
            END IF;
            --
          END IF;
          --
          vExpensesBudgetAmount := WTMX_MASSIVELOAD_PKG.GetContentNumber('Limite', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          vCardGroupID := WTMX_MASSIVELOAD_PKG.GetContentNumber('GrupoCartao', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          vCreditDistrGroupIdent := WTMX_MASSIVELOAD_PKG.GetContentNumber('GrupoDistrib', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          vCreditDistrGroupValue := WTMX_MASSIVELOAD_PKG.GetContentNumber('ValorDistrib', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          vMerchandiseIdentification := WTMX_MASSIVELOAD_PKG.GetContentNumber('Mercadoria', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          vMerchandiseQuantity := WTMX_MASSIVELOAD_PKG.GetContentNumber('QtdMercadoria', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          vCardTechnologyType := NVL(WTMX_MASSIVELOAD_PKG.GetContentNumber('TipoTecnologia', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 1 ); -- 1.0
          
          -- 1: Montante / 2: Litros
          IF WTMX_MASSIVELOAD_PKG.GetContent('UnidDistrib', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)) = 'MONTO' THEN
             vCreditDistrGrValueTypeId := 1;
          ELSif WTMX_MASSIVELOAD_PKG.GetContent('UnidDistrib', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)) = 'LITROS ' THEN
             vCreditDistrGrValueTypeId := 2;
          END IF;   

          -- 1.09 - INICIO
          IF vCreditDistrGroupIdent IS NOT NULL THEN 
            IF NVL(vCreditDistrGrValueTypeId,0) NOT IN (1,2) OR
              (vCreditDistrGrValueTypeId = 1 AND NVL(vCreditDistrGroupValue,0) = 0) OR
              (vCreditDistrGrValueTypeId = 2 AND NVL(vMerchandiseQuantity  ,0) = 0) THEN
               -- 
               WTMX_MASSIVELOAD_PKG.vReturnCode := 183024;  
               WTMX_MASSIVELOAD_PKG.vReturnMessage := WT_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode);
               --
               -- Atualiza registros 
               WTMX_MASSIVELOAD_PKG.UpdateLine(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                               PNU_REG     => WT_MASSIVELOAD_PKG.gFile.NU_REG,
                                               PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                               PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                               pMSG_USER   => vUserMessageLine,
                                               pCOD_RET    => vReturnCodeLine,
                                               pMSG_RET    => vReturnMessageLine);
               --
               IF NVL(vReturnCodeLine,0) <> 0 THEN
                 --
                 RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
                 --
               END IF;
               --
            END IF;      
          END IF;
          -- 1.09 - FIM
          --
          IF WTMX_MASSIVELOAD_PKG.GetContent('TpDistribuicao', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)) = 'RELATIVO' THEN
            --
            vValueTypeIdentification := 'NONACCUM';--1.06
            --
          ELSE
            --
            vValueTypeIdentification := 'ACCUM'; 
            --
          END IF;            
          --
          IF WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'A' THEN
            --
            -- Separa as unidades de Entrega
            IF vListaUE.EXISTS(TO_CHAR(vDeliverinUnitID)) THEN
              --
              vListaUE(TO_CHAR(vDeliverinUnitID)) := vListaUE(TO_CHAR(vDeliverinUnitID)) + 1;
              --
            ELSE
              --
              vListaUE(TO_CHAR(vDeliverinUnitID)) := 1;
              --
            END IF;
            --
            -- Monta lista de portadores
            IF vInputList IS NOT NULL THEN
              vInputList := vInputList||'|';
            END IF;  
            

            vInputList := vInputList ||
                          TO_CLOB(vEntity) || ';' ||
                          TO_CLOB(vProductCreditLineTypeID) || ';' ||
                          TO_CLOB(vExpensesBudgetAmount) || ';0;' ||
                          TO_CLOB(vDeliverinUnitID) || ';' ||
                          TO_CLOB(vCardGroupID) || ';' ||         
                          TO_CLOB(vCreditDistrGroupIdent)     || ';' ||
                          TO_CLOB(vCreditDistrGroupValue)     || ';' ||    
                          TO_CLOB(vValueTypeIdentification)   || ';' ||  
                          TO_CLOB(vMerchandiseIdentification) || ';' ||
                          TO_CLOB(vMerchandiseQuantity)       ||';0;'||     
                          TO_CLOB(vCreditDistrGrValueTypeId)  ||';;' ||
                          TO_CLOB(vCardTechnologyType);  -- 1.0



            --
            -- grava linha de cada entidade para recuperacao de erros futuros
            vListaEntidade(TO_CHAR(vEntity)) := WT_MASSIVELOAD_PKG.gFile.NU_REG;
            --
          ELSE
            --
            IF vEntityType = 1 THEN
              --
              SELECT E.VL_ETD,
                     E.CD_TIP_ID,
                     P.CD_CEN_CUS,
                     PF.DT_NSC,
                     PF.NM_NOM,
                     PF.NM_SBM,
                     PF.NM_NOM_EBS
                INTO vIdentificationNumber,
                     vIdentificationType,
                     vCostCenter,
                     vBirthDate,
                     vName,
                     vSurname,
                     vEmbossingName
                FROM PTC_ETD E,
                     PTC_PSS P,
                     PTC_PSS_FSC PF
               WHERE E.CD_ETD = vEntity
                 AND E.CD_ETD = PF.CD_ETD
                 AND PF.CD_PSS_FSC = P.CD_PSS_FSC;
              --
              vCardHolderName := TRIM(vName || ' ' || vSurname);
              vTagNumber := NULL;
              vVehicleType := NULL;
              vRegistrationNumber := NULL;
              vVehicleYear := NULL;
              --
            ELSE
              --
              SELECT V.CD_CEN_CUS,
                     DV.DC_PLC,
                     DV.CD_TIP_VEI,
                     DV.DC_RNA,
                     DV.AA_FBR
                INTO vCostCenter,
                     vTagNumber,
                     vVehicleType,
                     vRegistrationNumber,
                     vVehicleYear
                FROM PTC_DAD_VEI_EQP DV,
                     PTC_VEI_EQP V
               WHERE DV.CD_ETD = vEntity
                 AND DV.CD_VEI_EQP = V.CD_VEI_EQP;
              --
              vEmbossingName := vTagNumber;
              vIdentificationNumber := NULL;
              vIdentificationType := NULL;
              vCardHolderName := NULL;
              vBirthDate := NULL;
              vName := NULL;
              vSurname := NULL;
              --
            END IF;
            --
            -- Insere na tabela de interface para validacao
            INSERT INTO MX_INTERFACE.TKT_CMS_1038_141_CARDHOLDER(
              FILEID, 
              DOMAINID, 
              ROWNUMBER, 
              CUSTOMERCONTRACTID, 
              CORPORATELEVELID, 
              CUSTOMERMANAGERID, 
              OPERATIONCLASS, 
              CARDNUMBER, 
              REISSUINGREASONCODE, 
              ADDITIONALCARDIND, 
              NEWCARDNUMBER, 
              CARDHOLDERTYPE, 
              CARDHOLDERID, 
              IDENTIFICATIONTYPEID, 
              IDENTIFICATIONNUMBER, 
              PROFILECODE, 
              DELIVERINGUNITID, 
              UNITCOST, 
              CARHOLDERNAME, 
              BIRTHDATE, 
              FIRSTNAME, 
              LASTNAME, 
              TAGNUMBER, 
              VEHICLETYPEID, 
              VECHICLEREGISTRATIONNUMBER, 
              VEHICLEYEAR, 
              EMBOSSINGNAME, 
              ADITIONALEMBOSSINGDATA, 
              EXPENSESBUDGETAMOUNT, 
              ADDEXPENSESBUDGETAMOUNT, 
              ACCOUNTCREATIONIND, 
              PRODUCTCREDITLINETYPEID, 
              ACCUMULATIONTYPE, 
              AUTOMATICCREDITSCHEDULEGROUPID, 
              UNITTYPE, 
              VALUE, 
              PURCHASEITEMTYPEID, 
              PURCHASEITEMQUANTITY, 
              ACCOUNTID, 
              EFFECT, 
              RESPONSEMESSAGE, 
              RESPONSECODE, 
              OPERATIONID)
            VALUES(
              WT_MASSIVELOAD_PKG.gFile.CD_ARQ,               --FILEID
              WT_MASSIVELOAD_PKG.gFile.CD_DOM,               --DOMAINID, 
              WT_MASSIVELOAD_PKG.gFile.NU_REG,               --ROWNUMBER, 
              vContrato,                                     --CUSTOMERCONTRACTID, 
              vCD_BAS,                                       --CORPORATELEVELID, 
              vCD_GST,                                       --CUSTOMERMANAGERID, 
              'CREATECARDHOLDER',                            --OPERATIONCLASS, 
              NULL,                                          --CARDNUMBER, 
              NULL,                                          --REISSUINGREASONCODE, 
              'F',                                           --ADDITIONALCARDIND, 
              NULL,                                          --NEWCARDNUMBER, 
              DECODE(vEntityType, 1, 'PERSON', 'EQUIPMENT'), --CARDHOLDERTYPE, 
              NULL,                                          --CARDHOLDERID, 
              vIdentificationType,                           --IDENTIFICATIONTYPEID, 
              vIdentificationNumber,                         --IDENTIFICATIONNUMBER, 
              vCardGroupID,                                  --PROFILECODE, 
              vDeliverinUnitID,                              --DELIVERINGUNITID, 
              vCostCenter,                                   --UNITCOST, 
              vCardHolderName,                               --CARHOLDERNAME, 
              vBirthDate,                                    --BIRTHDATE, 
              vName,                                         --FIRSTNAME, 
              vSurname,                                      --LASTNAME, 
              vTagNumber,                                    --TAGNUMBER, 
              vVehicleType,                                  --VEHICLETYPEID, 
              SUBSTR(TRIM(vRegistrationNumber),1,18),        --VECHICLEREGISTRATIONNUMBER, 
              TO_DATE(vVehicleYear, 'YYYY'),                 --VEHICLEYEAR, 
              vTagNumber,                                    --EMBOSSINGNAME, 
              ' ',                                           --ADITIONALEMBOSSINGDATA, 
              vExpensesBudgetAmount,                         --EXPENSESBUDGETAMOUNT, 
              null,                                          --ADDEXPENSESBUDGETAMOUNT, 
              'T',                                           --ACCOUNTCREATIONIND, 
              vProductCreditLineTypeID,                      --PRODUCTCREDITLINETYPEID, 
              vValueTypeIdentification,                      --ACCUMULATIONTYPE, 
              vCreditDistrGroupIdent,                        --AUTOMATICCREDITSCHEDULEGROUPID, 
              vCreditDistrGrValueTypeId,                     --UNITTYPE, 
              vCreditDistrGroupValue,                        --VALUE, 
              vMerchandiseIdentification,                    --PURCHASEITEMTYPEID, 
              vMerchandiseQuantity,                          --PURCHASEITEMQUANTITY, 
              NULL,                                          --ACCOUNTID, 
              NULL,                                          --EFFECT, 
              NULL,                                          --RESPONSEMESSAGE, 
              NULL,                                          --RESPONSECODE, 
              NULL);                                         --OPERATIONID
            --
          END IF;
        ELSIF vTpReg = 99 THEN  -- Trailer
          --
          -- validar contador???
          NULL;
          --
        END IF;
        --
        WT_MASSIVELOAD_PKG.gFile.NU_REG := WTMX_MASSIVELOAD_PKG.vLines.NEXT(WT_MASSIVELOAD_PKG.gFile.NU_REG);
        --
      END LOOP;
      --
      -- Recupera quantidade total de linhas e quantidade de linhas com erro
      SELECT COUNT(NULLIF(REG.CD_MSG_ERR, 0)), -- 1.01
             COUNT(1)
        INTO vQtde,
             vQtdeTotLin
        FROM PTC_CMS_REG REG
       WHERE REG.CD_ARQ      = WT_MASSIVELOAD_PKG.gFile.CD_ARQ;     
      --
      IF (WT_MASSIVELOAD_PKG.gFile.TP_PRC  = 'F' AND NVL(vQtde, 0) > 0) OR
         (WT_MASSIVELOAD_PKG.gFile.TP_PRC <> 'F' AND NVL(vQtde, 0) = NVL(vQtdeTotLin, 0)) THEN
        --
        RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
        --
      END IF;
      --
      -- Refaz a leitura das linhas do dominio, desprezando as linhas com erro
      WTMX_MASSIVELOAD_PKG.GetDomainLines(PCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                          PCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                          PData     => WTMX_MASSIVELOAD_PKG.vLines,
                                          PType     => WTMX_MASSIVELOAD_PKG.vTypes,
                                          pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                          pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                          pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode,0) <> 0 THEN
        --
        RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
        --
      END IF;
      -- 
      IF WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'A' THEN -- APPLY
        --
        vDeliverinUnitID := vListaUE.FIRST;
        --
        vQuantidade := 0;
        vMenorUE    := 999999999999;
        --
        WHILE vDeliverinUnitID IS NOT NULL LOOP
          --
          vQuantidade := vQuantidade + vListaUE(vDeliverinUnitID);
          --
          IF TO_NUMBER(vDeliverinUnitID) < vMenorUE THEN
            --
            vMenorUE := TO_NUMBER(vDeliverinUnitID);
            --
          END IF;
          --
          vDeliverinUnitID := vListaUE.NEXT(vDeliverinUnitID);
          --
        END LOOP;
        --
        vOrderItems := vOrderItems                              || '3;' || -- CD_TIP_PED
                       vQuantidade                              ||  ';' || -- QT_ITE_PED   
                       TO_CHAR(vDtPed, 'DD/MM/YYYY HH24:MI:SS') ||  ';' || -- DT_AGD          
                       TO_CHAR(vDtPed, 'DD/MM/YYYY HH24:MI:SS') ||  ';' || -- DT_EXE          
                       1                                        ||  ';' || -- CD_STA_TIP_ITM_PED          
                       WT_MASSIVELOAD_PKG.gFile.CD_CLI          ||  ';' || -- CD_CLI          
                       TO_CHAR(vMenorUE);                                  -- CD_UND_ETG

        --
        -- Cria o pedido na WEM
        WTMX_ORDER_PKG.OrderCreate(PNU_PED => vNU_PED, 
                                   PDT_PED => vDtPed, 
                                   PDT_APV => vDtPed, 
                                   PDT_EXE => vDtPed, 
                                   PDC_OBS => vObs, 
                                   PCD_USU_SOL => vManagerUser, 
                                   PCD_USU_APV => vManagerUser, 
                                   PCD_BAS => vCD_BAS, 
                                   PCD_STA_PED => 8, 
                                   PCD_TIP_PED => 101, 
                                   PITEMLIST => vOrderItems, 
                                   pUSER => NULL, 
                                   pIP => 'MASSIVELOAD', 
                                   PEXTERNALORDERNUMBER => vExtPed, 
                                   pCD_GST => vCD_GST, 
                                   PMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                   PCOD_RET => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                   PMSG_RET => WTMX_MASSIVELOAD_PKG.vReturnMessage);
        --
        IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode,0) <> 0 THEN
          --
          -- Error in call to OrderCreate
          WTMX_MASSIVELOAD_PKG.UpdateLine(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                          PNU_REG     => NULL,            
                                          PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,     
                                          PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,  
                                          pMSG_USER   => vUserMessageLine,
                                          pCOD_RET    => vReturnCodeLine,
                                          pMSG_RET    => vReturnMessageLine);
          --
          IF NVL(vReturnCodeLine,0) <> 0 THEN
            --
            RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
            --
          END IF;
          --
          RAISE WTMX_MASSIVELOAD_PKG.EProcessReturn; --EProcessError;
          --
        END IF;

        -- 1.02 inicio
        WTMX_MASSIVELOAD_PKG.MassiveLoadOrderCreate(PCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ, 
                                                    PCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM, 
                                                    PNU_PED   => vNU_PED, 
                                                    PMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage, 
                                                    PCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode, 
                                                    PMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
        --
        IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
          --
          WTMX_MASSIVELOAD_PKG.UpdateRelatedLines(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                  PCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                  PNU_REG     => NULL,
                                                  PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                  PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage,
                                                  pMSG_USER   => vUserMessageLine,
                                                  pCOD_RET    => vReturnCodeLine,
                                                  pMSG_RET    => vReturnMessageLine);
          --
          IF NVL(vReturnCodeLine,0) <> 0 THEN
            --
            RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
            --
          END IF;
          --
          RAISE WTMX_MASSIVELOAD_PKG.EProcessReturn; 
          --
        END IF; -- 1.02 fim
          
        --
        -- Faz a emissao no Sunnel
        WTMX_CARD_PKG.CardIssuingCreate(PINPUTLIST => vInputList, 
                                        PCUSTOMERCONTRACTID => vContrato, 
                                        PCORPORATELEVELID => vCD_BAS, 
                                        PCUSTOMERMANAGERID => vCD_GST, 
                                        PPROCESSTYPE => 'APPLY', 
                                        PACCOUNTCREATIONIND => 'T', 
                                        PORDERNUMBER => vNU_PED, 
                                        PPRODUCT => vProduct, 
                                        PHOST => NULL, 
                                        pUSER => NULL, 
                                        pIP => 'MASSIVELOAD', 
                                        PERRORLIST => vErrorList, 
                                        PMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                        PCOD_RET => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                        PMSG_RET => WTMX_MASSIVELOAD_PKG.vReturnMessage);
        --
        -- verifica erros na camada SUNNEL
        -- 1.04 alterado retorno de erro
        IF vErrorList.COUNT > 0 THEN
          --
          FOR vInd IN 1 .. vErrorList.COUNT LOOP
            --
            IF vErrorList(vInd).SunnelErrorObjectName IS NOT NULL THEN
              --
              WTMX_MASSIVELOAD_PKG.vReturnCode := NVL(WTMX_UTILITY_PKG.GetSunnelError(vErrorList(vInd).SunnelErrorMessage || vErrorList(vInd).SunnelErrorObjectName, 15), 9999);
              WTMX_MASSIVELOAD_PKG.vReturnMessage := WTMX_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode);
              --
            ELSIF vErrorList(vInd).WEMErrorCode != 0 THEN
              --
              WTMX_MASSIVELOAD_PKG.vReturnCode := vErrorList(vInd).WEMErrorCode;
              WTMX_MASSIVELOAD_PKG.vReturnMessage := NVL(WTMX_UTILITY_PKG.GetMessage(WTMX_MASSIVELOAD_PKG.vReturnCode),'CardIssuingCreate error');
            ELSE
              --
              WTMX_MASSIVELOAD_PKG.vReturnCode := 189999;
              WTMX_MASSIVELOAD_PKG.vReturnMessage := 'CardIssuingCreate error';
            END IF;                   
            --            
            WTMX_MASSIVELOAD_PKG.UpdateLine(PCD_ARQ => WT_MASSIVELOAD_PKG.gFile.CD_ARQ, 
                                            PNU_REG => vListaEntidade(TO_CHAR(vErrorList(vInd).EntityIdentification)), 
                                            PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode, 
                                            PDS_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnMessage, 
                                            pMSG_USER   => vUserMessageLine,
                                            pCOD_RET    => vReturnCodeLine,
                                            pMSG_RET    => vReturnMessageLine);
            --
            IF NVL(vReturnCodeLine,0) <> 0 THEN
              --
              RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
              --
            END IF;
            --
          END LOOP;
          --
        ELSIF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode,0) <> 0 THEN
          --
          -- Error in call to CardIssuingCreate
          WTMX_MASSIVELOAD_PKG.UpdateLine(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                          PNU_REG     => NULL,            
                                          PCD_MSG_ERR => WTMX_MASSIVELOAD_PKG.vReturnCode,     
                                          PDS_MSG_ERR => NVL(WTMX_MASSIVELOAD_PKG.vReturnMessage, 'CardIssuingCreate error'),  
                                          pMSG_USER   => vUserMessageLine,
                                          pCOD_RET    => vReturnCodeLine,
                                          pMSG_RET    => vReturnMessageLine);
          --
          IF NVL(vReturnCodeLine,0) <> 0 THEN
            --
            RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
            --
          END IF;
          --
          RAISE WTMX_MASSIVELOAD_PKG.EProcessReturn; --EProcessError;
          --
        END IF;        
        --
        WTMX_MASSIVELOAD_PKG.vFinancialInd  := 'F';
        --
      ELSE -- validate
        --
        WTMX_MASSIVELOAD_PKG.vFinancialInd  := 'T';
        --
      END IF;
      --
    END IF;
    --
    -- Recupera quantidade total de linhas e quantidade de linhas com erro
    SELECT COUNT(NULLIF(REG.CD_MSG_ERR, 0)), -- 1.01
           COUNT(1)
      INTO vQtde,
           vQtdeTotLin
      FROM PTC_CMS_REG REG
     WHERE REG.CD_ARQ      = WT_MASSIVELOAD_PKG.gFile.CD_ARQ;
    -- AND REG.CD_MDL_REG  = WT_MASSIVELOAD_PKG.gFile.CD_MDL_REG;      
    --
    IF (WT_MASSIVELOAD_PKG.gFile.TP_PRC  = 'F' AND NVL(vQtde, 0) > 0) OR
       (WT_MASSIVELOAD_PKG.gFile.TP_PRC <> 'F' AND NVL(vQtde, 0) = NVL(vQtdeTotLin, 0)) THEN
       --
       RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
       --
    END IF;
    --
    
    -- 1.02
    -- Se o processamento envolver Greentech, atualiza status para processamento das interfaces necessarias
    IF WTMX_MASSIVELOAD_PKG.vFinancialInd = 'T' THEN
      --
      -- Atualiza o status do Dominio do Arquivo para "Aguardando Envio Financeiro"
      WTMX_MASSIVELOAD_PKG.MassiveLoadFileDomainUpdStatus(pCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                          pCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                          pDT_INI_PRC => NULL,
                                                          pDT_FIM_PRC => NULL,
                                                          pCD_STA_CMM => 78,          -- 78 = Processando Financeiro
                                                          pMSG_USER   => WTMX_MASSIVELOAD_PKG.vUserMessage, 
                                                          pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode, 
                                                          pMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      IF NVL(WTMX_MASSIVELOAD_PKG.vReturnCode, 0) <> 0 THEN
        -- Se o processo de update deu erro, forca o retorno do erro
        RAISE WTMX_MASSIVELOAD_PKG.EProcessReturn;
        --
      END IF;
      --
    ELSE
      --
      -- Atualiza o status do Dominio do Arquivo para "Nada a processar"
      WTMX_MASSIVELOAD_PKG.MassiveLoadFileDomainUpdStatus(pCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                          pCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                          pDT_INI_PRC => NULL,
                                                          pDT_FIM_PRC => SYSDATE,
                                                          pCD_STA_CMM => 86, -- 86 - Nada a Processar
                                                          pMSG_USER   => WTMX_MASSIVELOAD_PKG.vUserMessage, 
                                                          pCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode, 
                                                          pMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage);      
      --
      WTMX_MASSIVELOAD_PKG.MassiveLoadFinish(PCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                             PCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                             pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage, 
                                             pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode, 
                                             pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
    END IF;
    --

    
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --

  EXCEPTION
    --
    WHEN WTMX_MASSIVELOAD_PKG.EProcessReturn THEN
      --
      ROLLBACK;        -- Desfaz eventuais alteracoes ja efetuadas
      --
      -- Executa a proc para a gerac?o do arquivo de retorno    --
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
      ROLLBACK;        -- Desfaz eventuais alterac?es ja efetuadas
      --
      WTMX_MASSIVELOAD_PKG.vFinancialInd  := 'F';  -- Para n?o executar o Sunnel
      vExceptionType := 'EProcessError';
      -- Executa a proc para a gerac?o do arquivo de retorno    --
      WTMX_MASSIVELOAD_PKG.MassiveLoadGenerateRespFile(pCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                       pCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                       pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                       pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                       pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      RAISE;
      --
    WHEN OTHERS THEN
      --
      ROLLBACK;        -- Desfaz eventuais alterac?es ja efetuadas
      --

      -- 1.02
      WTMX_MASSIVELOAD_PKG.UpdateRelatedLines(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                              PCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                              PNU_REG     => NULL,
                                              PCD_MSG_ERR => 182190 ,
                                              PDS_MSG_ERR => sqlerrm,
                                              pMSG_USER   => vUserMessageLine,
                                              pCOD_RET    => vReturnCodeLine,
                                              pMSG_RET    => vReturnMessageLine);
      --
            
      -- Executa a proc para a gerac?o do arquivo de retorno    --
      WTMX_MASSIVELOAD_PKG.MassiveLoadGenerateRespFile(pCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                       pCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                       pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                       pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                       pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --         
      WTMX_MASSIVELOAD_PKG.vFinancialInd := 'F';  -- Para n?o executar o Sunnel
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      RAISE;
      --
  END;
  --
  -------------------------------------------------------------------
  -- Procedure de Finalizacao Especialista - Pedido de Cartao
  -------------------------------------------------------------------
  PROCEDURE CardRequisitionFinish IS
    --
    vStatus            PTC_STA_CMM.CD_STA_CMM%TYPE;
    vQtde              NUMBER;
    vQtdeTotLin        NUMBER;
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'CardRequisitionFinish');
    --
    -- Efetuar as leituras de status antes de seguir processamento
    SELECT AD.CD_STA_CMM
      INTO vStatus
      FROM PTC_CMS_ARQ_DOM AD
     WHERE AD.CD_ARQ = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
       AND AD.CD_DOM = WT_MASSIVELOAD_PKG.gFile.CD_DOM;
    --
    IF vStatus = 78 THEN
      --
      -- Se o processamento envolveu Greentech,
      -- ler os status de processamento das tabelas de interface
      -- e atualiza na tabela de Registro de Carga Massiva (PTC_CMS_REG)
      FOR R1 IN (SELECT ROWNUMBER,
                        RESPONSECODE,
                        RESPONSEMESSAGE
                   FROM TKT_CMS_1038_141_CARDHOLDER
                  WHERE FILEID = WT_MASSIVELOAD_PKG.gFile.CD_ARQ
                    AND DOMAINID = WT_MASSIVELOAD_PKG.gFile.CD_DOM
                    AND NVL(EFFECT, 'X') = 'R'
                    AND RESPONSEMESSAGE IS NOT NULL) LOOP
        --
        WTMX_MASSIVELOAD_PKG.UpdateRelatedLines(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                PCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                PNU_REG     => R1.ROWNUMBER,
                                                PCD_MSG_ERR => NVL(WT_UTILITY_PKG.GetSunnelError(R1.RESPONSEMESSAGE, 18), 9999), -- 1.03
                                                PDS_MSG_ERR => R1.RESPONSEMESSAGE,
                                                pMSG_USER   => vUserMessageLine,
                                                pCOD_RET    => vReturnCodeLine,
                                                pMSG_RET    => vReturnMessageLine);
        --
        IF NVL(vReturnCodeLine,0) <> 0 THEN
          --
          WTMX_MASSIVELOAD_PKG.vUserMessage   := WTMX_MASSIVELOAD_PKG.vUserMessage || '|' || vUserMessageLine;
          WTMX_MASSIVELOAD_PKG.vReturnCode    := WTMX_MASSIVELOAD_PKG.vReturnCode  || '|' || vReturnCodeLine;
          WTMX_MASSIVELOAD_PKG.vReturnMessage := WTMX_MASSIVELOAD_PKG.vReturnMessage || '|' || vReturnMessageLine;
          --
          RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
          --
        END IF;
        --
      END LOOP;
      --
      
      -- Recupera quantidade total de linhas e quantidade de linhas com erro
      SELECT COUNT(NULLIF(REG.CD_MSG_ERR, 0)), -- 1.01
             COUNT(1)
        INTO vQtde,
             vQtdeTotLin
        FROM PTC_CMS_REG REG
       WHERE REG.CD_ARQ      = WT_MASSIVELOAD_PKG.gFile.CD_ARQ;     
      --
      IF (WT_MASSIVELOAD_PKG.gFile.TP_PRC  = 'F' AND NVL(vQtde, 0) > 0) OR
         (WT_MASSIVELOAD_PKG.gFile.TP_PRC <> 'F' AND NVL(vQtde, 0) = NVL(vQtdeTotLin, 0)) THEN
        --
        RAISE WTMX_MASSIVELOAD_PKG.EProcessError;
        --
      END IF;
      --
    END IF;
    --
    
    WTMX_MASSIVELOAD_PKG.MassiveLoadGenerateRespFile(pCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                     pCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                     pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                     pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                     pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
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
      WTMX_MASSIVELOAD_PKG.MassiveLoadGenerateRespFile(pCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                       pCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                       pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                       pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                       pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      WTMX_MASSIVELOAD_PKG.vExceptionType := 'EProcessError';
      --
      IF WT_MASSIVELOAD_PKG.gFile.NU_PED IS NOT NULL AND WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'A' THEN
        --
        WTMX_ORDER_PKG.AutonomousCredDistribCancel(pNU_PED     => WT_MASSIVELOAD_PKG.gFile.NU_PED,
                                                   pCD_USU_SOL => WT_MASSIVELOAD_PKG.gFile.CD_USU,
                                                   PMSG_USER   => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                   PCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                   PMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage);
        --
      END IF;
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      RAISE;
      --
    WHEN OTHERS THEN
      -- 1.05
      WTMX_MASSIVELOAD_PKG.UpdateRelatedLines(PCD_ARQ     => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                              PCD_DOM     => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                              PNU_REG     => NULL,
                                              PCD_MSG_ERR => 9999,
                                              PDS_MSG_ERR => SQLERRM,
                                              pMSG_USER   => vUserMessageLine,
                                              pCOD_RET    => vReturnCodeLine,
                                              pMSG_RET    => vReturnMessageLine);      
      --
      WTMX_MASSIVELOAD_PKG.MassiveLoadGenerateRespFile(pCD_ARQ   => WT_MASSIVELOAD_PKG.gFile.CD_ARQ,
                                                       pCD_DOM   => WT_MASSIVELOAD_PKG.gFile.CD_DOM,
                                                       pMSG_USER => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                       pCOD_RET  => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                       pMSG_RET  => WTMX_MASSIVELOAD_PKG.vReturnMessage);
      --
      IF WT_MASSIVELOAD_PKG.gFile.NU_PED IS NOT NULL AND WT_MASSIVELOAD_PKG.gFile.TP_ACA = 'A' THEN
        --
        WTMX_ORDER_PKG.AutonomousCredDistribCancel(pNU_PED     => WT_MASSIVELOAD_PKG.gFile.NU_PED,
                                                   pCD_USU_SOL => WT_MASSIVELOAD_PKG.gFile.CD_USU,
                                                   PMSG_USER   => WTMX_MASSIVELOAD_PKG.vUserMessage,
                                                   PCOD_RET    => WTMX_MASSIVELOAD_PKG.vReturnCode,
                                                   PMSG_RET    => WTMX_MASSIVELOAD_PKG.vReturnMessage);
        --
      END IF;

      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      RAISE;
      --
  END;
  --
  ----------------------------------------------------------------------
  -- Procedure de Resposta Especialista - Pedido de Cartao
  ----------------------------------------------------------------------
  PROCEDURE CardRequisitionResponse(pCD_ARQ      IN PTC_CMS_ARQ_DOM.CD_ARQ%TYPE,
                                    pCD_DOM      IN PTC_CMS_ARQ_DOM.CD_DOM%TYPE,
                                    pNM_ARQ     OUT PTC_CMS_ARQ.NM_ARQ%TYPE,
                                    pResponse   OUT WTMX_MASSIVELOAD_PKG.TResponseList,
                                    pMSG_USER   OUT NOCOPY VARCHAR2,
                                    pCOD_RET    OUT NOCOPY NUMBER,
                                    pMSG_RET    OUT NOCOPY VARCHAR2) IS
    --                          
    vOperacao       VARCHAR2(10);
    vNomeArquivo    PTC_CMS_ARQ.NM_ARQ%TYPE;
    vStatus         PTC_CMS_ARQ.CD_STA_CMM%TYPE;
    vTpReg          NUMBER(2);
    vInd            BINARY_INTEGER  := 0;
    vEntity         PTC_ETD.CD_ETD%TYPE;
    vEntityType     PTC_ETD.CD_TIP_ETD%TYPE;
    vCardHolder     PTC_PTD.CD_PTD%TYPE;
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'CardRequisitionResponse');
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
    -- Popula os dados do arquivo em execuc?o
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
    IF NVL(pCOD_RET,0) <> 0 THEN
      --
      RETURN;
      --
    END IF;
    --
    
    -- Tratamento para as linhas retornadas da validac?o 
    IF WTMX_MASSIVELOAD_PKG.vLines.COUNT > 0 THEN
      --
      WT_MASSIVELOAD_PKG.gFile.NU_REG := WTMX_MASSIVELOAD_PKG.vLines.FIRST;
      --
      WHILE WT_MASSIVELOAD_PKG.gFile.NU_REG IS NOT NULL LOOP
        --
        BEGIN
          --
          vInd  := vInd + 1;
          vTpReg := WTMX_MASSIVELOAD_PKG.GetContent('TipoRegistro', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
          --
          IF vTpReg = 0 THEN  -- Header
            --  
            vNomeArquivo    := REPLACE(vNomeArquivo, '1038112I', '1038112O');
            vNomeArquivo    := SUBSTR(vNomeArquivo,  1, 24) || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') || '.TXT';
            pNM_ARQ         := vNomeArquivo;
            --                 
            pResponse(vInd) := '00' || 
                               LPAD(WTMX_MASSIVELOAD_PKG.GetContent('NroLinha', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  7, '0') ||
                               LPAD(WTMX_MASSIVELOAD_PKG.GetContent('NroRemessa', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 10, '0') ||
                               TO_CHAR(SYSDATE, 'DDMMYYYYHH24MISS')                                             ||
                               RPAD('INT1038.112 - RETORNO PEDIDO DE TARJETAS', 50, ' ')                 ||
                               RPAD(vOperacao, 10, ' ');
            --
          ELSIF vTpReg = 1 THEN  -- Gestor
            --
            pResponse(vInd) := '01' || 
                               LPAD(WTMX_MASSIVELOAD_PKG.GetContent('NroLinha', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  7, '0') ||
                               LPAD(WTMX_MASSIVELOAD_PKG.GetContent('Manager', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 12, '0') ||
                               LPAD(WTMX_MASSIVELOAD_PKG.GetContent('Base', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 12, '0') ||
                               SUBSTR(LPAD(WTMX_MASSIVELOAD_PKG.GetContent('CodErroReg', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  6, '0'), 3, 4);
            --
          ELSIF vTpReg = 2 THEN  -- Order Header
            
            pResponse(vInd) := '02' || 
                               LPAD(WTMX_MASSIVELOAD_PKG.GetContent('NroLinha', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  7, '0') ||
                               LPAD(NVL(WTMX_MASSIVELOAD_PKG.GetContent('NroPedido', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),'0'), 12, '0') ||
                               LPAD(NVL(WT_MASSIVELOAD_PKG.gFile.NU_PED, '0'), 12, '0') ||
                               SUBSTR(LPAD(WTMX_MASSIVELOAD_PKG.GetContent('CodErroReg', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  6, '0'), 3, 4);
            --
          ELSIF vTpReg = 3 THEN  -- Order Detail
            --
            vEntity := WTMX_MASSIVELOAD_PKG.GetContent('Entidade', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            vEntityType := WTMX_MASSIVELOAD_PKG.GetContentNumber('TipoEntidade', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG));
            --
            BEGIN
              --
              IF vEntityType = 1 THEN
                --
                SELECT P.CD_PTD
                  INTO vCardHolder
                  FROM PTC_PSS_FSC PF,
                       PTC_PSS P
                 WHERE PF.CD_ETD = vEntity
                   AND PF.CD_PSS_FSC = P.CD_PSS_FSC;
                --
              ELSE
                --
                SELECT V.CD_PTD
                  INTO vCardHolder
                  FROM PTC_DAD_VEI_EQP DV,
                       PTC_VEI_EQP V
                 WHERE DV.CD_ETD = vEntity
                   AND DV.CD_VEI_EQP = V.CD_VEI_EQP;
                --
              END IF;
              --
            EXCEPTION
              -- 
              WHEN NO_DATA_FOUND THEN
                --
                vCardHolder := NULL;
                --
            END;
            --
            pResponse(vInd) := '03' || 
                               LPAD(WTMX_MASSIVELOAD_PKG.GetContent('NroLinha', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 7, '0') ||
                               LPAD(NVL(WTMX_MASSIVELOAD_PKG.GetContent('NroPedido',WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), '0'), 12, '0') ||
                               LPAD(vEntity, 30, '0') ||
                               LPAD(NVL(TO_CHAR(vCardHolder), '0'), 12, '0') ||   --
                               LPAD(NVL(WT_MASSIVELOAD_PKG.gFile.NU_PED, '0'), 12, '0') ||
                               SUBSTR(LPAD(WTMX_MASSIVELOAD_PKG.GetContent('CodErroReg', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)), 6, '0'), 3, 4);
            --                                    
          ELSIF vTpReg = 99 THEN  -- Trailer
            --
            pResponse(vInd) := '99' || 
                               LPAD(WTMX_MASSIVELOAD_PKG.GetContent('NroLinha', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),   7, '0') ||
                               LPAD(WTMX_MASSIVELOAD_PKG.GetContent('NroRemessa', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  10, '0') ||
                               TO_CHAR(WTMX_MASSIVELOAD_PKG.GetContentDate('DataRemessa', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),'DDMMYYYYHH24MISS') ||
                               LPAD(WTMX_MASSIVELOAD_PKG.GetContent('QtdeRegistros', WTMX_MASSIVELOAD_PKG.vLines(WT_MASSIVELOAD_PKG.gFile.NU_REG)),  15, '0');
            --
          END IF;
          --           
        END;
        --
        WT_MASSIVELOAD_PKG.gFile.NU_REG := WTMX_MASSIVELOAD_PKG.vLines.NEXT(WT_MASSIVELOAD_PKG.gFile.NU_REG);
        --
      END LOOP;     -- Loop vLines
      --
    END IF;
    --
  END;
  --
END WTMX_CMS_ORDER_PKG;
