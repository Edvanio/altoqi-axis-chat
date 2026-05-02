# Plano de Upgrade Visual — LibreChat-Fork → Interface AltoQi Axis

> **Objetivo:** Fazer a interface do LibreChat-Fork se assemelhar visualmente à interface do `remix-of-interface-altoqi-axis-main`, com **baixo impacto de implementação**, sem incluir funcionalidades que não existem no LibreChat, e com itens extras controlados via role `ADMIN`.

---

## 1. Resumo da Análise Comparativa

| Aspecto | remix-of-interface (referência) | LibreChat-Fork (atual) | Gap |
|---------|-------------------------------|----------------------|-----|
| **Cor primária** | Verde HSL(152, 69%, 40%) | Já aplicado via `custom.css` | ✅ OK |
| **Sidebar** | Verde escuro w-72, logo visível, busca, nav por views | Sidebar colapsável, ícones, sem busca integrada na nav | 🟡 Parcial |
| **Fonte** | Inter 300–700 | Já forçado via `custom.css` | ✅ OK |
| **Landing do Chat** | Logo centralizado + textarea com model picker | Tela com sugestões genéricas | 🔴 Diferente |
| **Bolhas de mensagem** | Coloridas (verde user / cinza AI) com avatares circulares | Transparentes (custom.css atual) | 🟡 Ajustar |
| **Model picker** | Dropdown com emojis por modelo no input | Selector no header (diferente visual) | 🟡 Parcial |
| **Topbar** | Branca, info do agente + model picker + share | Header existente com presets/bookmarks | 🟡 Parcial |
| **Cards de agente** | Grid 2-col com emoji, borda, hover shadow | Já existe marketplace/agents | 🟡 Estilizar |
| **User menu** | Avatar + nome + plano + popup (idioma, ajuda, sair) | Menu settings/logout existente | 🟡 Estilizar |
| **Busca na sidebar** | Input integrado no topo da sidebar | Existe como feature separada | 🟡 Reposicionar via CSS |
| **Dark mode toggle** | Botão Sun/Moon na sidebar (topo) | Existe em settings | 🟡 Realocar |
| **Scrollbar** | Custom thin (4px, verde) | Já no custom.css (6px) | ✅ OK |
| **Border radius** | 8px–16px generoso | Já no custom.css | ✅ OK |

---

## 2. O Que NÃO Incluir (não existe no LibreChat)

| Feature do remix | Motivo de exclusão |
|-----------------|-------------------|
| Gestão de "Pastas/Projetos" com sessions vinculadas | LibreChat não tem conceito de projetos — impacto alto |
| "Cadastro de IA" (tela de registro de modelos) | LibreChat usa `librechat.yaml` para isso |
| Model picker com emojis no composer | LibreChat usa endpoint selector diferente — impacto médio-alto no React |
| Compartilhar conversa (ShareModal customizado) | LibreChat já tem share nativo, manter o dele |
| Tabs "Pergunta / Agentes" no landing | Não existe conceito equivalente — impacto alto |

---

## 3. O Que Colocar Apenas para ADMIN

| Feature | Justificativa | Mecanismo |
|---------|--------------|-----------|
| Botão "Conectores" (MCP) na sidebar | Admin configura; user usa | `interface.mcpServers.use: true` + `create: false` no `librechat.yaml` por role |
| Link para Agent Marketplace/criar agente | Admin cria agentes; user seleciona | `interface.agents.create: false` para user |
| Configurações avançadas (endpoint params) | Complexo demais para user final | Já é admin-only via permissions |

---

## 4. Plano de Implementação — 7 Blocos

### Bloco 1: Sidebar — Identidade Visual (CSS only)
**Impacto:** Baixo (apenas `custom.css`)  
**Arquivos:** `custom.css`

| # | Tarefa | Detalhe |
|---|--------|---------|
| 1.1 | Forçar sidebar expandida (w-72 / 288px) | CSS: `nav[aria-label] { width: 288px !important; min-width: 288px; }` |
| 1.2 | Logo + nome "AltoQi Axis" sempre visível | Substituir SVG do logo via Dockerfile (já feito); garantir que texto do app title apareça ao lado do logo via CSS `content` ou via `librechat.yaml > interface.appTitle` |
| 1.3 | Cor de fundo sidebar verde escuro | Já está no `custom.css` — validar seletores com versão atual |
| 1.4 | Hover items: `hsla(152, 30%, 40%, 0.12)` | Já está — manter |
| 1.5 | Active item: fundo verde 15% + border-left 3px verde | Já está — manter |
| 1.6 | Labels uppercase `text-xs tracking-wider` | Já está — manter |
| 1.7 | User footer: avatar circular com inicial | CSS para `.nav-user` / `[data-testid="user-menu"]` → border-radius: 50%, bg amber |

