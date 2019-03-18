-- New Carga Massiva update
update TKT_MDL_ARQ_PRC
set IN_DST_PRC = 'MSS'
where CD_MDL_ARQ_PRC = 803;

-- Modelo do Arquivo de Distribuição de Crédito
insert into PTC_MSS_MDL_ARQ (
    CD_MDL_ARQ,
    DS_MDL_ARQ,
    CD_STA_CMM,
    IN_TIP_PRC,
    IN_TIP_ACA,
    MU_MAX_LIN,
    VL_PRI_EXE,
    NU_EXE_SIM,
    IN_PMI_AGD,
    IN_VLD_DUP,
    IN_PRC_INT,
    NM_PRC_FIN,
    NM_FRM_SNN,
    IN_PRC_OLTP
)
select 
    CD_MDL_ARQ,
    DS_MDL_ARQ,
    1,
    'M',
    'M',
    MU_MAX_LIN,
    VL_PRI_EXE,
    NU_EXE_SIM,
    IN_PMI_AGD,
    'T',
    'F',
    null,
    null,
    'F'
from PTC_CMS_MDL_ARQ
where CD_MDL_ARQ = 803;

-- Modelo dos Registros de Distribuição de Crédito
insert into PTC_MSS_MDL_REG (
    CD_MDL_REG,
    CD_MDL_ARQ,
    NU_TAM_MAX,
    NU_ORD_PRC,
    DS_MDL_REG
    )
select 
    CD_MDL_REG,
    CD_MDL_ARQ,
    NU_TAM_MAX,
    NU_ORD_PRC,
    DS_MDL_REG
from PTC_CMS_MDL_REG
where CD_MDL_ARQ = 803;

-- Updates para Registros de Distribuição de Crédito
-- Header
update PTC_MSS_MDL_REG
set ID_CTD_REG = '00', TP_MDL_REG = 'H', 
  NM_PRC_REG = 'WT2MX_MSS_CREDIT_ORDER_PKG.FileHeader'
where CD_MDL_REG = 29;

-- Authentication
update PTC_MSS_MDL_REG
set ID_CTD_REG = '01', TP_MDL_REG = 'A', 
  NM_PRC_REG = 'WT2MX_MSS_CREDIT_ORDER_PKG.FileAutentication', CD_MDL_REG_PAI = 29
where CD_MDL_REG = 30;

-- Cabeçalho Pedido
update PTC_MSS_MDL_REG
set ID_CTD_REG = '02', TP_MDL_REG = 'D', 
  NM_PRC_REG = 'WT2MX_MSS_CREDIT_ORDER_PKG.ProcessarCabecalhoPedidoDist', CD_MDL_REG_PAI = 29
where CD_MDL_REG = 31;

-- Detalhe Pedido
update PTC_MSS_MDL_REG
set ID_CTD_REG = '03', TP_MDL_REG = 'D', 
  NM_PRC_REG = 'WT2MX_MSS_CREDIT_ORDER_PKG.ProcessarDetalheDistribuicao', CD_MDL_REG_PAI = 29
where CD_MDL_REG = 32;

-- Trailer
update PTC_MSS_MDL_REG
set ID_CTD_REG = '04', TP_MDL_REG = 'T'
where CD_MDL_REG = 32;

-- Modelo do Conteudo de Distribuição de Crédito 
insert into PTC_MSS_MDL_CTD (
    CD_MDL_CTD,
    CD_MDL_REG,   
    NU_POS_INI,   
    NU_POS_FIM,   
    TP_DAD,       
    DS_FMT_DAD,   
    NU_TAM_MAX,   
    NU_PCS,       
    DS_CTD,       
    DS_RTL_CTD,   
    IN_OBR,       
    VL_PDR,       
    CD_LST_VLR
    -- IN_KEY_VLR (não sei de onde vem esse campo)
)
select 
    CD_MDL_CTD,
    CD_MDL_REG,
    NU_POS_INI,
    NU_POS_FIM,
    TP_DAD,
    DS_FMT_DAD,
    NU_TAM_MAX,
    NU_PCS,
    DS_CTD,
    DS_RTL_CTD,
    IN_OBR,
    VL_PDR,
    CD_LST_VLR
    -- IN_KEY
