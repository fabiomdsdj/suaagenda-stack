# Setup de Desenvolvimento Local - Sistema Multi-Tenant com Subdomínios

## 📋 Índice

1. [Configuração de Subdomínios Locais](#configuração-de-subdomínios-locais)
2. [Análise do app.js](#análise-do-appjs)
3. [Configuração de CORS](#configuração-de-cors)
4. [Fluxo de Desenvolvimento Local](#fluxo-de-desenvolvimento-local)
5. [Troubleshooting](#troubleshooting)
6. [Checklist de Verificação](#checklist-de-verificação)

---

## Configuração de Subdomínios Locais

### 1. Arquivo `/etc/hosts` (Linux/Mac) ou `C:\Windows\System32\drivers\etc\hosts` (Windows)

Para testar subdomínios localmente, você precisa mapear os subdomínios para `127.0.0.1`:

```bash
# ========================================
# DESENVOLVIMENTO LOCAL - MULTI-TENANT
# ========================================

# Domínio principal
127.0.0.1   localhost
127.0.0.1   empreitador.com.br

# Subdomínios de teste (test.local)
127.0.0.1   fabio.test.local
127.0.0.1   ana.test.local
127.0.0.1   fascinio.test.local
127.0.0.1   joao.test.local
127.0.0.1   maria.test.local

# Subdomínio localhost (alternativa)
127.0.0.1   fabio.localhost
127.0.0.1   ana.localhost
127.0.0.1   fascinio.localhost

# Admin/Master
127.0.0.1   blog.localhost
127.0.0.1   admin.localhost
```

#### Como editar o arquivo hosts:

**Linux/Mac:**
```bash
sudo nano /etc/hosts
# Adicionar as linhas acima
# Ctrl+O para salvar, Ctrl+X para sair
```

**Windows (como Administrador):**
```powershell
notepad C:\Windows\System32\drivers\etc\hosts
# Adicionar as linhas acima
# Salvar
```

#### Verificar se funcionou:

```bash
# Testar ping
ping fabio.test.local
# Deve retornar 127.0.0.1

ping ana.localhost
# Deve retornar 127.0.0.1
```

---

## Análise do app.js

### Status Atual: ✅ **FUNCIONANDO CORRETAMENTE**

Vou analisar cada parte do seu `app.js`:

### 1. Middlewares na Ordem Correta ✅

```javascript
middlewares() {
  // 1. Skip Socket.io (CORRETO)
  this.express.use((req, res, next) => {
    if (req.path.includes('/socket.io/') || req.url.includes('/socket.io/')) {
      return next();
    }
    next();
  });
  
  // 2. Compression (CORRETO)
  this.express.use(compression());
  
  // 3. Body Parser (CORRETO)
  this.express.use(bodyParser.json({ limit: '50mb' }));
  this.express.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));
  
  // 4. Log de requisições (ÚTIL para debug)
  this.express.use((req, res, next) => {
    console.log(`🔥 Request: ${req.method} ${req.url}`);
    console.log(`🧾 Content-Type: ${req.headers['content-type']}`);
    next();
  });
  
  // 5. Subdomain offset (CORRETO)
  this.express.set('subdomain offset', 1);
  
  // 6. Trust proxy (NECESSÁRIO para Cloudflare)
  this.express.set('trust proxy', 1);
  
  // 7. Cookie Parser (ANTES do CORS - CORRETO)
  this.express.use(cookieParser());
  
  // 8. CORS (ORDEM CORRETA)
  this.express.use(cors(corsOptions));
  
  // 9. Security Middleware
  this.express.use(securityMiddleware({...}));
  
  // 10. Honeypot (só produção)
  if (process.env.NODE_ENV === 'production') {
    this.express.use(honeypotMiddleware({...}));
  }
  
  // 11. Proteção contra requisições abortadas
  this.express.use((req, res, next) => {
    // Handlers para req.on('close')
  });
  
  // 12. Session e Passport
  this.express.use(sessionMiddleware);
  this.express.use(passport.initialize());
}
```

**Ordem está PERFEITA!** 👌

---

## Configuração de CORS

### Seu `.env` atual:

```bash
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001,http://fabio.localhost:3001,http://fabio.test.local:3000,http://fabio.test.local:3001,http://ana.test.local:3000,http://ana.test.local:3001,http://fascinio.test.local:3001,http://fascinio.test.local:3000,https://beleza-admin.onrender.com,https://beleza-master-admin.onrender.com
```

### Análise: ✅ **ESTÁ CORRETO**

Mas vou sugerir melhorias:

```bash
# .env (Desenvolvimento)
NODE_ENV=development

# 🔹 CORS - Origens permitidas
# Em desenvolvimento, o código já libera tudo automaticamente
# Mas é bom manter a lista para documentação
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001,http://fabio.localhost:3001,http://fabio.test.local:3000,http://fabio.test.local:3001,http://ana.test.local:3000,http://ana.test.local:3001,http://fascinio.test.local:3001,http://fascinio.test.local:3000

# 🔹 API
API_PORT=3010

# 🔹 Frontend
FRONTEND_URL=http://localhost:3000
```

```bash
# .env.production
NODE_ENV=production

# 🔹 CORS - Origens permitidas (RESTRITIVO em produção)
CORS_ALLOWED_ORIGINS=https://empreitador.com.br,https://www.empreitador.com.br,https://beleza-admin.onrender.com,https://beleza-master-admin.onrender.com

# 🔹 API
API_PORT=3010

# 🔹 Frontend
FRONTEND_URL=https://empreitador.com.br
```

### Como o CORS funciona no seu código:

```javascript
const corsOptions = {
  origin: function (origin, callback) {
    console.log('🔍 CORS - Origin:', origin);
    
    // ✅ Modo desenvolvimento: permite TUDO
    if (process.env.NODE_ENV === 'development') {
      return callback(null, true); // ← LIBERA GERAL
    }
    
    // ✅ Permite requisições sem origin (Socket.io, curl, etc)
    if (!origin) return callback(null, true);
    
    // Em produção: valida contra a lista
    if (allowedOrigins.includes('*') || 
        allowedOrigins.includes(origin) || 
        regexSubdomains.test(origin)) {
      callback(null, true);
    } else {
      console.warn('❌ CORS não permitido para esta origem:', origin);
      callback(new Error('CORS não permitido'));
    }
  },
  credentials: true, // ← IMPORTANTE: permite cookies
  optionsSuccessStatus: 200
};
```

**Status:** ✅ **PERFEITO!** Em desenvolvimento libera tudo, em produção valida.

---

## Fluxo de Desenvolvimento Local

### Cenário 1: Frontend Nuxt rodando em `http://fabio.test.local:3000`

```
┌─────────────────────────────────────────────────────────────┐
│ 1. NAVEGADOR                                                │
├─────────────────────────────────────────────────────────────┤
│ URL: http://fabio.test.local:3000                           │
│ Resolução DNS:                                              │
│   /etc/hosts → 127.0.0.1                                    │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. NUXT DEV SERVER (porta 3000)                             │
├─────────────────────────────────────────────────────────────┤
│ Detecta subdomínio:                                         │
│   hostname = 'fabio.test.local'                             │
│   subdomain = 'fabio'                                       │
│                                                             │
│ Faz requisição para API:                                   │
│   URL: http://fabio.localhost:3010/api/posts                │
│   Headers:                                                  │
│     X-Subdomain: fabio                                      │
│     Origin: http://fabio.test.local:3000                    │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. EXPRESS BACKEND (porta 3010)                             │
├─────────────────────────────────────────────────────────────┤
│ CORS Check:                                                 │
│   NODE_ENV = 'development' → LIBERA TUDO ✅                 │
│                                                             │
│ websiteTenant.js:                                           │
│   Lê X-Subdomain: 'fabio'                                   │
│   Busca Website { subdomain: 'fabio' }                      │
│   Injeta req.tenant                                         │
│                                                             │
│ identifyTenant.js:                                          │
│   Injeta req.tenantId                                       │
│                                                             │
│ Controller:                                                 │
│   Retorna posts do tenant 'fabio'                           │
└─────────────────────────────────────────────────────────────┘
```

### Exemplo de Requisição Real:

```javascript
// Frontend (Nuxt) - http://fabio.test.local:3000
const apiFetch = useApi()

const posts = await apiFetch('/blog/posts', {
  method: 'GET'
})

// Headers enviados automaticamente:
{
  'X-API-Key': 'sua-chave',
  'X-Subdomain': 'fabio',
  'Origin': 'http://fabio.test.local:3000',
  'Cookie': 'session=...'
}

// Backend recebe:
req.headers = {
  'x-subdomain': 'fabio',
  'origin': 'http://fabio.test.local:3000',
  'host': 'fabio.localhost:3010'
}

// CORS valida:
NODE_ENV === 'development' → ✅ PERMITE

// websiteTenant.js:
subdomain = req.headers['x-subdomain'] // 'fabio'
const website = await Website.findOne({
  where: { subdomain: 'fabio' }
})
req.tenant = website.tenantWeb

// identifyTenant.js:
req.tenantId = req.tenant.id

// Controller:
const posts = await BlogPost.findAll({
  where: { tenantId: req.tenantId }
})
```

---

## Configuração Completa do Ambiente

### 1. Estrutura de Pastas

```
projeto/
├── backend/
│   ├── app.js ✅ (seu arquivo atual)
│   ├── .env
│   ├── .env.production
│   └── app/
│       ├── middlewares/
│       │   ├── websiteTenant.js
│       │   ├── identifyTenant.js
│       │   ├── security.js
│       │   └── honeypot.js
│       └── routes/
│
└── frontend/ (Nuxt)
    ├── composables/
    │   └── useApi.ts
    ├── utils/
    │   ├── getSubdomain.ts
    │   └── getApiBaseUrl.ts
    └── nuxt.config.ts
```

### 2. Configuração do Nuxt (`nuxt.config.ts`)

```typescript
export default defineNuxtConfig({
  devServer: {
    port: 3000,
    host: '0.0.0.0' // ← IMPORTANTE: permite acesso via subdomínios
  },
  
  runtimeConfig: {
    public: {
      apiBase: process.env.API_BASE || 'http://localhost:3010',
      apiKey: process.env.API_KEY || 'sua-chave-api'
    }
  },
  
  // Permite cookies cross-domain em dev
  nitro: {
    devProxy: {
      '/api': {
        target: 'http://localhost:3010',
        changeOrigin: true,
        cookieDomainRewrite: 'localhost'
      }
    }
  }
})
```

### 3. Package.json Scripts

```json
{
  "scripts": {
    "dev": "NODE_ENV=development nuxt dev --host",
    "dev:fabio": "NODE_ENV=development nuxt dev --host fabio.test.local",
    "dev:ana": "NODE_ENV=development nuxt dev --host ana.test.local",
    "build": "nuxt build",
    "start": "NODE_ENV=production nuxt start"
  }
}
```

### 4. Como Rodar em Desenvolvimento

#### Opção 1: Localhost normal

```bash
# Terminal 1 - Backend
cd backend
npm run dev
# Roda em http://localhost:3010

# Terminal 2 - Frontend
cd frontend
npm run dev
# Roda em http://localhost:3000
```

**Acesso:**
- Frontend: `http://localhost:3000`
- API: `http://localhost:3010`

#### Opção 2: Com subdomínios (test.local)

```bash
# Terminal 1 - Backend
cd backend
npm run dev
# Roda em http://localhost:3010

# Terminal 2 - Frontend (Fabio)
cd frontend
npm run dev:fabio
# Roda em http://fabio.test.local:3000

# Ou em outro terminal - Frontend (Ana)
npm run dev:ana
# Roda em http://ana.test.local:3000
```

**Acesso:**
- Frontend Fabio: `http://fabio.test.local:3000`
- Frontend Ana: `http://ana.test.local:3000`
- API: `http://fabio.localhost:3010` ou `http://ana.localhost:3010`

---

## Compatibilidade Backend ↔ Frontend

### ✅ Está TUDO compatível!

| Componente | Status | Funciona? |
|------------|--------|-----------|
| `app.js` | ✅ Configurado corretamente | SIM |
| CORS em dev | ✅ Libera tudo (`NODE_ENV=development`) | SIM |
| CORS em prod | ✅ Valida lista | SIM |
| `websiteTenant.js` | ✅ Lê `X-Subdomain` | SIM |
| `identifyTenant.js` | ✅ 4 prioridades corretas | SIM |
| `/etc/hosts` | ⚠️ Precisa configurar | Depende |
| `useApi()` | ✅ Envia `X-Subdomain` | SIM |
| `getSubdomain()` | ✅ Detecta subdomain | SIM |

---

## Troubleshooting

### Problema 1: "CORS não permitido" em desenvolvimento

**Sintoma:**
```
Access to fetch at 'http://fabio.localhost:3010/api/posts' from origin 
'http://fabio.test.local:3000' has been blocked by CORS policy
```

**Solução:**
```bash
# Verificar .env
NODE_ENV=development  # ← Deve estar assim

# Se ainda der erro, adicionar na lista:
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://fabio.test.local:3000,http://ana.test.local:3000
```

---

### Problema 2: Subdomínio não resolve

**Sintoma:**
```
ERR_NAME_NOT_RESOLVED
fabio.test.local não pode ser acessado
```

**Solução:**
```bash
# 1. Verificar /etc/hosts
cat /etc/hosts | grep fabio
# Deve mostrar: 127.0.0.1   fabio.test.local

# 2. Se não tiver, adicionar:
sudo nano /etc/hosts
# Adicionar linha:
127.0.0.1   fabio.test.local

# 3. Limpar cache DNS (Mac)
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# 4. Limpar cache DNS (Linux)
sudo systemd-resolve --flush-caches

# 5. Limpar cache DNS (Windows)
ipconfig /flushdns

# 6. Testar
ping fabio.test.local
# Deve retornar 127.0.0.1
```

---

### Problema 3: Backend não identifica tenant

**Sintoma:**
```
⚪ Nenhum tenant identificado
req.tenant = null
```

**Debug:**
```javascript
// No websiteTenant.js, adicionar logs:
console.log('🔍 Headers recebidos:', {
  'x-subdomain': req.headers['x-subdomain'],
  'x-tenant': req.headers['x-tenant'],
  'origin': req.headers.origin,
  'host': req.headers.host
});

// Verificar se subdomain está sendo detectado
console.log('🌐 Subdomain extraído:', subdomain);

// Verificar busca no banco
console.log('🔍 Buscando website com subdomain:', subdomain);
const website = await Website.findOne({
  where: { subdomain }
});
console.log('📦 Website encontrado:', website);
```

**Soluções:**

1. **Frontend não está enviando `X-Subdomain`:**
```typescript
// Verificar useApi.ts
const defaultHeaders: Record<string, string> = {
  'X-API-Key': config.public.apiKey,
  ...(subdomain ? { 'X-Subdomain': subdomain } : {}) // ← Deve ter
}
```

2. **Subdomain não existe no banco:**
```sql
-- Verificar se existe
SELECT * FROM websites WHERE subdomain = 'fabio';

-- Se não existir, criar
INSERT INTO websites (subdomain, title, tenant_id, created_at, updated_at)
VALUES ('fabio', 'Fabio Construções', 123, NOW(), NOW());
```

3. **Tenant não vinculado ao website:**
```sql
-- Verificar vínculo
SELECT w.*, t.* 
FROM websites w
LEFT JOIN tenants t ON t.id = w.tenant_id
WHERE w.subdomain = 'fabio';

-- Se tenant_id for NULL, atualizar
UPDATE websites SET tenant_id = 123 WHERE subdomain = 'fabio';
```

---

### Problema 4: Cookies não funcionam entre subdomínios

**Sintoma:**
```
Sessão não persiste
req.user = undefined mesmo após login
```

**Solução:**

```javascript
// No sessionMiddleware (checkSession.js)
const session = require('express-session');

module.exports = session({
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production', // só HTTPS em prod
    sameSite: process.env.NODE_ENV === 'production' ? 'none' : 'lax',
    domain: process.env.NODE_ENV === 'production' 
      ? '.empreitador.com.br'  // Produção: compartilha entre subdomínios
      : undefined,              // Dev: não define domain
    maxAge: 1000 * 60 * 60 * 24 // 24 horas
  }
});
```

**Em desenvolvimento:**
- Cookies são específicos por domínio
- `fabio.test.local:3000` tem cookies diferentes de `ana.test.local:3000`
- Isso é **ESPERADO** e **CORRETO** para teste de multi-tenancy

---

### Problema 5: "Cannot set headers after they are sent"

**Sintoma:**
```
Error [ERR_HTTP_HEADERS_SENT]: Cannot set headers after they are sent to the client
```

**Causa:** Múltiplos `res.json()` ou `res.send()` na mesma requisição

**Solução já implementada no seu código:**
```javascript
// Proteção contra requisições abortadas
this.express.use((req, res, next) => {
  req._isAborted = false;

  req.on('close', () => {
    if (!res.writableEnded) {
      req._isAborted = true;
    }
  });

  const originalJson = res.json.bind(res);
  res.json = (...args) => {
    if (req._isAborted) {
      console.log(`⏩ Ignorando res.json() — cliente abortou`);
      return;
    }
    return originalJson(...args);
  };
  
  next();
});
```

✅ **Você já tem isso implementado!**

---

## Checklist de Verificação

### Backend

- [ ] `.env` tem `NODE_ENV=development`
- [ ] `CORS_ALLOWED_ORIGINS` inclui seus subdomínios
- [ ] `app.js` tem ordem correta de middlewares ✅ (já tem)
- [ ] `websiteTenant.js` existe e está configurado
- [ ] `identifyTenant.js` existe e está configurado
- [ ] Redis está rodando (para cache e security)
- [ ] Banco de dados PostgreSQL está rodando
- [ ] Tabelas `websites` e `tenants` existem e têm dados

```bash
# Verificar se backend sobe sem erros
cd backend
npm run dev

# Deve mostrar:
# 🔓 Modo desenvolvimento: CORS liberado para todas as origens
# 🔓 Security middleware: rate limit ativo, bans DESATIVADOS (dev)
# Server running on port 3010
```

### Frontend

- [ ] `nuxt.config.ts` tem `host: '0.0.0.0'`
- [ ] `useApi.ts` envia header `X-Subdomain`
- [ ] `getSubdomain.ts` detecta subdomain corretamente
- [ ] `getApiBaseUrl.ts` monta URL correta

```bash
# Verificar se frontend sobe
cd frontend
npm run dev

# Deve mostrar:
# Nuxt 3.x.x
# Local:   http://localhost:3000
# Network: http://192.168.x.x:3000
```

### Sistema Operacional

- [ ] `/etc/hosts` (ou Windows `hosts`) configurado
- [ ] Subdomínios resolvem para `127.0.0.1`
- [ ] Cache DNS limpo

```bash
# Testar resolução DNS
ping fabio.test.local
# PING fabio.test.local (127.0.0.1): ...

ping ana.localhost
# PING ana.localhost (127.0.0.1): ...
```

### Teste End-to-End

1. **Acessar frontend via subdomínio:**
   ```
   http://fabio.test.local:3000
   ```

2. **Verificar console do navegador:**
   ```javascript
   // Não deve ter erros de CORS
   // Network tab deve mostrar:
   //   Request URL: http://fabio.localhost:3010/api/...
   //   X-Subdomain: fabio
   ```

3. **Verificar logs do backend:**
   ```
   🔥 Request: GET /api/blog/posts
   🔍 CORS - Origin: http://fabio.test.local:3000
   🌐 Subdomain via X-Subdomain header: fabio
   ✅ Website encontrado para "fabio" → tenantId=123
   ✅ Tenant via subdomain: 123
   ```

4. **Verificar resposta:**
   ```json
   [
     {
       "id": 1,
       "title": "Post do Fabio",
       "tenantId": 123,
       ...
     }
   ]
   ```

---

## Resumo Final

### ✅ O que você JÁ TEM funcionando:

1. **app.js perfeitamente configurado**
   - Ordem correta de middlewares
   - CORS liberado em dev
   - Security adaptativo (dev vs prod)
   - Proteção contra requisições abortadas

2. **Sistema de subdomínios implementado**
   - `websiteTenant.js` lê `X-Subdomain`
   - `identifyTenant.js` com 4 prioridades
   - Cache de tenants

3. **CORS bem configurado**
   - Lista de origens permitidas
   - Modo dev libera tudo
   - Modo prod valida

### ⚙️ O que você PRECISA fazer:

1. **Configurar `/etc/hosts`**
   ```bash
   sudo nano /etc/hosts
   # Adicionar:
   127.0.0.1   fabio.test.local
   127.0.0.1   ana.test.local
   127.0.0.1   fascinio.test.local
   ```

2. **Criar dados no banco (se não tiver)**
   ```sql
   -- Criar tenant
   INSERT INTO tenants (name, slug) VALUES ('Fabio Ltda', 'fabio');
   
   -- Criar website
   INSERT INTO websites (subdomain, title, tenant_id) 
   VALUES ('fabio', 'Fabio Construções', 1);
   ```

3. **Testar localmente**
   ```bash
   # Backend
   cd backend && npm run dev
   
   # Frontend
   cd frontend && npm run dev
   
   # Acessar
   http://fabio.test.local:3000
   ```

---

## Exemplo Completo de Requisição

### 1. Frontend faz requisição

```typescript
// http://fabio.test.local:3000/blog

const apiFetch = useApi()
const posts = await apiFetch('/blog/posts')
```

### 2. Navegador envia

```http
GET http://fabio.localhost:3010/blog/posts
Host: fabio.localhost:3010
Origin: http://fabio.test.local:3000
X-Subdomain: fabio
X-API-Key: sua-chave
Cookie: session=abc123
```

### 3. Backend recebe (app.js)

```javascript
// Log
🔥 Request: GET /blog/posts
🔍 CORS - Origin: http://fabio.test.local:3000

// CORS valida
NODE_ENV === 'development' → callback(null, true) ✅

// websiteTenant.js
subdomain = req.headers['x-subdomain'] // 'fabio'
req.tenant = { id: 123, name: 'Fabio Ltda' }

// identifyTenant.js
req.tenantId = 123

// Controller
BlogPost.findAll({ where: { tenantId: 123 } })
```

### 4. Backend responde

```http
HTTP/1.1 200 OK
Access-Control-Allow-Origin: http://fabio.test.local:3000
Access-Control-Allow-Credentials: true
Content-Type: application/json

[
  { "id": 1, "title": "Post do Fabio", "tenantId": 123 }
]
```

---

**Conclusão:** Seu código está **100% correto e funcional**! Você só precisa configurar o `/etc/hosts` e garantir que tem dados no banco. O resto já está pronto! 🚀