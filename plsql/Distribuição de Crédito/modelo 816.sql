-- Modelo carga
insert into ptc_mss_mdl_arq (CD_MDL_ARQ, DS_MDL_ARQ, CD_STA_CMM, IN_TIP_PRC, IN_TIP_ACA, MU_MAX_LIN, VL_PRI_EXE, NU_EXE_SIM, IN_PMI_AGD, IN_VLD_DUP, IN_PRC_INT, NM_PRC_FIN, NM_FRM_SNN, IN_PRC_OLTP)
values (816, 'Purchase Notification', 1, 'F', 'A', 0, 1, 8, 'F', 'F', 'F', null, null, 'T');

-- Modelo registros
insert into ptc_mss_mdl_reg (CD_MDL_REG, CD_MDL_ARQ, NU_TAM_MAX, NU_ORD_PRC, DS_MDL_REG, ID_CTD_REG, TP_MDL_REG, NM_PRC_REG, CD_STA_CMM, CD_MDL_REG_PAI)
values (1300, 816, 400, 1, 'Header', '00', 'H', 'WT2MX_CMS_PURCHASE_NOTIF_PKG.FileHeader', 1, null);

insert into ptc_mss_mdl_reg (CD_MDL_REG, CD_MDL_ARQ, NU_TAM_MAX, NU_ORD_PRC, DS_MDL_REG, ID_CTD_REG, TP_MDL_REG, NM_PRC_REG, CD_STA_CMM, CD_MDL_REG_PAI)
values (1301, 816, 400, 2, 'Autenticação', '01', 'A', 'WT2MX_CMS_PURCHASE_NOTIF_PKG.FileAutentication', 1, 1300);

insert into ptc_mss_mdl_reg (CD_MDL_REG, CD_MDL_ARQ, NU_TAM_MAX, NU_ORD_PRC, DS_MDL_REG, ID_CTD_REG, TP_MDL_REG, NM_PRC_REG, CD_STA_CMM, CD_MDL_REG_PAI)
values (1302, 816, 400, 3, 'Detalle - Notificacion de Compra', '02', 'D', 'WT2MX_CMS_PURCHASE_NOTIF_PKG.PurchaseDetail', 1, 1300);

insert into ptc_mss_mdl_reg (CD_MDL_REG, CD_MDL_ARQ, NU_TAM_MAX, NU_ORD_PRC, DS_MDL_REG, ID_CTD_REG, TP_MDL_REG, NM_PRC_REG, CD_STA_CMM, CD_MDL_REG_PAI)
values (1303, 816, 400, 4, 'Subdetalle – Conductor', '03', 'D', 'WT2MX_CMS_PURCHASE_NOTIF_PKG.PurchaseSubDetail', 1, 1302);

insert into ptc_mss_mdl_reg (CD_MDL_REG, CD_MDL_ARQ, NU_TAM_MAX, NU_ORD_PRC, DS_MDL_REG, ID_CTD_REG, TP_MDL_REG, NM_PRC_REG, CD_STA_CMM, CD_MDL_REG_PAI)
values (1304, 816, 400, 5, 'Trailer', '99', 'T', null, 1, null);

