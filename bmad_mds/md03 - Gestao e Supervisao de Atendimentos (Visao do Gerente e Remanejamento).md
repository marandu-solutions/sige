# MD03: Gestão e Supervisão de Atendimentos Omnichannel
## Cockpit do Gerente, Escalabilidade de Funil e Remanejamento Ágil de Leads

**Status:** Aprovado por Unanimidade pelo Comitê BMAD  
**Data:** 13 de Outubro de 2026  
**Autores (Comitê BMAD):**
- 📋 **John** (Product Manager)
- 🎨 **Sally** (UX/UI Designer)
- 📊 **Mary** (Business Analyst)
- 🏗️ **Winston** (System Architect)
- 💻 **Amelia** (Lead Software Engineer)

---

## 1. Transcrição do Debate BMAD Party Mode

### Contexto Inicial
A reunião foi convocada para tratar de dois pontos críticos levantados pelo gestor do projeto:
1. **Duplicidade na barra de navegação:** As rotas "Kanban" e "Atendimento" estão apontando para a mesma tela, poluindo a navegação do usuário.
2. **Conceito da Visão do Gerente:** A ideia inicial de criar um "Kanban de Vendedores" (onde as colunas seriam os vendedores e os cards seriam os clientes) apresentava graves riscos de usabilidade e perda da visão do funil em times maiores. Foi solicitado ao comitê um debate aprofundado para encontrar a solução mais escalável, ergonômica e alinhada ao contexto multitenant (EPI Forte e Solarium Solar).

---

### O Debate

📋 **John (PM):**  
"Pessoal, vamos direto ao ponto. O usuário nos deu uma excelente sinalização e um desafio claro: primeiro, 'Kanban' e 'Atendimento' estão duplicados na navbar e precisamos remover 'Kanban', deixando apenas Atendimento como hub oficial. Segundo, e mais importante: a visão do gerente. O cliente havia imaginado um 'Kanban de Vendedores', mas sabiamente percebeu o cheiro de problema de escalabilidade e nos pediu para debater a melhor UI/UX. Precisamos de uma solução onde o vendedor tenha seu funil de clientes e o gerente consiga auditar a carga de cada vendedor, ver seus clientes e remanejá-los com facilidade. Sally, por que a ideia de 'colunas = vendedores' acendeu seu alerta vermelho?"

🎨 **Sally (UX Designer):**  
"Graças aos deuses da ergonomia o usuário nos pediu para debater isso antes de codificar! Colocar 'vendedores como colunas de um Kanban' é um antipadrão clássico que parece sedutor no papel com 3 vendedores, mas desmorona miseravelmente na vida real. Vamos desenhar o cenário:
1. **Perda dos Estágios do Funil:** Num Kanban real, as colunas representam *fases de evolução* (Ex: Novo -> Em Cotação -> Proposta -> Fechamento). Se as colunas viram *nomes de vendedores* (Carlos, Beatriz, Mariana), para onde vão as etapas? O cliente do Carlos que acabou de chegar e o cliente que já assinou o contrato ficam todos jogados dentro da mesma coluna vertical! O gerente fica cego sobre a saúde do pipeline.
2. **Explosão Horizontal e Scroll Infinito:** Se uma loja ou distribuidora tem 12 ou 20 atendentes, você tem 20 colunas na tela. O gerente precisa dar scroll horizontal quilométrico para achar alguém.
3. **Sobrecarga de Cards:** Um vendedor com 35 conversas ativas gera uma coluna gigantesca. Tentar arrastar um card do vendedor da coluna 1 para o vendedor da coluna 18 é uma tortura de drag-and-drop.
A pergunta de ouro que o gerente faz todos os dias não é 'quem são meus vendedores?', mas sim: *'Como está o funil do Carlos hoje?', 'Quantos clientes estão parados com a Beatriz?'* e *'Quem pode pegar os leads que o bot de IA acabou de receber?'*."