---

### Bloco 2: Landing Page do Chat (CSS + config)
**Impacto:** Baixo-Médio  
**Arquivos:** `custom.css`, `librechat.yaml`

| # | Tarefa | Detalhe |
|---|--------|---------|
| 2.1 | Logo centralizado na landing | CSS: center logo no `.landing` / `[data-testid="landing-page"]`; aumentar tamanho para 40×40px |
| 2.2 | Placeholder do textarea | Tradução pt-BR: "Precisa de ajuda? Pergunte, pesquise ou crie." via `patches/translation-pt-BR.json` |
| 2.3 | Caixa de input com borda arredondada xl (16px) | CSS no composer container: `border-radius: 16px; border: 1px solid var(--border-light)` |
| 2.4 | Esconder/estilizar sugestões padrão | Se `startupConfig.showSuggestions` — estilizar como cards com borda + hover shadow (igual agents cards do remix) |
| 2.5 | Exibir agentes como grid de cards abaixo do input | Usar config `interface.agents.use: true` + CSS para exibir em grid 2-col na landing |

---

### Bloco 3: Bolhas de Mensagem (CSS only)
**Impacto:** Baixo  
**Arquivos:** `custom.css`

| # | Tarefa | Detalhe |
|---|--------|---------|
| 3.1 | Decidir: manter transparente ou colorir | **Recomendação:** colorir levemente como no remix para ficar mais parecido |
| 3.2 | Bolha do user | `background: hsla(152, 69%, 40%, 0.08)` light / `hsla(152, 69%, 40%, 0.12)` dark; `border-radius: 12px 12px 4px 12px` |
| 3.3 | Bolha da AI | `background: hsl(210, 10%, 96%)` light / `hsl(210, 11%, 18%)` dark; `border-radius: 12px 12px 12px 4px` |
| 3.4 | Avatar circular ao lado | CSS: forçar avatar container como `w-8 h-8 rounded-full` com cores distintas (verde user, cinza AI) |
| 3.5 | Max-width das bolhas | `max-width: min(768px, 80%)` — já está |
| 3.6 | Espaçamento entre mensagens | `gap/margin: 16px` entre blocos |

---

### Bloco 4: Header/Topbar (CSS only)
**Impacto:** Baixo  
**Arquivos:** `custom.css`

| # | Tarefa | Detalhe |
|---|--------|---------|
| 4.1 | Fundo branco com borda inferior sutil | `background: white; border-bottom: 1px solid hsl(210, 14%, 89%)` |
| 4.2 | Model/endpoint selector | Estilizar como pill arredondada com borda: `rounded-lg border px-3 py-1.5` |
| 4.3 | Botões do header (bookmarks, export) | Manter; estilizar com `rounded-lg border hover:bg-muted` |
| 4.4 | Dark mode: topbar cinza escuro | `.dark` header: `bg hsl(210, 11%, 12%); border hsl(210, 10%, 20%)` |

---

### Bloco 5: Cards e Marketplace de Agentes (CSS only)
**Impacto:** Baixo  
**Arquivos:** `custom.css`

| # | Tarefa | Detalhe |
|---|--------|---------|
| 5.1 | Cards dos agentes em grid responsivo | `display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 12px` |
| 5.2 | Card style | `border: 1px solid border-light; border-radius: 12px; padding: 16px; hover: shadow-md + border-primary/30` |
| 5.3 | Ícone/emoji do agente em destaque | `font-size: 2rem` no avatar/icon do agent |
| 5.4 | Nome e descrição | Nome `font-medium text-sm`; descrição `text-xs text-muted line-clamp-2` |
| 5.5 | Transição hover | `transform: translateY(-1px); transition: all 150ms` — já está no custom.css |

---

### Bloco 6: Tradução e Textos (JSON patch)
**Impacto:** Baixo  
**Arquivos:** `patches/translation-pt-BR.json`, Dockerfile

| # | Tarefa | Detalhe |
|---|--------|---------|
| 6.1 | Revisar `patches/translation-pt-BR.json` | Adicionar/atualizar keys para placeholders, labels da sidebar, landing |
| 6.2 | Placeholder do composer | `"com_ui_send_message": "Precisa de ajuda? Pergunte, pesquise ou crie."` |
| 6.3 | Botão novo chat | `"com_ui_new_chat": "Novo Chat"` |
| 6.4 | Seção "Conversas" | `"com_nav_conversations": "Conversas"` |
| 6.5 | Menu do user | Traduzir labels: "Idioma", "Obter ajuda", "Sair" |
| 6.6 | Agentes | `"com_ui_agents": "Agentes"` |
| 6.7 | Footer personalizado | `librechat.yaml > interface.customFooter: "AltoQi Axis"` ou vazio |