-- Modelo conteudo
insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11600, 1300, 1, 2, 'N', null, 2, 0, 'TYPE_REGISTER', 'TipoRegistro', 'T', null, null, 'REGISTER_TYPE');

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11601, 1300, 3, 9, 'N', null, 7, 0, 'LINE_SEQ_ID', 'NroLinha', 'T', null, null, 'LINE_NUMBER');

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11602, 1300, 10, 19, 'N', null, 10, 0, 'NR_REMESA', 'NroRemessa', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11603, 1300, 20, 33, 'D', 'DDMMYYYYHH24MISS', 14, 0, 'DT_REMESA', 'DataRemessa', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11604, 1300, 34, 83, 'A', null, 50, 0, 'DS_INTERFACE', 'NomeInterface', 'T', null, null, 'INTERFACE_NAME');

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11605, 1301, 1, 2, 'N', null, 2, 0, 'TYPE_REGISTER', 'TipoRegistro', 'T', null, null, 'REGISTER_TYPE');

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11606, 1301, 3, 9, 'N', null, 7, 0, 'LINE_SEQ_ID', 'NroLinha', 'T', null, null, 'LINE_NUMBER');

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11607, 1301, 10, 21, 'N', null, 12, 0, 'MANAGER_IDENTIFICATION', 'Manager', 'T', null, null, 'CD_GST');

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11608, 1301, 22, 33, 'N', null, 12, 0, 'CORPORATE_LEVEL_IDENTIF', 'Base', 'T', null, null, 'CD_BAS');

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11609, 1301, 34, 34, 'A', null, 1, 0, 'ACTION_TYPE', 'ActionType', 'T', null, null, 'ACTION_TYPE');

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11610, 1301, 35, 35, 'A', null, 1, 0, 'PROCESS_TYPE', 'ProcessType', 'T', null, null, 'PROCESS_TYPE');

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11611, 1302, 1, 2, 'N', null, 2, 0, 'TYPE REGISTER', 'TipoRegistro', 'T', null, null, 'REGISTER_TYPE');

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11612, 1302, 3, 9, 'N', null, 7, 0, 'LINE_SEQ_ID', 'NroLinha', 'T', null, null, 'LINE_NUMBER');

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11613, 1302, 10, 21, 'N', null, 12, 0, 'NSU', 'NSU', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11614, 1302, 22, 40, 'A', null, 19, 0, 'CARD_NUMBER', 'Cartao', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11615, 1302, 41, 59, 'A', null, 19, 0, 'STOCK_CARD_NUMBER', 'CartaoEstoque', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11616, 1302, 60, 75, 'N', null, 16, 2, 'AMOUNT', 'ValorCompra', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11617, 1302, 76, 87, 'N', null, 12, 0, 'PERSON_ID', 'Condutor', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11618, 1302, 88, 95, 'D', 'DDMMYYYY', 8, 0, 'PURCHASE_DATE', 'DataCompra', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11619, 1302, 96, 101, 'D', 'HH24MISS', 6, 0, 'PURCHASE_HOUR', 'HoraCompra', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11620, 1302, 102, 109, 'D', 'DDMMYYYY', 8, 0, 'TRANSMISSION_DATE', 'DataTransmissao', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11621, 1302, 110, 115, 'D', 'HH24MISS', 6, 0, 'TRANSMISSION_HOUR', 'HoraTransmissao', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11622, 1302, 116, 118, 'N', null, 3, 0, 'BY_PHONE_REASON_ID', 'PhoneReasonId', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11623, 1302, 119, 122, 'N', null, 4, 0, 'EXPIRATION_DATE', 'DataExpiracao', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11624, 1302, 123, 152, 'A', null, 30, 0, 'EMBOSSING_NAME', 'Embossing', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11625, 1302, 153, 164, 'N', null, 12, 0, 'MERCHANT CONTRACT ID', 'Contrato', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11626, 1302, 165, 184, 'A', null, 20, 0, 'ORDER_GUIDE_NUMBER', 'NroGuia', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11627, 1302, 185, 193, 'N', null, 9, 0, 'ODOMETER_HOURMETER_ VALUE', 'OdomHorim', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11628, 1302, 194, 205, 'N', null, 12, 0, 'POS_ID', 'POS', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11629, 1302, 206, 210, 'N', null, 5, 0, 'MERCHANDISE_CODE', 'Mercadoria', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11630, 1302, 211, 218, 'N', null, 8, 0, 'MERCHANDISE_QUANTITY', 'QtdMercadoria', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11631, 1302, 219, 219, 'N', null, 1, 0, 'DECIMALS_QUANTITY', 'DecimaisQtd', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11632, 1302, 220, 235, 'N', null, 16, 0, 'MERCHANDISE_UNIT_VALUE', 'ValorMercadoria', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11633, 1302, 236, 236, 'N', null, 1, 0, 'DECIMALS_UNIT_VALUE', 'DecimaisVlrUnit', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11634, 1302, 237, 252, 'N', null, 16, 0, 'PURCHASE_TOTAL_VALUE', 'ValorTotal', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11635, 1302, 253, 268, 'N', null, 16, 0, 'PURCHASE_FINAL_VALUE', 'ValorFinal', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11636, 1302, 269, 284, 'N', null, 16, 2, 'PURCHASE_DESCOUNT', 'Desconto', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11637, 1302, 285, 285, 'N', null, 1, 0, 'PURCHASE_DESC_TYPE', 'TipoDesconto', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11638, 1302, 286, 288, 'N', null, 3, 0, 'DATA1_ID', 'Dado1', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11639, 1302, 289, 290, 'N', null, 2, 0, 'DATA1_SIZE', 'TamanhoDado1', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11640, 1302, 291, 306, 'A', null, 16, 0, 'DATA1_INFORMATION', 'Informacao1', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11641, 1302, 307, 309, 'N', null, 3, 0, 'DATA2_ID', 'Dado2', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11642, 1302, 310, 311, 'N', null, 2, 0, 'DATA2_SIZE', 'TamanhoDado2', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11643, 1302, 312, 327, 'A', null, 16, 0, 'DATA2_INFORMATION', 'Informacao2', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11644, 1302, 328, 330, 'N', null, 3, 0, 'DATA3_ID', 'Dado3', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11645, 1302, 331, 332, 'N', null, 2, 0, 'DATA3_SIZE', 'TamanhoDado3', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11646, 1302, 333, 348, 'A', null, 16, 0, 'DATA3_INFORMATION', 'Informacao3', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11647, 1302, 349, 351, 'N', null, 3, 0, 'DATA4_ID', 'Dado4', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11648, 1302, 352, 353, 'N', null, 2, 0, 'DATA4_SIZE', 'TamanhoDado4', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11649, 1302, 354, 369, 'A', null, 16, 0, 'DATA4_INFORMATION', 'Informacao4', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11650, 1302, 370, 372, 'N', null, 3, 0, 'DATA5_ID', 'Dado5', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11651, 1302, 373, 374, 'N', null, 2, 0, 'DATA5_SIZE', 'TamanhoDado5', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11652, 1302, 375, 390, 'A', null, 16, 0, 'DATA5_INFORMATION', 'Informacao5', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11653, 1303, 1, 2, 'N', null, 2, 0, 'TYPE REGISTER', 'TipoRegistro', 'T', null, null, 'REGISTER_TYPE');

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11654, 1303, 3, 9, 'N', null, 7, 0, 'LINE_SEQ_ID', 'NroLinha', 'T', null, null, 'LINE_NUMBER');

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11655, 1303, 10, 28, 'A', null, 19, 0, 'CIU', 'Ciu', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11656, 1303, 29, 40, 'N', null, 12, 0, 'PERSON_ID', 'Person', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11657, 1303, 41, 44, 'N', null, 4, 0, 'CIU_EXPIRATION_DATE', 'DataExpCiu', 'F', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11658, 1304, 1, 2, 'N', null, 2, 0, 'TYPE REGISTER', 'TipoRegistro', 'T', null, null, 'REGISTER_TYPE');

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11659, 1304, 3, 9, 'N', null, 7, 0, 'LINE_SEQ_ID', 'NroLinha', 'T', null, null, 'LINE_NUMBER');

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11660, 1304, 10, 19, 'N', null, 10, 0, 'NR_REMESA', 'NroRemessa', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11661, 1304, 20, 33, 'D', 'DDMMYYYYHH24MISS', 14, 0, 'DT_REMESA', 'DataRemessa', 'T', null, null, null);