📊 **Mary (Business Analyst):**  
"Apoiada 100%, Sally. E eu trago a perspectiva do negócio e das duas empresas que atendemos:
Na **EPI Forte**, temos um comércio ágil. Entram 150 cotações por dia. Se o vendedor Carlos entra em horário de almoço ou atesta doença, o gerente precisa abrir a fila dele, ver o que está travado em 'Em Cotação' e remanejar 10 clientes para a Mariana. Se estivesse tudo misturado num 'Kanban de Vendedores', o gerente teria que caçar cotações misturadas com pedidos entregues.
Já na **Solarium Solar**, o ciclo é consultivo de alto ticket. O lead passa por 'Qualificado', 'Conta de Luz', 'Proposta Solar' e 'Financiamento'. O gerente precisa saber *onde* o lead está no funil, e remanejar baseado em especialidade técnica (ex: projetos residenciais vs fazendas solares).
Além disso, temos o fator mais crítico do SIGE: **o Bot de IA Omnichannel 24/7**. Quando um cliente manda mensagem no WhatsApp às 23h, para qual vendedor ele vai? Ele entra numa fila de **'Não Atribuídos' (Unassigned)**. O gerente precisa ver essa fila de triagem de imediato para distribuir aos vendedores na manhã seguinte!"

🏗️ **Winston (Architect):**  
"Arquiteturalmente, a visão da Sally e da Mary salva nossa modelagem de dados no Firestore.
Se criássemos um 'Kanban de Vendedores', teríamos que adulterar o campo `coluna_status` para guardar o `funcionario_id` em vez do estágio do funil, ou criaríamos dois esquemas de banco conflitantes para a mesma coleção `atendimento`. Isso seria uma aberração técnica que geraria bugs crônicos de sincronização.
O modelo correto, limpo e escalável é:
- **Uma única coleção de cards:** `tenant/{tenantId}/atendimento/board/historico/{cardId}`.
- O campo `coluna_status` continua armazenando a coluna do funil de vendas (`novo`, `cotacao`, `proposta`, `fechado`), que respeita a configuração do Tenant seedada no MD02.
- O campo `funcionario_responsavel_id` armazena o UID do vendedor atribuído (ou `null` se for do Bot/Não Atribuído).
- **No frontend:** A visão do Gerente mantém as colunas reais do funil, mas ganha um **Cockpit de Supervisão de Equipe no Topo**: uma barra de navegação rápida com avatares/chips dos vendedores, trazendo a contagem de clientes ativos de cada um e um botão de ação rápida para remanejar."

💻 **Amelia (Lead Dev):**  
"E tecnicamente no Flutter isso fica espetacular e muito fluido de codificar.
Vejam como a implementação resolve cirurgicamente tudo o que o usuário pediu:
1. **Limpeza da Nav:** Removemos `'kanban'` de `home_page.dart` e de `app_routes.dart`. O menu fica limpo, com 'Atendimento' como módulo único de comunicação e CRM.
2. **Detecção de Papel (Role-Aware):** Em `AtendimentoScreen`, lemos a role do usuário via `authServiceProvider`. Se for vendedor comum (`funcionario`), o filtro padrão mostra apenas as conversas dele (`_onlyMyCards = true`). Ele foca no trabalho dele.
3. **Cockpit do Gerente (Supervisão):** Se for `admin`, `dono` ou `gerente`, renderizamos logo abaixo do AppBar uma **Barra de Atendentes da Equipe**:
   - Chip `[Todos (48)]`: Mostra o quadro global com crachá do vendedor em cada card.
   - Chip `[Não Atribuídos (Bot IA) (6)]`: Destaque com cor de alerta, para o gerente ver os leads novos que entraram pela IA e precisam de dono.
   - Chips dos Vendedores `[Carlos (14)]`, `[Beatriz (12)]`, `[Mariana (16)]`: Ao clicar na Mariana, o Kanban vira instantaneamente o funil exclusivo da Mariana! O gerente vê exatamente os cards dela passando de coluna em coluna.