from PTC_CMS_MDL_CTD
where cd_mdl_reg in (29, 30, 31, 32, 33);

-- update IN_KEY_VLR
-- if DS_RTL_CTD then IN_KEY_VLR
    -- TipoRegistro = REGISTER_TYPE
    -- NroLinha = LINE_NUMBER
    -- NomeInterface = INTERFACE_NAME
    -- Manager = CD_GST
    -- Base = CD_BAS
    -- ActionType = ACTION_TYPE
    -- ProcessType = PROCESS_TYPE

update PTC_MSS_MDL_CTD
set IN_KEY_VLR = 'REGISTER_TYPE'
where cd_mdl_reg in (29, 30, 31, 32, 33)
  and DS_RTL_CTD = 'TipoRegistro';

update PTC_MSS_MDL_CTD
set IN_KEY_VLR = 'LINE_NUMBER'
where cd_mdl_reg in (29, 30, 31, 32, 33)
  and DS_RTL_CTD = 'NroLinha';

update PTC_MSS_MDL_CTD
set IN_KEY_VLR = 'INTERFACE_NAME'
where cd_mdl_reg in (29, 30, 31, 32, 33)
  and DS_RTL_CTD = 'NomeInterface';

update PTC_MSS_MDL_CTD
set IN_KEY_VLR = 'CD_GST'
where cd_mdl_reg in (29, 30, 31, 32, 33)
  and DS_RTL_CTD = 'Manager';

update PTC_MSS_MDL_CTD
set IN_KEY_VLR = 'CD_BAS'
where cd_mdl_reg in (29, 30, 31, 32, 33)
  and DS_RTL_CTD = 'Base';

update PTC_MSS_MDL_CTD
set IN_KEY_VLR = 'ACTION_TYPE'
where cd_mdl_reg in (29, 30, 31, 32, 33)
  and DS_RTL_CTD = 'ActionType';

update PTC_MSS_MDL_CTD
set IN_KEY_VLR = 'PROCESS_TYPE'
where cd_mdl_reg in (29, 30, 31, 32, 33)
  and DS_RTL_CTD = 'ProcessType';

-- *************************************************
-- * Configuração das tabelas de Modelo de Restposta 
-- * para Distribuição de Crédito: 803
-- *************************************************

-- Modelo do Arquivo de Resposta de Distribuição de Crédito
insert into PTC_MSS_MDL_ARQ_RPT(
  CD_MDL_ARQ_RPT,
  DS_MDL_ARQ_RPT,
  CD_MDL_ARQ,
  CD_STA_CMM,
  NM_PRC_RPT
)
select 
  CD_MDL_ARQ,
  DS_MDL_ARQ,
  CD_MDL_ARQ,
  CD_STA_CMM,
  null
from PTC_MSS_MDL_ARQ
where CD_MDL_ARQ = 803;

-- Modelo dos Registros de Resposta de Distribuição de Crédito
insert into PTC_MSS_MDL_REG_RPT(
  CD_MDL_REG_RPT,
  CD_MDL_ARQ_RPT,
  DS_MDL_REG_RPT,
  NU_ORD_REG,
  TP_MDL_REG,
  CD_STA_CMM,
  CD_MDL_REG,
  NM_PRC_REG
)
select 
  CD_MDL_REG,
  CD_MDL_ARQ,
  DS_MDL_REG,
  NU_ORD_PRC,
  TP_MDL_REG,
  CD_STA_CMM,
  CD_MDL_REG,
  null
from PTC_MSS_MDL_REG
where CD_MDL_ARQ = 803;

-- Modelo dos Registros de Resposta do Conteudo de Distribuição de Crédito

-- Header
insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
)
select
  CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, null,
  'F'
from PTC_MSS_MDL_CTD
where CD_MDL_CTD in (333, 334, 335, 336, 337);

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
) values (
  338, 29, 84, 93,
  'A', null, 10, 0,
  'DS_ACTION_TYPE', 'ActionType', 'T', null,
  'F'
);

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
) values (
  339, 29, 94, 110,
  'A', null, 17, 0,
  'FILLER', 'Filler', 'F', null,
  'F'
);

--Authentication
insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
)
select
  340, CD_MDL_REG, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, null,
  'F'
