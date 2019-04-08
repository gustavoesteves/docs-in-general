CREATE OR REPLACE PACKAGE BODY WT2_SNN_ACCOUNTCORPLEVEL_INT IS
  --
  -- Internal Types
  --
  TYPE TCorporateLevelList IS TABLE OF NUMBER(16, 2) INDEX BY VARCHAR2(12);
  -- 
  -- Internal Procedures
  -- 
  PROCEDURE GetCreditList(pList IN CLOB, pCardHolderList OUT TY_CREDDISTRIB_TBL) IS
    --
    vIndex  NUMBER := 0;
    vCD_PTD NUMBER;
    --
  BEGIN
    --
    pCardHolderList := TY_CREDDISTRIB_TBL();
    --
    FOR L1 IN (SELECT *
                 FROM TABLE(F_SplitClob15(pList))) LOOP
      --
      BEGIN
        SELECT CD_PTD
          INTO vCD_PTD
          FROM PTC_CAT
         WHERE NU_CAT = L1.Column01;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE_APPLICATION_ERROR(-20001, 'Card ' || L1.Column01 || ' not found.');
        
      END;
      --
      vIndex := vIndex + 1;
      pCardHolderList.Extend;
      --
      pCardHolderList(vIndex) := TY_CREDDISTRIB_OBJ(
        NU_SEQ         => vIndex,
        NU_CAT         => L1.Column01,
        CD_PTD         => vCD_PTD,
        VL_PED_FIN_CAT => L1.Column02,
        CD_TIP_VLR_DST => L1.Column03,
        CD_MRD         => L1.Column04,
        QT_MRD         => L1.Column05,
        DC_OBS         => L1.Column06,
        DT_EXP_CRD     => TO_DATE(L1.Column07, 'DD/MM/YYYY'),
        CD_UNI_MRD     => L1.Column08);

    --
    END LOOP;
    --
  END GetCreditList;
  --
  PROCEDURE GetRecList(pList IN CLOB, pRecList OUT TY_CREDDISTRIB_TBL) IS
    --
    vIndex  NUMBER := 0;
    vCD_PTD NUMBER;
    --
  BEGIN
    --
    pRecList := TY_CREDDISTRIB_TBL();
    --
    FOR L1 IN (SELECT *
                 FROM TABLE(F_SplitClob15(pList))) LOOP
      --
      BEGIN
        SELECT CD_PTD
          INTO vCD_PTD
          FROM PTC_CAT
         WHERE NU_CAT = L1.Column01;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE_APPLICATION_ERROR(-20001, 'Card ' || L1.Column01 || ' not found.');
        
      END;
      --
      vIndex := vIndex + 1;
      pRecList.Extend;
      --
      pRecList(vIndex) := TY_CREDDISTRIB_OBJ(NU_SEQ         => vIndex,
                                             NU_CAT         => L1.Column01,
                                             CD_PTD         => vCD_PTD,
                                             VL_PED_FIN_CAT => L1.Column02,
                                             CD_TIP_VLR_DST => L1.Column03,
                                             CD_MRD         => NULL,
                                             QT_MRD         => NULL,
                                             DC_OBS         => L1.Column04,
                                             DT_EXP_CRD     => NULL,
                                             CD_UNI_MRD     => NULL);
    
    --
    END LOOP;
    --
  END GetRecList;
  --
  PROCEDURE GetCorpLevelList(pList IN CLOB, pCLList OUT TCorporateLevelList) IS
    --
  BEGIN
    --
    FOR L1 IN (SELECT *
                 FROM TABLE(F_SplitClob15(pList))) LOOP
      --
      pCLList(L1.Column01) := TO_NUMBER(L1.Column02);
      --
    END LOOP;
    --
  END GetCorpLevelList;
  --
  PROCEDURE SplitPreAuthMerchList(pClob IN CLOB, 
                                  pType OUT TLONGINTEGERPK) IS
    --
    vIndex INT := 0;
    --
  BEGIN
    --
    pType := TLONGINTEGERPK();
    --
    FOR L1 IN (SELECT *
                 FROM TABLE(F_SplitClob(pList => pClob, pSeparatorLine => ','))) LOOP
      --
      pType.Extend;
      vIndex := vIndex + 1;
      pType(vIndex) := TO_NUMBER(L1.COLUMN01);
      --
    END LOOP;
    --
  END SplitPreAuthMerchList; 
  --
  PROCEDURE SplitDistribCardHolderList(pClob IN  CLOB, 
                                       pType OUT TTEdrCardHldrDbAutomCrRestrict) IS
    --
    vIndex INT := 0;
    --
  BEGIN
    --
    pType := TTEdrCardHldrDbAutomCrRestrict();
    --
    FOR List IN (SELECT *
                   FROM TABLE(f_splitclob10(pList => pClob))) LOOP
      --
      pType.Extend();
      vIndex := vIndex + 1;
      pType(vIndex) := TOEdrCardHldrDbAutomCrRestrict(operationType          => List.Column01,
                                                      accountId              => List.Column02,
                                                      cardHolderId           => List.Column03,
                                                      amount                 => List.Column04,
                                                      purchaseItemTypeId     => List.Column05,
                                                      purchaseItemCategoryId => List.Column06,
                                                      unitType               => List.Column07,
                                                      unitQty                => List.Column08);
      --
    END LOOP;
    --
  END SplitDistribCardHolderList;
  --
  PROCEDURE SplitUpdLimCHList(pClob IN CLOB, pType OUT TTEdrUpdExpBudAmntCardHolder) IS
    --
    vIndex INT := 0;
    --
  BEGIN
    --
    pType := TTEdrUpdExpBudAmntCardHolder();
    --
    FOR List IN (SELECT *
                   FROM TABLE(f_splitclob10(pList => pClob))) LOOP
      --
      pType.Extend();
      vIndex := vIndex + 1;
      pType(vIndex) := TOEdrUpdExpBudAmntCardHolder(CreditLineTypeId             => List.Column01,
                                                    expensesBudgetAccClass       => List.Column02,
                                                    operationType                => List.Column03,
                                                    expensesBudgetAmount         => List.Column04,
                                                    additionalExpensesBudgetAmnt => List.Column05,
                                                    availableExpensesBudgetAmnt  => List.Column06,
                                                    CardId                       => List.Column07,
                                                    cardHolderExpBudAccOpId      => List.Column08);
      --
    END LOOP;
    --
  END SplitUpdLimCHList; 
  --
  PROCEDURE SplitCorpLevelAccountList(pCLOB IN CLOB, pType OUT TTEdrCorpLevelAccount) IS
    --
    vIndex INT := 0;
    vOEdrCrAccountBillingSchedule  TOEdrCrAccountBillingSchedule;
    vOEdrCorpLevRenewalExpBudAcc   TOEdrCorpLevRenewalExpBudAcc;
    --
  BEGIN
    --
    pType := TTEdrCorpLevelAccount();
    --
    FOR List IN (SELECT *
                   FROM TABLE(f_splitclob30(pList => pCLOB))) LOOP
      --
      pType.Extend();
      vIndex := vIndex + 1;
      vOEdrCrAccountBillingSchedule := TOEdrCrAccountBillingSchedule(billingFrequency => List.Column09,
                                                                     weeklyBillingDay => List.Column10,
                                                                     billingDay1      => List.Column11,
                                                                     billingDay2      => List.Column12,
                                                                     billingDay3      => List.Column13,
                                                                     billingDay4      => List.Column14);
      --
      vOEdrCorpLevRenewalExpBudAcc := TOEdrCorpLevRenewalExpBudAcc(expensesBudgetRenewalFreq => List.Column15,
                                                                   weeklyRenewalDay          => List.Column16,
                                                                   renewalDay1               => List.Column17,
                                                                   renewalDay2               => List.Column18,
                                                                   renewalDay3               => List.Column19,
                                                                   renewalDay4               => List.Column20);
      --
      pType(vIndex) := TOEdrCorpLevelAccount(accountId                    => List.Column01,
                                             corporateLevelId             => List.Column02,
                                             CrAccountBillingSchedule     => vOEdrCrAccountBillingSchedule,
                                             CorpLevRenewalExpBudAcc      => vOEdrCorpLevRenewalExpBudAcc,
                                             creditLimit                  => List.Column03,
                                             expensesBudgetAmount         => List.Column04,
                                             productCreditLineTypeId      => List.Column05,
                                             automCrSchMethod             => List.Column06,
                                             partialAutomCrSchSortingMeth => List.Column07,
                                             currencyId                   => NULL,
                                             addressId                    => NULL,
                                             expensesBudgetControlInd     => NULL,
                                             expensesBudgetAccClass       => NULL,
                                             commonAccountId              => NULL,
                                             accountNonFinancialOpId      => NULL,
                                             tktAvailableBalRenewalReqInd => List.Column08);
      --
    END LOOP;
    --
  END SplitCorpLevelAccountList; 
  --
  --
  -- Public Procedures
  --
  -- --------------------------------------------------------------------------
  -- Call Sunnel DistribToCardHoldersCustMngr process
  -- --------------------------------------------------------------------------
  PROCEDURE DistribToCardHoldersCustMngr(
    pCD_GST         IN NUMBER,
    pCD_CTR_CLI     IN NUMBER,
    pCD_BAS         IN NUMBER,
    pCD_TP_LIN_CRD  IN NUMBER,
    pDT_AGD         IN DATE,
    pCD_MOE         IN NUMBER,
    pTP_ACA         IN VARCHAR2, -- VALIDATE/APPLY
    pVL_TOT_PED     IN NUMBER,
    pNU_PED         IN NUMBER,
    pNU_PED_EXT     IN NUMBER,
    pVL_PED_BAS     IN NUMBER,
    pCardHolderList IN CLOB,
    pNU_TRF_SNN     OUT NUMBER,
    pVL_SLD_BAS     OUT NUMBER,
    CUR_OUT         OUT T_CURSOR,
    pCOD_RET        OUT NOCOPY NUMBER,
    CUR_ERR         OUT T_CURSOR) IS
    --
    vDebitoImediato               VARCHAR2(1);
    vTIP_DST                      VARCHAR2(10);
    vUNI_MRD                      VARCHAR2(10);
    vDT_AGD                       DATE;
    vCardHolderList               TY_CREDDISTRIB_TBL;
    vODisbursmentCorpLevFinTransf TODisbursmentCorpLevFinTransf;
    vTTktFinTransfCardHoldersDtl  TTTktFinTransfCardHoldersDtl;
    vOCorpLevelFinTransferResult  TOCorpLevelFinTransferResult;
    vOErrorMessage                TOErrorMessage;
    vSuccessFulInd                VARCHAR2(1);
    vErro                         VARCHAR2(500);
    --
  BEGIN
    --
    IF pDT_AGD IS NULL THEN
      SELECT currentdate
        INTO vDT_AGD
        FROM t_ginitsetupparameter;
    ELSE
      vDT_AGD := pDT_AGD;
    END IF;
    --  
    IF vDT_AGD > SYSDATE THEN
      vDebitoImediato := 'F';
    ELSE
      vDebitoImediato := 'T';
    END IF;
    --
    IF pCardHolderList IS NOT NULL THEN
      -- Popula Type com Portadores e Valores a serem distribuidos
      BEGIN
        GetCreditList(pList => pCardHolderList, pCardHolderList => vCardHolderList);
      EXCEPTION
        WHEN OTHERS THEN
          pCOD_RET := 210669;
          vErro := SUBSTR(SQLERRM, 1, 500);
          WT2_AUDIT_UTL.AuditError('Exception DistribToCardHoldersCustMngr - GetCreditList - ' || pCOD_RET || ' - ' || vErro);

          OPEN CUR_ERR FOR
            SELECT vErro AS MESSAGE,
                   vErro AS MESSAGETYPE,
                   vErro AS SHORTMESSAGE,
                   0     AS ITEMINDEX
              FROM DUAL;
        
          WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT => CUR_OUT);
          RETURN;
      END;
    END IF;
    --
    -- Carrega Type de Distribuição com base no Type de Input
    --
    vTTktFinTransfCardHoldersDtl := TTTktFinTransfCardHoldersDtl();
    --
    FOR i IN vCardHolderList.FIRST() .. vCardHolderList.LAST() LOOP
      --
      IF vCardHolderList(i).CD_TIP_VLR_DST = 1 THEN
        vTIP_DST := 'ACCUM';
      ELSE
        vTIP_DST := 'NONACCUM';
      END IF;
      --          
      IF vCardHolderList(i).CD_UNI_MRD = 1 THEN
        vUNI_MRD := 'M3';
      ELSIF vCardHolderList(i).CD_UNI_MRD = 3 THEN
        vUNI_MRD := 'UNIDADE';
      ELSE
        vUNI_MRD := 'LTS';
      END IF;
      --          
      vTTktFinTransfCardHoldersDtl.Extend;
      vTTktFinTransfCardHoldersDtl(i) := TOTktFinTransfCardHoldersDtl(
        Cardholderid           => vCardHolderList(i).CD_PTD,
        VALUE                  => vCardHolderList(i).VL_PED_FIN_CAT,
        Currencyid             => pCD_MOE,
        Accumulationtype       => vTIP_DST,
        Balanceexpirationdate  => vCardHolderList(i).DT_EXP_CRD,
        PURCHASEITEMTYPEID     => vCardHolderList(i).CD_MRD,
        PURCHASEITEMCATEGORYID => NULL,
        UNITTYPE               => vUNI_MRD,
        UNITQTY                => vCardHolderList(i).QT_MRD,
        ADDITIONALCOMMENTS     => vCardHolderList(i).DC_OBS);
      --
    END LOOP;
    --
    --Carrega Type de Identificação com base nos parâmetros de Input
    vODisbursmentCorpLevFinTransf := TODisbursmentCorpLevFinTransf(
      Customermanagerid         => pCD_GST,
      Customercontractid        => pCD_CTR_CLI,
      Corporatelevelid          => pCD_BAS,
      Creditlinetypeid          => pCD_TP_LIN_CRD,
      Scheduleddate             => vDT_AGD,
      Currencyid                => pCD_MOE,
      Processtype               => pTP_ACA,
      VALUE                     => pVL_TOT_PED,
      Requestnumber             => pNU_PED,
      ORDERID                   => pNU_PED,
      ORDERNUMBER               => pNU_PED_EXT,
      CORPLEVELCREDITVALUE      => pVL_PED_BAS,
      COMMITEDBALANCEACCOUNTIND => vDebitoImediato);
    --
    BEGIN
      -- Execução do Processo Sunnel
      KEdrAccountCorpLevelServices.PDistribToCardHoldersCustMngr(
        iTODisbursmentCorpLevFinTransf => vODisbursmentCorpLevFinTransf,
        iTVFinTransCardHoldersDtl      => vTTktFinTransfCardHoldersDtl,
        iuser                          => 'DBAPI',
        ihost                          => 'DBAPI',
        oDistribToCardHoldersCMOutPar  => vOCorpLevelFinTransferResult,
        oErrorMessage                  => vOErrorMessage,
        oSuccessFulInd                 => vSuccessFulInd);
    
      --
      EXECUTE IMMEDIATE 'ALTER session set nls_numeric_characters = '',. ''';
      --                                                                     
    EXCEPTION
      WHEN OTHERS THEN
        --
        WT2_AUDIT_UTL.AuditError('Exception DistribToCardHoldersCustMngr - Retorno Sunnel - ' || SQLCODE || ' - ' || SQLERRM);
        --
        pCOD_RET  := SQLCODE;
        vErro    := SUBSTR(SQLERRM, 1, 500);
        OPEN CUR_ERR FOR
          SELECT 'Sunnel Exception - ' || vErro AS MESSAGE,
                 vErro AS MESSAGETYPE,
                 vErro AS SHORTMESSAGE,
                 0 AS ITEMINDEX
            FROM DUAL;
        WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT => CUR_OUT);
        --
        EXECUTE IMMEDIATE 'ALTER session set nls_numeric_characters = '',. ''';
        --
        RETURN;
        --
    END;
    -- 
    -- Tratamento para o retorno das informações 
    --
    IF vSuccessFulInd = 'F' THEN
      IF vOErrorMessage.MESSAGE IS NOT NULL THEN
        WT2_AUDIT_UTL.AuditError('DistribToCardHoldersCustMngr - erro Sunnel - ' || vOErrorMessage.MESSAGE);
      ELSE
        WT2_AUDIT_UTL.AuditError('DistribToCardHoldersCustMngr - erro Sunnel - ' || vOCorpLevelFinTransferResult.TVProcessFailed(1).MESSAGE.MESSAGE);
      END IF;
      --
      pCOD_RET  := -1;
      OPEN CUR_ERR FOR
        SELECT vOErrorMessage.MESSAGE AS MESSAGE,
               vOErrorMessage.MESSAGETYPE AS MESSAGETYPE,
               vOErrorMessage.SHORTMESSAGE AS SHORTMESSAGE,
               0 AS ITEMINDEX
          FROM DUAL
         WHERE vOErrorMessage.MESSAGETYPE IS NOT NULL
         UNION ALL
        SELECT R.MESSAGE.MESSAGE AS MESSAGE,
               R.MESSAGE.MESSAGETYPE AS MESSAGETYPE,
               R.MESSAGE.SHORTMESSAGE AS SHORTMESSAGE,
               C.NU_SEQ AS ITEMINDEX
          FROM TABLE(vCardHolderList) C
          JOIN TABLE(vOCorpLevelFinTransferResult.TVProcessFailed) R ON C.CD_PTD = R.CardHolderId;
      --
      OPEN CUR_OUT FOR
        SELECT R.CardHolderId,
               R.CreditValue,
               R.CurrencyID,
               R.AccountEntryType,
               R.InitialAvailableBalance,
               R.TransactionAmount
          FROM TABLE(vOCorpLevelFinTransferResult.TVProcessFailed) R;
      --
      RETURN;
      --
    END IF;
    --
    pNU_TRF_SNN := vOCorpLevelFinTransferResult.corpLevelFinTransferRequestId;
    pVL_SLD_BAS := vOCorpLevelFinTransferResult.corpLevAccFinalAvailBalance;
    --
    WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT => CUR_OUT);
    WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT => CUR_ERR);
      --
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      WT2_AUDIT_UTL.AuditError('Erro DistribToCardHoldersCustMngr - ' || SQLCODE || ' - ' || SQLERRM);
      --
      pCOD_RET := SQLCODE;
      vErro    := SUBSTR(SQLERRM, 1, 500);
      OPEN CUR_ERR FOR
        SELECT vErro AS MESSAGE,
               vErro AS MESSAGETYPE,
               vErro AS SHORTMESSAGE,
               0 AS ITEMINDEX
          FROM DUAL;
      WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT => CUR_OUT);
      --
  END DistribToCardHoldersCustMngr;
  --  
  -- --------------------------------------------------------------------------
  -- Call Sunnel CrDistributionToCorpLevelAcc process
  -- --------------------------------------------------------------------------
  PROCEDURE CrDistributionToCorpLevelAcc(pCD_GST         IN NUMBER,
                                         pCD_CTR_CLI     IN NUMBER,
                                         pCD_BAS         IN NUMBER,
                                         pCD_TP_LIN_CRD  IN NUMBER,
                                         pDT_AGD         IN DATE,
                                         pCD_MOE         IN NUMBER,
                                         pTP_ACA         IN VARCHAR2, -- VALIDATE/APPLY
                                         pVL_TOT_PED     IN NUMBER,
                                         pNU_PED         IN NUMBER,
                                         pCardHolderList IN CLOB,
                                         pNU_TRF_SNN     OUT NUMBER,
                                         pVL_SLD_BAS     OUT NUMBER,
                                         CUR_OUT         OUT T_CURSOR,
                                         pCOD_RET        OUT NOCOPY NUMBER,
                                         CUR_ERR         OUT T_CURSOR) IS
    --
    vTIP_DST                     VARCHAR2(10);
    vRecList                     TY_CREDDISTRIB_TBL;
    vOCorpLevFinTransf           TOCorpLevFinTransf;
    vTTktFinTransfCardHoldersDtl TTTktFinTransfCardHoldersDtl;
    vOCorpLevelFinTransferResult TOCorpLevelFinTransferResult;
    vOErrorMessage               TOErrorMessage;
    vSuccessFulInd               VARCHAR2(1);
    vErro                        VARCHAR2(500);
    --
  BEGIN
    --
    IF pCardHolderList IS NOT NULL THEN
      -- Popula Type com Portadores e Valores a serem recolhidos
      BEGIN
        GetRecList(pList => pCardHolderList, pRecList => vRecList);
      EXCEPTION
        WHEN OTHERS THEN
          pCOD_RET  := 210669;
          vErro := SUBSTR(SQLERRM, 1, 500);
          WT2_AUDIT_UTL.AuditError('Exception CrDistributionToCorpLevelAcc - GetRecList - ' || pCOD_RET || ' - ' || vErro);

          OPEN CUR_ERR FOR
            SELECT vErro AS MESSAGE,
                   vErro AS MESSAGETYPE,
                   vErro AS SHORTMESSAGE,
                   0     AS ITEMINDEX
              FROM DUAL;
        
          WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT => CUR_OUT);
          RETURN;
      END;
    END IF;
    --
    -- Carrega Type de Recolhimento com base no Type de Input
    vTTktFinTransfCardHoldersDtl := TTTktFinTransfCardHoldersDtl();
    --
    FOR i IN vRecList.FIRST() .. vRecList.LAST() LOOP
      --
      IF vRecList(i).CD_TIP_VLR_DST = 1 THEN
        vTIP_DST := 'ACCUM';
      ELSE
        vTIP_DST := 'NONACCUM';
      END IF;
      --          
      vTTktFinTransfCardHoldersDtl.Extend;
      vTTktFinTransfCardHoldersDtl(i) := TOTktFinTransfCardHoldersDtl(Cardholderid           => vRecList(i).CD_PTD,
                                                                      VALUE                  => ABS(vRecList(i).VL_PED_FIN_CAT),
                                                                      Currencyid             => pCD_MOE,
                                                                      Accumulationtype       => vTIP_DST,
                                                                      Balanceexpirationdate  => NULL,
                                                                      PURCHASEITEMTYPEID     => NULL,
                                                                      PURCHASEITEMCATEGORYID => NULL,
                                                                      UNITTYPE               => NULL,
                                                                      UNITQTY                => NULL,
                                                                      ADDITIONALCOMMENTS     => vRecList(i).DC_OBS);
      --
    END LOOP;
    --
    -- Carrega Type de Identificação com base nos parâmetros de Input
    vOCorpLevFinTransf := TOCorpLevFinTransf(CUSTOMERMANAGERID  => pCD_GST,
                                             CUSTOMERCONTRACTID => pCD_CTR_CLI,
                                             CORPORATELEVELID   => pCD_BAS,
                                             CREDITLINETYPEID   => pCD_TP_LIN_CRD,
                                             SCHEDULEDDATE      => pDT_AGD,
                                             CURRENCYID         => pCD_MOE,
                                             PROCESSTYPE        => pTP_ACA,
                                             VALUE              => pVL_TOT_PED,
                                             REQUESTNUMBER      => pNU_PED);
    --
    -- Chamada do Processo no SUNNEL
    BEGIN
      --
      KEdrAccountCorpLevelServices.PCrDistributionToCorpLevelAcc(iTOCorpLevFinTransf            => vOCorpLevFinTransf,
                                                                 iTVFinTransCardHoldersDtl      => vTTktFinTransfCardHoldersDtl,
                                                                 iuser                          => 'DBAPI',
                                                                 ihost                          => 'DBAPI',
                                                                 oCrDistribToCorpLevelAccOutPar => vOCorpLevelFinTransferResult,
                                                                 oErrorMessage                  => vOErrorMessage,
                                                                 oSuccessFulInd                 => vSuccessFulInd);
      --
      EXECUTE IMMEDIATE 'ALTER session set nls_numeric_characters = '',. ''';
      --
    EXCEPTION
      WHEN OTHERS THEN
        --
        WT2_AUDIT_UTL.AuditError('Exception CrDistributionToCorpLevelAcc - Retorno Sunnel - ' || SQLCODE || ' - ' || SQLERRM);
        --
        pCOD_RET  := SQLCODE;
        vErro    := SUBSTR(SQLERRM, 1, 500);
        OPEN CUR_ERR FOR
          SELECT 'Sunnel Exception - ' || vErro AS MESSAGE,
                 vErro AS MESSAGETYPE,
                 vErro AS SHORTMESSAGE,
                 0 AS ITEMINDEX
            FROM DUAL;
            
        WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT => CUR_OUT);
        --
        EXECUTE IMMEDIATE 'ALTER session set nls_numeric_characters = '',. ''';
        --
        RETURN;
        --
    END;
    -- 
    -- Tratamento para o retorno das informações 
    --
    IF vSuccessFulInd = 'F' THEN
      IF vOErrorMessage.MESSAGE IS NOT NULL THEN
        WT2_AUDIT_UTL.AuditError('CrDistributionToCorpLevelAcc - erro Sunnel - ' || vOErrorMessage.MESSAGE);
      ELSE
        WT2_AUDIT_UTL.AuditError('DistribToCardHoldersCustMngr - erro Sunnel - ' || vOCorpLevelFinTransferResult.TVProcessFailed(1).MESSAGE.MESSAGE);
      END IF;
      --
      pCOD_RET  := -1;
      OPEN CUR_ERR FOR
        SELECT vOErrorMessage.MESSAGE AS MESSAGE,
               vOErrorMessage.MESSAGETYPE AS MESSAGETYPE,
               vOErrorMessage.SHORTMESSAGE AS SHORTMESSAGE,
               0 AS ITEMINDEX
          FROM DUAL
         WHERE vOErrorMessage.MESSAGETYPE IS NOT NULL
         UNION
        SELECT R.MESSAGE.MESSAGE AS MESSAGE,
               R.MESSAGE.MESSAGETYPE AS MESSAGETYPE,
               R.MESSAGE.SHORTMESSAGE AS SHORTMESSAGE,
               C.NU_SEQ AS ITEMINDEX
          FROM TABLE(vOCorpLevelFinTransferResult.TVProcessFailed) R
          JOIN TABLE(vRecList) C ON C.CD_PTD = R.CardHolderId;
      --
      OPEN CUR_OUT FOR
        SELECT CardHolderId,
               CreditValue,
               CurrencyID,
               AccountEntryType,
               InitialAvailableBalance,
               TransactionAmount
          FROM TABLE(vOCorpLevelFinTransferResult.TVProcessFailed);
      --
      --
      RETURN;
      --
    END IF;
    --
    pNU_TRF_SNN := vOCorpLevelFinTransferResult.corpLevelFinTransferRequestId;
    pVL_SLD_BAS := vOCorpLevelFinTransferResult.corpLevAccFinalAvailBalance;
    --
    WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT => CUR_OUT);
    WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT => CUR_ERR);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      WT2_AUDIT_UTL.AuditError('Erro CrDistributionToCorpLevelAcc - ' || SQLCODE || ' - ' || SQLERRM);
      --
      pCOD_RET := SQLCODE;
      vErro    := SUBSTR(SQLERRM, 1, 500);
      OPEN CUR_ERR FOR
        SELECT vErro AS MESSAGE,
               vErro AS MESSAGETYPE,
               vErro AS SHORTMESSAGE,
               0 AS ITEMINDEX
          FROM DUAL;
      WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT => CUR_OUT);
      --
  END CrDistributionToCorpLevelAcc;
  --  
  -- --------------------------------------------------------------------------
  -- Call Sunnel OrderCreditCorpLevelAcct process
  -- --------------------------------------------------------------------------
  PROCEDURE OrderCreditCorpLevelAcct(pCD_GST         IN NUMBER,
                                     pNU_CTR         IN VARCHAR2,
                                     pNU_PED         IN NUMBER,
                                     pNU_PED_EXT     IN NUMBER,
                                     pDT_AGD         IN DATE,
                                     pCD_MOE         IN NUMBER,
                                     pCD_PDT_LIN_CRD IN NUMBER,
                                     pDS_PRI         IN VARCHAR2,
                                     pCD_BAS         IN NUMBER,
                                     pVL_PED_BAS     IN NUMBER,
                                     pCOD_RET        OUT NOCOPY NUMBER,
                                     CUR_ERR         OUT T_CURSOR) IS
    --
    vTListErrorMessage             TTListErrorMessage;
    vSuccessFulInd                 VARCHAR2(1);
    vOrderCreditCorpLevelAcctInPar OrderCreditCorpLevelAcctInPar;
    vTOrderCreditCorpLevelAcctDtl  TTOrderCreditCorpLevelAcctDtl;
    vOOrderCreditCorpLevelAcctDtl  TOOrderCreditCorpLevelAcctDtl;
    vErro                          VARCHAR2(500);
    --
  BEGIN
    --
    -- Preenche o TYPE do Pedido com os dados dos Parâmetros
    vOOrderCreditCorpLevelAcctDtl := TOOrderCreditCorpLevelAcctDtl(PRODUCTCREDITLINETYPEID => pCD_PDT_LIN_CRD,
                                                                   CORPORATELEVELID        => pCD_BAS,
                                                                   AMOUNT                  => pVL_PED_BAS,
                                                                   ITEMNUMBER              => 1,
                                                                   ORDERITEMID             => NULL);
    --
    vTOrderCreditCorpLevelAcctDtl := TTOrderCreditCorpLevelAcctDtl();
    vTOrderCreditCorpLevelAcctDtl.Extend;
    vTOrderCreditCorpLevelAcctDtl(1) := vOOrderCreditCorpLevelAcctDtl;
    --
    vOrderCreditCorpLevelAcctInPar := OrderCreditCorpLevelAcctInPar(CUSTOMERMANAGERID             => pCD_GST,
                                                                    CONTRACTNUMBER                => pNU_CTR,
                                                                    ORDERID                       => pNU_PED,
                                                                    ORDERNUMBER                   => PNU_PED_EXT,
                                                                    CRORDERSCHEDULEDDATE          => pDT_AGD,
                                                                    CURRENCYID                    => pCD_MOE,
                                                                    ITEMSQTY                      => 1,
                                                                    TOTALAMOUNT                   => pVL_PED_BAS,
                                                                    PRIORITY                      => pDS_PRI,
                                                                    LOSTREPORTNUMBER              => NULL,
                                                                    TVOrderCreditCorpLevelAcctDtl => vTOrderCreditCorpLevelAcctDtl);
    --
    -- Chamada do Processo no SUNNEL
    BEGIN
      --
      KEdrAccountCorpLevelServices.POrderCreditCorpLevelAcct(iUser                      => 'DBAPI',
                                                             iHost                      => 'DBAPI',
                                                             oTVListErrorMessage        => vTListErrorMessage,
                                                             oSuccessfulInd             => vSuccessFulInd,
                                                             ioOrderCreditCorpLevelAcct => vOrderCreditCorpLevelAcctInPar);
      --
      EXECUTE IMMEDIATE 'ALTER session set nls_numeric_characters = '',. ''';
      --
    EXCEPTION
      WHEN OTHERS THEN
        --
        WT2_AUDIT_UTL.AuditError('Exception OrderCreditCorpLevelAcct - Retorno Sunnel - ' || SQLCODE || ' - ' || SQLERRM);
        --
        pCOD_RET := SQLCODE;
        vErro    := SUBSTR(SQLERRM, 1, 500);
        OPEN CUR_ERR FOR
          SELECT 'Sunnel Exception - ' || vErro AS MESSAGE,
                 vErro AS MESSAGETYPE,
                 vErro AS SHORTMESSAGE,
                 0 AS ITEMINDEX
            FROM DUAL;
        --
        EXECUTE IMMEDIATE 'ALTER session set nls_numeric_characters = '',. ''';
        --
        RETURN;
        --
    END;
    --
    -- Tratamento para o retorno das informações 
    --
    IF vSuccessFulInd = 'F' THEN
      WT2_AUDIT_UTL.AuditError('OrderCreditCorpLevelAcct - erro Sunnel - ' || vTListErrorMessage(1).ErrorMessage.MESSAGE);
      --
      pCOD_RET  := -1;

      OPEN CUR_ERR FOR
        SELECT E.ErrorMessage.MESSAGE AS MESSAGE,
               E.ErrorMessage.MESSAGETYPE AS MESSAGETYPE,
               E.ErrorMessage.MESSAGE AS SHORTMESSAGE,
               E.ITEMINDEX
          FROM TABLE(vTListErrorMessage) E;
      --
      RETURN;
      --
    END IF;
    --
    WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT => CUR_ERR);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      WT2_AUDIT_UTL.AuditError('Erro OrderCreditCorpLevelAcct - ' || SQLCODE || ' - ' || SQLERRM);
      --
      pCOD_RET  := SQLCODE;
      vErro    := SUBSTR(SQLERRM, 1, 500);
      OPEN CUR_ERR FOR
        SELECT vErro AS MESSAGE,
               vErro AS MESSAGETYPE,
               vErro AS SHORTMESSAGE,
               0 AS ITEMINDEX
          FROM DUAL;
      --
  END OrderCreditCorpLevelAcct;
  --  
  -- --------------------------------------------------------------------------
  -- Call Sunnel ManagementDebitAccount process
  -- --------------------------------------------------------------------------
  PROCEDURE ManagementDebitAccount(pDS_OPE     IN VARCHAR2, -- FEE, REVERSALFEE, LOAN, REVERSALLOAN, CREDITADJUSTMENT, DEBITADJUSTMENT
                                   pCD_CTR_CLI IN NUMBER,
                                   pCD_BAS     IN NUMBER,
                                   pNU_CTA     IN NUMBER,
                                   pCD_MOE     IN NUMBER,
                                   pVL_TRN     IN NUMBER,
                                   pNU_PED_EXT IN NUMBER,
                                   pCD_MTV     IN NUMBER,
                                   pCOD_RET    OUT NOCOPY NUMBER,
                                   CUR_ERR         OUT T_CURSOR) IS
    --
    vManagementDebitAccountInPar ManagementDebitAccountInPar;
    voOperationId                NUMBER(12);
    vSuccessFulInd               VARCHAR2(1);
    vOErrorMessage               TOErrorMessage;
    vErro                        VARCHAR2(500);
  BEGIN
    --
    -- Preenche o TYPE dos Ajustes com os dados dos Parâmetros
    vManagementDebitAccountInPar := ManagementDebitAccountInPar(OPERATIONTYPE      => pDS_OPE,
                                                                CUSTOMERCONTRACTID => pCD_CTR_CLI,
                                                                CORPORATELEVELID   => pCD_BAS,
                                                                ACCOUNTID          => pNU_CTA,
                                                                CURRENCYID         => pCD_MOE,
                                                                TRANSACTIONAMOUNT  => pVL_TRN,
                                                                REFERENCENUMBER    => pNU_PED_EXT,
                                                                REASONCODEID       => pCD_MTV);
    --
    -- Chamada do Processo no SUNNEL
    BEGIN
      --
      KEdrAccountCorpLevelServices.PManagementDebitAccount(iManagementDebitAccountInPar => vManagementDebitAccountInPar,  
                                                           iUser                        => 'DBAPI',                       
                                                           iHost                        => 'DBAPI',                       
                                                           oOperationId                 => voOperationId,                 
                                                           oErrorMessage                => vOErrorMessage,                
                                                           oSuccessfulInd               => vSuccessFulInd);               
    
      --
      EXECUTE IMMEDIATE 'ALTER session set nls_numeric_characters = '',. ''';
      --
    EXCEPTION
      WHEN OTHERS THEN
        --
        WT2_AUDIT_UTL.AuditError('Exception ManagementDebitAccount - Retorno Sunnel - ' || SQLCODE || ' - ' || SQLERRM);
        --
        pCOD_RET  := SQLCODE;
        vErro    := SUBSTR(SQLERRM, 1, 500);
        OPEN CUR_ERR FOR
          SELECT 'Sunnel Exception - ' || vErro AS MESSAGE,
                 vErro AS MESSAGETYPE,
                 vErro AS SHORTMESSAGE,
                 0 AS ITEMINDEX
            FROM DUAL;
        --
        EXECUTE IMMEDIATE 'ALTER session set nls_numeric_characters = '',. ''';
        --
        RETURN;
        --
    END;
    --
    -- Tratamento para o retorno das informações 
    --
    IF vSuccessFulInd = 'F' THEN
      WT2_AUDIT_UTL.AuditError('ManagementDebitAccount - erro Sunnel - ' || vOErrorMessage.MESSAGE);
      --
      pCOD_RET  := -1;
      OPEN CUR_ERR FOR
        SELECT vOErrorMessage.MESSAGE AS MESSAGE,
               vOErrorMessage.MESSAGETYPE AS MESSAGETYPE,
               vOErrorMessage.MESSAGE AS SHORTMESSAGE,
               0 AS ITEMINDEX
          FROM DUAL;
      --
      RETURN;
      --
    ELSE
      --
      WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT => CUR_ERR);
      --
    END IF;
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      WT2_AUDIT_UTL.AuditError('Erro ManagementDebitAccount - ' || SQLCODE || ' - ' || SQLERRM);
      --
      pCOD_RET  := SQLCODE;
      vErro    := SUBSTR(SQLERRM, 1, 500);
      OPEN CUR_ERR FOR
        SELECT vErro AS MESSAGE,
               vErro AS MESSAGETYPE,
               vErro AS SHORTMESSAGE,
               0 AS ITEMINDEX
          FROM DUAL;
      --
  END ManagementDebitAccount;
  --

  -- --------------------------------------------------------------------------
  -- Call Sunnel MngmntCorpLevelFinTransferReq process
  -- --------------------------------------------------------------------------
  PROCEDURE MngmntCorpLevelFinTransferReq(pDS_OPE     IN VARCHAR2, -- CANCEL, CHANGESCHDATE
                                          pNU_CTA     IN NUMBER,
                                          pNU_PED_SNN IN NUMBER,
                                          pDT_AGD     IN DATE,
                                          pItemList   IN CLOB,
                                          pCOD_RET    OUT NOCOPY NUMBER,
                                          CUR_ERR         OUT T_CURSOR) IS
    --
    vMngCorpLevFinTransferReqInPar MngCorpLevFinTransferReqInPar;
    vIndex                         NUMBER := 0;
    vItemList                      TTCorpLevFinTransferReqItem;
    vSuccessFulInd                 VARCHAR2(1);
    vTListErrorMessage             TTListErrorMessage;
    vErro                          VARCHAR2(500);
    --
  BEGIN
    --
    IF pItemList IS NOT NULL THEN
      vItemList := TTCorpLevFinTransferReqItem();
      -- Popula Type com os Portadores do Pedido
      FOR L1 IN (SELECT *
                   FROM TABLE(F_SplitClob15(pItemList))) LOOP
        --
        vIndex := vIndex + 1;
        vItemList.Extend;
        -- 
        vItemList(vIndex) := TOCorpLevFinTransferReqItem(CORPLEVELFINTRANSFERREQITEMID => L1.Column01,
                                                         ACCOUNTID                     => L1.Column02,
                                                         CARDHOLDERID                  => L1.Column03);
        --
      END LOOP;
      --
    END IF;
    -- Poopula Type de interface com o Sunnel
    vMngCorpLevFinTransferReqInPar := MngCorpLevFinTransferReqInPar(OPERATIONTYPE                 => pDS_OPE,
                                                                    CUSTCONTRCORPLEVELACCTID      => pNU_CTA,
                                                                    CORPLEVELFINTRANSFERREQUESTID => pNU_PED_SNN,
                                                                    CRSCHEDULEDDATE               => pDT_AGD,
                                                                    TVCORPLEVFINTRANSFERREQITEM   => vItemList);
    --
    -- Chamada do Processo no SUNNEL
    BEGIN
      --
      KEdrAccountCorpLevelServices.PMngmntCorpLevelFinTransferReq(iMngmntCorpLevFinTransReqInPar => vMngCorpLevFinTransferReqInPar,
                                                                  iUser                          => 'DBAPI',
                                                                  iHost                          => 'DBAPI',
                                                                  oTVListErrorMessage            => vTListErrorMessage,
                                                                  oSuccessFulInd                 => vSuccessFulInd);
    
      --
      EXECUTE IMMEDIATE 'ALTER session set nls_numeric_characters = '',. ''';
      --
    EXCEPTION
      WHEN OTHERS THEN
        --
        WT2_AUDIT_UTL.AuditError('Exception MngmntCorpLevelFinTransferReq - Retorno Sunnel - ' || SQLCODE || ' - ' || SQLERRM);
        --
        pCOD_RET  := SQLCODE;
        vErro    := SUBSTR(SQLERRM, 1, 500);
        OPEN CUR_ERR FOR
          SELECT 'Sunnel Exception - ' || vErro AS MESSAGE,
                 vErro AS MESSAGETYPE,
                 vErro AS SHORTMESSAGE,
                 0 AS ITEMINDEX
            FROM DUAL;
        --
        EXECUTE IMMEDIATE 'ALTER session set nls_numeric_characters = '',. ''';
        --
        RETURN;
        --
    END;
    --
    -- Tratamento para o retorno das informações 
    --
    IF vSuccessFulInd = 'F' THEN
      WT2_AUDIT_UTL.AuditError('MngmntCorpLevelFinTransferReq - erro Sunnel - ' || vTListErrorMessage(1).ErrorMessage.MESSAGE);
      --
      pCOD_RET  := -1;
      OPEN CUR_ERR FOR
        SELECT E.ErrorMessage.MESSAGE AS MESSAGE,
               E.ErrorMessage.MESSAGETYPE AS MESSAGETYPE,
               E.ErrorMessage.MESSAGE AS SHORTMESSAGE,
               E.ITEMINDEX
          FROM TABLE(vTListErrorMessage) E;
      --
      RETURN;
      --
    ELSE
      --
      WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT => CUR_ERR);
      --
    END IF;
    --
 EXCEPTION
    --
    WHEN OTHERS THEN
      --
      WT2_AUDIT_UTL.AuditError('Erro MngmntCorpLevelFinTransferReq - ' || SQLCODE || ' - ' || SQLERRM);
      --
      pCOD_RET  := SQLCODE;
      vErro    := SUBSTR(SQLERRM, 1, 500);
      OPEN CUR_ERR FOR
        SELECT vErro AS MESSAGE,
               vErro AS MESSAGETYPE,
               vErro AS SHORTMESSAGE,
               0 AS ITEMINDEX
          FROM DUAL;
      --
  END MngmntCorpLevelFinTransferReq;
  --
  -- --------------------------------------------------------------------------
  -- Call Sunnel CreatePreAuthorization process
  -- --------------------------------------------------------------------------
  PROCEDURE CreatePreAuthorization(pCD_CTR_CLI        IN NUMBER,
                                   pCD_BAS            IN NUMBER,
                                   pCD_GST            IN NUMBER,
                                   pCD_MOE            IN NUMBER,
                                   pCD_PTD            IN NUMBER,
                                   pCD_TIP_LIN_CDT    IN NUMBER,
                                   pDT_HR_INI_VIG     IN DATE,
                                   pDT_HR_FIM_VIG     IN DATE,
                                   pVL_TOT_INF        IN NUMBER,
                                   pNU_MAX_OPE        IN NUMBER,
                                   pVL_MIN            IN NUMBER,
                                   pIN_RST_ETB        IN VARCHAR2,
                                   pDS_CLS_ETB        IN VARCHAR2, -- PRIVATEACCPTRESTRICT, SPECIFICMERCHANT
                                   pCD_SUB_RED        IN NUMBER,
                                   pMerchContractList IN CLOB,
                                   pCD_PAT           OUT NUMBER,
                                   pCD_OPE_DEB       OUT NUMBER,
                                   pCD_OPE_CRD       OUT NUMBER,
                                   pCOD_RET          OUT NOCOPY NUMBER,
                                   CUR_ERR           OUT T_CURSOR) IS
    --
    vCreatePreAuthorizationInPar  CreatePreAuthorizationInPar;
    vPreAuthorizationDetail       TOEdrPreAuthorizationDetail;
    vItemList                     tlongintegerpk;  
    vCreatePreAuthorizationOutPar CreatePreAuthorizationOutPar;
    vSuccessfulInd                VARCHAR2(1);
    vErrorMessage                 TOErrorMessage;
    vErro                         VARCHAR2(500);
    --                           
  BEGIN
    -- 
    -- Preenche o type de entreda
    SplitPreAuthMerchList(pClob => pMerchContractList, pType => vItemList);
    --
    vPreAuthorizationDetail := TOEdrPreAuthorizationDetail(CARDHOLDERID                 => pCD_PTD,
                                                           CREDITLINETYPEID             => pCD_TIP_LIN_CDT,
                                                           VALIDFROM                    => pDT_HR_INI_VIG,
                                                           VALIDTO                      => pDT_HR_FIM_VIG,
                                                           CURRENCYID                   => pCD_MOE,
                                                           AMOUNT                       => pVL_TOT_INF,
                                                           MAXQTYUSAGEOPALLOWED         => pNU_MAX_OPE,
                                                           MINBALANCE                   => pVL_MIN,
                                                           MERCHANTRESTRICTIONIND       => pIN_RST_ETB,
                                                           MERCHANTRESTRICTPREAUTHCLASS => pDS_CLS_ETB, -- PRIVATEACCPTRESTRICT, SPECIFICMERCHANT
                                                           ACCEPTANCERESTRICTIONID      => pCD_SUB_RED,
                                                           TVMERCHANTCONTRACT           => vItemList);
    --
    vCreatePreAuthorizationInPar := CreatePreAuthorizationInPar(CUSTOMERCONTRACTID        => pCD_CTR_CLI,
                                                                CORPORATELEVELID          => pCD_BAS,
                                                                CUSTOMERMANAGERID         => pCD_GST,
                                                                CURRENCYID                => pCD_MOE,
                                                                EDRPREAUTHORIZATIONDETAIL => vPreAuthorizationDetail);
    -- 
    -- Chamada do processo Sunnel
    BEGIN
      --
      KEdrAccountCorpLevelServices.PcreatePreAuthorization(iCreatePreAuthorizationInPar  => vCreatePreAuthorizationInPar,
                                                           iUser                         => 'DBAPI',
                                                           iHost                         => 'DBAPI',
                                                           oCreatePreAuthorizationOutPar => vCreatePreAuthorizationOutPar,
                                                           oErrorMessage                 => vErrorMessage,
                                                           oSuccessfulInd                => vSuccessfulInd);
                                                           
                                                           
      --
      EXECUTE IMMEDIATE 'ALTER session set nls_numeric_characters = '',. ''';
      --
    EXCEPTION
      WHEN OTHERS THEN
        --
        WT2_AUDIT_UTL.AuditError('Exception CreatePreAuthorization - Retorno Sunnel - ' || SQLCODE || ' - ' || SQLERRM);
        --
        pCOD_RET  := SQLCODE;
        vErro    := SUBSTR(SQLERRM, 1, 500);
        OPEN CUR_ERR FOR
          SELECT 'Sunnel Exception - ' || vErro AS MESSAGE,
                 vErro AS MESSAGETYPE,
                 vErro AS SHORTMESSAGE,
                 0 AS ITEMINDEX
            FROM DUAL;
        --
        EXECUTE IMMEDIATE 'ALTER session set nls_numeric_characters = '',. ''';
        --
        RETURN;
        --
    END;
    --
    -- Tratamento para o retorno das informações 
    --
    IF vSuccessfulInd = 'F' THEN
      WT2_AUDIT_UTL.AuditError('CreatePreAuthorization - erro Sunnel - ' || vErrorMessage.MESSAGE);
      --
      pCOD_RET  := -1;
      OPEN CUR_ERR FOR
        SELECT vErrorMessage.MESSAGE AS MESSAGE,
               vErrorMessage.MESSAGETYPE AS MESSAGETYPE,
               vErrorMessage.MESSAGE AS SHORTMESSAGE,
               0 AS ITEMINDEX
          FROM DUAL;
      --
      RETURN;
      --
    END IF;
    --
    pCD_PAT     := vCreatePreAuthorizationOutPar.PREAUTHORIZATIONID;
    pCD_OPE_DEB := vCreatePreAuthorizationOutPar.DEBITOPERATIONID;
    pCD_OPE_CRD := vCreatePreAuthorizationOutPar.CREDITOPERATIONID;
    --
    WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT => CUR_ERR);
    --
 EXCEPTION
    --
    WHEN OTHERS THEN
      --
      WT2_AUDIT_UTL.AuditError('Erro CreatePreAuthorization - ' || SQLCODE || ' - ' || SQLERRM);
      --
      pCOD_RET  := SQLCODE;
      vErro    := SUBSTR(SQLERRM, 1, 500);
      OPEN CUR_ERR FOR
        SELECT vErro AS MESSAGE,
               vErro AS MESSAGETYPE,
               vErro AS SHORTMESSAGE,
               0 AS ITEMINDEX
          FROM DUAL;
      --
  END CreatePreAuthorization;
  --
  -- --------------------------------------------------------------------------
  -- Call Sunnel MaintenAutomCrSchdGroup process
  -- --------------------------------------------------------------------------
  PROCEDURE MaintenAutomCrSchdGroup(pTP_OPE                 IN VARCHAR2, -- CREATE, UPDATE
                                    pCD_CTA_BAS             IN NUMBER,
                                    pCD_GPO_DST_CRD         IN OUT NUMBER,
                                    pDS_FRQ                 IN VARCHAR2, -- DAILY, WEEKLY, SPECIFICDAYS
                                    pDD_SMN_DST             IN VARCHAR2, -- MON, TUE, WED, THU, FRI, SAT, SUN
                                    pDD_EPC_DST_1           IN NUMBER,
                                    pDD_EPC_DST_2           IN NUMBER,
                                    pDD_EPC_DST_3           IN NUMBER,
                                    pDD_EPC_DST_4           IN NUMBER,
                                    pDS_GPO_DST_CRD         IN VARCHAR2,
                                    pDS_STA_GPO_DST_CRD     IN VARCHAR2, -- ACTIVE, INACTIVE
                                    pCD_MOE                 IN NUMBER,
                                    pDistribCardHolderList  IN CLOB,
                                    pDS_FRQ_WEKLY           IN VARCHAR2,  -- 1.03
                                    pDT_PRX_DST            OUT DATE,
                                    pCOD_RET               OUT NOCOPY NUMBER,
                                    CUR_ERR                OUT T_CURSOR) IS
    --
    vMaintenAutomCrSchdGroupInPar EdrMaintAutomCrSchdGroupInPar;
    vEdrCardHldrDbAutomCrRestrict TTEdrCardHldrDbAutomCrRestrict;
    vMaintAutomCrSchdGroupOutPar  EdrMaintAutomCrSchdGroupOutPar;
    vSuccessfulInd                VARCHAR2(1);
    vTListErrorMessage            TTListErrorMessage;
    vErro                         VARCHAR2(500);
    --                           
  BEGIN
    -- 
    -- Preenche o type de entreda
    SplitDistribCardHolderList(pClob => pDistribCardHolderList, pType => vEdrCardHldrDbAutomCrRestrict); 
    --
    vMaintenAutomCrSchdGroupInPar := EdrMaintAutomCrSchdGroupInPar(operationType            => pTP_OPE, 
                                                                   accountId                => pCD_CTA_BAS,
                                                                   automCrSchGroupId        => pCD_GPO_DST_CRD,
                                                                   TVItems                  => vEdrCardHldrDbAutomCrRestrict,
                                                                   creditFrequency          => pDS_FRQ,
                                                                   WeeklyCreditDay          => pDD_SMN_DST,
                                                                   creditDay1               => pDD_EPC_DST_1,
                                                                   creditDay2               => pDD_EPC_DST_2,
                                                                   creditDay3               => pDD_EPC_DST_3,
                                                                   creditDay4               => pDD_EPC_DST_4,
                                                                   automCrSheduleGroupDesc  => pDS_GPO_DST_CRD,
                                                                   status                   => pDS_STA_GPO_DST_CRD,
                                                                   currencyId               => pCD_MOE,
                                                                   WeekCreditDays           => pDS_FRQ_WEKLY  );     -- 1.03 - Parametro novo
    -- 
    -- Chamada do processo Sunnel
    BEGIN
      --
      KEdrAccountCorpLevelServices.PMaintenAutomCrSchdGroup(iMaintenAutomCrSchdGroupInPar => vMaintenAutomCrSchdGroupInPar, 
                                                            iUser                         => 'DBAPI',                       
                                                            iHost                         => 'DBAPI',                       
                                                            oMaintenAutomCrSchdGroup      => vMaintAutomCrSchdGroupOutPar,  
                                                            oTVListErrorMessage           => vTListErrorMessage,
                                                            oSuccessfulInd                => vSuccessfulInd);   
      --
      EXECUTE IMMEDIATE 'ALTER session set nls_numeric_characters = '',. ''';
      --
    EXCEPTION
      WHEN OTHERS THEN
        --
        WT2_AUDIT_UTL.AuditError('Exception MaintenAutomCrSchdGroup - Retorno Sunnel - ' || SQLCODE || ' - ' || SQLERRM);
        --
        pCOD_RET  := SQLCODE;
        vErro    := SUBSTR(SQLERRM, 1, 500);
        OPEN CUR_ERR FOR
          SELECT 'Sunnel Exception - ' || vErro AS MESSAGE,
                 vErro AS MESSAGETYPE,
                 vErro AS SHORTMESSAGE,
                 0 AS ITEMINDEX
            FROM DUAL;
        --
        EXECUTE IMMEDIATE 'ALTER session set nls_numeric_characters = '',. ''';
        --
        RETURN;
        --
    END;
    --
    -- Tratamento para o retorno das informações 
    --
    IF vSuccessfulInd = 'F' THEN
      WT2_AUDIT_UTL.AuditError('MaintenAutomCrSchdGroup - erro Sunnel - ' || vTListErrorMessage(1).ErrorMessage.MESSAGE);
      --
      pCOD_RET  := -1;
      OPEN CUR_ERR FOR
        SELECT E.ErrorMessage.MESSAGE AS MESSAGE,
               E.ErrorMessage.MESSAGETYPE AS MESSAGETYPE,
               E.ErrorMessage.MESSAGE AS SHORTMESSAGE,
               E.ITEMINDEX
          FROM TABLE(vTListErrorMessage) E;
      --
      RETURN;
      --
    END IF;
    --
    pCD_GPO_DST_CRD := vMaintAutomCrSchdGroupOutPar.AUTOMCRSCHGROUPID;
    pDT_PRX_DST     := vMaintAutomCrSchdGroupOutPar.NEXTTRANSFERDATE;
    --
    WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT => CUR_ERR);
    --
 EXCEPTION
    --
    WHEN OTHERS THEN
      --
      WT2_AUDIT_UTL.AuditError('Erro MaintenAutomCrSchdGroup - ' || SQLCODE || ' - ' || SQLERRM);
      --
      pCOD_RET  := SQLCODE;
      vErro    := SUBSTR(SQLERRM, 1, 500);
      OPEN CUR_ERR FOR
        SELECT vErro AS MESSAGE,
               vErro AS MESSAGETYPE,
               vErro AS SHORTMESSAGE,
               0 AS ITEMINDEX
          FROM DUAL;
      --
  END MaintenAutomCrSchdGroup;
  --
  -- --------------------------------------------------------------------------
  -- Call Sunnel MngmtExpBudCardHolderAcct process
  -- --------------------------------------------------------------------------
  PROCEDURE MngmtExpBudCardHolderAcct(pCD_GST       IN NUMBER,
                                      pCD_MOE       IN NUMBER,
                                      pUpdLimCHList IN CLOB,
                                      CUR_OUT       OUT T_CURSOR,
                                      pCOD_RET      OUT NOCOPY NUMBER,
                                      CUR_ERR       OUT T_CURSOR) IS
    --
    vEdrMngmtExpBudCrdHldrAccInPar EdrMngmtExpBudCardHldrAccInPar;
    vTVCardHolders                 TTEdrUpdExpBudAmntCardHolder;
    vSuccessfulInd                 VARCHAR2(1);
    vTListErrorMessage             TTListErrorMessage;
    vErro                          VARCHAR2(500);
    --                           
  BEGIN
    -- 
    -- Preenche o type de entreda
    SplitUpdLimCHList(pClob => pUpdLimCHList, pType => vTVCardHolders); 
    --
    vEdrMngmtExpBudCrdHldrAccInPar := EdrMngmtExpBudCardHldrAccInPar(customerManagerId  => pCD_GST,
                                                                     currencyId         => pCD_MOE);
    -- 
    -- Chamada do processo Sunnel
    BEGIN
      --
      KEdrAccountCorpLevelServices.PMngmtExpBudCardHolderAcct(iEdrMngmtExpBudCrdHldrAccInPar => vEdrMngmtExpBudCrdHldrAccInPar, 
                                                              iUser                          => 'DBAPI',                       
                                                              iHost                          => 'DBAPI',                       
                                                              ioTVCardHolders                => vTVCardHolders,
                                                              oSuccessfulInd                 => vSuccessfulInd,  
                                                              oTVListErrorMessage            => vTListErrorMessage);   
      --
      EXECUTE IMMEDIATE 'ALTER session set nls_numeric_characters = '',. ''';
      --
    EXCEPTION
      WHEN OTHERS THEN
        --
        WT2_AUDIT_UTL.AuditError('Exception MngmtExpBudCardHolderAcct - Retorno Sunnel - ' || SQLCODE || ' - ' || SQLERRM);
        --
        pCOD_RET  := SQLCODE;
        vErro    := SUBSTR(SQLERRM, 1, 500);
        OPEN CUR_ERR FOR
          SELECT 'Sunnel Exception - ' || vErro AS MESSAGE,
                 vErro AS MESSAGETYPE,
                 vErro AS SHORTMESSAGE,
                 0 AS ITEMINDEX
            FROM DUAL;
        --
        WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT => CUR_OUT);
        --
        EXECUTE IMMEDIATE 'ALTER session set nls_numeric_characters = '',. ''';
        --
        RETURN;
        --
    END;
    --
    -- Tratamento para o retorno das informações 
    --
    IF vSuccessfulInd = 'F' THEN
      WT2_AUDIT_UTL.AuditError('MngmtExpBudCardHolderAcct - erro Sunnel - ' || vTListErrorMessage(1).ErrorMessage.MESSAGE);
      --
      pCOD_RET  := -1;
      OPEN CUR_ERR FOR
        SELECT E.ErrorMessage.MESSAGE AS MESSAGE,
               E.ErrorMessage.MESSAGETYPE AS MESSAGETYPE,
               E.ErrorMessage.MESSAGE AS SHORTMESSAGE,
               E.ITEMINDEX
          FROM TABLE(vTListErrorMessage) E;
      --
      WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT => CUR_OUT);
      --
      RETURN;
      --
    END IF;
    --
    OPEN CUR_OUT FOR
      SELECT CreditLineTypeId,
             expensesBudgetAccClass,
             operationType,
             expensesBudgetAmount,
             additionalExpensesBudgetAmnt,
             availableExpensesBudgetAmnt,
             CardId,
             cardHolderExpBudAccOpId
        FROM TABLE(vTVCardHolders);
    --
    WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT => CUR_ERR);
    --
 EXCEPTION
    --
    WHEN OTHERS THEN
      --
      WT2_AUDIT_UTL.AuditError('Erro MngmtExpBudCardHolderAcct - ' || SQLCODE || ' - ' || SQLERRM);
      --
      pCOD_RET  := SQLCODE;
      vErro    := SUBSTR(SQLERRM, 1, 500);
      OPEN CUR_ERR FOR
        SELECT vErro AS MESSAGE,
               vErro AS MESSAGETYPE,
               vErro AS SHORTMESSAGE,
               0 AS ITEMINDEX
          FROM DUAL;
      --
      WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT => CUR_OUT);
      --
  END MngmtExpBudCardHolderAcct;
  --
  -- --------------------------------------------------------------------------
  -- Call Sunnel CorpLevelAccMaintenance process
  -- --------------------------------------------------------------------------
  PROCEDURE CorpLevelAccMaintenance(pCD_GST               IN NUMBER,
                                    pCD_CTR_CLI           IN NUMBER,
                                    pTP_ACA               IN VARCHAR2, -- VALIDATE, APPLY
                                    pCorpLevelAccountList IN CLOB,
                                    CUR_OUT               OUT T_CURSOR,
                                    pCOD_RET              OUT NOCOPY NUMBER,
                                    CUR_ERR               OUT T_CURSOR) IS
    --
    vCorpLevelAccMaintenanceInPar  CorpLevelAccMaintenanceInPar;
    vTVCorpLevelAccount            TTEdrCorpLevelAccount;
    vTTListErrorMessage            TTListErrorMessage;
    vSuccessfulInd                 VARCHAR2(1);
    vErro                          VARCHAR2(500);
    --
  BEGIN
    --
    -- preenche o type de entrada
    SplitCorpLevelAccountList(pCLOB => pCorpLevelAccountList, pType => vTVCorpLevelAccount);
    --
    vCorpLevelAccMaintenanceInPar := CorpLevelAccMaintenanceInPar(customerManagerId  => pCD_GST,
                                                                  customerContractId => pCD_CTR_CLI,
                                                                  Action             => pTP_ACA);
    --
    -- chamada ao processo Sunnel
    BEGIN
      --
      KEdrAccountCorpLevelServices.PCorpLevelAccMaintenance(iCorpLevelAccMaintenanceInPar => vCorpLevelAccMaintenanceInPar, 
                                                            ioTVCorpLevelAccount          => vTVCorpLevelAccount,
                                                            iUser                         => 'DBAPI',
                                                            iHost                         => 'DBAPI',
                                                            osuccessfulInd                => vSuccessfulInd, 
                                                            oTVListErrorMessage           => vTTListErrorMessage);
      --
      EXECUTE IMMEDIATE 'ALTER session set nls_numeric_characters = '',. ''';
      --
    EXCEPTION
      WHEN OTHERS THEN
        --
        WT2_AUDIT_UTL.AuditError('Exception CorpLevelAccMaintenance - Retorno Sunnel - ' || SQLCODE || ' - ' || SQLERRM);
        --
        pCOD_RET := SQLCODE;
        vErro    := SUBSTR(SQLERRM, 1, 500);
        --
        OPEN CUR_ERR FOR
          SELECT 'Sunnel Exception - ' || vErro AS MESSAGE,
                 vErro AS MESSAGETYPE,
                 vErro AS SHORTMESSAGE,
                 0 AS ITEMINDEX
            FROM DUAL;
        --
        EXECUTE IMMEDIATE 'ALTER session set nls_numeric_characters = '',. ''';
        --
        WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT);
        --
        RETURN;
        --
    END;
    --
    -- Tratamento para o retorno das informações 
    IF vSuccessfulInd = 'F' THEN
      --
      WT2_AUDIT_UTL.AuditError('CorpLevelAccMaintenance - erro Sunnel - ' || vTTListErrorMessage(1).ErrorMessage.MESSAGE);
      --
      pCOD_RET := -1;
    
      OPEN CUR_ERR FOR
        SELECT E.ErrorMessage.MESSAGE     AS MESSAGE,
               E.ErrorMessage.MESSAGETYPE AS MESSAGETYPE,
               E.ErrorMessage.MESSAGE     AS SHORTMESSAGE,
               E.ITEMINDEX
          FROM TABLE(vTTListErrorMessage) E;
      --
      WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT);
      --
      RETURN;
      --
    END IF;
    --
    OPEN CUR_OUT FOR 
      SELECT t.accountId                                         accountId,
             t.corporateLevelId                                  corporateLevelId,
             t.CrAccountBillingSchedule.billingFrequency         billingFrequency,
             t.CrAccountBillingSchedule.weeklyBillingDay         weeklyBillingDay,
             t.CrAccountBillingSchedule.billingDay1              billingDay1,
             t.CrAccountBillingSchedule.billingDay2              billingDay2,
             t.CrAccountBillingSchedule.billingDay3              billingDay3,
             t.CrAccountBillingSchedule.billingDay4              billingDay4,
             t.CorpLevRenewalExpBudAcc.expensesBudgetRenewalFreq expensesBudgetRenewalFreq,
             t.CorpLevRenewalExpBudAcc.weeklyRenewalDay          weeklyRenewalDay,
             t.CorpLevRenewalExpBudAcc.renewalDay1               renewalDay1,
             t.CorpLevRenewalExpBudAcc.renewalDay2               renewalDay2,
             t.CorpLevRenewalExpBudAcc.renewalDay3               renewalDay3,
             t.CorpLevRenewalExpBudAcc.renewalDay4               renewalDay4,
             t.creditLimit                                       creditLimit,
             t.expensesBudgetAmount                              expensesBudgetAmount,
             t.productCreditLineTypeId                           productCreditLineTypeId,
             t.automCrSchMethod                                  automCrSchMethod,
             t.partialAutomCrSchSortingMeth                      partialAutomCrSchSortingMeth,
             t.currencyId                                        currencyId,
             t.addressId                                         addressId,
             t.expensesBudgetControlInd                          expensesBudgetControlInd,
             t.expensesBudgetAccClass                            expensesBudgetAccClass,
             t.commonAccountId                                   commonAccountId,
             t.accountNonFinancialOpId                           accountNonFinancialOpId,
             t.tktAvailableBalRenewalReqInd                      tktAvailableBalRenewalReqInd
        FROM TABLE(vTVCorpLevelAccount) t;
    --
    -- Retorna Cursor de Erros vazio
    WT2_UTILITY_UTL.GetDummyCursor(CUR_ERR);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      WT2_AUDIT_UTL.AuditError('Erro CorpLevelAccMaintenance - ' || SQLCODE || ' - ' || SQLERRM);
      --
      pCOD_RET := SQLCODE;
      vErro    := SUBSTR(SQLERRM, 1, 500);
      OPEN CUR_ERR FOR
        SELECT vErro AS MESSAGE,
               vErro AS MESSAGETYPE,
               vErro AS SHORTMESSAGE,
               0 AS ITEMINDEX
          FROM DUAL;
      --
      WT2_UTILITY_UTL.GetDummyCursor(CUR_OUT);
      --
  END CorpLevelAccMaintenance;
  --                                                                                
END WT2_SNN_ACCOUNTCORPLEVEL_INT;
