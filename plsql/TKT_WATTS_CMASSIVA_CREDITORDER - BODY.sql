CREATE OR REPLACE PACKAGE BODY TKT_WATTS_CMASSIVA_CREDITORDER IS
  -- *********************
  -- * INTERNAL TYPES    *
  -- *********************
    DATEFORMAT  CONSTANT VARCHAR2(30) := 'DDMMYYYYHH24MISS';
    TYPE T_CURSOR IS REF CURSOR;
  -- Situacao de processamento 
    ARQ_NAO_PROC    CONSTANT NUMBER(1):= 1; -- Nao Process
    PROC_S_VALID    CONSTANT NUMBER(1):= 2; -- Process OK sem validar
    PROC_C_ERRO     CONSTANT NUMBER(1):= 3; -- Process Erro
    PROC_VALID_OK   CONSTANT NUMBER(1):= 4; -- Validado OK
    PROC_VALID_ERRO CONSTANT NUMBER(1):= 5; -- Validado com erro

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
    vCdGestor     NUMBER;
    vNumPedido    NUMBER;
    vValor        NUMBER; 
    vDtAgendam    DATE;
    vCd_Bas        NUMBER;   
    vCdMercador   NUMBER;   
    vQtMercador   NUMBER;   
    vVlMercador   NUMBER;  
    vQtdKm        NUMBER;
    vRendimento   NUMBER;
    vCD_TST_SEQ   NUMBER;
    vERRO EXCEPTION;
    v_contador      NUMBER;
  
  ---------------------------------------------------------------------
  PROCEDURE P_HEADER( PCD_ARQ        IN NUMBER,  
                                PCD_TST_SEQ    IN INTEGER,
                                PTP_PRC        IN PTC_CMS_ARQ.TP_PRC%TYPE,
                                PTP_ACA        IN PTC_CMS_ARQ.TP_ACA%TYPE,
                                PDATAHORA      IN DATE,
                                PCD_BAS        IN NUMBER,
                                PCD_GST        IN NUMBER,
                                PNU_LIN        IN OUT INTEGER,
                                PMSG_USER         OUT VARCHAR2,
                                PCOD_RET          OUT NUMBER,
                                PMSG_RET          OUT VARCHAR2 ) IS
  vListaPar   TKT_WATTS_GERADOR_CARGA_MASSIV.TListaCtd;
  vLinha      VARCHAR2(4000);
  vMsg        VARCHAR2(1000);
  BEGIN

  /*  -- Criar   Header
    vMsg:= 'criar registro header';
    PNU_LIN:= PNU_LIN + 1;
    vListaPar('TipoRegistro')   := '0';
    vListaPar('NroLinha')       := PNU_LIN;
    vListaPar('NroRemessa')     := PCD_TST_SEQ;
    vListaPar('DataGeracao')    := TO_CHAR(PDATAHORA, DATEFORMAT);

    --
    TKT_WATTS_GERADOR_CARGA_MASSIV.FormataLinhaTXT(PCD_REG_MDL =>  68,
                                                   PListaPar   =>  vListaPar,
                                                   PLinha      =>   vLinha);
                 
    TKT_WATTS_GERADOR_CARGA_MASSIV.CRIAR_TKT_ARQ_CTD(PCD_ARQ => PCD_ARQ,
                 PNU_LIN => PNU_LIN,
                 PLINHA  => vLinha,
                 PCD_TST_SEQ => PCD_TST_SEQ,
                 PNU_REG     => 'HEADER');
                         */
    -- Criar  Detalhe 01 - Autenticação
    
    vMsg:= 'criar registro header';
    PNU_LIN:= PNU_LIN + 1;
    vListaPar('TipoRegistro')   := '0';
    vListaPar('NroLinha')       := PNU_LIN;
    vListaPar('NroRemessa')     := '999';
    vListaPar('DataGeracao')    := TO_CHAR(PDATAHORA, DATEFORMAT);
    vListaPar('NomeInterface')  := 'INT1027.17 - DISPERSION DE CREDITOS';

    TKT_WATTS_GERADOR_CARGA_MASSIV.FormataLinhaTXT(PCD_REG_MDL => 29,
                 PListaPar  => vListaPar, 
                 PLinha     => vLinha);
                 
    TKT_WATTS_GERADOR_CARGA_MASSIV.CRIAR_TKT_ARQ_CTD(PCD_ARQ => PCD_ARQ,
                 PNU_LIN => pNU_LIN,
                 PLINHA  => vLinha,
                 PCD_TST_SEQ => PCD_TST_SEQ,
                 Pnu_reg => 'HEADER');


   
  --      
  -- INSERE TIPO 2 - Detalhe 01 - Autenticacao   MDL_REG = 30
  --    
  
    vMsg:= 'criar registro Autenticacao';
    PNU_LIN:= PNU_LIN + 1;
    vListaPar('TipoRegistro')   := '1';
    vListaPar('NroLinha')       := PNU_LIN;
    vListaPar('Manager')        := to_char(pCD_GST) ;
    vListaPar('Base')           := to_char(pCD_BAS) ;
    vListaPar('ActionType')     :=  nvl(PTP_ACA,'A');
    vListaPar('ProcessType')    :=  nvl(PTP_PRC,'F');

    TKT_WATTS_GERADOR_CARGA_MASSIV.FormataLinhaTXT(PCD_REG_MDL => 30,
                 PListaPar  => vListaPar, 
                 PLinha     => vLinha);
                 
    TKT_WATTS_GERADOR_CARGA_MASSIV.CRIAR_TKT_ARQ_CTD(PCD_ARQ => pCD_ARQ,
                 PNU_LIN => PNU_LIN,
                 PLINHA  => vLinha,
                 PCD_TST_SEQ => pCD_TST_SEQ,
                 Pnu_reg => 'AUTENTICATION');                 
    --
  EXCEPTION             
    WHEN OTHERS THEN
      --
      ROLLBACK;  
      --  
      PMSG_RET := 'Erro ao ' ||vMsg||': '||SQLERRM;
      PCOD_RET := 9999;
      PMSG_USER := PMSG_RET;
      --
  END;

  ---------------------------------------------------------------
  PROCEDURE P_TRAILLER( PCD_ARQ        IN NUMBER,  
                        PCD_TST_SEQ    IN INTEGER,
                        PDATAHORA      IN DATE,
                        PNU_LIN        IN OUT INTEGER,
                        PMSG_USER         OUT VARCHAR2,
                        PCOD_RET          OUT NUMBER,
                        PMSG_RET          OUT VARCHAR2 ) IS

  vListaPar   TKT_WATTS_GERADOR_CARGA_MASSIV.TListaCtd;
  vLinha      VARCHAR2(4000);
  vMsg        VARCHAR2(1000);
  BEGIN
    --
    -- 71	Trailer    
    vMsg:= 'criar registro trailler';
    PNU_LIN:= PNU_LIN + 1;
    
    vListaPar('TipoRegistro')   := '99';
    vListaPar('NroLinha')       := PNU_LIN;
    vListaPar('NroRemessa')     := PCD_TST_SEQ;
    vListaPar('DataRemessa')    := TO_CHAR(PDATAHORA, DATEFORMAT);
    vListaPar('QtdeRegistros')  := PNU_LIN;
    TKT_WATTS_GERADOR_CARGA_MASSIV.FormataLinhaTXT(PCD_REG_MDL => 33,
                 PListaPar  => vListaPar, 
                 PLinha     => vLinha);
    
    TKT_WATTS_GERADOR_CARGA_MASSIV.CRIAR_TKT_ARQ_CTD(PCD_ARQ => PCD_ARQ,
                 PNU_LIN => PNU_LIN,
                 PLINHA  => vLinha,
                 PCD_TST_SEQ => PCD_TST_SEQ,
                 PNU_REG     => 'TRAILLER');
    --
    COMMIT;    
    --        
  EXCEPTION             
    WHEN OTHERS THEN
      --
      ROLLBACK;  
      --
      PMSG_RET := 'Erro ao ' ||vMsg||': '||SQLERRM;
      PCOD_RET := 9999;
      PMSG_USER := PMSG_RET;
      --
  END;
    
  -----------------------------------------------------------------------  
  PROCEDURE P_GERAR(PTP_PRC           IN  PTC_CMS_ARQ.TP_PRC%TYPE,
                    PTP_ACA           IN  PTC_CMS_ARQ.TP_ACA%TYPE,
                    PQTREG            IN  NUMBER,
                    PQTREGERR         IN  NUMBER DEFAULT NULL,
                    PCD_TST_MAS       IN  PTC_TST_MAS.CD_TST_MAS%TYPE,
                    PDATAAGENDAMENTO  IN  DATE,
                    PVALOR            IN  NUMBER,
                    PINDPEDCRED       IN  NUMBER,
                    PINDTAGERR        IN  CHAR   DEFAULT NULL,  -- 1.2 Indica se são erros na Identif. de TAG (Numerica / Hex)
                    PCD_ARQ           OUT NUMBER,  
                    PMSG_USER         OUT VARCHAR2,
                    PCOD_RET          OUT NUMBER,
                    PMSG_RET          OUT VARCHAR2 ) IS
                      
  vListaPar   TKT_WATTS_GERADOR_CARGA_MASSIV.TListaCtd;
  vLinha      VARCHAR2(4000);
  vQuantErr   INTEGER;
  vQuantReg   INTEGER;
  vCD_ARQ     TKT_ARQ.CD_ARQ%TYPE;
  vNU_LIN     INTEGER;
  vCD_TST_SEQ INTEGER;
  v_DATA_HORA DATE;
  vMsg        VARCHAR2(1000);
  VCD_TST_MAS  PTC_TST_MAS.CD_TST_MAS%TYPE; 
  vTipoIdentif NUMBER(1);
  BEGIN
