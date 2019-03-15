CREATE OR REPLACE PACKAGE WT2MX_MSS_CREDIT_ORDER_PKG IS
  -- +=====================================================================================================
  -- |        Copyright (c) 2018 Edenred
  -- +=====================================================================================================
  -- |
  -- | CREATION BY
  -- |    Março/2019 - Gustavo - Stefanini
  -- |
  -- | Version   Date        Developer           Purpose
  -- | --------  ----------  -----------------   ----------------------------------------------------------
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
  ----------------------------------------------------
  -- Procedure processamento do header do arquivo
  ----------------------------------------------------
  PROCEDURE FileHeader;
  --
  --
  ----------------------------------------------------
  -- Procedure processamento da linha de autenticação do arquivo
  ----------------------------------------------------
  PROCEDURE FileAutentication;
  --
  --
  ----------------------------------------------------
  -- Procedure processamento da(s) linha(s) de detalhe do pedido de distribuição
  ----------------------------------------------------
  PROCEDURE ProcessarDetalheDistribuicao;
  --
  --
  END WT2MX_MSS_CREDIT_ORDER_PKG;