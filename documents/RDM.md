# Criando Requisição de Mudança (RDM)

## A Requisição de Mudança

### Criando a Requisição

1. Dentro do Jira acesse Projects e selecione Ticket RDM (TRDM)
2. Create nova Issue

### Preenchendo a Issue

- Summary: Informar um título
- Description: Descrever de forma objetiva sobre as mudanças e seus impactos
- Involves Brazil Architecture: Envolve arquitetura brasileira?
  - Se sim preencher os campos Branch URL e URL and TAG Review
- Category: Categoria da RDM
  - Scheduled (sendo apresentadas e discutidas no comite)
  - Not Scheduled (para ser executado fora do fluxo padrão, perante aprovação Gerencial)
  - Emergency Change (Correções de incidentes que impactem o ambiente produtivo. Perante aprovação Gerencial)
- Demanding Team: Torre de Demanda
- Nature: Natureza da mudança
- Issue: Relacionar a **"origem"** da mudança; ID de projetos, Incidentes, Requisições e/ou Problemas
- Impact Preview: Impacto previsto?
  - Se sim preencher Impact Description informando as áreas ou processos da empresa que serão impactados
- Request to send a communication: Plano de comunicação de indisponibilidade
  - Homologation
  - Homologation and Production
  - Production
- New Environment/Application in the DXC Infrastructure?: Novo Ambiente/Aplicação na infraestrutura da DXC? (para envio de documentação: RTPA2, KPE, etc) para controle e atualização do CMDB da DXC
- Requires DXC Monitoring?: Solicitar monitoração de ambientes críticos para DXC (KPE)
- Attachement: Anexar arquivo e/ou evidências de testes realizados em homologação
- Affected Countries: Paises que serão impactados com a mudança
- System Change: Aplicações que serão impactadas com a mudança
- Responsible for Validation: Informar o contato dos responsáveis pela validação (nome, telefone e email)
- Reporter: Preenchido automaticamente. Poderá ser alterado para outro responsável, caso não seja o usuário que abriu a RDM

## As sub Tarefas (subtask) da Requisição de Mudança (RDM)

### Criando atividades para RDM

1. Dentro da sua RDM acesse Create subtask

### Preenchendo Subtask

- Summary: Título para a atividade
- Activity Environment: Ambiente que será realizada à atividade
- Implemantation Plan: Detalhar o plano de execuçao da atividade com todas as informações de acesso, caminhos de pastas, servidores, etc
- Fallback Plan: Plano de fallback que será executado caso seja identificado impacto no ambiente relacionado ao plano implementado
- Solver Group: Grupo responsável pela execução da atividade
- Attachement: Anexar arquivo e/ou evidências relativo ao plano da atividade
- Após criar a Subtask basta submeter, botão Send to Screening