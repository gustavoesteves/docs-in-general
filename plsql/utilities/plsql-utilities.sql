-- list columns name from a table
select column_name from all_tab_columns where owner = '<table owner>' and table_name = '<table name>';
desc <table name>

-- 
select
    PARENT.TABLE_NAME,
    PARENT.CONSTRAINT_NAME,
    CHILD.TABLE_NAME,
    CHILD.COLUMN_NAME,
    CHILD.CONSTRAINT_NAME
from 
    ALL_CONS_COLUMNS CHILD,
    ALL_CONSTRAINTS CT,
    ALL_CONSTRAINTS PARENT
where CHILD.OWNER = CT.OWNER
and CT.CONSTRAINT_TYPE = 'R'
and CHILD.CONSTRAINT_NAME = CT.CONSTRAINT_NAME 
and CT.R_OWNER = PARENT.OWNER
and CT.R_CONSTRAINT_NAME = PARENT.CONSTRAINT_NAME 
and CHILD.TABLE_NAME = 'PTC_MSS_ARQ'
and CT.OWNER  = 'MX_ADM';

-- Tabelas e consultas relativas a Package de Distribuição de Crédito
select * from PTC_CMS_MDL_REG;

where CD_MDL_ARQ = 803;

select * from PTC_MSS_MDL_CTD;

SELECT * FROM PTC_MSS_MDL_ARQ;

SELECT * FROM PTC_MSS_MDL_REG
WHERE CD_MDL_ARQ = 803;

SELECT * FROM PTC_CMS_MDL_REG
WHERE CD_MDL_ARQ = 803;

select * from PTC_MSS_MDL_CTD;

SELECT * FROM PTC_CMS_MDL_CTD
where cd_mdl_reg in (29, 30, 31, 32, 33);

SELECT C.DS_RTL_CTD
FROM PTC_MSS_MDL_CTD C
WHERE C.IN_KEY_VLR = 'INTERFACE_NAME'
AND C.CD_MDL_REG IN (SELECT R.CD_MDL_REG FROM PTC_MSS_MDL_REG R);

SELECT A.CD_ARQ,
    A.CD_MDL_ARQ,
    A.TP_PRC,
    A.TP_ACA,
    M.IN_PRC_INT,
    M.IN_VLD_DUP,
    M.NM_PRC_FIN
FROM ptc_mss_ARQ A, PTC_mss_MDL_ARQ M
WHERE M.CD_MDL_ARQ = A.CD_MDL_ARQ;

select * from ptc_mss_arq;

select * from ptc_mss_mdl_arq;

select * from ptc_cms_arq cms
 inner join tkt_arq tkt on cms.cd_arq = tkt.cd_cms_arq
where cms.cd_mdl_arq = 803
order by cms.cd_arq desc;

select * from ptc_cms_reg
where cd_arq = 83740;

SELECT * FROM PTC_MSS_MDL_ARQ;

SELECT * FROM MX_ADM.TKT_MDL_ARQ_PRC;

select * from ptc_sta_cmm;

select arq.*
FROM TKT_ARQ ARQ,
     TKT_MDL_ARQ_PRC PRC -- 1.9
WHERE PRC.CD_MDL_ARQ = ARQ.CD_MDL_ARQ
  AND PRC.CD_MDL_ARQ_PRC = 803
  -- AND ARQ.cd_cms_arq = 36777
order by dt_rec_arq desc;
--
--
-- pesquisando em todos os lugares do banco por uma ocorrência
SELECT * FROM ALL_SOURCE S WHERE UPPER(S.TEXT) LIKE '%PTC_MSS_MDL_ARQ%';

SELECT * FROM ALL_SOURCE S WHERE UPPER(S.TEXT) LIKE UPPER('%NewFileReceivedLoader%');
--
-- voltar o status cd_sta_prc_arq para 1 e processar o arquivo novamente
update TKT_ARQ set cd_sta_prc_arq = 1
where cd_cms_arq = @Variavel