4. **Remanejamento Ágil:** 
   - No card do atendimento: colocamos um botão de ação rápida (três pontinhos ou ícone de transferência `LucideIcons.userCheck` / `arrowRightLeft`).
   - Ao tocar, abre um BottomSheet / Dialog elegante listando os funcionários ativos da empresa (vindos do `funcionariosProvider`), com foto, nome e quantidade atual de atendimentos.
   - O gerente clica no novo vendedor, o Firestore atualiza `funcionario_responsavel_id`, e a UI reage em tempo real via Stream!"

🎨 **Sally (UX Designer):**  
"Essa barra de chips no topo é o estado da arte de CRM moderno (inspirado no Linear e HubSpot)! Ela não polui a tela, funciona perfeitamente em telas de desktop com scroll suave ou wrap, e em telas móveis vira um carrossel horizontal de toque.
E o melhor: dá ao gerente um **termômetro instantâneo de sobrecarga**. Só de olhar para a barra, o gerente vê: 'Nossa, o Carlos está com 28 atendimentos e a Mariana está com apenas 4. Vou abrir o funil do Carlos e passar 8 cotações para ela'."

📋 **John (PM):**  
"Perfeito! Todos concordam com esse modelo?
- Mary: De acordo com a jornada de vendas e triagem do Bot IA?
- Winston: De acordo com a integridade do Firestore e segurança?
- Sally: De acordo com a ergonomia e fim do pesadelo das 20 colunas horizontais?
- Amelia: Pronta para executar no código?"

📊 **Mary:** "Aprovado! Resolve tanto a velocidade da EPI Forte quanto a qualificação da Solarium."  
🏗️ **Winston:** "Aprovado! 100% aderente aos princípios SOLID e isolamento multitenant."  
🎨 **Sally:** "Aprovado com louvor! O usuário vai adorar a elegância visual."  
💻 **Amelia:** "Vamos ao código agora mesmo!"

---

## 2. Parecer Oficial da Equipe e Arquitetura da Solução

### 2.1 A Decisão Técnica e de Produto
Rejeitou-se a arquitetura de "Colunas = Vendedores" pelos seguintes fatores impeditivos:
- **Degradação de Pipeline:** Anula as etapas do processo comercial de cada tenant.
- **Inviabilidade Ergonômica:** Impossibilita o uso com equipes superiores a 5 vendedores.
- **Quebra do Schema:** Corrompe a semântica da propriedade `coluna_status`.

Adotou-se o **Cockpit de Funil Mestre com Seletor Dinâmico de Atendentes e Fila de Triagem**:
1. **Preservação do Funil de Fases:** As colunas do Kanban continuam representando os estágios do ciclo de vendas configurados no Tenant (`kanban_config.colunas`).
2. **Barra de Supervisão de Atendentes (Supervisor Bar):** Componente superior interativo exibindo chips com contadores em tempo real de carga de trabalho por membro da equipe.
3. **Fila de Não Atribuídos (Triage IA):** Filtro exclusivo para triagem imediata de leads gerados pelas integrações omnichannel (WhatsApp/Instagram/Facebook).
4. **Mecanismo de Remanejamento em 2 Cliques:** Capacidade de transferir a responsabilidade de qualquer atendimento para outro membro da equipe diretamente pelo card ou modal de detalhes, com atualização em tempo real.

---

## 3. Especificação de UI/UX (Cockpit do Gerente)

