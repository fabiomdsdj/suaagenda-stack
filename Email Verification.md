# 📧 Manual de Implementação — Email Verification
## Sua Agenda · Sistema de Confirmação de E-mail

---

## Visão Geral do Fluxo

```
Cadastro
  │
  ├─► createCompleteTenant() → commit
  │
  ├─► sendEmail() welcome ← já existe
  │
  ├─► sendVerificationEmail() ← NOVO
  │     └─ cria registro em email_verifications
  │     └─ envia email com link tokenizado
  │
  └─► Redirect frontend → /admin/auth/check-email
        │
        └─► Usuário clica no link do email
              │
              └─► GET /auth/verify-email?token=xxx
                    │
                    ├─► success → /admin/auth/verify-email (página sucesso)
                    │             → auto-redirect /admin/setup em 5s
                    └─► error  → /admin/auth/verify-email (página erro + reenvio)
```

---

## 1. BANCO DE DADOS

### 1.1 Rodar as migrations (em ordem)

```bash
npx sequelize-cli db:migrate
```

Arquivos na pasta `migrations/`:

| Arquivo | O que faz |
|---|---|
| `20240101_create_email_verifications.js` | Cria tabela `email_verifications` |
| `20240102_add_emailVerified_to_users.js` | Adiciona `emailVerified` e `emailVerifiedAt` em `users` |

### 1.2 Estrutura da tabela `email_verifications`

| Coluna | Tipo | Descrição |
|---|---|---|
| `id` | INTEGER PK | Auto increment |
| `userId` | INTEGER FK | Referencia `users.id` com CASCADE DELETE |
| `token` | STRING(64) | Token hex único gerado com `crypto.randomBytes(32)` |
| `expiresAt` | DATE | `now + 24h` |
| `verifiedAt` | DATE nullable | Preenchido quando o usuário clica no link |

---

## 2. BACKEND

### 2.1 Copiar os arquivos

```
backend/
├── controllers/
│   └── EmailVerificationController.js    ← NOVO
├── models/
│   └── emailVerification.js              ← NOVO
├── routes/
│   └── emailVerification.js              ← NOVO
├── services/
│   └── emailVerificationService.js       ← NOVO
├── templates/emails/
│   └── verifyEmail.js                    ← NOVO
└── controllers/
    └── AuthController.js                 ← MODIFICADO (ver diff)
```

### 2.2 Registrar o model em `models/index.js`

O Sequelize CLI já carrega automaticamente todos os models da pasta, então
só garanta que o arquivo `emailVerification.js` está lá.

Se você usa carregamento manual, adicione:

```js
// models/index.js (se manual)
const EmailVerification = require('./emailVerification')(sequelize, DataTypes);
db.EmailVerification = EmailVerification;
```

### 2.3 Registrar as rotas no `app.js` / `server.js`

```js
// app.js ou server.js
const emailVerificationRoutes = require('./routes/emailVerification');

// Adicione junto com as outras rotas de auth:
app.use('/auth', emailVerificationRoutes);
// Resultado: GET  /auth/verify-email?token=xxx
//            POST /auth/resend-verification
```

### 2.4 Variáveis de ambiente necessárias

Adicione ao seu `.env`:

```env
# Já devem existir:
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=xxxx
AWS_SECRET_ACCESS_KEY=xxxx
EMAIL_FROM=noreply@suaagenda.link

# Obrigatório — usado para montar o link de verificação:
BASE_URL=https://app.suaagenda.link
```

> ⚠️ `BASE_URL` deve apontar para o domínio do **frontend**, não do backend.
> O link gerado será: `${BASE_URL}/admin/auth/verify-email?token=xxx`

### 2.5 Modificação no `AuthController.js`

No método `register`, após `await t.commit()`, adicione o bloco de
verificação (ver arquivo `AuthController.diff.js`). A mudança essencial é:

```js
// Após t.commit() e o email de boas-vindas:
try {
  await sendVerificationEmail(
    result.user.id,
    result.user.email,
    result.user.firstName,
  );
} catch (verifyErr) {
  console.error('[Auth] Falha ao enviar email de verificação:', verifyErr.message);
  // Não bloqueia o registro
}
```

E no response JSON, adicione `emailVerified: false`:

```js
return res.status(201).json({
  token,
  user: {
    ...
    emailVerified: false, // ← NOVO
  },
  ...
});
```

---

## 3. FRONTEND (Nuxt 3)

### 3.1 Copiar os arquivos de página

```
frontend/pages/admin/auth/
├── check-email.vue     ← NOVO (tela "verifique seu email")
└── verify-email.vue    ← NOVO (tela de resultado da verificação)
```

