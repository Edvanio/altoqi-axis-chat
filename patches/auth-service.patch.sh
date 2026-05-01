#!/bin/sh
# Workaround: permite salvar tokens OIDC mesmo quando o IdP não devolve refresh_token.
# O LibreChat (v0.8.x) aborta setOpenIDAuthTokens quando refresh_token vem vazio,
# o que impede o MCP de obter o access_token via {{LIBRECHAT_OPENID_ACCESS_TOKEN}}.
#
# Este patch:
#   1. Remove o `return` precoce quando refresh_token está ausente.
#   2. Substitui por um warning + continuação do fluxo (refreshToken = '' aceitável).

set -e

FILE=/app/api/server/services/AuthService.js

if [ ! -f "$FILE" ]; then
  echo "[patch] $FILE não encontrado — pulando"
  exit 0
fi

if grep -q "PATCH_NO_REFRESH_TOKEN_OK" "$FILE"; then
  echo "[patch] já aplicado"
  exit 0
fi

# Substitui o bloco de erro por warning sem interromper
node -e "
const fs=require('fs');
const f='$FILE';
let s=fs.readFileSync(f,'utf8');
const before=\`    if (!refreshToken) {
      logger.error('[setOpenIDAuthTokens] No refresh token available');
      return;
    }\`;
const after=\`    if (!refreshToken) {
      logger.warn('[setOpenIDAuthTokens] No refresh token available, continuing without it (PATCH_NO_REFRESH_TOKEN_OK)');
    }\`;
if(!s.includes(before)){console.error('[patch] bloco original não encontrado');process.exit(1);}
s=s.replace(before,after);
fs.writeFileSync(f,s);
console.log('[patch] aplicado em',f);
"

# -------------------------------------------------------------------
# Patch 2: Debug log nos headers resolvidos do MCP (bundle compilado)
# -------------------------------------------------------------------
BUNDLE=/app/packages/api/dist/index.js
if [ -f "$BUNDLE" ] && ! grep -q "PATCH_DEBUG_HEADERS" "$BUNDLE"; then
  node -e "
const fs=require('fs');
const f='$BUNDLE';
let s=fs.readFileSync(f,'utf8');

// Patch 2a: MCPConnectionFactory constructor — log resolved headers
const anchor2='this.serverName = basic.serverName;';
const inject2=anchor2 + \`
        // PATCH_DEBUG_HEADERS
        if (this.serverConfig && this.serverConfig.headers) {
          var _h = this.serverConfig.headers;
          var _authH = _h['Authorization'] || _h['authorization'] || '';
          var _hasPH = _authH.includes('LIBRECHAT_OPENID');
          var _masked = _authH.length > 20 ? _authH.slice(0, 20) + '...[' + _authH.length + ' chars]' : _authH;
          var _uFed = options && options.user ? options.user.federatedTokens : null;
          console.log('[PATCH_DEBUG_HEADERS] server=' + basic.serverName + ' authHeader=' + _masked + ' placeholder=' + _hasPH + ' hasFederatedTokens=' + !!_uFed + ' hasAccessToken=' + !!(_uFed && _uFed.access_token));
        }\`;
if(!s.includes(anchor2)){console.error('[patch2a] anchor not found');process.exit(0);}
s=s.replace(anchor2, inject2);

// Patch 2b: SSE transport — log actual headers sent
const anchor3='/** Add OAuth token to headers if available */';
const inject3=anchor3 + \`
                        // PATCH_DEBUG_SSE_HEADERS
                        var _hCheck = Object.assign({}, options.headers);
                        var _aDbg = _hCheck['Authorization'] || _hCheck['authorization'] || '';
                        var _pCheck = _aDbg.includes('LIBRECHAT_OPENID');
                        var _msk = _aDbg.length > 20 ? _aDbg.slice(0, 20) + '...[' + _aDbg.length + ' chars]' : _aDbg;
                        console.log('[PATCH_DEBUG_SSE] url=' + options.url + ' authHeader=' + _msk + ' placeholder=' + _pCheck);\`;
if(!s.includes(anchor3)){console.error('[patch2b] anchor not found');}
else { s=s.replace(anchor3, inject3); }

fs.writeFileSync(f,s);
console.log('[patch2] debug headers applied to bundle');
"
else
  echo "[patch2] already applied or file not found"
fi

# -------------------------------------------------------------------
# Patch 3 (FIX): Populate user.federatedTokens from session in MCP
#   reinitialize route. The JWT strategy loads user from DB which does
#   NOT have federatedTokens. The openIdJwtStrategy populates them
#   from req.session.openidTokens but only during login flow.
#   The MCP reinitialize endpoint needs them for {{LIBRECHAT_OPENID_ACCESS_TOKEN}}.
# -------------------------------------------------------------------
MCP_ROUTE=/app/api/server/routes/mcp.js
if [ -f "$MCP_ROUTE" ] && ! grep -q "PATCH_FEDERATED_FROM_SESSION" "$MCP_ROUTE"; then
  node -e "
const fs=require('fs');
const f='$MCP_ROUTE';
let s=fs.readFileSync(f,'utf8');
const anchor='const user = createSafeUser(req.user);';
const replacement=\`// PATCH_FEDERATED_FROM_SESSION — populate federatedTokens from session
      // The JWT strategy loads user from DB without federatedTokens.
      // We need to read them from the session (set during OIDC login).
      if (req.user && !req.user.federatedTokens && req.session && req.session.openidTokens) {
        const st = req.session.openidTokens;
        req.user.federatedTokens = {
          access_token: st.accessToken,
          id_token: st.idToken,
          refresh_token: st.refreshToken,
          expires_at: st.expiresAt ? Math.floor(st.expiresAt / 1000) : undefined,
        };
        console.log('[PATCH_FEDERATED_FROM_SESSION] Populated federatedTokens from session for user ' + req.user.id + ' hasAccessToken=' + !!st.accessToken);
      } else if (req.user && !req.user.federatedTokens) {
        // Fallback: try cookies
        const cookieHeader = req.headers.cookie;
        if (cookieHeader) {
          const cookies = {};
          cookieHeader.split(';').forEach(function(c) {
            var parts = c.trim().split('=');
            cookies[parts[0]] = decodeURIComponent(parts.slice(1).join('='));
          });
          if (cookies.openid_access_token) {
            req.user.federatedTokens = {
              access_token: cookies.openid_access_token,
              id_token: cookies.openid_id_token,
              refresh_token: cookies.refreshToken,
            };
            console.log('[PATCH_FEDERATED_FROM_SESSION] Populated federatedTokens from cookies for user ' + req.user.id);
          } else {
            console.log('[PATCH_FEDERATED_FROM_SESSION] No session or cookie tokens found for user ' + (req.user.id || 'unknown'));
          }
        }
      }
      const user = createSafeUser(req.user);\`;
if(!s.includes(anchor)){console.error('[patch3] anchor not found');process.exit(1);}
s=s.replace(anchor, replacement);
fs.writeFileSync(f,s);
console.log('[patch3] federatedTokens from session applied to', f);
"
else
  echo "[patch3] already applied or file not found"
fi

# -------------------------------------------------------------------
# Patch 4 (FIX): Fix SSE EventSource fetch losing Accept header.
#   The SSEClientTransport's _startOrAuth sets Accept: text/event-stream
#   on a Headers object, but LibreChat's eventSourceInit.fetch uses
#   Object.assign({}, SSE_REQUEST_HEADERS, init?.headers, headers)
#   which does NOT copy from a Headers instance (no own enumerable props).
#   This causes the server to return 400 "Expected SSE with Accept".
#   Fix: convert init.headers from Headers to plain object before merge.
# -------------------------------------------------------------------
BUNDLE=/app/packages/api/dist/index.js
if [ -f "$BUNDLE" ] && ! grep -q "PATCH_FIX_SSE_ACCEPT" "$BUNDLE"; then
  node -e '
const fs=require("fs");
const f="/app/packages/api/dist/index.js";
let s=fs.readFileSync(f,"utf8");

// Replace the line that loses Headers properties via Object.assign
const old="const fetchHeaders = new Headers(Object.assign({}, SSE_REQUEST_HEADERS, init === null || init === void 0 ? void 0 : init.headers, headers));";
const nw="/* PATCH_FIX_SSE_ACCEPT */ var _initH = {}; if (init && init.headers && typeof init.headers.forEach === \"function\") { init.headers.forEach(function(v, k) { _initH[k] = v; }); } else if (init && init.headers) { _initH = init.headers; } const fetchHeaders = new Headers(Object.assign({}, SSE_REQUEST_HEADERS, _initH, headers));";
if(!s.includes(old)){console.error("[patch4] anchor not found");process.exit(0);}
s=s.replace(old, nw);
fs.writeFileSync(f,s);
console.log("[patch4] SSE Accept header fix applied");
'
else
  echo "[patch4] already applied or file not found"
fi

# Patches 5 e 6 removidos: MCP server agora usa '-' em vez de '.' nos nomes das tools.
# Ex: project.get_models -> project-get_models (compatível com ^[a-zA-Z0-9_-]+$)

# -------------------------------------------------------------------
# Patch 8 (FIX): Handle invalid_session by forcing fresh reconnection
#   When SSE drops, the MCP server discards the session. LibreChat tries
#   to reconnect but gets "invalid_session" repeatedly, triggering the
#   circuit breaker. This patch:
#   1. Detects invalid_session in the error handler
#   2. Adds a longer delay before reconnecting (give server time to cleanup)
#   3. Resets the circuit breaker so a fresh attempt can succeed
#   4. Increases MAX_RECONNECT_ATTEMPTS for invalid_session cases
# -------------------------------------------------------------------
BUNDLE=/app/packages/api/dist/index.js
if [ -f "$BUNDLE" ] && ! grep -q "PATCH_INVALID_SESSION_RECOVERY" "$BUNDLE"; then
  node -e '
const fs = require("fs");
const f = "/app/packages/api/dist/index.js";
let s = fs.readFileSync(f, "utf8");

// Patch 8a: In handleReconnection, detect invalid_session and add longer delay
const oldReconnLoop = "yield this.connect();\n                        this.reconnectAttempts = 0;\n                        return;";
const newReconnLoop = "/* PATCH_INVALID_SESSION_RECOVERY */ yield this.connect();\n                        this.reconnectAttempts = 0;\n                        return;";
if (s.includes(oldReconnLoop)) {
  s = s.replace(oldReconnLoop, newReconnLoop);
  console.log("[patch8a] reconnect marker applied");
}

// Patch 8b: In the catch block of handleReconnection, detect invalid_session
// and reset circuit breaker + add extra delay
const oldCatch = "dataSchemas.logger.error(`${this.getLogPrefix()} Reconnection attempt failed:`, error);";
const newCatch = "dataSchemas.logger.error(`${this.getLogPrefix()} Reconnection attempt failed:`, error);\n                        /* PATCH_INVALID_SESSION_RECOVERY */\n                        var _errMsg = error && error.message ? error.message : String(error);\n                        if (_errMsg.indexOf(\"invalid_session\") !== -1) {\n                            dataSchemas.logger.info(this.getLogPrefix() + \" invalid_session detected, clearing circuit breaker and waiting 8s before fresh reconnect\");\n                            MCPConnection.clearCooldown(this.serverName);\n                            yield new Promise(function(r) { setTimeout(r, 8000); });\n                        }";
if (s.includes(oldCatch)) {
  // Only replace the first occurrence (inside handleReconnection)
  s = s.replace(oldCatch, newCatch);
  console.log("[patch8b] invalid_session handler applied");
} else {
  console.error("[patch8b] anchor not found");
}

// Patch 8c: In extractSSEErrorMessage, classify invalid_session as transient
// so the error handler does not mark it as "manual intervention required"
const oldReturn400 = "const isServerError = statusCode >= 500 && statusCode < 600;";
const newReturn400 = "var _isInvalidSession = rawMessage.indexOf(\"invalid_session\") !== -1;\n        const isServerError = (statusCode >= 500 && statusCode < 600) || _isInvalidSession; /* PATCH_INVALID_SESSION_RECOVERY: treat invalid_session as transient */";
if (s.includes(oldReturn400)) {
  s = s.replace(oldReturn400, newReturn400);
  console.log("[patch8c] invalid_session classified as transient");
} else {
  console.error("[patch8c] anchor not found");
}

fs.writeFileSync(f, s);
console.log("[patch8] invalid_session recovery applied to bundle");
'
else
  echo "[patch8] already applied or file not found"
fi

# -------------------------------------------------------------------
# Patch 7: Inject favicon.ico link and fix title in HTML
# -------------------------------------------------------------------
HTML_DIST=/app/client/dist/index.html
HTML_PUB=/app/client/public/index.html
for HTML in "$HTML_DIST" "$HTML_PUB"; do
  if [ -f "$HTML" ] && ! grep -q 'favicon.ico' "$HTML"; then
    sed -i 's|<link rel="icon" type="image/png" sizes="32x32"|<link rel="icon" type="image/x-icon" href="favicon.ico" />\n    <link rel="icon" type="image/png" sizes="32x32"|' "$HTML"
    sed -i 's|<title>LibreChat</title>|<title>Axis</title>|' "$HTML"
    echo "[patch7] favicon.ico + title applied to $HTML"
  fi
done
