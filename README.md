# AltoQi Axis — LibreChat Customizado

Plataforma de chat com IA baseada no [LibreChat](https://librechat.ai), customizada com tema AltoQi, MCPs e autenticação OIDC/Keycloak.

---

## Repositórios

| Repositório | Descrição |
|-------------|-----------|
| [altoqi-axis-chat](https://github.com/Edvanio/altoqi-axis-chat) | Este projeto — config, tema, deploy |
| [-librechat-fork](https://github.com/Edvanio/-librechat-fork) | Fork do LibreChat (código-fonte) |

---

## Arquitetura

```
LibreChat-Fork/ (fonte)
    └─ docker build → axis-librechat-base:latest
                            └─ Dockerfile (ChatAxis)
                                    └─ docker build → edvanio/axis-librechat:latest
                                                            └─ docker compose up → Container
```

**Princípio:** Toda customização possível deve ser feita **neste repo (ChatAxis)** — sem mexer no fork. O fork (`LibreChat-Fork/`) é alterado apenas para mudanças profundas no código-fonte do LibreChat que não são possíveis por configuração externa.

---

## O que fica em cada lugar

| O que customizar | Onde alterar | Precisa de rebuild? |
|---|---|---|
| Endpoints de IA, MCPs, interface | `librechat.yaml` | Não (volume) |
| Tema visual, cores, layout | `custom.css` | Não (volume) |
| Variáveis de ambiente, chaves de API | `.env` | Não (restart) |
| Logo, favicon | `images/` + `Dockerfile` | Sim (ChatAxis) |
| Patch OIDC, injeções no HTML | `Dockerfile` | Sim (ChatAxis) |
| Tradução pt-BR | `patches/translation-pt-BR.json` | Não (volume) |
| Lógica de backend/frontend | `LibreChat-Fork/` | Sim (fork + ChatAxis) |

---

## Pré-requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado e em execução
- (Opcional) [Git](https://git-scm.com/downloads)

---

## Estrutura do Projeto

```
07-ChatAxis/
├── docker-compose.yml           # Serviços principais (não editar)
├── docker-compose.override.yml  # Customizações locais
├── Dockerfile                   # Build da imagem customizada AltoQi
├── .env                         # Variáveis de ambiente locais (não versionado)
├── .envcopy                     # Template do .env para produção (não versionado)
├── librechat.yaml               # Configuração de endpoints, MCPs e interface
├── custom.css                   # Tema visual AltoQi Axis
├── images/                      # Logo SVG e PNG
├── patches/                     # Patch de auth OIDC e tradução pt-BR
├── LibreChat-Fork/              # Fork do fonte (ignorado pelo git deste repo)
├── .gitignore
└── README.md
```

---

## Configuração Inicial

### 1. Configure as chaves de API no `.env`

Abra o arquivo `.env` e adicione suas chaves de API. Os campos com `user_provided` permitem que cada usuário insira sua própria chave na interface.

Chaves importantes a configurar:
- `OPENAI_API_KEY` — [platform.openai.com](https://platform.openai.com/api-keys)
- `ANTHROPIC_API_KEY` — [console.anthropic.com](https://console.anthropic.com)
- `GOOGLE_KEY` — [aistudio.google.com](https://aistudio.google.com)

> **Segurança:** Altere os valores de `CREDS_KEY`, `CREDS_IV`, `JWT_SECRET` e `JWT_REFRESH_SECRET` antes de usar em produção.
> Use o gerador oficial: https://www.librechat.ai/toolkit/creds_generator

### 2. (Opcional) Configure endpoints customizados no `librechat.yaml`

Descomente e ajuste os blocos de endpoints (Ollama, OpenRouter, Groq, DeepSeek, etc.) conforme necessário.

---

## Subindo o projeto (primeira vez)

```powershell
# 1. Buildar a imagem base do fork (demora ~10 min)
docker build -t axis-librechat-base:latest .\LibreChat-Fork

# 2. Buildar a imagem customizada AltoQi
docker build -t edvanio/axis-librechat:latest .

# 3. Subir os containers
docker compose up -d
```

Acesse: **http://localhost:3080**

---

## Subindo o projeto (uso cotidiano)

Após o primeiro build, basta:

```powershell
docker compose up -d
```

Se alterou apenas `custom.css` ou `librechat.yaml`:
```powershell
docker compose restart api
```

---

## Comandos úteis

| Ação | Comando |
|------|---------|
| Subir serviços | `docker compose up -d` |
| Parar serviços | `docker compose down` |
| Reiniciar o servidor | `docker compose restart api` |
| Ver logs | `docker compose logs -f api` |

---

## Rebuild após alterações

### Alterou `custom.css` ou `librechat.yaml`
Sem rebuild — basta reiniciar:
```powershell
docker compose restart api
```

### Alterou logo, Dockerfile ou patch de auth
Rebuilda apenas a imagem do ChatAxis:
```powershell
docker build -t edvanio/axis-librechat:latest .
docker compose up -d
```

### Alterou o código-fonte no `LibreChat-Fork/`
Rebuilda o fork e depois o ChatAxis:
```powershell
docker build -t axis-librechat-base:latest .\LibreChat-Fork
docker build -t edvanio/axis-librechat:latest .
docker compose up -d
```

---

## Atualizar para nova versão

```powershell
docker compose down

# Remove imagens antigas do LibreChat
docker images -a --format "{{.ID}}" --filter "reference=*librechat*" | ForEach-Object { docker rmi $_ }

docker compose pull
docker compose up -d
```

---

## Solução de problemas

### Porta 3080 já em uso
Edite o `docker-compose.override.yml` e troque a porta:
```yaml
services:
  api:
    ports:
      - "3081:3080"
```
Depois acesse `http://localhost:3081`.

### Container encerra imediatamente
Verifique os logs:
```powershell
docker compose logs api
```

### CPU sem suporte a AVX (ex: VMs antigas)
Edite o `docker-compose.override.yml` e descomente:
```yaml
services:
  mongodb:
    image: mongo:4.4.18
```

---

## Links úteis

- Documentação oficial: https://www.librechat.ai/docs
- Referência do `.env`: https://www.librechat.ai/docs/configuration/dotenv
- Referência do `librechat.yaml`: https://www.librechat.ai/docs/configuration/librechat_yaml
- Validador YAML: https://www.librechat.ai/toolkit/yaml_checker
- Gerador de chaves: https://www.librechat.ai/toolkit/creds_generator