from PTC_MSS_MDL_CTD
where CD_MDL_CTD = 339;

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
)
select
  341, CD_MDL_REG, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, null,
  'F'
from PTC_MSS_MDL_CTD
where CD_MDL_CTD = 340;


insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
)
select
  342, CD_MDL_REG, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, null,
  'F'
from PTC_MSS_MDL_CTD
where CD_MDL_CTD = 341;

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
)
select
  343, CD_MDL_REG, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, null,
  'F'
from PTC_MSS_MDL_CTD
where CD_MDL_CTD = 342;

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
) values (
  344, 30, 34, 83,
  'A', null, 50, 0,
  'MSG_ERROS', 'Erros', 'T', null,
  'T'
);

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
) values (
  345, 30, 84, 110,
  'A', null, 27, 0,
  'FILLER', 'Filler', 'F', null,
  'F'
);

-- Cabecalho do Pedido
insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
)
select
  346, CD_MDL_REG, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, null,
  'F'
from PTC_MSS_MDL_CTD
where CD_MDL_CTD = 344;

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
)
select
  347, CD_MDL_REG, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, null,
  'F'
from PTC_MSS_MDL_CTD
where CD_MDL_CTD = 345;

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
)
select
  348, CD_MDL_REG, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, null,
  'F'
from PTC_MSS_MDL_CTD
where CD_MDL_CTD = 346;

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
) values (
  349, 31, 22, 33,
  'N', null, 12, 0,
  'NUM_PEDIDO', 'NumPedido', 'F', null,
  'F'
);

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
) values (
  350, 31, 34, 83,
  'A', null, 50, 0,
  'MSG_ERROS', 'Erros', 'T', null,
  'T'
);

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
) values (
  351, 31, 84, 110,
  'A', null, 27, 0,
  'FILLER', 'Filler', 'F', null,
  'F'
);

-- Detalhe do Pedido
insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
)
select
  352, CD_MDL_REG, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, null,
  'F'
from PTC_MSS_MDL_CTD
where CD_MDL_CTD = 353;

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
)
select
  353, CD_MDL_REG, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, null,
  'F'
from PTC_MSS_MDL_CTD
where CD_MDL_CTD = 354;

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
)
select
  354, CD_MDL_REG, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, null,
  'F'
from PTC_MSS_MDL_CTD
where CD_MDL_CTD = 355;

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
)
select
  355, CD_MDL_REG, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, null,
  'F'
from PTC_MSS_MDL_CTD
where CD_MDL_CTD = 356;

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
) values (
  356, 32, 41, 52,
  'N', null, 12, 0,
  'NUM_PEDIDO', 'NumPedido', 'F', null,
  'F'
);

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
) values (
  357, 32, 53, 54,
  'N', null, 2, 0,
  'RISK_CONDITION_REASON', 'RiskCondReason', 'F', null,
  'F'
);

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
) values (
  358, 32, 55, 104,
  'A', null, 50, 0,
  'MSG_ERROS', 'Erros', 'T', null,
  'T'
);

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
) values (
  359, 32, 105, 110,
  'A', null, 6, 0,
  'FILLER', 'Filler', 'F', null,
  'F'
);

-- Trailer
insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
)
select
  360, CD_MDL_REG, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, null,
  'F'
from PTC_MSS_MDL_CTD
where CD_MDL_CTD = 368;

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
)
select
  361, CD_MDL_REG, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, null,
  'F'
from PTC_MSS_MDL_CTD
where CD_MDL_CTD = 369;

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
)
select
  362, CD_MDL_REG, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, null,
  'F'
from PTC_MSS_MDL_CTD
where CD_MDL_CTD = 370;

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
)
select
  363, CD_MDL_REG, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, null,
  'F'
from PTC_MSS_MDL_CTD
where CD_MDL_CTD = 371;

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
)
select
  364, CD_MDL_REG, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, null,
  'F'
from PTC_MSS_MDL_CTD
where CD_MDL_CTD = 372;

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM,
  TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS,
  DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR,
  IN_ERR
) values (
  365, 33, 49, 110,
  'A', null, 62, 0,
  'FILLER', 'Filler', 'F', null,
  'F'
);