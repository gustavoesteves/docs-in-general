select 
    CD_MDL_ARQ,
    DS_MDL_ARQ,
    CD_TIP_RPT,
    MU_MAX_LIN,
    DS_CAM_UPL,
    DS_CAM_DNL,
    VL_LIN_INI,
    CD_TIP_ARQ,
    VL_PRI_EXE,
    NU_EXE_SIM,
    IN_PMI_AGD,
    TP_PRC_PDR,
    IN_AUT_REQ
from PTC_CMS_MDL_ARQ

select 
    IN_TOT_REG,
    CD_MDL_REG,
    CD_MDL_ARQ,
    NU_TAM_MAX,
    NU_ORD_PRC,
    DS_MDL_REG,
    VL_LIN_INI,
    DS_RTL_MDL_REG
from PTC_CMS_MDL_REG

select
    CD_MDL_CTD,
    CD_MDL_REG,
    NU_COL_PLN,
    NU_POS_INI,
    NU_POS_FIM,
    TP_DAD,
    DS_FMT_DAD,
    NU_TAM_MAX,
    NU_PCS,
    DS_CTD,
    DS_RTL_CTD,
    NM_FUN_CTD,
    IN_OBR,
    VL_PDR,
    IN_EXB,
    NM_FUN_VLD,
    IN_KEY,
    DS_RTL_CTD_ORG,
    VL_SEQ_MDL_CTD,
    IN_CTD_RSP,
    CD_LST_VLR
from PTC_CMS_MDL_CTD

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

-- New Carga Massiva update
update TKT_MDL_ARQ_PRC
set IN_DST_PRC = 'MSS'
where CD_MDL_ARQ_PRC = 803 

-- Arquivos de resposta
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
where CD_MDL_ARQ = 803

insert into PTC_MSS_MDL_REG_RPT(
  CD_MDL_REG_RPT
  CD_MDL_ARQ_RPT 
  DS_MDL_REG_RPT
  NU_ORD_REG     
  TP_MDL_REG
  CD_STA_CMM     
  CD_MDL_REG 
)
select 
  CD_MDL_REG,
  CD_MDL_ARQ,
  DS_MDL_REG,
  NU_ORD_PRC,
  TP_MDL_REG,
  CD_STA_CMM,
  CD_MDL_REG
from PTC_MSS_MDL_REG
where CD_MDL_ARQ = 803;

insert into PTC_MSS_MDL_CTD_RPT(
  CD_MDL_CTD_RPT,
  CD_MDL_REG_RPT,
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
  IN_ERR
)
values
(select 
  CD_MDL_CTD_RPT,
  CD_MDL_REG_RPT,
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
  IN_ERR)