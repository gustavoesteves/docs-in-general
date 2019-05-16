CREATE OR REPLACE PACKAGE MX_ADM.WT2MX_MSS_CREDIT_ORDER_PKG IS
  -- +====================================================================================================
  -- |        Copyright (c) 2018 Edenred
  -- +====================================================================================================
  -- |
  -- | CREATION BY
  -- |    Março/2019 - Gustavo Esteves - Stefanini
  -- |
  -- | Version   Date        Developer           Purpose
  -- | --------  ----------  -----------------   ---------------------------------------------------------
  -- | 1.00      06/03/2019  Gustavo - Stefanini   Versão inicial 
  -- +====================================================================================================
  --
  -- *****************
  -- * TIPOS GLOBAIS *
  -- *****************
  --
  TYPE T_CURSOR IS REF CURSOR;
  --
  --
  -- *********************
  -- * PUBLIC METHODS    *
  -- *********************
  --
  --
  ----------------------------------------------------------------------------------------
  -- Procedure processamento do header do arquivo
  ----------------------------------------------------------------------------------------
  PROCEDURE FileHeader;
  --
  ----------------------------------------------------------------------------------------
  -- Procedure processamento da linha de autenticação do arquivo
  ----------------------------------------------------------------------------------------
  PROCEDURE FileAuthentication;
  --
  --
  ----------------------------------------------------------------------------------------
  -- Procedure processamento do cabeçalho do pedido de distribuição
  ----------------------------------------------------------------------------------------
  PROCEDURE ProcessOrderDetailHeader;
  --
  --
  ----------------------------------------------------------------------------------------
  -- Procedure processamento da(s) linha(s) de detalhe do pedido de distribuição
  ----------------------------------------------------------------------------------------
  PROCEDURE ProcessOrderDistribution;
  --
  --
  ----------------------------------------------------------------------------------------
  -- Procedure Grava o NUM_PEDIDO para o arquivo de resposta
  ----------------------------------------------------------------------------------------
  PROCEDURE SetOrderNumber(
    PNREG       IN PTC_MSS_REG.NU_REG%TYPE, 
    PCD_MDL_REG IN PTC_MSS_MDL_REG.CD_MDL_REG%TYPE
  );
  --
  --
  END WT2MX_MSS_CREDIT_ORDER_PKG;