insert into ptc_mss_mdl_ctd (CD_MDL_CTD, CD_MDL_REG, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, CD_LST_VLR, IN_KEY_VLR)
values (11662, 1304, 34, 48, 'N', null, 15, 0, 'CT_REGISTROS', 'QtdeRegistros', 'T', null, null, null);

-- Modelo Arquivo Resposta
insert into Ptc_Mss_Mdl_arq_Rpt (CD_MDL_ARQ_RPT, DS_MDL_ARQ_RPT, CD_MDL_ARQ, CD_STA_CMM, NM_PRC_RPT)
values (816, 'Purchase Notification', 816, 1, null);

-- Modelo Registro Resposta
insert into Ptc_Mss_Mdl_reg_Rpt (CD_MDL_REG_RPT, CD_MDL_ARQ_RPT, DS_MDL_REG_RPT, NU_ORD_REG, TP_MDL_REG, CD_STA_CMM, CD_MDL_REG, NM_PRC_REG)
values (1300, 816, 'Header', 1, 'H', 1, 1300, null);

insert into Ptc_Mss_Mdl_reg_Rpt (CD_MDL_REG_RPT, CD_MDL_ARQ_RPT, DS_MDL_REG_RPT, NU_ORD_REG, TP_MDL_REG, CD_STA_CMM, CD_MDL_REG, NM_PRC_REG)
values (1301, 816, 'Autenticação', 2, 'A', 1, 1301, null);

insert into Ptc_Mss_Mdl_reg_Rpt (CD_MDL_REG_RPT, CD_MDL_ARQ_RPT, DS_MDL_REG_RPT, NU_ORD_REG, TP_MDL_REG, CD_STA_CMM, CD_MDL_REG, NM_PRC_REG)
values (1302, 816, 'Detalle - Notificacion de Compra', 3, 'D', 1, 1302, null);