---

### Bloco 7: Configuração YAML + Docker (config)
**Impacto:** Baixo  
**Arquivos:** `librechat.yaml`, `docker-compose.override.yml`

| # | Tarefa | Detalhe |
|---|--------|---------|
| 7.1 | App title | `interface.appTitle: "AltoQi Axis"` |
| 7.2 | Agentes visíveis para todos, criar só admin | `interface.agents: { use: true, create: false, share: false }` + override para admin role |
| 7.3 | MCP visível só admin | `interface.mcpServers: { use: true, create: true }` filtrado por role no yaml |
| 7.4 | Marketplace | Habilitar para user (somente use): `interface.marketplace: { use: true }` |
| 7.5 | Custom footer | `interface.customFooter: ""` (limpo, sem link LibreChat) |
| 7.6 | Logo no login | Garantir que `OPENID_IMAGE_URL` ou assets substituídos apontem para logo AltoQi |
| 7.7 | Validar volume mounts no `docker-compose.override.yml` | `custom.css` montado em `/app/client/dist/assets/custom.css` |

---

## 5. Ordem de Execução Recomendada

```
Bloco 7 (config YAML)     →  Bloco 6 (traduções)
       ↓                              ↓
Bloco 1 (sidebar CSS)     →  Bloco 4 (topbar CSS)
       ↓                              ↓
Bloco 3 (bolhas CSS)      →  Bloco 5 (cards CSS)
       ↓
Bloco 2 (landing CSS)
```

**Estimativa de complexidade total:** ~1 arquivo CSS principal + 1 JSON de tradução + ajustes no `librechat.yaml`

---

## 6. Critérios de Aceite

| # | Critério | Validação |
|---|----------|-----------|
| 1 | Sidebar verde escura expandida com logo + nome visíveis | Visual |
| 2 | Landing com logo centralizado e input arredondado | Visual |
| 3 | Bolhas com fundo sutil (verde claro user / cinza AI) | Visual |
| 4 | Cards de agente em grid com hover elegante | Visual |
| 5 | Topbar branca/clean com selector estilizado | Visual |
| 6 | Textos em pt-BR consistentes com o remix | Funcional |
| 7 | MCP/criar agentes visível apenas para admin | Funcional (testar com user normal) |
| 8 | Dark mode funcional em todos os blocos | Visual |
| 9 | Nenhuma funcionalidade quebrada do LibreChat original | Regressão |
| 10 | Build Docker passa sem erro | CI |

---

## 7. Riscos e Mitigações

| Risco | Probabilidade | Mitigação |
|-------|--------------|-----------|
| Seletores CSS quebram em update do LibreChat | Média | Usar `data-testid` quando disponível; documentar seletores frágeis |
| Sidebar forçada larga quebra mobile | Baixa | Media query `@media (max-width: 768px)` para colapsar |
| Tradução incompleta (keys faltando) | Baixa | Verificar dump de keys com `grep -r "com_ui_"` |
| Permissões de role não refletem no UI | Baixa | Testar com user sem role admin |
| Logo não aparece (path errado) | Baixa | Validar no Dockerfile e docker-compose.override |

---

## 8. Arquivos Impactados (resumo)

| Arquivo | Tipo de mudança |
|---------|----------------|
| `custom.css` | Extensão significativa (~100 linhas novas) |
| `librechat.yaml` | Ajuste de configs `interface.*` |
| `patches/translation-pt-BR.json` | Novas/atualizadas keys pt-BR |
| `Dockerfile` | Nenhuma (já copia custom.css e patches) |
| `docker-compose.override.yml` | Nenhuma (já monta volumes corretos) |
| Código React do LibreChat-Fork | **Nenhuma alteração** — tudo via CSS + config |

---

## 9. Decisões de Design

1. **Bolhas transparentes → levemente coloridas**: O remix usa cores sólidas nas bolhas. Para manter um visual elegante sem ser agressivo, usar opacidade baixa (8–12%) em vez de cor sólida.

2. **Sidebar sempre expandida**: O LibreChat permite colapsar. Vamos forçar expandida via CSS mas manter o botão de colapso funcional (não quebrar a feature).

3. **Sem alteração React**: Todo o visual será atingido via CSS override + YAML config + traduções. Isso garante que atualizações futuras do LibreChat não conflitem com nosso código.

4. **Model picker**: Não replicar o dropdown com emojis — o selector nativo do LibreChat (por endpoint/model) já cumpre a função. Apenas estilizar visualmente.

5. **Compartilhar**: Usar o share nativo do LibreChat em vez de recriar o ShareModal do remix.