### 3.2 Redirecionar após cadastro

No `registerUserWithTrial` do `stores/auth.ts`, troque o redirect final:

```ts
// Antes:
useRouter().push('/admin/setup');

// Depois:
useRouter().push(`/admin/auth/check-email?email=${encodeURIComponent(this.user.email)}`);
```

### 3.3 Rota do link no email

O link no email aponta para:
```
https://app.suaagenda.link/admin/auth/verify-email?token=abc123...
```

A página `verify-email.vue` lê o `?token=` da query string, chama a API e
exibe sucesso ou erro automaticamente no `onMounted`.

### 3.4 Verificar o `runtimeConfig` do Nuxt

```ts
// nuxt.config.ts
export default defineNuxtConfig({
  runtimeConfig: {
    public: {
      apiBaseUrl: process.env.API_BASE_URL || 'http://localhost:3001/api',
    },
  },
});
```

As páginas usam `config.public.apiBaseUrl` para as chamadas à API.

---

## 4. COMPORTAMENTO E EDGE CASES

### Tokens
- Validade: **24 horas**
- Cada cadastro gera **1 token novo**
- Clicar no link duas vezes retorna "Email já verificado anteriormente" (não
  dá erro 500, só informa)

### Reenvio
- Cooldown de **2 minutos** no backend (verifica o `createdAt` do último token)
- Cooldown visual de **120 segundos** no frontend (contador regressivo)
- Retorna 400 com mensagem amigável se estiver no cooldown

### Token expirado
- A página `verify-email.vue` detecta a palavra "expir" na mensagem de erro
  e exibe automaticamente o formulário de reenvio com campo de email

### Usuário não verificado
- Não bloqueia o login nem o acesso ao sistema (regra de negócio atual)
- Você pode adicionar um banner de aviso no dashboard consultando
  `authStore.user?.emailVerified`
- Para bloquear funcionalidades, crie um middleware Nuxt que redireciona para
  `/admin/auth/check-email` se `!emailVerified`

### Segurança
- Token gerado com `crypto.randomBytes(32)` — 256 bits de entropia
- Token de 64 caracteres hex, único via `UNIQUE` no banco
- Não expõe o token em logs
- Expiração verificada no servidor, não só no cliente

---

## 5. TESTE RÁPIDO

```bash
# 1. Fazer cadastro via frontend ou curl
curl -X POST http://localhost:3001/api/register \
  -H "Content-Type: application/json" \
  -d '{"firstName":"João","email":"joao@teste.com","password":"Teste@123","tenantTypeId":3,"subdomain":"joaoteste","officeName":"Salão do João","segmentTypeId":1}'

# 2. Verificar se o token foi criado no banco
SELECT * FROM email_verifications ORDER BY id DESC LIMIT 1;

# 3. Simular clique no link
curl "http://localhost:3001/api/auth/verify-email?token=SEU_TOKEN_AQUI"

# 4. Verificar se o user foi atualizado
SELECT id, email, emailVerified, emailVerifiedAt FROM users WHERE email = 'joao@teste.com';
```

---

## 6. OPCIONAL — Banner de aviso no Dashboard

Se quiser mostrar um aviso para usuários não verificados sem bloquear o acesso:

```vue
<!-- components/EmailVerificationBanner.vue -->
<template>
  <div v-if="!authStore.user?.emailVerified" class="verify-banner">
    ⚠️ Confirme seu e-mail para garantir o acesso contínuo.
    <NuxtLink to="/admin/auth/check-email">Verificar agora</NuxtLink>
  </div>
</template>

<script setup>
const authStore = useAuthStore();
</script>
```

---

## 7. RESUMO DOS ARQUIVOS ENTREGUES

| Arquivo | Tipo | Ação |
|---|---|---|
| `migrations/20240101_create_email_verifications.js` | SQL | Criar tabela |
| `migrations/20240102_add_emailVerified_to_users.js` | SQL | Alter users |
| `models/emailVerification.js` | Model | Copiar para `models/` |
| `services/emailVerificationService.js` | Service | Copiar para `services/` |
| `templates/emails/verifyEmail.js` | Template | Copiar para `templates/emails/` |
| `controllers/EmailVerificationController.js` | Controller | Copiar para `controllers/` |
| `controllers/AuthController.diff.js` | Diff | Aplicar no seu AuthController |
| `routes/emailVerification.js` | Route | Copiar e registrar no app.js |
| `pages/check-email.vue` | Vue page | `pages/admin/auth/check-email.vue` |
| `pages/verify-email.vue` | Vue page | `pages/admin/auth/verify-email.vue` |