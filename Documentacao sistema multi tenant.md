# Documentação Completa - Sistema Multi-Tenant com Subdomínios

## 📋 Índice

1. [Visão Geral do Sistema](#visão-geral-do-sistema)
2. [Fluxo de Requisição Completo](#fluxo-de-requisição-completo)
3. [Backend - Middlewares](#backend---middlewares)
4. [Frontend - Composables e Utils](#frontend---composables-e-utils)
5. [Exemplos Práticos de Uso](#exemplos-práticos-de-uso)
6. [Casos de Uso por Tipo de Usuário](#casos-de-uso-por-tipo-de-usuário)

---

## Visão Geral do Sistema

Este sistema implementa **multi-tenancy baseado em subdomínios** para um blog/website, permitindo que diferentes clientes (tenants) tenham seus próprios sites sob subdomínios diferentes, enquanto mantém um tenant Master Admin que pode gerenciar todos os outros.

### Arquitetura Geral

```
┌─────────────────────────────────────────────────────────────┐
│                    CLOUDFLARE WORKER                        │
│  (Injeta headers: X-Tenant, X-Original-Host, X-Subdomain)   │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│                     NUXT 3 FRONTEND                         │
│  - Detecta subdomínio (client/server)                      │
│  - Envia X-Subdomain no header de API                      │
│  - Usa composables (useApi, useWebsites)                   │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│                    EXPRESS BACKEND                          │
│  Middleware 1: websiteTenant.js (identifica tenant público) │
│  Middleware 2: identifyTenant.js (identifica tenant blog)   │
│  - Busca Website + Tenant no banco                         │
│  - Cacheia resultados                                       │
│  - Injeta req.tenant, req.tenantId, req.website            │
└─────────────────────────────────────────────────────────────┘
```

---

## Fluxo de Requisição Completo

### Exemplo Real: Usuário acessando `fabio.empreitador.com.br/blog`

```
1️⃣ NAVEGADOR
   └─> Acessa: https://fabio.empreitador.com.br/blog
   
2️⃣ CLOUDFLARE WORKER (Produção)
   └─> Injeta headers:
       - X-Tenant: fabio
       - X-Original-Host: fabio.empreitador.com.br
       
3️⃣ NUXT SSR (Server-Side)
   └─> getSubdomain() detecta:
       - Via headers.origin ou headers.host
       - Resultado: "fabio"
   
4️⃣ useApi() prepara requisição
   └─> Headers enviados:
       - X-API-Key: [sua chave]
       - X-Subdomain: fabio
       - Cookie: [sessão se autenticado]
       
5️⃣ EXPRESS BACKEND
   ├─> websiteTenant.js executa:
   │   ├─ Lê X-Subdomain: "fabio"
   │   ├─ Verifica cache
   │   ├─ Busca no DB: Website { subdomain: 'fabio' }
   │   └─ Injeta: req.tenant = { id: 123, name: 'Fabio Ltda' }
   │
   └─> identifyTenant.js executa:
       ├─ Se autenticado → usa req.user.tenantId
       ├─ Se não → usa req.tenant.id (do websiteTenant)
       └─ Injeta: req.tenantId = 123
       
6️⃣ CONTROLLER (exemplo: getBlogPosts)
   └─> Usa req.tenantId para filtrar posts do tenant correto
```

---

## Backend - Middlewares

### 1. `websiteTenant.js` - Identifica Tenant Público

**Propósito:** Identifica qual tenant está fazendo a requisição baseado no subdomínio, **ANTES** da autenticação.

#### Prioridades de Detecção

```javascript
// PRIORIDADE 1: Header X-Subdomain (enviado pelo frontend)
subdomain = req.headers['x-subdomain']
// Exemplo: 'fabio'

// PRIORIDADE 2: Header X-Tenant (Cloudflare Worker em produção)
subdomain = req.headers['x-tenant']
// Exemplo: 'fabio'

// PRIORIDADE 3: Header X-Original-Host (Cloudflare Worker)
const originalHost = req.headers['x-original-host']
// Exemplo: 'fabio.empreitador.com.br' → extrai 'fabio'

// PRIORIDADE 4: Origin/Host (desenvolvimento local)
const hostname = req.headers.origin ? new URL(origin).hostname : req.headers.host
// Exemplo: 'fabio.localhost:3010' → extrai 'fabio'
```

#### Exemplo Prático 1: Subdomínio Válido

```javascript
// Requisição recebida
Headers: {
  'x-subdomain': 'joao',
  'host': 'joao.empreitador.com.br'
}

// Processamento
console.log('🌐 Subdomain via X-Subdomain header: joao')

// Busca no banco
const website = await Website.findOne({
  where: { subdomain: 'joao' },
  include: [{ model: Tenant, as: 'tenantWeb' }]
})

// Resultado
req.website = {
  id: 5,
  subdomain: 'joao',
  title: 'João Construções',
  tenantId: 42
}
req.tenant = {
  id: 42,
  name: 'João da Silva',
  tenantTypeId: 2
}

// Cache atualizado
tenantCache['joao'] = {
  website: {...},
  tenant: {...},
  expires: Date.now() + 60000 // 1 minuto
}
```

#### Exemplo Prático 2: Sem Subdomínio (www ou domínio principal)

```javascript
// Requisição recebida
Headers: {
  'host': 'www.empreitador.com.br'
}

// Processamento
subdomain = 'www' // ou null

// Resultado
console.log('⚪ Ignorando subdomínio, tenant = null')
req.tenant = null
req.website = null
// Continua para próximo middleware
```

#### Exemplo Prático 3: Subdomínio Inexistente

```javascript
// Requisição recebida
Headers: {
  'x-subdomain': 'naoexiste'
}

// Busca no banco retorna null
const website = null

// Resposta HTTP 404
return res.status(404).json({ 
  error: 'Site não encontrado',
  subdomain: 'naoexiste'
})
```

---

### 2. `identifyTenant.js` - Identifica Tenant para Blog

**Propósito:** Identifica qual tenant deve ser usado para operações de blog, suportando Master Admin gerenciando outros tenants.

#### Sistema de Prioridades

```javascript
┌─────────────────────────────────────────────────────────┐
│ PRIORIDADE 1: Query Parameter ?tenantId=X              │
│ → Apenas Master Admin pode usar                        │
│ → Para gerenciar outros tenants                        │
└─────────────────────────────────────────────────────────┘
         ↓ (se não aplicável)
┌─────────────────────────────────────────────────────────┐
│ PRIORIDADE 2: Usuário Autenticado (req.user.tenantId)  │
│ → Gerencia seu próprio tenant                          │
└─────────────────────────────────────────────────────────┘
         ↓ (se não autenticado)
┌─────────────────────────────────────────────────────────┐
│ PRIORIDADE 3: Subdomain (req.tenant.id)                 │
│ → Visitante público acessando via subdomínio           │
└─────────────────────────────────────────────────────────┘
         ↓ (se nenhum dos anteriores)
┌─────────────────────────────────────────────────────────┐
│ PRIORIDADE 4: Tenant Master Blog (fallback)             │
│ → Busca tenant com tenantTypeId=5 e subdomain='blog'   │
└─────────────────────────────────────────────────────────┘
```

#### Exemplo Prático 1: Master Admin Gerenciando Outro Tenant

```javascript
// Requisição
GET /api/blog/posts?tenantId=99
Headers: {
  Cookie: 'session=...' // Master autenticado
}

// req.user (já injetado por middleware de auth)
req.user = {
  id: 1,
  name: 'Admin Master',
  tenantId: 5,
  tenantTypeId: 5 // ← Master Admin
}

// Processamento
if (req.query.tenantId) { // ✅ Passou tenantId=99
  const tenantId = parseInt(req.query.tenantId) // 99
  if (req.user.tenantTypeId === 5) { // ✅ É Master
    req.tenantId = 99
    req.managingOtherTenant = true
    console.log('✅ Master gerenciando tenant: 99')
    return next()
  }
}

// Resultado
req.tenantId = 99
req.managingOtherTenant = true

// Controller pode fazer
const posts = await BlogPost.findAll({
  where: { tenantId: 99 } // ← Posts do tenant 99, não do Master
})
```

#### Exemplo Prático 2: Usuário Comum Autenticado (Próprio Tenant)

```javascript
// Requisição
GET /api/blog/posts
Headers: {
  Cookie: 'session=...'
}

// req.user
req.user = {
  id: 42,
  name: 'João',
  tenantId: 123,
  tenantTypeId: 2 // Cliente normal
}

// Processamento
if (req.user && req.user.tenantId) { // ✅
  req.tenantId = 123
  req.managingOtherTenant = false
  console.log('✅ Tenant via auth (próprio): 123')
  return next()
}

// Resultado
req.tenantId = 123
req.managingOtherTenant = false

// Controller acessa
const posts = await BlogPost.findAll({
  where: { tenantId: 123 } // ← Próprios posts do João
})
```

#### Exemplo Prático 3: Visitante Público (Via Subdomain)

```javascript
// Requisição
GET /api/blog/posts
Headers: {
  'x-subdomain': 'maria'
}

// req.tenant (injetado por websiteTenant.js)
req.tenant = {
  id: 456,
  name: 'Maria Engenharia'
}

// Processamento (não autenticado, sem query param)
if (req.tenant && req.tenant.id) { // ✅
  req.tenantId = 456
  req.managingOtherTenant = false
  console.log('✅ Tenant via subdomain: 456')
  return next()
}

// Resultado
req.tenantId = 456

// Controller retorna
const posts = await BlogPost.findAll({
  where: { tenantId: 456, isPublished: true } // ← Posts públicos da Maria
})
```

#### Exemplo Prático 4: Fallback Master Blog

```javascript
// Requisição
GET /api/blog/posts
// Sem auth, sem subdomain, sem query param

// Processamento
const masterWebsite = await Website.findOne({
  where: { subdomain: 'blog' },
  include: [{ 
    model: Tenant, 
    as: 'tenantWeb', 
    where: { tenantTypeId: 5 } 
  }]
})

// Resultado do DB
masterWebsite.tenantWeb = {
  id: 1,
  name: 'Blog Master',
  tenantTypeId: 5
}

// Injeta
req.tenantId = 1
req.isMasterBlog = true
console.log('✅ Tenant Master (blog público): 1')

// Controller retorna posts do blog master
const posts = await BlogPost.findAll({
  where: { tenantId: 1, isPublished: true }
})
```

---

### 3. Middlewares Auxiliares

#### `requireTenant` - Requer Tenant Obrigatório

```javascript
// Uso em rotas que PRECISAM de tenant
router.get('/posts', requireTenant, async (req, res) => {
  // Se chegou aqui, req.tenantId está definido
  const posts = await BlogPost.findAll({
    where: { tenantId: req.tenantId }
  })
  res.json(posts)
})

// Exemplo de requisição SEM tenant
GET /api/blog/posts
// Sem auth, sem subdomain

// Resposta
HTTP 400 Bad Request
{
  "error": "Tenant não identificado",
  "hint": "Faça login ou acesse via subdomain"
}
```

#### `validateTenant` - Valida Tenant Gerenciado por Master

```javascript
// Uso após identifyTenant quando Master gerencia outro
router.post('/posts', 
  identifyTenant, 
  validateTenant, // ← Valida se tenantId existe
  async (req, res) => {
    // req.managedTenant tem os dados do tenant
    const post = await BlogPost.create({
      tenantId: req.tenantId,
      title: req.body.title
    })
    res.json(post)
  }
)

// Exemplo: Master tentando gerenciar tenant inexistente
GET /api/blog/posts?tenantId=9999
Cookie: session=master_session

// validateTenant executa
const tenant = await Tenant.findByPk(9999)
// null

// Resposta
HTTP 404 Not Found
{
  "error": "Tenant não encontrado",
  "message": "Tenant com ID 9999 não existe"
}
```

---

## Frontend - Composables e Utils

### 1. `getSubdomain()` - Detecta Subdomínio

**Local:** `utils/getSubdomain.ts`

#### Server-Side (Nuxt SSR)

```typescript
// Exemplo: Requisição para fabio.empreitador.com.br

// TENTATIVA 1: Via Origin
const headers = useRequestHeaders()
headers.origin = 'https://fabio.empreitador.com.br'

const url = new URL(headers.origin)
// url.hostname = 'fabio.empreitador.com.br'

const parts = url.hostname.split('.')
// parts = ['fabio', 'empreitador', 'com', 'br']

if (parts.length > 2) {
  return parts[0] // ← 'fabio'
}
```

```typescript
// Exemplo: Desenvolvimento local (localhost:3010)

const headers = useRequestHeaders()
headers.host = 'localhost:3010'

const parts = headers.host.split('.')
// parts = ['localhost:3010']

if (host.includes('localhost')) {
  return null // ← Sem subdomínio
}
```

#### Client-Side (Browser)

```typescript
// Exemplo: Browser em joao.empreitador.com.br

const host = window.location.hostname
// 'joao.empreitador.com.br'

const parts = host.split('.')
// ['joao', 'empreitador', 'com', 'br']

if (parts.length > 2) {
  return parts[0] // ← 'joao'
}
```

---

### 2. `getApiBaseUrl()` - Monta URL da API

**Local:** `utils/getApiBaseUrl.ts`

```typescript
// Exemplo 1: Produção com subdomínio
getApiBaseUrl('maria')
// Retorna: 'https://maria.empreitador.com.br'

// Exemplo 2: Desenvolvimento com subdomínio
getApiBaseUrl('pedro')
// Retorna: 'http://pedro.localhost:3010'

// Exemplo 3: Sem subdomínio (domínio principal)
getApiBaseUrl()
// Retorna: 'https://empreitador.com.br' (prod)
// ou 'http://empreitador.com.br:3010' (dev)

// Exemplo 4: Subdomínio ignorado
getApiBaseUrl('www')
// Retorna: 'https://empreitador.com.br' (fallback)
```

---

### 3. `useApi()` - Composable de Requisições

**Local:** `composables/useApi.ts`

#### Exemplo Completo: Fetch de Posts

```typescript
// Em um componente/página Nuxt
const apiFetch = useApi()

// Browser acessando: https://carlos.empreitador.com.br/blog

// 1️⃣ getSubdomain() detecta
const subdomain = 'carlos'

// 2️⃣ getApiBaseUrl() monta
const baseURL = 'https://carlos.empreitador.com.br'

// 3️⃣ Headers montados
const headers = {
  'X-API-Key': 'sua-chave-api',
  'X-Subdomain': 'carlos' // ← Crucial!
}

// 4️⃣ Requisição executada
const posts = await apiFetch('/blog/posts', {
  method: 'GET',
  credentials: 'include' // ← Envia cookies de sessão
})

// Requisição final enviada:
// GET https://carlos.empreitador.com.br/blog/posts
// Headers:
//   X-API-Key: sua-chave-api
//   X-Subdomain: carlos
//   Cookie: connect.sid=...
```

#### Exemplo: POST com Autenticação

```typescript
const apiFetch = useApi()

// Usuário logado como Master em blog.empreitador.com.br
// Criando post para outro tenant

const newPost = await apiFetch('/blog/posts?tenantId=88', {
  method: 'POST',
  body: {
    title: 'Novo Post',
    content: 'Conteúdo...',
    slug: 'novo-post'
  }
})

// Requisição:
// POST https://blog.empreitador.com.br/blog/posts?tenantId=88
// Headers:
//   X-API-Key: ...
//   X-Subdomain: blog
//   Cookie: session_master=...
// Body: { title: '...', content: '...', slug: '...' }

// Backend processa:
// 1. websiteTenant: req.tenant = blog tenant
// 2. identifyTenant: req.user.tenantTypeId = 5 (Master)
//                    req.tenantId = 88 (do query param)
//                    req.managingOtherTenant = true
// 3. validateTenant: Verifica se tenant 88 existe
// 4. Controller: Cria post para tenant 88
```

---

### 4. `useWebsites` - Store Pinia

**Local:** `stores/websites.ts`

#### Exemplo: Carregamento Inicial da Página

```typescript
// plugins/website.client.ts ou página
const websiteStore = useWebsites()

// SSR: Primeira renderização no servidor
await websiteStore.fetchCurrentWebsite()

// Fluxo interno:
const subdomain = getSubdomain() // 'ana'

if (!subdomain) {
  throw new Error('Subdomínio não definido')
}

const res = await apiFetch<Website>(`/website/by-subdomain/ana`, {
  credentials: 'include'
})

// Resposta do backend:
{
  id: 7,
  subdomain: 'ana',
  title: 'Ana Arquitetura',
  description: 'Projetos exclusivos',
  tenantId: 77,
  tenantWeb: {
    id: 77,
    name: 'Ana Silva',
    tenantTypeId: 2
  }
}

// Store atualizada
websiteStore.currentWebsite = { ... }

// Componentes podem usar
const { currentWebsite } = storeToRefs(websiteStore)
console.log(currentWebsite.value.title) // 'Ana Arquitetura'
```

---

### 5. `slugify()` - Geração de Slugs

```typescript
// Exemplo 1: Título normal
slugify('Minha Nova Obra em São Paulo')
// Retorna: 'minha-nova-obra-em-sao-paulo'

// Exemplo 2: Caracteres especiais
slugify('Projeto #1 - Edifício "Horizonte" (2024)')
// Retorna: 'projeto-1-edificio-horizonte-2024'

// Exemplo 3: Acentuação
slugify('Construção & Reformas Rápidas')
// Retorna: 'construcao-reformas-rapidas'

// Exemplo 4: Espaços múltiplos e hífens
slugify('Post   com---muitos    espaços')
// Retorna: 'post-com-muitos-espacos'

// Passo a passo:
'Título Ação'
  .normalize('NFD')                  // 'Título Ação'
  .replace(/[\u0300-\u036f]/g, '')   // 'Titulo Acao'
  .toLowerCase()                      // 'titulo acao'
  .replace(/\s+/g, '-')              // 'titulo-acao'
  .replace(/[^a-z0-9-]/g, '')        // 'titulo-acao'
  .replace(/--+/g, '-')              // 'titulo-acao'
  .replace(/^-+|-+$/g, '')           // 'titulo-acao'
```

---

## Exemplos Práticos de Uso

### Cenário 1: Blog Público - Visitante Anônimo

```
👤 Usuário: Visitante não autenticado
🌐 URL: https://pedro.empreitador.com.br/blog

┌─────────────────────────────────────────┐
│ 1. FRONTEND (Nuxt)                      │
├─────────────────────────────────────────┤
│ getSubdomain() → 'pedro'                │
│ useApi() → GET /blog/posts              │
│   Headers:                              │
│     X-Subdomain: pedro                  │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 2. BACKEND - websiteTenant.js           │
├─────────────────────────────────────────┤
│ Lê X-Subdomain: 'pedro'                 │
│ Busca no DB:                            │
│   Website { subdomain: 'pedro' }        │
│     include: Tenant                     │
│                                         │
│ Injeta:                                 │
│   req.website = { id: 3, ... }          │
│   req.tenant = { id: 55, name: 'Pedro' }│
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 3. BACKEND - identifyTenant.js          │
├─────────────────────────────────────────┤
│ req.user? → Não (não autenticado)       │
│ req.tenant.id? → Sim (55)               │
│                                         │
│ Injeta:                                 │
│   req.tenantId = 55                     │
│   req.managingOtherTenant = false       │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 4. CONTROLLER - getBlogPosts            │
├─────────────────────────────────────────┤
│ const posts = await BlogPost.findAll({  │
│   where: {                              │
│     tenantId: 55,                       │
│     isPublished: true  // ← Só público  │
│   }                                     │
│ })                                      │
│                                         │
│ return res.json(posts)                  │
└─────────────────────────────────────────┘
```

---

### Cenário 2: Gerenciamento - Usuário Autenticado

```
👤 Usuário: João (tenantId: 123)
🌐 URL: https://joao.empreitador.com.br/admin/blog
🔐 Autenticado: Sim

┌─────────────────────────────────────────┐
│ 1. FRONTEND (Nuxt)                      │
├─────────────────────────────────────────┤
│ useApi() → POST /blog/posts             │
│   Headers:                              │
│     X-Subdomain: joao                   │
│     Cookie: session=xyz123              │
│   Body:                                 │
│     { title: '...', content: '...' }    │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 2. BACKEND - Auth Middleware            │
├─────────────────────────────────────────┤
│ Valida cookie 'session=xyz123'          │
│ Busca usuário no DB                     │
│                                         │
│ Injeta:                                 │
│   req.user = {                          │
│     id: 42,                             │
│     name: 'João',                       │
│     tenantId: 123,                      │
│     tenantTypeId: 2                     │
│   }                                     │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 3. BACKEND - websiteTenant.js           │
├─────────────────────────────────────────┤
│ Lê X-Subdomain: 'joao'                  │
│ Busca e injeta:                         │
│   req.tenant = { id: 123, ... }         │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 4. BACKEND - identifyTenant.js          │
├─────────────────────────────────────────┤
│ req.user.tenantId? → Sim (123)          │
│                                         │
│ Injeta:                                 │
│   req.tenantId = 123  // ← Do usuário!  │
│   req.managingOtherTenant = false       │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 5. CONTROLLER - createBlogPost          │
├─────────────────────────────────────────┤
│ // João só pode criar no próprio tenant │
│ const post = await BlogPost.create({    │
│   tenantId: 123,  // ← Seu próprio      │
│   title: req.body.title,                │
│   authorId: req.user.id                 │
│ })                                      │
│                                         │
│ return res.json(post)                   │
└─────────────────────────────────────────┘
```

---

### Cenário 3: Master Admin Gerenciando Outros Tenants

```
👤 Usuário: Admin Master (tenantId: 1, tenantTypeId: 5)
🌐 URL: https://blog.empreitador.com.br/admin/posts?tenantId=88
🔐 Autenticado: Sim (Master)

┌─────────────────────────────────────────┐
│ 1. FRONTEND (Nuxt)                      │
├─────────────────────────────────────────┤
│ // Painel admin com dropdown de tenants │
│ const selectedTenant = ref(88)          │
│                                         │
│ useApi() → GET /blog/posts              │
│   Query: ?tenantId=88                   │
│   Headers:                              │
│     X-Subdomain: blog                   │
│     Cookie: session=master_abc          │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 2. BACKEND - Auth Middleware            │
├─────────────────────────────────────────┤
│ Injeta:                                 │
│   req.user = {                          │
│     id: 1,                              │
│     name: 'Admin Master',               │
│     tenantId: 1,                        │
│     tenantTypeId: 5  // ← MASTER        │
│   }                                     │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 3. BACKEND - websiteTenant.js           │
├─────────────────────────────────────────┤
│ Lê X-Subdomain: 'blog'                  │
│ Injeta:                                 │
│   req.tenant = { id: 1, ... }           │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 4. BACKEND - identifyTenant.js          │
├─────────────────────────────────────────┤
│ req.query.tenantId? → Sim (88)          │
│ req.user.tenantTypeId === 5? → Sim ✅   │
│                                         │
│ Injeta:                                 │
│   req.tenantId = 88  // ← NÃO é o 1!   │
│   req.managingOtherTenant = true        │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 5. BACKEND - validateTenant.js          │
├─────────────────────────────────────────┤
│ if (req.managingOtherTenant) {          │
│   const tenant = await Tenant.findByPk  │
│     (88)                                │
│                                         │
│   if (!tenant) {                        │
│     return 404 'Tenant não encontrado'  │
│   }                                     │
│                                         │
│   req.managedTenant = tenant            │
│ }                                       │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ 6. CONTROLLER - getBlogPosts            │
├─────────────────────────────────────────┤
│ // Master vendo posts do tenant 88      │
│ const posts = await BlogPost.findAll({  │
│   where: {                              │
│     tenantId: 88,  // ← Tenant gerenci. │
│   },                                    │
│   include: [{ model: User, as: 'author' │
│   }]                                    │
│ })                                      │
│                                         │
│ return res.json({                       │
│   posts,                                │
│   managedTenant: req.managedTenant      │
│ })                                      │
└─────────────────────────────────────────┘
```

---

## Casos de Uso por Tipo de Usuário

### 1. Visitante Anônimo (Público)

**O que pode fazer:**
- Visualizar posts publicados do tenant do subdomínio
- Ver informações do website (título, descrição)
- Acessar páginas públicas

**Limitações:**
- Não pode criar/editar posts
- Não vê posts não publicados (draft)
- Só acessa dados do tenant do subdomínio atual

**Exemplo de Rota:**
```javascript
// backend/routes/blog.js
router.get('/posts/public', 
  identifyTenant,  // ← Identifica via subdomain
  async (req, res) => {
    const posts = await BlogPost.findAll({
      where: { 
        tenantId: req.tenantId,
        isPublished: true  // ← Só publicados
      }
    })
    res.json(posts)
  }
)
```

---

### 2. Cliente Autenticado (Tenant Type 2-4)

**O que pode fazer:**
- Gerenciar posts do próprio tenant
- Criar/editar/deletar posts
- Ver posts publicados e não publicados (próprios)

**Limitações:**
- Só acessa dados do próprio tenant
- Não pode gerenciar outros tenants
- Query param `?tenantId=X` é ignorado

**Exemplo de Rota:**
```javascript
router.post('/posts',
  requireAuth,      // ← Precisa estar logado
  identifyTenant,   // ← Usa req.user.tenantId
  async (req, res) => {
    // req.tenantId = req.user.tenantId (sempre)
    
    const post = await BlogPost.create({
      tenantId: req.tenantId,  // ← Próprio tenant
      title: req.body.title,
      authorId: req.user.id
    })
    
    res.json(post)
  }
)
```

---

### 3. Master Admin (Tenant Type 5)

**O que pode fazer:**
- Gerenciar qualquer tenant usando `?tenantId=X`
- Criar posts para outros tenants
- Ver/editar/deletar posts de qualquer tenant
- Acessar dados agregados de todos os tenants

**Exemplo de Rota:**
```javascript
router.get('/posts/all',
  requireAuth,
  requireMasterAdmin,  // ← Verifica tenantTypeId === 5
  identifyTenant,
  validateTenant,      // ← Valida tenantId do query param
  async (req, res) => {
    // req.tenantId pode ser de outro tenant
    // req.managingOtherTenant = true
    
    const posts = await BlogPost.findAll({
      where: { tenantId: req.tenantId },
      include: [
        { model: User, as: 'author' },
        { model: Tenant, as: 'tenant' }
      ]
    })
    
    res.json({
      posts,
      managingTenant: req.managedTenant.name,
      isMasterAdmin: true
    })
  }
)
```

---

## Tabela de Decisão - Identificação de Tenant

| Condição | Query `?tenantId` | `req.user` | `req.tenant` | Resultado `req.tenantId` |
|----------|-------------------|------------|--------------|--------------------------|
| Master + Query | ✅ `?tenantId=99` | ✅ Master (type 5) | ✅ | `99` (query) |
| Master sem Query | ❌ | ✅ Master | ✅ | `1` (próprio) |
| Cliente + Query | ✅ `?tenantId=99` | ✅ Cliente (type 2-4) | ✅ | `123` (ignora query) |
| Cliente Autenticado | ❌ | ✅ Cliente | ✅ | `123` (user.tenantId) |
| Anônimo via Subdomain | ❌ | ❌ | ✅ | `456` (tenant.id) |
| Sem Auth/Subdomain | ❌ | ❌ | ❌ | `1` (master blog fallback) |

---

## Variáveis Injetadas no `req` (Backend)

```javascript
// Após todos os middlewares executarem
req = {
  // Da autenticação (se logado)
  user: {
    id: 42,
    tenantId: 123,
    tenantTypeId: 2,
    name: 'João'
  },
  
  // Do websiteTenant.js
  website: {
    id: 5,
    subdomain: 'joao',
    title: 'João Construções',
    tenantId: 123
  },
  tenant: {
    id: 123,
    name: 'João da Silva',
    tenantTypeId: 2
  },
  
  // Do identifyTenant.js
  tenantId: 123,                    // ← Usado em queries
  managingOtherTenant: false,       // ← true se Master + ?tenantId
  isMasterBlog: false,              // ← true se blog master público
  
  // Do validateTenant.js (se Master gerenciando)
  managedTenant: {
    id: 88,
    name: 'Outro Tenant'
  }
}
```

---

## Diagrama de Fluxo Completo

```
                    REQUISIÇÃO HTTP
                          │
                          ▼
            ┌─────────────────────────┐
            │   Cloudflare Worker     │
            │  (Injeta X-Subdomain)   │
            └───────────┬─────────────┘
                        │
                        ▼
            ┌─────────────────────────┐
            │    Express Backend      │
            └───────────┬─────────────┘
                        │
         ┌──────────────┴──────────────┐
         ▼                             ▼
┌──────────────────┐         ┌──────────────────┐
│ Auth Middleware  │         │ CORS/Headers     │
│ (se autenticado) │         │                  │
└────────┬─────────┘         └──────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│     websiteTenant.js                 │
│  1. Lê X-Subdomain                   │
│  2. Busca Website + Tenant no DB     │
│  3. Cacheia resultado                │
│  4. Injeta req.website, req.tenant   │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│     identifyTenant.js                │
│  PRIORIDADE:                         │
│  1. ?tenantId (se Master)            │
│  2. req.user.tenantId (se auth)      │
│  3. req.tenant.id (subdomain)        │
│  4. Master Blog (fallback)           │
│  Injeta: req.tenantId                │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│     validateTenant.js                │
│  (Só se managingOtherTenant)         │
│  Valida se tenantId existe           │
│  Injeta: req.managedTenant           │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│          CONTROLLER                  │
│  Usa req.tenantId em queries         │
│  Retorna dados filtrados             │
└──────────────────────────────────────┘
```

---

## Resumo das Boas Práticas

### ✅ Fazer

1. **Sempre enviar `X-Subdomain`** do frontend
2. **Cachear** resultados de busca de tenant (websiteTenant.js já faz)
3. **Validar tenant** quando Master gerencia outro (`validateTenant`)
4. **Filtrar por `req.tenantId`** em todas as queries de dados
5. **Usar `credentials: 'include'`** para enviar cookies de sessão

### ❌ Evitar

1. **Confiar em subdomínio sem validação** no banco
2. **Permitir usuários comuns usarem `?tenantId`** (segurança)
3. **Esquecer de publicar apenas posts públicos** para anônimos
4. **Cachear indefinidamente** (use TTL razoável)
5. **Fazer queries sem filtro de tenant** (vazamento de dados)

---

## Exemplo de Uso Completo: Criar Post

### Frontend (Nuxt)

```vue
<script setup>
const apiFetch = useApi()
const router = useRouter()

const form = reactive({
  title: '',
  content: '',
  isPublished: false
})

async function createPost() {
  try {
    // Se for Master gerenciando outro tenant
    const queryParams = route.query.tenantId 
      ? `?tenantId=${route.query.tenantId}` 
      : ''
    
    const post = await apiFetch(`/blog/posts${queryParams}`, {
      method: 'POST',
      body: {
        title: form.title,
        content: form.content,
        slug: slugify(form.title),
        isPublished: form.isPublished
      }
    })
    
    router.push(`/blog/${post.slug}`)
  } catch (error) {
    console.error('Erro ao criar post:', error)
  }
}
</script>

<template>
  <form @submit.prevent="createPost">
    <input v-model="form.title" placeholder="Título" />
    <textarea v-model="form.content" placeholder="Conteúdo" />
    <label>
      <input type="checkbox" v-model="form.isPublished" />
      Publicar imediatamente
    </label>
    <button type="submit">Criar Post</button>
  </form>
</template>
```

### Backend (Express)

```javascript
// routes/blog.js
const express = require('express')
const router = express.Router()
const { BlogPost } = require('../models')
const { requireAuth } = require('../middleware/auth')
const { identifyTenant, validateTenant } = require('../middleware/identifyTenant')

router.post('/posts',
  requireAuth,       // Precisa estar autenticado
  identifyTenant,    // Identifica tenant (próprio ou gerenciado)
  validateTenant,    // Valida se tenant existe (se Master)
  async (req, res) => {
    try {
      // Validações
      if (!req.body.title || !req.body.content) {
        return res.status(400).json({ error: 'Título e conteúdo obrigatórios' })
      }
      
      // Verifica se slug já existe para este tenant
      const existingPost = await BlogPost.findOne({
        where: { 
          slug: req.body.slug,
          tenantId: req.tenantId  // ← Importante!
        }
      })
      
      if (existingPost) {
        return res.status(409).json({ error: 'Slug já existe para este tenant' })
      }
      
      // Cria o post
      const post = await BlogPost.create({
        tenantId: req.tenantId,  // ← Usa tenant identificado
        authorId: req.user.id,
        title: req.body.title,
        content: req.body.content,
        slug: req.body.slug,
        isPublished: req.body.isPublished || false
      })
      
      // Log para auditoria
      if (req.managingOtherTenant) {
        console.log(`[Audit] Master ${req.user.id} criou post para tenant ${req.tenantId}`)
      }
      
      res.status(201).json(post)
      
    } catch (error) {
      console.error('Erro ao criar post:', error)
      res.status(500).json({ error: 'Erro ao criar post' })
    }
  }
)

module.exports = router
```

---

Essa documentação cobre todo o fluxo de identificação de tenants tanto no frontend quanto no backend, com exemplos práticos para cada cenário! 🚀