-- Osvaldo
MX_ADM.PRC_T1('TKT_WATTS_CMASSIVA_CREDITORDER > GERAR ');
MX_ADM.PRC_T1('TKT_WATTS_CMASSIVA_CREDITORDER > PTP_PRC = ' || PTP_PRC);
MX_ADM.PRC_T1('TKT_WATTS_CMASSIVA_CREDITORDER > PTP_ACA = ' || PTP_ACA);
MX_ADM.PRC_T1('TKT_WATTS_CMASSIVA_CREDITORDER > PQTREG = ' || PQTREG);
MX_ADM.PRC_T1('TKT_WATTS_CMASSIVA_CREDITORDER > PQTREGERR = ' || PQTREGERR);
MX_ADM.PRC_T1('TKT_WATTS_CMASSIVA_CREDITORDER > PCD_TST_MAS = ' || PCD_TST_MAS);
MX_ADM.PRC_T1('TKT_WATTS_CMASSIVA_CREDITORDER > PDATAAGENDAMENTO = ' || PDATAAGENDAMENTO);
MX_ADM.PRC_T1('TKT_WATTS_CMASSIVA_CREDITORDER > PVALOR = ' || PVALOR);
MX_ADM.PRC_T1('TKT_WATTS_CMASSIVA_CREDITORDER > PINDPEDCRED = ' || PINDPEDCRED);
MX_ADM.PRC_T1('TKT_WATTS_CMASSIVA_CREDITORDER > PINDTAGERR = ' || PINDTAGERR);