### Wireframe Mental do Cockpit
```text
+--------------------------------------------------------------------------------------------------+
| AppBar: Atendimentos Omnichannel  [Expiração] [Histórico] [Nova Coluna] [Novo Lead] [Filtro/Visão]|
+--------------------------------------------------------------------------------------------------+
| BARRA DE SUPERVISÃO (Visível apenas para Gerente/Admin/Dono):                                    |
| [ Todos (42) ]  [ ⚠️ Não Atribuídos (6) ]  [ 👤 Carlos (14) ]  [ 👤 Beatriz (12) ]  [ 👤 Mari (10) ]|
+--------------------------------------------------------------------------------------------------+
| KANBAN DE ESTÁGIOS (Filtrado pelo atendente selecionado acima):                                  |
|                                                                                                  |
|  [ Novo Contato (12) ]      [ Em Cotação (18) ]       [ Proposta (8) ]       [ Fechado (4) ]     |
|  +--------------------+     +--------------------+    +--------------------+  +----------------+ |
|  | Lead: Supermercado |     | Lead: Metalúrgica  |    | Lead: Fazenda Sol  |  | Lead: Posto SP | |
|  | Resp: Carlos       |     | Resp: Beatriz      |    | Resp: Mariana      |  | Resp: Carlos   | |
|  | [Trocar Vendedor]  |     | [Trocar Vendedor]  |    | [Trocar Vendedor]  |  | [Trocar Vend.] | |
|  +--------------------+     +--------------------+    +--------------------+  +----------------+ |
+--------------------------------------------------------------------------------------------------+
```

### Regras de Interação e Permissão
1. **Vendedor Comum (`funcionario`):**
   - Vê por padrão apenas os seus próprios atendimentos (`_onlyMyCards = true`).
   - Pode visualizar o quadro geral se o gerente liberar a permissão de equipe, mas não pode remanejar cards de outros colegas.
2. **Gerente / Administrador / Dono (`gerente`, `admin`, `dono`):**
   - Vê a Barra de Supervisão com contagem de carga de todos os atendentes.
   - Pode filtrar a visão por qualquer vendedor com um único clique no chip.
   - Tem acesso ao botão "Remanejar Atendente" em cada card de atendimento.
   - Pode enviar um atendimento de volta para a fila "Não Atribuído" se necessário.

---

## 4. Modelagem de Dados no Firestore

### Esquema do Documento de Atendimento
Caminho: `tenant/{tenantId}/atendimento/board/historico/{cardId}`

```json
{
  "id": "card_abc123",
  "tenant_id": "tenant_epi_01",
  "titulo": "Cotação 50 Luvas Nitrílicas e Capacetes",
  "coluna_status": "c2",
  "prioridade": "alta",
  "cliente_nome": "Marcos Silveira",
  "cliente_telefone": "+5511999887766",
  "funcionario_responsavel_id": "user_carlos_01",
  "funcionario_responsavel_nome": "Carlos Silva",
  "status": "ativo",
  "mensagens_nao_lidas": 2,
  "ultima_mensagem": "Consegue dar 5% de desconto para faturamento em 30 dias?",
  "data_criacao": "2026-10-13T08:00:00Z",
  "data_ultima_atualizacao": "2026-10-13T10:15:00Z",
  "historico_atribuicoes": [
    {
      "de_funcionario_id": null,
      "para_funcionario_id": "user_carlos_01",
      "por_usuario_id": "gerente_roberto_99",
      "data": "2026-10-13T08:30:00Z",
      "motivo": "Distribuição inicial da fila IA"
    }
  ]
}
```

---

## 5. Plano de Implementação Detalhado

### Etapa 1: Correção Imediata da Navegação
- [x] Remover a entrada `'kanban'` e `'module_kanban'` do mapa de rotas disponíveis em `lib/src/core/routes/app_routes.dart`.
- [x] Ajustar o método `_calcularModulos` em `lib/src/shell/home_page/home_page.dart` para ignorar qualquer módulo legado denominado `kanban`, eliminando o item duplicado do Sidebar e do BottomNavigationBar.

### Etapa 2: Camada de Serviços e Notifier
- [x] Adicionar o método `reassignCard(tenantId, cardId, newFuncionarioId, {newFuncionarioNome})` em `AtendimentoService`.
- [x] Adicionar o método `reassignCard(...)` no `AtendimentoNotifier` em `AtendimentoProvider`.