insert into Ptc_Mss_Mdl_reg_Rpt (CD_MDL_REG_RPT, CD_MDL_ARQ_RPT, DS_MDL_REG_RPT, NU_ORD_REG, TP_MDL_REG, CD_STA_CMM, CD_MDL_REG, NM_PRC_REG)
values (1303, 816, 'Trailer', 5, 'T', 1, 1303, null);

-- Modelo Conteudo Resposta
insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11600, 1300, 1, 2, 'N', null, 2, 0, 'TYPE_REGISTER', 'TipoRegistro', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11601, 1300, 3, 9, 'N', null, 7, 0, 'LINE_SEQ_ID', 'NroLinha', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11602, 1300, 10, 19, 'N', null, 10, 0, 'NR_REMESA', 'NroRemessa', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11603, 1300, 20, 33, 'D', 'DDMMYYYYHH24MISS', 14, 0, 'DT_REMESA', 'DataRemessa', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11604, 1300, 34, 83, 'A', null, 50, 0, 'DS_INTERFACE', 'NomeInterface', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11605, 1300, 84, 133, 'A', null, 50, 0, 'MSG_ERROS', 'Erros', 'T', null, 'T');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11606, 1301, 1, 2, 'N', null, 2, 0, 'TYPE_REGISTER', 'TipoRegistro', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11607, 1301, 3, 9, 'N', null, 7, 0, 'LINE_SEQ_ID', 'NroLinha', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11608, 1301, 10, 21, 'N', null, 12, 0, 'MANAGER_IDENTIFICATION', 'Manager', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11609, 1301, 22, 33, 'N', null, 12, 0, 'CORPORATE_LEVEL_IDENTIF', 'Base', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11610, 1301, 34, 34, 'A', null, 1, 0, 'ACTION_TYPE', 'ActionType', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11611, 1301, 35, 35, 'A', null, 1, 0, 'PROCESS_TYPE', 'ProcessType', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11612, 1301, 36, 85, 'A', null, 50, 0, 'MSG_ERROS', 'Erros', 'T', null, 'T');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11613, 1302, 1, 2, 'N', null, 2, 0, 'TYPE_REGISTER', 'TipoRegistro', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11614, 1302, 3, 9, 'N', null, 7, 0, 'LINE_SEQ_ID', 'NroLinha', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11615, 1302, 10, 21, 'N', null, 12, 0, 'NSU', 'NSU', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11616, 1302, 22, 40, 'A', null, 19, 0, 'CARD_NUMBER', 'Cartao', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11617, 1302, 41, 59, 'A', null, 19, 0, 'STOCK_CARD_NUMBER', 'CartaoEstoque', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11618, 1302, 60, 71, 'N', null, 12, 0, 'RESPONSE_NSU', 'NSUResposta', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11619, 1302, 72, 75, 'N', null, 4, 0, 'RESPONSE_CODE', 'CodigoResposta', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11620, 1302, 76, 275, 'A', null, 200, 0, 'RESPONSE_DESCRIPTION', 'DescResposta', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11621, 1302, 276, 325, 'A', null, 50, 0, 'MSG_ERROS', 'Erros', 'T', null, 'T');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11622, 1303, 1, 2, 'N', null, 2, 0, 'TYPE_REGISTER', 'TipoRegistro', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11623, 1303, 3, 9, 'N', null, 7, 0, 'LINE_SEQ_ID', 'NroLinha', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11624, 1303, 10, 19, 'N', null, 10, 0, 'NR_REMESA', 'NroRemessa', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11625, 1303, 20, 33, 'D', 'DDMMYYYYHH24MISS', 14, 0, 'DT_REMESA', 'DataRemessa', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11626, 1303, 34, 48, 'N', null, 15, 0, 'CT_REGISTROS', 'QtdeRegistros', 'T', null, 'F');

insert into ptc_mss_mdl_ctd_rpt (CD_MDL_CTD_RPT, CD_MDL_REG_RPT, NU_POS_INI, NU_POS_FIM, TP_DAD, DS_FMT_DAD, NU_TAM_MAX, NU_PCS, DS_CTD, DS_RTL_CTD, IN_OBR, VL_PDR, IN_ERR)
values (11627, 1303, 49, 98, 'A', null, 50, 0, 'MSG_ERROS', 'Erros', 'T', null, 'T');