--
    PMSG_USER := null;
    PCOD_RET  := 0;
    PMSG_RET  := null;
    -- Checa parametros
    --
    VCD_TST_MAS:= PCD_TST_MAS;
    v_DATA_HORA:= systimestamp;
    vNU_LIN:= 0;
    vQuantErr := NVL(PQTREGERR,0);
    vQuantReg := NVL(PQTREG,0);        
    --
    if pValor is null then
      PMSG_USER := 'VALOR UNITARIO NAO PREENCHIDO';
      PCOD_RET  := -1;
      PMSG_RET  := 'VALOR UNITARIO NAO PREENCHIDO';
      Raise vERRO;
    end if;    
    vValor        := PVALOR*100; 
    vDtAgendam    := NVL(PDATAAGENDAMENTO, SYSDATE);
    --
    vMsg:= 'coletar parametro iniciais';
    --
    IF VCD_TST_MAS IS NULL THEN
      SELECT MAX(CD_TST_MAS)
      INTO VCD_TST_MAS
      FROM PTC_TST_MAS M
      WHERE M.CD_TST_FUN = 119;
    END IF;   
    --
    --    
    v_contador:= 0;
    FOR H IN (SELECT ATB1.VL_ATB CD_BAS, COUNT(1) CONT, MIN(DAD.ID_TAG_NFC), MIN(DAD.NU_TAG_NFC) 
               FROM PTC_TST_MAS_LIN ATB1, PTC_TST_MAS_LIN ATB2, 
                    PTC_VEI_EQP     VEI,
                    PTC_DAD_VEI_EQP DAD,
                    PTC_CAT         CAT
               WHERE VCD_TST_MAS IS NOT NULL
                 AND ATB1.CD_TST_MAS = VCD_TST_MAS 
                 AND ATB1.DC_ATB = 'CorporateLevelIdentification'
                 AND ATB2.CD_TST_MAS = ATB1.CD_TST_MAS  
                 AND ATB2.NU_LIN     = ATB1.NU_LIN 
                 AND ATB2.DC_ATB = 'CardNumber' 
                 AND CAT.NU_CAT = ATB2.VL_ATB
                 AND VEI.CD_PTD = CAT.CD_PTD
                 AND DAD.CD_VEI_EQP = VEI.CD_VEI_EQP
              GROUP BY ATB1.VL_ATB
              HAVING COUNT(1) >= PQTREG
              ORDER BY MIN(DAD.NU_TAG_NFC), MIN(DAD.ID_TAG_NFC),  DBMS_RANDOM.VALUE) LOOP
      vCd_Bas:= H.CD_BAS;
      v_contador:= H.CONT;
      EXIT;
    END LOOP;    
    --
    IF nvl(v_contador,0) = 0 then
      --
      PMSG_USER := 'NAO FORAM ENCONTRADOS REGISTROS PARA A  SELECAO';
      PCOD_RET  := -1;
      PMSG_RET  := 'NAO FORAM ENCONTRADOS REGISTROS PARA A  SELECAO';
      Raise vERRO;
      --
    END IF;  
    --
    SELECT MAX(G.CD_GST)
    INTO vCdGestor
    FROM PTC_BAS B, PTC_CLI C, PTC_GST G
    WHERE B.CD_BAS = vCd_Bas
      AND C.CD_CLI = B.CD_CLI
      AND G.CD_CSL = C.CD_CSL
      AND G.CD_STA_USU = 1
      AND G.CD_TIP_GST = 5;
    --
    
    --       
    -----------------------------------------------------------------------------
    --    Capturar dados
    -----------------------------------------------------------------------------
 
    -- Gera novo numero do Pedido
    vNumPedido := '9999000000'; 
  
    -- Se ja existir na area de carga, pega o primeiro numero livre
     select nvl(max(to_number((b.vl_ctd)) +1) , 9999000000)
       into vNumPedido
     FROM PTC_CMS_ARQ a, PTC_CMS_CTD b
      WHERE a.cd_arq = b.cd_arq
        AND a.cd_mdl_arq in ( 803,810)
        AND b.cd_mdl_ctd  in (25,346) 
        and to_number(b.vl_ctd) >= 9999000000;
     IF   vNumPedido is null then
       vNumPedido :=9999000000;
     END IF; 
     -- 

  ------------------------------GERACAO DO ARQUIVO -----------------------
  --
    vMsg:= 'coletar parametro iniciais';
    vNU_LIN:= 0;
    v_DATA_HORA:= systimestamp;
    --  INSERE CONTROLE DE INTERFACES 
    --
  
    vMsg:= 'criar controle de interface';
    vCD_TST_SEQ:= TKT_WATTS_GERADOR_CARGA_MASSIV.CRIAR_CONTROLE_INTERF(21,NULL);
    vCD_ARQ:= TKT_WATTS_GERADOR_CARGA_MASSIV.CRIAR_TKT_ARQ(PCD_MDL_ARQ => '4', PCD_TST_SEQ => vCD_TST_SEQ); 
    PCD_ARQ:= vCD_ARQ;
    --
    TKT_WATTS_GERADOR_CARGA_MASSIV.ATUALIZA_CONTROLE_INTERF(vCD_TST_SEQ, vCD_ARQ);

    P_HEADER( PCD_ARQ        => vCD_ARQ,
              PCD_TST_SEQ    => vCD_TST_SEQ,
              PTP_PRC        => PTP_PRC,
              PTP_ACA        => PTP_ACA,
              PDATAHORA      => v_DATA_HORA,
              PCD_BAS        => vCD_BAS,
              PCD_GST        => vCdGestor,
              PNU_LIN        => vNU_LIN,
              PMSG_USER      => PMSG_USER,
              PCOD_RET       => PCOD_RET,
              PMSG_RET       => PMSG_RET);
    --      
    -- INSERE TIPO 3 - Detalhe 02 - Cabecalho Pedido   MDL_REG = 31
    --
    -- insere pedido no controle de interfaces   
  
    vMsg:= 'criar registro Cabecalho Pedido';
    vNU_LIN:= vNU_LIN + 1;
    vListaPar('TipoRegistro')   := '2';
    vListaPar('NroLinha')       := vNU_LIN;
    vListaPar('NroPedido')      := to_char(vNumPedido);
    vListaPar('DataPedido')     := to_char(vDtAgendam,'DDMMYYYY');
    vListaPar('Obs')            := 'PEDIDO DE DISPERSION CLIENTE AVANZADO';
    vListaPar('QtdItens')       := to_char(PQTREG);
    vListaPar('IndPedCredito')  := nvl(PINDPEDCRED,2);
    vListaPar('ValorPedido')    := to_char(PQTREG * vValor);  

    TKT_WATTS_GERADOR_CARGA_MASSIV.FormataLinhaTXT(PCD_REG_MDL => 31,
                 PListaPar  => vListaPar, 
                 PLinha     => vLinha);
                 
    TKT_WATTS_GERADOR_CARGA_MASSIV.CRIAR_TKT_ARQ_CTD(PCD_ARQ => vCD_ARQ,
                 PNU_LIN => vNU_LIN,
                 PLINHA  => vLinha,
                 PCD_TST_SEQ => vCD_TST_SEQ,
                 Pnu_reg => to_char(vNumPedido));
    --      
    -- INSERE TIPO 4 - Detalhe 03 - Distribuic?o aos Cartoes   MDL_REG = 32
    -- 
     vCdMercador  := null;   
     vQtMercador  := null;  
     vVlMercador  := null;  
     vQtdKm       := null;
     vRendimento  := null;
     vTipoIdentif := 0;
     FOR Reg IN ( SELECT TO_NUMBER(ATB1.VL_ATB) CardNumber,
                      TO_NUMBER(ATB2.VL_ATB) PrimeCompanyIdentification,
                      TO_NUMBER(ATB3.VL_ATB) CustomerIdentification,
                      TO_NUMBER(ATB4.VL_ATB) CorporateLevelIdentification,
                      TO_NUMBER(ATB5.VL_ATB) CustomerManagerIdentification,
                      DAD.ID_TAG_NFC,
                      DAD.NU_TAG_NFC,
                      CAT.*
                    FROM PTC_TST_MAS_LIN ATB1,
                         PTC_TST_MAS_LIN ATB2,
                         PTC_TST_MAS_LIN ATB3,
                         PTC_TST_MAS_LIN ATB4,
                         PTC_TST_MAS_LIN ATB5,
                         PTC_VEI_EQP     VEI,
                         PTC_DAD_VEI_EQP DAD,
                         PTC_CAT         CAT
                    WHERE VCD_TST_MAS IS NOT NULL
                      AND ATB1.CD_TST_MAS = VCD_TST_MAS    
                      AND ATB2.CD_TST_MAS = ATB1.CD_TST_MAS    
                      AND ATB3.CD_TST_MAS = ATB1.CD_TST_MAS    
                      AND ATB4.CD_TST_MAS = ATB1.CD_TST_MAS 
                      AND ATB5.CD_TST_MAS = ATB1.CD_TST_MAS 
                      AND ATB2.NU_LIN     = ATB1.NU_LIN  
                      AND ATB3.NU_LIN     = ATB1.NU_LIN  
                      AND ATB4.NU_LIN     = ATB1.NU_LIN  
                      AND ATB5.NU_LIN     = ATB1.NU_LIN  
                      AND ATB1.DC_ATB = 'CardNumber' 
                      AND ATB2.DC_ATB = 'PrimeCompanyIdentification' 
                      AND ATB3.DC_ATB = 'CustomerIdentification' 
                      AND ATB4.DC_ATB = 'CorporateLevelIdentification' 
                      AND ATB5.DC_ATB = 'CustomerManagerIdentification'
                      AND TO_NUMBER(ATB4.VL_ATB) = vCD_Bas
                      AND CAT.NU_CAT = ATB1.VL_ATB
                      AND VEI.CD_PTD = CAT.CD_PTD
                      AND DAD.CD_VEI_EQP = VEI.CD_VEI_EQP
                      AND ROWNUM <= NVL(PQTREG, 1000)
                      ORDER BY DAD.ID_TAG_NFC, DAD.NU_TAG_NFC
                   ) LOOP
      vQuantReg   := vQuantReg + 1;
      vTipoIdentif:= vTipoIdentif + 1;
      IF vTipoIdentif > 7 THEN
        vTipoIdentif:= 1;
      END IF;  
      
 /*     IF  vQuantReg > nvl(PQTREG,0) and  nvl(PQTREG,0) <> 0    THEN
         EXIT;
      END IF; */
      vMsg:= 'criar registro Distribuicao de credito';
      vNU_LIN:= vNU_LIN + 1;
      vListaPar('TipoRegistro')   := '3';
      vListaPar('NroLinha')       := vNU_LIN;
      vListaPar('NroPedido')      := to_char(vNumPedido);
      
      -- Forçar erro informando cartao inexistente
      vListaPar('NroCartao')      := to_char(Reg.CardNumber );
      vListaPar('TagNfcNum')      := to_char(Reg.Nu_Tag_Nfc );
      vListaPar('TagNfcId')       := to_char(Reg.Id_Tag_Nfc );
      --
      IF UPPER(NVL(PINDTAGERR,'F')) = 'F' THEN -- 1.2
        --
        IF vTipoIdentif = 1 THEN
          NULL;
        ELSIF vTipoIdentif = 2 AND
              vListaPar('TagNfcNum')  IS NOT NULL AND
              vListaPar('TagNfcId') IS NOT NULL THEN
          vListaPar('NroCartao')      := NULL;
        ELSIF vTipoIdentif = 3 THEN
          vListaPar('TagNfcNum')      := NULL;
        ELSIF vTipoIdentif = 4 THEN
          vListaPar('TagNfcId')       := NULL;
        ELSIF vTipoIdentif = 5  AND
              vListaPar('TagNfcId') IS NOT NULL THEN
          vListaPar('NroCartao')      := NULL;
          vListaPar('TagNfcNum')      := NULL;
        ELSIF vTipoIdentif = 6  AND
              vListaPar('TagNfcNum')  IS NOT NULL THEN
          vListaPar('NroCartao')      := NULL;
          vListaPar('TagNfcId')       := NULL;
        ELSIF vTipoIdentif = 7 THEN
          vListaPar('TagNfcNum')      := NULL;
          vListaPar('TagNfcId')       := NULL;
        END IF; 
      --
      END IF; -- 1.2
      --
      IF vQuantErr > 0 THEN
        --
        IF UPPER(NVL(PINDTAGERR,'F')) = 'F' THEN -- 1.2
          IF vTipoIdentif = 1 THEN
            vListaPar('NroCartao')      := NULL;
            vListaPar('TagNfcNum')      := NULL;
            vListaPar('TagNfcId')       := NULL;
          ELSE
            IF vListaPar('NroCartao') IS NOT NULL THEN
             vListaPar('NroCartao')      := '9999999999999999999';
            ELSIF vListaPar('TagNfcNum') IS NOT NULL THEN
             vListaPar('TagNfcNum')      := '9999999999999999999';
            ELSIF vListaPar('TagNfcId') IS NOT NULL THEN
             vListaPar('TagNfcId')      := '9999999999999999999';
            END IF;    
          END IF;
          --
        ELSE     -- 1.2
          --
          -- 1.2 Cenarios para testes da identificacao do cartao
          --
          IF    MOD(vTipoIdentif,4) = 1 THEN  -- Dados gerados pela massa
             vListaPar('TagNfcId')   := '9999999999999999999';
             vListaPar('TagNfcNum')  :=  NULL;
          ELSIF MOD(vTipoIdentif,4) = 2 THEN  -- NroCartão é nulo
             vListaPar('TagNfcId')   :=  NULL;
             vListaPar('TagNfcNum')  := '9999999999999999999';
          ELSIF MOD(vTipoIdentif,4) = 3 THEN  
             vListaPar('TagNfcId')   := '9999999999999999999';
             vListaPar('TagNfcNum')  := '9999999999999999999';
          ELSE -- MOD(vTipoIdentif,4) = 0
             vListaPar('TagNfcNum')  := NULL;          
          END IF;           
        END IF; -- 1.2
        --
        vQuantErr:= vQuantErr - 1;
      END IF;
      --
      vListaPar('Valor')          := to_char(vValor);
      vListaPar('SaldoCartao')    := '0';
      vListaPar('Obs')            := 'PEDIDO DE DISPERSION CLIENTE AVANZADO';
      vListaPar('TpCredito')      := '1';
      vListaPar('TpDistribuicao') := 1; -- 1 MONTO
      vListaPar('Mercadoria')     := '';
      vListaPar('QtdMercadoria')  := '';
      vListaPar('DtExpiracao')    :=  '01012999';
      vListaPar('Rota')           := ''; 
      vListaPar('QtdKM')          := '';
      vListaPar('Rendimento')     := '';
      vListaPar('Portador')       := Reg.cd_pTD;
       