### Etapa 3: Barra de Supervisão do Gerente
- [x] Integrar a verificação de permissão do usuário logado na `AtendimentoScreen`.
- [x] Carregar a lista de funcionários ativos via `funcionariosProvider(tenantId)`.
- [x] Renderizar a barra horizontal de chips com as estatísticas de cada vendedor e a contagem de "Não Atribuídos".
- [x] Permitir alternância dinâmica de filtro entre `Todos`, `Não Atribuídos` e vendedores individuais.

### Etapa 4: Ergonomia de Remanejamento no Card
- [x] Exibir o nome/avatar do vendedor responsável diretamente no card de atendimento.
- [x] Adicionar diálogo de remanejamento (`showDialog`) ao clicar no ícone de transferência do card.
- [x] Atualizar os dados atomicamente no Firestore e refletir na interface sem necessidade de reload.

### Etapa 5: Validação e Testes
- [x] Executar análise estática (`flutter analyze`) para garantir 0 erros de tipagem ou lint.
- [x] Validar persistência multitenant para os dois clientes-piloto (EPI Forte e Solarium Solar).

---

## 6. Conclusão e Próximos Passos
Com esta decisão e implementação, o SIGE ganha uma experiência de atendimento moderna, profissional e verdadeiramente escalável. O gerente tem visão total e controle operacional sem quebrar o funil de vendas, e o vendedor trabalha focado em sua própria esteira de clientes.

---

## 7. Refinamento de UI/UX por Sally: Segregação Visual Completa & Design System no Modo Claro

### 7.1 Segregação Arquitetural das Duas Telas
Para eliminar qualquer ambiguidade entre vendedor e gestor, o sistema opera com duas rotas e componentes distintos:
1. **`AtendimentoScreen` (Workspace Pessoal do Vendedor):**
   - Rota: `/atendimento` (Mapeada na Navbar para vendedores e gerentes).
   - Foco: Produtividade individual (`Meus Atendimentos`).
   - KPIs Pessoais: Meus Clientes Ativos, Mensagens Não Lidas, Cotações Abertas.
   - Filtros Pessoais: Todos, Não Lidos, Alta Prioridade.
   - Restrição Ergonômica: Não exibe barra de supervisão de terceiros nem botões de remanejamento.
2. **`GerenteAtendimentoScreen` (Cockpit de Supervisão do Gerente):**
   - Rota: `/gerente_atendimento` (Mapeada na Navbar como `Supervisão` exclusivamente para `admin`, `dono` e `gerente`).
   - Foco: Gestão de equipe, balanceamento de carteiras e triagem de leads.
   - Seletor Dinâmico de Atendentes (Cockpit Team Switcher): Permite auditar o funil de qualquer vendedor em 1 clique.
   - Triagem IA: Fila isolada de novos leads recebidos pela IA nos canais omnichannel (WhatsApp/Instagram/Facebook).
   - Remanejamento Ágil: Ação rápida em cada card com modal e indicadores de carga de trabalho dos membros da equipe.

### 7.2 Design System e Solução Definitiva do Modo Claro
- **Classe `SigeTheme` & `SigeColors`:**
  - Padronização em `CardThemeData` com superfície branca cristalina (`#FFFFFF`), bordas ultra-finas (`0.8px` em `#E2E8F0`) e sombras suaves (`BoxShadow(color: Color(0x0A0F172A), blurRadius: 8, offset: Offset(0, 2))`).
  - Remoção de containers pretos hardcoded em modo claro (`Colors.grey[800]`), substituídos por balões de mensagem harmoniosos e acessíveis.
  - Badges suaves de prioridade com fundo pastel e tipografia saturada (Verde Esmeralda para Baixa, Âmbar para Média, Rosa/Vermelho para Alta).
  - Pistas de Kanban (`AtendimentoColumn`) com container estruturado em Slate 100 suave (`#F1F5F9`) no modo claro e Slate 800 (`#161F30`) no modo escuro, com animação fluida de arrasto e soltura.

