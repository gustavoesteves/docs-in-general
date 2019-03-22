CREATE OR REPLACE PACKAGE BODY WT2MX_MSS_CREDIT_ORDER_PKG  IS
  -- *********************
  -- * INTERNAL TYPES    *
  -- *********************
  TYPE RCurCardOperationCardList IS RECORD (
    LINES      NUMBER,
    ROWPAG     NUMBER,
    NU_CAT     PTC_CAT.NU_CAT%TYPE,
    NU_CAT_OPE PTC_CAT.NU_CAT%TYPE,
    CD_TIP_CAT PTC_TIP_CAT.CD_TIP_CAT%TYPE
  );
  -- 
  --
  -- *********************
  -- * VARIAVEIS GLOBAIS *
  -- *********************
  --
  vModule VARCHAR2(100);
  vAction VARCHAR2(100);
  --
  vCD_GST         PTC_GST.CD_GST%TYPE;
  vCD_BAS         PTC_BAS.CD_BAS%TYPE;
  vCreditLineType PTC_PED_FIN_CAT.CD_TIP_LIN_CDT%TYPE;
  vCD_GST_RET     PTC_GST.CD_GST%TYPE;
  vCD_USU_SOL     PTC_USU.CD_USU%TYPE;
  vCD_TIP_GST     PTC_GST.CD_TIP_GST%TYPE;
  vCD_CSL         PTC_CSL.CD_CSL%TYPE;
  vContrato       PTC_CTR_CLI.CD_CTR_CLI%TYPE;
  vExtPed         PTC_PED.NU_PED_EXT%TYPE;
  vDt_Agd         PTC_ITE_PED.DT_AGD%TYPE;
  vVL_PED_FIN_BAS PTC_PED_FIN_BAS.VL_PED_FIN_BAS%TYPE;
  vQT_ITE_PED     PTC_ITE_PED.QT_ITE_PED%TYPE;
  vCD_TIP_PED     PTC_PED_CAT.CD_TIP_PED%TYPE;
  vTagNfcNum      PTC_DAD_VEI_EQP.NU_TAG_NFC%TYPE; -- 1.25  VARCHAR2(20); -- 1.22
  vCardType       PTC_CAT.CD_TIP_CAT%TYPE;
  vCardStatus     PTC_CAT.CD_STA_CAT%TYPE;
  vNU_PED         PTC_PED_CAT.NU_PED%TYPE;
  vCD_CIC_APU     PTC_CIC_APU.CD_CIC_APU%TYPE;
  VCD_TIP_ETD     PTC_ETD.CD_TIP_ETD%TYPE;
  vProductCreditLineTypeID PTC_TIP_LIN_SNN.CD_TIP_LIN_CDT%TYPE;
  --
  vKM_Quantity PTC_GPO_DST_CRD_PTD.QT_KM%TYPE;  -- 1.14
  vNU_RND      PTC_GPO_DST_CRD_PTD.NU_RND%TYPE; -- 1.14   
  --
  vCard              VARCHAR2(20);
  vTagNfcId          VARCHAR2(20); -- 1.22
  vValue             NUMBER;
  vCreditType        NUMBER;
  vItemDist          CLOB;
  vCardOperationList RCurCardOperationCardList;
  vOperationClass    VARCHAR2(20);
  vFinancialInd      VARCHAR2(1);
  vUnitType          NUMBER;
  vMerchandise       NUMBER;
  vMerchQuantity     NUMBER;
  vMerchPrice        NUMBER;
  vAdditionalInfo    VARCHAR2(200);
  vExpirationDate    DATE;
  vCardBalance       NUMBER;
  vRoute             VARCHAR2(50);
  vCurrency          NUMBER;
  vCardHolder        NUMBER;
  vVL_TRF            NUMBER;
  vMerchUnit         NUMBER;
  --
  -- *********************
  -- *  METHODS          *
  -- *********************
  --
  --
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
   
  END GetCardFromTagNFC;
  --
  --
  ----------------------------------------------------------------------------------------
  -- Retorna o ProductCreditLineType ID a partir do Codigo da Base
  ----------------------------------------------------------------------------------------
  FUNCTION GetProdCreditLineFromCorpLevel(PLabelCorpLevel IN VARCHAR2) RETURN NUMBER IS
    --
    vResult PTC_PDT_SVC_LIN_CDT_SNN.CD_PDT_LIN_CRD%TYPE;
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'GetProdCreditLineFromCorpLevel');
    --                                                     
    BEGIN
      --
      SELECT PSLCS.CD_PDT_LIN_CRD
        INTO vResult
      FROM PTC_BAS B, PTC_PDT_SVC_LIN_CDT_SNN PSLCS 
       WHERE B.CD_BAS = PLabelCorpLevel
         AND B.CD_MDL_FAT = PSLCS.CD_MDL_FAT;        
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --
        vResult := NULL;
        --
    END;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
    RETURN vResult;
    --
  END GetProdCreditLineFromCorpLevel;
  --
  --
  ----------------------------------------------------------------------------------------
  -- Retorna o Valor total do pedido
  ----------------------------------------------------------------------------------------
  FUNCTION GetValorTotalPedido RETURN NUMBER IS
    --
    vResult NUMBER;
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'GetValorTotalPedido');
    --                                                     
    BEGIN
      SELECT SUM(MSS_CTD.VL_CTD)
        INTO vResult
      FROM PTC_MSS_CTD MSS_CTD
        INNER JOIN PTC_MSS_MDL_CTD MDL_CTD ON MDL_CTD.CD_MDL_CTD = MSS_CTD.CD_MDL_CTD
        INNER JOIN PTC_MSS_REG MSS_REG ON MSS_CTD.NU_REG = MSS_REG.NU_REG
      WHERE MDL_CTD.DS_CTD = 'VALUE'
        AND MDL_CTD.CD_MDL_REG IN (
          SELECT CD_MDL_REG
          FROM PTC_MSS_MDL_REG
          WHERE CD_MDL_ARQ = 803
        )
        AND MSS_REG.CD_ARQ = WT2MX_MASSIVELOAD_MNG.gFile.CD_ARQ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --
        vResult := NULL;
    --
    END;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
    RETURN vResult;
    --
  END GetValorTotalPedido;
  --
  --
  ----------------------------------------------------
  -- Retorna a linha de crédito a ser utilizada
  ----------------------------------------------------
  FUNCTION GetCreditLineFromCorpLevel RETURN NUMBER IS
    --
    vCreditLine NUMBER;
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'GetCreditLineFromCorpLevel');
    --                                                     
    BEGIN
      SELECT DISTINCT (PSLCS.CD_TIP_LIN_CDT)
        INTO vCreditLine
      FROM PTC_BAS                        BAS,
           PTC_NIV_CTR_ITE_SVC_PTE_NEG    NCISPN,
           PTC_PDT_SVC_LIN_CDT_SNN        PSLCS
      WHERE BAS.CD_PTE_NEG    = NCISPN.CD_PTE_NEG
        AND NCISPN.CD_ITE_SVC = NCISPN.CD_SVC
        AND NCISPN.CD_SVC     = PSLCS.CD_SVC
        AND BAS.CD_MDL_FAT    = PSLCS.CD_MDL_FAT
        AND BAS.CD_BAS        = vCD_BAS
        AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --
        vCreditLine := NULL;
        --
    END;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
    RETURN vCreditLine;
    --
  END GetCreditLineFromCorpLevel;
  --
  --
  ----------------------------------------------------------------------------------------
  -- Retorna o Codigo do Usuario a partir do Codigo do Gestor
  ----------------------------------------------------------------------------------------
  FUNCTION GetUserFromManager RETURN NUMBER IS
    --
    vUser             PTC_GST.CD_USU%TYPE;
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'GetUserFromManager');
    --
    BEGIN
      --
      SELECT MAX(G.CD_USU)
        INTO vUser
        FROM PTC_GST G,
             PTC_BAS B, 
             PTC_CLI C 
       WHERE B.CD_BAS = vCD_BAS 
         AND B.CD_CLI = C.CD_CLI 
         AND C.CD_CSL = G.CD_CSL 
         AND G.CD_GST = vCD_GST;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --
        vUser := NULL;
        --
    END;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
    RETURN vUser;
    --
  END GetUserFromManager;
  --
  --
  ----------------------------------------------------------------------------------------
  -- Retorna o Codigo do Contrato Cliente a partir do Codigo da Base
  ----------------------------------------------------------------------------------------
  FUNCTION GetContractIDFromCL RETURN NUMBER IS
    --
    vClientContract   PTC_CTR_CLI.CD_CTR_CLI%TYPE;
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'GetContractIDFromCL');
    --
    BEGIN
      --
      SELECT CC.CD_CTR_CLI
        INTO vClientContract
        FROM PTC_BAS     BAS,
             PTC_CTR_CLI CC
       WHERE BAS.CD_CLI = CC.CD_CLI
         AND BAS.CD_BAS = vCD_BAS;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --
        vClientContract := NULL;
        --
    END;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
    RETURN vClientContract;
    --
  END GetContractIDFromCL;
  --
  --
  ----------------------------------------------------
  -- Procedure processamento da(s) linha(s) de detalhe do pedido de distribuição
  ----------------------------------------------------
  PROCEDURE ProcessarRegistro IS
    --
    vTrack VARCHAR2(500);
    --
    vUserMessage   VARCHAR2(1000);
    vReturnCode    NUMBER;
    vReturnMessage VARCHAR2(1000);
    vMessageType  VARCHAR2(500);
    vItemIndex    INT;
    --
    vCD_PDT_LIN_CRD PTC_PDT_SVC_LIN_CDT_SNN.CD_PDT_LIN_CRD%TYPE;
    vCUR_ERR  T_CURSOR;
    --
    vNU_TRF_SNN NUMBER;
    vVL_SLD_BAS NUMBER;
    vCUR_OUT T_CURSOR;
    vCOD_RET NUMBER;
    vTP_ACA VARCHAR2(100);
    vVL_TOT_PED NUMBER;
    --
  BEGIN
    --
    IF NVL(vFinancialInd, 'F') = 'T' THEN
      --
      -- Criacao do Pedido na WEM
      --
      vTrack := 'WTMX_ORDER_PKG.CreditDistribuctionCreate()';
      --
      WTMX_ORDER_PKG.CreditDistribuctionCreate(
        PNU_PED => vNU_PED, 
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
        PMSG_USER => vUserMessage, 
        PCOD_RET => vReturnCode, 
        PMSG_RET => vReturnMessage
      );
      --
      IF NVL(vReturnCode, 0) <> 0 THEN
        RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
      END IF;
      --
      --
    END IF;
    --
    IF WT2MX_MASSIVELOAD_MNG.gFile.TP_ACA = 'V' THEN
      vTP_ACA := 'VALIDATE';
    ELSE
      vTP_ACA := 'APPLY';
    END IF; 
    --
    vVL_TOT_PED := GetValorTotalPedido();
    --
    IF vCD_TIP_PED = 11 THEN
      --
      --
      -- Criando Pedido para base e distribuição de crédito
      --
      vTrack := 'WT2MX_SNN_ACCOUNTCORPLEVEL_INT.OrderCreditCorpLevelAcct()';
      --
      vCD_PDT_LIN_CRD := GetProdCreditLineFromCorpLevel(vCD_BAS);
      --
      WT2MX_SNN_ACCOUNTCORPLEVEL_INT.OrderCreditCorpLevelAcct(
        pCD_GST         => vCD_GST,
        pNU_CTR         => vContrato,
        pNU_PED         => vNU_PED,
        pNU_PED_EXT     => vExtPed,
        pDT_AGD         => vDt_Agd,
        pCD_MOE         => vCurrency,
        pCD_PDT_LIN_CRD => vCD_PDT_LIN_CRD,
        pDS_PRI         => 'NORMAL',
        pCD_BAS         => vCD_BAS,
        pVL_PED_BAS     => vVL_PED_FIN_BAS,
        pID_MSG         => NULL,
        pID_REQ         => NULL,
        pCOD_RET        => vReturnCode,
        CUR_ERR         => vCUR_ERR
      );
      --
      IF NVL(vReturnCode,0) <> 0 THEN
        -- validar cursor de erros
        FETCH vCUR_ERR INTO vUserMessage, vMessageType, vReturnMessage, vItemIndex;
        --
        vReturnCode:= NVL(WTMX_UTILITY_PKG.GetSunnelError(vReturnMessage, 18), 2109);

        CLOSE vCUR_ERR;
        --      
        RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
        --
      END IF;
      --
      vTrack := 'WT2MX_SNN_ACCOUNTCORPLEVEL_INT.DistribToCardHoldersCustMngr()';
      --
      WT2MX_SNN_ACCOUNTCORPLEVEL_INT.DistribToCardHoldersCustMngr(
        pCD_GST         => vCD_GST,
        pCD_CTR_CLI     => vContrato,
        pCD_BAS         => vCD_BAS,
        pCD_TP_LIN_CRD  => vProductCreditLineTypeID,
        pDT_AGD         => vDt_Agd,
        pCD_MOE         => vCurrency,
        pTP_ACA         => vTP_ACA,
        pVL_TOT_PED     => vVL_TOT_PED,
        pNU_PED         => vNU_PED,
        pNU_PED_EXT     => vExtPed,
        pVL_PED_BAS     => vVL_PED_FIN_BAS,
        pCardHolderList => vItemDist,
        pID_MSG         => NULL,
        pID_REQ         => NULL,
        pNU_TRF_SNN     => vNU_TRF_SNN,
        pVL_SLD_BAS     => vVL_SLD_BAS,
        CUR_OUT         => vCUR_OUT,
        pCOD_RET        => vCOD_RET,
        CUR_ERR         => vCUR_ERR
      );
      --
      IF NVL(vReturnCode,0) <> 0 THEN
        -- validar cursor de erros
        FETCH vCUR_ERR INTO vUserMessage, vMessageType, vReturnMessage, vItemIndex;
        --
        vReturnCode:= NVL(WTMX_UTILITY_PKG.GetSunnelError(vReturnMessage, 18), 2109);

        CLOSE vCUR_ERR;
        --      
        RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
        --
      END IF;
      --
    ELSIF vCD_TIP_PED = 2 THEN
      --
      --
      -- Criando Distribuição de crédito
      --
      vTrack := 'WT2MX_SNN_ACCOUNTCORPLEVEL_INT.DistribToCardHoldersCustMngr()';
      --
      WT2MX_SNN_ACCOUNTCORPLEVEL_INT.DistribToCardHoldersCustMngr(
        pCD_GST         => vCD_GST,
        pCD_CTR_CLI     => vContrato,
        pCD_BAS         => vCD_BAS,
        pCD_TP_LIN_CRD  => vProductCreditLineTypeID,
        pDT_AGD         => vDt_Agd,
        pCD_MOE         => vCurrency,
        pTP_ACA         => vTP_ACA,
        pVL_TOT_PED     => vVL_TOT_PED,
        pNU_PED         => vNU_PED,
        pNU_PED_EXT     => vExtPed,
        pVL_PED_BAS     => vVL_PED_FIN_BAS,
        pCardHolderList => vItemDist,
        pID_MSG         => NULL,
        pID_REQ         => NULL,
        pNU_TRF_SNN     => vNU_TRF_SNN,
        pVL_SLD_BAS     => vVL_SLD_BAS,
        CUR_OUT         => vCUR_OUT,
        pCOD_RET        => vCOD_RET,
        CUR_ERR         => vCUR_ERR
      );
      --
      IF NVL(vReturnCode,0) <> 0 THEN
        -- validar cursor de erros
        FETCH vCUR_ERR INTO vUserMessage, vMessageType, vReturnMessage, vItemIndex;
        --
        vReturnCode:= NVL(WTMX_UTILITY_PKG.GetSunnelError(vReturnMessage, 18), 2109);

        CLOSE vCUR_ERR;
        --      
        RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
        --
      END IF;
      --      
    ELSIF vCD_TIP_PED = 12 THEN  
      --
      --
      -- Criando Recolhimento
      --
      vTrack := 'WT2MX_SNN_ACCOUNTCORPLEVEL_INT.CrDistributionToCorpLevelAcc()';
      --
      WT2MX_SNN_ACCOUNTCORPLEVEL_INT.CrDistributionToCorpLevelAcc(
        pCD_GST         => vCD_GST,
        pCD_CTR_CLI     => vContrato,
        pCD_BAS         => vCD_BAS,
        pCD_TP_LIN_CRD  => vProductCreditLineTypeID,
        pDT_AGD         => vDt_Agd,
        pCD_MOE         => vCurrency,
        pTP_ACA         => vTP_ACA,
        pVL_TOT_PED     => vVL_TOT_PED,
        pNU_PED         => vNU_PED,
        pCardHolderList => vItemDist,
        pNU_TRF_SNN     => vNU_TRF_SNN,
        pVL_SLD_BAS     => vVL_SLD_BAS,
        CUR_OUT         => vCUR_OUT,
        pCOD_RET        => vCOD_RET,
        CUR_ERR         => vCUR_ERR
      );
      --
      IF NVL(vReturnCode,0) <> 0 THEN
        -- validar cursor de erros
        FETCH vCUR_ERR INTO vUserMessage, vMessageType, vReturnMessage, vItemIndex;
        --
        vReturnCode:= NVL(WTMX_UTILITY_PKG.GetSunnelError(vReturnMessage, 18), 2109);

        CLOSE vCUR_ERR;
        --      
        RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
        --
      END IF;
      --    
    END IF;
    --
    --    
  EXCEPTION
    WHEN OTHERS THEN
      --
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      IF NVL(vReturnCode, 0) <> 0 THEN
         WT2MX_MASSIVELOAD_MNG.ProcessError(
          pErrorCode  => vReturnCode, 
          pErrorMessage => vReturnMessage,
          pAuxMessage => 'Erro ao ' || vTrack ||': ' ||NVL(vUserMessage, vReturnCode), 
          pErrorType  => 'ERR',
          pErrorLevel => 'REG'
        );  
      ELSE                                   
        WT2MX_MASSIVELOAD_MNG.ProcessError(
          pErrorCode   => 182190, 
          pAuxMessage => 'Erro ao ' || vTrack ||': ' ||SQLERRM, 
          pErrorType  => 'EXC',
          pErrorLevel => 'REG'
        );   
      END IF;                                    
      --
  END ProcessarRegistro;
  --   
  --
  ----------------------------------------------------
  -- Procedure processamento do header do arquivo
  ----------------------------------------------------
  PROCEDURE FileHeader IS
    --
    vTrack         VARCHAR2(500);
    --
    vUserMessage   VARCHAR2(500);
    vReturnCode    NUMBER;
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'FileHeader');
    --
    -- Valida a Descricao da Interface no Header
    vTrack:= 'validar descricao da interface no header';
    vReturnCode := WT2MX_MASSIVELOAD_MNG.ValidateInterfaceName('INT1027.17 - DISPERSION DE CREDITOS');
    --
    IF NVL(vReturnCode, 0) <> 0 THEN
      RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
      --
    END IF;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION
    WHEN OTHERS THEN  
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      IF NVL(vReturnCode,0) <> 0 THEN
         WT2MX_MASSIVELOAD_MNG.ProcessError(
          pErrorCode  => vReturnCode, 
          pAuxMessage => 'Erro ao ' || vTrack ||': ' ||NVL(vUserMessage, vReturnCode), 
          pErrorType  => 'ERR',
          pErrorLevel => 'ARQ'
        );  
      ELSE                                   
        WT2MX_MASSIVELOAD_MNG.ProcessError(
          pErrorCode   => 182548, 
          pAuxMessage => 'Erro ao ' || vTrack ||': ' ||SQLERRM, 
          pErrorType  => 'EXC',
          pErrorLevel => 'ARQ'
        );   
      END IF;                                    
      --
  END FileHeader;
  --
  --
  ----------------------------------------------------
  -- Procedure processamento da linha de autenticação do arquivo
  ----------------------------------------------------
  PROCEDURE FileAutentication IS
    --
    vTrack         VARCHAR2(500);
    --
    vUserMessage   VARCHAR2(500);
    vReturnCode    NUMBER;
    vReturnMessage VARCHAR2(500);
    --    
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'FileAutentication');
    --
    --
    vCD_GST := WT2MX_MASSIVELOAD_MNG.gValores('Manager').NumberValue;
    vCD_BAS := WT2MX_MASSIVELOAD_MNG.gValores('Base').NumberValue;
    vCreditLineType := GetCreditLineFromCorpLevel;
    --
    -- Verificac?o da Abrangencia do Gestor
    --
    vTrack := 'Verificação da abrangência do Gestor - WTMX_CORPORATELEVEL_PKG.ManagerHierarchyValidate()';
    --
    WTMX_CORPORATELEVEL_PKG.ManagerHierarchyValidate(
      pCD_CSL         => NULL,
      pCD_CLI         => NULL,
      pCD_BAS         => vCD_BAS,
      pCD_CTR_CLI     => NULL,
      pCD_GST         => vCD_GST,
      pCD_USU         => NULL,
      pCD_HIE_ETD     => NULL,
      pCD_GST_RET     => vCD_GST_RET,
      pCD_TIP_GST_RET => vCD_TIP_GST,
      pCD_CSL_RET     => vCD_CSL,
      pMSG_USER       => vUserMessage,
      pCOD_RET        => vReturnCode,
      pMSG_RET        => vReturnMessage
    );
    --
    IF NVL(vReturnCode, 0) <> 0 THEN
      RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
    END IF;
    --
    --
    vCD_USU_SOL := GetUserFromManager;
    vContrato := GetContractIDFromCL;
    --             
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION  
    WHEN OTHERS THEN
     --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      IF NVL(vReturnCode,  0) <> 0 THEN
         WT2MX_MASSIVELOAD_MNG.ProcessError(
          pErrorCode  => vReturnCode, 
          pAuxMessage => 'Erro ao ' || vTrack ||': ' ||NVL(vUserMessage, vReturnCode), 
          pErrorType  => 'ERR',
          pErrorLevel => 'ARQ'
        );  
      ELSE                                   
        WT2MX_MASSIVELOAD_MNG.ProcessError(
          pErrorCode   => 182190, 
          pAuxMessage => 'Erro ao ' || vTrack ||': ' ||SQLERRM, 
          pErrorType  => 'EXC',
          pErrorLevel => 'ARQ'
        );   
      END IF;                                    
      -- 
  END FileAutentication;
  --
  --
  ----------------------------------------------------
  -- Procedure processamento do cabeçalho do pedido de distribuição
  ----------------------------------------------------
  PROCEDURE ProcessarCabecalhoPedidoDist IS
    --
    vTrack         VARCHAR2(500);
    --
    vUserMessage   VARCHAR2(500);
    vReturnCode    NUMBER;
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'ProcessarDetalheDistribuicao');
    --
    vExtPed := WT2MX_MASSIVELOAD_MNG.gValores('NroPedido').NumberValue;
    vDt_Agd := WT2MX_MASSIVELOAD_MNG.gValores('DataPedido').DateValue;
    vVL_PED_FIN_BAS := WT2MX_MASSIVELOAD_MNG.gValores('ValorPedido').NumberValue;
    vQT_ITE_PED := WT2MX_MASSIVELOAD_MNG.gValores('QtdItens').NumberValue;

    vCD_TIP_PED := WT2MX_MASSIVELOAD_MNG.gValores('IndPedCredito').StringValue;

    IF vCD_TIP_PED = 1 THEN
      vCD_TIP_PED := 11; -- Pedido para base e distribuic?o de credito
    ELSIF vCD_TIP_PED = 2 THEN
      vCD_TIP_PED := 2;  -- Somente distribuic?o de credito
    ELSIF vCD_TIP_PED = 3 THEN  
      vCD_TIP_PED := 12;  -- Recolhimento              
    END IF;
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --  
  EXCEPTION
    WHEN OTHERS THEN
     --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      IF NVL(vReturnCode,  0) <> 0 THEN
         WT2MX_MASSIVELOAD_MNG.ProcessError(
          pErrorCode  => vReturnCode, 
          pAuxMessage => 'Erro ao ' || vTrack ||': ' ||NVL(vUserMessage, vReturnCode), 
          pErrorType  => 'ERR',
          pErrorLevel => 'ARQ'
        );  
      ELSE                                   
        WT2MX_MASSIVELOAD_MNG.ProcessError(
          pErrorCode   => 182190, 
          pAuxMessage => 'Erro ao ' || vTrack ||': ' ||SQLERRM, 
          pErrorType  => 'EXC',
          pErrorLevel => 'ARQ'
        );   
      END IF;                                    
      --   
  END ProcessarCabecalhoPedidoDist;
  --
  --
  ----------------------------------------------------
  -- Procedure processamento da(s) linha(s) de detalhe do pedido de distribuição
  ----------------------------------------------------
  PROCEDURE ProcessarDetalheDistribuicao IS
    --
    vTrack         VARCHAR2(500);
    --
    vUserMessage   VARCHAR2(500);
    vReturnCode    NUMBER;
    --
    vCurOut T_CURSOR;
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'ProcessarDetalheDistribuicao');
    --
    vReturnCode := NULL;

    vCard := WT2MX_MASSIVELOAD_MNG.gValores('NroCartao').StringValue;
    vTagNfcId := WT2MX_MASSIVELOAD_MNG.gValores('TagNfcId').StringValue; -- 1.22
    vTagNfcNum := WT2MX_MASSIVELOAD_MNG.gValores('TagNfcNum').StringValue;  -- 1.25
    --
    --
    -- 1.22 / 1.25 inicio
    -- Se CARD_NUMBER não for informado, obter o cartão ativo a partir dos novos campos 
    -- (TAG_NUMERICA ou TAG_HEXADECIMAL)
    GetCardFromTagNFC(
      PNU_CARD    => vCard,     
      PID_TAG_NFC => vTagNfcId,
      PNU_TAG_NFC => vTagNfcNum,
      pCOD_RET    => vReturnCode
    );
    --
    vTrack := 'Se CARD_NUMBER não for informado pegar TAG_NUMERICA ou TAG_HEXADECIMAL - GetCardFromTagNFC';
    --
    IF NVL(vReturnCode, 0) <> 0 THEN
      -- Manager incompatible with hierarchy
      RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
      --
    END IF;
    --
    -- 1.22 / 1.25 fim
    --
    vValue := NVL(WT2MX_MASSIVELOAD_MNG.gValores('Valor').NumberValue, 0);
    vCreditType := WT2MX_MASSIVELOAD_MNG.gValores('TpCredito').NumberValue;              
    --
    IF NVL(WT2MX_MASSIVELOAD_MNG.gFile.IN_VLD_DUP, 'F') = 'T' THEN
      --
      -- verifica duplicidade
      --
      vTrack := 'Numero do cartão duplicado no arquivo';
      --
      IF DBMS_LOB.instr(vItemDist, vCard) > 0 THEN
        --
        vReturnCode := 182589;  -- Numero do cart?o duplicado no arquivo
        RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
        --
      END IF;
      --
    END IF;
    --
    IF NVL(vReturnCode, 0) = 0 THEN
      --
      -- valida cartao
      BEGIN 
        SELECT CAT.CD_TIP_CAT
          INTO vCardType
        FROM PTC_CAT   CAT
        WHERE CAT.NU_CAT = vCard;
      EXCEPTION -- 1.01
        WHEN NO_DATA_FOUND THEN
          vReturnCode := 182297;
          RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
      END; 
      --
      IF vCardType = 4 THEN  -- Caso seja cart?o estoque deve recuperar o cart?o de operac?o
        --
        -- Busca o cart?o de operac?o do cart?o informado (quando houver)
        WTMX_CARD_PKG.CardGetOperationCardList(
          CARDLIST  => vCard,
          STARTPAGE => NULL,
          PAGEROWS  => NULL,
          CUR_OUT   => vCurOut
        );
        --
        FETCH vCurOut INTO vCardOperationList;
        --
        vTrack := 'Cartão inválido - Cartão de estoque deve recuperar o cartão da operação';
        --
        IF vCardOperationList.NU_CAT_OPE IS NOT NULL THEN
          --
          vCard := vCardOperationList.NU_CAT_OPE;
          --
        ELSE
          --
          vReturnCode := 180716;
          RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
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
      vTrack := 'OperationClass = BYPASS';
      --
      IF vCD_TIP_PED = 12 THEN -- 1.15
        vOperationClass := 'PICKINGUP';
      ELSE  
        --
        IF  vValue > 0 AND vCardStatus IS NOT NULL THEN -- 1.12 ref. vCardStatus
          --
          vOperationClass := 'DISBURSEMENT';
          --
          vTrack := 'Status do Cartão 6';
          --
          IF vCardStatus = 6 THEN
            --
            vReturnCode := 182465;
            RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
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
          vReturnCode := 180491;
          RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
          -- 1.17 (fim)
        END IF;
        --
      END IF;
      --
    END IF;
    --
    IF NVL(vReturnCode, 0) = 0 AND vOperationClass <> 'BYPASS' THEN
      --
      vFinancialInd := 'T';
      --
      vCreditType := WT2MX_MASSIVELOAD_MNG.gValores('TpCredito').NumberValue;
      vUnitType := NVL(WT2MX_MASSIVELOAD_MNG.gValores('TpDistribuicao').NumberValue, 1); -- 1.14
      vMerchandise := WT2MX_MASSIVELOAD_MNG.gValores('Mercadoria').NumberValue;
      vMerchQuantity := WT2MX_MASSIVELOAD_MNG.gValores('QtdMercadoria').NumberValue;
      vMerchPrice := WT2MX_MASSIVELOAD_MNG.gValores('PrecoMercadoria').NumberValue;
      vAdditionalInfo := WT2MX_MASSIVELOAD_MNG.gValores('Obs').StringValue;
      vExpirationDate := WT2MX_MASSIVELOAD_MNG.gValores('DtExpiracao').DateValue;
      vCardBalance := WT2MX_MASSIVELOAD_MNG.gValores('SaldoCartao').NumberValue;
      vRoute := WT2MX_MASSIVELOAD_MNG.gValores('Rota').StringValue;
      vCurrency := WTMX_MASSIVELOAD_PKG.GetCurrencyIDParameter();
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
      vKM_Quantity := WT2MX_MASSIVELOAD_MNG.gValores('QtdKM').NumberValue; -- 1.14
      vNU_RND := WT2MX_MASSIVELOAD_MNG.gValores('Rendimento').NumberValue; -- 1.14    
      --

      -- Valida infors x tipo NV -- 1.14
      --
      vTrack := 'Valida infors x tipo NV';
      --      
      IF (vUnitType = 1 AND  (vKM_Quantity IS NOT NULL OR vNU_RND IS NOT NULL)) OR
          (vUnitType = 2 AND  (vMerchandise IS NULL OR vMerchQuantity IS NULL OR vMerchPrice IS NULL OR vKM_Quantity IS NOT NULL OR vNU_RND IS NOT NULL)) OR
          (vUnitType = 3 AND  (vMerchandise IS NULL OR vMerchPrice IS NULL OR vKM_Quantity IS NULL OR vNU_RND IS NULL)) THEN
          --
          vReturnCode := 183046;
          RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
          --                  
      END IF;

      -- Valida se portador NÃO está associado a uma controle de Nota Vale
      --
      vTrack := 'Valida se portador NÃO está associado a uma controle de Nota Vale';
      --
      IF WT_ORDER_PKG.ISCardHolderPreAutorization(NULL, vCardHolder) = 'T' THEN -- 1.13
        --                  
        vReturnCode := 182542; -- Cardholder is associated a PreAuthorization CardGroup
        RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
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
        vItemDist := vItemDist || '|';
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
    END IF;
    --
    vReturnCode := NULL;
    -- vFinancialInd := NULL; -- 1.01
    --
    --
    ---------------------------------------------------------
    vTrack:= 'verificar se é ultima linha do registro detalhe';
    --
    IF WT2MX_MASSIVELOAD_MNG.RegisterLastLine(PNU_REG => WT2MX_MASSIVELOAD_MNG.gFile.NU_REG) = WT2MX_MASSIVELOAD_MNG.gFile.NU_REG THEN
      --
      vTrack := 'chamar procedure ProcessarRegistro';
      --
      ProcessarRegistro;
      --
    END IF;
    ---------------------------------------------------------
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --     
  EXCEPTION
    WHEN OTHERS THEN
     --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      IF NVL(vReturnCode,0) <> 0 THEN
         WT2MX_MASSIVELOAD_MNG.ProcessError(
          pErrorCode  => vReturnCode, 
          pAuxMessage => 'Erro ao ' || vTrack ||': ' ||NVL(vUserMessage, vReturnCode), 
          pErrorType  => 'ERR',
          pErrorLevel => 'ARQ'
        );
      ELSE                                   
        WT2MX_MASSIVELOAD_MNG.ProcessError(
          pErrorCode   => 182190, 
          pAuxMessage => 'Erro ao ' || vTrack ||': ' ||SQLERRM, 
          pErrorType  => 'EXC',
          pErrorLevel => 'ARQ'
        );   
      END IF;                                    
      -- 
  END ProcessarDetalheDistribuicao;

END WT2MX_MSS_CREDIT_ORDER_PKG;