/*Moeda
SaldoCartao
PrecoMercadoria*/

      TKT_WATTS_GERADOR_CARGA_MASSIV.FormataLinhaTXT(PCD_REG_MDL => 32,
                   PListaPar  => vListaPar, 
                   PLinha     => vLinha);
                   
      TKT_WATTS_GERADOR_CARGA_MASSIV.CRIAR_TKT_ARQ_CTD(PCD_ARQ => vCD_ARQ,
                   PNU_LIN => vNU_LIN,
                   PLINHA  => vLinha,
                   PCD_TST_SEQ => vCD_TST_SEQ,
                   Pnu_reg => to_char(vNumPedido));
    END LOOP; 

    --      
    -- INSERE TIPO 5 - TRAILLER   MDL_REG = 33
    --
    P_TRAILLER( PCD_ARQ        => vCD_ARQ,
                PCD_TST_SEQ    => vCD_TST_SEQ,
                PDATAHORA      => v_DATA_HORA,
                PNU_LIN        => vNU_LIN,
                PMSG_USER      => PMSG_USER,
                PCOD_RET       => PCOD_RET,
                PMSG_RET       => PMSG_RET); 
    --             
    IF NVL(PCOD_RET, 0) <> 0 THEN
      RETURN;
    END IF;      
    --
    --
    COMMIT;    
    --     
  exception
    when vERRO then
      ROLLBACK;
      Raise_Application_ERROR(-20999, PMSG_RET);
    when others then
      ROLLBACK;
      PMSG_USER := 'ERRO NA GERACAO DE PEDIDO - ' || SQLERRM;
      PCOD_RET  := -1;
      PMSG_RET := 'Erro ao ' ||vMsg||': '||SQLERRM;
      Raise_Application_ERROR(-20999, 'ERRO GENERICO' || SQLERRM);
  END; 
  --

  PROCEDURE P_ANALISE(PCD_ARQ_TKT TKT_ARQ.CD_ARQ%TYPE,
                      PDETALHES IN BOOLEAN ,
                      PANALISE OUT CLOB) IS
   vAnalise CLOB; 
   vLinha   CLOB; 
   vAux     VARCHAR2(500);  
   vVei     BOOLEAN; 
   vPed     NUMBER;
   vStsPed  NUMBER;  
   vCurOut               T_CURSOR;
   vCardOperationList    RCurCardOperationCardList;
   vCardFin NUMBER;
   vCartao  VARCHAR2(100);
   vHead    BOOLEAN;
  BEGIN
    --
    -- Arquivos Gerados
    FOR ARQ IN (select t.cd_arq, a.cd_arq arq_cms, A.CD_CSL, A.CD_GST, A.CD_BAS, A.CD_CLI,
                d.cd_dom, m.ds_mdl_arq, a.tp_prc, a.tp_aca, a.cd_sta_cmm, s.dc_sta_cmm,
                a.nm_arq, a.NU_TOT_LIN, a.dt_ini_prc, a.dt_fim_prc, round((a.dt_fim_prc-a.dt_ini_prc)*24*60,2) QT_MIN_PRC,
                (SELECT COUNT(1) 
                 FROM PTC_CMS_MDL_REG MR , PTC_CMS_REG RE
                 WHERE MR.CD_MDL_ARQ = A.CD_MDL_ARQ 
                   AND RE.CD_ARQ     = A.CD_ARQ
                   AND RE.CD_MDL_REG = MR.CD_MDL_REG
                   AND MR.IN_TOT_REG = 'T'
                   AND RE.CD_MSG_ERR IS NULL) QT_LIN_PRC,
                 (SELECT COUNT(1) 
                 FROM PTC_CMS_MDL_REG MR , PTC_CMS_REG RE
                 WHERE MR.CD_MDL_ARQ = A.CD_MDL_ARQ 
                   AND RE.CD_ARQ     = A.CD_ARQ
                   AND RE.CD_MDL_REG = MR.CD_MDL_REG
                   AND MR.IN_TOT_REG = 'T'
                   AND RE.CD_MSG_ERR IS NOT NULL) QT_LIN_ERR,
                 (SELECT COUNT(1) 
                   FROM MX_ADM.TKT_CMS_1027_28_ORDER_DETAIL I
                   WHERE I.FILEID = A.CD_ARQ
                     AND I.EFFECT = 'P' ) QT_LIN_INT_PRC,
                  (SELECT COUNT(1) 
                   FROM MX_ADM.TKT_CMS_1027_28_ORDER_DETAIL I
                   WHERE I.FILEID = A.CD_ARQ
                     AND I.EFFECT <> 'P' ) QT_LIN_INT_ERR            
              from mx_adm.tkt_arq t, mx_adm.ptc_cms_arq a, mx_adm.ptc_cms_mdl_arq m, mx_adm.ptc_sta_cmm s, mx_adm.PTC_CMS_ARQ_DOM D
              where a.cd_arq = t.cd_cms_arq(+)
                and a.cd_mdl_arq = m.cd_mdl_arq
                and s.cd_sta_cmm = a.cd_sta_cmm
                and d.cd_arq (+)= a.cd_arq
                --AND a.cd_arq = PCD_CMS_ARQ
                AND t.cd_arq = PCD_ARQ_TKT
                AND D.CD_DOM = 5
              order by 2 DESC) LOOP

      vAnalise:=  '-- VISAO GERAL DO PROCESSAMENTO --'||CHR(13)||  
                 'Cod. Arquivo Tkt;'  || ARQ.CD_ARQ || ';Cod. Arquivo Cms;'|| ARQ.ARQ_CMS||chr(13)||
                 'Consolidador;'      || ARQ.CD_CSL || ';Corporate Level;' || ARQ.CD_BAS || ';Gestor;' || ARQ.CD_GST ||';Cliente;'|| ARQ.CD_CLI || chr(13)||
                 'Dominio;'           || ARQ.CD_DOM || ' - ' || ARQ.DS_MDL_ARQ || chr(13)||
                 'Tipo Processamento;'|| ARQ.TP_PRC ||';Tipo Ação;'|| ARQ.TP_ACA|| chr(13) ||
                 'Resultado;'         || ARQ.CD_STA_CMM||' - '|| ARQ.DC_STA_CMM|| chr(13)||
                 --ARQ.NM_ARQ, 
                 'Linhas do arquivo;'  || ARQ.NU_TOT_LIN ||chr(13)||
                 'Inicio proc.;'       || TO_CHAR(ARQ.DT_INI_PRC,'DD/MM/YYYY HH24:MI:SS') || ';Fim proc.;'|| TO_CHAR(ARQ.DT_FIM_PRC,'DD/MM/YYYY HH24:MI:SS')||'; Minutos;'|| ARQ.QT_MIN_PRC || chr(13)||
                 chr(13)||
                 '> Processamento Geral' ||chr(13)||
                 '  Linhas sem erro;' || ARQ.QT_LIN_PRC ||chr(13)||
                 '  Linhas com erro;'    || ARQ.QT_LIN_ERR ||chr(13)|| 
                 chr(13)||
                 '> Processamento Interface Sunnel' ||chr(13)||
                 '  Linhas processadas;' || ARQ.QT_LIN_INT_PRC ||chr(13)||
                 '  Linhas com erro;'    || ARQ.QT_LIN_INT_ERR;
      --
      --
      vAnalise:= vAnalise || chr(13);
      -- Ordem criada
      vAnalise:= vAnalise || chr(13);
      vAnalise:= vAnalise || 'DADOS DO PEDIDO' || chr(13);
      FOR ORD IN (SELECT P.*, S.DC_STA_PED_TKT, T.DC_TIP_PED
                  FROM PTC_CMS_ARQ_PED A, PTC_PED P, PTC_STA_PED S, PTC_TIP_PED T
                  WHERE A.CD_ARQ = ARQ.arq_cms
                    AND A.NU_PED = P.NU_PED
                    AND S.CD_STA_PED = P.CD_STA_PED
                    AND T.CD_TIP_PED = P.CD_TIP_PED) LOOP
        vPed:= Ord.Nu_Ped ;            
        vAnalise:= vAnalise || chr(13);                    
        vAnalise:= vAnalise || 'Pedido gerado: '|| Ord.Nu_Ped  ||' Data: '|| Ord.Dt_Ped|| chr(13);
        vAnalise:= vAnalise || Ord.Cd_Tip_Ped||' '|| Ord.Dc_Tip_Ped || chr(13);
        vAnalise:= vAnalise || 'Status: '|| Ord.Cd_Sta_Ped|| ' '||Ord.Dc_Sta_Ped_Tkt|| chr(13);
        vAnalise:= vAnalise || 'Obs.: '|| Ord.Dc_Obs || chr(13);
        
        FOR ITE IN (SELECT I.*, D.DC_TIP_PED, T.DC_STA_PED_USU
                  FROM PTC_ITE_PED I, PTC_TIP_PED D, ptc_Sta_Tip_Itm_Ped T
                  WHERE I.NU_PED = ORD.NU_PED
                    AND D.CD_TIP_PED = I.CD_TIP_PED
                    AND T.CD_TIP_PED = I.CD_TIP_PED
                    AND T.CD_STA_TIP_ITM_PED = I.CD_STA_TIP_ITM_PED) LOOP
                    
           vAnalise:= vAnalise || Ite.dc_tip_ped|| ' - ' || Ite.DC_STA_PED_USU || ',  Qtd.: '|| Ite.Qt_Ite_Ped || ',  Pedido Sunnel: '|| Ite.Nu_Ped_Snn || chr(13);
        END LOOP;   
      END LOOP;         
      vAnalise:= vAnalise || chr(13);
      -- 
      -- Interface
      vAnalise:= vAnalise || chr(13);
      vAnalise:= vAnalise || 'DADOS ORDEM INTERFACE - GT' || chr(13);
      FOR INTERF IN (SELECT * FROM MX_INTERFACE.TKT_CMS_1027_28_ORDER_HEADER
                     WHERE FILEID = ARQ.arq_cms) LOOP
         vAnalise:= vAnalise || chr(13);    
         vAnalise:= vAnalise || 'Id Ordem: ' || Interf.Orderid || CHR(13);
         vAnalise:= vAnalise || 'Num Ordem: ' || Interf.Ordernumber || CHR(13);
         vAnalise:= vAnalise || 'Dt. Agendamento: ' || Interf.Scheduledate || CHR(13);
         vAnalise:= vAnalise || 'Valor: ' || Interf.Creditamount || CHR(13);
         vAnalise:= vAnalise || 'Effect: ' || Interf.Effect || CHR(13);
         vAnalise:= vAnalise || 'Mensagem Erro: ' || Interf.Responsemessage || CHR(13);
         vAnalise:= vAnalise || 'Codigo Erro: ' || Interf.Responsecode || CHR(13);
         
         SELECT DECODE(COUNT(1),0,'*** Pedido NAO criado no SUNNEL', '*** Pedido criado no SUNNEL')
         INTO vAux
         FROM T_GORDER O 
         WHERE O.ORDERID=Interf.Orderid;
         vAnalise:= vAnalise || vAux;
      END LOOP;
      vAnalise:= vAnalise || chr(13);               
      --
            
      IF PDETALHES THEN
        --                                     
        -----------------------------------------------------
        -----------------------------------------------------                               
         -- HEADER
         vAnalise:= vAnalise || chr(13)|| chr(13)|| '-- DETALHES -- '|| CHR(13)||
                     'EXEC;'         ||
                     'NU_REG;'       || 
                     'Cartao;'       ||
                     'Tag NFC Num;'  ||
                     'Tag NFC Id;'   ||
                     'Reg Erro;'     ||
                     'Reg. Mensagem;'||
                     'Interf. Valor;'    ||
                     'Interf. Oper;'    ||
                     'Interf. Tipo;'    ||
                     'Interf. Effect;'   || 
                     'Interf. Code;'     ||
                     'Interf. Message;'  || 
                     'Cartao Financ.;'||
                     'Portador;'||
                     'Tipo Tecn.;'||
                     'Status;'||
                     'Conta;'||                     
                     'Status;'||                     
                     'Dt.Status;'||                                                               
                    /* 'Cred/Deb;'||
                     'Data;'||
                     'Valor;'||
                     'Tipo;'||*/
                     'Pedido;'||
                     'Valor;'||
                     'Dt.Agend;'||
                     'Status;'||
                     'Mensagem;'||
                     'Data;'||
                     chr(13);
        --   
        -- Cartoes
        vVei:= FALSE;
        FOR CAR IN (SELECT C.NU_REG,
                           C.VL_CTD CARTAO,
                           C1.VL_CTD TAGNFCNUM,
                           C2.VL_CTD TAGNFCID
                    FROM MX_ADM.PTC_CMS_CTD C,
                         MX_ADM.PTC_CMS_CTD C1,
                         MX_ADM.PTC_CMS_CTD C2
                    WHERE C.cd_arq      = ARQ.arq_cms
                      AND C.CD_MDL_CTD  = 356
                      AND C1.cd_arq     = ARQ.arq_cms
                      AND C1.NU_REG     = C.NU_REG
                      AND C1.CD_MDL_CTD = 785
                      AND C2.cd_arq     = ARQ.arq_cms
                      AND C2.NU_REG     = C.NU_REG
                      AND C2.CD_MDL_CTD = 786
                    ORDER BY NU_REG) LOOP 

          vLinha:= car.Nu_Reg          || ';' ||
                   ''''||car.cartao    || ';' ||
                   ''''||car.TAGNFCNUM || ';' ||
                   ''''||car.TAGNFCID  || ';' ;  
          vCartao:= car.cartao ;
          IF car.cartao IS NULL THEN
            IF car.TAGNFCNUM IS NOT NULL THEN
              SELECT MAX(CAT.NU_CAT)
              INTO vCartao
              FROM PTC_DAD_VEI_EQP DAD, PTC_VEI_EQP VEI, PTC_CAT CAT
              WHERE DAD.NU_TAG_NFC = car.TAGNFCNUM
               AND VEI.CD_VEI_EQP = DAD.CD_VEI_EQP
               --AND VEI.CD_BAS = ARQ.CD_BAS
               AND CAT.CD_PTD = VEI.CD_PTD
               AND CAT.CD_BAS = VEI.CD_BAS;
            END IF;
            IF car.TAGNFCID IS NOT NULL THEN
              SELECT MAX(CAT.NU_CAT)
              INTO vCartao
              FROM PTC_DAD_VEI_EQP DAD, PTC_VEI_EQP VEI, PTC_CAT CAT
              WHERE DAD.ID_TAG_NFC = car.TAGNFCID
               AND VEI.CD_VEI_EQP = DAD.CD_VEI_EQP
               --AND VEI.CD_BAS = ARQ.CD_BAS
               AND CAT.CD_PTD = VEI.CD_PTD
               AND CAT.CD_BAS = VEI.CD_BAS;
            END IF;            
          END IF;
          -- Registro de Erros
          FOR Erro IN (SELECT NU_REG, MR.CD_MDL_REG, DS_MSG_ERR, CD_MSG_ERR,  
                           DECODE(IT.FILEID, NULL, '(sem interf.)', NVL(IT.EFFECT,'X')) IN_INT_EFF, 
                           IT.RESPONSECODE, IT.RESPONSEMESSAGE,
                           IT.VALUE, IT.TRANSACTIONAMOUNT, IT.OPERATIONCLASS, IT.CREDITTYPE
                    FROM mx_adm.PTC_CMS_REG RE, 
                         mx_adm.TKT_CMS_1027_28_ORDER_DETAIL IT, 
                         mx_adm.PTC_CMS_MDL_REG MR
                    WHERE CD_ARQ       = ARQ.arq_cms
                      AND IT.Fileid    (+)= RE.CD_ARQ 
                      AND IT.ROWNUMBER (+)= RE.NU_REG
                      AND MR.CD_MDL_REG = RE.CD_MDL_REG
                      AND MR.IN_TOT_REG = 'T'
                      AND RE.NU_REG = CAR.NU_REG) LOOP
            --
            vLinha:= vLinha||
                     Erro.Cd_Msg_Err     || ';' ||
                     SUBSTR(REPLACE(REPLACE(Erro.Ds_Msg_Err,     ';', ' '),CHR(10), ' '), 1, 100) || ';' ||
                     Erro.Transactionamount || ';' ||
                     Erro.Operationclass || ';' ||
                     Erro.Credittype || ';' ||
                     SUBSTR(REPLACE(REPLACE(Erro.In_Int_Eff,     ';', ' '),CHR(10), ' '), 1, 100) || ';' ||
                     SUBSTR(REPLACE(REPLACE(Erro.Responsecode,   ';', ' '),CHR(10), ' '), 1, 100) || ';' ||
                     SUBSTR(REPLACE(REPLACE(Erro.Responsemessage,';', ' '),CHR(10), ' '), 1, 100) || ';' ;
            --         
          END LOOP;
          --
          -- BD - Cartao e conta
          IF vCartao IS NULL THEN
              vLinha:= vLinha  
                          || ';' 
                          || ';' 
                          || ';' 
                          || ';' 
                          || ';' ||
                          ';' ;            
          ELSE
            FOR REG IN (SELECT CA.*, CC.ACCOUNTID, CO.STATUS, CO.STATUSDATE
                        FROM MX_ADM.PTC_CAT CA, 
                             MX_ADM.T_GCARDACCOUNT CC, 
                             MX_ADM.T_GACCOUNT     CO
                        WHERE CA.NU_CAT       = vCartao --CAR.CARTAO
                          AND CC.CARDID    (+)= CA.NU_CAT
                          AND CO.ACCOUNTID (+)= CC.ACCOUNTID) LOOP
              -- 
              IF REG.CD_TIP_CAT = 4 THEN
                 MX_ADM.WTMX_CARD_PKG.CardGetOperationCardList(CARDLIST  => REG.NU_CAT,
                                                           STARTPAGE => NULL,
                                                           PAGEROWS  => NULL,
                                                           CUR_OUT   => vCurOut);
                 --
                 FETCH vCurOut INTO vCardOperationList;
                 --
                 vLinha:= vLinha || vCardOperationList.NU_CAT_OPE || ';' ;
                 IF vCardOperationList.NU_CAT_OPE IS NOT NULL THEN
                    vCardFin:= vCardOperationList.NU_CAT_OPE;
                 END IF;  
              ELSE   
                vLinha:= vLinha || ';' ;
                vCardFin:= REG.NU_CAT;
              END IF;                 
              --
              vLinha:= vLinha ||  
                         Reg.Cd_Ptd         || ';' ||
                         Reg.Cd_Tip_Tcn_Cat || ';' ||
                         Reg.Cd_Sta_Cat     || ';' ||
                         Reg.Accountid      || ';' ||
                         Reg.Status         || ';' ||
                         TO_CHAR(Reg.Statusdate,'DD/MM/YYYY') || ';' ;
              --    
           END LOOP;
         END IF;
         
         -- PED FIN
         vStsPed:= NULL;
         FOR Ped IN (SELECT NU_PED, P.VL_PED_FIN_CAT, P.DT_AGD, P.CD_STA_ITE_PED_DET, DS_MSG_PRC, DT_EXE,
           D.DS_STA_ITE_PED_DET
                      FROM MX_ADM.PTC_PED_FIN_CAT P, MX_ADM.PTC_STA_ITE_PED_DET D
                      WHERE NU_PED = vPed
                      AND   NU_CAT = vCardFin --CAR.CARTAO
                      AND   D.CD_STA_ITE_PED_DET = P.CD_STA_ITE_PED_DET) LOOP
            vStsPed:= Ped.Cd_Sta_Ite_Ped_Det;          
            --DS_STA_ITE_PED_DET
            vLinha:= vLinha ||
                     Ped.NU_PED             ||';'||
                     Ped.Vl_Ped_Fin_Cat     ||';'||
                     TO_DATE(Ped.Dt_Agd, 'DD/MM/YYYY HH24:MI') ||';'||
                     Ped.Cd_Sta_Ite_Ped_Det||'-'||Ped.DS_STA_ITE_PED_DET ||';'||
                     Ped.Ds_Msg_Prc         ||';'||
                     Ped.Dt_Exe             ||';';              
           --  
         END LOOP;
            
         IF vStsPed IS NULL THEN
           vLinha:= 'NÃO GERADO;'||vLinha;
         ELSIF vStsPed = 2 THEN
           vLinha:= 'OK  GERADO;'||vLinha;  
         ELSE  
           vLinha:= 'NÃO GERADO;'||vLinha;
         END IF;  
         --                                    
         --
         vLinha:= vLinha ||';';
         --               
         --
         vAnalise:= vAnalise || chr(13)||vLinha;
         --
        END LOOP;
        --
        -- 1.1 Inicio
        -- Resposta da Carga Massiva
        --
        vHead := FALSE;
        --
        FOR RSP IN (SELECT C.NU_REG,
                          R.VL_RPT
                     FROM MX_ADM.PTC_CMS_CTD C,
                          MX_ADM.PTC_CMS_CTD C1,
                          MX_ADM.PTC_CMS_CTD C2,
                          PTC_CMS_REG_RPT    R 
                     WHERE C.cd_arq      = ARQ.arq_cms
                       AND C.CD_MDL_CTD  = 356
                       AND C1.cd_arq     = ARQ.arq_cms
                       AND C1.NU_REG     = C.NU_REG
                       AND C1.CD_MDL_CTD = 785
                       AND C2.cd_arq     = ARQ.arq_cms
                       AND C2.NU_REG     = C.NU_REG
                       AND C2.CD_MDL_CTD = 786
                       AND R.CD_ARQ     = ARQ.arq_cms
                       AND R.NU_REG     = C.NU_REG
                     ORDER BY NU_REG ) LOOP

          IF vHead = FALSE THEN   
             vAnalise:= vAnalise || chr(13)|| chr(13)|| '-- RESPOSTA -- '|| CHR(13)||
                                                       'NU_REG;'        || 
                                                       'No Ordem;'      ||
                                                       'No Cartao;'     ||
                                                       'No Pedido;'     ||
                                                       'Cod Bloqueio;'  ||
                                                       'Mensagem Erro'  ||
                                                       chr(13);
            vHead := TRUE;
          END IF;

          vLinha  := TO_CHAR(RSP.NU_REG)   || ';'||
                     DBMS_LOB.substr(RSP.VL_RPT,12,10) || ';' ||   -- Número del pedido.
             ''''||  DBMS_LOB.substr(RSP.VL_RPT,19,22) || ';' ||   -- Numero de la tarjeta
             ''''||  DBMS_LOB.substr(RSP.VL_RPT,12,41) || ';' ||   -- Numero do pedido gerado em WATTS
                     DBMS_LOB.substr(RSP.VL_RPT,2,53)  || ';' ||   -- Código del motivo bloqueo del emisor
                     DBMS_LOB.substr(RSP.VL_RPT,50,55);            -- Message error
                
          vAnalise:= vAnalise ||  chr(13)||vLinha;         
       END LOOP;
       --  1.1 fim
       --
      END IF;
      
      PANALISE:= vAnalise;
     
    END LOOP;
  END;

  PROCEDURE P_ANALISE(PCD_TST_SEQ IN OUT PTC_TST_CTR_INT_DET.CD_TST_SEQ%TYPE,
                      PCD_ARQ_TKT IN OUT TKT_ARQ.CD_ARQ%TYPE,
                      PDETALHES   IN BOOLEAN DEFAULT TRUE) IS 
    vANALISE CLOB;
  BEGIN
    --
    IF PCD_TST_SEQ IS NOT NULL THEN
      SELECT T.CD_ARQ_TKT
      INTO PCD_ARQ_TKT
      FROM PTC_TST_CTR_INT T
      WHERE T.CD_TST_SEQ = PCD_TST_SEQ;
    ELSE
      SELECT MAX(T.CD_TST_SEQ)
      INTO PCD_TST_SEQ
      FROM PTC_TST_CTR_INT T
      WHERE T.CD_ARQ_TKT = PCD_ARQ_TKT;      
    END IF;  
    
    DELETE PTC_TST_CTR_INT_ANA
    WHERE CD_TST_SEQ = PCD_TST_SEQ;
    
    P_ANALISE(PCD_ARQ_TKT => PCD_ARQ_TKT,
              PDETALHES   => PDETALHES,
              PANALISE    => vANALISE); 
    
    INSERT INTO PTC_TST_CTR_INT_ANA
    VALUES(PCD_TST_SEQ, vANALISE);

    COMMIT;
  END;       

PROCEDURE P_ANALISE_MSS(PCD_ARQ_TKT TKT_ARQ.CD_ARQ%TYPE,
                      PDETALHES   IN BOOLEAN,
                      PANALISE    OUT CLOB) IS
    vAnalise CLOB; 
    vLinha   CLOB; 
    vAux     VARCHAR2(500);  
    vVei     BOOLEAN; 
    vPed     NUMBER;
    vStsPed  NUMBER;  
    vCurOut               T_CURSOR;
    vCardOperationList    RCurCardOperationCardList;
    vCardFin NUMBER;
    vCartao  VARCHAR2(100);
    vHead    BOOLEAN;
  BEGIN
    --
    -- Arquivos Gerados
    FOR ARQ IN (
        SELECT T.CD_ARQ,
            A.CD_ARQ ARQ_CMS,
            A.CD_CSL,
            A.CD_GST,
            A.CD_BAS,
            A.CD_CLI,
            M.DS_MDL_ARQ,
            A.TP_PRC,
            A.TP_ACA,
            A.CD_STA_CMM,
            S.DC_STA_CMM,
            A.NM_ARQ,
            A.NU_TOT_LIN,
            A.DT_INI_PRC,
            A.DT_FIM_PRC,
            ROUND((A.DT_FIM_PRC - A.DT_INI_PRC) * 24 * 60, 2) QT_MIN_PRC,
            
            (SELECT COUNT(1)
                FROM PTC_MSS_MDL_REG MR 
                INNER JOIN PTC_MSS_REG RE ON RE.CD_MDL_REG = MR.CD_MDL_REG
                WHERE RE.CD_ARQ = A.CD_ARQ
                AND MR.CD_MDL_ARQ = A.CD_MDL_ARQ
                AND RE.IN_ERR_PRC IS NULL) QT_LIN_PRC,
                
            (SELECT COUNT(1)
                FROM PTC_MSS_MDL_REG MR
                INNER JOIN PTC_MSS_REG RE ON RE.CD_MDL_REG = MR.CD_MDL_REG
                WHERE MR.CD_MDL_ARQ = A.CD_MDL_ARQ
                AND RE.CD_ARQ = A.CD_ARQ
                AND RE.IN_ERR_PRC IS NOT NULL) QT_LIN_ERR,
                
            (SELECT COUNT(1)
                FROM MX_ADM.PTC_MSS_REG_RPT I
                WHERE I.CD_ARQ = A.CD_ARQ) QT_LIN_INT_PRC,
                
            (SELECT COUNT(1)
                FROM MX_ADM.PTC_MSS_REG_ERR I
                WHERE I.CD_ARQ = A.CD_ARQ) QT_LIN_INT_ERR
                    
        FROM MX_ADM.TKT_ARQ T
        INNER JOIN MX_ADM.PTC_MSS_ARQ A ON A.CD_ARQ = T.CD_CMS_ARQ
        INNER JOIN MX_ADM.PTC_MSS_MDL_ARQ M ON M.CD_MDL_ARQ = A.CD_MDL_ARQ
        INNER JOIN MX_ADM.PTC_STA_CMM S ON S.CD_STA_CMM = A.CD_STA_CMM
        WHERE T.CD_ARQ = PCD_ARQ_TKT
        ORDER BY 2 DESC
    ) LOOP

        vAnalise := '-- VISAO GERAL DO PROCESSAMENTO --' || CHR(13) ||
                  'Cod. Arquivo Tkt;' || ARQ.CD_ARQ || ';Cod. Arquivo Cms;' ||
                  ARQ.ARQ_CMS || chr(13) || 'Consolidador;' || ARQ.CD_CSL ||
                  ';Corporate Level;' || ARQ.CD_BAS || ';Gestor;' ||
                  ARQ.CD_GST || ';Cliente;' || ARQ.CD_CLI || chr(13) ||
                  'Tipo Processamento;' || ARQ.TP_PRC ||
                  ';Tipo Ação;' || ARQ.TP_ACA || chr(13) || 'Resultado;' ||
                  ARQ.CD_STA_CMM || ' - ' || ARQ.DC_STA_CMM || chr(13) ||
                 --ARQ.NM_ARQ, 
                  'Linhas do arquivo;' || ARQ.NU_TOT_LIN || chr(13) ||
                  'Inicio proc.;' ||
                  TO_CHAR(ARQ.DT_INI_PRC, 'DD/MM/YYYY HH24:MI:SS') ||
                  ';Fim proc.;' ||
                  TO_CHAR(ARQ.DT_FIM_PRC, 'DD/MM/YYYY HH24:MI:SS') ||
                  '; Minutos;' || ARQ.QT_MIN_PRC || chr(13) || chr(13) ||
                  '> Processamento Geral' || chr(13) ||
                  '  Linhas sem erro;' || ARQ.QT_LIN_PRC || chr(13) ||
                  '  Linhas com erro;' || ARQ.QT_LIN_ERR || chr(13) ||
                  chr(13) || '> Processamento Interface Sunnel' || chr(13) ||
                  '  Linhas processadas;' || ARQ.QT_LIN_INT_PRC || chr(13) ||
                  '  Linhas com erro;' || ARQ.QT_LIN_INT_ERR;
        --
        --
        vAnalise := vAnalise || chr(13);
        -- Ordem criada
        vAnalise := vAnalise || chr(13);
        vAnalise := vAnalise || 'DADOS DO PEDIDO' || chr(13);

        FOR ORD IN (
            SELECT P.*, S.DC_STA_PED_TKT, T.DC_TIP_PED
            FROM MX_ADM.PTC_MSS_ARQ_PED A 
            INNER JOIN PTC_PED P ON A.NU_PED = P.NU_PED
            INNER JOIN PTC_STA_PED S ON S.CD_STA_PED = P.CD_STA_PED
            INNER JOIN PTC_TIP_PED T ON T.CD_TIP_PED = P.CD_TIP_PED
            WHERE A.CD_ARQ = ARQ.arq_cms
        ) LOOP

            vPed:= Ord.Nu_Ped ;            
            vAnalise:= vAnalise || chr(13);                    
            vAnalise:= vAnalise || 'Pedido gerado: '|| Ord.Nu_Ped  ||' Data: '|| Ord.Dt_Ped|| chr(13);
            vAnalise:= vAnalise || Ord.Cd_Tip_Ped||' '|| Ord.Dc_Tip_Ped || chr(13);
            vAnalise:= vAnalise || 'Status: '|| Ord.Cd_Sta_Ped|| ' '||Ord.Dc_Sta_Ped_Tkt|| chr(13);
            vAnalise:= vAnalise || 'Obs.: '|| Ord.Dc_Obs || chr(13);

        END LOOP;

        vAnalise:= vAnalise || chr(13);

        IF PDETALHES THEN
            --                                     
            -----------------------------------------------------
            -----------------------------------------------------                               
            -- HEADER
            vAnalise:= vAnalise || chr(13)|| chr(13)|| '-- DETALHES -- '|| CHR(13)||
                     'EXEC;'         ||
                     'NU_REG;'       || 
                     'Cartao;'       ||
                     'Tag NFC Num;'  ||
                     'Tag NFC Id;'   ||
                     'Reg Erro;'     ||
                     'Reg. Mensagem;'||
                     'Interf. Valor;'    ||
                     'Interf. Oper;'    ||
                     'Interf. Tipo;'    ||
                     'Interf. Effect;'   || 
                     'Interf. Code;'     ||
                     'Interf. Message;'  || 
                     'Cartao Financ.;'||
                     'Portador;'||
                     'Tipo Tecn.;'||
                     'Status;'||
                     'Conta;'||                     
                     'Status;'||                     
                     'Dt.Status;'||                                                               
                    /* 'Cred/Deb;'||
                     'Data;'||
                     'Valor;'||
                     'Tipo;'||*/
                     'Pedido;'||
                     'Valor;'||
                     'Dt.Agend;'||
                     'Status;'||
                     'Mensagem;'||
                     'Data;'||
                     chr(13);
            --   
            -- Cartoes
            vVei:= FALSE;
            FOR CAR IN (
                SELECT C.NU_REG, C.VL_CTD CARTAO, C1.VL_CTD TAGNFCNUM, C2.VL_CTD TAGNFCID
                FROM MX_ADM.PTC_MSS_CTD C, MX_ADM.PTC_MSS_CTD C1, MX_ADM.PTC_MSS_CTD C2
                WHERE C.cd_arq = ARQ.arq_cms
                AND C.CD_MDL_CTD =
                    (select CD_MDL_CTD
                        from MX_ADM.PTC_MSS_MDL_CTD
                        where cd_mdl_reg in (select cd_mdl_reg
                                                from MX_ADM.PTC_MSS_MDL_REG
                                            where cd_mdl_arq = 803)
                        and ds_ctd = 'CARD_NUMBER')
                AND C1.cd_arq = ARQ.arq_cms
                AND C1.NU_REG = C.NU_REG
                AND C1.CD_MDL_CTD =
                    (select CD_MDL_CTD
                        from MX_ADM.PTC_MSS_MDL_CTD
                        where cd_mdl_reg in (select cd_mdl_reg
                                                from MX_ADM.PTC_MSS_MDL_REG
                                            where cd_mdl_arq = 803)
                        and ds_ctd = 'DISTRIBUTION_TYPE')
                AND C2.cd_arq = ARQ.arq_cms
                AND C2.NU_REG = C.NU_REG
                AND C2.CD_MDL_CTD =
                    (select CD_MDL_CTD
                        from MX_ADM.PTC_MSS_MDL_CTD
                        where cd_mdl_reg in (select cd_mdl_reg
                                                from MX_ADM.PTC_MSS_MDL_REG
                                            where cd_mdl_arq = 803)
                        and ds_ctd = 'TAG_HEXADECIMAL')
                ORDER BY NU_REG
            ) LOOP
                vLinha:= car.Nu_Reg          || ';' ||
                   ''''||car.cartao    || ';' ||
                   ''''||car.TAGNFCNUM || ';' ||
                   ''''||car.TAGNFCID  || ';' ;  
                vCartao:= car.cartao ;

                IF car.cartao IS NULL THEN
                    IF car.TAGNFCNUM IS NOT NULL THEN
                        SELECT MAX(CAT.NU_CAT)
                        INTO vCartao
                        FROM PTC_DAD_VEI_EQP DAD
                        INNER JOIN PTC_VEI_EQP VEI
                            ON VEI.CD_VEI_EQP = DAD.CD_VEI_EQP
                        INNER JOIN PTC_CAT CAT
                            ON CAT.CD_PTD = VEI.CD_PTD
                        AND CAT.CD_BAS = VEI.CD_BAS
                        WHERE DAD.NU_TAG_NFC = car.TAGNFCNUM;
                    END IF;
                    IF car.TAGNFCID IS NOT NULL THEN
                        SELECT MAX(CAT.NU_CAT)
                        INTO vCartao
                        FROM PTC_DAD_VEI_EQP DAD
                        INNER JOIN PTC_VEI_EQP VEI
                            ON VEI.CD_VEI_EQP = DAD.CD_VEI_EQP
                        INNER JOIN PTC_CAT CAT
                            ON CAT.CD_PTD = VEI.CD_PTD
                        AND CAT.CD_BAS = VEI.CD_BAS
                        WHERE DAD.ID_TAG_NFC = car.TAGNFCID;
                    END IF;
                END IF;

                -- Registro de Erros
                FOR Erro IN (
                    SELECT NU_REG, MR.CD_MDL_REG, IN_ERR_PRC
                    FROM MX_ADM.PTC_MSS_REG RE
                    INNER JOIN MX_ADM.PTC_MSS_MDL_REG MR
                        ON MR.CD_MDL_REG = RE.CD_MDL_REG
                    WHERE CD_ARQ = ARQ.arq_cms
                ) LOOP
                    vLinha:= vLinha||
                     SUBSTR(REPLACE(REPLACE(Erro.IN_ERR_PRC,     ';', ' '),CHR(10), ' '), 1, 100) || ';';
                END LOOP;

                --
                -- BD - Cartao e conta
                IF vCartao IS NULL THEN
                    vLinha:= vLinha  
                          || ';' 
                          || ';' 
                          || ';' 
                          || ';' 
                          || ';' ||
                          ';' ;
                ELSE
                    FOR REG IN (
                        SELECT CA.*, CC.ACCOUNTID, CO.STATUS, CO.STATUSDATE
                        FROM MX_ADM.PTC_CAT CA
                        INNER JOIN MX_ADM.T_GCARDACCOUNT CC
                            ON CC.CARDID = CA.NU_CAT
                        INNER JOIN MX_ADM.T_GACCOUNT CO
                            ON CO.ACCOUNTID = CC.ACCOUNTID
                        WHERE CA.NU_CAT = vCartao
                    ) LOOP
                        IF REG.CD_TIP_CAT = 4 THEN
                            MX_ADM.WTMX_CARD_PKG.CardGetOperationCardList(CARDLIST  => REG.NU_CAT,
                                                           STARTPAGE => NULL,
                                                           PAGEROWS  => NULL,
                                                           CUR_OUT   => vCurOut);
                            --
                            FETCH vCurOut INTO vCardOperationList;
                            --
                            vLinha:= vLinha || vCardOperationList.NU_CAT_OPE || ';' ;
                            IF vCardOperationList.NU_CAT_OPE IS NOT NULL THEN
                                vCardFin:= vCardOperationList.NU_CAT_OPE;
                            END IF; 
                        ELSE
                            vLinha:= vLinha || ';' ;
                            vCardFin:= REG.NU_CAT;
                        END IF;
                        --
                        vLinha:= vLinha ||  
                            Reg.Cd_Ptd         || ';' ||
                            Reg.Cd_Tip_Tcn_Cat || ';' ||
                            Reg.Cd_Sta_Cat     || ';' ||
                            Reg.Accountid      || ';' ||
                            Reg.Status         || ';' ||
                            TO_CHAR(Reg.Statusdate,'DD/MM/YYYY') || ';' ;
                        --  
                    END LOOP;
                END IF;

                -- PED FIN
                vStsPed:= NULL;

                FOR Ped IN (
                    SELECT NU_PED,
                        P.VL_PED_FIN_CAT,
                        P.DT_AGD,
                        P.CD_STA_ITE_PED_DET,
                        DS_MSG_PRC,
                        DT_EXE,
                        D.DS_STA_ITE_PED_DET
                    FROM MX_ADM.PTC_PED_FIN_CAT P
                    LEFT JOIN MX_ADM.PTC_STA_ITE_PED_DET D ON D.CD_STA_ITE_PED_DET = P.CD_STA_ITE_PED_DET
                    WHERE NU_PED = vPed
                    AND   NU_CAT = vCardFin
                ) LOOP

                vStsPed:= Ped.Cd_Sta_Ite_Ped_Det;          

                vLinha:= vLinha ||
                    Ped.NU_PED             ||';'||
                    Ped.Vl_Ped_Fin_Cat     ||';'||
                    TO_DATE(Ped.Dt_Agd, 'DD/MM/YYYY HH24:MI') ||';'||
                    Ped.Cd_Sta_Ite_Ped_Det||'-'||Ped.DS_STA_ITE_PED_DET ||';'||
                    Ped.Ds_Msg_Prc         ||';'||
                    Ped.Dt_Exe             ||';';
                END LOOP;

                IF vStsPed IS NULL THEN
                    vLinha:= 'NÃO GERADO;'||vLinha;
                ELSIF vStsPed = 2 THEN
                    vLinha:= 'OK  GERADO;'||vLinha;  
                ELSE  
                    vLinha:= 'NÃO GERADO;'||vLinha;
                END IF;  

                vLinha:= vLinha ||';';

                vAnalise:= vAnalise || chr(13)||vLinha;
            END LOOP;
            --
            -- 1.1 Inicio
            -- Resposta da Carga Massiva
            vHead := FALSE;
            
            FOR RSP IN (
                SELECT C.NU_REG, R.VL_RPT
                FROM MX_ADM.PTC_MSS_CTD C,
                    MX_ADM.PTC_MSS_CTD C1,
                    MX_ADM.PTC_MSS_CTD C2,
                    PTC_MSS_REG_RPT    R
                WHERE C.cd_arq = ARQ.arq_cms
                AND C.CD_MDL_CTD =
                    (select CD_MDL_CTD
                        from MX_ADM.PTC_MSS_MDL_CTD
                        where cd_mdl_reg in (select cd_mdl_reg
                                                from MX_ADM.PTC_MSS_MDL_REG
                                            where cd_mdl_arq = 803)
                        and ds_ctd = 'CARD_NUMBER')
                AND C1.cd_arq = ARQ.arq_cms
                AND C1.NU_REG = C.NU_REG
                AND C1.CD_MDL_CTD =
                    (select CD_MDL_CTD
                        from MX_ADM.PTC_MSS_MDL_CTD
                        where cd_mdl_reg in (select cd_mdl_reg
                                                from MX_ADM.PTC_MSS_MDL_REG
                                            where cd_mdl_arq = 803)
                        and ds_ctd = 'DISTRIBUTION_TYPE')
                AND C2.cd_arq = ARQ.arq_cms
                AND C2.NU_REG = C.NU_REG
                AND C2.CD_MDL_CTD =
                    (select CD_MDL_CTD
                        from MX_ADM.PTC_MSS_MDL_CTD
                        where cd_mdl_reg in (select cd_mdl_reg
                                                from MX_ADM.PTC_MSS_MDL_REG
                                            where cd_mdl_arq = 803)
                        and ds_ctd = 'TAG_HEXADECIMAL')
                AND R.CD_ARQ = ARQ.arq_cms
                AND R.NU_REG = C.NU_REG
                ORDER BY NU_REG
            ) LOOP

                IF vHead = FALSE THEN   
                    vAnalise:= vAnalise || chr(13)|| chr(13)|| '-- RESPOSTA -- '|| CHR(13)||
                                                            'NU_REG;'        || 
                                                            'No Ordem;'      ||
                                                            'No Cartao;'     ||
                                                            'No Pedido;'     ||
                                                            'Cod Bloqueio;'  ||
                                                            'Mensagem Erro'  ||
                                                            chr(13);
                    vHead := TRUE;
                END IF;

                vLinha  := TO_CHAR(RSP.NU_REG)   || ';'||
                            DBMS_LOB.substr(RSP.VL_RPT,12,10) || ';' ||   -- Número del pedido.
                    ''''||  DBMS_LOB.substr(RSP.VL_RPT,19,22) || ';' ||   -- Numero de la tarjeta
                    ''''||  DBMS_LOB.substr(RSP.VL_RPT,12,41) || ';' ||   -- Numero do pedido gerado em WATTS
                            DBMS_LOB.substr(RSP.VL_RPT,2,53)  || ';' ||   -- Código del motivo bloqueo del emisor
                            DBMS_LOB.substr(RSP.VL_RPT,50,55);            -- Message error
                
                vAnalise:= vAnalise ||  chr(13)||vLinha;
            END LOOP;
        END IF;
        
        PANALISE:= vAnalise;

    END LOOP;
  END;
  
END;