---

## 8. Arquitetura Definitiva do Cockpit Executivo do Gerente (Sally UX - "UAU!")

### 8.1 Por que os Chips Horizontais Falharam na Prática
Na auditoria visual do protótipo com a equipe de design, identificou-se que colocar atendentes como filtros horizontais no topo repetia problemas de usabilidade:
- **Inviabilidade para 5 a 50+ Atendentes:** Uma fileira horizontal de 22 chips exige scroll lateral cansativo, oculta quem está com gargalos e trata profissionais como filtros frios de e-commerce.
- **Falta de Inteligência Visual Operacional:** O gerente não sabia num relance quem estava ocioso, quem estava sobrecarregado e quem tinha clientes aguardando resposta há mais de 30 minutos.
- **Ruído Visual no Quadro:** Alças de arraste de coluna protuberantes (`:::`) quebrando as bordas superiores e estados vazios com ícones de cesto desproporcionais.

### 8.2 A Solução: Dual-Pane Command Center (Radar da Equipe + HUD Executivo ao Vivo)

```text
+---------------------------------------------------------------------------------------------------------------+
| APPBAR: Cockpit de Supervisão Comercial  [MODO GERENTE]        [Expiração] [Histórico] [Nova Etapa] [+ Lead]  |
+---------------------------------------------------------------------------------------------------------------+
| [ RADAR OPERACIONAL DA EQUIPE ]    | [ HUD EXECUTIVO DO ATENDENTE SELECIONADO ]                               |
| [🔍 Buscar atendente ou cargo...]  | 👤 Handerson Lima • Vendedor Sênior [🟢 Ao Vivo]                         |
| [Todos] [Sobrecarga] [Livres]      | [🎯 12 Leads]  [💬 4 Pendentes]  [⚖️ Carga Ideal]  [⚡ Remanejar Excedente]|
|------------------------------------|--------------------------------------------------------------------------|
| 🌐 Visão Panorâmica (48 leads)     | [ KANBAN DE ETAPAS AO VIVO ]                                             |
| 🤖 Fila IA 24/7 (6 aguardando) [Auto|                                                                         |
|------------------------------------|  [ Novos Leads (4) ]     [ Em Negociação (5) ]      [ Fechamento (3) ]   |
| ATENDENTES (22):                   |  +--------------------+  +--------------------+     +------------------+ |
| 🟢 Carlos Silva (Closer)           |  | Lead: Empresa Alfa |  | Lead: Agro Solar   |     | Lead: Hospital   | |
|    [====------] 4 leads            |  | 💬 1 | WhatsApp    |  | 💬 0 | WhatsApp    |     | 💬 0 | Instagram | |
| 🔴 Beatriz Rocha (SDR)             |  | [Remanejar]        |  | [Remanejar]        |     | [Remanejar]      | |
|    [==========] 14 leads ⚠️        |  +--------------------+  +--------------------+     +------------------+ |
| 🟢 Mariana Rios (Consultora)       |                                                                          |
|    [==--------] 2 leads (Livre)    |  *DICA UAU: Arraste qualquer lead do Kanban e solte direto sobre o       |
|                                    |   nome do atendente no Radar à esquerda para remanejar na hora!          |
+------------------------------------+--------------------------------------------------------------------------+
```

### 8.3 Inovações Chave Implementadas
1. **Radar da Equipe com Termômetro de Carga Visual:**
   - Barra de capacidade em tempo real (Verde até 4 leads, Âmbar até 9 leads, Vermelho em sobrecarga com 10+ leads).
   - Busca instantânea por nome ou especialidade/cargo.
   - Pinned Card para a **Fila IA 24/7** com botão de **Distribuição Round-Robin Automática em 1 Toque**.
