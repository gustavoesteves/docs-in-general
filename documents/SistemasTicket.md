# Sistemas Ticket

## Produtos e modelo do negócio

### Produtos Tikect Brasil

- TAE: Alimentação
- TRE: Restaurante
- TKE: Cultura
- TPA: Parceiro

### Produtos gestão de frotas

- TC: Car (Argentina e Mexico)

### Produtos Chile

- J: Restaurante Junaeb
- A: Alimentação
- R: Restaurante

### O modelo de negócio

- Cliente - Estabelecimento - Ticket - Rede de captura
- Cliente contrata a Ticket para prover crédito para seus portadores
- Estabelecimento se filia a Ticket para aceitar transações
- Conta: Associação do cartão/portador que possui informação de saldo e atividades
- Rede de captura: Quem recebe a transação através do POS's e envia para Ticket, Redecard, etc...
- Filiação: Rede de captura gera "numero logico" para estabelecimento esse "numero" é cadastrado e validado pela Ticket
- Processadora: Mantem informações das partes envolvidas na transação e faz autorização

## WATTS (Worldwide Authorization Ticket Transaction System)

- Contempla: Transações, pedidos de crédito, gestão de contas de portadores, produção de cartões
- Mantem cadastros geridos por outros sistemas: Contratos, clientes, filiações, portadores, etc...
- Alimenta outros sistemas: Geração de reembolso, geração de dados de entrega de cartão, retorno de pedidos para emissão de NF

## GRCT (Gestão de Rede Credenciadas Ticket)

- Criação de cadastro de filiação dos estabelecimentos

### Estrutura dos sistemas - Brasil

WATTS (Autorizador, Sunnel (Glassfish), Web-TC)

- ERP (Cadastro de faturamento)
- GRCT
- Redes de captura

### Estrutura dos sistemas - Mexico

WATTS (Autorizador, Sunnel, Web-TC)

- SPIRIT (ERP)
- ATPV (GRCT)
- Redes de captura

### Estrutura dos sistemas - Argentina/Chile

WATTS (Autorizador, Sunnel, Web-TC)

- Sistema próprio (ERP)
- ATPV
- Redes de captura

## Web Services

Utilizados na integração de sistemas e na comunicação entre aplicações diferentes. Dados são enviados em formato XML

Os protocolos que definem o XML são chamados Endpoint

## Metodos e Serviços WATTS

### Serviços

- Authorization: Transações
- CorporateLevelAdministration: Cria base (nivel intermediario)
- CorporateLevelManagement: Cria veículos, cria grupo de cartões, emissão de cartão, reemissão de cartão
- CustomerAdministration: Cria cliente, endereço cliente, contrato
- CustomerManagement: Cria grupo de regiões, hierarquia do cliente, garagem
- MerchantAdministration: Cria, altera e consulta administração do estabelecimento
- Sunnel: Serviços utilizados pelo Sunnel
- etc

### Métodos

- CommonCorporateLevelAdministration.CorporateLevelExecute: cria base
- CorporateLevelManagement.CardRequisitionCardReeissuingMassive: reemitir cartões
- CustomerAdministration.CustomerMaintenanceExecute: cria cliente
- CustomerManagement.EntityHierarchyExecute: cria grupo e regiões
- etc

## ARCA

### Cliente

Utilizado pelo Call Center e pelo Backoffice para realizar operações financeiras, consultas, modificar pedidos, reemitir cartões, bloquear cartões, ativar borderô, entre outra funções

### Parameter

Utilizado internamente para criar usuário, parametrizar regra dos produtos, definir embassadora, vincular o tipo de plástico ao produto, criar subredes, definir tipo de tecnologia, criar perfil de usuários, etc...

### Reports

Utilizado pelo Call Center para criar relatórios. Pedidos gerados por produtos, ajustes de credito por portador, conta com saldo negativo, etc...

## Sistemas Corporativos - Brasil

### Bureau

Por conta de uma exigência do Banco Central é necessário que todo cadastro (Cliente, Estabelecimento, Fornecedor, Candidato) do Grupo Edenred seja Higienizado, ou seja, os dados cadastrais devem estar atualizados e sem restrição no Compliance (Listas restritivas internas ou externas)

O objetivo é entregar informações confiáveis aos sistemas do grupo e bloquear/alertar potenciais clientes que possuem restrições de compliance

Web Services (c#) e banco (sql server) que integram as informações ao ERP-EBS

[Documentação Wiki](http://wiki/xwiki/bin/view/Projetos/Bureau/?srid=UHtvDJxF)

[Bureau QA](http://testberau.lanet.accorservice.net)

[Bureau HOMO](http://homoberau.lanet.accorservice.net)

### ERP-EBS

Solução ERP do Oracle

- AR: responsável pelos módulos de cadastro, faturamento, contrato, etc
- AP: pagamento de clientes, estabelecimento e fornecedor

[ERP-EBS QA](http://su-br-qa-db07.lanet.accorservices.net:8000/OA_HTML/AppsLocalLogin.jsp)

[ERP-EBS HOMO](http://su-br-homo-db07.lanet.accorservices.net:8000/OA_HTML/AppsLocalLogin.jsp)

## Bacen

O grupo Edenred se enquadra no parâmetro de prestação de contas, devido ao Bacen passar a regulamentar o mercado de "Arranjos de Pagamentos" pelo seu montante financeiro envolvido (empresas que trabalham com cartões Prés e Pós Pago)

Informações diárias e mensais que devem ser enviadas:

- Compulsória
- Fluxo de caixa

[Bacen HOMO](http://homobacen.lanet.accorservices.net)

[Bacen PROD](http://bacen.lanet.accorservices.net)