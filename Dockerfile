# Dockerfile customizado do ChatAxis
# Estende o LibreChat-Fork (fonte local) e injeta customizações AltoQi.
#
# Pré-requisito: buildar a imagem do fork antes:
#   docker build -t axis-librechat-base:latest ./LibreChat-Fork
#
# Build:  docker build -t edvanio/axis-librechat:latest .
# Push:   docker push edvanio/axis-librechat:latest

FROM axis-librechat-base:latest

# Configuração principal (interface, MCP visuscost, etc.)
COPY librechat.yaml /app/librechat.yaml

# Logo customizado (substitui o logo padrão do LibreChat na tela de login)
COPY images/logo.svg /app/client/public/assets/logo.svg
COPY images/logo.svg /app/client/dist/assets/logo.svg

# Logo PNG disponível em /images/logo.png (usado pelo OPENID_IMAGE_URL)
COPY images/logo.png /app/client/public/images/logo.png

# Favicon customizado (substitui o favicon padrão do LibreChat)
COPY logo.ico /app/client/public/favicon.ico
COPY logo.ico /app/client/dist/favicon.ico

# Custom CSS (tema AltoQi Axis)
COPY custom.css /app/client/dist/assets/custom.css
COPY custom.css /app/client/public/assets/custom.css

# Gerar favicon PNGs (32x32, 16x16, 180x180) a partir do logo.png usando sharp
COPY images/logo.png /tmp/logo-src.png
RUN node -e " \
const sharp = require('sharp'); \
const tasks = [ \
  [32, '/app/client/public/assets/favicon-32x32.png'], \
  [32, '/app/client/dist/assets/favicon-32x32.png'], \
  [16, '/app/client/public/assets/favicon-16x16.png'], \
  [16, '/app/client/dist/assets/favicon-16x16.png'], \
  [180, '/app/client/public/assets/apple-touch-icon-180x180.png'], \
  [180, '/app/client/dist/assets/apple-touch-icon-180x180.png'], \
]; \
Promise.all(tasks.map(([s,d]) => sharp('/tmp/logo-src.png').resize(s,s).png().toFile(d).then(() => console.log('Generated',d,s+'x'+s)))) \
  .then(() => console.log('[favicon] all PNGs generated')) \
  .catch(e => { console.error('[favicon] error:', e.message); process.exit(1); }); \
"

# Injeta o link do custom.css no index.html
# Injeta script para definir Enter = quebra de linha (não enviar) como default
RUN sed -i 's|</head>|<link rel="stylesheet" href="/assets/custom.css" /></head>|g' /app/client/dist/index.html && \
    sed -i 's|</head>|<link rel="stylesheet" href="/assets/custom.css" /></head>|g' /app/client/public/index.html 2>/dev/null || true && \
    sed -i 's|</head>|<script>if(!localStorage.getItem("enterToSend")){localStorage.setItem("enterToSend","false")}</script></head>|g' /app/client/dist/index.html && \
    sed -i 's|</head>|<script>if(!localStorage.getItem("enterToSend")){localStorage.setItem("enterToSend","false")}</script></head>|g' /app/client/public/index.html 2>/dev/null || true

# Patch: permite que o LibreChat salve os tokens OIDC mesmo quando o IdP
# (Keycloak AltoQi) não retorna refresh_token. Sem este patch o MCP visuscost
# nunca recebe LIBRECHAT_OPENID_ACCESS_TOKEN.
COPY patches/auth-service.patch.sh /tmp/auth-service.patch.sh
RUN sh /tmp/auth-service.patch.sh
