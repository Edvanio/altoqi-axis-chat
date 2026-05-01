# ChatAxis — LibreChat com Docker

Plataforma de chat com IA baseada no [LibreChat](https://librechat.ai), rodando via Docker Compose.

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
├── .env                         # Variáveis de ambiente e chaves de API
├── librechat.yaml               # Configuração de endpoints de IA
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

## Subindo o projeto

```powershell
docker compose up -d
```

Na primeira execução, as imagens serão baixadas (pode demorar alguns minutos).

Acesse: **http://localhost:3080**

> A primeira conta registrada se torna administradora.

---

## Comandos úteis

| Ação | Comando |
|------|---------|
| Subir serviços | `docker compose up -d` |
| Parar serviços | `docker compose down` |
| Ver logs | `docker compose logs -f api` |
| Ver todos os logs | `docker compose logs -f` |
| Reiniciar | `docker compose down && docker compose up -d` |

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