2. **Remanejamento por Drag & Drop Direto no Radar:**
   - O gerente pode arrastar qualquer lead do Kanban e **soltar diretamente sobre o atendente na barra lateral esquerda** (`DragTarget`), executando a transferência com feedback visual e SnackBar em tempo real.
3. **HUD Executivo Integrado:**
   - Mostra métricas consolidadas do atendente selecionado, status operacional e botão de ação rápida para aliviar carteira.
4. **Acabamento das Colunas:**
   - Alça de reordenação (`gripVertical`) embutida organicamente dentro do cabeçalho da coluna.
   - Empty state com container pontilhado discreto ("Nenhum atendimento • Arraste leads para cá").

---

## 9. Workspace Pessoal de Alta Performance do Vendedor (Sally UX - "UAU!")

### 9.1 A Filosofia: Estado de Fluxo e Foco Comercial
Enquanto o gerente precisa de auditoria e visão panorâmica da equipe, o atendente/vendedor precisa de **velocidade, clareza e ritmo de fechamento**. Ele não pode perder tempo procurando quem está sem resposta ou navegando em telas confusas.

```text
+---------------------------------------------------------------------------------------------------------------+
| APPBAR: Meus Atendimentos [PRODUTIVIDADE VENDAS]            [Histórico] [Nova Etapa] [+ Novo Cliente]         |
+---------------------------------------------------------------------------------------------------------------+
| [ COCKPIT RIBBON DE METAS & STATUS ]                                                                          |
| 💬 Pipeline Ativo de Handerson [Respostas Pendentes]  |  [👥 8 Em Negociação] [💬 3 Aguardando] [🔥 2 Urgentes]|
| "Atenção: Você tem 3 clientes esperando resposta no WhatsApp/Omnichannel! Vamos fechar negócios hoje!"       |
+---------------------------------------------------------------------------------------------------------------+
| [ BARRA DE FOCO & BUSCA INSTANTÂNEA ]                                                                         |
| [🔍 Filtrar cliente por nome, telefone ou produto...] | [✨ Todos (8)]  [💬 Não Lidos (3)]  [🔥 Prioridade (2)] |
+---------------------------------------------------------------------------------------------------------------+
| [ KANBAN DE CONVERSÃO DO VENDEDOR ]                                                                           |
|                                                                                                               |
|  [ Novos Leads (2) ]       [ Em Cotação (4) ]        [ Proposta Enviada (2) ]      [ Fechamento (0) ]         |
|  +--------------------+    +--------------------+    +--------------------+        +------------------------+ |
|  | Marcos (EPIs)      |    | Construtora Beta   |    | Supermercado Silva |        | [ Sem atendimentos     | |
|  | 💬 1 | WhatsApp    |    | 💬 2 | WhatsApp    |    | 💬 0 | WhatsApp    |        |   Arraste para cá ]    | |
|  +--------------------+    +--------------------+    +--------------------+        +------------------------+ |
+---------------------------------------------------------------------------------------------------------------+
```

### 9.2 Inovações Chave para o Atendente
1. **Ribbon de Produtividade & Saudação Contextual:**
   - Saudação inteligente com nome (`Bom dia, Handerson 🚀`).
   - Diagnóstico em tempo real da carteira (*Respostas Pendentes* vs *Carteira em Dia*).
   - KPIs de foco imediato: clientes em negociação, mensagens não respondidas e oportunidades quentes.
2. **Barra de Foco Rápido & Busca em Tempo Real:**
   - Campo de busca instantânea que filtra simultaneamente por nome do cliente, telefone ou demanda em todas as colunas do funil.
   - Segmented Pills de foco com contadores dinâmicos (`Todos`, `Não Lidos`, `Alta Prioridade`).
3. **Chat Lateral Integrado em 1 Toque:**
   - Ao tocar em qualquer card, abre imediatamente o chat omnichannel lateral mantendo a visão do funil ativa.


