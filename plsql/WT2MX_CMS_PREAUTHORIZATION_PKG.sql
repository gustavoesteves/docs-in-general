CREATE OR REPLACE PACKAGE BODY WT2MX_CMS_PREAUTHORIZATION_PKG  IS
  -- *********************
  -- * INTERNAL TYPES    *
  -- *********************
  -- 
  --
  -- *********************
  -- * VARIAVEIS GLOBAIS *
  -- *********************
  --
  vModule               VARCHAR2(100);
  vAction               VARCHAR2(100);
  --
  --
  -- *********************
  -- *  METHODS          *
  -- *********************
   
  ----------------------------------------------------
  -- Procedure processamento do header do arquivo
  ----------------------------------------------------
  PROCEDURE FileHeader IS
    --
    vUserMessage   VARCHAR2(500);
    vReturnCode    NUMBER;
    vTrack         VARCHAR2(500);
    --    
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'FileHeader');
    --
    -- Valida a Descricao da Interface no Header
    vTrack:= 'validar descricao da interface no header';
    vReturnCode := WT2MX_MASSIVELOAD_MNG.ValidateInterfaceName('INT1038.154 - NOTA VALE');
    --
    IF vReturnCode > 0 THEN
      --RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
      RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
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
      IF NVL(vReturnCode,0) <> 0 THEN
         WT2MX_MASSIVELOAD_MNG.ProcessError(pErrorCode  => vReturnCode, 
                                     pAuxMessage => 'Erro ao ' || vTrack ||': ' ||NVL(vUserMessage, vReturnCode), 
                                     pErrorType  => 'ERR',
                                     pErrorLevel => 'ARQ');  
      ELSE                                   
        WT2MX_MASSIVELOAD_MNG.ProcessError(pErrorCode   => 182190, 
                                          pAuxMessage => 'Erro ao ' || vTrack ||': ' ||SQLERRM, 
                                          pErrorType  => 'EXC',
                                          pErrorLevel => 'ARQ');   
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
    vUserMessage   VARCHAR2(500);
    vReturnCode    NUMBER;
    vReturnMessage VARCHAR2(500);
    vTrack         VARCHAR2(500);
    --    
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'FileAutentication');
    --
    --
    -- Verificação da Abrangencia do Gestor
    vTrack:= 'validar hierarquia (linha de autenticação)';
    WTMX_CORPORATELEVEL_PKG.ManagerHierarchyValidate(pCD_CSL         => NULL,
                                                     pCD_CLI         => NULL,
                                                     pCD_BAS         => WT2MX_MASSIVELOAD_MNG.gValores('Base').NumberValue,
                                                     pCD_CTR_CLI     => NULL,
                                                     pCD_GST         => WT2MX_MASSIVELOAD_MNG.gValores('Manager').NumberValue,
                                                     pCD_USU         => NULL,
                                                     pCD_HIE_ETD     => NULL,
                                                     pCD_GST_RET     => WT2MX_MASSIVELOAD_MNG.gValores('Manager').NumberValue,
                                                     pCD_TIP_GST_RET => WT2MX_MASSIVELOAD_MNG.gValores('CD_TIP_GST').NumberValue,
                                                     pCD_CSL_RET     => WT2MX_MASSIVELOAD_MNG.gValores('CD_CSL').NumberValue,
                                                     pMSG_USER       => vUserMessage,
                                                     pCOD_RET        => vReturnCode,
                                                     pMSG_RET        => vReturnMessage);
    --
    IF NVL(vReturnCode, 0) <> 0 THEN
      -- Manager incompatible with hierarchy
      RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
      --
    END IF;
    --
    -- Obtem o Contrato
    vTrack:= 'obter contrato';
    --
    BEGIN
      SELECT CC.CD_CTR_CLI
        INTO WT2MX_MASSIVELOAD_MNG.gValores('CD_CTR_CLI').NumberValue
        FROM PTC_CTR_CLI CC, PTC_CLI C, PTC_BAS B, PTC_GST G
       WHERE B.CD_BAS = WT2MX_MASSIVELOAD_MNG.gValores('Base').NumberValue
         AND B.CD_CLI = C.CD_CLI
         AND C.CD_CSL = G.CD_CSL
         AND G.CD_GST = WT2MX_MASSIVELOAD_MNG.gValores('Manager').NumberValue
         AND C.CD_CLI = CC.CD_CLI;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --
        vReturnCode := 182257;
        RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
        --
    END;    
    --
    -- Obtem o usuario
    vTrack:= 'obter usuario';
    --
    SELECT MAX(GST.CD_USU)
     INTO WT2MX_MASSIVELOAD_MNG.gValores('CD_USU_SOL').NumberValue
     FROM PTC_GST GST
    WHERE GST.CD_GST = WT2MX_MASSIVELOAD_MNG.gValores('Manager').NumberValue
      AND GST.CD_CSL = WT2MX_MASSIVELOAD_MNG.gValores('CD_CSL').NumberValue;
    --
    --                  
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
  EXCEPTION  
    WHEN OTHERS THEN
     --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      IF NVL(vReturnCode,0) <> 0 THEN
         WT2MX_MASSIVELOAD_MNG.ProcessError(pErrorCode  => vReturnCode, 
                                     pAuxMessage => 'Erro ao ' || vTrack ||': ' ||NVL(vUserMessage, vReturnCode), 
                                     pErrorType  => 'ERR',
                                     pErrorLevel => 'ARQ');  
      ELSE                                   
        WT2MX_MASSIVELOAD_MNG.ProcessError(pErrorCode   => 182190, 
                                          pAuxMessage => 'Erro ao ' || vTrack ||': ' ||SQLERRM, 
                                          pErrorType  => 'EXC',
                                          pErrorLevel => 'ARQ');   
      END IF;                                    
      --     
  END;
  --
  PROCEDURE ProcessarRegistroNV IS
    --
    vTrack         VARCHAR2(500);
    --
    vUserMessage     VARCHAR2(1000);
    vReturnCode      NUMBER;
    vReturnMessage   VARCHAR2(1000);
    --   
    vCD_OPE_DEB           NUMBER;
    vCD_OPE_CRD           NUMBER;
    vCUR_ERR              T_CURSOR;
    vMessageType  VARCHAR2(500);
    vItemIndex    INT;

    --
  BEGIN
    --
    vTrack:= 'chamar WT2MX_SNN_ACCOUNTCORPLEVEL_INT.CreatePreAuthorization ('||WT2MX_MASSIVELOAD_MNG.gFile.NU_REG ||')';
    --
    WT2MX_SNN_ACCOUNTCORPLEVEL_INT.CreatePreAuthorization
            (pCD_CTR_CLI        => WT2MX_MASSIVELOAD_MNG.gValores('CD_CTR_CLI').NumberValue, 
             pCD_BAS            => WT2MX_MASSIVELOAD_MNG.gValores('Base').NumberValue, 
             pCD_GST            => WT2MX_MASSIVELOAD_MNG.gValores('Manager').NumberValue, 
             pCD_MOE            => 484, 
             pCD_PTD            => WT2MX_MASSIVELOAD_MNG.gValores('CD_PTD').NumberValue,
             pCD_TIP_LIN_CDT    => 1, 
             pDT_HR_INI_VIG     => WT2MX_MASSIVELOAD_MNG.gValores('IniVig').DateValue,
             pDT_HR_FIM_VIG     => WT2MX_MASSIVELOAD_MNG.gValores('FimVig').DateValue,
             pVL_TOT_INF        => WT2MX_MASSIVELOAD_MNG.gValores('ValorNV').NumberValue,
             pNU_MAX_OPE        => WT2MX_MASSIVELOAD_MNG.gValores('QtdUsos').NumberValue, 
             pVL_MIN            => WT2MX_MASSIVELOAD_MNG.gValores('VlrMinCancel').NumberValue, 
             pIN_RST_ETB        => 'F' ,-- MERCHANTRESTRICTIONIND
             pDS_CLS_ETB        => NULL, -- PRIVATEACCPTRESTRICT / SPECIFICMERCHANT
             pCD_SUB_RED        => WT2MX_MASSIVELOAD_MNG.gValores('CdRedRestrita').NumberValue, 
             pMerchContractList => WT2MX_MASSIVELOAD_MNG.gValores('MerchContractLt').ClobValue,
             pCD_PAT            => WT2MX_MASSIVELOAD_MNG.gValores('CD_PAT').NumberValue, -- out
             pCD_OPE_DEB        => vCD_OPE_DEB, 
             pCD_OPE_CRD        => vCD_OPE_CRD, 
             pCOD_RET           => vReturnCode, 
             CUR_ERR            => vCUR_ERR); -- OUT T_CURSOR

    --
    IF NVL(vReturnCode,0) <> 0 THEN
      -- validar cursor de erros
      FETCH vCUR_ERR INTO vUserMessage, vMessageType, vReturnMessage, vItemIndex;
      --
      vReturnCode:= NVL(WTMX_UTILITY_PKG.GetSunnelError(vReturnMessage ,18),2109);

      CLOSE vCUR_ERR;
      --      
      RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
      --
    END IF;
    --
    vTrack:= 'chamar WT2MX_PREAUTHORIZATION_MNT.PreAuthorizationOrderCreate ('||WT2MX_MASSIVELOAD_MNG.gFile.NU_REG ||')';
    --
    WT2MX_PREAUTHORIZATION_MNT.PreAuthorizationOrderCreate
                        ( pNU_PED               => WT2MX_MASSIVELOAD_MNG.gValores('NU_PED').NumberValue, 
                          pCD_PAT               => WT2MX_MASSIVELOAD_MNG.gValores('CD_PAT').NumberValue,
                          pCD_USU_SOL           => WT2MX_MASSIVELOAD_MNG.gValores('CD_USU_SOL').NumberValue,
                          pCD_BAS               => WT2MX_MASSIVELOAD_MNG.gValores('Base').NumberValue,
                          pCD_TIP_PAT           => WT2MX_MASSIVELOAD_MNG.gValores('TpNV').NumberValue,
                          pDT_HR_INI_VIG        => WT2MX_MASSIVELOAD_MNG.gValores('IniVig').DateValue,
                          pDT_HR_FIM_VIG        => WT2MX_MASSIVELOAD_MNG.gValores('FimVig').DateValue,
                          pNU_MAX_OPE           => WT2MX_MASSIVELOAD_MNG.gValores('QtdUsos').NumberValue, 
                          pVL_TOT_INF           => WT2MX_MASSIVELOAD_MNG.gValores('ValorNV').NumberValue,
                          pVL_MIN_CAN_AUT       => WT2MX_MASSIVELOAD_MNG.gValores('VlrMinCancel').NumberValue, 
                          pNU_PCT_MIN_CAN_AUT   => WT2MX_MASSIVELOAD_MNG.gValores('PctMinCancel').NumberValue,
                          pCD_VGE               => WT2MX_MASSIVELOAD_MNG.gValores('CdViagem').NumberValue,
                          pCD_PTD               => WT2MX_MASSIVELOAD_MNG.gValores('CD_PTD').NumberValue,
                          pCD_TRJ               => WT2MX_MASSIVELOAD_MNG.gValores('CdTrajeto').NumberValue,
                          pDC_OBS               => WT2MX_MASSIVELOAD_MNG.gValores('DsNV').StringValue,
                          pCD_GST               => WT2MX_MASSIVELOAD_MNG.gValores('Manager').NumberValue,
                          pTP_CSM               => WT2MX_MASSIVELOAD_MNG.gValores('TP_CSM').StringValue,
                          pMerchandiseList      => WT2MX_MASSIVELOAD_MNG.gValores('MerchandiseList').StringValue,
                          pDriverList           => WT2MX_MASSIVELOAD_MNG.gValores('DriverList').StringValue,
                          pRestrictionList      => WT2MX_MASSIVELOAD_MNG.gValores('RestrictionList').StringValue,
                          pNU_PED_EXT           => WT2MX_MASSIVELOAD_MNG.gValores('NuPedExt').StringValue,
                          pUSER                 => NULL,
                          pIP                   => 'MASSIVELOAD',
                          PMSG_USER             => vUserMessage,
                          PCOD_RET              => vReturnCode,
                          PMSG_RET              => vReturnMessage);
    --
    IF NVL(vReturnCode, 0) <> 0 THEN
      --
      IF vReturnCode = -1 THEN
        vReturnCode:= NVL(WTMX_UTILITY_PKG.GetSunnelError(vReturnMessage ,18),2109);
      END IF;
      --  
      RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
      --
    END IF;
    --
    --
    -- Associar pedido ao arquivo
    --
    vTrack:= 'adicionar campos retornados das rotinas dbapi';
    --
    WT2MX_MASSIVELOAD_MNG.AddFieldResponse(PNU_REG     => WT2MX_MASSIVELOAD_MNG.gValores('NU_REG_MASTER').NumberValue, 
                                           PDS_RTL_CTD => 'NU_PED', 
                                           PCONTEUDO   => WT2MX_MASSIVELOAD_MNG.gValores('NU_PED').NumberValue);
    --    
    WT2MX_MASSIVELOAD_MNG.AddFieldResponse(PNU_REG     => WT2MX_MASSIVELOAD_MNG.gValores('NU_REG_MASTER').NumberValue, 
                                           PDS_RTL_CTD => 'CD_PAT', 
                                           PCONTEUDO   => WT2MX_MASSIVELOAD_MNG.gValores('CD_PAT').NumberValue);
    --
    --
  EXCEPTION  
    WHEN OTHERS THEN
      --
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      IF NVL(vReturnCode,0) <> 0 THEN
         WT2MX_MASSIVELOAD_MNG.ProcessError(pErrorCode  => vReturnCode, 
                                     pErrorMessage => vReturnMessage,
                                     pAuxMessage => 'Erro ao ' || vTrack ||': ' ||NVL(vUserMessage, vReturnCode), 
                                     pErrorType  => 'ERR',
                                     pErrorLevel => 'REG');  
      ELSE                                   
        WT2MX_MASSIVELOAD_MNG.ProcessError(pErrorCode   => 182190, 
                                          pAuxMessage => 'Erro ao ' || vTrack ||': ' ||SQLERRM, 
                                          pErrorType  => 'EXC',
                                          pErrorLevel => 'REG');   
      END IF;                                    
      --   

      --    
  END;
  --
  ----------------------------------------------------
  -- Procedure processamento da NotaVale (principal)
  ----------------------------------------------------
  PROCEDURE NotaVale IS
    --
    vTrack         VARCHAR2(500);
    --
    vUserMessage     VARCHAR2(1000);
    vReturnCode      NUMBER;
    vReturnMessage   VARCHAR2(1000);
    --   
    vQtde                 NUMBER;
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'NotaVale');
    --
    --
    vTrack:= 'definir valores iniciais';
    --
    WT2MX_MASSIVELOAD_MNG.gValores('CD_PTD').NumberValue         := NULL;
    WT2MX_MASSIVELOAD_MNG.gValores('TP_CSM').StringValue         := NULL;
    WT2MX_MASSIVELOAD_MNG.gValores('CdRedRestrita').NumberValue  := NULL;
    WT2MX_MASSIVELOAD_MNG.gValores('MerchandiseList').StringValue:= NULL; 
    WT2MX_MASSIVELOAD_MNG.gValores('MerchContractLt').ClobValue:= NULL;    
    WT2MX_MASSIVELOAD_MNG.gValores('DriverList').StringValue     := NULL;
    WT2MX_MASSIVELOAD_MNG.gValores('RestrictionList').StringValue:= NULL;
    WT2MX_MASSIVELOAD_MNG.gValores('IN_RST_ETB').StringValue     := 'F';
    --
    WT2MX_MASSIVELOAD_MNG.gValores('NU_REG_MASTER').NumberValue  := WT2MX_MASSIVELOAD_MNG.gFile.NU_REG;
    --
    --
    --/
    vTrack:= 'definir valor para o campo autoconsumo';
    -- 
    IF NVL(WT2MX_MASSIVELOAD_MNG.gValores('IndAutoConsumo').StringValue, 'F') = 'T' THEN
       WT2MX_MASSIVELOAD_MNG.gValores('TP_CSM').StringValue := 'I';
    ELSE
       WT2MX_MASSIVELOAD_MNG.gValores('TP_CSM').StringValue := 'E';
    END IF;
    -- 
    -- Verifica Bomba Propria
    vTrack:= 'verificar bomba propria';
    --
    IF NVL(WT2MX_MASSIVELOAD_MNG.gValores('IndAutoConsumo').StringValue, 'F') = 'T' THEN
      --
      SELECT DECODE(COUNT(1), 0, 0, 1)
      INTO vQtde
      FROM PTC_BAS B,
           PTC_NIV_CTR_ITE_SVC_PTE_NEG NCISPN
      WHERE B.CD_BAS = WT2MX_MASSIVELOAD_MNG.gValores('Base').NumberValue
        AND B.CD_PTE_NEG = NCISPN.CD_PTE_NEG
        AND NCISPN.CD_ITE_SVC IN (3, 6);
      --
      IF vQtde = 0 THEN
        --
        vReturnCode    := 183015;-- Autoconsumo Nota Vale" is only allowed when CorporateLevel have "Bomba Própria" Service Item.
        RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
        --
      END IF;
      --
    END IF;
    --
    -- Sub Rede
    vTrack:= 'verificar sub rede';
    --
    IF WT2MX_MASSIVELOAD_MNG.gValores('CdRedRestrita').NumberValue = 0 THEN
       WT2MX_MASSIVELOAD_MNG.gValores('CdRedRestrita').NumberValue := NULL;
    END IF;
    --
    -- Verifica se Rede Restrita é do Consolidador
    vTrack:= 'verificar  se rede restrita é do consolidador';
    --
    IF NVL(WT2MX_MASSIVELOAD_MNG.gValores('CdRedRestrita').NumberValue,0) > 0 THEN
      BEGIN
        SELECT CD_SUB_RED
          INTO WT2MX_MASSIVELOAD_MNG.gValores('CdRedRestrita').NumberValue
          FROM PTC_SUB_RED
         WHERE CD_SUB_RED = WT2MX_MASSIVELOAD_MNG.gValores('CdRedRestrita').NumberValue
           AND CD_CSL     = WT2MX_MASSIVELOAD_MNG.gValores('CD_CSL').NumberValue;

        EXCEPTION
           WHEN NO_DATA_FOUND THEN
              --
              vReturnCode    := 180596;-- AcceptanceRestrictionIdentification invalid.
              RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
              --
      END;
      --
    END IF;
    --
    -- valor minimo para cancelamento
    vTrack:= 'verificar valor minimo para cancelamento';
    --
    IF WT2MX_MASSIVELOAD_MNG.gValores('VlrMinCancel').NumberValue >=
         WT2MX_MASSIVELOAD_MNG.gValores('ValorNV').NumberValue THEN
      --
      vReturnCode:= 182545; -- MinimumValueToCancel must be less then value
      RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
      --
    END IF;
    --
    --
    /*vTrack:= 'verificar se é ultima linha do registro detalhe';
    --
    IF WT2MX_MASSIVELOAD_MNG.RegisterLastLine(PNU_REG => WT2MX_MASSIVELOAD_MNG.gFile.NU_REG) = WT2MX_MASSIVELOAD_MNG.gFile.NU_REG THEN
      --
      vTrack:= 'chamar procedure ProcessarRegistroNV';
      --
      ProcessarRegistroNV;
      --
    END IF;*/
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
      IF NVL(vReturnCode,0) <> 0 THEN
         WT2MX_MASSIVELOAD_MNG.ProcessError(pErrorCode  => vReturnCode, 
                                     pErrorMessage => vReturnMessage,
                                     pAuxMessage => 'Erro ao ' || vTrack ||': ' ||NVL(vUserMessage, vReturnCode), 
                                     pErrorType  => 'ERR',
                                     pErrorLevel => 'REG');  
      ELSE                                   
        WT2MX_MASSIVELOAD_MNG.ProcessError(pErrorCode   => 182190, 
                                          pAuxMessage => 'Erro ao ' || vTrack ||': ' ||SQLERRM, 
                                          pErrorType  => 'EXC',
                                          pErrorLevel => 'REG');   
      END IF;                                    
      --   
      --
  END;
  --
  --
  ----------------------------------------------------
  -- Procedure processamento Portador
  ----------------------------------------------------
  PROCEDURE Portador IS
    --
    vTrack         VARCHAR2(500);
    --
    vUserMessage   VARCHAR2(500);
    vReturnCode    NUMBER;
    vReturnMessage   VARCHAR2(500);
    --
    --
    vCard                 VARCHAR2(20);
    vTagNfcNum            VARCHAR2(20);
    vTagNfcId             VARCHAR2(20);
    vRiskConditionReasonCodeId T_GCARD.RISKCONDITIONREASONCODEID%TYPE;
    vQtde                 NUMBER;
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'Portador');
    --       
    --
    vTrack:= 'receber campos especificos';
    --                                             
    vCard      := WT2MX_MASSIVELOAD_MNG.gValores('NuCartao').StringValue;
    vTagNfcNum := WT2MX_MASSIVELOAD_MNG.gValores('TAGNFCNum').StringValue;
    vTagNfcId  := WT2MX_MASSIVELOAD_MNG.gValores('TAGNFC').StringValue;

    -- Se CARD_NUMBER não for informado, obter o cartão ativo a partir dos novos campos
    -- (TAG_NUMERICA ou TAG_HEXADECIMAL)
    --
    vTrack:= 'obter o cartão ativo a partir dos campos NU_CARTAO/TAG_NUMERICA/TAG_HEXADECIMAL';
    --                                             
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
        vReturnCode    := 183143;  -- Could not find Card Number
        RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
        --
      END IF;
      --
      WT2MX_MASSIVELOAD_MNG.gValores('NuCartao').StringValue:= vCard;
      --
    EXCEPTION
      WHEN OTHERS THEN
        --
        vReturnCode    := 183143;  -- Could not find Card Number
        RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
        --
    END;
    --
    --
    -- Se o cartão obtido estiver com bloqueio emissor (T_GCARD.RISKCONDITIONREASONCODEID = 99),
    -- apontar erro específico (3139)
    --
    vTrack:= 'verificar se o cartão obtido está com bloqueio emissor';
    --                                             
    SELECT C.RISKCONDITIONREASONCODEID
    INTO vRiskConditionReasonCodeId
    FROM T_GCARD C
    WHERE CARDID = vCard;
    --
    IF vRiskConditionReasonCodeId = 99 THEN
        --
        vReturnCode    := 183139;
        RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
        --
    END IF;
    --
    --
    vTrack:= 'verificar portados do cartão';
    --                                             
    BEGIN
      SELECT CAT.CD_PTD
        INTO WT2MX_MASSIVELOAD_MNG.gValores('CD_PTD').NumberValue
        FROM PTC_CAT  CAT
       WHERE CAT.NU_CAT = vCard;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --
        WT2MX_MASSIVELOAD_MNG.gValores('CD_PTD').NumberValue := NULL;
        --
    END;
    --
    --
    vTrack:= 'validar portador do cartão';
    --                                             
    SELECT COUNT(1)
       INTO vQtde
       FROM PTC_PTD
      WHERE CD_PTD = WT2MX_MASSIVELOAD_MNG.gValores('CD_PTD').NumberValue
        AND CD_BAS = WT2MX_MASSIVELOAD_MNG.gValores('Base').NumberValue;
    --
    IF  vQtde  = 0 THEN
      --
      vReturnCode    := 182549; --Invalid Cardholder
      RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
      --
    END IF;
    --
    --
    -- Verifica se o portador informado pertence a abrangencia de gest?o
    vTrack:= 'verificar se o portador informado pertence a abrangencia de gestão';
    IF WT2MX_MASSIVELOAD_MNG.gValores('CD_TIP_GST').NumberValue <>  5        THEN
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
          AND PTD.CD_PTD      = WT2MX_MASSIVELOAD_MNG.gValores('CD_PTD').NumberValue
          AND CCU.CD_HIE_ETD IN (SELECT  HIE.CD_HIE_ETD
                                 FROM PTCMX_HIE_ETD   HIE
                             START WITH HIE.CD_HIE_ETD   IN (SELECT GSTH.CD_HIE_ETD
                                                                FROM PTCMX_GST_HIE_ETD GSTH
                                                               WHERE GSTH.CD_GST     = WT2MX_MASSIVELOAD_MNG.gValores('Manager').NumberValue
                                                                 AND GSTH.CD_CSL     = WT2MX_MASSIVELOAD_MNG.gValores('CD_CSL').NumberValue)
                         CONNECT BY PRIOR HIE.CD_HIE_ETD = HIE.CD_HIE_ETD_PAI);
      --
      -- Verifica diferenca nos totais
      --
      IF  vQtde = 0 THEN
        --
        vReturnCode    := 152339; --Manager incompatible with Hierarchy
        RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
        --
      END IF;
      --
    END IF;
    --
    ---------------------------------------------------------
    vTrack:= 'verificar se é ultima linha do registro detalhe';
    --
    IF WT2MX_MASSIVELOAD_MNG.RegisterLastLine(PNU_REG => WT2MX_MASSIVELOAD_MNG.gFile.NU_REG) = WT2MX_MASSIVELOAD_MNG.gFile.NU_REG THEN
      --
      vTrack:= 'chamar procedure ProcessarRegistroNV (Portador)';
      --
      ProcessarRegistroNV;
      --
    END IF;
    ---------------------------------------------------------
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
      IF NVL(vReturnCode,0) <> 0 THEN
         WT2MX_MASSIVELOAD_MNG.ProcessError(pErrorCode  => vReturnCode, 
                                     pErrorMessage => vReturnMessage,
                                     pAuxMessage => 'Erro ao ' || vTrack ||': ' ||NVL(vUserMessage, vReturnCode), 
                                     pErrorType  => 'ERR',
                                     pErrorLevel => 'REG');  
      ELSE                                   
        WT2MX_MASSIVELOAD_MNG.ProcessError(pErrorCode   => 182190, 
                                          pAuxMessage => 'Erro ao ' || vTrack ||': ' ||SQLERRM, 
                                          pErrorType  => 'EXC',
                                          pErrorLevel => 'REG');   
      END IF;                                    
      --   

      --
  END;
  --
  --  
  ----------------------------------------------------
  -- Procedure processamento da Mercadorias
  ----------------------------------------------------
  PROCEDURE Mercadoria IS
    --
    vTrack         VARCHAR2(500);
    --
    vUserMessage   VARCHAR2(500);
    vReturnCode    NUMBER;
    vReturnMessage   VARCHAR2(500);
    --
    vCdMercadoria   PTC_MRD.CD_MRD%TYPE;
    vQtMercadoria   NUMBER;
    vVlUnMercadoria NUMBER;
    vQtdKM NUMBER;
    vRendimento NUMBER;
    --  
    vQtde           NUMBER;
    --      
  BEGIN  
    --
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'Mercadorias');
    --    
    --
    vTrack:= 'receber conteudo mercadorias';
    --
    vCdMercadoria   := WT2MX_MASSIVELOAD_MNG.gValores('CdMercadoria').NumberValue;
    vQtMercadoria   := WT2MX_MASSIVELOAD_MNG.gValores('QtMercadoria').NumberValue;
    vVlUnMercadoria := WT2MX_MASSIVELOAD_MNG.gValores('VlUnMercadoria').NumberValue;
    --
    vQtdKM          := WT2MX_MASSIVELOAD_MNG.gValores('QtdKM').NumberValue;
    vRendimento     := WT2MX_MASSIVELOAD_MNG.gValores('Rendimento').NumberValue;

    -- Valida infors x tipo NV 
    --
    vTrack:= 'validar inforações de mercadoria x tipo NV';
    --
    IF (WT2MX_MASSIVELOAD_MNG.gValores('TpNV').NumberValue  = 1 AND 
          (vQtdKM IS NOT NULL OR vRendimento IS NOT NULL)) 
        OR
       (WT2MX_MASSIVELOAD_MNG.gValores('TpNV').NumberValue  = 2 AND 
          (vCdMercadoria IS NULL OR vQtMercadoria IS NULL OR vVlUnMercadoria IS NULL OR vQtdKM IS NOT NULL OR vRendimento IS NOT NULL)) 
        OR
       (WT2MX_MASSIVELOAD_MNG.gValores('TpNV').NumberValue  = 3 AND  
          (vCdMercadoria IS NULL OR vVlUnMercadoria IS NULL OR vQtdKM IS NULL OR vRendimento IS NULL)) THEN
      --
      vReturnCode := 183046; -- Invalid informations for PreAuthorization Type.
      RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
      --
    END IF;
    --
    --
    vTrack:= 'validar mercadoria';
    --
    SELECT COUNT(CD_TIP_MRD)
     INTO vQtde
     FROM PTC_MRD_TIP_MRD
    WHERE CD_TIP_MRD = 1  -- Combustivel
      AND CD_MRD     = vCdMercadoria;
    --
    IF  vQtde = 0 THEN
     --
     vReturnCode := 182457; -- Mercadoria Invalida
     RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
     --
    END IF;
    --
    --
    vTrack:= 'validar valores de mercadoria';
    --
    IF NVL(vQtMercadoria,   0) = 0 OR
      NVL(vVlUnMercadoria, 0) = 0 THEN
      --
      vReturnCode := 182457; -- Required invalid information
      RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
    END IF;
    --
    --
    vTrack:= 'montar lista de mercadorias';
    --
    IF WT2MX_MASSIVELOAD_MNG.gValores('MerchandiseList').StringValue IS NOT NULL THEN
       WT2MX_MASSIVELOAD_MNG.gValores('MerchandiseList').StringValue := WT2MX_MASSIVELOAD_MNG.gValores('MerchandiseList').StringValue || '|';
    END IF;
    --
    WT2MX_MASSIVELOAD_MNG.gValores('MerchandiseList').StringValue := WT2MX_MASSIVELOAD_MNG.gValores('MerchandiseList').StringValue  ||
                         vCdMercadoria  || ';' ||
                         vQtMercadoria  || ';' ||
                         vVlUnMercadoria|| ';' ||
                         vQtdKM         || ';' || 
                         vRendimento;
    --
    ---------------------------------------------------------
    vTrack:= 'verificar se é ultima linha do registro detalhe';
    --
    IF WT2MX_MASSIVELOAD_MNG.RegisterLastLine(PNU_REG => WT2MX_MASSIVELOAD_MNG.gFile.NU_REG) = WT2MX_MASSIVELOAD_MNG.gFile.NU_REG THEN
      --
      vTrack:= 'chamar procedure ProcessarRegistroNV (Mercadoria)';
      --
      ProcessarRegistroNV;
      --
    END IF;

    ---------------------------------------------------------
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
      IF NVL(vReturnCode,0) <> 0 THEN
         WT2MX_MASSIVELOAD_MNG.ProcessError(pErrorCode  => vReturnCode, 
                                     pErrorMessage => vReturnMessage,
                                     pAuxMessage => 'Erro ao ' || vTrack ||': ' ||NVL(vUserMessage, vReturnCode), 
                                     pErrorType  => 'ERR',
                                     pErrorLevel => 'REG');  
      ELSE                                   
        WT2MX_MASSIVELOAD_MNG.ProcessError(pErrorCode   => 182190, 
                                          pAuxMessage => 'Erro ao ' || vTrack ||': ' ||SQLERRM, 
                                          pErrorType  => 'EXC',
                                          pErrorLevel => 'REG');   
      END IF;                                    
      --   
      --
  END;    
  --
  --  
  ----------------------------------------------------
  -- Procedure processamento de Estabelecimentos
  ----------------------------------------------------
  PROCEDURE Estabelecimento IS
    --
    vTrack         VARCHAR2(500);
    --
    vUserMessage   VARCHAR2(500);
    vReturnCode    NUMBER;
    vReturnMessage   VARCHAR2(500);
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'Estabelecimentos');
    --
    vTrack:= 'montar lista de contratos de estabelecimento';
    --
    IF WT2MX_MASSIVELOAD_MNG.gValores('MerchContractLt').ClobValue IS NOT NULL THEN
       WT2MX_MASSIVELOAD_MNG.gValores('MerchContractLt').ClobValue := WT2MX_MASSIVELOAD_MNG.gValores('MerchContractLt').ClobValue || '|';
    END IF;
    --
    WT2MX_MASSIVELOAD_MNG.gValores('MerchContractLt').ClobValue := WT2MX_MASSIVELOAD_MNG.gValores('MerchContractLt').ClobValue  ||
                       WT2MX_MASSIVELOAD_MNG.gValores('CtrEstRestrito').NumberValue  ;
    --
    WT2MX_MASSIVELOAD_MNG.gValores('IN_RST_ETB').StringValue     := 'T';
    --
    ---------------------------------------------------------
    vTrack:= 'verificar se é ultima linha do registro detalhe';
    --
    IF WT2MX_MASSIVELOAD_MNG.RegisterLastLine(PNU_REG => WT2MX_MASSIVELOAD_MNG.gFile.NU_REG) = WT2MX_MASSIVELOAD_MNG.gFile.NU_REG THEN
      --
      vTrack:= 'chamar procedure ProcessarRegistroNV (Estabelecimento)';
      --
      ProcessarRegistroNV;
      --
    END IF;

    ---------------------------------------------------------
    --    
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      IF NVL(vReturnCode,0) <> 0 THEN
         WT2MX_MASSIVELOAD_MNG.ProcessError(pErrorCode  => vReturnCode, 
                                     pErrorMessage => vReturnMessage,
                                     pAuxMessage => 'Erro ao ' || vTrack ||': ' ||NVL(vUserMessage, vReturnCode), 
                                     pErrorType  => 'ERR',
                                     pErrorLevel => 'REG');  
      ELSE                                   
        WT2MX_MASSIVELOAD_MNG.ProcessError(pErrorCode   => 182190, 
                                          pAuxMessage => 'Erro ao ' || vTrack ||': ' ||SQLERRM, 
                                          pErrorType  => 'EXC',
                                          pErrorLevel => 'REG');   
      END IF;                                    
      --   

      --
  END;    
  --
  --  
  ----------------------------------------------------
  -- Procedure processamento de Condutores
  ----------------------------------------------------
  PROCEDURE Condutor IS
    --
    vTrack         VARCHAR2(500);
    --
    vUserMessage   VARCHAR2(500);
    vReturnCode    NUMBER;
    vReturnMessage   VARCHAR2(500);
    --
    vQtde           NUMBER;
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'Condutores');
    --
    --    
    vTrack:= 'validar condutor';
    --
    SELECT COUNT(FSC.CD_PSS_FSC)
     INTO vQtde
     FROM PTC_PSS_FSC      FSC,
          PTC_PSS          PSS
     WHERE FSC.CD_ETD     = WT2MX_MASSIVELOAD_MNG.gValores('CdCondutor').NumberValue
       AND FSC.CD_PSS_FSC = PSS.CD_PSS_FSC
       AND PSS.CD_BAS     = WT2MX_MASSIVELOAD_MNG.gValores('Base').NumberValue
       AND PSS.CD_STA_CMM = 1;  
    --
    IF vQtde  = 0 THEN
      --
      vReturnCode := 182461; -- Condutor Invalido
      RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
      --
    END IF;
    --
         
    --    
    vTrack:= 'montar lista de condutores';
    --
    IF WT2MX_MASSIVELOAD_MNG.gValores('DriverList').StringValue IS NOT NULL THEN
       WT2MX_MASSIVELOAD_MNG.gValores('DriverList').StringValue := WT2MX_MASSIVELOAD_MNG.gValores('DriverList').StringValue || '|';
    END IF;
    --
    WT2MX_MASSIVELOAD_MNG.gValores('DriverList').StringValue := WT2MX_MASSIVELOAD_MNG.gValores('DriverList').StringValue|| 
        WT2MX_MASSIVELOAD_MNG.gValores('CdCondutor').NumberValue;
    --
    --
    ---------------------------------------------------------
    vTrack:= 'verificar se é ultima linha do registro detalhe';
    --
    IF WT2MX_MASSIVELOAD_MNG.RegisterLastLine(PNU_REG => WT2MX_MASSIVELOAD_MNG.gFile.NU_REG) = WT2MX_MASSIVELOAD_MNG.gFile.NU_REG THEN
      --
      vTrack:= 'chamar procedure ProcessarRegistroNV (Condutor)';
      --
      ProcessarRegistroNV;
      --
    END IF;

    ---------------------------------------------------------
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
      IF NVL(vReturnCode,0) <> 0 THEN
         WT2MX_MASSIVELOAD_MNG.ProcessError(pErrorCode  => vReturnCode, 
                                     pErrorMessage => vReturnMessage,
                                     pAuxMessage => 'Erro ao ' || vTrack ||': ' ||NVL(vUserMessage, vReturnCode), 
                                     pErrorType  => 'ERR',
                                     pErrorLevel => 'REG');  
      ELSE                                   
        WT2MX_MASSIVELOAD_MNG.ProcessError(pErrorCode   => 182190, 
                                          pAuxMessage => 'Erro ao ' || vTrack ||': ' ||SQLERRM, 
                                          pErrorType  => 'EXC',
                                          pErrorLevel => 'REG');   
      END IF;                                    
      --   


      --
  END; 
  --  
  --
  ----------------------------------------------------
  -- Procedure processamento de Restricao
  ----------------------------------------------------
  PROCEDURE Restricao IS
    --
    vTrack         VARCHAR2(500);
    --
    vUserMessage   VARCHAR2(500);
    vReturnCode    NUMBER;
    vReturnMessage   VARCHAR2(500);
    --
    vHrInicio       DATE;
    vHrFim          DATE;
    vPeriodicidade  PTC_PDC.CD_PDC%TYPE;
    vQtde           NUMBER;
    --
  BEGIN
    --
    DBMS_APPLICATION_INFO.READ_MODULE(vModule, vAction);
    DBMS_APPLICATION_INFO.SET_MODULE($$PLSQL_UNIT, 'Restricao');
    --
    vTrack:= 'validar horario de restição';
    --
    BEGIN
      --
      vHrInicio  := TO_DATE('01/01/2000 ' ||
                   WT2MX_MASSIVELOAD_MNG.gValores('HrInicio').StringValue,
                   'DD/MM/YYYY HH24MI');
      --
      vHrFim    := TO_DATE('01/01/2000 ' ||
                   WT2MX_MASSIVELOAD_MNG.gValores('HrFim').StringValue,
                   'DD/MM/YYYY HH24MI');
      --
    EXCEPTION
      WHEN OTHERS THEN
        --
        vReturnCode := 182555; -- Invalid start or end time
        RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
        --
    END;
    --
    --
    vPeriodicidade := WT2MX_MASSIVELOAD_MNG.gValores('Periodicidade').StringValue;
    --
    --
    vTrack:= 'validar periodicidade';
    --
    SELECT COUNT(CD_PDC)
     INTO vQtde
     FROM PTC_PDC
    WHERE CD_PDC = vPeriodicidade
      AND vPeriodicidade IN (8, 10, 11, 12);  -- Dias Uteis / Sabado / Domingo / Feriados
    --
    IF  vQtde = 0 THEN
       --
        vReturnCode := 180962; -- Periodicidade Invalida
        RAISE WT2MX_MASSIVELOAD_MNG.EProcessError;
       --
    END IF;
    --
    --
    vTrack:= 'montar lista de restrição';
    --
    IF  WT2MX_MASSIVELOAD_MNG.gValores('RestrictionList').StringValue IS NOT NULL THEN
        WT2MX_MASSIVELOAD_MNG.gValores('RestrictionList').StringValue := WT2MX_MASSIVELOAD_MNG.gValores('RestrictionList').StringValue || '|';
    END IF;
    --
    WT2MX_MASSIVELOAD_MNG.gValores('RestrictionList').StringValue := WT2MX_MASSIVELOAD_MNG.gValores('RestrictionList').StringValue ||
                              TO_CHAR(vHrInicio, 'HH24:MI') || ';' ||
                              TO_CHAR(vHrFim,    'HH24:MI') || ';' ||
                              vPeriodicidade;
    --
    ---------------------------------------------------------
    vTrack:= 'verificar se é ultima linha do registro detalhe';
    --
    IF WT2MX_MASSIVELOAD_MNG.RegisterLastLine(PNU_REG => WT2MX_MASSIVELOAD_MNG.gFile.NU_REG) = WT2MX_MASSIVELOAD_MNG.gFile.NU_REG THEN
      --
      vTrack:= 'chamar procedure ProcessarRegistroNV (Restrição)';
      --
      ProcessarRegistroNV;
      --
    END IF;

    ---------------------------------------------------------
    --    
    --
    DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
    --
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      --
      DBMS_APPLICATION_INFO.SET_MODULE(vModule, vAction);
      --
      IF NVL(vReturnCode,0) <> 0 THEN
         WT2MX_MASSIVELOAD_MNG.ProcessError(pErrorCode  => vReturnCode, 
                                     pErrorMessage => vReturnMessage,
                                     pAuxMessage => 'Erro ao ' || vTrack ||': ' ||NVL(vUserMessage, vReturnCode), 
                                     pErrorType  => 'ERR',
                                     pErrorLevel => 'REG');  
      ELSE                                   
        WT2MX_MASSIVELOAD_MNG.ProcessError(pErrorCode   => 182190, 
                                          pAuxMessage => 'Erro ao ' || vTrack ||': ' ||SQLERRM, 
                                          pErrorType  => 'EXC',
                                          pErrorLevel => 'REG');   
      END IF;                                    
      --   


      --
  END;   
END WT2MX_CMS_PREAUTHORIZATION_PKG;

